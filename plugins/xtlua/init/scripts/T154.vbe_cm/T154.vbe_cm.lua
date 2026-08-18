function deferred_dataref(name,type,notifier)
	print("Deffered dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end

simDR_bus27left                    = find_dataref("tu154/custom/elec/bus27_volt_left")
simDR_bus27right                    = find_dataref("tu154/custom/elec/bus27_volt_right")
simDR_time = find_dataref("sim/time/zulu_time_sec")
simDR_passed = find_dataref("sim/operation/misc/frame_rate_period")
simDR_ping_pong = find_dataref("sim/graphics/animation/ping_pong_2")

simDR_vbe_alt_l	= find_dataref("tu154/custom/gauges/alt/vbe_alt_left")
simDR_vbe_press_l = find_dataref("tu154/custom/gauges/alt/vbe_press_left")
simDR_vbe_fl_l = find_dataref("tu154/custom/gauges/alt/vbe_flightlevel_left")
simDR_brt_l = find_dataref("tu154/custom/gauges/alt/vbe_brt_left")
simDR_vbe_on_l = find_dataref("tu154/custom/switchers/ovhd/vbe_1_on")
altitude_1000_l = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_l_alt_1000", "number")
altitude_100_l = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_l_alt_100", "number")
f_level_l = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_l_fl", "number")
needle_angle_l = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_l_needle", "number")
border_l = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_l_border", "number")
brt_l = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_l_brt", "number")
btn_mode_l = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_l_btn_mode", "number")
vbe_test_l = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_l_test", "number")
vbe_test_l2 = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_l_test2", "number")


simDR_on_ground = find_dataref("sim/flightmodel/failures/onground_all") 
simDR_vbe_alt_r	= find_dataref("tu154/custom/gauges/alt/vbe_alt_right")
simDR_vbe_press_r = find_dataref("tu154/custom/gauges/alt/vbe_press_right")
simDR_vbe_fl_r = find_dataref("tu154/custom/gauges/alt/vbe_flightlevel_right")
simDR_brt_r = find_dataref("tu154/custom/gauges/alt/vbe_brt_right")
simDR_vbe_on_r = find_dataref("tu154/custom/switchers/ovhd/vbe_2_on")
altitude_1000_r = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_r_alt_1000", "number")
altitude_100_r = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_r_alt_100", "number")
f_level_r = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_r_fl", "number")
needle_angle_r = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_r_needle", "number")
border_r = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_r_border", "number")
brt_r = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_r_brt", "number")
btn_mode_r = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_r_btn_mode", "number")
vbe_test_r = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_r_test", "number")
vbe_test_r2 = deferred_dataref("tu154/custom/gauges/alt/vbe_cm_r_test2", "number")
vbe_mode_l= deferred_dataref("tu154/custom/gauges/alt/vbe_mode_left_new", "number")
vbe_mode_r= deferred_dataref("tu154/custom/gauges/alt/vbe_mode_right_new", "number")


local f_level_lm = 0
local altitude_current_l = 0
local altitude_diff_l = 0
local start_self_test_l = 1
local self_test_l = 0
local start_reset_mod_timer_l = 0
local vbe_press_was_l = 0

local altitude_current_r = 0
local altitude_diff_r = 0
local start_self_test_r = 1
local self_test_r = 0
local start_reset_mod_timer_r = 0
local vbe_press_was_l = 0



function vbecm_button_1_CMDhandler(phase, duration)
    if phase == 0 then
        if simDR_bus27left > 0 and simDR_vbe_on_l > 0 and start_self_test_l < 1 and self_test_l < 1 then
            start_reset_mod_timer_l = 0
            if btn_mode_l < 5 and simDR_on_ground > 0 then
                btn_mode_l = btn_mode_l +1
            elseif btn_mode_l < 4 and simDR_on_ground < 1 then
                btn_mode_l = btn_mode_l +1
            else
                btn_mode_l = 0
            end
        end    
            
	
    end   	
end	

function vbecm_button_2_CMDhandler(phase, duration)
    if phase == 0 then
        
        
        if simDR_bus27left > 0 and simDR_vbe_on_l > 0 and start_self_test_l < 1 and self_test_l < 1  then
            start_reset_mod_timer_l = 0
            if btn_mode_l == 0 and simDR_vbe_fl_l > 0 then 
                simDR_vbe_fl_l = 0
            end
            if btn_mode_l == 1 then
                simDR_vbe_press_l = simDR_vbe_press_l -1
            end
            if btn_mode_l == 2 then
                if vbe_mode_l == 1 then
                   simDR_vbe_fl_l = simDR_vbe_fl_l -152.4
                else
                    simDR_vbe_fl_l = simDR_vbe_fl_l -100
                end
            end
            if btn_mode_l == 4 and simDR_brt_l > 0.1 then
                simDR_brt_l = simDR_brt_l - 0.05
            end
        end    
        
        if vbe_test_l == 3 then
            vbe_test_l = 0
            self_test_l = 0
            vbe_test_l2 = 0
        end    
    end
	
    if phase == 1 then
        if simDR_bus27left > 0 and simDR_vbe_on_l > 0 and start_self_test_l < 1 and self_test_l < 1  then
        if duration > 0.4 then
            if btn_mode_l == 1 then
                simDR_vbe_press_l = simDR_vbe_press_l -1
            end
            if btn_mode_l == 2 then
                if vbe_mode_l == 1 then
                    simDR_vbe_fl_l = simDR_vbe_fl_l -152.4
                else
                    simDR_vbe_fl_l = simDR_vbe_fl_l -100
                end
            end
            if btn_mode_l == 4 and simDR_brt_l > 0.1 then
                simDR_brt_l = simDR_brt_l - 0.05
            end
        end
        if duration > 2 then
        
            if btn_mode_l == 2 then
                if vbe_mode_l == 1 then
                simDR_vbe_fl_l = simDR_vbe_fl_l -600
                else
                simDR_vbe_fl_l = simDR_vbe_fl_l -300
                end
            end
        end
        end
    end
    if phase == 2 then
        if vbe_mode_l == 1 and simDR_vbe_fl_l > 0 then
            simDR_vbe_fl_l = f_level_l * 0.3048
        end
    end
end	
    
function vbecm_button_3_CMDhandler(phase, duration)
    if phase == 0 then
        if simDR_bus27left > 0 and simDR_vbe_on_l > 0 and start_self_test_l < 1 and self_test_l < 1 then
            start_reset_mod_timer_l = 0
            if btn_mode_l == 1 then
                simDR_vbe_press_l = simDR_vbe_press_l +1
            end
            if btn_mode_l == 2 then
                if vbe_mode_l == 1 then
                    simDR_vbe_fl_l = simDR_vbe_fl_l +152.4
                else
                    simDR_vbe_fl_l = simDR_vbe_fl_l +100
                end
            end
            if btn_mode_l == 3 then
                if vbe_mode_l > 0 then
                    vbe_mode_l = 0
                    simDR_vbe_fl_l = simDR_vbe_fl_l + 49
                else
                    vbe_mode_l = 1
                    simDR_vbe_fl_l = simDR_vbe_fl_l + 49
                end
            end
            if btn_mode_l == 4 and simDR_brt_l < 1 then
                simDR_brt_l = simDR_brt_l + 0.05
            end
            if btn_mode_l == 5 then
                if self_test_l < 1 then
                    self_test_l = 1
                end
            end
        end
    end
	
    if phase == 1 then
        if simDR_bus27left > 0 and simDR_vbe_on_l > 0 and start_self_test_l < 1 and self_test_l < 1 then
        if duration > 0.4 then
            if btn_mode_l == 1 then
                simDR_vbe_press_l = simDR_vbe_press_l +1
            end
            if btn_mode_l == 2 then
                if vbe_mode_l == 1 then
                    simDR_vbe_fl_l = simDR_vbe_fl_l +152.4
                else
                    simDR_vbe_fl_l = simDR_vbe_fl_l +100
                end
            end
            if btn_mode_l == 4 and simDR_brt_l < 1 then
                simDR_brt_l = simDR_brt_l + 0.05
            end
        end
        if duration > 2 then
        
            if btn_mode_l == 2 then
                if vbe_mode_l == 1 then
                simDR_vbe_fl_l = simDR_vbe_fl_l +457.2
                else
                simDR_vbe_fl_l = simDR_vbe_fl_l +300
                end
            end
        end
        end
    end
    if phase == 2 then
        if vbe_mode_l == 1 and simDR_vbe_fl_l > 0 then
            simDR_vbe_fl_l = f_level_l * 0.3048
        end
    end
end	


function vbecm_button_1_r_CMDhandler(phase, duration)
    if phase == 0 then
        if simDR_bus27right > 0 and simDR_vbe_on_r > 0 and start_self_test_r < 1 and self_test_r < 1 then
            start_reset_mod_timer_r = 0
            if btn_mode_r < 5 and simDR_on_ground > 0 then
                btn_mode_r = btn_mode_r +1
            elseif btn_mode_l < 4 and simDR_on_ground < 1 then
                btn_mode_r = btn_mode_r +1
            else
                btn_mode_r = 0
            end
        end    
    end   	
end	

function vbecm_button_2_r_CMDhandler(phase, duration)
    if phase == 0 then
        
        
        if simDR_bus27right > 0 and simDR_vbe_on_r > 0 and start_self_test_r < 1 and self_test_r < 1 then
            start_reset_mod_timer_r = 0
            if btn_mode_r == 0 and simDR_vbe_fl_r > 0 then 
                simDR_vbe_fl_r = 0
            end
            if btn_mode_r == 1 then
                simDR_vbe_press_r = simDR_vbe_press_r -1
            end
            if btn_mode_r == 2 then
                if vbe_mode_r == 1 then
                simDR_vbe_fl_r = simDR_vbe_fl_r -152.4
                else
                simDR_vbe_fl_r = simDR_vbe_fl_r -100
                end
            end
            if btn_mode_r == 4 and simDR_brt_r > 0.1 then
                simDR_brt_r = simDR_brt_r - 0.05
            end
        end    
        
        if vbe_test_r == 3 then
            vbe_test_r = 0
            self_test_r = 0
            vbe_test_r2 = 0
        end 
    end
	
    if phase == 1 then
        if simDR_bus27right > 0 and simDR_vbe_on_r > 0 and start_self_test_r < 1 and self_test_r < 1 then
        if duration > 0.4 then
            if btn_mode_r == 1 then
                simDR_vbe_press_r = simDR_vbe_press_r -1
            end
            if btn_mode_r == 2 then
                if vbe_mode_r == 1 then
                simDR_vbe_fl_r = simDR_vbe_fl_r -152.4
                else
                simDR_vbe_fl_r = simDR_vbe_fl_r -100
                end
            end
            if btn_mode_r == 4 and simDR_brt_r > 0.1 then
                simDR_brt_r = simDR_brt_r - 0.05
            end
        end
        if duration > 2 then
        
            if btn_mode_r == 2 then
                if vbe_mode_r == 1 then
                simDR_vbe_fl_r = simDR_vbe_fl_r -457.2
                else
                simDR_vbe_fl_r = simDR_vbe_fl_r -300
                end
            end
        end
        end
    end
    if phase == 2 then
        if vbe_mode_r == 1 and simDR_vbe_fl_r > 0 then
            simDR_vbe_fl_r = f_level_r * 0.3048
        end
    end
end	
    
function vbecm_button_3_r_CMDhandler(phase, duration)
    if phase == 0 then
        if simDR_bus27right > 0 and simDR_vbe_on_r > 0 and start_self_test_r < 1 and self_test_r < 1 then
            start_reset_mod_timer_r = 0
            if btn_mode_r == 1 then
                simDR_vbe_press_r = simDR_vbe_press_r +1
            end
            if btn_mode_r == 2 then
                if vbe_mode_r == 1 then
                simDR_vbe_fl_r = simDR_vbe_fl_r +152.4
                else
                simDR_vbe_fl_r = simDR_vbe_fl_r +100
                end
            end
            if btn_mode_r == 3 then
                if vbe_mode_r > 0 then
                    vbe_mode_r = 0
                else
                    vbe_mode_r = 1
                end
            end
            if btn_mode_r == 4 and simDR_brt_r < 1 then
                simDR_brt_r = simDR_brt_r + 0.05
            end
            if btn_mode_r == 5 then
                if self_test_r < 1 then
                    self_test_r = 1
                end
            end
        end    
    end
	
    if phase == 1 then
        if simDR_bus27right > 0 and simDR_vbe_on_r > 0 and start_self_test_r < 1 and self_test_r < 1 then
        if duration > 0.4 then
            if btn_mode_r == 1 then
                simDR_vbe_press_r = simDR_vbe_press_r +1
            end
            if btn_mode_r == 2 then
                if vbe_mode_r == 1 then
                simDR_vbe_fl_r = simDR_vbe_fl_r +152.4
                else
                simDR_vbe_fl_r = simDR_vbe_fl_r +100
                end
            end
            if btn_mode_r == 4 and simDR_brt_r < 1 then
                simDR_brt_r = simDR_brt_r + 0.05
            end
        end
        if duration > 2 then
        
            if btn_mode_r == 2 then
                if vbe_mode_r == 1 then
                simDR_vbe_fl_r = simDR_vbe_fl_r +457.2
                else
                simDR_vbe_fl_r = simDR_vbe_fl_r +300
                end
            end
        end
        end
    end	
    if phase == 2 then
        if vbe_mode_r == 1 and simDR_vbe_fl_r > 0 then
            simDR_vbe_fl_r = f_level_r * 0.3048
        end
    end
end	

    
function vbecm_button_23_CMDhandler(phase, duration)
    if phase == 0 then
        if simDR_bus27left > 0 and simDR_vbe_on_l > 0 and start_self_test_l < 1 and self_test_l < 1 then
            start_reset_mod_timer_l = 0
            if btn_mode_l == 1 then
                simDR_vbe_press_l = 1013
            end
        end
    end   	
end
function vbecm_button_23_r_CMDhandler(phase, duration)
    if phase == 0 then
        if simDR_bus27right > 0 and simDR_vbe_on_r > 0 and start_self_test_r < 1 and self_test_r < 1 then
            start_reset_mod_timer_r = 0
            if btn_mode_r == 1 then
                simDR_vbe_press_r = 1013
            end
        end
    end   	
end


vbe_btn1_cmnd_l	= create_command("vbecm_l/vbe_btn1_cmnd", "VBE-CM BTN1", vbecm_button_1_CMDhandler)
vbe_btn2_cmnd_l	= create_command("vbecm_l/vbe_btn2_cmnd", "VBE-CM BTN2", vbecm_button_2_CMDhandler)
vbe_btn3_cmnd_l	= create_command("vbecm_l/vbe_btn3_cmnd", "VBE-CM BTN3", vbecm_button_3_CMDhandler)
vbe_btn23_cmnd_l = create_command("vbecm_l/vbe_btn23_cmnd", "VBE-CM BTN2 + BTN3", vbecm_button_23_CMDhandler)


vbe_btn1_cmnd_r	= create_command("vbecm_r/vbe_btn1_cmnd", "VBE-CM R BTN1", vbecm_button_1_r_CMDhandler)
vbe_btn2_cmnd_r	= create_command("vbecm_r/vbe_btn2_cmnd", "VBE-CM R BTN2", vbecm_button_2_r_CMDhandler)
vbe_btn3_cmnd_r	= create_command("vbecm_r/vbe_btn3_cmnd", "VBE-CM R BTN3", vbecm_button_3_r_CMDhandler)
vbe_btn23_cmnd_r = create_command("vbecm_r/vbe_btn23_cmnd", "VBE-CM R BTN2 + BTN3", vbecm_button_23_r_CMDhandler)






function mode_reset()
    if btn_mode_l == 5 and simDR_on_ground < 1 then
        btn_mode_l = 0
    end
    if btn_mode_r == 5 and simDR_on_ground < 1 then
        btn_mode_r = 0
    end

    
    
    if btn_mode_l > 0 then
            start_reset_mod_timer_l = start_reset_mod_timer_l + simDR_passed
            if start_reset_mod_timer_l > 13 then
             btn_mode_l = 0
            end   
    end
    if btn_mode_r > 0 then
            start_reset_mod_timer_r = start_reset_mod_timer_r + simDR_passed
            if start_reset_mod_timer_r > 13 then
             btn_mode_r = 0
            end   
    end
end

function self_test()
    
    
    if simDR_vbe_on_l < 1 then
        start_self_test_l = 1
        self_test_l = 0
        btn_mode_l = 0
        vbe_test_l = 0
        vbe_test_l2 = -1
    end
    if simDR_vbe_on_l > 0 and simDR_bus27left < 1 then
        start_self_test_l = 1
        simDR_brt_l = 0
    end
    
    if vbe_test_l2 < 0 then
            simDR_brt_l = 0
    end
    
    
    if self_test_l > 0 and simDR_vbe_on_l > 0 and simDR_bus27left > 0 then
        if vbe_test_l2 < 1 then
            vbe_test_l2 = vbe_test_l2 + 0.005
            vbe_test_l = 1
        else
                vbe_test_l = 3
                btn_mode_l = 0
        end
    end
    
    
    if start_self_test_l > 0 and simDR_vbe_on_l > 0 and simDR_bus27left > 0 then
        if vbe_test_l2 < 1.5 then
            vbe_test_l2 = vbe_test_l2 + 0.005
            if vbe_test_l2 < 1 then
                vbe_test_l = 1
            end
            if vbe_test_l2 > 1 then
                vbe_test_l = 2
            end
            if simDR_brt_l < 0.69 and vbe_test_l2 > 0 then
             simDR_brt_l = simDR_brt_l + 0.01
            elseif vbe_test_l2 > 1 then
                simDR_brt_l = 0.7                
            end
        else
            start_self_test_l = 0
            vbe_test_l = 0
            vbe_test_l2 = 0
        end
        
    end
    
    
    
    
    
    if simDR_vbe_on_r < 1 then
        start_self_test_r = 1
        self_test_r = 0
        btn_mode_r = 0
        vbe_test_r = 0
        vbe_test_r2 = -1
        simDR_brt_r = 0
    end
    if simDR_vbe_on_r > 0 and simDR_bus27left < 1 then
        start_self_test_r = 1
        simDR_brt_r = 0
    end
    
    if self_test_r > 0 and simDR_vbe_on_r > 0 and simDR_bus27right > 0 then
        if vbe_test_r2 < 1 then
            vbe_test_r2 = vbe_test_r2 + 0.005
            vbe_test_r = 1
        else
                vbe_test_r = 3
                btn_mode_r = 0
        end
    end
    
    if vbe_test_r2 < 0 then
            simDR_brt_r = 0
    end
    
    if start_self_test_r > 0 and simDR_vbe_on_r > 0 and simDR_bus27right > 0 then
        if vbe_test_r2 < 1.5 then
            vbe_test_r2 = vbe_test_r2 + 0.005
            if vbe_test_r2 < 1 then
                vbe_test_r = 1
            end
            if vbe_test_r2 > 1 then
                vbe_test_r = 2
            end
            if simDR_brt_r < 0.69 and vbe_test_r2 > 0 then
             simDR_brt_r = simDR_brt_r + 0.01
            elseif vbe_test_r2 > 1 then
                simDR_brt_r = 0.7              
            end
        else
            start_self_test_r = 0
            vbe_test_r = 0
            vbe_test_r2 = 0
        end
        
    end
end

function altitudes_calc()
    if vbe_mode_l == 0 then 
        if simDR_vbe_alt_l > 0 and self_test_l < 1 then
            altitude_1000_l = math.floor(simDR_vbe_alt_l * 0.001)
			altitude_100_l = math.floor((simDR_vbe_alt_l - altitude_1000_l * 1000) * 0.2) * 5
        elseif self_test_l < 1 then 
            altitude_1000_l = math.ceil(simDR_vbe_alt_l * 0.001) 
			altitude_100_l = math.ceil((simDR_vbe_alt_l - altitude_1000_l * 1000) * 0.2) * 5
        else
            altitude_1000_l = 12
            altitude_100_l = 100
        end
	else 
        if simDR_vbe_alt_l > 0 and self_test_l < 1 then
            altitude_1000_l = math.floor((simDR_vbe_alt_l / 0.3048) * 0.001)
			altitude_100_l = math.floor(((simDR_vbe_alt_l / 0.3048) - altitude_1000_l * 1000) / 10) * 10
        elseif self_test_l < 1 then
            altitude_1000_l = math.ceil((simDR_vbe_alt_l / 0.3048) * 0.001)
			altitude_100_l = math.ceil(((simDR_vbe_alt_l / 0.3048) - altitude_1000_l * 1000) / 10) * 10
        else
            altitude_1000_l = 12
            altitude_100_l = 100
        end
	end 
    
    
    if vbe_mode_l == 0 and self_test_l < 1 then
        if  simDR_vbe_fl_l > 0 then
            simDR_vbe_fl_l = math.floor(simDR_vbe_fl_l * 0.01) *100
        end
        f_level_l = simDR_vbe_fl_l
    elseif self_test_l < 1 then
        if  simDR_vbe_fl_l > 0 then
            f_level_l = math.floor((simDR_vbe_fl_l * 3.280839895013 * 0.01 + 0.49)*0.2) * 500
        end
    else
        f_level_l = 0
    end
    if self_test_l < 1 then
	   needle_angle_l = altitude_100_l * 360 / 1000
    else
	   needle_angle_l = 36
    end
       brt_l = simDR_brt_l * 100
    
    
    if vbe_mode_r == 0 then 
        if simDR_vbe_alt_r > 0 and self_test_r < 1 then
            altitude_1000_r = math.floor(simDR_vbe_alt_r * 0.001)
			altitude_100_r = math.floor((simDR_vbe_alt_r - altitude_1000_r * 1000) * 0.2) * 5
        elseif self_test_r < 1 then 
            altitude_1000_r = math.ceil(simDR_vbe_alt_r * 0.001) 
			altitude_100_r = math.ceil((simDR_vbe_alt_r - altitude_1000_r * 1000) * 0.2) * 5
        else
            altitude_1000_r = 12
            altitude_100_r = 100
        end
	else 
        if simDR_vbe_alt_r > 0 and self_test_r < 1 then
            altitude_1000_r = math.floor((simDR_vbe_alt_r / 0.3048) * 0.001)
			altitude_100_r = math.floor(((simDR_vbe_alt_r / 0.3048) - altitude_1000_r * 1000) / 10) * 10
        elseif self_test_r < 1 then
            altitude_1000_r = math.ceil((simDR_vbe_alt_r / 0.3048) * 0.001)
			altitude_100_r = math.ceil(((simDR_vbe_alt_r / 0.3048) - altitude_1000_r * 1000) / 10) * 10
        else
            altitude_1000_r = 12
            altitude_100_r = 100
        end
	end 
    if vbe_mode_r == 0 and self_test_r < 1 then
        if  simDR_vbe_fl_r > 0 then
            simDR_vbe_fl_r = math.floor(simDR_vbe_fl_r * 0.01) *100
        end
        f_level_r = simDR_vbe_fl_r
    elseif self_test_r < 1 then
        f_level_r = math.floor((simDR_vbe_fl_r * 3.280839895013 * 0.01 + 0.49)*0.2) * 500
    else
        f_level_r = 0
    end
    if  self_test_r < 1 then
	   needle_angle_r = altitude_100_r * 360 / 1000
    else
	   needle_angle_r = 36
    end
    brt_r = simDR_brt_r * 100

end


function border_draw()
        
    if simDR_vbe_fl_l > 0 and start_self_test_l < 1 and self_test_l < 1 then
        altitude_current_l = (altitude_1000_l * 1000) + altitude_100_l
        altitude_diff_l = math.abs(f_level_l - altitude_current_l)
        if vbe_mode_l == 0 then
            if altitude_diff_l >= 150 then
                border_l = 2
            elseif altitude_diff_l >= 60 and altitude_diff_l < 150 then
                
                if simDR_ping_pong > 0.3 then
                    border_l = 0
                elseif simDR_ping_pong < -0.3 then
                    border_l = 0
                else
                    border_l = 2
                end
            else
                border_l = 1
            end
        else
           if altitude_diff_l >= 500 then
                border_l = 2
            elseif altitude_diff_l >= 200 and altitude_diff_l < 500 then
                if simDR_ping_pong > 0.3 then
                    border_l = 0
                elseif simDR_ping_pong < -0.3 then
                    border_l = 0
                else
                    border_l = 2
                end
            else
                border_l = 1
            end 
            end 
    
    else
        border_l = 0
    end 
    
    if self_test_l > 0 and vbe_test_l == 3 then
        if simDR_ping_pong > 0.3 then
                    border_l = 0
                elseif simDR_ping_pong < -0.3 then
                    border_l = 0
                else
                    border_l = 1
        end
    end
    
    if simDR_vbe_fl_r > 0 and start_self_test_r < 1 and self_test_r < 1 then
        altitude_current_r = (altitude_1000_r * 1000) + altitude_100_r
        altitude_diff_r = math.abs(f_level_r - altitude_current_r)
        if vbe_mode_r == 0 then
            if altitude_diff_r >= 150 then
                border_r = 2
            elseif altitude_diff_r >= 60 and altitude_diff_r < 150 then
                
                if simDR_ping_pong > 0.3 then
                    border_r = 0
                elseif simDR_ping_pong < -0.3 then
                    border_r = 0
                else
                    border_r = 2
                end
            else
                border_r = 1
            end
        else
           if altitude_diff_r >= 500 then
                border_r = 2
            elseif altitude_diff_r >= 200 and altitude_diff_r < 500 then
                if simDR_ping_pong > 0.3 then
                    border_r = 0
                elseif simDR_ping_pong < -0.3 then
                    border_r = 0
                else
                    border_r = 2
                end
            else
                border_r = 1
            end 
            end 
    
    else
        border_r = 0
    end 
    
    if self_test_r > 0 and vbe_test_r == 3 then
        if simDR_ping_pong > 0.3 then
                    border_r = 0
                elseif simDR_ping_pong < -0.3 then
                    border_r = 0
                else
                    border_r = 1
        end
    end
end

function after_physics()
    altitudes_calc()
    border_draw()
    self_test()
    mode_reset()
end