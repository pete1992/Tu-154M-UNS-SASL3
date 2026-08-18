function tu154_hear_spu2on_DRhandler() end
function tu154_azs_emerg_trim_DRhandler() end

function deferred_dataref(name,type,notifier)
	print("Deffered dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end
  
simDR_apu_start_ready = find_dataref("tu154/custom/lights/apu/start_ready") 
simDR_36vl				= find_dataref("tu154/custom/elec/bus36_volt_left")
simDR_36vr				= find_dataref("tu154/custom/elec/bus36_volt_right")
simDR_on_ground = find_dataref("sim/flightmodel/failures/onground_all") 
simDR_lit_test_front = find_dataref("tu154/custom/buttons/lamp_test_front")
simDR_gliss_lit = find_dataref("tu154/custom/lights/button/absu_gz")
simDR_at_mode = find_dataref("tu154/custom/absu/stu_mode")
simDR_sw_sound = find_dataref("tu154/custom/switchers/console/nvu_corr_on")
simDR_thr1 = find_dataref("tu154/custom/controlls/throttle_1")
simDR_thr2 = find_dataref("tu154/custom/controlls/throttle_2")
simDR_thr3 = find_dataref("tu154/custom/controlls/throttle_2")
simDR_yoke_p = find_dataref("tu154/custom/controlls/yoke_pitch")
simDR_yoke_r = find_dataref("tu154/custom/controlls/yoke_roll")
simDR_hyd1_press = find_dataref("tu154/custom/hydro/gs_press_1")
simDR_hyd2_press = find_dataref("tu154/custom/hydro/gs_press_2")
simDR_hyd3_press = find_dataref("tu154/custom/hydro/gs_press_3")
simDR_hyd_emer_press = find_dataref("tu154/custom/hydro/gs_press_4")
simDR_checklist_select = find_dataref("tu154/custom/checklist/checklist_selected")
simDR_diss_cc = find_dataref("tu154/custom/nvu/diss_cc")
simDR_diss_mode = find_dataref("tu154/custom/nvu/diss_mode")
simDR_diss_slip = find_dataref("tu154/custom/nvu/diss_slip_angle")
simDR_diss_gs = find_dataref("tu154/custom/nvu/diss_groundspeed")
simDR_diss_wnd_spd = find_dataref("tu154/custom/nvu/diss_wind_spd")
simDR_diss_wnd_crs = find_dataref("tu154/custom/nvu/diss_wind_course")
simDR_mid_flag  = find_dataref("tu154/custom/gauges/speed/speed_mid_flag")
simDR_needle  = find_dataref("tu154/custom/gauges/speed/speed_mid_needle")
simDR_pitch_trim  = find_dataref("tu154/custom/trimmers/int_pitch_trim")
simDR_emerg_trim  = find_dataref("tu154/custom/switchers/console/emerg_elev_trimm")
simDR_spd_but  = find_dataref("tu154/custom/buttons/console/absu_stab_speed")
simDR_spd_but_lit  = find_dataref("tu154/custom/lights/button/absu_stab_spd")
simDR_apu_oilt  = find_dataref("tu154/custom/eng/apu_oil_t")
simDR_apu_cc  = find_dataref("tu154/custom/elec/gen4_amp")
simDR_start_seq  = find_dataref("tu154/custom/elec/apu_start_seq")
simDR_apu_n1  = find_dataref("tu154/custom/eng/apu_n1")
simDR_apu_working  = find_dataref("tu154/custom/lights/apu/work_mode")
simDR_apu_start_mode  = find_dataref("tu154/custom/switchers/eng/apu_start_mode")
simDR_oat  = find_dataref("sim/cockpit2/temperature/outside_air_temp_deg")
simDR_passed = find_dataref("sim/operation/misc/frame_rate_period")
simDR_time  = find_dataref("sim/time/total_running_time_sec")
simDR_flaps_cl = find_dataref("sim/aircraft/controls/acf_flap_cl") 
simDR_flaps_cm = find_dataref("sim/aircraft/controls/acf_flap_cm") 
simDR_flaps_cd = find_dataref("sim/aircraft/controls/acf_flap_cd") 
simDR_flaps2_cm = find_dataref("sim/aircraft/controls/acf_flap2_cm") 
simDR_flaps2_cl = find_dataref("sim/aircraft/controls/acf_flap2_cl")  
simDR_flaps2_cd = find_dataref("sim/aircraft/controls/acf_flap2_cd")  
simDR_flap_ratio_deg = find_dataref("sim/flightmodel2/wing/flap1_deg") 
simDR_flap_ratio_set = find_dataref("sim/cockpit2/controls/flap_ratio") 
simDR_absu_turn = find_dataref("tu154/custom/switchers/console/absu_turn_handle") 
simDR_absu_zk = find_dataref("tu154/custom/buttons/console/absu_zk") 
simDR_absu_reset = find_dataref("tu154/custom/buttons/console/absu_reset") 
simDR_absu_nvu = find_dataref("tu154/custom/buttons/console/absu_nvu") 
simDR_light_l = find_dataref("tu154/custom/lights/landing_mode_set_L") 
simDR_light_r = find_dataref("tu154/custom/lights/landing_mode_set_R") 
simDR_light_l_ext = find_dataref("tu154/custom/lights/landing_ext_set_L") 
simDR_light_r_ext = find_dataref("tu154/custom/lights/landing_ext_set_R") 
simDR_gear_blocks = find_dataref("tu154/custom/anim/gear_blocks")  
simDR_gear_fan = find_dataref("tu154/custom/switchers/eng/gear_fan")
simDR_park_brake = find_dataref("tu154/custom/controll/parking_brake") 
simDR_brake_l = find_dataref("tu154/custom/gauges/console/gear_brake_press_L") 
simDR_brake_r = find_dataref("tu154/custom/gauges/console/gear_brake_press_R")
simDR_ped_brake_l = find_dataref("tu154/custom/controlls/brake_L")
simDR_ped_brake_r = find_dataref("tu154/custom/controlls/brake_R")
simDR_emerg_brake = find_dataref("tu154/custom/controlls/brake_emerg")
simDRcrs_flag1				= find_dataref("tu154/custom/radio/nav1_cs_flag")
simDRgs_flag1				= find_dataref("tu154/custom/radio/nav1_gs_flag")
simDRcrs_flag2				= find_dataref("tu154/custom/radio/nav2_cs_flag")
simDRgs_flag2				= find_dataref("tu154/custom/radio/nav2_gs_flag")
simDRcrs_np1			= find_dataref("tu154/custom/switchers/ovhd/curs_np_on_1")
simDRcrs_np2				= find_dataref("tu154/custom/switchers/ovhd/curs_np_on_2")
simDRsp50_c1				= find_dataref("tu154/custom/lights/small/sp50_c1")
simDRsp50_c2				= find_dataref("tu154/custom/lights/small/sp50_c2")
simDRsp50_g1				= find_dataref("tu154/custom/lights/small/sp50_g1")
simDRsp50_g2				= find_dataref("tu154/custom/lights/small/sp50_g2")
simDR_ping_pong = find_dataref("sim/graphics/animation/ping_pong_2")
simDR_sin_wave = find_dataref("sim/graphics/animation/sin_wave_2")
simDRnav1mhz = find_dataref("sim/cockpit2/radios/actuators/nav1_frequency_Mhz")
simDRnav2mhz = find_dataref("sim/cockpit2/radios/actuators/nav2_frequency_Mhz")
simDRgeartestup = find_dataref("tu154/custom/buttons/lamp_test_upper_gear")
simDR_but_sound = find_dataref("tu154/custom/buttons/srpbz/but_down")
simDR_rpm_thr = find_dataref("sim/cockpit2/engine/actuators/throttle_ratio_all")
simDR_spd = find_dataref("sim/flightmodel/position/indicated_airspeed")
simDR_ralt = find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
simDR_cg = find_dataref("tu154/custom/misc/cg_pos_actual")
simDR_flood_front = find_dataref("tu154/custom/lights/front_panel_flood")
simDR_gear_lev = find_dataref("sim/aircraft/parts/acf_gear_deploy")
simDR_toga = find_dataref("tu154/custom/lights/toga")
simDR_elev_load = find_dataref("tu154/custom/gauges/misc/elevator_pos_ind")
simDR_alrn_load = find_dataref("tu154/custom/gauges/misc/aileron_pos_ind")
simDR_rud_load = find_dataref("tu154/custom/gauges/misc/rudder_pos_ind")
simDR_absu_pitch_mode = find_dataref("tu154/custom/absu/pitch_sub_mode")
simDR_gpss = find_dataref("sim/cockpit2/autopilot/gpss_status")
simDR_cab_light = find_dataref("sim/weapons/Prad")
simDR_start_apu = find_dataref("tu154/custom/lights/apu/start_apu")
simDR_lamp_test_apu =  find_dataref("tu154/custom/buttons/lamp_test_apu")
simDR_apu_bleed =   find_dataref("tu154/custom/eng/apu_air_doors")
simDR_apu_bleed_sw =   find_dataref("tu154/custom/switchers/eng/apu_air_bleed")


---no lights pn5_pn6_pu46 during light test fix ---
simDR_zk_lit = find_dataref("tu154/custom/lights/button/absu_zk")
simDR_reset_lit = find_dataref("tu154/custom/lights/button/absu_reset")
simDR_nvu_lit = find_dataref("tu154/custom/lights/button/absu_nvu")
simDR_gliss_lit = find_dataref("tu154/custom/lights/button/absu_gz")
simDR_app_lit = find_dataref("tu154/custom/lights/button/absu_app")
simDR_az1_lit = find_dataref("tu154/custom/lights/button/absu_az1")
simDR_az2_lit = find_dataref("tu154/custom/lights/button/absu_az2")
simDR_stab_h_lit = find_dataref("tu154/custom/lights/button/absu_stab_h")
simDR_stab_m_lit = find_dataref("tu154/custom/lights/button/absu_stab_m")
simDR_stab_v_lit = find_dataref("tu154/custom/lights/button/absu_stab_v")
simDR_stab_spd_lit = find_dataref("tu154/custom/lights/button/absu_stab_spd")
simDR_thro1_lit = find_dataref("tu154/custom/lights/button/absu_thro1")
simDR_thro2_lit = find_dataref("tu154/custom/lights/button/absu_thro2")
simDR_thro3_lit = find_dataref("tu154/custom/lights/button/absu_thro3")

simDR_stu_pitch = find_dataref("tu154/custom/lights/small/stu_pitch")
simDR_stu_roll = find_dataref("tu154/custom/lights/small/stu_roll")
simDR_stu_toga = find_dataref("tu154/custom/lights/small/stu_toga")
simDR_at1 = find_dataref("tu154/custom/lights/small/at_1")
simDR_at2 = find_dataref("tu154/custom/lights/small/at_2")

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


--- end



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
local spd_delta = 0
local ralt_delta = 0
local cg_delta = 0
local flap_ratio = 0
local flap_delta = 0
local gear_ratio = 0



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




function absu_turn_left_CMDhandler(phase, duration) 
    if phase == 0 then
        if simDR_absu_turn > -50 then
            simDR_absu_turn = simDR_absu_turn - 2
        end
    end
    if phase == 1 then
        if duration > 0.3 then
            if simDR_absu_turn > -50 and simDR_absu_turn < -0.01 then
                simDR_absu_turn = simDR_absu_turn - 2
            end
            if simDR_absu_turn > 0 and absu_turn_zero < 1 then
                if simDR_absu_turn == 0 then
                absu_turn_zero = 1
                end
                simDR_absu_turn = simDR_absu_turn - 2
            end
        end
    end
    if phase == 2 then
        absu_turn_zero = 0
    end
end

function absu_turn_right_CMDhandler(phase, duration) 
    if phase == 0 then
        if simDR_absu_turn < 50 then
            simDR_absu_turn = simDR_absu_turn + 2
        end
    end
    if phase == 1 then
        if duration > 0.3 then
            if simDR_absu_turn < 50 and simDR_absu_turn > 0.01 then
                simDR_absu_turn = simDR_absu_turn + 2
            end
            if simDR_absu_turn < 0 and absu_turn_zero < 1 then
                if simDR_absu_turn == 0 then
                absu_turn_zero = 1
                end
                simDR_absu_turn = simDR_absu_turn + 2
            end
        end
    end
    if phase == 2 then
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

if simDR_apu_bleed > 0.01 and simDR_lamp_test_apu < 1 then
   simDR_apu_start_ready = 0
end
    
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
    
 
simDR_gpss = 2 
if simDRgeartestup > 0 then
    simDR_but_sound = 1
    pressed = 1
end
if simDRgeartestup < 1 and pressed > 0 then
    simDR_but_sound = 0
    pressed = 0
end

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
    
if simDR_flap_ratio_deg[0] > 0 then
    flap_ratio = simDR_flap_ratio_deg[0]
elseif simDR_flap_ratio_deg[1] > 0 then
    flap_ratio = simDR_flap_ratio_deg[1]
else 
    flap_ratio = 0
end
    
if simDR_gear_lev[1] > 0 then
    gear_ratio = simDR_gear_lev[1]
elseif simDR_gear_lev[1] > 0 then
    gear_ratio = simDR_gear_lev[2]
else 
    gear_ratio = 0
end
    

if simDR_spd > 126 and simDR_spd < 227 then        
  spd_delta = 226 - simDR_spd
else
  if simDR_spd > 226 then
    spd_delta = 1
  end
  if simDR_spd < 127 then
    spd_delta = 0
  end
end

if simDR_ralt < 40 then
    ralt_delta = (40 - simDR_ralt) * 0.005
else
    ralt_delta = 0
end

if simDR_cg < 29 then
    if simDR_cg > 21 then
        cg_delta = (29 - simDR_cg) * 0.125
    else
        cg_delta = 1
    end
else
    cg_delta = 0
end
    

if flap_ratio < 35 then
        flap_delta = (35 - flap_ratio) * 0.05
else
        flap_delta = 0
end  

if flap_ratio > 28 then
   local flap_cm_delta = 0.0048 * flap_ratio
else
    flap_cm_delta = 0
end
    
simDR_flaps_cl = simDR_flaps_cl - (((flap_ratio * 0.0185 * 0.022) / 1.5) + ((1 - simDR_rpm_thr) * 9 * 0.01) ) 
simDR_flaps2_cl = simDR_flaps2_cl - (((flap_ratio * 0.0095 * 0.022) / 1.5) + ((1 - simDR_rpm_thr) * 14 * 0.01) )
simDR_flaps_cm = -0.29 + (flap_ratio * 0.16 * 0.022) + (ralt_delta * simDR_rpm_thr * cg_delta * flap_delta) - flap_cm_delta
simDR_flaps2_cm = -0.38 + (flap_ratio * 0.14 * 0.022) + (ralt_delta * simDR_rpm_thr * cg_delta * flap_delta) - flap_cm_delta
if flap_ratio < 15 then
    simDR_flaps_cd = 0.051 + flap_ratio * 0.0018 + (gear_ratio * 0.014)
end
if flap_ratio > 15 and flap_ratio < 28 then
    simDR_flaps_cd = 0.112 - flap_ratio * 0.0023 + (gear_ratio * 0.014)
end
if flap_ratio > 28 and flap_ratio < 36 then
    simDR_flaps_cd = 0.012 + (flap_ratio * 0.00239) - ( flap_delta * 0.091) + (gear_ratio * 0.014)
end
if flap_ratio > 36 then
    simDR_flaps_cd = 0.098 + flap_ratio * 0.000045 + (gear_ratio * 0.014)
end
simDR_flaps2_cd = simDR_flaps_cd + 0.01
    
    
        --15 - 0.078 0.088
        --28 - 0.047 0.057
        --36 - 0.098 0.108
        --45 - 0.100 0.110
    

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
    

if simDR_checklist_select > 0 then
  checklist_num = simDR_checklist_select
end   
    
    
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

function after_physics()
    systems()
end
