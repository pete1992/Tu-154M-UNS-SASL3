function deferred_dataref(name,type,notifier)
	print("Deffered dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end


simDR_gps_power = find_dataref("sim/cockpit2/radios/actuators/gps_power")
simDR_bus27left = find_dataref("tu154/custom/elec/bus27_volt_left")
simDR_bus27right = find_dataref("tu154/custom/elec/bus27_volt_right")
simDR_vor1_m_a             = find_dataref("tu154/custom/switchers/nav_1_man_auto")
simDR_vor2_m_a             = find_dataref("tu154/custom/switchers/nav_2_man_auto")
simDR_radio_nav1             = find_dataref("sim/cockpit2/radios/actuators/nav1_frequency_hz")
simDR_radio_nav2             = find_dataref("sim/cockpit2/radios/actuators/nav2_frequency_hz")
simDR_radio_nav_freq_hz             = find_dataref("sim/cockpit2/radios/actuators/nav_frequency_hz")
simDR_sw_sound                    = find_dataref("tu154/custom/switchers/console/nvu_corr_on")
simDR_uns_brt = find_dataref("sim/cockpit2/switches/instrument_brightness_ratio")
uns1_on = find_dataref("tu154/custom/uns1_on")
uns2_on = find_dataref("tu154/custom/uns2_on")


uns_brt_l = deferred_dataref("tu154/custom/uns/brt_l", "number")
uns_brt_r = deferred_dataref("tu154/custom/uns/brt_r", "number")
vor1_freq					= deferred_dataref("tu154/custom/uns_vor1_freq", "number")
vor2_freq					= deferred_dataref("tu154/custom/uns_vor2_freq", "number")
vor1_auto					= deferred_dataref("tu154/custom/switchers/uns_vor1_a", "number")
vor2_auto				= deferred_dataref("tu154/custom/switchers/uns_vor2_a", "number")

local sw_sound = 0
local sw_sound2 = 0
local sw_sound3 = 0
local sw_sound4 = 0


function after_physics()
              
    if simDR_bus27left < 5 then
            uns_brt_l = 0
    elseif uns1_on < 1 then
            uns_brt_l = 0
    else
            uns_brt_l = simDR_uns_brt[17]
    end 
    if simDR_bus27right < 5 then
            uns_brt_r = 0
    elseif uns2_on < 1 then
            uns_brt_r = 0
    else
            uns_brt_r = simDR_uns_brt[16]
    end 
    
    if uns1_on > 0 then
        simDR_gps_power = 1
    elseif uns2_on > 0 then
        simDR_gps_power = 1
    else
        simDR_gps_power = 0
    end
    if vor1_auto > 0 and sw_sound < 1 then
        if simDR_sw_sound > -2 then
            simDR_sw_sound = -2
            sw_sound = 1
        else
            simDR_sw_sound = -1
            sw_sound = 1
        end
    end
    if vor1_auto < 1 and sw_sound > 0 then
        if simDR_sw_sound > -2 then
            simDR_sw_sound = -2
            sw_sound = 0
        else
            simDR_sw_sound = -1
            sw_sound = 0
        end
    end
    if vor2_auto > 0 and sw_sound2 < 1 then
        if simDR_sw_sound > -2 then
            simDR_sw_sound = -2
            sw_sound2 = 1
        else
            simDR_sw_sound = -1
            sw_sound2 = 1
        end
    end
    if vor2_auto < 1 and sw_sound2 > 0 then
        if simDR_sw_sound > -2 then
            simDR_sw_sound = -2
            sw_sound2 = 0
        else
            simDR_sw_sound = -1
            sw_sound2 = 0
        end
    end
    
    
    if uns1_on > 0 and sw_sound3 < 1 then
        if simDR_sw_sound > -2 then
            simDR_sw_sound = -2
            sw_sound3 = 1
        else
            simDR_sw_sound = -1
            sw_sound3 = 1
        end
    end
    if uns1_on < 1 and sw_sound3 > 0 then
        if simDR_sw_sound > -2 then
            simDR_sw_sound = -2
            sw_sound3 = 0
        else
            simDR_sw_sound = -1
            sw_sound3 = 0
        end
    end
    if uns2_on > 0 and sw_sound4 < 1 then
        if simDR_sw_sound > -2 then
            simDR_sw_sound = -2
            sw_sound4 = 1
        else
            simDR_sw_sound = -1
            sw_sound4 = 1
        end
    end
    if uns2_on < 1 and sw_sound4 > 0 then
        if simDR_sw_sound > -2 then
            simDR_sw_sound = -2
            sw_sound4 = 0
        else
            simDR_sw_sound = -1
            sw_sound4 = 0
        end
    end
    
    
    
    
    if simDR_vor1_m_a > 0 and vor1_auto > 0 and vor1_freq > 1000 then
        simDR_radio_nav1 = vor1_freq
    end
    
    if simDR_vor2_m_a > 0 and vor2_auto > 0 and vor2_freq > 1000 then
        simDR_radio_nav2 = vor2_freq
    end

end