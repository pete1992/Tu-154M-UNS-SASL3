-- T154.usvp.lua
-- Sole owner of the USVP true/ground-speed needle, formerly SASL usvp.lua.
-- DISS owns its measurements and warm-up; this instrument only consumes them.

local find_datarefs = {
    { "tas_svs", "tu154/custom/svs/true_airspeed" },
    { "diss_groundspeed", "tu154/custom/nvu/diss_groundspeed" },
    { "diss_cc", "tu154/custom/nvu/diss_cc" },
    { "diss_mode", "tu154/custom/nvu/diss_mode" },
    { "speed_mid_flag", "tu154/custom/gauges/speed/speed_mid_flag" },
    { "speed_mid_needle", "tu154/custom/gauges/speed/speed_mid_needle" },
    { "sim_frame_period", "sim/operation/misc/frame_rate_period" },
    { "sim_paused", "sim/time/paused" },
}

-- Bind global proxies in this module's namespace, not the bootstrap parent _G.
-- SASL retains DataRef creation; never register a second copy of the output.
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

local speed_act = 0
local function datarefs_ready()
    for _, handle in ipairs(dataref_handles) do
        if XLuaGetDataRefType(handle) ~= "number" then return false end
    end
    return true
end

function update_usvp()
    if not datarefs_ready() then return end

    -- Match SASL time_logic's frame-duration bounds and pause behavior.
    local passed = sim_frame_period
    if sim_paused ~= 0 or passed ~= passed or passed < 0 or passed == math.huge then
        passed = 0
    end
    passed = math.min(passed, 0.1)

    local ground_selected = speed_mid_flag == 1
    local spd = tas_svs
    if ground_selected then spd = diss_groundspeed end
    if spd ~= spd or math.abs(spd) == math.huge then return end

    -- Keep the original filter running behind the warm-up mask. There is only
    -- one final needle write, so callback ordering can no longer cause flicker.
    speed_act = speed_act + (spd - speed_act) * passed * 5
    local angle = speed_act / 1000 * 360
    if ground_selected and diss_cc > 0 and diss_mode == 0 then angle = 0 end

    -- Do not wrap/clamp at 360: T154.zmisc derives the 1000-km/h flag from it.
    -- Compute on both SmartCopilot peers; the source values, not this output,
    -- are synchronized. Original USVP had no master-only authority gate.
    speed_mid_needle = angle
end

-- Per-frame classic MAIN timer preserves Euler damping and runs in replay.
-- No after_physics duplicate; the host cancels this timer on module unload.
run_at_interval(update_usvp, 0)
