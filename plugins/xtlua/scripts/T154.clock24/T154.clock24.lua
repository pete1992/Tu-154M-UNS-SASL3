-- T154.clock24.lua
-- Rear-panel clock: numeric worker only; the cockpit OBJ still draws the hands.
-- Existing outputs are created by SASL dataref_creator_1.lua, not by this module.

-- SASL's main.lua seeded its RNG. This isolated worker VM needs its own seed;
-- otherwise every module reload would use LuaJIT's same default red-hand value.
math.randomseed(os.time())

local find_datarefs = {
    { "utc_time", "sim/time/zulu_time_sec" },
    { "clock_24_hours", "tu154/custom/gauges/clock_24_hours" },
    { "clock_24_mins", "tu154/custom/gauges/clock_24_mins" },
    { "clock_24_red", "tu154/custom/gauges/clock_24_red" },
}

-- Bind into the script namespace, not the bootstrap's parent _G table.
-- DataRef variables remain global; only their readiness handles are private.
local module_env = getfenv(1)
local dataref_handles = {}
local function bind_datarefs(definitions)
    for _, def in ipairs(definitions) do
        local property = find_dataref(def[2])
        dataref_handles[#dataref_handles + 1] = property.dref
        module_env[def[1]] = property
    end
end
bind_datarefs(find_datarefs)

local red_initialized = false
local function datarefs_ready()
    for _, handle in ipairs(dataref_handles) do
        if XTLuaGetDataRefType(handle) ~= "number" then return false end
    end
    return true
end

function after_physics()
    -- A deferred wrapper exists even before SASL creates the real output.
    -- Unresolved writes are dropped, so never consume the one-shot early.
    if not datarefs_ready() then return end

    local main_time = utc_time
    if main_time ~= main_time or math.abs(main_time) == math.huge then return end

    if not red_initialized then
        clock_24_red = math.random(360)
        red_initialized = true
    end

    -- Preserve the original unwrapped angles and the public minute-hand output.
    -- Do not continuously write the red hand: SmartCopilot can synchronize it.
    clock_24_mins = main_time * 0.1
    clock_24_hours = main_time * 360 / (60 * 60 * 24)
end

-- Ordinary flight starts do not reset the red hand. Only module reload does.
-- No SIM_PERIOD integration: worker callbacks are not simulator-frame callbacks.
