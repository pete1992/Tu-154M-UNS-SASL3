-- antiice_fails.lua
-- Anti-ice failures: keep native failure enums separate from custom boolean failures.
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    { "failures_enabled", "tu154/custom/failures/failures_enabled", globalPropertyi },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    -- Smart Copilot
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    -- failures
    { "ppd_3_heat_fail", "tu154/custom/antiice/ppd_3_heat_fail", globalPropertyi },
    { "rel_ice_inlet_heat1", "sim/operation/failures/rel_ice_inlet_heat", globalPropertyi },
    { "rel_ice_inlet_heat2", "sim/operation/failures/rel_ice_inlet_heat2", globalPropertyi },
    { "rel_ice_inlet_heat3", "sim/operation/failures/rel_ice_inlet_heat3", globalPropertyi },
    { "rel_ice_pitot_heat1", "sim/operation/failures/rel_ice_pitot_heat1", globalPropertyi },
    { "rel_ice_pitot_heat2", "sim/operation/failures/rel_ice_pitot_heat2", globalPropertyi },
    { "rel_ice_pitot_heat_stby", "sim/operation/failures/rel_ice_pitot_heat_stby", globalPropertyi },
    { "rel_ice_surf_heat", "sim/operation/failures/rel_ice_surf_heat", globalPropertyi },
    { "rel_ice_surf_heat2", "sim/operation/failures/rel_ice_surf_heat2", globalPropertyi },
    { "rio_fail", "tu154/custom/failures/rio_fail", globalPropertyi },
    { "window_heat_fail_1", "tu154/custom/failures/window_heat_fail_1", globalPropertyi },
    { "window_heat_fail_2", "tu154/custom/failures/window_heat_fail_2", globalPropertyi },
    { "window_heat_fail_3", "tu154/custom/failures/window_heat_fail_3", globalPropertyi },
    -- sources
    { "deflection_mtr_2", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalProperty },
    { "deflection_mtr_3", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", globalProperty },
    -- Probe power: PPD 1 uses the left bus, PPD 2 and 3 use the right bus.
    { "pitot_heat_1", "tu154/custom/switchers/ovhd/pitot_heat_1", globalPropertyi },
    { "pitot_heat_2", "tu154/custom/switchers/ovhd/pitot_heat_2", globalPropertyi },
    { "pitot_heat_3", "tu154/custom/switchers/ovhd/pitot_heat_3", globalPropertyi },
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
})

local fail_counter = 0
local check_time = math.random(15, 30)
-- aux vars
local ppd1_counter = 0
local ppd2_counter = 0
local ppd3_counter = 0
local wing_counter = 0
local stab_counter = 0

-- Only energized probes on the ground can accumulate heat-soak exposure.
-- Flight, OFF, TEST, loss of power or an open heater circuit reset exposure.
local function probe_heat_counter(counter, switch, bus, failed, on_ground, passed)
    if not on_ground or get(switch) ~= 1 or get(bus) <= 13 or failed then return 0 end
    if passed ~= passed or passed < 0 or passed == math.huge then return counter end
    return counter + passed
end

-- Do not turn an unsuccessful random draw into a repair, or erase a scheduled
-- X-Plane failure. Native failures use 6; the custom PPD 3 flag uses 1.
local function random_probe_failure(property, failed_value, probability)
    if get(property) == 0 and math.random() < probability then
        set(property, failed_value)
    end
end

function update()
	local passed = get(frame_time)
if get(ismaster) ~= 1 then	
	local FAIL = get(failures_enabled)
	FAIL = FAIL * 0.05 * 4 ^ (FAIL * 0.5)
	if FAIL > 0 then
		local on_ground = get(deflection_mtr_2) + get(deflection_mtr_3) >= 0.02
		ppd1_counter = probe_heat_counter(ppd1_counter, pitot_heat_1, bus27_volt_left,
			get(rel_ice_pitot_heat1) == 6, on_ground, passed)
		ppd2_counter = probe_heat_counter(ppd2_counter, pitot_heat_2, bus27_volt_right,
			get(rel_ice_pitot_heat2) == 6, on_ground, passed)
		ppd3_counter = probe_heat_counter(ppd3_counter, pitot_heat_3, bus27_volt_right,
			get(ppd_3_heat_fail) ~= 0 or get(rel_ice_pitot_heat_stby) == 6, on_ground, passed)
		fail_counter = fail_counter + passed
		if fail_counter > check_time then
			fail_counter = 0
			check_time = math.random(15, 30)
			-- random failures
			if get(rel_ice_inlet_heat1) ~= 1 then set(rel_ice_inlet_heat1, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6) end
			if get(rel_ice_inlet_heat2) ~= 1 then set(rel_ice_inlet_heat2, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6) end
			if get(rel_ice_inlet_heat3) ~= 1 then set(rel_ice_inlet_heat3, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6) end
			random_probe_failure(rel_ice_pitot_heat1, 6, 0.00001 * FAIL * 0.3)
			random_probe_failure(rel_ice_pitot_heat2, 6, 0.00001 * FAIL * 0.3)
			random_probe_failure(ppd_3_heat_fail, 1, 0.00001 * FAIL * 0.3)
			if get(rel_ice_surf_heat) ~= 1 then set(rel_ice_surf_heat, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6) end
			if get(rel_ice_surf_heat2) ~= 1 then set(rel_ice_surf_heat2, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6) end
			if get(rio_fail) ~= 1 then set(rio_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(window_heat_fail_1) ~= 1 then set(window_heat_fail_1, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(window_heat_fail_2) ~= 1 then set(window_heat_fail_2, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(window_heat_fail_3) ~= 1 then set(window_heat_fail_3, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			-- dependent random
			if ppd1_counter > 1200 then random_probe_failure(rel_ice_pitot_heat1, 6, 0.1 * FAIL * 0.3) end
			if ppd2_counter > 1200 then random_probe_failure(rel_ice_pitot_heat2, 6, 0.1 * FAIL * 0.3) end
			if ppd3_counter > 1200 then random_probe_failure(ppd_3_heat_fail, 1, 0.1 * FAIL * 0.3) end
			if wing_counter > 90 and get(rel_ice_surf_heat) ~= 6 then set(rel_ice_surf_heat, bool2int(math.random() < 0.3 * FAIL * 0.3) * 6) end
			if stab_counter > 90 and get(rel_ice_surf_heat2) ~= 6 then set(rel_ice_surf_heat2, bool2int(math.random() < 0.3 * FAIL * 0.3) * 6) end
		end
		-- dependent failures --
		-- check ground
		if get(deflection_mtr_2) + get(deflection_mtr_3) < 0.02 then
			wing_counter = wing_counter + passed
			stab_counter = stab_counter + passed
		else
			wing_counter = 0
			stab_counter = 0			
		end
	else
		fail_counter = 0
		-- no failures enabled
		set(ppd_3_heat_fail, 0)
		set(rel_ice_inlet_heat1, 0)
		set(rel_ice_inlet_heat2, 0)
		set(rel_ice_inlet_heat3, 0)
		set(rel_ice_pitot_heat1, 0)
		set(rel_ice_pitot_heat2, 0)
		set(rel_ice_surf_heat, 0)
		set(rel_ice_surf_heat2, 0)
		set(rio_fail, 0)
		set(window_heat_fail_1, 0)
		set(window_heat_fail_2, 0)
		set(window_heat_fail_3, 0)
		-- reset variables
		ppd1_counter = 0
		ppd2_counter = 0
		ppd3_counter = 0
		wing_counter = 0
		stab_counter = 0
		end
	end
end
