-- kskv_bleed.lua
-- KSKV air bleed logic
-- Notes:
-- * Frame caching, helper functions, and minor robustness (clamps) added.

-----------------------------------------------------------------------
-- Smartcopilot (keep separate)
-----------------------------------------------------------------------
defineProperty("ismaster", globalPropertyf("scp/api/ismaster"))
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1"))

-----------------------------------------------------------------------
-- Helper to bulk-define DataRefs
-----------------------------------------------------------------------
local function defineProps(defs)
	for _, d in ipairs(defs) do
		defineProperty(d[1], d[3](d[2]))
	end
end

-----------------------------------------------------------------------
-- DataRefs
-----------------------------------------------------------------------
defineProps({
	-- Engines / sources
	{"rpm_high_1", "tu154/custom/gauges/engine/rpm_high_1", globalPropertyf},
	{"rpm_high_2", "tu154/custom/gauges/engine/rpm_high_2", globalPropertyf},
	{"rpm_high_3", "tu154/custom/gauges/engine/rpm_high_3", globalPropertyf},
	{"asu_press", "tu154/custom/asu/press", globalPropertyf},
	{"apu_n1", "tu154/custom/eng/apu_n1", globalPropertyf},
	{"msl_alt", "sim/flightmodel/position/elevation", globalPropertyf},
	{"msl_press", "sim/weather/barometer_sealevel_inhg", globalPropertyf},
	-- Switches / controls
	{"psvp_left_on", "tu154/custom/switchers/airbleed/psvp_left_on", globalPropertyi},
	{"psvp_right_on", "tu154/custom/switchers/airbleed/psvp_right_on", globalPropertyi},
	{"psvp_left_on_cap", "tu154/custom/switchers/airbleed/psvp_left_on_cap", globalPropertyi},
	{"psvp_right_on_cap", "tu154/custom/switchers/airbleed/psvp_right_on_cap", globalPropertyi},
	{"air_valve_left", "tu154/custom/switchers/airbleed/air_valve_left", globalPropertyi},
	{"air_valve_right", "tu154/custom/switchers/airbleed/air_valve_right", globalPropertyi},
	{"emerg_decompress", "tu154/custom/switchers/airbleed/emerg_decompress", globalPropertyi},
	{"emerg_decompress_cap", "tu154/custom/switchers/airbleed/emerg_decompress_cap", globalPropertyi},
	{"eng_valve_1", "tu154/custom/switchers/airbleed/eng_valve_1", globalPropertyi},
	{"eng_valve_2", "tu154/custom/switchers/airbleed/eng_valve_2", globalPropertyi},
	{"eng_valve_3", "tu154/custom/switchers/airbleed/eng_valve_3", globalPropertyi},
	-- Failures
	{"airbleed_1", "tu154/custom/failures/airbleed_1", globalPropertyi},
	{"airbleed_2", "tu154/custom/failures/airbleed_2", globalPropertyi},
	{"airbleed_3", "tu154/custom/failures/airbleed_3", globalPropertyi},
	{"psvp_fail_left", "tu154/custom/failures/psvp_fail_left", globalPropertyi},
	{"psvp_fail_right", "tu154/custom/failures/psvp_fail_right", globalPropertyi},
	-- Gear / misc
	{"gear_defl", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalProperty},
	-- Outputs
	{"air_usage_L", "tu154/custom/bleed/air_usage_L", globalPropertyf},
	{"air_usage_R", "tu154/custom/bleed/air_usage_R", globalPropertyf},
	{"eng_airvalve_1", "tu154/custom/bleed/eng_airvalve_1", globalPropertyf},
	{"eng_airvalve_2", "tu154/custom/bleed/eng_airvalve_2", globalPropertyf},
	{"eng_airvalve_3", "tu154/custom/bleed/eng_airvalve_3", globalPropertyf},
	{"apu_air_doors", "tu154/custom/eng/apu_air_doors", globalPropertyf},
	-- Power
	{"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
	{"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
	-- Start system
	{"start_sys_work", "tu154/custom/start/start_sys_work", globalPropertyf},
	-- Sim actuators (SOVs)
	{"engine_bleed_sov_1", "sim/cockpit2/bleedair/actuators/engine_bleed_sov[0]", globalProperty},
	{"engine_bleed_sov_2", "sim/cockpit2/bleedair/actuators/engine_bleed_sov[1]", globalProperty},
	{"engine_bleed_sov_3", "sim/cockpit2/bleedair/actuators/engine_bleed_sov[2]", globalProperty},
	-- Time
	{"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
})

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------
local function bool2int(v) return v and 1 or 0 end

local function clamp(x, lo, hi)
	if x < lo then return lo end
	if x > hi then return hi end
	return x
end

-- Step engine bleed valve with command/fail/power logic (matches original behavior)
local function step_valve(val, cmd_on, failed, powered, dt, rate)
	-- cmd_on: 0/1 switch -> open(+)/close(-)
	if not powered then return val end
	if not failed then
		val = val + ((cmd_on * 2 - 1) * dt * rate)
	else
		val = val - dt * rate
	end
	if val > 1 then val = 1
	elseif val < 0 then val = 0 end
	return val
end

-- PSVP regulator around target flow window [FLOW_LO..FLOW_HI]
local function update_psvp(psvp, powered_ok, flow, dt, track_rate, decay_k, FLOW_LO, FLOW_HI)
	if not powered_ok then
		psvp = psvp + dt -- drift up when unpowered (as in original)
	else
		if flow < FLOW_LO then
			psvp = psvp + dt * track_rate
		elseif flow > FLOW_HI then
			psvp = psvp - dt * (flow - FLOW_HI) * decay_k
		end
	end
	if psvp > 1 then psvp = 1
	elseif psvp < 0 then psvp = 0 end
	return psvp
end

-----------------------------------------------------------------------
-- Constants (documenting original numeric values)
-----------------------------------------------------------------------
local VALVE_RATE = 0.2
local MAIN_VLV_RATE = 0.1
local MAIN_VLV_CLOSE_RATE = 0.2
local PSVP_TRACK_RATE = 0.05
local PSVP_DECAY_K = 0.1
local FLOW_LO = 590
local FLOW_HI = 620
local SMOOTH_STEP = 0.1
local SMOOTH_MAX = 0.2
local INIT_DELAY = 0.3
local RPM_IDLE = 10

-----------------------------------------------------------------------
-- Tables
-----------------------------------------------------------------------
local air_usage_tbl = {
	{ -100000, 0.0 },
	{ 0, 0 },
	{ 60, 250 },
	{ 65, 400 },
	{ 70, 600 },
	{ 80, 1010 },
	{ 85, 1100 },
	{ 90, 1190 },
	{ 95, 1270 },
	{ 100, 1320 },
	{ 10000000, 1500 },
}

-----------------------------------------------------------------------
-- State
-----------------------------------------------------------------------
local passed = get(frame_time)
local main_valve_L = 1
local main_valve_R = 1
local psvp_L = 1
local psvp_R = 1
local flow_left = 0
local flow_right = 0
local smooth_vlv = 0
local counter = 0
local notLoaded = true

local function reset_vars()
	if get(rpm_high_1) < RPM_IDLE and get(rpm_high_2) < RPM_IDLE and get(rpm_high_3) < RPM_IDLE then
		main_valve_L = 0
		main_valve_R = 0
		psvp_L = 0
		psvp_R = 0
		flow_left = 0
		flow_right = 0
		smooth_vlv = 0
	end
	notLoaded = false
end

-----------------------------------------------------------------------
-- Update
-----------------------------------------------------------------------
function update()
	passed = get(frame_time)
	counter = counter + passed
	if counter > INIT_DELAY and notLoaded then reset_vars() end

	local MASTER = get(ismaster) ~= 1
	if MASTER then
	-------------------------------------------------------------------
	-- Frame-cached inputs
	-------------------------------------------------------------------
		local power_L = get(bus27_volt_left) > 13
		local power_R = get(bus27_volt_right) > 13
		local cmd_v1 = get(eng_valve_1)
		local cmd_v2 = get(eng_valve_2)
		local cmd_v3 = get(eng_valve_3)
		local valve_1 = get(eng_airvalve_1)
		local valve_2 = get(eng_airvalve_2)
		local valve_3 = get(eng_airvalve_3)
		local valve_fail_1 = get(airbleed_1) == 1
		local valve_fail_2 = get(airbleed_2) == 1
		local valve_fail_3 = get(airbleed_3) == 1
		local apu_doors = get(apu_air_doors)
		local apu_n1_v = get(apu_n1)
		local asu_p = get(asu_press)
		local alt_msl = get(msl_alt)
		local qnh_inHg = get(msl_press)

		local start_sys = get(start_sys_work) == 1
		local gear_defl_v = get(gear_defl)

	-------------------------------------------------------------------
	-- Valves (per engine) with power side & failure logic
	-------------------------------------------------------------------
		valve_1 = step_valve(valve_1, cmd_v1, valve_fail_1, power_L, passed, VALVE_RATE)
		valve_2 = step_valve(valve_2, cmd_v2, valve_fail_2, power_R, passed, VALVE_RATE)
		valve_3 = step_valve(valve_3, cmd_v3, valve_fail_3, power_R, passed, VALVE_RATE)

	-------------------------------------------------------------------
	-- Air mass flows
	-------------------------------------------------------------------
		-- Pressure altitude correction (clamped to [0..1] to avoid negatives at extreme altitudes)
		local acf_alt = alt_msl + (29.92 - qnh_inHg) * 1000 * 0.3048
		local alt_coef = clamp(1 - acf_alt / 22000, 0, 1)

		local eng_airflow_1 = valve_1 * interpolate(air_usage_tbl, get(rpm_high_1)) * alt_coef
		local eng_airflow_2 = valve_2 * interpolate(air_usage_tbl, get(rpm_high_2)) * alt_coef
		local eng_airflow_3 = valve_3 * interpolate(air_usage_tbl, get(rpm_high_3)) * alt_coef
		local eng_airflow_4 = (apu_doors * apu_n1_v * 11 * alt_coef) + asu_p * 111

	-------------------------------------------------------------------
	-- Main valves (left/right manifold)
	-------------------------------------------------------------------
		local main_vlv_power_L = bool2int(power_L)
		local main_vlv_power_R = bool2int(power_R)

		if not start_sys then
			main_valve_L = main_valve_L + get(air_valve_left) * passed * MAIN_VLV_RATE * main_vlv_power_L
			main_valve_R = main_valve_R + get(air_valve_right) * passed * MAIN_VLV_RATE * main_vlv_power_R
		else
			main_valve_L = main_valve_L - passed * MAIN_VLV_CLOSE_RATE * main_vlv_power_L
			main_valve_R = main_valve_R - passed * MAIN_VLV_CLOSE_RATE * main_vlv_power_R
		end
		main_valve_L = clamp(main_valve_L, 0, 1)
		main_valve_R = clamp(main_valve_R, 0, 1)

	-------------------------------------------------------------------
	-- PSVP regulators (left/right)
	-------------------------------------------------------------------
		local psvp_power_L = (get(psvp_left_on) == 1) and power_L and (get(psvp_fail_left) == 0)
		local psvp_power_R = (get(psvp_right_on) == 1) and power_R and (get(psvp_fail_right) == 0)

		psvp_L = update_psvp(psvp_L, psvp_power_L, flow_left, passed, PSVP_TRACK_RATE, PSVP_DECAY_K, FLOW_LO, FLOW_HI)
		psvp_R = update_psvp(psvp_R, psvp_power_R, flow_right, passed, PSVP_TRACK_RATE, PSVP_DECAY_K, FLOW_LO, FLOW_HI)

	-------------------------------------------------------------------
	-- Smooth valve assist (right side) – same logic, clamped
	-------------------------------------------------------------------
		local eng_start_sys = false
		if gear_defl_v > 0.05 and not eng_start_sys and power_R and not start_sys then
			smooth_vlv = smooth_vlv + passed * SMOOTH_STEP
		else
			smooth_vlv = smooth_vlv - passed * SMOOTH_STEP
		end
		smooth_vlv = clamp(smooth_vlv, 0, SMOOTH_MAX)

	-------------------------------------------------------------------
	-- Resulting flows (as in original)
	-------------------------------------------------------------------
		flow_left = (eng_airflow_1 + eng_airflow_2 * 0.5 + eng_airflow_4 * 0.5) * math.min(main_valve_L, psvp_L)
		flow_right = (eng_airflow_3 + eng_airflow_2 * 0.5 + eng_airflow_4 * 0.5) * math.min(main_valve_R + smooth_vlv, psvp_R + smooth_vlv, 1)

	-------------------------------------------------------------------
	-- Outputs
	-------------------------------------------------------------------
		set(eng_airvalve_1, valve_1)
		set(eng_airvalve_2, valve_2)
		set(eng_airvalve_3, valve_3)
		set(engine_bleed_sov_1, bool2int(valve_1 > 0.5))
		set(engine_bleed_sov_2, bool2int(valve_2 > 0.5))
		set(engine_bleed_sov_3, bool2int(valve_3 > 0.5))
		set(air_usage_L, flow_left)
		set(air_usage_R, flow_right)
	end
end
