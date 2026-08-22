-- Compatibility notifier stubs retained for existing dataref definitions.
function tu154_hear_spu2on_DRhandler() end
function tu154_azs_emerg_trim_DRhandler() end

-- Legacy helper for writable datarefs that are created from Lua.
function deferred_dataref(name,type,notifier)
    print("Deferred dataref: "..name)
    local dref = XLuaCreateDataRef(name, type, "yes", notifier)
    return wrap_dref_any(dref, type)
end
  
-- Centralized dataref binding -------------------------------------------------

--[[ 
XTLua executes each script in a private environment created by init.
xtlua. Writing the properties into that environment is important: 
namespace_write() recognizes the find_dataref() property objects 
and preserves the familiar transparent read/write syntax used by the 
rest of this script.
--]]

local function bind_datarefs(definitions)
    local env = getfenv(1)

    for name, path in pairs(definitions) do
        env[name] = find_dataref(path)
    end
end

local DATAREFS = {
    -- Electrical power and common simulation state
    simDR_36vl = "tu154/custom/elec/bus36_volt_left",
    simDR_36vr = "tu154/custom/elec/bus36_volt_right",
    simDR_on_ground = "sim/flightmodel/failures/onground_all",
    simDR_passed = "sim/operation/misc/frame_rate_period",
    simDR_time = "sim/time/total_running_time_sec",
    simDR_oat = "sim/cockpit2/temperature/outside_air_temp_deg",
    -- Flight controls, trim and hydraulics
    simDR_thr1 = "tu154/custom/controlls/throttle_1",
    simDR_thr2 = "tu154/custom/controlls/throttle_2",
    simDR_thr3 = "tu154/custom/controlls/throttle_3",
    simDR_yoke_p = "tu154/custom/controlls/yoke_pitch",
    simDR_yoke_r = "tu154/custom/controlls/yoke_roll",
    simDR_pitch_trim = "tu154/custom/trimmers/int_pitch_trim",
    simDR_emerg_trim = "tu154/custom/switchers/console/emerg_elev_trimm",
    simDR_hyd1_press = "tu154/custom/hydro/gs_press_1",
    simDR_hyd2_press = "tu154/custom/hydro/gs_press_2",
    simDR_hyd3_press = "tu154/custom/hydro/gs_press_3",
    simDR_hyd_emer_press = "tu154/custom/hydro/gs_press_4",
    -- ABSU / STU and checklist controls
    simDR_gliss_lit = "tu154/custom/lights/button/absu_gz",
    simDR_at_mode = "tu154/custom/absu/stu_mode",
    simDR_sw_sound = "tu154/custom/switchers/console/nvu_corr_on",
    simDR_spd_but = "tu154/custom/buttons/console/absu_stab_speed",
    simDR_spd_but_lit = "tu154/custom/lights/button/absu_stab_spd",
    simDR_absu_turn = "tu154/custom/switchers/console/absu_turn_handle",
    simDR_absu_zk = "tu154/custom/buttons/console/absu_zk",
    simDR_absu_reset = "tu154/custom/buttons/console/absu_reset",
    simDR_absu_nvu = "tu154/custom/buttons/console/absu_nvu",
    simDR_absu_pitch_mode = "tu154/custom/absu/pitch_sub_mode",
    simDR_checklist_select = "tu154/custom/checklist/checklist_selected",
    simDR_gpss = "sim/cockpit2/autopilot/gpss_status",
    -- DISS / NVU
    simDR_diss_cc = "tu154/custom/nvu/diss_cc",
    simDR_diss_mode = "tu154/custom/nvu/diss_mode",
    simDR_diss_slip = "tu154/custom/nvu/diss_slip_angle",
    simDR_diss_gs = "tu154/custom/nvu/diss_groundspeed",
    simDR_diss_wnd_spd = "tu154/custom/nvu/diss_wind_spd",
    simDR_diss_wnd_crs = "tu154/custom/nvu/diss_wind_course",
    simDR_mid_flag = "tu154/custom/gauges/speed/speed_mid_flag",
    simDR_needle = "tu154/custom/gauges/speed/speed_mid_needle",
    -- APU
    simDR_apu_start_ready = "tu154/custom/lights/apu/start_ready",
    simDR_apu_oilt = "tu154/custom/eng/apu_oil_t",
    simDR_apu_cc = "tu154/custom/elec/gen4_amp",
    simDR_start_seq = "tu154/custom/elec/apu_start_seq",
    simDR_apu_n1 = "tu154/custom/eng/apu_n1",
    simDR_apu_working = "tu154/custom/lights/apu/work_mode",
    simDR_apu_start_mode = "tu154/custom/switchers/eng/apu_start_mode",
    simDR_start_apu = "tu154/custom/lights/apu/start_apu",
    simDR_lamp_test_apu = "tu154/custom/buttons/lamp_test_apu",
    simDR_apu_bleed = "tu154/custom/eng/apu_air_doors",
    simDR_apu_bleed_sw = "tu154/custom/switchers/eng/apu_air_bleed",
    -- Tu-154M flap aerodynamics
    simDR_flaps_cl = "sim/aircraft/controls/acf_flap_cl",
    simDR_flaps_cd = "sim/aircraft/controls/acf_flap_cd",
    simDR_flaps_cm = "sim/aircraft/controls/acf_flap_cm",
    simDR_flaps2_cl = "sim/aircraft/controls/acf_flap2_cl",
    simDR_flaps2_cd = "sim/aircraft/controls/acf_flap2_cd",
    simDR_flaps2_cm = "sim/aircraft/controls/acf_flap2_cm",
    simDR_flap_inn_L = "sim/flightmodel/controls/wing1l_fla1def",
    simDR_flap_inn_R = "sim/flightmodel/controls/wing1r_fla1def",
    simDR_flap_mid_L = "sim/flightmodel/controls/wing2l_fla2def",
    simDR_flap_mid_R = "sim/flightmodel/controls/wing2r_fla2def",
    -- Landing lights and brakes
    simDR_light_l = "tu154/custom/lights/landing_mode_set_L",
    simDR_light_r = "tu154/custom/lights/landing_mode_set_R",
    simDR_light_l_ext = "tu154/custom/lights/landing_ext_set_L",
    simDR_light_r_ext = "tu154/custom/lights/landing_ext_set_R",
    simDR_gear_blocks = "tu154/custom/anim/gear_blocks",
    simDR_gear_fan = "tu154/custom/switchers/eng/gear_fan",
    simDR_park_brake = "tu154/custom/controll/parking_brake",
    simDR_brake_l = "tu154/custom/gauges/console/gear_brake_press_L",
    simDR_brake_r = "tu154/custom/gauges/console/gear_brake_press_R",
    simDR_ped_brake_l = "tu154/custom/controlls/brake_L",
    simDR_ped_brake_r = "tu154/custom/controlls/brake_R",
    simDR_emerg_brake = "tu154/custom/controlls/brake_emerg",
    -- SP-50 / navigation receivers
    simDRcrs_flag1 = "tu154/custom/radio/nav1_cs_flag",
    simDRgs_flag1 = "tu154/custom/radio/nav1_gs_flag",
    simDRcrs_flag2 = "tu154/custom/radio/nav2_cs_flag",
    simDRgs_flag2 = "tu154/custom/radio/nav2_gs_flag",
    simDRcrs_np1 = "tu154/custom/switchers/ovhd/curs_np_on_1",
    simDRcrs_np2 = "tu154/custom/switchers/ovhd/curs_np_on_2",
    simDRsp50_c1 = "tu154/custom/lights/small/sp50_c1",
    simDRsp50_c2 = "tu154/custom/lights/small/sp50_c2",
    simDRsp50_g1 = "tu154/custom/lights/small/sp50_g1",
    simDRsp50_g2 = "tu154/custom/lights/small/sp50_g2",
    simDRnav1mhz = "sim/cockpit2/radios/actuators/nav1_frequency_Mhz",
    simDRnav2mhz = "sim/cockpit2/radios/actuators/nav2_frequency_Mhz",
    -- Indicators, test controls and legacy animation helpers
    simDR_lit_test_front = "tu154/custom/buttons/lamp_test_front",
    simDR_ping_pong = "sim/graphics/animation/ping_pong_2",
    simDR_sin_wave = "sim/graphics/animation/sin_wave_2",
    simDRgeartestup = "tu154/custom/buttons/lamp_test_upper_gear",
    simDR_but_sound = "tu154/custom/buttons/srpbz/but_down",
    simDR_flood_front = "tu154/custom/lights/front_panel_flood",
    simDR_toga = "tu154/custom/lights/toga",
    simDR_elev_load = "tu154/custom/gauges/misc/elevator_pos_ind",
    simDR_alrn_load = "tu154/custom/gauges/misc/aileron_pos_ind",
    simDR_rud_load = "tu154/custom/gauges/misc/rudder_pos_ind",
    simDR_cab_light = "sim/weapons/Prad",
    -- Lamps excluded from the general front-panel lamp test
    simDR_zk_lit = "tu154/custom/lights/button/absu_zk",
    simDR_reset_lit = "tu154/custom/lights/button/absu_reset",
    simDR_nvu_lit = "tu154/custom/lights/button/absu_nvu",
    simDR_app_lit = "tu154/custom/lights/button/absu_app",
    simDR_az1_lit = "tu154/custom/lights/button/absu_az1",
    simDR_az2_lit = "tu154/custom/lights/button/absu_az2",
    simDR_stab_h_lit = "tu154/custom/lights/button/absu_stab_h",
    simDR_stab_m_lit = "tu154/custom/lights/button/absu_stab_m",
    simDR_stab_v_lit = "tu154/custom/lights/button/absu_stab_v",
    simDR_stab_spd_lit = "tu154/custom/lights/button/absu_stab_spd",
    simDR_thro1_lit = "tu154/custom/lights/button/absu_thro1",
    simDR_thro2_lit = "tu154/custom/lights/button/absu_thro2",
    simDR_thro3_lit = "tu154/custom/lights/button/absu_thro3",
    simDR_stu_pitch = "tu154/custom/lights/small/stu_pitch",
    simDR_stu_roll = "tu154/custom/lights/small/stu_roll",
    simDR_stu_toga = "tu154/custom/lights/small/stu_toga",
    simDR_at1 = "tu154/custom/lights/small/at_1",
    simDR_at2 = "tu154/custom/lights/small/at_2",
}

bind_datarefs(DATAREFS)

-- Tu-154M flap aerodynamics.
-- The fixed CL/CD values and CM schedules mirror the calibrated flap model.
local FLAP1_CL = 1.029
local FLAP1_CD = 0.064
local FLAP2_CL = 1.165
local FLAP2_CD = 0.068

-- 80 percent of the calculated C-selector coupling is compensated.
-- The remaining 20 percent avoids pitch reversal and preserves useful
-- elevator margin for the F and A selector schedules.
local flap1_cm_tbl = {
    { -10, -0.4480 },
    {   0, -0.4480 },
    {  15, -0.4480 },
    {  28, -0.3490 },
    {  36, -0.4102 },
    {  45, -0.3762 },
    { 100, -0.3762 },
}

local flap2_cm_tbl = {
    { -10, -0.5071 },
    {   0, -0.5071 },
    {  13, -0.5071 },
    {  25, -0.3950 },
    {  32, -0.4642 },
    {  40, -0.4257 },
    { 100, -0.4257 },
}

local function interpolate_table(tbl, value)
    if value <= tbl[1][1] then
        return tbl[1][2]
    end
    for index = 2, #tbl do
        local upper = tbl[index]
        if value <= upper[1] then
            local lower = tbl[index - 1]
            local span = upper[1] - lower[1]
            if span == 0 then
                return upper[2]
            end
            local ratio = (value - lower[1]) / span
            return lower[2] + (upper[2] - lower[2]) * ratio
        end
    end

    return tbl[#tbl][2]
end

-- Local assignments force XTLua to 
-- refresh the external datarefs before
-- their values are used by the calculations.
local function update_flap_coefficients()
    local flap_inn_left = simDR_flap_inn_L
    local flap_inn_right = simDR_flap_inn_R
    local flap_mid_left = simDR_flap_mid_L
    local flap_mid_right = simDR_flap_mid_R
    local flap_inn = 0.5 * (flap_inn_left + flap_inn_right)
    local flap_mid = 0.5 * (flap_mid_left + flap_mid_right)
    simDR_flaps_cl = FLAP1_CL
    simDR_flaps_cd = FLAP1_CD
    simDR_flaps_cm = interpolate_table(flap1_cm_tbl, flap_inn)
    simDR_flaps2_cl = FLAP2_CL
    simDR_flaps2_cd = FLAP2_CD
    simDR_flaps2_cm = interpolate_table(flap2_cm_tbl, flap_mid)
end

-- Runtime state -----------------------------------------------------------
-- Saved lamp states are restored while 
-- the general front-panel lamp test runs.
local zk_lit = 0
local reset_lit = 0
local nvu_lit = 0
local gliss_lit = 0
local app_lit = 0
local az1_lit = 0
local az2_lit = 0
local stab_h_lit = 0
local stab_m_lit = 0
local stab_v_lit = 0
local stab_spd_lit = 0
local thro1_lit = 0
local thro2_lit = 0
local thro3_lit = 0
local stu_pitch = 0
local stu_roll = 0
local stu_toga = 0
local at1 = 0
local at2 = 0
local sw_apu_sound = 0
local apu_bleed_new = 0
local checklist_num = 0
local diss_timer = 0
local diss_timer_start = 1
local diss_spd = 0
local diss_slip = 0
local diss_wnd_spd = 0
local diss_wnd_crs = 0
local current_pitch_trim = 0
local current_pitch_trim_stu = 0
local oat_delta = 0
local apu_pause_1 = 0
local apu_pause_2 = 0
local apu_pause_3 = 0
local apu_tr_n = 0
local apu_tr_n_set = 0
local absu_turn_zero = 0
local lights = 0
local wait = 0
local blocks_wait = 0
local gear_block_time = 0
local lights_set = 0
local bus36 = 0
local pressed = 0
local start_self_test_var_l = 1
local var_l_dur_test = 8000
local thr_delta = 0
local apu_was_run = 0
local gs_fl = 0



-- Command handlers --------------------------------------------------------
-- Landing-light commands move the selector immediately; physical extension is
-- delayed in systems() to represent the lamp mechanism.
function land_lights_up_CMDhandler(phase, duration) 
    if phase == 0 then
        if simDR_light_l < 1 and simDR_light_r < 1 then
            simDR_light_l = simDR_light_l +1
            simDR_light_r = simDR_light_r +1
        end
    end
    if phase == 2 then
        if simDR_light_l > 0 and simDR_light_r > 0 then
            lights = 1
            wait = 1
            lights_set = 1
        end
        if simDR_light_l == 0 and simDR_light_r == 0 then
            lights = 0
            wait = 1
            lights_set = 1
        end
    end
end
function land_lights_down_CMDhandler(phase, duration) 
    if phase == 0 then
        if simDR_light_l > -1 and simDR_light_r > -1 then
            simDR_light_l = simDR_light_l -1
            simDR_light_r = simDR_light_r -1
        end
    end
    if phase == 2 then
        if simDR_light_l < 0 and simDR_light_r < 0 then
            lights = 1
            wait = 1
            lights_set = 1
        end
        if simDR_light_l == 0 and simDR_light_r == 0 then
            lights = 0
            wait = 1
            lights_set = 1
        end
    end
end




-- ABSU turn handle: +/-2 per command step, +/-50 travel, with a center detent.
function absu_turn_left_CMDhandler(phase, duration)
    if phase == 0 then
        if simDR_absu_turn > -50 then
            local next_value = math.max(-50, simDR_absu_turn - 2)

            -- Preserve the center detent when approaching zero from the right.
            if simDR_absu_turn > 0 and next_value < 0 then
                next_value = 0
            end

            simDR_absu_turn = next_value
        end
    elseif phase == 1 and duration > 0.3 then
        if simDR_absu_turn > 0 and absu_turn_zero < 1 then
            local next_value = simDR_absu_turn - 2

            if next_value <= 0 then
                simDR_absu_turn = 0
                absu_turn_zero = 1
            else
                simDR_absu_turn = next_value
            end
        elseif simDR_absu_turn < -0.01 and absu_turn_zero < 1 then
            simDR_absu_turn = math.max(-50, simDR_absu_turn - 2)
        end
    elseif phase == 2 then
        absu_turn_zero = 0
    end
end

function absu_turn_right_CMDhandler(phase, duration)
    if phase == 0 then
        if simDR_absu_turn < 50 then
            local next_value = math.min(50, simDR_absu_turn + 2)

            -- Preserve the center detent when approaching zero from the left.
            if simDR_absu_turn < 0 and next_value > 0 then
                next_value = 0
            end

            simDR_absu_turn = next_value
        end
    elseif phase == 1 and duration > 0.3 then
        if simDR_absu_turn < 0 and absu_turn_zero < 1 then
            local next_value = simDR_absu_turn + 2

            if next_value >= 0 then
                simDR_absu_turn = 0
                absu_turn_zero = 1
            else
                simDR_absu_turn = next_value
            end
        elseif simDR_absu_turn > 0.01 and absu_turn_zero < 1 then
            simDR_absu_turn = math.min(50, simDR_absu_turn + 2)
        end
    elseif phase == 2 then
        absu_turn_zero = 0
    end
end

function absu_turn_center_CMDhandler(phase, duration) 
    if phase == 0 then
            simDR_absu_turn = 0
    end
end

function absu_nvu_CMDhandler(phase, duration) 
    if phase == 0 then
            simDR_absu_nvu = 1
    elseif phase == 2 then
            simDR_absu_nvu = 0
    end
end

function absu_zk_CMDhandler(phase, duration) 
    if phase == 0 then
            simDR_absu_zk = 1
    elseif phase == 2 then
            simDR_absu_zk = 0
    end
end

function absu_reset_CMDhandler(phase, duration) 
    if phase == 0 then
            simDR_absu_reset = 1
    elseif phase == 2 then
            simDR_absu_reset = 0
    end
end

function checklist_next_CMDhandler(phase, duration) 
    if phase == 0 then
        if checklist_num < 9 then
            checklist_num = checklist_num + 1
            simDR_checklist_select = checklist_num
        else
            checklist_num = 1
            simDR_checklist_select = checklist_num
        end
    end   	
end


-- Register custom commands after all handlers are defined.
checklist_next_cmnd	= create_command("t154/checklist_next", "T154 Checklist next", checklist_next_CMDhandler)
absu_roll_left_cmnd	= create_command("t154/absu_roll_left", "T154 ABSU Roll left", absu_turn_left_CMDhandler)
absu_roll_right_cmnd	= create_command("t154/absu_roll_right", "T154 ABSU Roll right", absu_turn_right_CMDhandler)
absu_roll_center_cmnd	= create_command("t154/absu_roll_center", "T154 ABSU Roll center", absu_turn_center_CMDhandler)
absu_reset_cmnd	= create_command("t154/absu_reset", "T154 ABSU SBROS", absu_reset_CMDhandler)
absu_zk_cmnd	= create_command("t154/absu_zk", "T154 ABSU ZK", absu_zk_CMDhandler)
absu_nvu_cmnd	= create_command("t154/absu_nvu", "T154 ABSU NVU", absu_nvu_CMDhandler)
lights_up_cmnd	= create_command("t154/lights_up", "T154 Lights up", land_lights_up_CMDhandler)
lights_down_cmnd	= create_command("t154/lights_down", "T154 Lights down", land_lights_down_CMDhandler)


function systems()

    -- Front-panel lamp-test compatibility ------------------------------------
    -- Keep selected ABSU/STU lamps at their real pre-test state.
if simDR_lit_test_front > 0 then
    simDR_zk_lit = zk_lit
    simDR_reset_lit = reset_lit
    simDR_nvu_lit = nvu_lit
    simDR_gliss_lit = gliss_lit
    simDR_app_lit = app_lit
    simDR_az1_lit = az1_lit
    simDR_az2_lit = az2_lit
    simDR_stab_h_lit = stab_h_lit
    simDR_stab_m_lit = stab_m_lit
    simDR_stab_v_lit = stab_v_lit
    simDR_stab_spd_lit = stab_spd_lit
    simDR_thro1_lit = thro1_lit
    simDR_thro2_lit = thro2_lit
    simDR_thro3_lit = thro3_lit
    simDR_stu_pitch = stu_pitch
    simDR_stu_roll = stu_roll
    simDR_stu_toga = stu_toga
    simDR_at1 = at1
    simDR_at2 = at2
        
else
    stu_pitch = simDR_stu_pitch
    stu_roll = simDR_stu_roll
    stu_toga = simDR_stu_toga
    at1 = simDR_at1
    at2 = simDR_at2
    zk_lit = simDR_zk_lit
    reset_lit = simDR_reset_lit
    nvu_lit = simDR_nvu_lit
    gliss_lit = simDR_gliss_lit
    app_lit = simDR_app_lit
    az1_lit = simDR_az1_lit
    az2_lit = simDR_az2_lit
    stab_h_lit = simDR_stab_h_lit
    stab_m_lit = simDR_stab_m_lit
    stab_v_lit = simDR_stab_v_lit
    stab_spd_lit = simDR_stab_spd_lit
    thro1_lit = simDR_thro1_lit
    thro2_lit = simDR_thro2_lit
    thro3_lit = simDR_thro3_lit
end

-- APU bleed and start-ready interlock -----------------------------------
if simDR_apu_bleed > 0.01 and simDR_lamp_test_apu < 1 then
   simDR_apu_start_ready = 0
end
    
-- Preserve the legacy smoothed APU bleed-door state. 
-- The local value is
-- currently not written to an external dataref.
if simDR_apu_n1 > 90 then
    if simDR_apu_bleed_sw > 0 then
       if apu_bleed_new < 1 then
        apu_bleed_new = apu_bleed_new + 0.11 * SIM_PERIOD
       else
        apu_bleed_new = 1
       end
    elseif simDR_apu_bleed_sw < 0 then
       if apu_bleed_new > 0 then
       apu_bleed_new = apu_bleed_new - 0.11 * SIM_PERIOD
       else
        apu_bleed_new = 0
       end
    end
else
    if apu_bleed_new > 0 then
      apu_bleed_new = apu_bleed_new - 0.01
    else
      apu_bleed_new = 0
    end
end
    
 
-- Aircraft integration expects GPSS status 2 while this systems script runs.
simDR_gpss = 2 
-- Upper gear lamp-test button sound.
if simDRgeartestup > 0 then
    simDR_but_sound = 1
    pressed = 1
end
if simDRgeartestup < 1 and pressed > 0 then
    simDR_but_sound = 0
    pressed = 0
end

-- Brake pressure indication with wheel chocks installed -----------------
-- Reproduce normal and emergency brake gauge pressure while the aircraft is
-- immobilized by the external gear blocks.
if simDR_gear_blocks > 0 then
    if simDR_park_brake < 1 and simDR_ped_brake_l == 0 and simDR_ped_brake_r == 0 and simDR_emerg_brake == 0 then
        simDR_brake_l = 0
        simDR_brake_r = 0
    end
    if simDR_ped_brake_l > 0 then
        if simDR_hyd1_press > 25 then
        simDR_brake_l = simDR_ped_brake_l * 120
        elseif simDR_emerg_brake == 0 then
        simDR_brake_l = 0
        end
    end
    if simDR_ped_brake_r > 0 then
        if simDR_hyd1_press > 25 then
        simDR_brake_r = simDR_ped_brake_r * 120
        elseif simDR_emerg_brake == 0 then
        simDR_brake_r = 0
        end
    end
    if simDR_park_brake > 0 then
        if simDR_hyd1_press > 25 then
        simDR_brake_l = simDR_ped_brake_l * 120
        simDR_brake_r = simDR_ped_brake_r * 120
        elseif simDR_emerg_brake == 0 then
        simDR_brake_l = 0
        simDR_brake_r = 0
        end
    end
    if simDR_emerg_brake > 0 then
        if simDR_hyd_emer_press > 25 and simDR_ped_brake_l < simDR_emerg_brake and simDR_ped_brake_r < simDR_emerg_brake then   
        simDR_brake_l = simDR_emerg_brake * 120
        simDR_brake_r = simDR_emerg_brake * 120
        elseif simDR_ped_brake_l == 0 and simDR_ped_brake_r == 0 then
        simDR_brake_l = 0
        simDR_brake_r = 0
        end
    end
    gear_block_time = 1
end

if simDR_gear_blocks < 1 and gear_block_time > 0  then
   blocks_wait = 1
   gear_block_time = 0
end 
    
if blocks_wait > 0 then 
        blocks_wait = blocks_wait - simDR_passed
        if simDR_park_brake < 1 and simDR_ped_brake_l == 0 and simDR_ped_brake_r == 0 and simDR_emerg_brake == 0 then
            simDR_brake_l = 0
            simDR_brake_r = 0
        end
end 

    
-- Landing-light extension/retraction delay -------------------------------
if wait > 0 then 
        wait = wait - simDR_passed
end   
if lights == 1 and wait < 0.1 and lights_set > 0 then
    simDR_light_l_ext = 1
    simDR_light_r_ext = 1
    lights_set = 0
end
if lights == 0 and wait < 0.1 and lights_set > 0 then
    lights_set = 0
    simDR_light_l_ext = 0
    simDR_light_r_ext = 0
end
-- Flap aerodynamics are updated in before_physics().

    

-- APU temperature limits and hot-start behavior --------------------------
if simDR_apu_working > 0 then
    apu_tr_n = 0
    apu_was_run = 1
end
 

if apu_was_run < 1 then
    if simDR_apu_oilt < 5 then
        simDR_apu_oilt = 5
    end
else
    if simDR_apu_oilt < 20 then
        simDR_apu_oilt = 20
    end
end

if simDR_apu_oilt > 112 and simDR_apu_cc < 123 then
    simDR_apu_oilt = 112
end
    
if simDR_start_seq > 0 then
    if simDR_oat > 25 then
        oat_delta = (simDR_oat - 25)
        if apu_tr_n_set < 1 then
            apu_tr_n = apu_tr_n + 1
            apu_tr_n_set = 1
        end
    else
        oat_delta = 0
    end
    if oat_delta > 0 and apu_pause_1 < math.random(-1,4) and apu_tr_n < 4 and simDR_apu_start_mode > 0 then  
        if simDR_apu_n1 > math.random(17,20) then
            apu_pause_1 = apu_pause_1 + simDR_passed
            simDR_apu_n1 = simDR_apu_n1 - 0.22
        end 
    end
    if oat_delta > math.random(6,15) and apu_pause_2 < math.random(-1,4) and apu_tr_n < 3 and simDR_apu_start_mode > 0 then  
        if simDR_apu_n1 > math.random(21,27) then
            apu_pause_2 = apu_pause_2 + simDR_passed
            simDR_apu_n1 = simDR_apu_n1 - 0.22
        end 
    end
    if oat_delta > math.random(16,20) and apu_pause_3 < math.random(-1,4) and apu_tr_n < 2 and simDR_apu_start_mode > 0 then  
        if simDR_apu_n1 > math.random(28,41) then
            apu_pause_3 = apu_pause_3 + simDR_passed
            simDR_apu_n1 = simDR_apu_n1 - 0.22
        end 
    end
else
    apu_pause_1 = 0
    apu_pause_2 = 0
    apu_pause_3 = 0
    apu_tr_n_set = 0
end
    

-- Synchronize the command-side checklist index with external selections.
if simDR_checklist_select > 0 then
  checklist_num = simDR_checklist_select
end   
    
    
-- DISS warm-up -----------------------------------------------------------
-- Freeze DISS outputs for 180 seconds after power-up, then enable normal mode.
if simDR_diss_cc > 0 and diss_timer_start > 0 then
    if diss_timer == 0 then
        diss_timer = simDR_time
        diss_spd = simDR_diss_gs
        diss_slip = simDR_diss_slip
        diss_wnd_spd = simDR_diss_wnd_spd
        diss_wnd_crs = simDR_diss_wnd_crs
    end
    if (simDR_time - diss_timer) < 180 then
        simDR_diss_gs = diss_spd
        simDR_diss_slip = diss_slip
        simDR_diss_wnd_spd = diss_wnd_spd
        simDR_diss_wnd_crs = diss_wnd_crs
        simDR_diss_mode = 0
        if simDR_mid_flag > 0 then
            simDR_needle  = 0
        end
    else
        simDR_diss_mode = 1
        diss_timer = 0
        diss_timer_start = 0
        diss_spd = 0
        diss_slip = 0
        diss_wnd_spd = 0
        diss_wnd_crs = 0
    end
end
    
if simDR_diss_cc < 1 then
        diss_timer = 0
        diss_timer_start = 1
end
    

-- Total hydraulic-loss control limitation -------------------------------
if simDR_hyd1_press < 30 and simDR_hyd2_press < 30 and simDR_hyd3_press < 30 then
        if simDR_yoke_p > 0.2 then
            simDR_yoke_p = 0.2 
        elseif simDR_yoke_p < -0.2 then
            simDR_yoke_p = -0.2 
        end
        if simDR_yoke_r > 0.12 then
            simDR_yoke_r = 0.12 
        elseif simDR_yoke_r < -0.12 then
            simDR_yoke_r = -0.12 
        end
end    
    
-- STU / autothrottle mode coordination ----------------------------------
if simDR_at_mode < 4 then
            if simDR_thr1 < 0.08 and simDR_thr2 < 0.08 and simDR_thr3 < 0.08 then
                if simDR_spd_but > 0 then
                    simDR_at_mode = 2
                end
            else
                if simDR_at_mode > 1.5 then
                    if simDR_spd_but > 0 then
                        simDR_at_mode = 3
                    end
                end
            end
        if simDR_absu_pitch_mode == 6 then
          simDR_at_mode = 2
        end
end
  

-- 36 V supply and SP-50 indication logic --------------------------------
if simDR_36vl > 5 then
    bus36 = 1
elseif simDR_36vr > 5 then
    bus36 = 1
else
    bus36 = 0
end

if bus36 > 0 then
    
    
    if simDR_cab_light[3] < 1 then
        simDR_cab_light[3] = 1
    end
    if simDRcrs_np1 > 0 then
        if simDRcrs_flag1 < 1 and simDRnav1mhz < 112 then
            simDRsp50_c1 = 1
        else
            simDRsp50_c1 = 0
        end
        if simDRgs_flag1 < 1 and simDRnav1mhz < 112 then
            simDRsp50_g1 = 1
        else
            simDRsp50_g1 = 0
        end
    else
        simDRsp50_c1 = 0
        simDRsp50_g1 = 0
    end
    if simDRcrs_np2 > 0 then
        if simDRcrs_flag2 < 1 and simDRnav2mhz < 112 then
            simDRsp50_c2 = 1
        else
            simDRsp50_c2 = 0
        end
        if simDRgs_flag2 < 1 and simDRnav2mhz < 112 then
            simDRsp50_g2 = 1
        else
            simDRsp50_g2 = 0
        end
    else
        simDRsp50_c2 = 0
        simDRsp50_g2 = 0
    end       
else
        simDRsp50_c1 = 0
        simDRsp50_g1 = 0
        simDRsp50_c2 = 0
        simDRsp50_g2 = 0
end
    

-- Ground-only control-load indication and TOGA trim behavior -----------
if simDR_on_ground > 0 then
    simDR_elev_load = simDR_elev_load * 0.18
    simDR_alrn_load = simDR_alrn_load * 0.18
    simDR_rud_load = simDR_rud_load * 0.18
    if simDR_toga < 1 then
        current_pitch_trim_stu = simDR_pitch_trim
    end
    if simDR_toga > 0 and simDR_lit_test_front < 1 then
        current_pitch_trim_stu = current_pitch_trim_stu + 0.00015
        simDR_pitch_trim = current_pitch_trim_stu
    end
end     


-- Inhibit the GLISS lamp when neither receiver has a usable glideslope.
if simDRgs_flag1 < 1 then
        gs_fl = 0
elseif simDRgs_flag2 < 1 then
        gs_fl = 0
else
        gs_fl = 1
end    

if gs_fl > 0 then
        simDR_gliss_lit = 0
end

end

-- XTLua lifecycle callbacks ----------------------------------------------
function flight_start()
    update_flap_coefficients()
end

function before_physics()
    update_flap_coefficients()
end

function after_physics()
    systems()
end
