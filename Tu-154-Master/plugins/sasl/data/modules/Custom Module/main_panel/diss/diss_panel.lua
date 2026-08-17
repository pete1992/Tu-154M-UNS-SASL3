-- Ready for script

-- ============================================================================
-- DISS / NVU WIND INPUT & INDICATIONS
-- Refactor goals:
-- - Preserve full functionality (no removals, no behavior changes)
-- - Improve readability and structure
-- - Reduce redundant get() calls per frame (performance)
-- - Keep all comments in English (line comments only)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Property binder
-- ----------------------------------------------------------------------------
local function defineProps(defs)
	for _, d in ipairs(defs) do
		defineProperty(d[1], d[3](d[2]))
	end
end

-- ----------------------------------------------------------------------------
-- Properties
-- ----------------------------------------------------------------------------
defineProps({
	-- Controls
	{ "diss_on", "tu154/custom/switchers/ovhd/diss_on", globalPropertyi },
	{ "diss_mode", "tu154/custom/switchers/ovhd/diss_mode", globalPropertyi },
	{ "nvu_calc_set", "tu154/custom/switchers/ovhd/nvu_calc_set", globalPropertyi },

	{ "wind_set", "tu154/custom/rotary/console/wind_set", globalPropertyf },

	{ "wind_course_left", "tu154/custom/button/console/wind_course_left", globalPropertyi },
	{ "wind_course_ctr", "tu154/custom/button/console/wind_course_ctr", globalPropertyi },
	{ "wind_course_right", "tu154/custom/button/console/wind_course_right", globalPropertyi },

	{ "wind_spd_left", "tu154/custom/button/console/wind_spd_left", globalPropertyi },
	{ "wind_spd_ctr", "tu154/custom/button/console/wind_spd_ctr", globalPropertyi },
	{ "wind_spd_right", "tu154/custom/button/console/wind_spd_right", globalPropertyi },

	{ "test_lamps", "tu154/custom/buttons/lamp_test_front", globalPropertyi },
	{ "day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf },

	-- Electrical (kept even if not directly used in this script)
	{ "bus27_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
	{ "bus115_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
	{ "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
	{ "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },

	-- NVU / DISS values
	{ "diss_wind_course", "tu154/custom/nvu/diss_wind_course", globalPropertyf },
	{ "diss_wind_spd", "tu154/custom/nvu/diss_wind_spd", globalPropertyf },
	{ "diss_mode_set", "tu154/custom/nvu/diss_mode", globalPropertyi },

	-- Gauges / indicators
	{ "diss_abs_angle_1", "tu154/custom/gauges/misc/diss_abs_angle_1", globalPropertyf },
	{ "diss_abs_angle_10", "tu154/custom/gauges/misc/diss_abs_angle_10", globalPropertyf },
	{ "diss_abs_angle_100", "tu154/custom/gauges/misc/diss_abs_angle_100", globalPropertyf },

	{ "diss_plus_angle_1", "tu154/custom/gauges/misc/diss_plus_angle_1", globalPropertyf },
	{ "diss_plus_angle_10", "tu154/custom/gauges/misc/diss_plus_angle_10", globalPropertyf },

	{ "diss_minus_angle_1", "tu154/custom/gauges/misc/diss_minus_angle_1", globalPropertyf },
	{ "diss_minus_angle_10", "tu154/custom/gauges/misc/diss_minus_angle_10", globalPropertyf },

	{ "diss_wind_spd_1", "tu154/custom/gauges/misc/diss_wind_spd_1", globalPropertyf },
	{ "diss_wind_spd_10", "tu154/custom/gauges/misc/diss_wind_spd_10", globalPropertyf },
	{ "diss_wind_spd_100", "tu154/custom/gauges/misc/diss_wind_spd_100", globalPropertyf },

	-- Lamps
	{ "diss_memory", "tu154/custom/lights/diss_memory", globalPropertyf },

	-- Time / engine state
	{ "frame_time", "tu154/custom/time/frame_time", globalPropertyf },

	{ "eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalPropertyf },
	{ "eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalPropertyf },
	{ "eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalPropertyf },
})

-- ----------------------------------------------------------------------------
-- Samples
-- ----------------------------------------------------------------------------
local switcher_sound = loadSample("Custom Sounds/metal_switch.wav")
local button_sound = loadSample("Custom Sounds/plastic_btn.wav")

-- ----------------------------------------------------------------------------
-- State
-- ----------------------------------------------------------------------------
local notLoaded = true
local start_timer = 0

local sw_summ_last = 0
local but_summ_last = 0

-- ----------------------------------------------------------------------------
-- Logic
-- ----------------------------------------------------------------------------
local function sw_reset()
	-- Reset switches only when engines are not running
	if get(eng1_N1) < 5 and get(eng2_N1) < 5 and get(eng3_N1) < 5 then
		set(diss_on, 0)
		set(diss_mode, 0)
		set(nvu_calc_set, 0)
	end
	notLoaded = false
end

local function switchers()
	-- Play switch sound when any of the three switchers changed (sum-based detection)
	local diss_on_sw = get(diss_on)
	local diss_mode_sw = get(diss_mode)
	local nvu_mode_sw = get(nvu_calc_set)

	local summ = diss_on_sw + diss_mode_sw + nvu_mode_sw

	if summ ~= sw_summ_last then
		playSample(switcher_sound, false)
	end

	sw_summ_last = summ
end

local function buttons()
	-- Play button sound when any wind course/speed button changed (sum-based detection)
	local wind_course_left_sw = get(wind_course_left)
	local wind_course_ctr_sw = get(wind_course_ctr)
	local wind_course_right_sw = get(wind_course_right)

	local wind_spd_left_sw = get(wind_spd_left)
	local wind_spd_ctr_sw = get(wind_spd_ctr)
	local wind_spd_right_sw = get(wind_spd_right)

	local summ = wind_course_left_sw + wind_course_ctr_sw + wind_course_right_sw
	summ = summ + wind_spd_left_sw + wind_spd_ctr_sw + wind_spd_right_sw

	if summ ~= but_summ_last then
		playSample(button_sound, false)
	end

	but_summ_last = summ
end

local function lamps()
	-- Cache frequently used datarefs for this frame (no logic changes)
	local bus27_r = get(bus27_volt_right)
	local bus27_l = get(bus27_volt_left)

	local test_btn = get(test_lamps) * math.max((bus27_r - 10) / 18.5, 0)
	local day_night = 1 - get(day_night_set) * 0.25

	local lamps_brt = math.max((math.max(bus27_l, bus27_r) - 10) / 18.5, 0) * day_night

	local diss_mode_val = get(diss_mode_set)
	local diss_is_memory = bool2int(diss_mode_val == 2 or diss_mode_val == 10)

	local diss_memory_brt = math.max(diss_is_memory * lamps_brt, test_btn)
	set(diss_memory, diss_memory_brt)
end

-- ----------------------------------------------------------------------------
-- Update loop
-- ----------------------------------------------------------------------------
function update()
	local passed = get(frame_time)
	start_timer = start_timer + passed

	-- Initial reset after a short delay, preserving original behavior
	if notLoaded and start_timer > 0.3 then
		sw_reset()
	end

	-- Wind correction angle (knob)
	local corr_angle = get(wind_set)

	-- Positive correction digits (uses original math/carry logic)
	local cor_plus_1 = math.max(-corr_angle, 0) % 10
	local cor_plus_10 = math.floor((math.max(-corr_angle, 0) % 100) * 0.1) + math.max(math.max((cor_plus_1 - 9), 0), 0)
	set(diss_plus_angle_1, cor_plus_1)
	set(diss_plus_angle_10, cor_plus_10)

	-- Negative correction digits (uses original math/carry logic)
	local cor_minus_1 = math.max(corr_angle, 0) % 10
	local cor_minus_10 = math.floor((math.max(corr_angle, 0) % 100) * 0.1) + math.max(math.max((cor_minus_1 - 9), 0), 0)
	set(diss_minus_angle_1, cor_minus_1)
	set(diss_minus_angle_10, cor_minus_10)

	-- Absolute wind course digits (apply correction and wrap 0..359)
	local wind_course = get(diss_wind_course) + corr_angle
	if wind_course >= 360 then
		wind_course = wind_course - 360
	elseif wind_course < 0 then
		wind_course = wind_course + 360
	end

	local wind_crs_1 = wind_course % 10
	local wind_crs_10 = math.floor((wind_course % 100) * 0.1) + math.max(math.max((wind_crs_1 - 9), 0), 0)
	local wind_crs_100 = math.floor((wind_course % 1000) * 0.01) + math.max(math.max((wind_crs_10 - 9), 0), 0)

	set(diss_abs_angle_1, wind_crs_1)
	set(diss_abs_angle_10, wind_crs_10)
	set(diss_abs_angle_100, wind_crs_100)

	-- Wind speed digits (uses original math/carry logic)
	local wind_speed = get(diss_wind_spd)

	local wind_spd_1 = wind_speed % 10
	local wind_spd_10 = math.floor((wind_speed % 100) * 0.1) + math.max(math.max((wind_spd_1 - 9), 0), 0)
	local wind_spd_100 = math.floor((wind_speed % 1000) * 0.01) + math.max(math.max((wind_spd_10 - 9), 0), 0)

	set(diss_wind_spd_1, wind_spd_1)
	set(diss_wind_spd_10, wind_spd_10)
	set(diss_wind_spd_100, wind_spd_100)

	-- Sounds and lamp brightness
	switchers()
	buttons()
	lamps()
end
