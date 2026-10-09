-- electric_worker.lua
-- Exchanges ordered electrical-model inputs and outputs with the worker controller.

-- SASL string transfers use one-based offsets and the complete protocol buffer.

-- Main-thread electrical adapter. The numerical model runs in xTlua whenever
-- its mailbox is available; a bounded synchronous fallback retains full state.
local base = sasl.getAircraftPath() .. "/plugins/xtlua/scripts/T154.electric/"
local Core = assert(loadfile(base .. "core.lua"))()
local Packet = assert(loadfile(base .. "packet.lua"))()
local Controller = assert(loadfile(base .. "controller.lua"))()(Core, Packet)
local properties = {}

local function defineProps(defs)
    for _, def in ipairs(defs) do
        local prop
        if def[4] ~= nil then
            prop = def[3](def[2], def[4])
        else
            prop = def[3](def[2])
        end
        assert(prop, "Missing electrical DataRef: " .. def[2])
        defineProperty(def[1], prop)
        properties[def[5]] = prop
    end
end

local definitions = {}
for index, item in ipairs(Core.bindings) do
    local accessor
    if item.index ~= nil then
        accessor = item.kind == "integer" and globalPropertyiae or globalPropertyfae
    else
        accessor = item.kind == "integer" and globalPropertyi or globalPropertyf
    end
    definitions[#definitions + 1] = {
        "electric_input_" .. index,
        item.path,
        accessor,
        item.index ~= nil and item.index + 1 or nil,
        item.key,
    }
end
defineProps(definitions)

-- Diagnostic controls are private to this adapter and are not flight presets.
-- Disabling the worker keeps the same numerical model/state on the main thread.
local enabled = createGlobalPropertyi("tu154/custom/elec/worker_enabled", 1)
local mode = createGlobalPropertyi("tu154/custom/elec/worker_mode", 0)
local lag = createGlobalPropertyi("tu154/custom/elec/worker_lag_frames", 0)
local batches = createGlobalPropertyi("tu154/custom/elec/worker_batches", 0)
local fallbacks = createGlobalPropertyi("tu154/custom/elec/worker_fallbacks", 0)
local batch_steps = createGlobalPropertyi("tu154/custom/elec/worker_last_batch_steps", 0)

local function capture()
    local inputs = {}
    for _, item in ipairs(Core.bindings) do
        inputs[item.key] = get(properties[item.key])
    end
    return inputs
end

local request_ref, response_ref
local transport = {}
function transport.ready()
    -- xTlua unregisters its owned mailboxes on plugin reload. Resolve before
    -- every access so a cached SASL wrapper cannot outlive that registration.
    local request, request_kind = sasl.findDataRef(Packet.REQUEST_PATH, TYPE_STRING, true)
    local response, response_kind = sasl.findDataRef(Packet.RESPONSE_PATH, TYPE_STRING, true)
    request_ref = request_kind == TYPE_STRING and request or nil
    response_ref = response_kind == TYPE_STRING and response or nil
    if not request_ref or not response_ref then
        return false
    end
    -- Native accessors return empty while xTlua is still starting or disabled.
    return sasl.getDataRefSize(request_ref) == Packet.CAPACITY and sasl.getDataRefSize(response_ref) == Packet.CAPACITY
end
function transport.read()
    -- SASL string positions are one-based; pass the complete fixed buffer.
    return sasl.getDataRef(response_ref, 1, Packet.CAPACITY)
end
function transport.write(packet)
    sasl.setDataRef(request_ref, packet, 1, Packet.CAPACITY)
end

local controller = Controller.new({
    initial = capture(),
    random = math.random,
    session = tostring(os.time()) .. "-" .. tostring(os.clock()) .. "-" .. tostring({}),
    transport = transport,
    report = function(message)
        logError("electric_worker.lua: " .. message)
    end,
})

function update()
    local inputs = capture()
    local outputs = controller:tick(inputs, get(enabled) == 1)
    -- All publication occurs inside this one SASL callback, before GPU sounds,
    -- failure logic and the panel are dispatched by electric_system.lua.
    for _, item in ipairs(Core.bindings) do
        local value = outputs[item.key]
        if value ~= nil then
            set(properties[item.key], value)
        end
    end
    set(mode, controller.mode) -- 0 local, 1 waiting, 2 worker results accepted
    set(lag, #controller.pending)
    set(batches, controller.batches)
    set(fallbacks, controller.fallbacks)
    set(batch_steps, controller.last_batch_steps)
end
