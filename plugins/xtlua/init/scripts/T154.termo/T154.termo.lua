-- T154.termo.lua
-- Outside-air temperature indicator, ported from SASL main_panel/termo.lua.
-- Keep the legacy per-frame Euler response on xTlua's classic MAIN runtime.
-- An independent worker would repeat/skip frame deltas and change the damping.

local find_datarefs = {
    { "thermo", "sim/cockpit2/temperature/outside_air_temp_degc" },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right" },
    { "sim_frame_period", "sim/operation/misc/frame_rate_period" },
    { "sim_paused", "sim/time/paused" },
    { "thermo_outside", "tu154/custom/gauges/misc/thermo_outside" },
}

-- SASL still creates the output; no duplicate writable DataRef is registered.
-- The script environment owns global properties, not the bootstrap's parent _G.
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

local termENG_act = -55
local function datarefs_ready()
    for _, handle in ipairs(dataref_handles) do
        if XLuaGetDataRefType(handle) ~= "number" then return false end
    end
    return true
end

function update_thermo()
    if not datarefs_ready() then return end

    -- Equivalent to SASL time_logic.lua, without depending on plugin update order.
    -- Classic SIM_PERIOD is fixed at 0.02 and must not be used as frame duration.
    local passed = sim_frame_period
    if sim_paused ~= 0 or passed ~= passed or passed < 0 or passed == math.huge then
        passed = 0
    end
    passed = math.min(passed, 0.1)

    local therm = -55
    if bus27_volt_right > 13 then therm = thermo end
    if therm ~= therm then return end
    if therm > 115 then therm = 115 elseif therm < -55 then therm = -55 end

    termENG_act = termENG_act + (therm - termENG_act) * passed * 5
    thermo_outside = termENG_act
end

-- Zero interval is a supported classic-main timer: one call per pre-frame,
-- including replay and pause. The pause guard above freezes the needle.
-- Do NOT also call update_thermo from after_physics (that would integrate twice).
-- The host owns/cancels this timer when the module is unloaded or reloaded.
run_at_interval(update_thermo, 0)
