-- absu_at.lua
-- Auto-throttle (AT) logic for Tu-154M (X-Plane 11)
-- Refactored for clarity and efficiency; functionality preserved.

-----------------------------------------------------------------------
-- Smartcopilot (kept on top, not part of bulk definitions)
-----------------------------------------------------------------------
defineProperty("ismaster",    globalPropertyf("scp/api/ismaster"))   -- 0 = plugin not found, 1 = slave, 2 = master
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1")) -- 1 = no control, 2 = has control

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function decay(x, rate, dt)
	return x - x * rate * dt
end

local function defineProps(defs)
	for _, d in ipairs(defs) do
		defineProperty(d[1], d[3](d[2]))
	end
end

-----------------------------------------------------------------------
-- Bulk DataRef definitions
-----------------------------------------------------------------------
defineProps({
	-- sources
	{"ias_left", "tu154/custom/gauges/speed/ias_left", globalPropertyf},     -- captain IAS
	{"ias_right", "tu154/custom/gauges/speed/ias_right", globalPropertyf},   -- FO IAS
	-- controls
	{"absu_speed_change", "tu154/custom/switchers/console/absu_speed_change", globalPropertyi},        -- speed change handle
	{"absu_speed_off", "tu154/custom/switchers/console/absu_speed_off", globalPropertyi},              -- AT channel off: 1 = off ch1, -1 = off ch2
	{"absu_speed_prepare", "tu154/custom/switchers/console/absu_speed_prepare", globalPropertyi},      -- AT prepare
	{"absu_speed_us_right_left", "tu154/custom/switchers/console/absu_speed_us_right_left", globalPropertyi}, -- source selector (left/right)
	{"absu_stab_speed", "tu154/custom/buttons/console/absu_stab_speed", globalPropertyi},              -- "C" button on ABSU panel
	{"absu_throt_off_1", "tu154/custom/buttons/console/absu_throt_off_1", globalPropertyi},            -- disconnect throttle 1
	{"absu_throt_off_2", "tu154/custom/buttons/console/absu_throt_off_2", globalPropertyi},            -- disconnect throttle 2
	{"absu_throt_off_3", "tu154/custom/buttons/console/absu_throt_off_3", globalPropertyi},            -- disconnect throttle 3
	-- throttle levers (normalized)
	{"anim_rud1", "tu154/custom/controlls/throttle_1", globalPropertyf},
	{"anim_rud2", "tu154/custom/controlls/throttle_2", globalPropertyf},
	{"anim_rud3", "tu154/custom/controlls/throttle_3", globalPropertyf},
	-- throttle commands (SC-safe)
	{"tro_comm_1", "tu154/custom/SC/engine/ENGN_thro_0", globalPropertyf},
	{"tro_comm_2", "tu154/custom/SC/engine/ENGN_thro_1", globalPropertyf},
	{"tro_comm_3", "tu154/custom/SC/engine/ENGN_thro_2", globalPropertyf},
	-- arrows (needles) logic from console
	{"absu_nav_on", "tu154/custom/switchers/console/absu_nav_on", globalPropertyi},                    -- NAV arrows enabled
	{"absu_landing_on", "tu154/custom/switchers/console/absu_landing_on", globalPropertyi},            -- LAND arrows enabled
	-- main/sub modes from ABSU core
	{"roll_main_mode", "tu154/custom/absu/roll_main_mode", globalPropertyi},                           -- roll main mode: 0 off, 1 manual, 2 stabilizer
	{"pitch_main_mode", "tu154/custom/absu/pitch_main_mode", globalPropertyi},                         -- pitch main mode: 0 off, 1 manual, 2 stabilizer
	{"roll_sub_mode", "tu154/custom/absu/roll_sub_mode", globalPropertyi},                             -- roll submode
	{"pitch_sub_mode", "tu154/custom/absu/pitch_sub_mode", globalPropertyi},                           -- pitch submode
	-- power
	{"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
	{"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
	{"bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf},
	{"bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf},
	{"absu_at_power_cc", "tu154/custom/absu_at_power_cc", globalPropertyf},                             -- AT current consumption (computed)
	-- timing
	{"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
	-- results (indications / outputs)
	{"ias_yellow_left", "tu154/custom/gauges/speed/ias_yellow_left", globalPropertyf},                 -- yellow marker on captain's IAS
	{"ias_yellow_right", "tu154/custom/gauges/speed/ias_yellow_right", globalPropertyf},               -- yellow marker on FO's IAS
	{"absu_at_dif_left", "tu154/custom/absu_at_dif_left", globalPropertyf},                            -- speed difference for PKP (left)
	{"absu_at_dif_right", "tu154/custom/absu_at_dif_right", globalPropertyf},                          -- speed difference for PKP (right)
	{"rud_1_spd", "tu154/custom/absu/rud_1_spd", globalPropertyf},                                     -- throttle change speed CH1
	{"rud_2_spd", "tu154/custom/absu/rud_2_spd", globalPropertyf},                                     -- throttle change speed CH2
	{"rud_3_spd", "tu154/custom/absu/rud_3_spd", globalPropertyf},                                     -- throttle change speed CH3
	{"stu_mode", "tu154/custom/absu/stu_mode", globalPropertyi},                                       -- AT modes: 0 off, 1 sync, 2 ready, 3 work, 4 TOGA
	{"toga_command", "tu154/custom/absu/toga_comm", globalPropertyi},                                  -- go-around command
	-- failures
	{"absu_at1_fail", "tu154/custom/failures/absu_at1_fail", globalPropertyi},
	{"absu_at2_fail", "tu154/custom/failures/absu_at2_fail", globalPropertyi},
	-- XP 11.10 fix selector
	{"sim_vers", "sim/version/xplane_internal_version", globalPropertyi},
})

-----------------------------------------------------------------------
-- Internal state
-----------------------------------------------------------------------
local AT_mode = 0                -- 0 = off, 1 = sync spd, 2 = prepare, 3 = work, 4 = TOGA
local spd_hold = 0               -- declared (kept; not used)
local IAS_smth = 0               -- smoothed IAS
local prepare_counter = 0
local rud_chng = false
local rud_last = get(tro_comm_1) + get(tro_comm_2) + get(tro_comm_3)
local rud_last_1 = get(tro_comm_1)
local rud_last_2 = get(tro_comm_2)
local rud_last_3 = get(tro_comm_3)
local marker_act_L = get(ias_left)
local marker_act_R = get(ias_right)

IAS_last = 0                     -- intentionally global (kept as in original)

local stab_counter = 0
local spd_diff_ind_L = 0
local spd_diff_ind_R = 0

-- constants (tuned to match original behavior)
local MAX_MARKER = 400
local MARKER_LERP_RATE = 2.0
local MARKER_ADJUST_RATE = 4.0
local DIFF_DECAY_RATE = 1.0
local THROTTLE_LIMIT = 0.4       -- max |rate| for main RUD speed
local THROTTLE_EDGE = 0.95       -- near full-forward block
local TOGA_DONE_FACTOR = 0.98    -- TOGA considered completed when levers reach 98% of active path
local TOGA_RUD_RATE = 0.4        -- TOGA lever advance rate
local ACTIVE_SCALER = 0.6        -- (at_1_work + at_2_work) multiplier

-----------------------------------------------------------------------
-- Command handlers: throttle up/down collapse (same logic)
-----------------------------------------------------------------------
local THR_dn = sasl.findCommand("sim/engines/throttle_down")
local THR_up = sasl.findCommand("sim/engines/throttle_up")

local function thr_common_handler(phase)
	if phase == 1 then
		if get(stu_mode) > 2 then set(stu_mode, 2) end
	end
	return 0
end

sasl.registerCommandHandler(THR_dn, 0, thr_common_handler)
sasl.registerCommandHandler(THR_up, 0, thr_common_handler)

-----------------------------------------------------------------------
-- Update loop
-----------------------------------------------------------------------
function update()
	-- Smartcopilot: treat "not slave" as write-enabled
	local MASTER = get(ismaster) ~= 1
	local passed = get(frame_time)

	-- inputs / switches
	local channel_off = get(absu_speed_off)                    -- 1 = off ch1, -1 = off ch2
	local prepare = get(absu_speed_prepare) == 1
	local stab_button = get(absu_stab_speed) == 1
	local source = 1 - get(absu_speed_us_right_left)           -- 0 = left, 1 = right

	-- power & channels
	local p27L = get(bus27_volt_left) > 13
	local p27R = get(bus27_volt_right) > 13
	local p36L = get(bus36_volt_left) > 30
	local p115 = get(bus115_1_volt) > 110
	local power = p36L and p115 and (p27L or p27R)

	local at_1_work = bool2int(p27L and channel_off ~= 1 and get(absu_at1_fail) == 0)
	local at_2_work = bool2int(p27R and channel_off ~= -1 and get(absu_at2_fail) == 0)

	-- working throttles (1 = active, 0 = disconnected)
	local rud_work_1 = (1 - get(absu_throt_off_1))
	local rud_work_2 = (1 - get(absu_throt_off_2))
	local rud_work_3 = (1 - get(absu_throt_off_3))

	-- current throttle commands (for change detection)
	local rud_now_1 = get(tro_comm_1)
	local rud_now_2 = get(tro_comm_2)
	local rud_now_3 = get(tro_comm_3)
	local rud_now = rud_now_1 + rud_now_2 + rud_now_3

	-- ABSU readiness (pitch required for TOGA)
	local stu_roll_ready = get(roll_main_mode) > 0 and get(absu_nav_on) == 1
	local stu_pitch_ready = get(pitch_main_mode) > 0 and get(absu_landing_on) == 1

	-- current mode from shared DR
	AT_mode = get(stu_mode)

	-------------------------------------------------------------------
	-- Mode state machine (order preserved)
	-------------------------------------------------------------------
	if not power then
		AT_mode = 0 -- off
	elseif at_1_work + at_2_work == 0 then
		AT_mode = -1 -- total fail
	elseif prepare_counter < 1 and power then
		AT_mode = 1 -- ON, not ready (sync)
	elseif power and prepare and prepare_counter >= 1 and AT_mode == 1 then
		AT_mode = 2 -- ready
	elseif power and prepare and (rud_work_1 + rud_work_2 + rud_work_3) > 1 and stab_button and AT_mode == 2 and stab_counter > 0.1 then
		AT_mode = 3 -- work (stabilize)
		rud_last = rud_now
		rud_last_1 = rud_now_1
		rud_last_2 = rud_now_2
		rud_last_3 = rud_now_3
		stab_counter = 0
	elseif power and prepare and AT_mode == 3 and stu_pitch_ready and get(pitch_sub_mode) == 6 then
		AT_mode = 4 -- TOGA
		rud_last = rud_now
		rud_last_1 = rud_now_1
		rud_last_2 = rud_now_2
		rud_last_3 = rud_now_3
		stab_counter = 0
	elseif (rud_work_1 + rud_work_2 + rud_work_3) < 2 and AT_mode >= 3 then
		AT_mode = 2 -- drop to ready if two RUDs are disconnected
		stab_counter = 0
	elseif rud_chng and AT_mode >= 3 then
		AT_mode = 2 -- drop to ready when pilot moves throttles
		stab_counter = 0
	elseif AT_mode == 4 and get(anim_rud1) > TOGA_DONE_FACTOR * rud_work_1 and get(anim_rud2) > TOGA_DONE_FACTOR * rud_work_2 and get(anim_rud3) > TOGA_DONE_FACTOR * rud_work_3 then
		AT_mode = 2 -- TOGA completed -> ready
		stab_counter = 0
	elseif stab_counter > 0.1 and stab_button and AT_mode > 2 then
		AT_mode = 2 -- cancel AT when button pressed again
		stab_counter = 0
	end

	-- stab button gate (count when released)
	if not stab_button then
		stab_counter = stab_counter + passed
	end

	-- publish mode back when allowed
	if MASTER then set(stu_mode, AT_mode) end

	-------------------------------------------------------------------
	-- Additional per-frame calculations
	-------------------------------------------------------------------
	-- prepare timing
	if power and prepare then
		prepare_counter = prepare_counter + passed
	else
		prepare_counter = 0
	end
	if prepare_counter > 1 then prepare_counter = 1 end

	-- detect manual throttle movement (two or more active levers moved > 0.1)
	local moved_1 = bool2int(math.abs(rud_last_1 - rud_now_1) > 0.25 and rud_work_1 == 1)
	local moved_2 = bool2int(math.abs(rud_last_2 - rud_now_2) > 0.25 and rud_work_2 == 1)
	local moved_3 = bool2int(math.abs(rud_last_3 - rud_now_3) > 0.25 and rud_work_3 == 1)
	local rud_moved = moved_1 + moved_2 + moved_3
	if rud_moved > 1 then
		rud_last = rud_now
		rud_last_1 = rud_now_1
		rud_last_2 = rud_now_2
		rud_last_3 = rud_now_3
		rud_chng = true
	else
		rud_chng = false
	end

	-- IAS and markers
	local IAS = get(ias_left)
	if source == 1 then IAS = get(ias_right) end

	-- current markers from DRs
	marker_act_L = get(ias_yellow_left)
	marker_act_R = get(ias_yellow_right)

	-- smooth IAS
	IAS_smth = lerp(IAS_smth, IAS, passed * MARKER_LERP_RATE)

	-------------------------------------------------------------------
	-- Throttle and speed control per mode
	-------------------------------------------------------------------
	if AT_mode == 1 or AT_mode == 2 then
		-- sync markers to current IAS
		marker_act_L = lerp(marker_act_L, IAS_smth, passed * MARKER_LERP_RATE)
		marker_act_R = lerp(marker_act_R, IAS_smth, passed * MARKER_LERP_RATE)

		-- no throttle movement
		set(rud_1_spd, 0)
		set(rud_2_spd, 0)
		set(rud_3_spd, 0)

		-- decay speed-diff indications
		spd_diff_ind_L = decay(spd_diff_ind_L, DIFF_DECAY_RATE, passed)
		spd_diff_ind_R = decay(spd_diff_ind_R, DIFF_DECAY_RATE, passed)

	elseif AT_mode == 3 then
		-- work mode: operator adjusts selected-side marker; other side follows IAS
		local work_spd
		if source == 0 then
			-- left side controlled
			marker_act_L = marker_act_L + get(absu_speed_change) * passed * MARKER_ADJUST_RATE
			marker_act_R = lerp(marker_act_R, IAS_smth, passed * MARKER_LERP_RATE)
			work_spd = marker_act_L
			spd_diff_ind_L = IAS_smth - marker_act_L
			spd_diff_ind_R = decay(spd_diff_ind_R, DIFF_DECAY_RATE, passed)
		else
			-- right side controlled
			marker_act_R = marker_act_R + get(absu_speed_change) * passed * MARKER_ADJUST_RATE
			marker_act_L = lerp(marker_act_L, IAS_smth, passed * MARKER_LERP_RATE)
			work_spd = marker_act_R
			spd_diff_ind_L = decay(spd_diff_ind_L, DIFF_DECAY_RATE, passed)
			spd_diff_ind_R = IAS_smth - marker_act_R
		end

		-- PD controller on IAS error and derivative
		local P = work_spd - IAS_smth
		local D = 0
		if passed ~= 0 then D = (IAS_smth - IAS_last) / passed end
		IAS_last = IAS_smth

		local K_P = 0.015
		local K_D = -0.11
		if get(sim_vers) >= 111000 then
			K_P = 0.008
			K_D = -0.05
		end

		local main_rud_spd = P * K_P + D * K_D
		main_rud_spd = clamp(main_rud_spd, -THROTTLE_LIMIT, THROTTLE_LIMIT)

		-- block further increase near full-forward
		local rud_current = (get(anim_rud1) + get(anim_rud2) + get(anim_rud3)) / 3
		if rud_current > THROTTLE_EDGE and main_rud_spd > 0 then
			main_rud_spd = 0
		end

		-- add small channel spread to avoid perfect sync (as designed)
		local rud_spd_1 = main_rud_spd * math.random(98, 102) * 0.01
		local rud_spd_2 = main_rud_spd * math.random(98, 102) * 0.01
		local rud_spd_3 = main_rud_spd * math.random(98, 102) * 0.01

		if MASTER then
			local active = (at_1_work + at_2_work) * ACTIVE_SCALER
			set(rud_1_spd, rud_spd_1 * rud_work_1 * active)
			set(rud_2_spd, rud_spd_2 * rud_work_2 * active)
			set(rud_3_spd, rud_spd_3 * rud_work_3 * active)
		end

	elseif AT_mode == 4 then
		-- TOGA: markers follow IAS, levers advance at fixed rate
		marker_act_L = lerp(marker_act_L, IAS_smth, passed * MARKER_LERP_RATE)
		marker_act_R = lerp(marker_act_R, IAS_smth, passed * MARKER_LERP_RATE)

		if MASTER then
			local active = (at_1_work + at_2_work) * ACTIVE_SCALER
			set(rud_1_spd, TOGA_RUD_RATE * rud_work_1 * active)
			set(rud_2_spd, TOGA_RUD_RATE * rud_work_2 * active)
			set(rud_3_spd, TOGA_RUD_RATE * rud_work_3 * active)
		end

		spd_diff_ind_L = decay(spd_diff_ind_L, DIFF_DECAY_RATE, passed)
		spd_diff_ind_R = decay(spd_diff_ind_R, DIFF_DECAY_RATE, passed)

	else
		-- off / fail: no throttle movement, decay indications
		set(rud_1_spd, 0)
		set(rud_2_spd, 0)
		set(rud_3_spd, 0)

		spd_diff_ind_L = decay(spd_diff_ind_L, DIFF_DECAY_RATE, passed)
		spd_diff_ind_R = decay(spd_diff_ind_R, DIFF_DECAY_RATE, passed)
	end

	-- clamp markers
	marker_act_L = clamp(marker_act_L, 0, MAX_MARKER)
	marker_act_R = clamp(marker_act_R, 0, MAX_MARKER)

	-- write outputs guarded by MASTER
	if MASTER then
		set(ias_yellow_left, marker_act_L)
		set(ias_yellow_right, marker_act_R)

		-- Fake TOGA behavior outside mode 4 (tiny negative speed to keep levers alive)
		if get(toga_command) == 1 and AT_mode ~= 4 then
			set(rud_1_spd, -0.00001)
			set(rud_2_spd, -0.00001)
			set(rud_3_spd, -0.00001)
		end
	end

	-- write indications and power consumption
	set(absu_at_dif_left, spd_diff_ind_L)
	set(absu_at_dif_right, spd_diff_ind_R)
	set(absu_at_power_cc, bool2int(power and channel_off ~= 1) + bool2int(power and channel_off ~= -1))
end
