-- kskv_sard.lua
--
-- Changelog:
-- 	- Grouped all property bindings through a local defineProps() helper without changing names, paths, constructors, or order.
-- 	- Replaced Russian comments with English comments and cleaned up formatting.
-- 	- Fixed fast and window decompression so they are applied as altitude changes instead of absolute cabin altitudes.
-- 	- Prevented decompression overshoot by limiting interpolation steps to the 0..1 range.
-- 	- Limited the fast decompression coefficient to its intended 100..500 range.
-- 	- Made the pressure-regulator state deterministic on every frame.
-- 	- Prevented simultaneous decompression sources from stacking; the strongest active decompression rate is used.
-- 	- Restored Smart Copilot master-only writes for authoritative pressurization outputs.
--		- Reduced repeated property reads inside update().
-- 	- Clamped SARD panel brightness to the valid 0..1 range.
-- 	- Preserved existing pressure tables, thresholds, conversion factors, and currently unused bindings/state variables.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Time
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    -- Internal system state
    { "air_usage_L", "tu154/custom/bleed/air_usage_L", globalPropertyf },
    { "air_usage_R", "tu154/custom/bleed/air_usage_R", globalPropertyf },
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "sard_panel_lit", "tu154/custom/lights/sard_panel_lit", globalPropertyf },
    { "start_sys_work", "tu154/custom/start/start_sys_work", globalPropertyf },
    -- Controls
    { "sard_cabin_press_set", "tu154/custom/switchers/sard/sard_cabin_press_set", globalPropertyf },
    { "sard_abs_press_set", "tu154/custom/switchers/sard/sard_abs_press_set", globalPropertyf },
    { "sard_diff_set", "tu154/custom/switchers/sard/sard_diff_set", globalPropertyf },
    { "sard_spd_set", "tu154/custom/switchers/sard/sard_spd_set", globalPropertyf },
    { "emerg_decompress", "tu154/custom/switchers/airbleed/emerg_decompress", globalPropertyi },
    { "sard_disable", "tu154/custom/switchers/eng/sard_disable", globalPropertyi },
    -- Windows and doors
    { "cockpit_window_left", "tu154/custom/anim/cockpit_window_left", globalPropertyf },
    { "cockpit_window_right", "tu154/custom/anim/cockpit_window_right", globalPropertyf },
    { "pax_door_1", "tu154/custom/anim/pax_door_1", globalPropertyf },
    { "pax_door_2", "tu154/custom/anim/pax_door_2", globalPropertyf },
    { "pax_door_3", "tu154/custom/anim/pax_door_3", globalPropertyf },
    -- Failures
    { "sard_valve_fail", "tu154/custom/failures/sard_valve_fail", globalPropertyi },
    -- Aircraft state
    { "msl_alt", "sim/flightmodel/position/elevation", globalPropertyf },
    { "msl_press", "sim/weather/barometer_sealevel_inhg", globalPropertyf },
    -- Pressurization outputs
    { "dump_to_altitude_on", "sim/cockpit2/pressurization/actuators/dump_to_altitude_on", globalPropertyi },
    { "cabin_altitude_ft", "sim/cockpit2/pressurization/actuators/cabin_altitude_ft", globalPropertyf },
    { "cabin_vvi_fpm", "sim/cockpit2/pressurization/actuators/cabin_vvi_fpm", globalPropertyf },
    { "dump_all_on", "sim/cockpit2/pressurization/actuators/dump_all_on", globalPropertyi },
    -- Current pressurization state
    { "cabin_alt_now_ft", "sim/cockpit2/pressurization/indicators/cabin_altitude_ft", globalPropertyf },
    { "pressure_diff_psi", "sim/cockpit2/pressurization/indicators/pressure_diffential_psi", globalPropertyf },
 --   { "acf_has_press_controls", "sim/aircraft/view/acf_has_press_controls", globalPropertyf },
    -- Smart Copilot
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf },
})

-- set(acf_has_press_controls, 1)

local press_alt_tbl = {
    { -100000, 1000000 }, -- Lower guard point for interpolation.
    { 525, 3000 },
    { 560, 2500 },
    { 597, 2000 },
    { 635, 1500 },
    { 674, 1000 },
    { 714, 500 },
    { 760, 0 },
    { 806, -500 },
    { 10000000, -100000 }, -- Upper guard point for interpolation.
}

local press_reg = 0 -- Pressure valve position: 0 = closed, 1 = fully open.
local cab_alt_need = -200
local decomp_last = 0

function update()
    local passed = get(frame_time)
    local bus27_left = get(bus27_volt_left)
    local bus27_right = get(bus27_volt_right)
    local bus115_1 = get(bus115_1_volt)
    local power_L = bus27_left > 13
    local power_R = bus27_right > 13
    -- Calculate barometric aircraft altitude and current cabin altitude in meters.
    local acf_alt = get(msl_alt) + (29.92 - get(msl_press)) * 1000 * 0.3048
    local current_alt = get(cabin_alt_now_ft) * 0.3048
    local airflow = get(air_usage_L) + get(air_usage_R)
    local current_diff = get(pressure_diff_psi) * 0.0778
    local alt_set = interpolate(press_alt_tbl, get(sard_cabin_press_set))
    local diff_set = get(sard_diff_set)
    -- Preserve the existing natural equalization model while preventing an invalid step.
    local slow_decomp_coef = 1
    local slow_decomp_step = clamp(passed * slow_decomp_coef, 0, 1)
    local slow_decomp = (acf_alt - current_alt) * slow_decomp_step
    -- Preserve the existing airflow model and coefficient.
    local flow_alt_coef = 1
    local airflow_comp = (acf_alt - 10500 - current_alt) * passed * airflow * flow_alt_coef

    -- Determine the pressure-valve command from the current state only.
    local new_press_reg = 0
    if current_diff > diff_set then
        new_press_reg = 1
    elseif acf_alt < alt_set + 200 then
        new_press_reg = bool2int(current_alt < acf_alt - 200)
    elseif current_diff < diff_set then
        new_press_reg = bool2int(current_alt < alt_set)
    end
    press_reg = new_press_reg

    local start_sys = get(start_sys_work) == 1
    local emergency_dump = get(emerg_decompress) == 1
    local valve_available = get(sard_valve_fail) == 0 and get(sard_disable) == 0
    local fast_dump_active = (emergency_dump or press_reg == 1)
        and valve_available
        and power_R
        and not start_sys

    -- Limit the original altitude-dependent fast decompression coefficient
    -- to its intended range and convert it into a stable interpolation step.
    local fast_decomp_coef = clamp((acf_alt / 12000) * -400 + 500, 100, 500)
    local fast_decomp_step = 0
    if fast_dump_active then
        fast_decomp_step = clamp(passed * fast_decomp_coef, 0, 1)
    end

    local openings = get(cockpit_window_left)
        + get(cockpit_window_right)
        + get(pax_door_1)
        + get(pax_door_2)
        + get(pax_door_3)

    local windows_open = openings > 0.2
    local window_decomp_step = 0
    local cabin_vvi = 10000

    if windows_open then
        window_decomp_step = clamp(passed * 1000, 0, 1)
        cabin_vvi = 100000
    end

    -- First apply normal airflow and slow pressure equalization.
    local base_alt = current_alt + airflow_comp + slow_decomp

    -- Fast dump and open-window decompression both move the cabin toward
    -- outside pressure. Use the stronger active rate instead of stacking them.
    local decomp_step = math.max(fast_decomp_step, window_decomp_step)
    local sys_alt = base_alt
    if decomp_step > 0 then
        sys_alt = base_alt + (acf_alt - base_alt) * decomp_step
    end

    local dump_active = fast_dump_active or windows_open
    local MASTER = get(ismaster) ~= 1

    -- Pressurization commands are authoritative only on the Smart Copilot master.
    if MASTER then
        set(cabin_vvi_fpm, cabin_vvi)
        set(cabin_altitude_ft, sys_alt / 0.3048)
        set(dump_all_on, bool2int(dump_active))
    end

    -- Panel lighting is local visual state and may be updated on both instances.
    set(sard_panel_lit, clamp(bus115_1 / 115, 0, 1))
end
