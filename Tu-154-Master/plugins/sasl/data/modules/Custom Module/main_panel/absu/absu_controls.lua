-- absu_controls.lua
-- Improved ABSU logic (upvalue-safe refactor: consolidated state into table S)

-----------------------------------------------------------------------
-- Smartcopilot
-----------------------------------------------------------------------
-- 0 = not found, 1 = slave, 2 = master
defineProperty("ismaster",    globalPropertyf("scp/api/ismaster"))
-- 1 = no control, 2 = has control
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1"))

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

-- Math helpers
local function sign(x)
    if x > 0 then return 1 end
    if x < 0 then return -1 end
    return 0
end

--[[  If your project defines isILS elsewhere, you can remove this.
      Keeping it here avoids runtime errors where it's used below. ]]
local function isILS(freq_hz)
    local f = freq_hz
    if f > 1000 and f < 200000 then f = f / 100 end
    return f >= 108.10 and f <= 111.95
end

local function line(x, x1, y1, x2, y2)
    if x2 == x1 then return y1 end
    return y1 + (y2 - y1) * (x - x1) / (x2 - x1)
end

-- Keep semantics aligned with project-wide helper usage
local function bool2int(v) return v and 1 or 0 end

-- Improved input validation and protection

-- Optimized interpolation function
local function fastInterpolate(tbl, x)
    if #tbl < 2 then return 0 end
    local low, high = 1, #tbl
    while low < high do
        local mid = math.floor((low + high) / 2)
        if tbl[mid][1] <= x then
            low = mid + 1
        else
            high = mid
        end
    end
    local i = math.max(1, low - 1)
    if i >= #tbl then return tbl[#tbl][2] end
    if i < 1 then return tbl[1][2] end
    local x1, y1 = tbl[i][1], tbl[i][2]
    local x2, y2 = tbl[i + 1][1], tbl[i + 1][2]
    if x2 == x1 then return y1 end
    return y1 + (y2 - y1) * (x - x1) / (x2 - x1)
end

-----------------------------------------------------------------------
-- Bulk DataRef definitions
-----------------------------------------------------------------------
defineProps({
	-- Controls
	{"joy_pitch", "tu154/custom/SC/yoke_pitch_ratio", globalPropertyf},
	{"joy_roll", "tu154/custom/SC/yoke_roll_ratio", globalPropertyf},
	{"joy_yaw", "tu154/custom/SC/yoke_heading_ratio", globalPropertyf},
	-- Timing
	{"frame_time", "tu154/custom/time/frame_time", globalPropertyf}, 
	-- Hydraulics pressures
	{"gs_press_1", "tu154/custom/hydro/gs_press_1", globalPropertyf},
	{"gs_press_2", "tu154/custom/hydro/gs_press_2", globalPropertyf},
	{"gs_press_3", "tu154/custom/hydro/gs_press_3", globalPropertyf},
	{"hydro_ra56_rud_1", "tu154/custom/switchers/eng/hydro_ra56_rud_1", globalPropertyi},
	{"hydro_ra56_rud_2", "tu154/custom/switchers/eng/hydro_ra56_rud_2", globalPropertyi},
	{"hydro_ra56_rud_3", "tu154/custom/switchers/eng/hydro_ra56_rud_3", globalPropertyi},
	{"hydro_ra56_ail_1", "tu154/custom/switchers/eng/hydro_ra56_ail_1", globalPropertyi},
	{"hydro_ra56_ail_2", "tu154/custom/switchers/eng/hydro_ra56_ail_2", globalPropertyi},
	{"hydro_ra56_ail_3", "tu154/custom/switchers/eng/hydro_ra56_ail_3", globalPropertyi},
	{"hydro_ra56_elev_1", "tu154/custom/switchers/eng/hydro_ra56_elev_1", globalPropertyi},
	{"hydro_ra56_elev_2", "tu154/custom/switchers/eng/hydro_ra56_elev_2", globalPropertyi},
	{"hydro_ra56_elev_3", "tu154/custom/switchers/eng/hydro_ra56_elev_3", globalPropertyi},
	-- ABSU panel controls
	{"absu_turn_handle", "tu154/custom/switchers/console/absu_turn_handle", globalPropertyi},
	{"absu_pitch_wheel", "tu154/custom/switchers/console/absu_pitch_wheel", globalPropertyi},
	{"absu_zpu_sel", "tu154/custom/switchers/console/absu_zpu_sel", globalPropertyi},
	{"ZK_select", "tu154/custom/switchers/ZK_select", globalPropertyi},
	{"absu_smooth_on", "tu154/custom/switchers/console/absu_smooth_on", globalPropertyi},
	{"absu_nav_on", "tu154/custom/switchers/console/absu_nav_on", globalPropertyi},
	{"absu_landing_on", "tu154/custom/switchers/console/absu_landing_on", globalPropertyi},
	{"absu_needles_on", "tu154/custom/switchers/console/absu_needles_on", globalPropertyi},
	{"nav_select", "tu154/custom/switchers/nav_select", globalPropertyi},
	-- STU speed test buttons
	{"absu_speed_test_1", "tu154/custom/buttons/console/absu_speed_test_1", globalPropertyi},
	{"absu_speed_test_2", "tu154/custom/buttons/console/absu_speed_test_2", globalPropertyi},
	-- ABSU navigation source
	{"absu_use_second_nav", "tu154/custom/absu_use_second_nav", globalPropertyi},
	-- PKP (PNP) compasses and courses
	{"pkp_course_L", "tu154/custom/gauges/compas/pkp_helper_course_L", globalPropertyf}, 
	{"pkp_course_R", "tu154/custom/gauges/compas/pkp_helper_course_R", globalPropertyf},
	{"pkp_gyro_course_L", "tu154/custom/gauges/compas/pkp_gyro_course_L", globalPropertyf},
	{"pkp_gyro_course_R", "tu154/custom/gauges/compas/pkp_gyro_course_R", globalPropertyf},
	{"pkp_obs_1", "tu154/custom/gauges/compas/pkp_obs_L", globalPropertyf}, 
	{"pkp_obs_2", "tu154/custom/gauges/compas/pkp_obs_R", globalPropertyf}, 
	-- Angular rates and accelerations
	{"roll_rate", "sim/flightmodel/position/P", globalPropertyf},
	{"pitch_rate", "sim/flightmodel/position/Q", globalPropertyf},
	{"yaw_rate", "sim/flightmodel/position/R", globalPropertyf},
	{"roll_acc", "sim/flightmodel/position/P_dot", globalPropertyf},
	{"pitch_acc", "sim/flightmodel/position/Q_dot", globalPropertyf},
	{"yaw_acc", "sim/flightmodel/position/R_dot", globalPropertyf},
	{"slip", "sim/cockpit2/gauges/indicators/sideslip_degrees", globalPropertyf},
	-- SVS
	{"mach_svs", "tu154/custom/svs/machno", globalPropertyf},
	{"alt_svs", "tu154/custom/svs/altitude", globalPropertyf},
	{"tas_svs", "tu154/custom/svs/true_airspeed", globalPropertyf},
	{"ias", "sim/cockpit2/gauges/indicators/airspeed_kts_pilot", globalPropertyf},
	-- NVU
	{"nvu_res_course", "tu154/custom/nvu/nvu_res_course", globalPropertyf},
	{"nvu_res_z", "tu154/custom/nvu/nvu_res_z", globalPropertyf},
	-- ABSU modes
	{"roll_main_mode", "tu154/custom/absu/roll_main_mode", globalPropertyi},
	{"pitch_main_mode", "tu154/custom/absu/pitch_main_mode", globalPropertyi}, 
	{"roll_sub_mode", "tu154/custom/absu/roll_sub_mode", globalPropertyi},
	{"pitch_sub_mode", "tu154/custom/absu/pitch_sub_mode", globalPropertyi},   
	-- BKK
	{"bkk_pitch", "tu154/custom/bkk/bkk_pitch", globalPropertyf},
	{"bkk_roll", "tu154/custom/bkk/bkk_roll", globalPropertyf},
	-- TKS
	{"course_gpk", "tu154/custom/tks/course_gpk", globalPropertyf},
	{"course_gmk", "tu154/custom/tks/course_gmk", globalPropertyf},
	{"tks_fail_left", "tu154/custom/tks/fail_left", globalPropertyi},
	{"tks_fail_right", "tu154/custom/tks/fail_right", globalPropertyi},
	-- DISS
	{"diss_groundspeed", "tu154/custom/nvu/diss_groundspeed", globalPropertyf},
	{"diss_slip_angle", "tu154/custom/nvu/diss_slip_angle", globalPropertyf},
	-- Course/ILS
	{"obs_1", "sim/cockpit2/radios/actuators/nav1_obs_deg_mag_pilot", globalPropertyf},
	{"obs_2", "sim/cockpit2/radios/actuators/nav2_obs_deg_mag_pilot", globalPropertyf},
	{"nav_cs_1", "tu154/custom/radio/nav1_cs", globalPropertyf},
	{"nav_cs_2", "tu154/custom/radio/nav2_cs", globalPropertyf},
	{"nav_gs_1", "tu154/custom/radio/nav1_gs", globalPropertyf},
	{"nav_gs_2", "tu154/custom/radio/nav2_gs", globalPropertyf},
	{"freq_1", "sim/cockpit2/radios/actuators/nav1_frequency_hz", globalPropertyf},
	{"freq_2", "sim/cockpit2/radios/actuators/nav2_frequency_hz", globalPropertyf},
	{"nav_cs_flag_1", "tu154/custom/radio/nav1_cs_flag", globalPropertyi},
	{"nav_gs_flag_1", "tu154/custom/radio/nav1_gs_flag", globalPropertyi},
	{"nav_cs_flag_2", "tu154/custom/radio/nav2_cs_flag", globalPropertyi},
	{"nav_gs_flag_2", "tu154/custom/radio/nav2_gs_flag", globalPropertyi},
	{"cr_flag_1", "sim/cockpit2/radios/indicators/nav1_flag_from_to_pilot", globalPropertyf},
	{"cr_flag_2", "sim/cockpit2/radios/indicators/nav2_flag_from_to_pilot", globalPropertyf},
	-- KLN / GPS sources
	{"kln_course", "tu154/custom/kln90/kln_course", globalPropertyf},
	{"kln_dev", "tu154/custom/kln90/kln_dev", globalPropertyf},
	{"show_gns", "tu154/custom/anim/show_gns", globalPropertyi},
	{"show_RXP", "tu154/custom/anim/RXP", globalPropertyi},
	-- RXP (GTN/GNS)
	{"RXP_course", "RXP/radios/indicators/gps_course_degtm", globalPropertyf},
	{"RXP_dev", "RXP/radios/indicators/gps_cross_track_nm", globalPropertyf},
	-- GNS430 passthrough
	{"GNS430_dtk", "tu154/custom/SC/GNS430_dtk", globalPropertyf},
	{"GNS430_dev", "tu154/custom/SC/GNS430_dev", globalPropertyf},
	-- Radio altimeter and DH
	{"rv5_alt", "tu154/custom/misc/rv5_alt_left", globalPropertyf},
	{"dh_set", "tu154/custom/gauges/alt/radioalt_dh_left", globalPropertyf},
	{"rv_angle", "tu154/custom/gauges/alt/radioalt_needle_left", globalPropertyf},
	-- Gears and flaps
	{"gear1_deploy", "sim/aircraft/parts/acf_gear_deploy[0]", globalPropertyf},
	{"gear2_deploy", "sim/aircraft/parts/acf_gear_deploy[1]", globalPropertyf},
	{"gear3_deploy", "sim/aircraft/parts/acf_gear_deploy[2]", globalPropertyf},
	{"flap_inn_L", "sim/flightmodel/controls/wing1l_fla1def", globalPropertyf},
	{"flap_inn_R", "sim/flightmodel/controls/wing1r_fla1def", globalPropertyf},
	{"gear1_deflect", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[0]", globalPropertyf},
	-- ABSU indicators and flags
	{"absu_roll_ind", "tu154/custom/absu/absu_roll_ind", globalPropertyf},
	{"absu_pitch_ind", "tu154/custom/absu/absu_pitch_ind", globalPropertyf},
	{"absu_roll_flag", "tu154/custom/absu/absu_roll_flag", globalPropertyi},
	{"absu_pitch_flag", "tu154/custom/absu/absu_pitch_flag", globalPropertyi},
	-- ABSU actuators
	{"absu_contr_pitch", "tu154/custom/absu/contr_pitch", globalPropertyf},
	{"absu_contr_roll", "tu154/custom/absu/contr_roll", globalPropertyf},
	{"absu_contr_yaw", "tu154/custom/absu/contr_yaw", globalPropertyf},
	{"absu_pitch_trimm", "tu154/custom/absu/absu_pitch_trimm", globalPropertyi},
	-- Limit annunciations
	{"absu_course_out", "tu154/custom/absu_course_out", globalPropertyi},
	{"absu_gs_out", "tu154/custom/absu_gs_out", globalPropertyi},
	-- Failures
	{"absu_damp_roll_fail", "tu154/custom/failures/absu_damp_roll_fail", globalPropertyi},
	{"absu_damp_pitch_fail", "tu154/custom/failures/absu_damp_pitch_fail", globalPropertyi},
	{"absu_damp_yaw_fail", "tu154/custom/failures/absu_damp_yaw_fail", globalPropertyi},
	{"absu_contr_roll_fail", "tu154/custom/failures/absu_contr_roll_fail", globalPropertyi},
	{"absu_contr_pitch_fail", "tu154/custom/failures/absu_contr_pitch_fail", globalPropertyi},
	{"absu_calc_toga_fail", "tu154/custom/failures/absu_calc_toga_fail", globalPropertyi},
	{"absu_calc_roll_fail", "tu154/custom/failures/absu_calc_roll_fail", globalPropertyi},
	{"absu_calc_pitch_fail", "tu154/custom/failures/absu_calc_pitch_fail", globalPropertyi},
	-- Manual lamps
	{"man_roll_lamp", "tu154/custom/absu/man_roll_lamp", globalPropertyi},
	{"man_pitch_lamp", "tu154/custom/absu/man_pitch_lamp", globalPropertyi},
})

-----------------------------------------------------------------------
-- Improved PID Controller Parameters
-----------------------------------------------------------------------
local PID_PARAMS = {
    V_MODE = { Kp = 0.4, Ki = 0.003, Kd = 1.5, max_i = 1.0 },
    M_MODE = { Kp = 250, Ki = 0.03, Kd = 400, max_i = 1.0 },
    H_MODE = { Kp_base = 0.08, Kd_base = 0.25, max_i = 0.08 },
    ROLL   = { Kp = 0.08, Kd = 0.06 },
    GS     = { Kp_high = 0.9, Kp_low = 1.5, Kd_high = 2.0, Kd_low = 3.0 }
}

-----------------------------------------------------------------------
-- Mode Transition Management
-----------------------------------------------------------------------
local mode_transition_timer = 0
local previous_roll_submode = 0
local previous_pitch_submode = 0
local transition_factor = 0
local TRANSITION_TIME = 3.5

local function handleModeTransition(S)
    local current_roll_mode  = get(roll_sub_mode)
    local current_pitch_mode = get(pitch_sub_mode)
    if current_roll_mode ~= previous_roll_submode or current_pitch_mode ~= previous_pitch_submode then
        mode_transition_timer   = 0
        previous_roll_submode   = current_roll_mode
        previous_pitch_submode  = current_pitch_mode
    end
    mode_transition_timer = mode_transition_timer + S.passed
    transition_factor     = math.min(mode_transition_timer / TRANSITION_TIME, 1.0)
end

-----------------------------------------------------------------------
-- Input validation helpers
-----------------------------------------------------------------------
local function validateInputs(S)
    S.pitch_now = safeClamp(get(bkk_pitch), -90, 90, 0)
    S.roll_now  = safeClamp(get(bkk_roll),  -180, 180, 0)
    S.mach      = safeClamp(get(mach_svs),  0, 1.2, 0.3)
end

-----------------------------------------------------------------------
-- Constants (tables)
-----------------------------------------------------------------------
local roll_ail_tbl = {
    {0, 1}, {0.2, 1}, {0.3, 0.5}, {0.4, -0.1}, {0.6, -0.2}, {0.8, -0.4}, {1, -0.6}
}
local pitch_elev_tbl = {
    {0, 0.5}, {0.2, 0.5}, {0.3, 0.3}, {0.4, 0.2}, {0.6, 0}, {0.8, -0.1}, {1, -0.2}
}
local flaps_tbl = {
    {0, 0}, {15, 5}, {28, 7}, {36, 8}, {45, 10}, {50, 10}
}

-----------------------------------------------------------------------
-- Consolidated state (reduces upvalues dramatically)
-----------------------------------------------------------------------
local S = {
    -- actuators
    pitch_act = 0, roll_act = 0, yaw_act = 0,
    -- kinematics
    pitch_now = 0, roll_now = 0, mach = 0,
    -- config
    flap_coef = 0.025,
    pitch_stab_roll_coef = 0.00175 * 2,
    elev_lim = 0.4, ail_lim = 0.4,
    pitch_coef = 0.3,
    -- dynamic flags
    gear_down = false, flaps = 0,
    passed = 0, MASTER = false,
    -- PU
    pitch_whl_last = 0,
    PU_pitch = 0,
    -- V
    V_stab = 0, V_smth = 0, V_last = 0, I_V = 0,
    -- M
    M_stab = 0, M_smth = 0, M_last = 0, I_M = 0,
    -- H
    H_stab = 0, H_last = 0, I_H = 0,
    -- GS
    GS_last = 0, GS_smth = 0, GS_est = 0,
    -- TOGA
    toga_alt = 0,
    -- roll manual
    roll_coef = 0.5,
    -- handle-mode
    course_stab_timer = 0,
    course_stab_act = 0,
    -- NVU/KLN
    nvu_z_last = 0, nvu_side_last = 0, nvu_spd_last = 0, nvu_course_last = 0,
    kln_frame_timer = 0, kln_Z_last = 0, kln_spd = 0,
    gps_Z_smooth = 0,
    course_change_timer = 0,
    -- VOR
    vor_slip_act = 0, vor_dev_lim = 4, vor_dev_act = 0,
    -- APP
    dev_last = 0, ILS_spd_smth = 0, ILS_dev_smth = 0, ILS_spd_last = 0,
    -- Yaw damper memory
    yaw_I = 0, yaw_P_last = 0,
    -- displays / smoothing
    pitch_show = 0, roll_show = 0,
    pitch_need_smth = 0, roll_need_smth = 0,
}

-- Initial seeds from sim
S.PU_pitch        = get(bkk_pitch)
S.course_stab_act = get(course_gpk)
S.V_stab          = get(ias) / 1.852
S.V_smth          = S.V_stab
S.V_last          = S.V_stab
S.M_stab          = get(mach_svs)
S.M_smth          = S.M_stab
S.M_last          = S.M_stab
S.H_stab          = get(alt_svs)
S.H_last          = S.H_stab
S.toga_alt        = S.H_stab
S.pitch_show      = get(bkk_pitch)
S.roll_show       = get(bkk_roll)
S.pitch_need_smth = S.pitch_show
S.roll_need_smth  = S.roll_show

-----------------------------------------------------------------------
-- Forward declarations (now take S)
-----------------------------------------------------------------------
local function pitch_holder(pitch_hold, S) end
local function roll_holder(roll_hold, S) end
local function yaw_holder(S) end

-----------------------------------------------------------------------
-- Per-frame update
-----------------------------------------------------------------------
function update()

  -- per-frame basics
  S.passed = get(frame_time)
  S.MASTER = get(ismaster) ~= 1

  -- init once (stored in S to avoid extra locals)
  S.ILS_LIM              = S.ILS_LIM              or 25
  S.ILS_SPD_LIM          = S.ILS_SPD_LIM          or 40         -- was 50, slightly softer
  S.ILS_GAIN_BASE        = S.ILS_GAIN_BASE        or 1.8        -- was 2.5*(1+), now gentler
  S.ILS_SPD_GAIN_BASE    = S.ILS_SPD_GAIN_BASE    or 1000       -- was 1600, softer
  S.SPIKE_THRESHOLD      = S.SPIKE_THRESHOLD      or 0.8        -- was 1.0
  S.ALPHA_SPIKE          = S.ALPHA_SPIKE          or 0.28       -- was 0.18
  S.ALPHA_NORMAL         = S.ALPHA_NORMAL         or 0.70       -- was 0.55
  S.APP_INTERCEPT_CAP    = S.APP_INTERCEPT_CAP    or 18         -- was 30/20
  S.APP_FINE_ROLL_CAP    = S.APP_FINE_ROLL_CAP    or 7.0        -- was 8..10

  -- validation + transition smoothing
  validateInputs(S)
  handleModeTransition(S)

  -- modes
  local secondNav     = get(absu_use_second_nav) == 1
  local roll_mode     = get(roll_main_mode)
  local pitch_mode    = get(pitch_main_mode)
  local roll_submode  = get(roll_sub_mode)
  local pitch_submode = get(pitch_sub_mode)

  -- body rates
  local roll_W  = get(roll_rate)
  local pitch_W = get(pitch_rate)
  local roll_W2 = get(roll_acc)
  if get(absu_damp_roll_fail)  == 1 then roll_W = 0; roll_W2 = 0 end
  if get(absu_damp_pitch_fail) == 1 then pitch_W = 0 end

  -- pilot in
  local pitch_cmd = get(joy_pitch)
  local roll_cmd  = get(joy_roll)

  -- flight state
  S.mach           = safeClamp(get(mach_svs), 0, 1.2, 0.3)
  local airspeed   = safeClamp(get(ias) * 1.852, 50, 1000, 250)
  local alt        = safeClamp(get(alt_svs), -1000, 50000, 10000)
  local gs_dev     = safeClamp(get(nav_gs_1) * 10, -15, 15, 0)
  if secondNav then gs_dev = safeClamp(get(nav_gs_2) * 10, -15, 15, 0) end

  local RV_alt = safeClamp(get(rv5_alt), 0, 2500, 1000)

  S.gear_down = get(gear1_deploy) + get(gear2_deploy) + get(gear3_deploy) > 0.05
  S.flaps     = (get(flap_inn_L) + get(flap_inn_R)) / 2

  local nav_on      = get(absu_nav_on)      == 1
  local app_on      = get(absu_landing_on)  == 1
  local needles_on  = get(absu_needles_on)  == 1
  local absu_smooth = get(absu_smooth_on)

  -------------------------------------------------------------------
  -- Pitch channel
  -------------------------------------------------------------------
  local pitch_need = S.pitch_now
  S.pitch_show = pitch_need

  if pitch_mode >= 1 then
    if pitch_submode == 1 or pitch_submode == 10 then
      -- PU mode
      local pitch_whl  = get(absu_pitch_wheel)
      local pitch_diff = pitch_whl - S.pitch_whl_last
      while pitch_diff >  1 do pitch_diff = pitch_diff - 20 end
      while pitch_diff < -1 do pitch_diff = pitch_diff + 20 end
      S.pitch_whl_last = pitch_whl

      S.PU_pitch = S.PU_pitch + pitch_diff * 0.2
      if S.PU_pitch > 17 then S.PU_pitch = 17
      elseif S.PU_pitch < -17 then S.PU_pitch = -17 end

      pitch_need = S.PU_pitch

      S.V_stab = airspeed; S.V_smth = S.V_stab
      S.M_stab = S.mach;   S.M_smth = S.M_stab
      S.toga_alt = alt;    S.H_stab = alt

    elseif pitch_submode == 2 then
      -- IAS hold
      S.V_smth = S.V_smth + (airspeed - S.V_smth) * S.passed
      local P, D = (S.V_smth - S.V_stab), 0
      S.I_V = S.I_V + P * S.passed * PID_PARAMS.V_MODE.Ki
      S.I_V = S.I_V - sign(S.I_V) * S.passed * 0.02
      S.I_V = safeClamp(S.I_V, -PID_PARAMS.V_MODE.max_i, PID_PARAMS.V_MODE.max_i, 0)
      if S.passed > 0 then D = (S.V_smth - S.V_last) / S.passed end
      local PID = P * PID_PARAMS.V_MODE.Kp + D * (PID_PARAMS.V_MODE.Kd * (1 - absu_smooth * 0.5)) + S.I_V

      pitch_need = safeClamp(PID + S.PU_pitch, -8.5, 17.0, S.PU_pitch)

      S.PU_pitch = S.PU_pitch + (S.pitch_now - S.PU_pitch) * S.passed * 0.3 * transition_factor
      S.M_stab = S.mach; S.M_smth = S.M_stab
      S.toga_alt = alt;  S.H_stab = alt

    elseif pitch_submode == 3 then
      -- Mach hold
      S.M_smth = S.M_smth + (S.mach - S.M_smth) * S.passed
      local P, D = (S.M_smth - S.M_stab), 0
      S.I_M = S.I_M + P * S.passed * PID_PARAMS.M_MODE.Ki
      S.I_M = S.I_M - sign(S.I_M) * S.passed * 0.2
      S.I_M = safeClamp(S.I_M, -PID_PARAMS.M_MODE.max_i, PID_PARAMS.M_MODE.max_i, 0)
      if S.passed > 0 then D = (S.M_smth - S.M_last) / S.passed end
      local PID = P * PID_PARAMS.M_MODE.Kp + D * (PID_PARAMS.M_MODE.Kd * (1 - absu_smooth * 0.5)) + S.I_M

      pitch_need = safeClamp(PID + S.PU_pitch, -8.5, 13.6, S.PU_pitch)

      S.PU_pitch = S.PU_pitch + (S.pitch_now - S.PU_pitch) * S.passed * 0.3 * transition_factor
      S.V_stab = airspeed; S.V_smth = S.V_stab
      S.toga_alt = alt;    S.H_stab = alt

    elseif pitch_submode == 4 then
      -- Altitude hold
      local P = safeClamp(alt - S.H_stab, -100, 100, 0)
      S.I_H = S.I_H + P * S.passed * 0.00001
      S.I_H = safeClamp(S.I_H, -PID_PARAMS.H_MODE.max_i, PID_PARAMS.H_MODE.max_i, 0)
      local D = 0
      if S.passed > 0 then D = (alt - S.H_last) / S.passed end

      local PID = P * line(S.mach, 0.3, PID_PARAMS.H_MODE.Kp_base, 0.8, PID_PARAMS.H_MODE.Kp_base * 0.5)
                + D * (line(S.mach, 0.3, PID_PARAMS.H_MODE.Kd_base, 0.8, PID_PARAMS.H_MODE.Kd_base * 0.5) * (1 - absu_smooth * 0.5))
                + S.I_H

      pitch_need = safeClamp(-PID + S.PU_pitch, -8.5, 8.5, S.PU_pitch)

      S.PU_pitch = S.PU_pitch + (S.pitch_now - S.PU_pitch) * S.passed * 0.3 * transition_factor
      S.V_stab = airspeed; S.V_smth = S.V_stab
      S.M_stab = S.mach;   S.M_smth = S.M_stab
      S.toga_alt = alt

    elseif pitch_submode == 5 then
      -- GS hold (soft flare shaping)
      S.GS_smth = S.GS_smth + (gs_dev - S.GS_smth) * S.passed * 5
      local gs_spd = 0
      if S.passed > 0 then gs_spd = (S.GS_smth - S.GS_last) / S.passed end

      local Kp = PID_PARAMS.GS.Kp_low
      local Kd = PID_PARAMS.GS.Kd_low
      if RV_alt <= 250 then
        Kp = PID_PARAMS.GS.Kp_high
        Kd = PID_PARAMS.GS.Kd_high
        if RV_alt <= 100 and RV_alt > 20 then
          local f = 1.0 - (100 - RV_alt) * 0.4 / 80
          Kp = Kp * f; Kd = Kd * f
        elseif RV_alt <= 20 then
          Kp = Kp * 0.3; Kd = Kd * 0.3
        end
      end

      local PID = S.GS_smth * Kp + gs_spd * Kd * transition_factor
      pitch_need = -PID + S.PU_pitch

      local up_lim   = 17 * 0.4 * (S.gear_down and 0.8 or 1.0)
      local down_lim = -17 * 0.5 * (S.gear_down and 1.2 or 1.0)
      pitch_need = safeClamp(pitch_need, down_lim, up_lim, S.PU_pitch)

      if math.abs(S.GS_smth) < 1 then S.GS_est = 1
      elseif math.abs(S.GS_smth) > 6 then S.GS_est = 0 end

      S.PU_pitch = S.PU_pitch + (S.pitch_now - S.PU_pitch) * S.passed * 0.1 * transition_factor
      S.V_stab = airspeed; S.V_smth = S.V_stab
      S.M_stab = S.mach;   S.M_smth = S.M_stab
      S.H_stab = alt;      S.toga_alt = alt

      if RV_alt <= 100 and math.abs(S.GS_smth) > 4 then set(absu_gs_out, 1) end

    elseif pitch_submode == 6 and get(absu_calc_toga_fail) == 0 then
      -- TOGA
      if S.flaps >= 40 then S.V_stab = 290
      elseif S.flaps >= 25 then S.V_stab = 345
      else S.V_stab = 400 end

      S.V_smth = S.V_smth + (airspeed - S.V_smth) * S.passed
      local P, D = safeClamp(S.V_smth - S.V_stab, -3, 3, 0), 0
      S.I_V = S.I_V + P * S.passed * PID_PARAMS.V_MODE.Ki
      S.I_V = S.I_V - sign(S.I_V) * S.passed * 0.02
      S.I_V = safeClamp(S.I_V, -PID_PARAMS.V_MODE.max_i, PID_PARAMS.V_MODE.max_i, 0)
      if S.passed > 0 then D = (S.V_smth - S.V_last) / S.passed end
      local PID = P * PID_PARAMS.V_MODE.Kp + D * (PID_PARAMS.V_MODE.Kd * (1 - absu_smooth * 0.5)) + S.I_V

      if alt < S.toga_alt then pitch_need = pitch_need + S.passed * 2 else pitch_need = PID + S.PU_pitch end
      pitch_need = safeClamp(pitch_need, 0, 17, S.PU_pitch)

      S.PU_pitch = S.PU_pitch + (S.pitch_now - S.PU_pitch) * S.passed * 0.2 * transition_factor
      S.M_stab = S.mach; S.M_smth = S.M_stab
      S.H_stab = alt;    S.toga_alt = alt

    else
      -- fallback
      S.PU_pitch = S.pitch_now
      S.V_stab = airspeed; S.V_smth = S.V_stab
      S.M_stab = S.mach;   S.M_smth = S.M_stab
      S.H_stab = alt
    end

    -- save last
    S.V_last  = S.V_smth
    S.M_last  = S.M_smth
    S.H_last  = alt
    S.GS_last = S.GS_smth

    -- elevator + trimmer
    if pitch_mode == 1 then
      if S.mach < 1 then S.pitch_coef = fastInterpolate(pitch_elev_tbl, S.mach) else S.pitch_coef = -0.2 end
      local elev_need = safeClamp(pitch_cmd * S.pitch_coef - pitch_W * 0.15, -S.elev_lim, S.elev_lim, 0)
      if S.MASTER then set(absu_pitch_trimm, 0) end
      S.V_stab = airspeed; S.V_smth = S.V_stab; S.M_stab = S.mach; S.M_smth = S.M_stab; S.H_stab = alt
      S.PU_pitch = S.pitch_now; S.pitch_need_smth = S.pitch_now; S.pitch_act = elev_need

    elseif pitch_mode == 2 then
      if get(absu_calc_pitch_fail) == 0 then S.pitch_act = pitch_holder(pitch_need, S) end
    end

    S.pitch_show = pitch_need

  else
    if S.MASTER then set(absu_pitch_trimm, 0) end
    S.pitch_need_smth = 0
    S.pitch_act       = 0
  end

  -- apply pitch hydraulics (inline HS)
  if S.MASTER then
    set(
      absu_contr_pitch,
      get(absu_contr_pitch) +
      (S.pitch_act - get(absu_contr_pitch)) * S.passed *
      math.max(
        0,
        get(hydro_ra56_elev_1) * clamp((get(gs_press_1) - 10) / 70, 0, 1),
        get(hydro_ra56_elev_2) * clamp((get(gs_press_2) - 10) / 70, 0, 1),
        get(hydro_ra56_elev_3) * clamp((get(gs_press_3) - 10) / 70, 0, 1)
      ) * 10
    )
  end

  -------------------------------------------------------------------
  -- Roll channel
  -------------------------------------------------------------------
  local course_now = safeClamp(get(course_gpk), 0, 360, 0)
  local roll_need  = S.roll_now
  S.roll_show = roll_need

  if roll_mode >= 1 then
    local roll_handle = get(absu_turn_handle)

    if math.abs(roll_handle) <= 1 and roll_mode == 2 and roll_submode == 1 then
      S.course_stab_timer = S.course_stab_timer + S.passed
    else
      S.course_stab_timer = 0
      S.course_stab_act   = course_now
    end

    if roll_submode == 1 or roll_submode == 10 then
      if S.course_stab_timer > 0 and S.course_stab_timer < 8 then
        local course_diff = course_now - S.course_stab_act
        if course_diff > 180 then course_diff = course_diff - 360 elseif course_diff < -180 then course_diff = course_diff + 360 end
        S.course_stab_act = S.course_stab_act + course_diff * S.passed * 3 * transition_factor
      end

      local course_diff = S.course_stab_act - course_now
      if course_diff > 180 then course_diff = course_diff - 360 elseif course_diff < -180 then course_diff = course_diff + 360 end

      if S.course_stab_timer > 8 then
        roll_need = course_diff * 1.5 * transition_factor
      else
        roll_need = (math.abs(roll_handle) <= 1) and 0 or (roll_handle * 0.5)
      end

      roll_need   = safeClamp(roll_need, -25, 25, 0)
      S.roll_show = 0
      S.ILS_dev_smth = 0

    elseif roll_submode == 2 then
      -- ZK (heading bug)
      local pnp_course = get(pkp_course_L)
      course_now = get(pkp_gyro_course_L)
      if get(ZK_select) == 1 then pnp_course = get(pkp_course_R); course_now = get(pkp_gyro_course_R) end

      local course_diff = pnp_course - course_now
      if course_diff > 180 then course_diff = course_diff - 360 elseif course_diff < -180 then course_diff = course_diff + 360 end

      roll_need = safeClamp(course_diff * 2 * transition_factor, -20, 20, 0)
      S.roll_show = 0
      S.ILS_dev_smth = 0

    elseif roll_submode == 3 then
      -- NVU / GPS-LNAV
      local nvu_course = get(nvu_res_course)
      local nvu_z      = get(nvu_res_z)

      local kln_mode = get(nav_select) == 1
      local KZ  = 0.015 * (100 / math.max(get(diss_groundspeed), 50))
      local KPZ = 0.4   * math.min(math.max(get(diss_groundspeed), 50) / 100, 2.0)

      if kln_mode then nvu_course = get(kln_course); nvu_z = -get(kln_dev) * 1.852 end
      if get(show_gns) == 1 and get(show_RXP) == 0 and kln_mode then
        nvu_course = get(GNS430_dtk)
        local Z = -get(GNS430_dev) * 1.852 * 0.8
        S.gps_Z_smooth = S.gps_Z_smooth - (S.gps_Z_smooth - Z) * S.passed
        nvu_z = S.gps_Z_smooth
      end
      if get(show_gns) == 1 and get(show_RXP) == 1 and kln_mode then
        nvu_course = get(RXP_course)
        local Z = -get(RXP_dev) * 1.852
        S.gps_Z_smooth = S.gps_Z_smooth - (S.gps_Z_smooth - Z) * S.passed
        nvu_z = S.gps_Z_smooth
      end

      local side = safeClamp(nvu_z * 1000, -2400, 2400, 0)

      if math.abs(nvu_z) > 5.0 then nvu_z = sign(nvu_z) * 5.0; side = sign(side) * 2400 end

      local PZ = 0
      if not kln_mode or (get(show_gns) >= 1 and kln_mode) then
        if S.passed > 0 then PZ = (nvu_z - S.nvu_z_last) / S.passed end
      else
        if nvu_z ~= S.nvu_z_last then
          if S.kln_frame_timer > 0 then S.kln_spd = (nvu_z - S.kln_Z_last) / S.kln_frame_timer end
          S.kln_Z_last, S.kln_frame_timer = nvu_z, 0
        else
          S.kln_frame_timer = S.kln_frame_timer + S.passed
        end
        PZ = S.kln_spd
      end
      S.nvu_z_last = nvu_z

      local side_spd = safeClamp(PZ * 1000, -160, 160, 0)

      if math.abs(nvu_course - S.nvu_course_last) > 0.5 then S.course_change_timer = 0 end
      S.nvu_course_last = nvu_course
      if S.course_change_timer < 3 then side = 0; side_spd = 0 end
      S.course_change_timer = S.course_change_timer + S.passed

      course_now = get(pkp_gyro_course_L)

      if math.abs(nvu_z) > 3.5 then
        local intercept_angle = math.min(30, math.abs(nvu_z) * 8)
        local new_course = nvu_course - intercept_angle * sign(nvu_z)
        if new_course < 0 then new_course = new_course + 360 elseif new_course > 360 then new_course = new_course - 360 end
        local course_diff = new_course - course_now
        if course_diff > 180 then course_diff = course_diff - 360 elseif course_diff < -180 then course_diff = course_diff + 360 end
        roll_need = course_diff * 2 * transition_factor
      else
        roll_need = (-side * KZ - side_spd * KPZ) * transition_factor
      end

      roll_need = safeClamp(roll_need, -25, 25, 0)

      local course_delta = nvu_course - course_now
      while course_delta > 180 do course_delta = course_delta - 360 end
      while course_delta < -180 do course_delta = course_delta + 360 end
      if math.abs(course_delta) > 90 then roll_need = sign(course_delta) * 25 * transition_factor end

      S.roll_show = roll_need
      if not nav_on then roll_need = 0 end
      S.ILS_dev_smth = 0

    elseif roll_submode == 4 or roll_submode == 5 then
      -- AZ1 / AZ2 (VOR)
      local slip_angle = get(diss_slip_angle)
      course_now = get(course_gpk)

      local course_dev = (roll_submode == 5 and get(nav_cs_2) or get(nav_cs_1)) * 10
      local pnp_course = (get(absu_zpu_sel) == 1) and get(pkp_obs_2) or get(pkp_obs_1)

      S.vor_slip_act = S.vor_slip_act + (slip_angle - S.vor_slip_act) * S.passed * 0.5 * transition_factor
      course_dev      = safeClamp(course_dev, -S.vor_dev_lim, S.vor_dev_lim, 0)
      S.vor_dev_act   = S.vor_dev_act + (course_dev - S.vor_dev_act) * S.passed * 0.5 * transition_factor

      local course_diff = pnp_course - course_now
      if course_diff > 180 then course_diff = course_diff - 360 elseif course_diff < -180 then course_diff = course_diff + 360 end

      roll_need = safeClamp(((course_diff - S.vor_slip_act) * 1.5 + S.vor_dev_act * 10) * transition_factor, -20, 20, 0)
      S.roll_show = roll_need
      if not nav_on then roll_need = 0 end

      S.course_stab_act = course_now
      S.course_stab_timer = 0
      S.ILS_dev_smth = 0

    elseif roll_submode == 6 then
      -- APP (LOC) — softened
      local course_dev = (secondNav and get(nav_cs_2) or get(nav_cs_1)) * 10
      local pnp_course = (get(absu_zpu_sel) == 1) and get(pkp_obs_2) or get(pkp_obs_1)

      S.ILS_dev_smth = S.ILS_dev_smth + (course_dev - S.ILS_dev_smth) * S.passed * 8 * transition_factor
      local dev_spd = 0
      if S.passed > 0 then dev_spd = (S.ILS_dev_smth - S.dev_last) / S.passed end
      S.dev_last = S.ILS_dev_smth

      if math.abs(course_dev) > 9 then
        local intercept_angle = math.min(S.APP_INTERCEPT_CAP, math.abs(course_dev) * 2)
        local new_course = pnp_course + intercept_angle * sign(course_dev)
        if new_course < 0 then new_course = new_course + 360 elseif new_course > 360 then new_course = new_course - 360 end
        local course_diff = new_course - course_now
        if course_diff > 180 then course_diff = course_diff - 360 elseif course_diff < -180 then course_diff = course_diff + 360 end
        roll_need = course_diff * 1.15 * transition_factor
        local roll_limit = S.APP_INTERCEPT_CAP * 0.6
        roll_need = safeClamp(roll_need, -roll_limit, roll_limit, 0)
        S.roll_show = roll_need
      else
        local K_ILS = S.ILS_GAIN_BASE * ((RV_alt > 250) and 2 or 1)
        local ILS_dev_limited = safeClamp(S.ILS_dev_smth * K_ILS, -S.ILS_LIM, S.ILS_LIM, 0)

        local ILS_spd_limited = safeClamp(dev_spd * (S.ILS_SPD_GAIN_BASE * ((RV_alt > 250) and 2 or 1)), -S.ILS_SPD_LIM, S.ILS_SPD_LIM, 0)

        if math.abs(S.ILS_spd_last - dev_spd) > S.SPIKE_THRESHOLD then
          ILS_spd_limited = ILS_spd_limited + (0 - ILS_spd_limited) * (1 - S.ALPHA_SPIKE)
          ILS_dev_limited = ILS_dev_limited + (0 - ILS_dev_limited) * S.ALPHA_SPIKE
        else
          ILS_spd_limited = ILS_spd_limited * S.ALPHA_NORMAL + (dev_spd * (S.ILS_SPD_GAIN_BASE * ((RV_alt > 250) and 2 or 1))) * (1 - S.ALPHA_NORMAL)
          ILS_dev_limited = ILS_dev_limited * S.ALPHA_NORMAL + (S.ILS_dev_smth * K_ILS) * (1 - S.ALPHA_NORMAL)
          ILS_spd_limited = safeClamp(ILS_spd_limited, -S.ILS_SPD_LIM, S.ILS_SPD_LIM, 0)
          ILS_dev_limited = safeClamp(ILS_dev_limited, -S.ILS_LIM, S.ILS_LIM, 0)
        end

        local roll_calc = (ILS_dev_limited + ILS_spd_limited) * transition_factor
        roll_need = roll_need + (roll_calc - roll_need) * S.passed

        S.ILS_spd_last = dev_spd

        local roll_limit = S.APP_FINE_ROLL_CAP * ((RV_alt > 250) and 1.5 or 1.0)
        roll_need = safeClamp(roll_need, -roll_limit, roll_limit, 0)
        S.roll_show = roll_need
      end

      S.course_stab_timer = 0
      local course_diff = course_now - S.course_stab_act
      if course_diff > 180 then course_diff = course_diff - 360 elseif course_diff < -180 then course_diff = course_diff + 360 end
      S.course_stab_act = S.course_stab_act + course_diff * S.passed * 3 * transition_factor

      if RV_alt <= 100 and math.abs(S.ILS_dev_smth) > 3 then set(absu_course_out, 1) end

    elseif roll_submode == 7 and get(absu_calc_toga_fail) == 0 then
      -- TOGA roll
      local course_diff = S.course_stab_act - course_now
      if course_diff > 180 then course_diff = course_diff - 360 elseif course_diff < -180 then course_diff = course_diff + 360 end
      roll_need = safeClamp(course_diff * 1.5 * transition_factor, -20, 20, 0)
      S.roll_show = roll_need
      S.ILS_dev_smth = 0

    else
      S.course_stab_timer = 0
      S.course_stab_act   = course_now
      S.ILS_dev_smth = 0
      S.roll_show = 0
    end

    -- ailerons
    if roll_mode == 1 then
      if S.mach < 1 then S.roll_coef = fastInterpolate(roll_ail_tbl, S.mach) else S.roll_coef = -0.8 end
      local ail_need = roll_cmd * S.roll_coef - roll_W * 0.08 * (0.3 + 0.01 * math.abs(roll_W2) / (0.01 * math.abs(roll_W2) + 1))
      S.roll_act = safeClamp(ail_need, -S.ail_lim, S.ail_lim, 0)
      S.roll_need_smth = S.roll_now
    elseif roll_mode == 2 then
      local rate_limit = 2 * transition_factor
      if roll_need - S.roll_need_smth > rate_limit then
        S.roll_need_smth = S.roll_need_smth + S.passed * 8
      elseif roll_need - S.roll_need_smth < -rate_limit then
        S.roll_need_smth = S.roll_need_smth - S.passed * 8
      else
        S.roll_need_smth = S.roll_need_smth + (roll_need - S.roll_need_smth) * S.passed * 8 * transition_factor
      end
      if get(absu_calc_roll_fail) == 0 then S.roll_act = roll_holder(S.roll_need_smth, S) end
    end

  else
    S.roll_act = 0
    S.roll_need_smth = S.roll_now
  end

  -- apply roll hydraulics (inline HS)
  if S.MASTER then
    set(
      absu_contr_roll,
      get(absu_contr_roll) +
      (S.roll_act - get(absu_contr_roll)) * S.passed *
      math.max(
        0,
        get(hydro_ra56_ail_1) * clamp((get(gs_press_1) - 10) / 70, 0, 1),
        get(hydro_ra56_ail_2) * clamp((get(gs_press_2) - 10) / 70, 0, 1),
        get(hydro_ra56_ail_3) * clamp((get(gs_press_3) - 10) / 70, 0, 1)
      ) * 10
    )
  end

  -------------------------------------------------------------------
  -- Yaw channel
  -------------------------------------------------------------------
  local yaw_res_need = 0
  if roll_mode >= 1 then
    S.yaw_act, S.yaw_I, S.yaw_P_last = yaw_holder(S)
    yaw_res_need = S.yaw_act
  else
    S.yaw_act = 0
    yaw_res_need = 0
  end
  if get(gear1_deflect) > 0.01 then yaw_res_need = 0 end

  if S.MASTER then
    set(
      absu_contr_yaw,
      get(absu_contr_yaw) +
      (yaw_res_need - get(absu_contr_yaw)) * S.passed *
      math.max(
        0,
        get(hydro_ra56_rud_1) * clamp((get(gs_press_1) - 10) / 70, 0, 1),
        get(hydro_ra56_rud_2) * clamp((get(gs_press_2) - 10) / 70, 0, 1),
        get(hydro_ra56_rud_3) * clamp((get(gs_press_3) - 10) / 70, 0, 1)
      ) * 10
    )
  end

  -------------------------------------------------------------------
  -- Director needles and flags
  -------------------------------------------------------------------
  local flag_roll  = bool2int((not nav_on and not app_on) or (get(absu_speed_test_2) == 1 and nav_on and app_on))
  local flag_pitch = bool2int((not nav_on and not app_on) or (get(absu_speed_test_2) == 1 and nav_on and app_on))

  if roll_submode == 1 or roll_submode == 2 then
    if not needles_on then
      S.roll_show = 25; S.pitch_show = 10
    elseif not app_on then
      S.roll_show = 0; S.pitch_show = 0
    else
      if (not isILS(get(freq_1)) or get(nav_cs_flag_1) == 1) and not secondNav then S.roll_show = 0 else S.roll_show = 0 end
      S.pitch_show = 0
    end

  elseif roll_submode == 3 then
    if not needles_on then
      S.roll_show = 25; S.pitch_show = 10
    elseif nav_on then
      S.roll_show = S.roll_show - S.roll_now; S.pitch_show = 0
    else
      S.roll_show = 0; S.pitch_show = 0
    end

  elseif roll_submode == 4 then
    if not needles_on then
      S.roll_show = 25; S.pitch_show = 10
    elseif not nav_on then
      S.roll_show = 0; S.pitch_show = 0
    else
      if isILS(get(freq_1)) or get(nav_cs_flag_1) == 1 then S.roll_show = 0 else S.roll_show = S.roll_show - S.roll_now end
      S.pitch_show = 0
    end

  elseif roll_submode == 5 then
    if not needles_on then
      S.roll_show = 25; S.pitch_show = 10
    elseif not nav_on then
      S.roll_show = 0; S.pitch_show = 0
    else
      if isILS(get(freq_2)) or get(nav_cs_flag_2) == 1 then S.roll_show = 0 else S.roll_show = S.roll_show - S.roll_now end
      S.pitch_show = 0
    end

  elseif roll_submode == 6 and pitch_submode == 5 then
    if not needles_on then
      S.roll_show = 25; S.pitch_show = 10
    elseif not app_on then
      S.roll_show = 0; S.pitch_show = 0
    else
      if (not isILS(get(freq_1)) or get(nav_cs_flag_1) == 1) and not secondNav then S.roll_show = 0 else S.roll_show = S.roll_show - S.roll_now end
      if (not isILS(get(freq_1)) or get(nav_gs_flag_1) == 1) and get(nav_gs_flag_2) == 1 then
        S.pitch_show = 0
      else
        S.pitch_show = S.pitch_show - S.pitch_now
      end
    end

  elseif roll_submode == 6 then
    if not needles_on then
      S.roll_show = 25; S.pitch_show = 10
    elseif not app_on then
      S.roll_show = 0; S.pitch_show = 0
    else
      if (not isILS(get(freq_1)) or get(nav_cs_flag_1) == 1) and not secondNav then S.roll_show = 0 else S.roll_show = S.roll_show - S.roll_now end
      S.pitch_show = 0
    end

  elseif roll_submode == 7 and pitch_submode == 6 then
    if not needles_on then
      S.roll_show = 25; S.pitch_show = 10
    elseif not app_on then
      S.roll_show = 0; S.pitch_show = 0
    else
      if not isILS(get(freq_1)) or get(nav_cs_flag_1) == 1 then S.roll_show = 0 else S.roll_show = 0 end
      S.pitch_show = 0
    end

  else
    S.roll_show = 25; S.pitch_show = 10
  end

  -- failure flags
  if (get(man_roll_lamp) == 1 and
      (get(absu_calc_roll_fail) == 1 or get(nav_cs_flag_1) == 1 or get(nav_cs_flag_2) == 1 or get(tks_fail_left) + get(tks_fail_right) == 2 or get(man_pitch_lamp) == 1))
      or get(absu_speed_test_2) == 1 then
    flag_roll = 1; S.roll_show = 25
  end

  if (get(man_pitch_lamp) == 1 and
      (get(absu_calc_pitch_fail) == 1 or get(nav_gs_flag_1) == 1 or get(man_roll_lamp) == 1))
      or get(absu_speed_test_2) == 1 then
    flag_pitch = 1; S.pitch_show = 10
  end

  -- lamps reset
  if get(rv_angle) <= get(dh_set) or RV_alt > 100 then
    set(absu_gs_out, 0)
    set(absu_course_out, 0)
  end

  if S.MASTER then
    set(absu_roll_ind,  S.roll_show)
    set(absu_pitch_ind, S.pitch_show)
    set(absu_roll_flag,  flag_roll)
    set(absu_pitch_flag, flag_pitch)
  end
end

-----------------------------------------------------------------------
-- Functions (now parameterized with S to avoid upvalues)
-----------------------------------------------------------------------

-- manipulates elevator and trimmer by a given pitch angle
function pitch_holder(pitch_hold, S)
    local P = (pitch_hold - S.pitch_now)
    local D = get(pitch_rate) * (1 - get(absu_damp_pitch_fail))

    local PID_part = P * PID_PARAMS.ROLL.Kp - D * 0.15

    -- roll coupling vs bank; boost with gear down
    local pitch_stab_coef = S.pitch_stab_roll_coef
    if S.gear_down then
        pitch_stab_coef = 0.00425 * 2
    end
    local roll_part = math.abs(S.roll_now) * pitch_stab_coef * line(S.mach, 0.4, 1.3, 0.8, 0.8) * transition_factor

    local elev_pos = PID_part + roll_part
    elev_pos = safeClamp(elev_pos, -S.elev_lim, S.elev_lim, 0)

    local new_pitch_act = S.pitch_act + (elev_pos - S.pitch_act) * S.passed * 5

    if S.MASTER then
        if new_pitch_act > 0.015 then
            set(absu_pitch_trimm, 1)
        elseif new_pitch_act < -0.015 then
            set(absu_pitch_trimm, -1)
        else
            set(absu_pitch_trimm, 0)
        end
    end

    return new_pitch_act
end

-- manipulates ailerons by a given roll angle
function roll_holder(roll_hold, S)
    local P = (roll_hold - S.roll_now)

    local roll_W  = get(roll_rate)
    local roll_W2 = get(roll_acc)
    if get(absu_damp_roll_fail) == 1 then roll_W = 0; roll_W2 = 0 end

    local roll_stab_coef = PID_PARAMS.ROLL.Kp
    if S.mach < 0.5 then 
        roll_stab_coef = line(S.mach, 0.5, PID_PARAMS.ROLL.Kp, 0, PID_PARAMS.ROLL.Kp * 2) 
    end

    local PID = P * roll_stab_coef - roll_W * PID_PARAMS.ROLL.Kd * (0.5 + 0.01 * math.abs(roll_W2) / (0.01 * math.abs(roll_W2) + 1))
    local new_roll_act = S.roll_act + (PID - S.roll_act) * S.passed * 5
    new_roll_act = safeClamp(new_roll_act, -S.ail_lim, S.ail_lim, 0)
    return new_roll_act
end

function yaw_holder(S)
    local P  = get(slip) * (1 - get(absu_damp_yaw_fail))
    local KP = 0.01

    local K_I = 0
    local yaw_I = S.yaw_I + P * S.passed * K_I
    yaw_I = yaw_I - sign(yaw_I) * S.passed * 0.1
    yaw_I = safeClamp(yaw_I, -0.1, 0.1, 0)

    local D = 0
    if S.passed > 0 then D = (P - S.yaw_P_last) / S.passed end
    local K_D = 0.01

    local PID = P * KP + yaw_I + D * K_D

    local new_yaw_act = S.yaw_act + (PID - S.yaw_act) * S.passed * 5
    new_yaw_act = safeClamp(new_yaw_act, -0.4, 0.4, 0)

    return new_yaw_act, yaw_I, P
end
