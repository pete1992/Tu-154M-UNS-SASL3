--[[
Changelog
2026-10-04
- Run ordered electrical batches in xTlua and return state through owned mailboxes.
- Validate request sequences; leave public aircraft DataRef writes to SASL.
]]

-- Numeric electric worker. SASL alone commits public aircraft DataRefs.
local Packet = dofile("packet.lua")
local Core = dofile("core.lua")
local module_env = getfenv(1)
local dataref_handles = {}
local find_datarefs = {
    { "electric_worker_request", Packet.REQUEST_PATH },
    { "electric_worker_response", Packet.RESPONSE_PATH },
}

local function bind_datarefs(definitions)
    for _, def in ipairs(definitions) do
        local property = find_dataref(def[2])
        dataref_handles[#dataref_handles + 1] = property.dref
        module_env[def[1]] = property
    end
end

bind_datarefs(find_datarefs)

local last_packet
local last_session, last_id
local last_error

local function report(message)
    message = tostring(message)
    if message ~= last_error then
        last_error = message
        if type(log_error) == "function" then log_error("Electric worker: " .. message) end
    end
end

local function process(packet)
    local request = Packet.validate_request(Packet.unpack(packet))
    if request.session == last_session and request.id <= last_id then return end
    local started = os.clock()
    local core = Core.new(request.frames[1].inputs, request.state, nil, ".")
    for _, frame in ipairs(request.frames) do
        core:step(frame.inputs)
    end
    local response = Packet.pack({
        version = Packet.VERSION,
        session = request.session,
        id = request.id,
        first = request.first,
        last = request.last,
        state = core:export(),
        outputs = core:outputs(),
        elapsed_ms = math.max(0, (os.clock() - started) * 1000),
    })
    electric_worker_response = response
    last_session, last_id = request.session, request.id
    last_error = nil
end

function after_physics()
    for _, handle in ipairs(dataref_handles) do
        if XTLuaGetDataRefType(handle) ~= "string" then return end
    end
    local packet = electric_worker_request
    if packet == last_packet or packet == Packet.empty() or packet == "" then return end
    -- Retry only a changed packet; a failed batch never repeatedly consumes CPU.
    last_packet = packet
    local ok, message = pcall(process, packet)
    if not ok then report(message) end
end
