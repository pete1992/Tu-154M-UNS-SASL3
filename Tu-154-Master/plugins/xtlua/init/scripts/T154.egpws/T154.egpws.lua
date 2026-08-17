function deferred_dataref(name,type,notifier)
	print("Deffered dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end
   
simDR_qfeqnh = find_dataref("tu154/custom/switchers/ovhd/egpws_mode") 
simDR_vbe1 = find_dataref("tu154/custom/switchers/ovhd/vbe_1_on") 
simDR_vbe2 = find_dataref("tu154/custom/switchers/ovhd/vbe_2_on") 
simDR_var1 = find_dataref("tu154/custom/switchers/ovhd/var_left") 
simDR_var2 = find_dataref("tu154/custom/switchers/ovhd/var_right") 
simDR_svs = find_dataref("tu154/custom/switchers/ovhd/svs_on")
simDR_on_ground = find_dataref("sim/flightmodel/failures/onground_all") 
simDR_diss = find_dataref("tu154/custom/nvu/diss_mode") 
simDR_gps_power = find_dataref("sim/cockpit2/radios/actuators/gps_power")
simDR_taws1  = find_dataref("tu154/custom/taws/taws_message")
simDR_taws2  = find_dataref("tu154/custom/sounds/taws_rus_phrase")
simDR_taws3  = find_dataref("tu154/custom/sounds/taws_eng_phrase")
simDR_taws_mode = find_dataref("tu154/custom/taws/mode_set")
simDR_alarm  = find_dataref("tu154/custom/switchers/ovhd/egpws_alarm_1")
simDR_but_sound = find_dataref("tu154/custom/buttons/srpbz/but_down")
simDR_sw_sound = find_dataref("tu154/custom/switchers/console/nvu_corr_on")
simDR_passed = find_dataref("sim/operation/misc/frame_rate_period")
simDR_36vl = find_dataref("tu154/custom/elec/bus36_volt_left")
simDR_36vr = find_dataref("tu154/custom/elec/bus36_volt_right")
simDR_rv2 = find_dataref("tu154/custom/elec/rv5_right_cc")

dis_sound = deferred_dataref("tu154/custom/egpws/dis_sound", "number")
dis_gear = deferred_dataref("tu154/custom/egpws/dis_gear", "number")
dis_flaps = deferred_dataref("tu154/custom/egpws/dis_flaps", "number")
dis_rppz = deferred_dataref("tu154/custom/egpws/dis_rppz", "number")
dis_gs = deferred_dataref("tu154/custom/egpws/dis_gs", "number")
srpbz = deferred_dataref("tu154/custom/kontur/srpbz", "number")
srpbz_lit = deferred_dataref("tu154/custom/kontur/srpbz_lit", "number")
srpbz_lit_set = deferred_dataref("tu154/custom/kontur/srpbz_lit_set", "number")
srpbz_rppz_lit = deferred_dataref("tu154/custom/kontur/srpbz_rppz_lit", "number")
srpbz_sppz_lit = deferred_dataref("tu154/custom/kontur/srpbz_sppz_lit", "number")
srpbz_test_lit = deferred_dataref("tu154/custom/kontur/srpbz_test_lit", "number")

local srpbz_start = 0
local srpbz_timer = 0
local volt_36 = 0
local egpws_started = 0
local egpws_on = 0
local sppz_lit_on = 0
local rppz_lit_on = 0
local test_lit_on = 0
local sppz_test_set = 0
local vbe_on = 0
local var_on = 0
srpbz_lit_set = 0.7

function dis_sound_CMDhandler(phase, duration) 
    if phase == 0 then
        if dis_sound == 0 and srpbz > 0 then
            dis_sound = 1
        else
            dis_sound = 0
        end
        simDR_but_sound = 1
    end  
    if phase == 2 then
        simDR_but_sound = 0
    end
end

function dis_gear_CMDhandler(phase, duration) 
    if phase == 0 then
        if dis_gear == 0 and srpbz > 0 then
            dis_gear = 1
        else
            dis_gear = 0
        end
        simDR_but_sound = 1
    end  
    if phase == 2 then
        simDR_but_sound = 0
    end
end
function dis_flaps_CMDhandler(phase, duration) 
    if phase == 0 then
        if dis_flaps == 0 and srpbz > 0 then
            dis_flaps = 1
        else
            dis_flaps = 0
        end
        simDR_but_sound = 1
    end  
    if phase == 2 then
        simDR_but_sound = 0
    end
end
function dis_rppz_CMDhandler(phase, duration) 
    if phase == 0 then
        if dis_rppz == 0 and srpbz > 0 then
            dis_rppz = 1
        else
            dis_rppz = 0
        end
        simDR_but_sound = 1
    end  
    if phase == 2 then
        simDR_but_sound = 0
    end
end
function dis_gs_CMDhandler(phase, duration) 
    if phase == 0 then
        if dis_gs == 0 and srpbz > 0 then
            dis_gs = 1
        else
            dis_gs = 0
        end
        simDR_but_sound = 1
    end  
    if phase == 2 then
        simDR_but_sound = 0
    end
end

function srpbz_ovhd_onoff_CMDhandler(phase, duration)
     if phase == 0 then
        if srpbz > 0 then
            srpbz = 0
        else
            srpbz = 1
        end  
        if simDR_sw_sound > -1 then
        simDR_sw_sound = -1
        else
        simDR_sw_sound = 0
        end
    end    	
end

dis_sound_cmnd	= create_command("egpws/dis_sound", "EGPWS Disable sound", dis_sound_CMDhandler)
dis_gear_cmnd	= create_command("egpws/dis_gear", "EGPWS Disable gear", dis_gear_CMDhandler)
dis_flaps_cmnd	= create_command("egpws/dis_flaps", "EGPWS Disable flaps", dis_flaps_CMDhandler)
dis_rppz_cmnd	= create_command("egpws/dis_rppz", "EGPWS Disable rppz", dis_rppz_CMDhandler)
dis_gs_cmnd	= create_command("egpws/dis_gs", "EGPWS Disable GS", dis_gs_CMDhandler)
srpbz_onoff_cmnd	= create_command("srpbz/onoff", "SRPBZ ON/OFF", srpbz_ovhd_onoff_CMDhandler)

function egpws()
    
    if simDR_36vl > 0 then
       volt_36 = 1
    elseif simDR_36vr > 0 then
       volt_36 = 1
    else
       volt_36 = 0
    end

    if simDR_vbe1 > 0 then
        vbe_on = 1
    elseif simDR_vbe2 > 0 then
        vbe_on = 1
    else
        vbe_on = 0
    end
    if simDR_var1 > 0 then
        var_on = 1
    elseif simDR_var2 > 0 then
        var_on = 1
    else
        var_on = 0
    end
    
    if volt_36 > 0 and srpbz > 0 then
            srpbz_lit = srpbz_lit_set
            if sppz_lit_on > 0 then
                srpbz_sppz_lit = srpbz_lit
            elseif simDR_taws_mode > 4 then
                srpbz_sppz_lit = srpbz_lit
            else
                srpbz_sppz_lit = 0
            end
            if rppz_lit_on > 0 then
                srpbz_rppz_lit = srpbz_lit
            elseif simDR_taws_mode > 4 then
                srpbz_rppz_lit = srpbz_lit
            else
                srpbz_rppz_lit = 0
            end
            if test_lit_on > 0 then
                srpbz_test_lit = srpbz_lit
            else
                srpbz_test_lit = 0
            end
        
            if simDR_on_ground > 0 then
                test_lit_on = 1
            else
                test_lit_on = 0
            end
            
            if simDR_taws_mode == 4 then
                rppz_lit_on = 1
            elseif simDR_diss > 0 and simDR_gps_power > 0 then            
                rppz_lit_on = 0
            else           
                rppz_lit_on = 1
            end
        
            if simDR_taws_mode == 4 then
                sppz_lit_on = 1
            elseif vbe_on > 0 and var_on > 0 and simDR_svs > 0 then            
                sppz_lit_on = 0
            else           
                sppz_lit_on = 1
            end
        
            if srpbz_start > 0 then
                srpbz_timer = srpbz_timer + simDR_passed
                if srpbz_timer < 45 then
                    simDR_taws_mode = 0
                else
                        srpbz_start = 0
                        egpws_started = 1
                        srpbz_timer = 0
                end
            end
        
            if simDR_rv2 > 0 and egpws_started > 0 and egpws_on < 1 then
                        simDR_taws_mode = 1
                        egpws_on = 1
            end
            if simDR_rv2 < 1 then
                egpws_on = 0
            end
    else
            simDR_taws_mode = 0
            srpbz_timer = 0
            srpbz_start = 1
            egpws_started = 0
            egpws_on = 0
            srpbz_lit = 0
            srpbz_test_lit = 0
            srpbz_rppz_lit = 0
            srpbz_sppz_lit = 0
    end
    
    if simDR_taws_mode > 4 then
      if simDR_diss > 0 and simDR_gps_power > 0 and vbe_on > 0 and var_on > 0 and simDR_svs > 0 and simDR_on_ground > 0 then
      else
            simDR_taws_mode = 1
      end
    end
    
    if simDR_taws_mode == 5 then
       sppz_test_set = 1
       dis_sound = 1
       dis_gear = 1
       dis_flaps = 1
       dis_rppz = 1
       dis_gs = 1
       simDR_qfeqnh = -1
    else
        if sppz_test_set > 0 then
           dis_sound = 0
           dis_gear = 0
           dis_flaps = 0
           dis_rppz = 0
           dis_gs = 0
           simDR_qfeqnh = 1
           sppz_test_set = 0
        end
    end
    
    if dis_sound > 0 and simDR_taws_mode < 5 then
        simDR_taws2 = 0
        simDR_taws3 = 0
        simDR_alarm = 0
    end
    if dis_gear > 0 and simDR_taws_mode < 5 then
        if simDR_taws1 == 8 then
            simDR_taws1 = 0
            simDR_taws2 = 0
            simDR_taws3 = 0
        end    
    end
    if dis_flaps > 0 and simDR_taws_mode < 5 then
        if simDR_taws1 == 9 then
            simDR_taws1 = 0
            simDR_taws2 = 0
            simDR_taws3 = 0
        end    
    end
    if dis_rppz > 0 and simDR_taws_mode < 5 then
        simDR_alarm = 0
        if simDR_taws1 == 1 then
            simDR_taws1 = 0
            simDR_taws2 = 0
            simDR_taws3 = 0
        end  
        if simDR_taws1 == 3 then
            simDR_taws1 = 0
            simDR_taws2 = 0
            simDR_taws3 = 0
        end  
        if simDR_taws1 == 4 then
            simDR_taws1 = 0
            simDR_taws2 = 0
            simDR_taws3 = 0
        end 
        if simDR_taws1 == 5 then
            simDR_taws1 = 0
            simDR_taws2 = 0
            simDR_taws3 = 0
        end   
        if simDR_taws1 == 6 then
            simDR_taws1 = 0
            simDR_taws2 = 0
            simDR_taws3 = 0
        end  
        if simDR_taws1 == 11 then
            simDR_taws1 = 0
            simDR_taws2 = 0
            simDR_taws3 = 0
        end  
        if simDR_taws1 == 12 then
            simDR_taws1 = 0
            simDR_taws2 = 0
            simDR_taws3 = 0
        end    
    end
    if dis_gs > 0 and simDR_taws_mode < 5 then
        if simDR_taws1 == 13 then
            simDR_taws1 = 0
            simDR_taws2 = 0
            simDR_taws3 = 0
        end    
    end
    
    if dis_rppz < 1 and dis_sound < 1 then
        simDR_alarm = 1
    end
    
end

function after_physics()
    egpws()
end