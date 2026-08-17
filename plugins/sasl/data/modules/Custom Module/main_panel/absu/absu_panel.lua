-- absu_panel.lua

-----------------------------------------------------------------------
-- Smartcopilot (must stay at the top, not in the bulk list)
-----------------------------------------------------------------------
defineProperty("ismaster", globalPropertyf("scp/api/ismaster"))      -- 0 = not found, 1 = slave, 2 = master (project-specific)
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1")) -- 1 = no control, 2 = has control (project-specific)

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------
local function bool2int(v) -- convert boolean-like expression to 0/1
    return (v and 1) or 0
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
    -- timing
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf}, -- time of frame

    -- gauges (view modes)
    {"absu_roll_mode",  "tu154/custom/gauges/console/absu_roll_mode",  globalPropertyi}, -- ABSU roll mode: 0 off, 1 manual, 2 stabilize
    {"absu_pitch_mode", "tu154/custom/gauges/console/absu_pitch_mode", globalPropertyi}, -- ABSU pitch mode: 0 off, 1 manual, 2 stabilize

    -- console controls
    {"absu_zpu_sel",               "tu154/custom/switchers/console/absu_zpu_sel",               globalPropertyi}, -- ZPU selector: left-right
    {"absu_nav_on",                "tu154/custom/switchers/console/absu_nav_on",                globalPropertyi}, -- NAV needles prep
    {"absu_landing_on",            "tu154/custom/switchers/console/absu_landing_on",            globalPropertyi}, -- Landing needles prep
    {"absu_needles_on",            "tu154/custom/switchers/console/absu_needles_on",            globalPropertyi}, -- Needles visible
    {"absu_speed_mode",            "tu154/custom/switchers/console/absu_speed_mode",            globalPropertyi}, -- STU mode: 0 off, 1 NVU, 2 AZ1, 3 AZ2, 4 APP
    {"absu_speed_change",          "tu154/custom/switchers/console/absu_speed_change",          globalPropertyi}, -- Speed change knob
    {"absu_speed_off",             "tu154/custom/switchers/console/absu_speed_off",             globalPropertyi}, -- AT channel disable (1/2)
    {"absu_speed_prepare",         "tu154/custom/switchers/console/absu_speed_prepare",         globalPropertyi}, -- STU preparation
    {"absu_speed_us_right_left",   "tu154/custom/switchers/console/absu_speed_us_right_left",   globalPropertyi}, -- STU side select
    {"absu_roll_ch_on",            "tu154/custom/switchers/console/absu_roll_ch_on",            globalPropertyi}, -- Roll channel power
    {"absu_pitch_ch_on",           "tu154/custom/switchers/console/absu_pitch_ch_on",           globalPropertyi}, -- Pitch channel power
    {"absu_smooth_on",             "tu154/custom/switchers/console/absu_smooth_on",             globalPropertyi}, -- Turbulence smoothing
    {"absu_turn_handle",           "tu154/custom/switchers/console/absu_turn_handle",           globalPropertyi}, -- Turn handle (manual roll)
    {"absu_pitch_wheel",           "tu154/custom/switchers/console/absu_pitch_wheel",           globalPropertyf}, -- Pitch wheel position
    {"absu_pitch_wheel_dir",       "tu154/custom/switchers/console/absu_pitch_wheel_dir",       globalPropertyi}, -- Pitch wheel direction

    -- hydraulics RA56 (yaw/roll/pitch) power selects
    {"hydro_ra56_rud_1",  "tu154/custom/switchers/eng/hydro_ra56_rud_1",  globalPropertyi}, -- RA56 yaw channel hyd power 1
    {"hydro_ra56_rud_2",  "tu154/custom/switchers/eng/hydro_ra56_rud_2",  globalPropertyi}, -- RA56 yaw channel hyd power 2
    {"hydro_ra56_rud_3",  "tu154/custom/switchers/eng/hydro_ra56_rud_3",  globalPropertyi}, -- RA56 yaw channel hyd power 3
    {"hydro_ra56_ail_1",  "tu154/custom/switchers/eng/hydro_ra56_ail_1",  globalPropertyi}, -- RA56 roll channel hyd power 1
    {"hydro_ra56_ail_2",  "tu154/custom/switchers/eng/hydro_ra56_ail_2",  globalPropertyi}, -- RA56 roll channel hyd power 2
    {"hydro_ra56_ail_3",  "tu154/custom/switchers/eng/hydro_ra56_ail_3",  globalPropertyi}, -- RA56 roll channel hyd power 3
    {"hydro_ra56_elev_1", "tu154/custom/switchers/eng/hydro_ra56_elev_1", globalPropertyi}, -- RA56 pitch channel hyd power 1
    {"hydro_ra56_elev_2", "tu154/custom/switchers/eng/hydro_ra56_elev_2", globalPropertyi}, -- RA56 pitch channel hyd power 2
    {"hydro_ra56_elev_3", "tu154/custom/switchers/eng/hydro_ra56_elev_3", globalPropertyi}, -- RA56 pitch channel hyd power 3

    -- hydraulic crossfeed / longitudinal control (capt covers too)
    {"hydro_circuit_auto_man",     "tu154/custom/switchers/eng/hydro_circuit_auto_man",     globalPropertyi}, -- Automatic/manual ring
    {"hydro_long_control",         "tu154/custom/switchers/eng/hydro_long_control",         globalPropertyi}, -- Longitudinal controllability
    {"hydro_circuit_auto_man_cap", "tu154/custom/switchers/eng/hydro_circuit_auto_man_cap", globalPropertyi}, -- Cover state
    {"hydro_long_control_cap",     "tu154/custom/switchers/eng/hydro_long_control_cap",     globalPropertyi}, -- Cover state

    -- selectors
    {"ZK_select", "tu154/custom/switchers/ZK_select", globalPropertyi}, -- ZK selector
    {"nav_select", "tu154/custom/switchers/nav_select", globalPropertyi}, -- NAV source selector
    {"vbe_select", "tu154/custom/switchers/vbe_select", globalPropertyi}, -- VBE selector

    -- buttons on ABSU console
    {"absu_zk",          "tu154/custom/buttons/console/absu_zk",          globalPropertyi}, -- ZK button
    {"absu_reset",       "tu154/custom/buttons/console/absu_reset",       globalPropertyi}, -- Program reset
    {"absu_nvu",         "tu154/custom/buttons/console/absu_nvu",         globalPropertyi}, -- NVU
    {"absu_az1",         "tu154/custom/buttons/console/absu_az1",         globalPropertyi}, -- AZ1
    {"absu_az2",         "tu154/custom/buttons/console/absu_az2",         globalPropertyi}, -- AZ2
    {"absu_app",         "tu154/custom/buttons/console/absu_app",         globalPropertyi}, -- Approach
    {"absu_gs",          "tu154/custom/buttons/console/absu_gs",          globalPropertyi}, -- Glideslope
    {"absu_stab_m",      "tu154/custom/buttons/console/absu_stab_m",      globalPropertyi}, -- STAB M
    {"absu_stab_v",      "tu154/custom/buttons/console/absu_stab_v",      globalPropertyi}, -- STAB V
    {"absu_stab_h",      "tu154/custom/buttons/console/absu_stab_h",      globalPropertyi}, -- STAB H
    {"absu_stab",        "tu154/custom/buttons/console/absu_stab",        globalPropertyi}, -- STAB
    {"absu_arrest",      "tu154/custom/buttons/console/absu_arrest",      globalPropertyi}, -- MGV arrest
    {"absu_speed_test_1","tu154/custom/buttons/console/absu_speed_test_1",globalPropertyi}, -- STU test lower
    {"absu_speed_test_2","tu154/custom/buttons/console/absu_speed_test_2",globalPropertyi}, -- STU test upper
    {"absu_stab_speed",  "tu154/custom/buttons/console/absu_stab_speed",  globalPropertyi}, -- STAB C
    {"absu_throt_off_1", "tu154/custom/buttons/console/absu_throt_off_1", globalPropertyi}, -- Throttle 1 off
    {"absu_throt_off_2", "tu154/custom/buttons/console/absu_throt_off_2", globalPropertyi}, -- Throttle 2 off
    {"absu_throt_off_3", "tu154/custom/buttons/console/absu_throt_off_3", globalPropertyi}, -- Throttle 3 off

    -- caps on console
    {"absu_arrest_cap",        "tu154/custom/buttons/console/absu_arrest_cap",        globalPropertyi}, -- MGV arrest cap
    {"absu_smooth_on_cap",     "tu154/custom/switchers/console/absu_smooth_on_cap",   globalPropertyi}, -- Turbulence smoothing cap
    {"absu_speed_prepare_cap", "tu154/custom/switchers/console/absu_speed_prepare_cap", globalPropertyi}, -- STU prep cap
    {"absu_speed_off_cap",     "tu154/custom/switchers/console/absu_speed_off_cap",   globalPropertyi}, -- AT off cap

    -- small button lamps (ABSUs' own)
    {"absu_zk_lamp",        "tu154/custom/lights/button/absu_zk",        globalPropertyf},
    {"absu_reset_lamp",     "tu154/custom/lights/button/absu_reset",     globalPropertyf},
    {"absu_nvu_lamp",       "tu154/custom/lights/button/absu_nvu",       globalPropertyf},
    {"absu_az1_lamp",       "tu154/custom/lights/button/absu_az1",       globalPropertyf},
    {"absu_az2_lamp",       "tu154/custom/lights/button/absu_az2",       globalPropertyf},
    {"absu_app_lamp",       "tu154/custom/lights/button/absu_app",       globalPropertyf},
    {"absu_gz_lamp",        "tu154/custom/lights/button/absu_gz",        globalPropertyf},
    {"absu_stab_m_lamp",    "tu154/custom/lights/button/absu_stab_m",    globalPropertyf},
    {"absu_stab_v_lamp",    "tu154/custom/lights/button/absu_stab_v",    globalPropertyf},
    {"absu_stab_h_lamp",    "tu154/custom/lights/button/absu_stab_h",    globalPropertyf},
    {"absu_stab_lamp",      "tu154/custom/lights/button/absu_stab",      globalPropertyf},
    {"absu_stab_spd_lamp",  "tu154/custom/lights/button/absu_stab_spd",  globalPropertyf},
    {"absu_thro1_lamp",     "tu154/custom/lights/button/absu_thro1",     globalPropertyf},
    {"absu_thro2_lamp",     "tu154/custom/lights/button/absu_thro2",     globalPropertyf},
    {"absu_thro3_lamp",     "tu154/custom/lights/button/absu_thro3",     globalPropertyf},

    -- small status lamps (roll/pitch/TOGA/AT)
    {"stu_roll_lamp",    "tu154/custom/lights/small/stu_roll",    globalPropertyf}, -- Roll
    {"stu_pitch_lamp",   "tu154/custom/lights/small/stu_pitch",   globalPropertyf}, -- Pitch
    {"stu_toga_lamp",    "tu154/custom/lights/small/stu_toga",    globalPropertyf}, -- TOGA
    {"at_1_lamp",        "tu154/custom/lights/small/at_1",        globalPropertyf}, -- AT 1
    {"at_2_lamp",        "tu154/custom/lights/small/at_2",        globalPropertyf}, -- AT 2
    {"course_lim",       "tu154/custom/lights/course_lim",        globalPropertyf}, -- Course limit exceeded
    {"gs_lim",           "tu154/custom/lights/gs_lim",            globalPropertyf}, -- GS limit exceeded

    -- forward panel lamps
    {"wrong_trimm",         "tu154/custom/lights/wrong_trimm",         globalPropertyf}, -- False trim
    {"controll_roll",       "tu154/custom/lights/controll_roll",       globalPropertyf}, -- Control roll
    {"controll_pitch",      "tu154/custom/lights/controll_pitch",      globalPropertyf}, -- Control pitch
    {"yoke_sign",           "tu154/custom/lights/yoke_sign",           globalPropertyf}, -- Go-around cue in manual
    {"triangle",            "tu154/custom/lights/triangle",            globalPropertyf}, -- Integral signal light (blinker)
    {"controll_thrust",     "tu154/custom/lights/controll_thrust",     globalPropertyf}, -- Control thrust
    {"toga",                "tu154/custom/lights/toga",                globalPropertyf}, -- GO AROUND
    {"course",              "tu154/custom/lights/course",              globalPropertyf}, -- COURSE
    {"glideslope",          "tu154/custom/lights/glideslope",          globalPropertyf}, -- GLIDE
    {"zk_lamp",             "tu154/custom/lights/zk_lamp",             globalPropertyf}, -- ZK
    {"thrust_automat",      "tu154/custom/lights/thrust_automat",      globalPropertyf}, -- Autothrottle
    {"stab_roll",           "tu154/custom/lights/stab_roll",           globalPropertyf}, -- Roll stabilization
    {"stab_pitch",          "tu154/custom/lights/stab_pitch",          globalPropertyf}, -- Pitch stabilization
    {"nvu_lamp",            "tu154/custom/lights/nvu_lamp",            globalPropertyf}, -- NVU
    {"vor_lamp",            "tu154/custom/lights/vor_lamp",            globalPropertyf}, -- VOR
    {"stab_h",              "tu154/custom/lights/stab_h",              globalPropertyf}, -- STAB H
    {"stab_v",              "tu154/custom/lights/stab_v",              globalPropertyf}, -- STAB V
    {"stab_m",              "tu154/custom/lights/stab_m",              globalPropertyf}, -- STAB M
    {"pitch_control_fail",  "tu154/custom/lights/pitch_control_fail",  globalPropertyf}, -- Pitch control fail
    {"roll_control_fail",   "tu154/custom/lights/roll_control_fail",   globalPropertyf}, -- Roll control fail
    {"absu_work",           "tu154/custom/lights/absu_work",           globalPropertyf}, -- ABSU OK
    {"sns_lamp",            "tu154/custom/lights/sns_lamp",            globalPropertyf}, -- SNS lamp

    -- engineer panel lamps (RA56 channels)
    {"ra56_roll_fail_1",   "tu154/custom/lights/ra56_roll_fail_1",   globalPropertyf},
    {"ra56_roll_fail_2",   "tu154/custom/lights/ra56_roll_fail_2",   globalPropertyf},
    {"ra56_roll_fail_3",   "tu154/custom/lights/ra56_roll_fail_3",   globalPropertyf},
    {"ra56_pitch_fail_1",  "tu154/custom/lights/ra56_pitch_fail_1",  globalPropertyf},
    {"ra56_pitch_fail_2",  "tu154/custom/lights/ra56_pitch_fail_2",  globalPropertyf},
    {"ra56_pitch_fail_3",  "tu154/custom/lights/ra56_pitch_fail_3",  globalPropertyf},
    {"ra56_course_fail_1", "tu154/custom/lights/ra56_course_fail_1", globalPropertyf},
    {"ra56_course_fail_2", "tu154/custom/lights/ra56_course_fail_2", globalPropertyf},
    {"ra56_course_fail_3", "tu154/custom/lights/ra56_course_fail_3", globalPropertyf},
    {"eng_at_on_lamp",     "tu154/custom/lights/engines/eng_at_on",  globalPropertyf}, -- AT ON (engineers panel)

    -- other sources and modes
    {"lamp_test",        "tu154/custom/buttons/lamp_test_front", globalPropertyi}, -- Front panel lamp test
    {"day_night_set",    "tu154/custom/lights/day_night_set",    globalPropertyf}, -- 0 day, 1 night (dimming)
    {"lamp_test_eng",    "tu154/custom/buttons/lamp_test_pa56",  globalPropertyi}, -- Engineer panel lamp test
    {"roll_main_mode",   "tu154/custom/absu/roll_main_mode",     globalPropertyi}, -- ABSU main roll mode
    {"pitch_main_mode",  "tu154/custom/absu/pitch_main_mode",    globalPropertyi}, -- ABSU main pitch mode
    {"roll_sub_mode",    "tu154/custom/absu/roll_sub_mode",      globalPropertyi}, -- ABSU roll submode
    {"pitch_sub_mode",   "tu154/custom/absu/pitch_sub_mode",     globalPropertyi}, -- ABSU pitch submode
    {"stu_mode",         "tu154/custom/absu/stu_mode",           globalPropertyi}, -- AT modes: 0 off, 1 on, 2 ready, 3 hold, 4 go-around
    {"absu_pnp_mode_1",  "tu154/custom/absu/absu_pnp_mode_1",    globalPropertyi}, -- PNP indicator mode 1: 0 off, 1 NVU, 2 VOR1, 3 VOR2, 4 PS
    {"absu_pnp_mode_2",  "tu154/custom/absu/absu_pnp_mode_2",    globalPropertyi}, -- PNP indicator mode 2: 0 off, 1 NVU, 2 VOR1, 3 VOR2, 4 PS
    {"absu_course_out",  "tu154/custom/absu_course_out",         globalPropertyi}, -- Out of course limits
    {"absu_gs_out",      "tu154/custom/absu_gs_out",             globalPropertyi}, -- Out of GS limits

    -- flags and sensors
    {"pkp_fail_left",   "tu154/custom/gauges/ahz/ahz_flag_L",    globalPropertyf}, -- PKP left fail flag
    {"pkp_fail_right",  "tu154/custom/gauges/ahz/ahz_flag_R",    globalPropertyf}, -- PKP right fail flag
    {"mgv_contr_fail",  "tu154/custom/gyro/mgv_contr_flag",      globalPropertyf}, -- MGV control fail
    {"pressure_ind_1",  "tu154/custom/gauges/hydro/pressure_ind_1", globalPropertyf}, -- Hydraulic pressure 1
    {"pressure_ind_2",  "tu154/custom/gauges/hydro/pressure_ind_2", globalPropertyf}, -- Hydraulic pressure 2
    {"pressure_ind_3",  "tu154/custom/gauges/hydro/pressure_ind_3", globalPropertyf}, -- Hydraulic pressure 3

    -- STU/SAU power and TKS fail
    {"sau_stu_on",     "tu154/custom/switchers/ovhd/sau_stu_on", globalPropertyi}, -- SAU STU switch
    {"tks_fail_left",  "tu154/custom/tks/fail_left",             globalPropertyi}, -- TKS left fail
    {"tks_fail_right", "tu154/custom/tks/fail_right",            globalPropertyi}, -- TKS right fail

    -- trim system
    {"elev_trimm_switcher", "tu154/custom/controll/elev_trimm_switcher", globalPropertyi}, -- RV trim handle: -1 dive, 0 neutral, +1 climb
    {"emerg_elev_trimm",    "tu154/custom/switchers/console/emerg_elev_trimm", globalPropertyi}, -- Emergency trim
    {"bus27_volt_left",     "tu154/custom/elec/bus27_volt_left",  globalPropertyf},
    {"bus27_volt_right",    "tu154/custom/elec/bus27_volt_right", globalPropertyf},
    {"int_pitch_trim",      "tu154/custom/trimmers/int_pitch_trim", globalPropertyf}, -- Pitch trim position (internal)
    {"absu_pitch_trimm",    "tu154/custom/absu/absu_pitch_trimm",   globalPropertyi}, -- ABSU trim command: +1 up, -1 down

    -- engines N1
    {"eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalPropertyf}, -- Engine 1 N1
    {"eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalPropertyf}, -- Engine 2 N1
    {"eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalPropertyf}, -- Engine 3 N1

    -- ABSU internal lamp signals (logic inputs)
    {"damp_roll_lamp",     "tu154/custom/absu/damp_roll_lamp",   globalPropertyi},
    {"damp_pitch_lamp",    "tu154/custom/absu/damp_pitch_lamp",  globalPropertyi},
    {"damp_yaw_lamp",      "tu154/custom/absu/damp_yaw_lamp",    globalPropertyi},
    {"roll_contr_lamp",    "tu154/custom/absu/roll_contr_lamp",  globalPropertyi},
    {"pitch_contr_lamp",   "tu154/custom/absu/pitch_contr_lamp", globalPropertyi},
    {"man_roll_lamp",      "tu154/custom/absu/man_roll_lamp",    globalPropertyi},
    {"man_pitch_lamp",     "tu154/custom/absu/man_pitch_lamp",   globalPropertyi},
    {"man_toga_lamp",      "tu154/custom/absu/man_toga_lamp",    globalPropertyi},
    {"triangle_lamp_signal","tu154/custom/absu/triangle_lamp_signal", globalPropertyi},

    -- failures
    {"absu_ra56_roll_fail",  "tu154/custom/failures/absu_ra56_roll_fail",  globalPropertyi}, -- RA56 roll channel fail
    {"absu_ra56_pitch_fail", "tu154/custom/failures/absu_ra56_pitch_fail", globalPropertyi}, -- RA56 pitch channel fail
    {"absu_ra56_yaw_fail",   "tu154/custom/failures/absu_ra56_yaw_fail",   globalPropertyi}, -- RA56 yaw channel fail
    {"absu_at1_fail",        "tu154/custom/failures/absu_at1_fail",        globalPropertyi}, -- AT1 fail
    {"absu_at2_fail",        "tu154/custom/failures/absu_at2_fail",        globalPropertyi}, -- AT2 fail
    {"absu_damp_roll_fail",  "tu154/custom/failures/absu_damp_roll_fail",  globalPropertyi}, -- Dampers roll fail
    {"absu_damp_pitch_fail", "tu154/custom/failures/absu_damp_pitch_fail", globalPropertyi}, -- Dampers pitch fail
    {"absu_damp_yaw_fail",   "tu154/custom/failures/absu_damp_yaw_fail",   globalPropertyi}, -- Dampers yaw fail
    {"absu_contr_roll_fail", "tu154/custom/failures/absu_contr_roll_fail", globalPropertyi}, -- Lateral control fail
    {"absu_contr_pitch_fail","tu154/custom/failures/absu_contr_pitch_fail",globalPropertyi}, -- Longitudinal control fail
    {"absu_calc_toga_fail",  "tu154/custom/failures/absu_calc_toga_fail",  globalPropertyi}, -- TOGA computer fail
    {"absu_calc_roll_fail",  "tu154/custom/failures/absu_calc_roll_fail",  globalPropertyi}, -- STU roll channel fail
    {"absu_calc_pitch_fail", "tu154/custom/failures/absu_calc_pitch_fail", globalPropertyi}, -- STU pitch channel fail
})

-----------------------------------------------------------------------
-- State
-----------------------------------------------------------------------
local passed = get(frame_time)
local notLoaded = true
local start_timer = 0
local elev_tr_last = get(int_pitch_trim)
local stu_test_1_cntr = 0
local stu_test_2_cntr = 0
local triangle_timer = 0
local triangle_lit = 0

-----------------------------------------------------------------------
-- Sounds
-----------------------------------------------------------------------
local switcher_sound = loadSample('Custom Sounds/metal_switch.wav')
local button_sound   = loadSample('Custom Sounds/plastic_btn.wav')
local cap_sound      = loadSample('Custom Sounds/cap.wav')

-----------------------------------------------------------------------
-- Init helper
-----------------------------------------------------------------------
local function sw_reset()
    -- Reset switches if all engines are stopped
    if get(eng1_N1) < 5 and get(eng2_N1) < 5 and get(eng3_N1) < 5 then
        set(absu_needles_on, 0)
        set(absu_nav_on, 0)
        set(absu_speed_prepare, 0)
        set(absu_roll_ch_on, 0)
        set(absu_pitch_ch_on, 0)
    end
    notLoaded = false
end

-----------------------------------------------------------------------
-- UI sound handlers
-----------------------------------------------------------------------
local button_summ_last = 0
local function buttons()
    -- Sum of all momentary buttons for edge-detect sound triggering
    local summ =  get(absu_zk) + get(absu_reset) + get(absu_nvu) + get(absu_az1) + get(absu_az2) + get(absu_app)
    summ = summ + get(absu_gs) + get(absu_stab_m) + get(absu_stab_v) + get(absu_stab_h) + get(absu_stab)
    summ = summ + get(absu_arrest) + get(absu_speed_test_1) + get(absu_speed_test_2)
    summ = summ + get(absu_stab_speed) + get(absu_throt_off_1) + get(absu_throt_off_2) + get(absu_throt_off_3) + get(lamp_test_eng)

    if button_summ_last ~= summ then
        playSample(button_sound, false)
    end
    button_summ_last = summ
end

local switchers_summ = 0
local function switchers()
    -- Sum of all latching switch positions for edge-detect sound
    local summ =  get(absu_zpu_sel) + get(absu_nav_on) + get(absu_landing_on) + get(absu_needles_on) + get(absu_speed_mode)
    summ = summ + get(absu_speed_change) + get(absu_speed_off) + get(absu_speed_prepare) + get(absu_speed_us_right_left)
    summ = summ + get(absu_roll_ch_on) + get(absu_pitch_ch_on) + get(absu_smooth_on)
    summ = summ + get(hydro_ra56_rud_1) + get(hydro_ra56_rud_2) + get(hydro_ra56_rud_3)
    summ = summ + get(hydro_ra56_ail_1) + get(hydro_ra56_ail_2) + get(hydro_ra56_ail_3)
    summ = summ + get(hydro_ra56_elev_1) + get(hydro_ra56_elev_2) + get(hydro_ra56_elev_3)
    summ = summ + get(hydro_circuit_auto_man) + get(hydro_long_control)
    summ = summ + get(ZK_select) + get(nav_select) + get(vbe_select)

    if switchers_summ ~= summ then
        playSample(switcher_sound, false)
    end
    switchers_summ = summ

    -- Pitch wheel movement (normalized wrap into [-20, 20])
    local wheel = get(absu_pitch_wheel)
    wheel = wheel + get(absu_pitch_wheel_dir) * get(frame_time) * 10
    wheel = ((wheel + 20) % 40) - 20  -- modulo-based wrap; avoids while-loops
    set(absu_pitch_wheel, wheel)

    -- Turn handle deadzone (zero if within [-1, 1])
    if math.abs(get(absu_turn_handle)) <= 1 then
        set(absu_turn_handle, 0)
    end
end

local caps_summ = 0
local function caps()
    -- Sum of protective caps states for sound
    local summ =  get(absu_arrest_cap) + get(absu_smooth_on_cap) + get(absu_speed_prepare_cap) + get(absu_speed_off_cap)
    summ = summ + get(hydro_circuit_auto_man_cap) + get(hydro_long_control_cap)

    if caps_summ ~= summ then
        playSample(cap_sound, false)
    end
    caps_summ = summ

    -- Mechanical cover logic: when cap is closed, enforce safe state
    if get(hydro_circuit_auto_man_cap) == 0 then set(hydro_circuit_auto_man, 0) end
    if get(hydro_long_control_cap)   == 0 then set(hydro_long_control, 1)   end
end

-----------------------------------------------------------------------
-- Gauges (panel indicators)
-----------------------------------------------------------------------
local function gauges()
    set(absu_roll_mode,  get(roll_main_mode))
    set(absu_pitch_mode, get(pitch_main_mode))
end

-----------------------------------------------------------------------
-- Lamps and annunciators
-----------------------------------------------------------------------
local function lamps()
    -- Cache frequently used values
    local volt_l = get(bus27_volt_left)
    local volt_r = get(bus27_volt_right)
    local volt_max = math.max(volt_l, volt_r)

    local day_night = 1 - get(day_night_set) * 0.25
    local lamps_brt = math.max((volt_max - 10) / 18.5, 0) * day_night
    local small_lamps_brt = math.max((volt_max - 10) / 18.5, 0) -- small lamps and buttons (no extra night dim)
    local test_btn = get(lamp_test) * math.max((volt_r - 10) / 18.5, 0)
    local test_btn_eng = get(lamp_test_eng) * math.max((volt_r - 10) / 18.5, 0) -- fixed parens

    local roll_mode = get(roll_main_mode)
    local pitch_mode = get(pitch_main_mode)
    local roll_submode = get(roll_sub_mode)
    local pitch_submode = get(pitch_sub_mode)
    local AT_mode = get(stu_mode)

    -- Button lamps (ABSUs' own)
    set(absu_zk_lamp,       math.max(bool2int(roll_mode > 0 and roll_submode == 2) * lamps_brt * day_night, test_btn))
    set(absu_reset_lamp,    math.max(bool2int(roll_mode > 0 and roll_submode == 1 and pitch_submode ~= 6) * lamps_brt * day_night, test_btn))
    set(absu_nvu_lamp,      math.max(bool2int(roll_mode > 0 and roll_submode == 3) * lamps_brt * day_night, test_btn))
    set(absu_az1_lamp,      math.max(bool2int(roll_mode > 0 and roll_submode == 4) * lamps_brt * day_night, test_btn))
    set(absu_az2_lamp,      math.max(bool2int(roll_mode > 0 and roll_submode == 5) * lamps_brt * day_night, test_btn))
    set(absu_app_lamp,      math.max(bool2int(roll_mode > 0 and (roll_submode == 6 or roll_submode == 10)) * lamps_brt * day_night, test_btn))
    set(absu_gz_lamp,       math.max(bool2int(roll_mode > 0 and (pitch_submode == 5 or pitch_submode == 10)) * lamps_brt * day_night, test_btn))
    set(absu_stab_m_lamp,   math.max(bool2int(pitch_mode > 0 and pitch_submode == 3) * lamps_brt * day_night, test_btn))
    set(absu_stab_v_lamp,   math.max(bool2int(pitch_mode > 0 and pitch_submode == 2) * lamps_brt * day_night, test_btn))
    set(absu_stab_h_lamp,   math.max(bool2int(pitch_mode > 0 and pitch_submode == 4) * lamps_brt * day_night, test_btn))
    set(absu_stab_lamp,     0) -- intentionally unused on this panel (kept as-is)
    set(absu_stab_spd_lamp, math.max(bool2int(AT_mode > 2) * lamps_brt * day_night, test_btn))

    set(absu_thro1_lamp,    math.max(bool2int(AT_mode > 2 and get(absu_throt_off_1) == 1) * lamps_brt * day_night, test_btn))
    set(absu_thro2_lamp,    math.max(bool2int(AT_mode > 2 and get(absu_throt_off_2) == 1) * lamps_brt * day_night, test_btn))
    set(absu_thro3_lamp,    math.max(bool2int(AT_mode > 2 and get(absu_throt_off_3) == 1) * lamps_brt * day_night, test_btn))

    -- STU test #1 timing (requires nav or landing prep)
    local nav_prep  = get(absu_nav_on) == 1
    local land_prep = get(absu_landing_on) == 1
    if get(absu_speed_test_2) == 1 and (nav_prep or land_prep) then
        stu_test_1_cntr = stu_test_1_cntr + passed
    else
        stu_test_1_cntr = 0
    end

    -- STU lamps (roll/pitch/TOGA) availability during test window
    set(stu_roll_lamp,  math.max(bool2int(roll_mode >= 1 and pitch_mode >= 1 and land_prep and stu_test_1_cntr < 1   and get(absu_calc_roll_fail) == 0) * lamps_brt * day_night, test_btn))
    set(stu_pitch_lamp, math.max(bool2int(roll_mode >= 1 and pitch_mode >= 1 and land_prep and stu_test_1_cntr < 0.5 and get(absu_calc_pitch_fail) == 0) * lamps_brt * day_night, test_btn))
    set(stu_toga_lamp,  math.max(bool2int(roll_mode >= 1 and pitch_mode >= 1 and land_prep and stu_test_1_cntr < 0.5 and get(absu_calc_toga_fail) == 0) * lamps_brt * day_night, test_btn))

    -- STU test #2 timing (autothrottle)
    local at_off = get(absu_speed_off)
    if get(absu_speed_test_1) == 1 and AT_mode > 1 then
        stu_test_2_cntr = stu_test_2_cntr + passed
    else
        stu_test_2_cntr = 0
    end

    set(at_1_lamp, math.max(bool2int(AT_mode > 1 and at_off ~= 1  and stu_test_2_cntr < 10 and get(absu_at1_fail) == 0) * lamps_brt * day_night, test_btn))
    set(at_2_lamp, math.max(bool2int(AT_mode > 1 and at_off ~= -1 and stu_test_2_cntr < 10 and get(absu_at2_fail) == 0) * lamps_brt * day_night, test_btn))

    -- Forward panel lamps (pilot side)
    local elev_tr_now = get(int_pitch_trim)
    local trim_fail = bool2int(
        (get(pitch_main_mode) == 2 and (get(elev_trimm_switcher) ~= 0 or get(emerg_elev_trimm) ~= 0)) or
        ((get(absu_pitch_trimm) ~= 0) and (elev_tr_now - elev_tr_last == 0))
    )
    elev_tr_last = elev_tr_now

    local wrong_trimm_brt = math.max(trim_fail * lamps_brt * day_night, test_btn)
    if get(ismaster) ~= 1 then -- do not override master in Smartcopilot
        set(wrong_trimm, wrong_trimm_brt)
    end

    set(controll_roll,  math.max(get(man_roll_lamp)  * lamps_brt * day_night, test_btn))
    set(controll_pitch, math.max(get(man_pitch_lamp) * lamps_brt * day_night, test_btn))
    set(yoke_sign,      math.max(get(man_toga_lamp)  * lamps_brt * day_night, test_btn))

    -- Triangle blinking logic
    if get(triangle_lamp_signal) == 1 then
        triangle_timer = triangle_timer + passed
        if triangle_timer > 0.3 then
            triangle_lit = 1 - triangle_lit
            triangle_timer = 0
        end
    else
        triangle_lit = 0
        triangle_timer = 0
    end
    set(triangle, math.max(triangle_lit * lamps_brt * day_night, test_btn))

    set(controll_thrust, math.max(bool2int(AT_mode == -1) * lamps_brt * day_night, test_btn))
    set(toga,            math.max(bool2int(pitch_mode == 2 and pitch_submode == 6) * lamps_brt * day_night, test_btn))

    set(course_lim, math.max(get(absu_course_out) * lamps_brt * day_night, test_btn))
    set(gs_lim,     math.max(get(absu_gs_out)     * lamps_brt * day_night, test_btn))

    set(course,      math.max(bool2int(roll_mode  == 2 and roll_submode  == 6) * lamps_brt * day_night, test_btn))
    set(glideslope,  math.max(bool2int(pitch_mode == 2 and pitch_submode == 5) * lamps_brt * day_night, test_btn))
    set(zk_lamp,     math.max(bool2int(roll_mode  == 2 and roll_submode  == 2) * lamps_brt * day_night, test_btn))
    set(thrust_automat, math.max(bool2int(AT_mode > 2) * lamps_brt * day_night, test_btn))
    set(stab_roll,   math.max(bool2int(roll_mode  == 2 and (roll_submode  == 1 or roll_submode  == 10)) * lamps_brt * day_night, test_btn))
    set(stab_pitch,  math.max(bool2int(pitch_mode == 2 and (pitch_submode == 1 or pitch_submode == 10)) * lamps_brt * day_night, test_btn))
    set(nvu_lamp,    math.max(bool2int(roll_mode  == 2 and roll_submode  == 3) * lamps_brt * day_night, test_btn))
    set(vor_lamp,    math.max(bool2int(roll_mode  == 2 and (roll_submode == 4 or roll_submode == 5)) * lamps_brt * day_night, test_btn))
    set(sns_lamp,    math.max(bool2int(roll_mode >= 1 and roll_submode == 3 and get(nav_select) == 1) * lamps_brt * day_night, test_btn))
    set(stab_h,      math.max(bool2int(pitch_mode == 2 and pitch_submode == 4) * lamps_brt * day_night, test_btn))
    set(stab_v,      math.max(bool2int(pitch_mode == 2 and pitch_submode == 2) * lamps_brt * day_night, test_btn))
    set(stab_m,      math.max(bool2int(pitch_mode == 2 and pitch_submode == 3) * lamps_brt * day_night, test_btn))

    set(pitch_control_fail, math.max(get(pitch_contr_lamp) * lamps_brt * day_night, test_btn))
    set(roll_control_fail,  math.max(get(roll_contr_lamp)  * lamps_brt * day_night, test_btn))

    -- ABSU WORK (system OK) logic
    local absu_work_logic = (get(pkp_fail_left) + get(pkp_fail_right) + get(mgv_contr_fail)) < 2
    absu_work_logic = absu_work_logic and (bool2int(get(pressure_ind_1) < 100) + bool2int(get(pressure_ind_2) < 100) + bool2int(get(pressure_ind_3) < 100) < 2)

    local yaw_fail  = get(absu_ra56_yaw_fail)
    local roll_fail = get(absu_ra56_roll_fail)
    local pitch_fail= get(absu_ra56_pitch_fail)

    local ra56_rud_on = (get(hydro_ra56_rud_1) * bool2int(yaw_fail  ~= 3) +
                         get(hydro_ra56_rud_2) * bool2int(yaw_fail  == 0) +
                         get(hydro_ra56_rud_3) * bool2int(yaw_fail  <  2)) > 1

    local ra56_ail_on = (get(hydro_ra56_ail_1) * bool2int(roll_fail == 0) +
                         get(hydro_ra56_ail_2) * bool2int(roll_fail ~= 3) +
                         get(hydro_ra56_ail_3) * bool2int(roll_fail <  2)) > 1

    local ra56_elev_on = (get(hydro_ra56_elev_1) * bool2int(pitch_fail ~= 3) +
                          get(hydro_ra56_elev_2) * bool2int(pitch_fail <  2) +
                          get(hydro_ra56_elev_3) * bool2int(pitch_fail == 0)) > 1

    local chan_1_work = (get(hydro_ra56_rud_1)  * bool2int(yaw_fail   ~= 3) +
                         get(hydro_ra56_ail_1)  * bool2int(roll_fail  == 0) +
                         get(hydro_ra56_elev_1) * bool2int(pitch_fail ~= 3)) > 0

    local chan_2_work = (get(hydro_ra56_rud_2)  * bool2int(yaw_fail   == 0) +
                         get(hydro_ra56_ail_2)  * bool2int(roll_fail  ~= 3) +
                         get(hydro_ra56_elev_2) * bool2int(pitch_fail <  2)) > 0

    local chan_3_work = (get(hydro_ra56_rud_3)  * bool2int(yaw_fail   <  2) +
                         get(hydro_ra56_ail_3)  * bool2int(roll_fail  <  2) +
                         get(hydro_ra56_elev_3) * bool2int(pitch_fail == 0)) > 0

    absu_work_logic = absu_work_logic and ra56_rud_on and ra56_ail_on and ra56_elev_on
    absu_work_logic = absu_work_logic and chan_1_work and chan_2_work and chan_3_work
    absu_work_logic = absu_work_logic and get(sau_stu_on) == 1 and (get(tks_fail_left) + get(tks_fail_right) == 0)
    absu_work_logic = absu_work_logic and (stu_test_1_cntr < 0.5)
    absu_work_logic = absu_work_logic and (get(absu_damp_roll_fail) == 0 and get(absu_damp_pitch_fail) == 0 and get(absu_damp_yaw_fail) == 0)
    absu_work_logic = absu_work_logic and (get(absu_contr_roll_fail) == 0 and get(absu_contr_pitch_fail) == 0)

    set(absu_work, math.max(bool2int(absu_work_logic) * lamps_brt * day_night, 0))

    -- Engineer panel RA56 fail lamps
    set(ra56_roll_fail_1,  math.max(bool2int(get(hydro_ra56_ail_1)  == 0 or get(absu_ra56_roll_fail)  > 2) * lamps_brt * day_night, test_btn_eng))
    set(ra56_roll_fail_2,  math.max(bool2int(get(hydro_ra56_ail_2)  == 0 or get(absu_ra56_roll_fail)  > 0) * lamps_brt * day_night, test_btn_eng))
    set(ra56_roll_fail_3,  math.max(bool2int(get(hydro_ra56_ail_3)  == 0 or get(absu_ra56_roll_fail)  > 1) * lamps_brt * day_night, test_btn_eng))

    set(ra56_pitch_fail_1, math.max(bool2int(get(hydro_ra56_elev_1) == 0 or get(absu_ra56_pitch_fail) > 2) * lamps_brt * day_night, test_btn_eng))
    set(ra56_pitch_fail_2, math.max(bool2int(get(hydro_ra56_elev_2) == 0 or get(absu_ra56_pitch_fail) > 1) * lamps_brt * day_night, test_btn_eng))
    set(ra56_pitch_fail_3, math.max(bool2int(get(hydro_ra56_elev_3) == 0 or get(absu_ra56_pitch_fail) > 0) * lamps_brt * day_night, test_btn_eng))

    set(ra56_course_fail_1, math.max(bool2int(get(hydro_ra56_rud_1) == 0 or get(absu_ra56_yaw_fail) > 2) * lamps_brt * day_night, test_btn_eng))
    set(ra56_course_fail_2, math.max(bool2int(get(hydro_ra56_rud_2) == 0 or get(absu_ra56_yaw_fail) > 0) * lamps_brt * day_night, test_btn_eng))
    set(ra56_course_fail_3, math.max(bool2int(get(hydro_ra56_rud_3) == 0 or get(absu_ra56_yaw_fail) > 1) * lamps_brt * day_night, test_btn_eng))
end

-----------------------------------------------------------------------
-- Update
-----------------------------------------------------------------------
function update()
    -- Always refresh frame delta first to keep timing consistent
    passed = get(frame_time)

    buttons()
    switchers()
    caps()
    lamps()
    gauges()

    start_timer = start_timer + passed
    if notLoaded and start_timer > 0.3 then
        sw_reset()
    end
end
