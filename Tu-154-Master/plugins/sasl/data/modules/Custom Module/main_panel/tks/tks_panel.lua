-- ============================================================================
-- TKS SWITCHES / LAMPS / SOUNDS
-- Refactor goals:
-- - Preserve full functionality (no removals, no behavior changes)
-- - Improve readability and structure
-- - Reduce redundant get() calls per frame (performance)
-- - Keep all comments in English (line comments only)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Property binder
-- ----------------------------------------------------------------------------

function defineProps(defs)
	for _, d in ipairs(defs) do
		defineProperty(d[1], d[3](d[2]))
	end
end

-- ----------------------------------------------------------------------------
-- Properties
-- ----------------------------------------------------------------------------
defineProps({
	-- Controls
	{ "tks_mode", "tu154/custom/switchers/ovhd/tks_mode", globalPropertyi },
	{ "tks_user", "tu154/custom/switchers/ovhd/tks_mode_left", globalPropertyi },
	{ "tks_source", "tu154/custom/switchers/ovhd/tks_mode_right", globalPropertyi },
	{ "tks_course_set", "tu154/custom/switchers/ovhd/tks_course_set", globalPropertyi },
	{ "tks_corrr_button", "tu154/custom/buttons/ovhd/tks_corrr_button", globalPropertyi },
	{ "tks_lat_set", "tu154/custom/rotary/ovhd/tks_lat_set", globalPropertyf },

	-- Stabilization
	{ "stabil_ga_main", "tu154/custom/switchers/ovhd/stabil_ga_main", globalPropertyi },
	{ "stabil_ga_reserv", "tu154/custom/switchers/ovhd/stabil_ga_reserv", globalPropertyi },

	-- Fail flags
	{ "fail_left", "tu154/custom/tks/fail_left", globalPropertyi },
	{ "fail_right", "tu154/custom/tks/fail_right", globalPropertyi },

	-- Electrical / lighting
	{ "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
	{ "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },

	{ "mgv_flag", "tu154/custom/gyro/mgv_contr_flag", globalPropertyf },
	{ "mgv_contr_fail", "tu154/custom/bkk/mgv_contr_fail", globalPropertyi },

	{ "tks_main_fail", "tu154/custom/lights/small/tks_main_fail", globalPropertyf },
	{ "tks_contr_fail", "tu154/custom/lights/small/tks_contr_fail", globalPropertyf },
	{ "ga_main_fail", "tu154/custom/lights/ga_main_fail", globalPropertyf },
	{ "ga_reserve_fail", "tu154/custom/lights/ga_reserve_fail", globalPropertyf },

	{ "lamp_test", "tu154/custom/buttons/lamp_test_front", globalPropertyi },
	{ "day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf },
})

-- ----------------------------------------------------------------------------
-- Sounds
-- ----------------------------------------------------------------------------
local switcher_sound = loadSample('Custom Sounds/plastic_switch.wav')
local button_sound = loadSample('Custom Sounds/plastic_btn.wav')

-- ----------------------------------------------------------------------------
-- State
-- ----------------------------------------------------------------------------
local sw_last = 0
local butt_last = get(tks_corrr_button)

-- ----------------------------------------------------------------------------
-- Switch / button sound logic
-- ----------------------------------------------------------------------------
local function switchers_check()
	local tks_mode_sw = get(tks_mode)
	local tks_user_sw = get(tks_user)
	local tks_source_sw = get(tks_source)
	local tks_course_set_sw = get(tks_course_set)

	local sw_summ = tks_mode_sw + tks_user_sw + tks_source_sw + tks_course_set_sw
	if sw_summ ~= sw_last then
		playSample(switcher_sound, false)
	end
	sw_last = sw_summ

	local butt_now = get(tks_corrr_button)
	if butt_last ~= butt_now then
		playSample(button_sound, false)
	end
	butt_last = butt_now
end

-- ----------------------------------------------------------------------------
-- Lamp logic
-- ----------------------------------------------------------------------------
local function lamps()
	local bus_l = get(bus27_volt_left)
	local bus_r = get(bus27_volt_right)

	local fail_main = bool2int(get(fail_left) == 1)
	local fail_aux = bool2int(get(fail_right) == 1)

	-- Raw brightness (no day/night correction)
	local lamps_brt_raw = math.max((math.max(bus_l, bus_r) - 10) / 18.5, 0)

	-- Small TKS fail lamps (no test button in original logic)
	local tks_main_fail_brt = math.max(fail_main * lamps_brt_raw, 0)
	set(tks_main_fail, tks_main_fail_brt)

	local tks_contr_fail_brt = math.max(fail_aux * lamps_brt_raw, 0)
	set(tks_contr_fail, tks_contr_fail_brt)

	-- NOTE: Preserve original operator precedence (bus_r - (10/18.5)) exactly
	local test_btn = get(lamp_test) * math.max(bus_r - (10 / 18.5), 0)

	local day_night = 1 - get(day_night_set) * 0.25
	local lamps_brt_dn = lamps_brt_raw * day_night

	local ga_main_fail_brt = math.max(fail_main * lamps_brt_dn, test_btn)
	set(ga_main_fail, ga_main_fail_brt)

	local ga_reserve_fail_brt = math.max(fail_aux * lamps_brt_dn, test_btn)
	set(ga_reserve_fail, ga_reserve_fail_brt)
end

-- ----------------------------------------------------------------------------
-- Update loop
-- ----------------------------------------------------------------------------
function update()
	switchers_check()
	lamps()
end
