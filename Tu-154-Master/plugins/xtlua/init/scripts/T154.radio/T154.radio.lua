function deferred_dataref(name,type,notifier)
	print("Deffered dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end

simDR_36vl				= find_dataref("tu154/custom/elec/bus36_volt_left")
simDR_36vr				= find_dataref("tu154/custom/elec/bus36_volt_right")
simDR_vhf_rotary = find_dataref("tu154/custom/rotary/ovhd/vhf_1_right")
simDR_vhf2_rotary = find_dataref("tu154/custom/rotary/ovhd/vhf_2_right")
simDR_nav1_rotary = find_dataref("tu154/custom/rotary/ovhd/nav_1_right")
simDR_nav2_rotary = find_dataref("tu154/custom/rotary/ovhd/nav_2_right")
simDR_spu1 = find_dataref("tu154/custom/switchers/spu_1_source")
simDR_bus27left = find_dataref("tu154/custom/elec/bus27_volt_left")
simDR_bus27right = find_dataref("tu154/custom/elec/bus27_volt_right")
simDR_vhf1 = find_dataref("tu154/custom/switchers/ovhd/vhf_1_on")
simDR_vhf2 = find_dataref("tu154/custom/switchers/ovhd/vhf_2_on")
simDR_nav1 = find_dataref("tu154/custom/switchers/ovhd/curs_np_on_1")
simDR_nav2 = find_dataref("tu154/custom/switchers/ovhd/curs_np_on_2")
simDR_passed = find_dataref("sim/operation/misc/frame_rate_period")
simDR_com1_khz = find_dataref("sim/cockpit2/radios/actuators/com1_frequency_khz")
simDR_com1_mhz = find_dataref("sim/cockpit2/radios/actuators/com1_frequency_Mhz")
simDR_com1_stby_khz = find_dataref("sim/cockpit2/radios/actuators/com1_standby_frequency_khz")
simDR_com1_stby_mhz = find_dataref("sim/cockpit2/radios/actuators/com1_standby_frequency_Mhz")
simDR_com1_freq = find_dataref("sim/cockpit2/radios/actuators/com1_frequency_hz_833")
simDR_com1_freq_stby = find_dataref("sim/cockpit2/radios/actuators/com1_standby_frequency_hz_833")

simDR_sw_sound = find_dataref("tu154/custom/switchers/console/nvu_corr_on")

simCMD_com1_actv_fine_up    = find_command("sim/radios/actv_com1_fine_up_833")
simCMD_com1_actv_fine_dn    = find_command("sim/radios/actv_com1_fine_down_833")
simCMD_com1_stby_fine_up    = find_command("sim/radios/stby_com1_fine_up_833")
simCMD_com1_stby_fine_dn    = find_command("sim/radios/stby_com1_fine_down_833")

simCMD_nav1_fine_up    = find_command("sim/radios/actv_nav1_fine_up")
simCMD_nav1_fine_dn    = find_command("sim/radios/actv_nav1_fine_down")
simCMD_nav2_fine_up    = find_command("sim/radios/actv_nav2_fine_up")
simCMD_nav2_fine_dn    = find_command("sim/radios/actv_nav2_fine_down")

vhf1_100_mode = deferred_dataref("tu154/custom/radios/vhf1_100mode", "number")
vhf2_100_mode = deferred_dataref("tu154/custom/radios/vhf2_100mode", "number")
vhf1_ap = deferred_dataref("tu154/custom/radios/vhf1_ap", "number")
vhf2_ap = deferred_dataref("tu154/custom/radios/vhf2_ap", "number")
vhf1_ps = deferred_dataref("tu154/custom/radios/vhf1_ps", "number")
vhf2_ps = deferred_dataref("tu154/custom/radios/vhf2_ps", "number")
vhf2_ap_lit = deferred_dataref("tu154/custom/radios/vhf2_ap_lit", "number")
vhf1_ap_lit = deferred_dataref("tu154/custom/radios/vhf1_ap_lit", "number")

local vhf1_fast = 0
local vhf2_fast = 0
local sw_sound = 0
local sw_sound1 = 0
local sw_sound2 = 0
local sw_sound3 = 0
local vhf1_freq = 0
local vhf1_freq_set = 0
local vhf2_freq = 0
local vhf2_freq_set = 0
vhf1_ps = 1
vhf2_ps = 1

function com1_actv_dial_up_CMDhandler(phase, duration)

    if phase == 0 then
        if simDR_spu1 == 0 then
            if simDR_bus27left > 5 and simDR_vhf1 > 0 then
                simCMD_com1_actv_fine_up:once()
            end
            simDR_vhf_rotary = simDR_vhf_rotary +300
            if vhf1_fast < 1 then
                vhf1_fast = vhf1_fast +0.15
            end
            if vhf1_100_mode > 0 then
                  if simDR_com1_khz < 901 then
                    simDR_com1_khz = math.ceil(simDR_com1_khz* 0.01) * 100
                  else
                    simDR_com1_khz = 0
                  end
            end
            if vhf2_100_mode > 0 then
                  if simDR_com1_stby_khz < 901 then
                    simDR_com1_stby_khz = math.ceil(simDR_com1_stby_khz* 0.01) * 100
                  else
                    simDR_com1_stby_khz = 0
                  end
            end
        else
            if simDR_bus27right > 5 and simDR_vhf2 > 0 then
                simCMD_com1_actv_fine_up:once()
            end
            simDR_vhf2_rotary = simDR_vhf2_rotary +300
            if vhf2_fast < 1 then
                vhf2_fast = vhf2_fast +0.15
            end
            if vhf2_100_mode > 0 then
                  if simDR_com1_khz < 901 then
                    simDR_com1_khz = math.ceil(simDR_com1_khz* 0.01) * 100
                  else
                    simDR_com1_khz = 0
                  end
            end
            if vhf1_100_mode > 0 then
                  if simDR_com1_stby_khz < 901 then
                    simDR_com1_stby_khz = math.ceil(simDR_com1_stby_khz* 0.01) * 100
                  else
                    simDR_com1_stby_khz = 0
                  end
            end
        end
    end
end

function com1_actv_dial_dn_CMDhandler(phase, duration)

    if phase == 0 then
        if simDR_spu1 == 0 then
            if simDR_bus27left > 5 and simDR_vhf1 > 0 then
                simCMD_com1_actv_fine_dn:once()
            end
            simDR_vhf_rotary = simDR_vhf_rotary +300
            if vhf1_fast < 1 then
                vhf1_fast = vhf1_fast +0.15
            end
            if vhf1_100_mode > 0 then
                  simDR_com1_khz = math.floor(simDR_com1_khz* 0.01) * 100
            end
            if vhf2_100_mode > 0 then
                  simDR_com1_stby_khz = math.floor(simDR_com1_stby_khz* 0.01) * 100
            end
        else
            if simDR_bus27right > 5 and simDR_vhf2 > 0 then
                simCMD_com1_actv_fine_dn:once()
            end
            simDR_vhf2_rotary = simDR_vhf2_rotary +300
            if vhf2_fast < 1 then
                vhf2_fast = vhf2_fast +0.15
            end
            if vhf2_100_mode > 0 then
                  simDR_com1_khz = math.floor(simDR_com1_khz* 0.01) * 100
            end
            if vhf1_100_mode > 0 then
                  simDR_com1_stby_khz = math.floor(simDR_com1_stby_khz* 0.01) * 100
            end
        end
    end

end

function com1_stby_dial_up_CMDhandler(phase, duration)

    if phase == 0 then
        if simDR_spu1 == 0 then
            if simDR_bus27left > 5 and simDR_vhf2 > 0 then
                simCMD_com1_stby_fine_up:once()
            end
            simDR_vhf2_rotary = simDR_vhf2_rotary +300
            if vhf2_fast < 1 then
                vhf2_fast = vhf2_fast +0.15
            end
            
            if vhf1_100_mode > 0 then
                  if simDR_com1_khz < 901 then
                    simDR_com1_khz = math.ceil(simDR_com1_khz* 0.01) * 100
                  else
                    simDR_com1_khz = 0
                  end
            end
            if vhf2_100_mode > 0 then
                  if simDR_com1_stby_khz < 901 then
                    simDR_com1_stby_khz = math.ceil(simDR_com1_stby_khz* 0.01) * 100
                  else
                    simDR_com1_stby_khz = 0
                  end
            end
            
        else
            if simDR_bus27right > 5 and simDR_vhf1 > 0 then
                simCMD_com1_stby_fine_up:once()
            end
            simDR_vhf_rotary = simDR_vhf_rotary +300
            if vhf1_fast < 1 then
                vhf1_fast = vhf1_fast +0.15
            end
            
            if vhf2_100_mode > 0 then
                  if simDR_com1_khz < 901 then
                    simDR_com1_khz = math.ceil(simDR_com1_khz* 0.01) * 100
                  else
                    simDR_com1_khz = 0
                  end
            end
            if vhf1_100_mode > 0 then
                  if simDR_com1_stby_khz < 901 then
                    simDR_com1_stby_khz = math.ceil(simDR_com1_stby_khz* 0.01) * 100
                  else
                    simDR_com1_stby_khz = 0
                  end
            end
            
        end
    end
end

function com1_stby_dial_dn_CMDhandler(phase, duration)

    if phase == 0 then
        if simDR_spu1 == 0 then
            if simDR_bus27left > 5 and simDR_vhf2 > 0 then
                simCMD_com1_stby_fine_dn:once()
            end
            simDR_vhf2_rotary = simDR_vhf2_rotary +300
            if vhf2_fast < 1 then
                vhf2_fast = vhf2_fast +0.2
            end
            
            if vhf1_100_mode > 0 then
                  simDR_com1_khz = math.floor(simDR_com1_khz* 0.01) * 100
            end
            if vhf2_100_mode > 0 then
                  simDR_com1_stby_khz = math.floor(simDR_com1_stby_khz* 0.01) * 100
            end
            
        else
            if simDR_bus27right > 5 and simDR_vhf1 > 0 then
                simCMD_com1_stby_fine_dn:once()
            end
            simDR_vhf_rotary = simDR_vhf2_rotary +300
            if vhf1_fast < 1 then
                vhf1_fast = vhf1_fast +0.2
            end
            
            if vhf2_100_mode > 0 then
                  simDR_com1_khz = math.floor(simDR_com1_khz* 0.01) * 100
            end
            if vhf1_100_mode > 0 then
                  simDR_com1_stby_khz = math.floor(simDR_com1_stby_khz* 0.01) * 100
            end
            
        end
    end

end

function nav1_dial_up_CMDhandler(phase, duration)

    if phase == 0 then
            if bus36 > 0 and simDR_nav1 > 0 then
                simCMD_nav1_fine_up:once()
            end
            simDR_nav1_rotary = simDR_nav1_rotary +300
    end

end
function nav1_dial_dn_CMDhandler(phase, duration)

    if phase == 0 then
            if bus36 > 0 and simDR_nav1 > 0 then
                simCMD_nav1_fine_dn:once()
            end
            simDR_nav1_rotary = simDR_nav1_rotary +300
    end

end
function nav2_dial_up_CMDhandler(phase, duration)

    if phase == 0 then
            if bus36 > 0 and simDR_nav2 > 0 then
                simCMD_nav2_fine_up:once()
            end
            simDR_nav1_rotary = simDR_nav2_rotary +300
    end

end
function nav2_dial_dn_CMDhandler(phase, duration)

    if phase == 0 then
            if bus36 > 0 and simDR_nav2 > 0 then
                simCMD_nav2_fine_dn:once()
            end
            simDR_nav1_rotary = simDR_nav2_rotary +300
    end

end

vhf_actv_up_cmnd	= create_command("t154/vhf/actv_fine_up", "T154 VHF actv fine up", com1_actv_dial_up_CMDhandler)
vhf_actv_dn_cmnd	= create_command("t154/vhf/actv_fine_dn", "T154 VHF actv fine dn", com1_actv_dial_dn_CMDhandler)
vhf_stby_up_cmnd	= create_command("t154/vhf/stby_fine_up", "T154 VHF stby fine up", com1_stby_dial_up_CMDhandler)
vhf_stby_dn_cmnd	= create_command("t154/vhf/stby_fine_dn", "T154 VHF stby fine dn", com1_stby_dial_dn_CMDhandler)
nav1_up_cmnd	= create_command("t154/nav/nav1_fine_up", "T154 NAV1 fine up", nav1_dial_up_CMDhandler)
nav1_dn_cmnd	= create_command("t154/nav/nav1_fine_dn", "T154 NAV1 fine dn", nav1_dial_dn_CMDhandler)
nav2_up_cmnd	= create_command("t154/nav/nav2_fine_up", "T154 NAV2 fine up", nav2_dial_up_CMDhandler)
nav2_dn_cmnd	= create_command("t154/nav/nav2_fine_dn", "T154 NAV2 fine dn", nav2_dial_dn_CMDhandler)

function vhf()

if simDR_36vl > 5 then
    bus36 = 1
elseif simDR_36vr > 5 then
    bus36 = 1
else
    bus36 = 0
end
    
    if vhf1_fast > 0 then
        vhf1_fast = vhf1_fast - simDR_passed
    else
        vhf1_100_mode = 0
    end

    if vhf1_fast > 1 and vhf1_100_mode < 1 then
      vhf1_100_mode = 1
    end
    
    if vhf2_fast > 0 then
        vhf2_fast = vhf2_fast - simDR_passed
    else
        vhf2_100_mode = 0
    end

    if vhf2_fast > 1 and vhf2_100_mode < 1 then
      vhf2_100_mode = 1
    end
    
if vhf1_ap > 0 and sw_sound > 0 then
    if simDR_sw_sound > -2 then
        simDR_sw_sound = -2
        sw_sound = 0
    else
        simDR_sw_sound = -1
        sw_sound= 0
    end
end
if vhf1_ap < 1 and sw_sound < 1 then
    if simDR_sw_sound > -2 then
        simDR_sw_sound = -2
        sw_sound = 1
    else
        simDR_sw_sound = -1
        sw_sound = 1
    end
end 
if vhf2_ap > 0 and sw_sound1 > 0 then
    if simDR_sw_sound > -2 then
        simDR_sw_sound = -2
        sw_sound1 = 0
    else
        simDR_sw_sound = -1
        sw_sound1= 0
    end
end
if vhf2_ap < 1 and sw_sound1 < 1 then
    if simDR_sw_sound > -2 then
        simDR_sw_sound = -2
        sw_sound1 = 1
    else
        simDR_sw_sound = -1
        sw_sound1 = 1
    end
end 

if vhf1_ps > 0 and sw_sound2 > 0 then
    if simDR_sw_sound > -2 then
        simDR_sw_sound = -2
        sw_sound2 = 0
    else
        simDR_sw_sound = -1
        sw_sound2= 0
    end
end
if vhf1_ps < 1 and sw_sound2 < 1 then
    if simDR_sw_sound > -2 then
        simDR_sw_sound = -2
        sw_sound2 = 1
    else
        simDR_sw_sound = -1
        sw_sound2 = 1
    end
end 
if vhf2_ps > 0 and sw_sound3 > 0 then
    if simDR_sw_sound > -2 then
        simDR_sw_sound = -2
        sw_sound3 = 0
    else
        simDR_sw_sound = -1
        sw_sound3= 0
    end
end
if vhf2_ps < 1 and sw_sound3 < 1 then
    if simDR_sw_sound > -2 then
        simDR_sw_sound = -2
        sw_sound3 = 1
    else
        simDR_sw_sound = -1
        sw_sound3 = 1
    end
end
 
if simDR_bus27left > 5 and simDR_vhf1 > 0 then   
    if simDR_spu1 == 0 and simDR_com1_freq == 121500 then
        vhf1_ap_lit = 1
    elseif simDR_spu1 == 1 and simDR_com1_freq_stby == 121500 then
        vhf1_ap_lit = 1
    else
        vhf1_ap_lit = 0
    end
else
    vhf1_ap_lit = 0 
end        
        
if simDR_bus27right > 5 and simDR_vhf2 > 0 then   
    if simDR_spu1 == 1 and simDR_com1_freq == 121500 then
        vhf2_ap_lit = 1
    elseif simDR_spu1 == 0 and simDR_com1_freq_stby == 121500 then
        vhf2_ap_lit = 1
    else
        vhf2_ap_lit = 0
    end
else
    vhf2_ap_lit = 0
end 
    
end

function after_physics()
    vhf()
end