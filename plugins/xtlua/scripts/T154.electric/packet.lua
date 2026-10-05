--[[
Changelog
2026-10-04
- Replace path-keyed frame payloads with stable dense binding vectors.
- Delta-encode queued frames after the first sample.
- Carry only worker-owned checkpoint values and a compact output bit mask.
- Reduce each fixed mailbox from 128 KiB to 16 KiB while retaining bounded ASCII transport.
]]

-- Compact data-only packets shared by the SASL bridge and the electric worker.
-- The mailbox remains fixed-size because both runtimes expose it as a string
-- DataRef, but only stable numeric slots cross the boundary now; DataRef names do
-- not.  Subsequent frames in one batch contain only changed slots.
local Packet = {
    VERSION = 2,
    CAPACITY = 16384,
    MAX_FRAMES = 16,
    REQUEST_PATH = "tu154/custom/elec/worker_request",
    RESPONSE_PATH = "tu154/custom/elec/worker_response",
}

local MAGIC = "T154E2:"
local HEADER_SIZE = #MAGIC + 7
local MAX_PAYLOAD = Packet.CAPACITY - HEADER_SIZE
local MAX_DEPTH = 24
local MAX_NODES = 16384
local MAX_STRING = 4096
local MAX_INTEGER = 9007199254740991
local EMPTY = string.rep(" ", Packet.CAPACITY)
local HEX = "0123456789ABCDEF"

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

local function dense_length(value, maximum)
    if type(value) ~= "table" then return nil end
    local count, largest = 0, 0
    for key in pairs(value) do
        if not integer(key, 1) then return nil end
        count = count + 1
        if key > largest then largest = key end
        if maximum and count > maximum then return nil end
    end
    if largest ~= count then return nil end
    return count
end

local function require_array(value, expected, label)
    local count = dense_length(value, expected or MAX_NODES)
    if count == nil or (expected ~= nil and count ~= expected) then
        fail((label or "array") .. " shape")
    end
    return count
end

function Packet.empty()
    return EMPTY
end

-- Small generic codec used only after transport structures have already been
-- compacted. Dense Lua arrays have their own tag and therefore do not serialize
-- numeric table keys at all.
local function encode_packet(value)
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

            local array_count = dense_length(item, MAX_NODES)
            if array_count ~= nil then
                append("a" .. array_count .. ":")
                for index = 1, array_count do encode(item[index], depth + 1) end
            else
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

local function decode_packet(packet)
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
        elseif tag == "a" then
            local entries = count(MAX_NODES)
            local result = {}
            for index = 1, entries do result[index] = decode(depth + 1) end
            return result
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

local function compact_state(state, Core)
    if type(state) ~= "table" or type(state.values) ~= "table"
        or type(state.models) ~= "table" then fail("state shape") end
    local values = {}
    for index, definition in ipairs(Core.owned_bindings) do
        local value = state.values[definition.key]
        if not finite(value) then fail("invalid state value") end
        values[index] = value
    end
    local revision = state.gpu_command_revision or 0
    if not integer(revision, 0) then fail("invalid state revision") end
    return { values, state.models, revision }
end

local function expand_state(compact, Core)
    require_array(compact, 3, "compact state")
    local source_values = compact[1]
    require_array(source_values, #Core.owned_bindings, "state values")
    if type(compact[2]) ~= "table" then fail("state models") end
    if not integer(compact[3], 0) then fail("state revision") end

    local values = {}
    for index, definition in ipairs(Core.owned_bindings) do
        local value = source_values[index]
        if not finite(value) then fail("invalid state value") end
        values[definition.key] = value
    end
    return {
        values = values,
        models = compact[2],
        gpu_command_revision = compact[3],
    }
end

local function input_vector(inputs, Core)
    if type(inputs) ~= "table" then fail("frame inputs") end
    local result = {}
    for index, definition in ipairs(Core.transport_bindings) do
        local value = inputs[definition.key]
        if not finite(value) then fail("invalid transport input") end
        result[index] = value
    end
    local revision = inputs[Core.gpu_revision_key] or 0
    if not integer(revision, 0) then fail("invalid GPU revision") end
    result[#Core.transport_bindings + 1] = revision
    return result
end

local function expand_input_vector(vector, Core)
    local expected = #Core.transport_bindings + 1
    require_array(vector, expected, "input vector")
    local result = {}
    for index, definition in ipairs(Core.transport_bindings) do
        local value = vector[index]
        if not finite(value) then fail("invalid transport input") end
        result[definition.key] = value
    end
    local revision = vector[expected]
    if not integer(revision, 0) then fail("invalid GPU revision") end
    result[Core.gpu_revision_key] = revision
    return result
end

local function delta_vector(previous, current)
    local result = {}
    for index = 1, #current do
        if current[index] ~= previous[index] then
            result[#result + 1] = index
            result[#result + 1] = current[index]
        end
    end
    return result
end

local function apply_delta(previous, delta)
    local count = require_array(delta, nil, "frame delta")
    if count % 2 ~= 0 then fail("frame delta pair") end
    local result = {}
    for index = 1, #previous do result[index] = previous[index] end
    local last_slot = 0
    for position = 1, count, 2 do
        local slot, value = delta[position], delta[position + 1]
        if not integer(slot, 1) or slot > #previous or slot <= last_slot or not finite(value) then
            fail("invalid frame delta")
        end
        result[slot] = value
        last_slot = slot
    end
    return result
end

local function output_mask(outputs, state, Core)
    if type(outputs) ~= "table" then fail("outputs missing") end
    local bits = {}
    for index = 1, math.ceil(#Core.owned_bindings / 4) do bits[index] = 0 end
    local known = {}
    for index, definition in ipairs(Core.owned_bindings) do
        known[definition.key] = index
    end
    for key, value in pairs(outputs) do
        local index = known[key]
        if not index or not finite(value) or state.values[key] ~= value then
            fail("invalid output value")
        end
        local nibble = math.floor((index - 1) / 4) + 1
        local bit = (index - 1) % 4
        bits[nibble] = bits[nibble] + 2 ^ bit
    end
    local chars = {}
    for index, value in ipairs(bits) do chars[index] = HEX:sub(value + 1, value + 1) end
    return table.concat(chars)
end

local function expand_outputs(mask, state, Core)
    local expected = math.ceil(#Core.owned_bindings / 4)
    if type(mask) ~= "string" or #mask ~= expected then fail("output mask size") end
    local outputs = {}
    for nibble = 1, expected do
        local char = mask:sub(nibble, nibble):upper()
        local value = HEX:find(char, 1, true)
        if not value then fail("output mask character") end
        value = value - 1
        for bit = 0, 3 do
            local index = (nibble - 1) * 4 + bit + 1
            if index <= #Core.owned_bindings and math.floor(value / (2 ^ bit)) % 2 == 1 then
                local key = Core.owned_bindings[index].key
                local item = state.values[key]
                if not finite(item) then fail("output state value") end
                outputs[key] = item
            end
        end
    end
    return outputs
end

local function validate_envelope(session, id, first, last)
    if type(session) ~= "string" or #session < 1 or #session > 128 or not ascii(session) then
        fail("session")
    end
    if not integer(id, 1) or not integer(first, 1) or not integer(last, first) then
        fail("sequence")
    end
end

function Packet.pack_request(request, Core)
    if type(request) ~= "table" or request.version ~= Packet.VERSION then fail("request version") end
    validate_envelope(request.session, request.id, request.first, request.last)
    if type(request.frames) ~= "table" then fail("request frames") end
    local frame_count = request.last - request.first + 1
    if frame_count < 1 or frame_count > Packet.MAX_FRAMES then fail("too many frames") end
    require_array(request.frames, frame_count, "request frames")

    local frames = {}
    local previous
    for index = 1, frame_count do
        local frame = request.frames[index]
        if type(frame) ~= "table" or frame.id ~= request.first + index - 1 then fail("frame sequence") end
        local current = input_vector(frame.inputs, Core)
        if index == 1 then frames[1] = current
        else frames[index] = delta_vector(previous, current) end
        previous = current
    end

    return encode_packet({
        "Q", Packet.VERSION, request.session, request.id,
        request.first, request.last, compact_state(request.state, Core), frames,
    })
end

function Packet.unpack_request(packet, Core)
    local wire = decode_packet(packet)
    require_array(wire, 8, "request")
    if wire[1] ~= "Q" or wire[2] ~= Packet.VERSION then fail("request version") end
    validate_envelope(wire[3], wire[4], wire[5], wire[6])
    local frame_count = wire[6] - wire[5] + 1
    if frame_count < 1 or frame_count > Packet.MAX_FRAMES then fail("too many frames") end
    require_array(wire[8], frame_count, "request frames")

    local frames, previous = {}, nil
    for index = 1, frame_count do
        local current
        if index == 1 then
            current = wire[8][1]
            require_array(current, #Core.transport_bindings + 1, "first input vector")
        else
            current = apply_delta(previous, wire[8][index])
        end
        frames[index] = {
            id = wire[5] + index - 1,
            inputs = expand_input_vector(current, Core),
        }
        previous = current
    end

    return {
        version = wire[2], session = wire[3], id = wire[4],
        first = wire[5], last = wire[6],
        state = expand_state(wire[7], Core), frames = frames,
    }
end

function Packet.pack_response(response, Core)
    if type(response) ~= "table" or response.version ~= Packet.VERSION then fail("response version") end
    validate_envelope(response.session, response.id, response.first, response.last)
    local state = response.state
    local mask = output_mask(response.outputs, state, Core)
    return encode_packet({
        "R", Packet.VERSION, response.session, response.id,
        response.first, response.last, compact_state(state, Core), mask,
    })
end

function Packet.unpack_response(packet, Core)
    local wire = decode_packet(packet)
    require_array(wire, 8, "response")
    if wire[1] ~= "R" or wire[2] ~= Packet.VERSION then fail("response version") end
    validate_envelope(wire[3], wire[4], wire[5], wire[6])
    local state = expand_state(wire[7], Core)
    return {
        version = wire[2], session = wire[3], id = wire[4],
        first = wire[5], last = wire[6], state = state,
        outputs = expand_outputs(wire[8], state, Core),
    }
end

-- Retained for packet diagnostics/tests; production request/response traffic
-- should use the schema-aware functions above.
Packet.pack = encode_packet
Packet.unpack = decode_packet

return Packet
