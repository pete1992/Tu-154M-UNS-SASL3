-- this is ABSU modes logic

local function defineProps(defs)
	for _, d in ipairs(defs) do
		defineProperty(d[1], d[3](d[2]))
	end
end

defineProps({
-- controls
	{ "absu_zpu_sel", "tu154/custom/switchers/console/absu_zpu_sel", globalPropertyi }, --  .  -
	{ "absu_nav_on", "tu154/custom/switchers/console/absu_nav_on", globalPropertyi }, --
	{ "absu_landing_on", "tu154/custom/switchers/console/absu_landing_on", globalPropertyi }, --
	{ "absu_needles_on", "tu154/custom/switchers/console/absu_needles_on", globalPropertyi }, --
	{ "absu_speed_mode", "tu154/custom/switchers/console/absu_speed_mode", globalPropertyi }, --  . 0 - , 1 - , 2 - 1, 3 - 2, 4 -
	{ "absu_speed_change", "tu154/custom/switchers/console/absu_speed_change", globalPropertyi }, --   .
	{ "absu_speed_off", "tu154/custom/switchers/console/absu_speed_off", globalPropertyi }, --  1  2
	{ "absu_speed_prepare", "tu154/custom/switchers/console/absu_speed_prepare", globalPropertyi }, --
	{ "absu_speed_us_right_left", "tu154/custom/switchers/console/absu_speed_us_right_left", globalPropertyi }, --

	{ "absu_roll_ch_on", "tu154/custom/switchers/console/absu_roll_ch_on", globalPropertyi }, --
	{ "absu_pitch_ch_on", "tu154/custom/switchers/console/absu_pitch_ch_on", globalPropertyi }, --
	{ "absu_smooth_on", "tu154/custom/switchers/console/absu_smooth_on", globalPropertyi }, --  " "

	{ "absu_turn_handle", "tu154/custom/switchers/console/absu_turn_handle", globalPropertyi }, --
	{ "absu_pitch_wheel", "tu154/custom/switchers/console/absu_pitch_wheel", globalPropertyf }, --  ,

	{ "hydro_ra56_rud_1", "tu154/custom/switchers/eng/hydro_ra56_rud_1", globalPropertyi }, --  56
	{ "hydro_ra56_rud_2", "tu154/custom/switchers/eng/hydro_ra56_rud_2", globalPropertyi }, --  56
	{ "hydro_ra56_rud_3", "tu154/custom/switchers/eng/hydro_ra56_rud_3", globalPropertyi }, --  56

	{ "hydro_ra56_ail_1", "tu154/custom/switchers/eng/hydro_ra56_ail_1", globalPropertyi }, --  56
	{ "hydro_ra56_ail_2", "tu154/custom/switchers/eng/hydro_ra56_ail_2", globalPropertyi }, --  56
	{ "hydro_ra56_ail_3", "tu154/custom/switchers/eng/hydro_ra56_ail_3", globalPropertyi }, --  56

	{ "hydro_ra56_elev_1", "tu154/custom/switchers/eng/hydro_ra56_elev_1", globalPropertyi }, --  56
	{ "hydro_ra56_elev_2", "tu154/custom/switchers/eng/hydro_ra56_elev_2", globalPropertyi }, --  56
	{ "hydro_ra56_elev_3", "tu154/custom/switchers/eng/hydro_ra56_elev_3", globalPropertyi }, --  56

	{ "sau_stu_on", "tu154/custom/switchers/ovhd/sau_stu_on", globalPropertyi }, --

--defineProperty("tro_comm_1", globalProperty("sim/flightmodel/engine/ENGN_thro[0]"))
--defineProperty("tro_comm_2", globalProperty("sim/flightmodel/engine/ENGN_thro[1]"))
--defineProperty("tro_comm_3", globalProperty("sim/flightmodel/engine/ENGN_thro[2]"))

	{ "tro_comm_1", "tu154/custom/SC/engine/ENGN_thro_0", globalPropertyf },
	{ "tro_comm_2", "tu154/custom/SC/engine/ENGN_thro_1", globalPropertyf },
	{ "tro_comm_3", "tu154/custom/SC/engine/ENGN_thro_2", globalPropertyf },

-- buttons
	{ "absu_zk", "tu154/custom/buttons/console/absu_zk", globalPropertyi }, --
	{ "absu_reset", "tu154/custom/buttons/console/absu_reset", globalPropertyi }, --
	{ "absu_nvu", "tu154/custom/buttons/console/absu_nvu", globalPropertyi }, --
	{ "absu_az1", "tu154/custom/buttons/console/absu_az1", globalPropertyi }, --   1
	{ "absu_az2", "tu154/custom/buttons/console/absu_az2", globalPropertyi }, --   2
	{ "absu_app", "tu154/custom/buttons/console/absu_app", globalPropertyi }, --
	{ "absu_gs", "tu154/custom/buttons/console/absu_gs", globalPropertyi }, --
	{ "absu_stab_m", "tu154/custom/buttons/console/absu_stab_m", globalPropertyi }, --  M
	{ "absu_stab_v", "tu154/custom/buttons/console/absu_stab_v", globalPropertyi }, --  V
	{ "absu_stab_h", "tu154/custom/buttons/console/absu_stab_h", globalPropertyi }, --  H
	{ "absu_stab", "tu154/custom/buttons/console/absu_stab", globalPropertyi }, --

	{ "absu_arrest", "tu154/custom/buttons/console/absu_arrest", globalPropertyi }, --
	{ "absu_speed_test_1", "tu154/custom/buttons/console/absu_speed_test_1", globalPropertyi }, --
	{ "absu_speed_test_2", "tu154/custom/buttons/console/absu_speed_test_2", globalPropertyi }, --

	{ "absu_stab_speed", "tu154/custom/buttons/console/absu_stab_speed", globalPropertyi }, --  C
	{ "absu_throt_off_1", "tu154/custom/buttons/console/absu_throt_off_1", globalPropertyi }, --   1
	{ "absu_throt_off_2", "tu154/custom/buttons/console/absu_throt_off_2", globalPropertyi }, --   2
	{ "absu_throt_off_3", "tu154/custom/buttons/console/absu_throt_off_3", globalPropertyi }, --   3

-- power
	{ "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf }, --   27
	{ "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf }, --   27

	{ "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf }, --    115
	{ "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf }, --    115

	{ "bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf }, --   36
	{ "bus36_volt_right", "tu154/custom/elec/bus36_volt_right", globalPropertyf }, --   36
	{ "bus36_volt_pts250_1", "tu154/custom/elec/bus36_volt_pts250_1", globalPropertyf }, --   36  1
	{ "bus36_volt_pts250_2", "tu154/custom/elec/bus36_volt_pts250_2", globalPropertyf }, --   36  2

	{ "absu_power_cc", "tu154/custom/absu_power_cc", globalPropertyf }, --

-- other sources
-- The NVU-labelled button selects GPS1 for the HSI and ABSU.
	{ "nav_select", "tu154/custom/switchers/nav_select", globalPropertyi },
	{ "hsi_source_pilot", "sim/cockpit2/radios/actuators/HSI_source_select_pilot", globalPropertyi },
	{ "hsi_source_copilot", "sim/cockpit2/radios/actuators/HSI_source_select_copilot", globalPropertyi },
	{ "gps_power", "sim/cockpit2/radios/actuators/gps_power", globalPropertyi },
	{ "gps_fromto", "sim/cockpit/radios/gps_fromto", globalPropertyi },
	{ "gps_course", "sim/cockpit/radios/gps_course_degtm", globalPropertyf },
	{ "gps_dev", "sim/cockpit/radios/gps_hdef_dot", globalPropertyf },
	{ "gps_nm_per_dot", "sim/cockpit/radios/gps_hdef_nm_per_dot", globalPropertyf },
	{ "GNS430_dtk", "tu154/custom/SC/GNS430_dtk", globalPropertyf },
	{ "GNS430_dev", "tu154/custom/SC/GNS430_dev", globalPropertyf },
	{ "GNS430_flag", "tu154/custom/SC/GNS430_flag", globalPropertyi },
	{ "freq_1", "sim/cockpit2/radios/actuators/nav1_frequency_hz", globalPropertyf }, -- set the frequency
	{ "freq_2", "sim/cockpit2/radios/actuators/nav2_frequency_hz", globalPropertyf }, -- set the frequency

	{ "nav_cs_flag_1", "tu154/custom/radio/nav1_cs_flag", globalPropertyi },
	{ "nav_gs_flag_1", "tu154/custom/radio/nav1_gs_flag", globalPropertyi },

	{ "nav_cs_flag_2", "tu154/custom/radio/nav2_cs_flag", globalPropertyi },
	{ "nav_gs_flag_2", "tu154/custom/radio/nav2_gs_flag", globalPropertyi },

	{ "nav_gs_1", "tu154/custom/radio/nav1_gs", globalPropertyf }, -- glideslope
	{ "nav_gs_2", "tu154/custom/radio/nav2_gs", globalPropertyf },
	{ "nav_power_1", "tu154/custom/radio/nav1_pow_cc", globalPropertyf },
	{ "nav_power_2", "tu154/custom/radio/nav2_pow_cc", globalPropertyf },
	{ "nav_fail_1", "tu154/custom/failures/nav1_fail", globalPropertyi },
	{ "nav_fail_2", "tu154/custom/failures/nav2_fail", globalPropertyi },

	{ "svs_on", "tu154/custom/switchers/ovhd/svs_on", globalPropertyi }, --
	{ "svs_fail", "sim/operation/failures/rel_adc_comp", globalPropertyi }, -- static fail

	{ "rv5_alt", "tu154/custom/misc/rv5_alt_left", globalPropertyf }, --
	{ "rv_flag", "tu154/custom/gauges/alt/radioalt_flag_left", globalPropertyf }, -- RV flag

	{ "absu_course_out", "tu154/custom/absu_course_out", globalPropertyi }, -- flying outside the course limits
	{ "absu_gs_out", "tu154/custom/absu_gs_out", globalPropertyi }, -- flying outside the course limits

	{ "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- time of frame

-- Throttles
	{ "anim_rud1", "tu154/custom/controlls/throttle_1", globalPropertyf }, --  1
	{ "anim_rud2", "tu154/custom/controlls/throttle_2", globalPropertyf }, --  2
	{ "anim_rud3", "tu154/custom/controlls/throttle_3", globalPropertyf }, --  3
-- flaps
	{ "flap_inn_L", "sim/flightmodel/controls/wing1l_fla1def", globalPropertyf }, -- inner flaps left
	{ "flap_inn_R", "sim/flightmodel/controls/wing1r_fla1def", globalPropertyf }, -- inner flaps right

-- joystick
--defineProperty("joy_pitch", globalPropertyf("sim/cockpit2/controls/yoke_pitch_ratio")) -- pitch position of joytick
--defineProperty("joy_roll", globalPropertyf("sim/cockpit2/controls/yoke_roll_ratio")) -- roll position of joystick
--defineProperty("joy_yaw", globalPropertyf("sim/cockpit2/controls/yoke_heading_ratio")) -- yaw position of joystick

	{ "joy_pitch", "tu154/custom/SC/yoke_pitch_ratio", globalPropertyf },
	{ "joy_roll", "tu154/custom/SC/yoke_roll_ratio", globalPropertyf },
	{ "joy_yaw", "tu154/custom/SC/yoke_heading_ratio", globalPropertyf },

	{ "manip_pitch", "sim/cockpit2/controls/yoke_pitch_ratio", globalPropertyf },
	{ "manip_roll", "sim/cockpit2/controls/yoke_roll_ratio", globalPropertyf },

--sim/cockpit2/controls/yoke_roll_ratio	sim/cockpit2/controls/yoke_pitch_ratio

	{ "pkp_fail_left", "tu154/custom/gauges/ahz/ahz_flag_L", globalPropertyf }, --
	{ "pkp_fail_right", "tu154/custom/gauges/ahz/ahz_flag_R", globalPropertyf }, --
	{ "mgv_contr_fail", "tu154/custom/gyro/mgv_contr_flag", globalPropertyf }, --

	{ "pressure_ind_1", "tu154/custom/gauges/hydro/pressure_ind_1", globalPropertyf }, --    1
	{ "pressure_ind_2", "tu154/custom/gauges/hydro/pressure_ind_2", globalPropertyf }, --    2
	{ "pressure_ind_3", "tu154/custom/gauges/hydro/pressure_ind_3", globalPropertyf }, --    3

	{ "gs_press_1", "tu154/custom/hydro/gs_press_1", globalPropertyf }, --   1
	{ "gs_press_2", "tu154/custom/hydro/gs_press_2", globalPropertyf }, --   2
	{ "gs_press_3", "tu154/custom/hydro/gs_press_3", globalPropertyf }, --   3
	{ "gs_press_4", "tu154/custom/hydro/gs_press_4", globalPropertyf }, --   4

	{ "tks_fail_left", "tu154/custom/tks/fail_left", globalPropertyi }, --
	{ "tks_fail_right", "tu154/custom/tks/fail_right", globalPropertyi }, --

	{ "outer_marker", "sim/cockpit/misc/outer_marker_lit", globalPropertyi },

-- results
	{ "roll_main_mode", "tu154/custom/absu/roll_main_mode", globalPropertyi }, --     . 0 - , 1 -  - 2 -
	{ "pitch_main_mode", "tu154/custom/absu/pitch_main_mode", globalPropertyi }, --     . 0 - , 1 -  - 2 -

	{ "roll_sub_mode", "tu154/custom/absu/roll_sub_mode", globalPropertyi }, --    . 0 - , 1 - , 2 - , 3 - , 4 - 1, 5 - 2, 6 - , 7 - , 10
	{ "pitch_sub_mode", "tu154/custom/absu/pitch_sub_mode", globalPropertyi }, --    . 0 - , 1 - , 2 - V, 3 - M, 4 - H, 5 - , 6 - , 10 -

	{ "absu_pnp_mode_1", "tu154/custom/absu/absu_pnp_mode_1", globalPropertyi }, --   . 0 = off, 1 = , 2 = VOR1, 3 = VOR2, 4 =
	{ "absu_pnp_mode_2", "tu154/custom/absu/absu_pnp_mode_2", globalPropertyi }, --   . 0 = off, 1 = , 2 = VOR1, 3 = VOR2, 4 =

	{ "autopilot_mode", "sim/cockpit/autopilot/autopilot_mode", globalPropertyi }, --

	{ "toga_command", "tu154/custom/absu/toga_comm", globalPropertyi }, --

	{ "absu_use_second_nav", "tu154/custom/absu_use_second_nav", globalPropertyi }, --

	{ "damp_roll_lamp", "tu154/custom/absu/damp_roll_lamp", globalPropertyi }, --
	{ "damp_pitch_lamp", "tu154/custom/absu/damp_pitch_lamp", globalPropertyi }, --
	{ "damp_yaw_lamp", "tu154/custom/absu/damp_yaw_lamp", globalPropertyi }, --
	{ "roll_contr_lamp", "tu154/custom/absu/roll_contr_lamp", globalPropertyi }, --
	{ "pitch_contr_lamp", "tu154/custom/absu/pitch_contr_lamp", globalPropertyi }, --
	{ "man_roll_lamp", "tu154/custom/absu/man_roll_lamp", globalPropertyi }, --
	{ "man_pitch_lamp", "tu154/custom/absu/man_pitch_lamp", globalPropertyi }, --
	{ "man_toga_lamp", "tu154/custom/absu/man_toga_lamp", globalPropertyi }, --
	{ "triangle_lamp_signal", "tu154/custom/absu/triangle_lamp_signal", globalPropertyi }, --

-- Smart Copilot
	{ "ismaster", "scp/api/ismaster", globalPropertyf }, -- Master. 0 = plugin not found, 1 = slave 2 = master
	{ "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- Have control. 0 = plugin not found, 1 = no control 2 = has control

-- failures
	{ "absu_ra56_roll_fail", "tu154/custom/failures/absu_ra56_roll_fail", globalPropertyi }, --  ra56
	{ "absu_ra56_pitch_fail", "tu154/custom/failures/absu_ra56_pitch_fail", globalPropertyi }, --  ra56
	{ "absu_ra56_yaw_fail", "tu154/custom/failures/absu_ra56_yaw_fail", globalPropertyi }, --  ra56

-- failures
	{ "absu_damp_roll_fail", "tu154/custom/failures/absu_damp_roll_fail", globalPropertyi }, --
	{ "absu_damp_pitch_fail", "tu154/custom/failures/absu_damp_pitch_fail", globalPropertyi }, --
	{ "absu_damp_yaw_fail", "tu154/custom/failures/absu_damp_yaw_fail", globalPropertyi }, --
	{ "absu_contr_roll_fail", "tu154/custom/failures/absu_contr_roll_fail", globalPropertyi }, --
	{ "absu_contr_pitch_fail", "tu154/custom/failures/absu_contr_pitch_fail", globalPropertyi }, --
	{ "absu_calc_toga_fail", "tu154/custom/failures/absu_calc_toga_fail", globalPropertyi }, --
	{ "absu_calc_roll_fail", "tu154/custom/failures/absu_calc_roll_fail", globalPropertyi }, --
	{ "absu_calc_pitch_fail", "tu154/custom/failures/absu_calc_pitch_fail", globalPropertyi }, --

	{ "absu_fail_signal", "tu154/custom/absu/absu_fail_signal", globalPropertyi }, --
})

local TOGA_mode = false
local TOGA_button = false
local AP_button = false

local roll_mode_main = 1
local pitch_mode_main = 1

local signal_timer = 0

TOGA_COMM = sasl.findCommand("sim/autopilot/take_off_go_around")

local thro_last_1 = get(tro_comm_1)
local thro_last_2 = get(tro_comm_2)
local thro_last_3 = get(tro_comm_3)

function TOGA_comm_hnd(phase)
	-- Handle a short press as well as a held TOGA button.
	if phase == SASL_COMMAND_BEGIN or phase == SASL_COMMAND_CONTINUE then
		TOGA_mode = true
		TOGA_button = true
		set(toga_command, 1)
	else
		set(toga_command, 0)
		TOGA_button = false
		--set(tro_comm_1, thro_last_1)
		--set(tro_comm_2, thro_last_2)
		--set(tro_comm_3, thro_last_3)
	end
	
	return 0
end

-- The Tu-154 ABSU handles TOGA; suppress the simulator autopilot action.
sasl.registerCommandHandler(TOGA_COMM, 1, TOGA_comm_hnd)

local AP_toggle = sasl.findCommand("sim/autopilot/fdir_toggle")

function AP_toggle_hnd(phase)
	if 0 == phase then
		if get(roll_main_mode) == 2 then set(roll_main_mode, 1) end
		if get(pitch_main_mode) == 2 then set(pitch_main_mode, 1) end
		AP_button = true
	elseif 1 == phase then
		AP_button = true
	else 
		AP_button = false
		--TOGA_mode = false
	end
	return 0
end

sasl.registerCommandHandler(AP_toggle, 0, AP_toggle_hnd)

local roll_submode = 1
local pitch_submode = 1

local sau_sw_last = get(sau_stu_on) == 1

local pitch_wheel_last = get(absu_pitch_wheel)

local land_sw_last = get(absu_landing_on) == 1

local power_counter = 0
local state_checked = false

local yoke_reset = false

-- Qualify acquisition and tolerate brief reception gaps, never hardware failures.
local ILS_ACQUIRE_TIME = 0.3
local ILS_LOSS_TIME = 1.0
local ils_source = get(absu_use_second_nav) == 1 and 2 or 1
local ils_frequency = nil
local loc_valid_time, gs_valid_time = 0, 0
local loc_loss_time, gs_loss_time = 0, 0
local app_button_last, gs_button_last = false, false
local gs_auto_armed = false

local function finite_number(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function gps1_ready()
	local fromto = get(gps_fromto)
	local scale = get(gps_nm_per_dot)
	return get(gps_power) > 0 and (fromto == 1 or fromto == 2)
		and get(GNS430_flag) == 0
		and finite_number(get(GNS430_dtk)) and finite_number(get(GNS430_dev))
		and finite_number(get(gps_course)) and finite_number(get(gps_dev))
		and finite_number(scale) and scale > 0
end

function update()
	
	thro_last_1 = get(tro_comm_1)
	thro_last_2 = get(tro_comm_2)
	thro_last_3 = get(tro_comm_3)
	
	set(autopilot_mode, 0)
	
local MASTER = get(ismaster) ~= 1	
if MASTER then	
	
	-- initial variables
	-- sync
	roll_mode_main = get(roll_main_mode)
	pitch_mode_main = get(pitch_main_mode)
	
	roll_submode = get(roll_sub_mode)
	pitch_submode = get(pitch_sub_mode)
	
	local sau_sw = get(sau_stu_on) == 1
	
	local power = get(bus27_volt_left) > 13 and get(bus27_volt_right) > 13 and get(bus115_3_volt) > 110 and get(bus36_volt_left) > 30 and get(bus36_volt_right) > 30 and get(bus36_volt_pts250_1) and sau_sw -- temp
	
	local passed = get(frame_time)
	if not finite_number(passed) or passed < 0 then passed = 0 end
	
	local stab_btn = get(absu_stab) == 1
	
	if stab_btn and not yoke_reset then
		set(manip_pitch, 0)
		set(manip_roll, 0)
	end
	yoke_reset = stab_btn
	
	local pitch_sw = get(absu_pitch_ch_on) == 1
	local roll_sw = get(absu_roll_ch_on) == 1
	
	local ail_hyd_sw = get(hydro_ra56_ail_1) + get(hydro_ra56_ail_2) + get(hydro_ra56_ail_3) > 1 and get(absu_ra56_roll_fail) < 2
	
	local elev_hyd_sw = get(hydro_ra56_elev_1) + get(hydro_ra56_elev_2) + get(hydro_ra56_elev_3) > 1 and get(absu_ra56_pitch_fail) < 2
	
	local rud_hyd_sw = get(hydro_ra56_rud_1) + get(hydro_ra56_rud_2) + get(hydro_ra56_rud_3) > 1 and get(absu_ra56_yaw_fail) < 2
	
	local roll_handle = get(absu_turn_handle)
	
	local rud_toga = get(anim_rud1) + get(anim_rud2) + get(anim_rud3) > 0.99 * 3
	
	local nav_prep = get(absu_nav_on) == 1
	local land_prep = get(absu_landing_on) == 1
	local gps_ready = gps1_ready()
	if power and not land_prep then
		-- HSI sources follow the ABSU source buttons, independently of Kontur.
		if get(absu_nvu) == 1 then
			set(nav_select, 1)
			set(hsi_source_pilot, 2)
			set(hsi_source_copilot, 2)
		elseif get(absu_az1) == 1 and nav_prep then
			set(hsi_source_pilot, 0)
			set(hsi_source_copilot, 0)
		elseif get(absu_az2) == 1 and nav_prep then
			set(hsi_source_pilot, 1)
			set(hsi_source_copilot, 1)
		end
	end
	
	local flaps = (get(flap_inn_L) + get(flap_inn_R)) / 2
	
	local reset_but = get(absu_reset) == 1
	
	-- conditions, when ABSU can work
	local absu_work_logic = true-- get(pkp_fail_left) + get(pkp_fail_right) + get(mgv_contr_fail) < 2
	absu_work_logic = absu_work_logic and bool2int(get(gs_press_1) > 100) + bool2int(get(gs_press_2) > 100) + bool2int(get(gs_press_3) > 100) >= 2
	absu_work_logic = absu_work_logic -- and sau_sw and get(tks_fail_left) + get(tks_fail_right) == 0
	
	local ahz_work = get(pkp_fail_left) + get(pkp_fail_right) + get(mgv_contr_fail) < 2
	
	-- general yoke mode enable
	if sau_sw ~= sau_sw_last and sau_sw then -- need to extend conditions
		if ail_hyd_sw and rud_hyd_sw and absu_work_logic then 
			roll_mode_main = 1 
			--roll_submode = 1
		end
		if elev_hyd_sw and absu_work_logic then 
			pitch_mode_main = 1 
			--pitch_submode = 1
		end
	end
	
	sau_sw_last = sau_sw
	
	-- roll part
	-- set stab mode
	if roll_mode_main == 1 and stab_btn and roll_sw then
		roll_mode_main = 2
		--roll_submode = 1
	end
	
	-- set yoke mode

	--if roll_mode_main == 2 and (math.abs(get(joy_roll)) > 0.2 or math.abs(get(joy_yaw)) > 0.2 or math.abs(get(joy_pitch)) > 0.2) then
	if roll_mode_main == 2 and math.abs(get(joy_roll)) > 0.2 then --or get(absu_contr_roll_fail) == 1) then
		roll_mode_main = 1
		--pitch_mode_main = 1
	end
	if pitch_mode_main == 2 and math.abs(get(joy_pitch)) > 0.2 then --or get(absu_contr_pitch_fail) == 1) then
		--roll_mode_main = 1
		pitch_mode_main = 1
		if pitch_submode >= 2 and pitch_submode <= 4 then pitch_submode = 1 end
	end
	
	if roll_mode_main == 2 and (not roll_sw or not ahz_work) then
		roll_mode_main = 1
		--pitch_mode_main = 1
	end
	
	-- check mode for once, after loading the acf
	power_counter = power_counter + passed
	
	if power_counter > 15 and not state_checked then
		if power and pitch_mode_main == 0 and roll_mode_main == 0 then 
			pitch_mode_main = 1
			roll_mode_main = 1
		end
		state_checked = true
	end
	
	-- reset mode, when no power or hydraulics
	if not power or not ail_hyd_sw or not rud_hyd_sw or not absu_work_logic then
		roll_mode_main = 0
	end

	if not power or not elev_hyd_sw or not absu_work_logic then
		pitch_mode_main = 0
	end
	
	-- Keep a captured approach on one receiver; NAV1 recovering must not switch
	-- an established NAV2 approach or invalidate it via unrelated NAV1 flags.
	local app_button = get(absu_app) == 1
	local gs_button = get(absu_gs) == 1
	local app_pressed = app_button and not app_button_last
	local gs_pressed = gs_button and not gs_button_last
	app_button_last, gs_button_last = app_button, gs_button
	local approach_captured = land_prep and (roll_submode == 6 or pitch_submode == 5)
	local nav1_ils = finite_number(get(freq_1)) and isILS(get(freq_1))
	local nav2_ils = finite_number(get(freq_2)) and isILS(get(freq_2))
	if ils_frequency == nil then ils_frequency = get(ils_source == 2 and freq_2 or freq_1) end
	if not approach_captured then
		local source = 1
		local armed_source_valid = (roll_submode == 10 or pitch_submode == 10)
			and (ils_source == 2 and nav2_ils or ils_source == 1 and nav1_ils)
			and get(ils_source == 2 and nav_cs_flag_2 or nav_cs_flag_1) == 0
		if not land_prep then
			-- Preserve the existing non-approach receiver fallback.
			if get(nav_cs_flag_1) == 1 and nav2_ils and get(nav_cs_flag_2) == 0 then source = 2 end
		elseif armed_source_valid then source = ils_source
		elseif not (nav1_ils and get(nav_cs_flag_1) == 0) and nav2_ils
			and (get(nav_cs_flag_2) == 0 or not nav1_ils) then source = 2 end
		local frequency = get(source == 2 and freq_2 or freq_1)
		if source ~= ils_source or frequency ~= ils_frequency then
			loc_valid_time, gs_valid_time = 0, 0
			loc_loss_time, gs_loss_time = 0, 0
		end
		ils_source, ils_frequency = source, frequency
	end
	set(absu_use_second_nav, bool2int(ils_source == 2))
	local selected_frequency = get(ils_source == 2 and freq_2 or freq_1)
	local ils_available = (ils_source == 2 and nav2_ils or ils_source == 1 and nav1_ils)
		and selected_frequency == ils_frequency
		and get(ils_source == 2 and nav_power_2 or nav_power_1) > 0
		and get(ils_source == 2 and nav_fail_2 or nav_fail_1) ~= 1
	local loc_valid = ils_available and get(ils_source == 2 and nav_cs_flag_2 or nav_cs_flag_1) == 0
	local gs_deviation = get(ils_source == 2 and nav_gs_2 or nav_gs_1)
	local gs_valid = ils_available and get(ils_source == 2 and nav_gs_flag_2 or nav_gs_flag_1) == 0
		and finite_number(gs_deviation)
	loc_valid_time = loc_valid and math.min(ILS_ACQUIRE_TIME, loc_valid_time + passed) or 0
	gs_valid_time = gs_valid and math.min(ILS_ACQUIRE_TIME, gs_valid_time + passed) or 0
	loc_loss_time = loc_valid and 0 or math.min(ILS_LOSS_TIME, loc_loss_time + passed)
	gs_loss_time = gs_valid and 0 or math.min(ILS_LOSS_TIME, gs_loss_time + passed)
	local loc_ready = loc_valid and loc_valid_time >= ILS_ACQUIRE_TIME
	local gs_ready = gs_valid and gs_valid_time >= ILS_ACQUIRE_TIME
	local loc_lost = not ils_available or loc_loss_time >= ILS_LOSS_TIME
	local gs_lost = not ils_available or gs_loss_time >= ILS_LOSS_TIME
	if app_pressed and land_prep then gs_auto_armed = true end
	if not power or not land_prep or reset_but or pitch_wheel_last ~= get(absu_pitch_wheel)
		or pitch_submode == 6 then gs_auto_armed = false end
	
	-- submodes
	if roll_mode_main > 0 then -- need to define cases more clearly
		if roll_submode == 0 then roll_submode = 1 end
		
		if reset_but or math.abs(roll_handle) > 1 then -- Explicit cancellation precedes capture.
			roll_submode = 1
		elseif get(absu_zk) == 1 and roll_mode_main == 2 then -- ZK mode
			roll_submode = 2
			
		elseif get(absu_nvu) == 1 and not land_prep then -- GPS1 tracking
			if gps_ready then
				roll_submode = 3
			else
				-- A selected but unavailable GPS must not leave VOR steering active.
				roll_submode = 1
				set(man_roll_lamp, 1)
				set(absu_fail_signal, 1)
			end
			
		elseif get(absu_az1) == 1 and nav_prep and not land_prep then -- AZ mode. works only with VOR freq.
			roll_submode = 4
			
		elseif get(absu_az2) == 1 and nav_prep and not land_prep then -- AZ mode. works only with VOR freq.
			roll_submode = 5
			
		elseif app_pressed and land_prep and loc_ready then -- APP mode
			roll_submode = 6
			
		elseif app_pressed and land_prep and roll_submode ~= 6 then -- Arm APP until reception is stable.
			roll_submode = 10
			
		elseif roll_submode == 10 and land_prep and loc_ready then -- Capture armed APP.
			roll_submode = 6
			
		elseif (roll_submode == 6 or roll_submode == 10) and roll_mode_main >= 1 and pitch_mode_main >= 1 and (rud_toga or TOGA_mode) then -- TOGA mode
			roll_mode_main = 2
			pitch_mode_main = 2
			roll_submode = 1
			pitch_submode = 6
		end
	
	else
		roll_submode = 0
	end
	
	-- A lost GPS solution releases GPS tracking without selecting the NVU computer.
	if roll_submode == 3 and not gps_ready then
		roll_submode = 1
		set(man_roll_lamp, 1)
		set(absu_fail_signal, 1)
	end
	-- reset cases for ROLL modes
	if roll_submode == 4 and roll_mode_main == 2 and (isILS(get(freq_1)) or get(nav_cs_flag_1) == 1) then -- AZ1
		roll_submode = 1
		--TOGA_mode = false
	elseif roll_submode == 5 and roll_mode_main == 2 and (isILS(get(freq_2)) or get(nav_cs_flag_2) == 1) then -- AZ2
		roll_submode = 1
		--TOGA_mode = false
	elseif roll_submode == 6 and (loc_lost or not land_prep) and pitch_submode == 5 and roll_mode_main == 2 then -- APP and GS
		roll_submode = 1
		roll_mode_main = 1
		--print("OOPS")
		if loc_lost then
			set(man_roll_lamp, 1)
			set(absu_fail_signal, 1)
		end
		--TOGA_mode = false
	elseif roll_submode == 6 and (loc_lost or not land_prep) then -- APP / flight director
		roll_submode = 1
		if loc_lost then
			set(man_roll_lamp, 1)
			set(absu_fail_signal, 1)
		end
		--TOGA_mode = false
		
	end
	
	-- pitch part
	-- set stab mode
	if pitch_mode_main == 1 and stab_btn and pitch_sw then
		pitch_mode_main = 2
		--pitch_submode = 1
	end
	
	-- set yoke mode
	if pitch_mode_main == 2 and (not pitch_sw or not ahz_work) then
		--roll_mode_main = 1
		pitch_mode_main = 1
		if pitch_submode >= 2 and pitch_submode <= 4 then
			pitch_submode = 1
			--roll_submode = 1
		end
	end
	
	local putch_wheel = get(absu_pitch_wheel)
	
	-- submodes
	if pitch_mode_main > 0 then
		if pitch_submode == 0 then pitch_submode = 1 end
		
		local svs = get(svs_on) == 1

		if pitch_wheel_last ~= putch_wheel or (reset_but and pitch_submode >= 5) then
			-- Pilot cancellation must also win on the acquisition frame.
			pitch_submode = 1
		elseif get(absu_stab_v) == 1 and pitch_mode_main == 2 and svs then -- Stab V mode
			pitch_submode = 2
		
		elseif get(absu_stab_m) == 1 and pitch_mode_main == 2 and svs then -- Stab M mode
			pitch_submode = 3
			
		elseif get(absu_stab_h) == 1 and pitch_mode_main == 2 and svs then -- Stab H mode
			pitch_submode = 4
			
		elseif gs_pressed and land_prep and gs_ready then -- GS mode
			pitch_submode = 5
			
		elseif gs_auto_armed and land_prep and gs_ready and roll_submode == 6
			and math.abs(gs_deviation) < 0.02 and flaps > 31 then -- auto GS, once per APP selection
			pitch_submode = 5
			
		elseif gs_pressed and land_prep and pitch_submode ~= 5 then -- Arm GS until reception is stable.
			pitch_submode = 10
			
		elseif pitch_submode == 10 and land_prep and gs_ready then -- Capture armed GS.
			pitch_submode = 5
			
		elseif pitch_mode_main == 1 and (pitch_submode == 2 or pitch_submode == 3 or pitch_submode == 4) then -- reset V M H modes, when MAN mode
			pitch_submode = 1
		
		end
	
	else 
		pitch_submode = 0
	end
	
	if reset_but then -- reset mode
		roll_submode = 1
		if pitch_submode < 2 or pitch_submode > 4 then
			pitch_submode = 1
		end
	end
	
	-- reset TOGA mode
	if pitch_submode ~= 6 then
		TOGA_mode = false
	end
	
	--print(TOGA_mode, "  ", pitch_submode, "  ", roll_submode)
	
	pitch_wheel_last = putch_wheel
	if pitch_submode == 5 or roll_submode ~= 6 and roll_submode ~= 10 then gs_auto_armed = false end
	if not land_prep then
		if roll_submode == 10 then roll_submode = 1 end
		if pitch_submode == 10 then pitch_submode = 1 end
	end
	
	-- reset some modes
	if (gs_lost or not land_prep) and pitch_submode == 5 then -- GS / flight director
		pitch_submode = 1
		pitch_mode_main = 1
		
		if gs_lost then
			set(man_pitch_lamp, 1)
			set(absu_fail_signal, 1)
		end
		
	end
	
	-- lamp signals
	set(damp_roll_lamp, bool2int(power and get(absu_damp_roll_fail) == 1))
	set(damp_pitch_lamp, bool2int(power and get(absu_damp_pitch_fail) == 1))
	set(damp_yaw_lamp, bool2int(power and get(absu_damp_yaw_fail) == 1))
	set(roll_contr_lamp, bool2int(power and get(absu_contr_roll_fail) == 1))
	set(pitch_contr_lamp, bool2int(power and get(absu_contr_pitch_fail) == 1))
	
	-- roll lamp
	if power and roll_mode_main == 2 then
		if get(absu_damp_roll_fail) == 1 or get(absu_contr_roll_fail) == 1 or (get(absu_calc_toga_fail) == 1 and pitch_submode == 6) or (get(absu_calc_roll_fail) == 1 and roll_submode > 1 and roll_submode ~= 10) 
		then
			set(man_roll_lamp, 1)
			set(absu_fail_signal, 1)
		end
	end
	
	if power and roll_mode_main == 2 then
		if (get(tks_fail_left) + get(tks_fail_right) == 2 and roll_submode > 1 and roll_submode ~= 10) or
			(get(nav_cs_flag_1) == 1 and roll_submode == 4) or
			(loc_lost and roll_submode == 6)
		then
			roll_submode = 1
			set(man_roll_lamp, 1)
			set(absu_fail_signal, 1)
		end
	end
	
	-- pitch lamp
	if power and pitch_mode_main == 2 then
		if get(absu_damp_pitch_fail) == 1 or get(absu_contr_pitch_fail) == 1 or 
			(get(absu_calc_toga_fail) == 1 and pitch_submode == 6) or 
			(get(absu_calc_pitch_fail) == 1 and pitch_submode > 1) 
		then
			pitch_mode_main = 1
			
			pitch_submode = 1
			
			set(man_pitch_lamp, 1)
			set(absu_fail_signal, 1)
		end	
	end
	
	if power and pitch_mode_main == 2 then
		if ((get(svs_fail) == 6 or get(svs_on) == 0) and (pitch_submode == 2 or pitch_submode == 3 or pitch_submode == 4)) or
			(pitch_submode == 5 and gs_lost)
			then
			pitch_submode = 1
			pitch_mode_main = 1
			set(man_pitch_lamp, 1)
			set(absu_fail_signal, 1)
		end
	end
	
	-- roll and pitch lamps on RV fail
	if power and pitch_mode_main == 2 then
		if get(rv_flag) == 1 and get(outer_marker) == 1 and roll_submode == 6 and pitch_submode == 5 then
			pitch_mode_main = 1
			roll_submode = 1
			pitch_submode = 1
			set(man_roll_lamp, 1)
			set(man_pitch_lamp, 1)
			set(absu_fail_signal, 1)
		end
	
	end
	
	-- TOGA lamp
	if power and pitch_submode == 6 then
		if get(absu_calc_toga_fail) == 1 or get(absu_damp_pitch_fail) == 1 then
			set(man_toga_lamp, 1)
			set(man_pitch_lamp, 1)
			set(man_roll_lamp, 1)
			set(absu_fail_signal, 1)
		end
	end
	
	-- triangle lamp
	if get(rv5_alt) < 60 and power and roll_submode == 6 and pitch_submode == 5 and (get(man_pitch_lamp) == 1 or get(man_roll_lamp) == 1 or get(absu_course_out) == 1 or get(absu_gs_out) == 1) then
		set(triangle_lamp_signal, 1)
	end
	
	-- end alarm
	if (get(absu_fail_signal) == 1 and signal_timer > 8) then
		set(absu_fail_signal, 0)
		signal_timer = 0
	end
	
	if get(absu_fail_signal) == 0 then
		signal_timer = 0
	end
	
	-- reset lamps and alarm
	if not power or TOGA_button or AP_button then
		set(absu_fail_signal, 0)
		set(man_roll_lamp, 0)
		set(man_pitch_lamp, 0)
		set(man_toga_lamp, 0)
		set(triangle_lamp_signal, 0)
		signal_timer = 0
		--print("reset" .. passed)
	end
	
	-- fail alarm logic
	if get(absu_fail_signal) == 1 then
		signal_timer = signal_timer + passed
	else signal_timer = 0
	end
	
	-- reset modes on failures or turned off sources
	if get(absu_damp_roll_fail) == 1 then roll_mode_main = 0 end -- roll damper fail
	if get(absu_damp_pitch_fail) == 1 then pitch_mode_main = 0 end -- roll damper fail
	if get(absu_contr_roll_fail) == 1 and roll_mode_main == 2 then roll_mode_main = 1 end -- roll controls fail
	if get(absu_contr_pitch_fail) == 1 and pitch_mode_main == 2 then pitch_mode_main = 1 end -- pitch controls fail
	if get(absu_calc_toga_fail) == 1 and roll_mode_main >=1 and pitch_mode_main >= 1 and pitch_submode == 6 then roll_mode_main = 1 pitch_mode_main = 1 end -- TOGA calc fail
	if get(absu_calc_roll_fail) == 1 and roll_mode_main >= 1 then roll_submode = 1 end -- STU roll fail
	if get(absu_calc_pitch_fail) == 1 and pitch_mode_main >= 1 then pitch_submode = 1 end -- STU pitch fail
	
	-----------------------
	-- full disable ABSU --
	if not ail_hyd_sw or not sau_sw then 
		roll_mode_main = 0
		roll_submode = 0
	end
	
	if not elev_hyd_sw or not sau_sw then
		pitch_mode_main = 0
		pitch_submode = 0
	end

	-- indication modes

	set(absu_pnp_mode_2, get(absu_speed_mode) * bool2int(power)) -- set Co-Pilot PNP right away.
	
	-- Captain PNP
	
	if reset_but or not power then
		set(absu_pnp_mode_1, 0) -- off mode
	elseif land_prep ~= land_sw_last and land_prep then
		set(absu_pnp_mode_1, 4) -- landing mode
	elseif get(absu_nvu) == 1 then
		set(absu_pnp_mode_1, 1) -- NAV mode
	elseif nav_prep and get(absu_az1) == 1 then
		set(absu_pnp_mode_1, 2) -- VOR 
	elseif nav_prep and get(absu_az2) == 1 then
		set(absu_pnp_mode_1, 3) -- VOR 
	end
	
	land_sw_last = land_prep
	
	-- set results
	set(roll_main_mode, roll_mode_main)
	set(pitch_main_mode, pitch_mode_main)

	set(roll_sub_mode, roll_submode)
	set(pitch_sub_mode, pitch_submode)
	
	--set(toga_command, bool2int(TOGA_mode))

	set(absu_power_cc, bool2int(power))

end

end

