--[[
Changelog
2026-10-04
- Add bounded, data-only request and response serialization.
- Use fixed-size ASCII packets with version, structure and numeric validation.
]]

-- Bounded data-only packets shared by the SASL bridge and the electric worker.
-- Fixed-size ASCII writes keep the owned XTLua string storage length stable.
local Packet = {
    VERSION = 1,
    CAPACITY = 131072,
    MAX_FRAMES = 16,
    REQUEST_PATH = "tu154/custom/elec/worker_request",
    RESPONSE_PATH = "tu154/custom/elec/worker_response",
}

local MAGIC = "T154E1:"
local HEADER_SIZE = #MAGIC + 7
local MAX_PAYLOAD = Packet.CAPACITY - HEADER_SIZE
local MAX_DEPTH = 24
local MAX_NODES = 32768
local MAX_STRING = 65536
local MAX_INTEGER = 9007199254740991
local EMPTY = string.rep(" ", Packet.CAPACITY)

local function fail(message)
    error("electric packet: " .. message, 0)
end

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

local function integer(value, minimum)
    return finite(value) and value >= minimum and value <= MAX_INTEGER
        and value == math.floor(value)
end

local function ascii(value)
    return not value:find("[^\032-\126]")
end

function Packet.empty()
    return EMPTY
end

function Packet.pack(value)
    if type(value) ~= "table" then fail("root must be a table") end
    local pieces, stack = {}, {}
    local bytes, nodes = 0, 0
    local function append(part)
        bytes = bytes + #part
        if bytes > MAX_PAYLOAD then fail("capacity exceeded") end
        pieces[#pieces + 1] = part
    end
    local function encode(item, depth)
        nodes = nodes + 1
        if nodes > MAX_NODES or depth > MAX_DEPTH then fail("structure limit exceeded") end
        local kind = type(item)
        if kind == "number" then
            if not finite(item) then fail("non-finite number") end
            local number = string.format("%.17g", item)
            if not number:match("^[%d%+%-%.eE]+$") then fail("unsupported numeric locale") end
            append("n" .. #number .. ":" .. number)
        elseif kind == "string" then
            if #item > MAX_STRING or not ascii(item) then fail("invalid string") end
            append("s" .. #item .. ":" .. item)
        elseif kind == "boolean" then
            append(item and "b1" or "b0")
        elseif kind == "table" then
            if stack[item] or getmetatable(item) ~= nil then fail("cyclic or non-plain table") end
            stack[item] = true
            local keys = {}
            for key in pairs(item) do
                if type(key) ~= "string" and not integer(key, -MAX_INTEGER) then
                    fail("invalid table key")
                end
                keys[#keys + 1] = key
                if #keys > MAX_NODES then fail("table limit exceeded") end
            end
            table.sort(keys, function(a, b)
                if type(a) ~= type(b) then return type(a) == "number" end
                return a < b
            end)
            append("m" .. #keys .. ":")
            for _, key in ipairs(keys) do
                encode(key, depth + 1)
                encode(item[key], depth + 1)
            end
            stack[item] = nil
        else
            fail("unsupported value type")
        end
    end
    encode(value, 0)
    local payload = table.concat(pieces)
    return MAGIC .. string.format("%06d", #payload) .. ":" .. payload
        .. EMPTY:sub(1, MAX_PAYLOAD - #payload)
end

function Packet.unpack(packet)
    if type(packet) ~= "string" or #packet ~= Packet.CAPACITY then fail("wrong buffer size") end
    if packet:sub(1, #MAGIC) ~= MAGIC then fail("wrong protocol signature") end
    local length_text = packet:sub(#MAGIC + 1, #MAGIC + 6)
    if not length_text:match("^%d%d%d%d%d%d$")
        or packet:sub(HEADER_SIZE, HEADER_SIZE) ~= ":" then fail("invalid header") end
    local length = tonumber(length_text)
    if length < 1 or length > MAX_PAYLOAD then fail("invalid payload length") end
    local payload = packet:sub(HEADER_SIZE + 1, HEADER_SIZE + length)
    if not ascii(payload) or packet:sub(HEADER_SIZE + length + 1):find("[^ ]") then
        fail("invalid payload or padding")
    end
    local position, nodes = 1, 0
    local function count(limit)
        local stop = payload:find(":", position, true)
        if not stop or stop - position > 8 then fail("invalid field length") end
        local text = payload:sub(position, stop - 1)
        if not text:match("^%d+$") or (#text > 1 and text:sub(1, 1) == "0") then
            fail("invalid field count")
        end
        local result = tonumber(text)
        if result > limit then fail("field limit exceeded") end
        position = stop + 1
        return result
    end
    local decode
    decode = function(depth)
        nodes = nodes + 1
        if nodes > MAX_NODES or depth > MAX_DEPTH or position > length then
            fail("structure limit or truncated value")
        end
        local tag = payload:sub(position, position)
        position = position + 1
        if tag == "n" or tag == "s" then
            local size = count(tag == "n" and 32 or MAX_STRING)
            if position + size - 1 > length then fail("truncated field") end
            local text = payload:sub(position, position + size - 1)
            position = position + size
            if tag == "s" then return text end
            if size == 0 or not text:match("^[%d%+%-%.eE]+$") then fail("invalid number") end
            local number = tonumber(text)
            if not finite(number) then fail("invalid or non-finite number") end
            return number
        elseif tag == "b" then
            local value = payload:sub(position, position)
            position = position + 1
            if value == "0" then return false end
            if value == "1" then return true end
            fail("invalid boolean")
        elseif tag == "m" then
            local entries = count(MAX_NODES)
            local result = {}
            for _ = 1, entries do
                local key = decode(depth + 1)
                if type(key) ~= "string" and not integer(key, -MAX_INTEGER) then
                    fail("invalid table key")
                end
                if result[key] ~= nil then fail("duplicate key") end
                result[key] = decode(depth + 1)
            end
            return result
        end
        fail("unknown value tag")
    end
    local result = decode(0)
    if type(result) ~= "table" or position ~= length + 1 then fail("trailing payload or wrong root") end
    return result
end

function Packet.validate_request(request)
    if type(request) ~= "table" or request.version ~= Packet.VERSION then fail("request version") end
    if type(request.session) ~= "string" or #request.session < 1 or #request.session > 128
        or not ascii(request.session) then fail("request session") end
    if not integer(request.id, 1) or not integer(request.first, 1)
        or not integer(request.last, request.first) then fail("request sequence") end
    if type(request.state) ~= "table" or type(request.frames) ~= "table" then fail("request state or frames") end
    local frames = request.last - request.first + 1
    if frames > Packet.MAX_FRAMES then fail("too many frames") end
    local count = 0
    for key in pairs(request.frames) do
        if not integer(key, 1) or key > frames then fail("invalid frame array") end
        count = count + 1
    end
    if count ~= frames then fail("missing frame") end
    for index = 1, frames do
        local frame = request.frames[index]
        if type(frame) ~= "table" or frame.id ~= request.first + index - 1
            or type(frame.inputs) ~= "table" then fail("invalid frame") end
    end
    return request
end

return Packet
