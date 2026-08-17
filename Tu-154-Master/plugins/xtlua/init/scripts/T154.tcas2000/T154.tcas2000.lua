function deferred_dataref(name,type,notifier)
	print("Deffered dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end

simDR_sqwk	= find_dataref("sim/cockpit2/radios/actuators/transponder_code")
simDR_fid	= find_dataref("sim/cockpit2/tcas/targets/flight_id")
simDR_tcas_disp_mod	= find_dataref("tu154/custom/tcas/screen_mode")
simDR_tcas_sw_mod	= find_dataref("tu154/custom/switchers/tcas/tcas_mode")
simDR_ping_pong	= find_dataref("sim/graphics/animation/ping_pong_2")
simDR_but_sound  = find_dataref("tu154/custom/buttons/srpbz/but_down")
simDR_vsi_brtleft  = find_dataref("tu154/custom/gauges/vsi/vsi_brt_left")
simDR_vsi_brtright  = find_dataref("tu154/custom/gauges/vsi/vsi_brt_right")

simDR_1000_up	= find_command("sim/radios/transponder_1000_up")
simDR_1000_dn	= find_command("sim/radios/transponder_1000_down")
simDR_100_up	= find_command("sim/radios/transponder_100_up")
simDR_100_dn	= find_command("sim/radios/transponder_100_down")
simDR_10_up	= find_command("sim/radios/transponder_10_up")
simDR_10_dn	= find_command("sim/radios/transponder_10_down")
simDR_1_up	= find_command("sim/radios/transponder_1_up")
simDR_1_dn	= find_command("sim/radios/transponder_1_down")

lit_atc = deferred_dataref("tu154/custom/tcas2000/lit_atc", "number")
lit_fid = deferred_dataref("tu154/custom/tcas2000/lit_fid", "number")
lit_xpndr = deferred_dataref("tu154/custom/tcas2000/lit_xpndr", "number")
mode = deferred_dataref("tu154/custom/tcas2000/mode", "number")
tcas_lit = deferred_dataref("tu154/custom/tcas2000/lit", "number")
l1 = deferred_dataref("tu154/custom/tcas2000/l1", "number")
l2 = deferred_dataref("tu154/custom/tcas2000/l2", "number")
r1 = deferred_dataref("tu154/custom/tcas2000/r1", "number")
r2 = deferred_dataref("tu154/custom/tcas2000/r2", "number")
line = deferred_dataref("tu154/custom/tcas2000/line", "string")

local atcfid = 0
local ent = 0

function tcas2000_l1_up_CMDhandler(phase, duration)
    if phase == 0 then
            if atcfid == 0 then
                simDR_1000_up:once()
            end
                   if l1 > 0 then
                    l1 = l1 - 36
                   else
                    l1 = 324
                   end
    end   	
end	
function tcas2000_l1_dn_CMDhandler(phase, duration)
    if phase == 0 then
            if atcfid == 0 then
                simDR_1000_dn:once()
            end
                   if l1 < 324 then
                    l1 = l1 + 36
                   else
                    l1 = 0
                   end
    end   	
end	

function tcas2000_l2_up_CMDhandler(phase, duration)
    if phase == 0 then
            if atcfid == 0 then
                simDR_100_up:once()
            end
                   if l2 > 0 then
                    l2 = l2 - 36
                   else
                    l2 = 324
                   end
    end   	
end	
function tcas2000_l2_dn_CMDhandler(phase, duration)
    if phase == 0 then
            if atcfid == 0 then
                simDR_100_dn:once()
            end
                   if l1 < 324 then
                    l1 = l1 + 36
                   else
                    l1 = 0
                   end
    end   	
end	

function tcas2000_r1_up_CMDhandler(phase, duration)
    if phase == 0 then
            if atcfid == 0 then
                simDR_10_up:once()
            end
                   if r1 > 0 then
                    r1 = r1 - 36
                   else
                    r1 = 324
                   end
    end   	
end	
function tcas2000_r1_dn_CMDhandler(phase, duration)
    if phase == 0 then
            if atcfid == 0 then
                simDR_10_dn:once()
            end
                   if r1 < 324 then
                    r1 = r1 + 36
                   else
                    r1 = 0
                   end
    end   	
end	

function tcas2000_r2_up_CMDhandler(phase, duration)
    if phase == 0 then
            if atcfid == 0 then
                simDR_1_up:once()
                   if r2 > 0 then
                    r2 = r2 - 36
                   else
                    r2 = 324
                   end
            end
    end   	
end	
function tcas2000_r2_dn_CMDhandler(phase, duration)
    if phase == 0 then
            if atcfid == 0 then
                simDR_1_dn:once()
                   if r2 < 324 then
                    r2 = r2 + 36
                   else
                    r2 = 0
                   end
            end
    end   	
end	

function tcas2000_mode_CMDhandler(phase, duration)
    if phase == 0 then
            if simDR_tcas_disp_mod < 5 and simDR_tcas_disp_mod > -1 then
                if atcfid < 1 then
                atcfid = 1
                ent = 0
                else
                atcfid = 0
                ent = 0
                end
            end
        simDR_but_sound = 1
	
     elseif phase == 2 then
        simDR_but_sound = 0
    end   	
end	

function tcas2000_ent_CMDhandler(phase, duration)
    if phase == 0 then
        simDR_but_sound = 1
	
     elseif phase == 2 then
        simDR_but_sound = 0
    end   	
end	

l_1_up	= create_command("tcas2000/l1_up", "TCAS2000 L1 u", tcas2000_l1_up_CMDhandler)
l_1_dn	= create_command("tcas2000/l1_dn", "TCAS2000 L1 d", tcas2000_l1_dn_CMDhandler)
l_2_up	= create_command("tcas2000/l2_up", "TCAS2000 L2 u", tcas2000_l2_up_CMDhandler)
l_2_dn	= create_command("tcas2000/l2_dn", "TCAS2000 L2 d", tcas2000_l2_dn_CMDhandler)
r_1_up	= create_command("tcas2000/r1_up", "TCAS2000 R1 u", tcas2000_r1_up_CMDhandler)
r_1_dn	= create_command("tcas2000/r1_dn", "TCAS2000 R1 d", tcas2000_r1_dn_CMDhandler)
r_2_up	= create_command("tcas2000/r2_up", "TCAS2000 R2 u", tcas2000_r2_up_CMDhandler)
r_2_dn	= create_command("tcas2000/r2_dn", "TCAS2000 R2 d", tcas2000_r2_dn_CMDhandler)
mode_com	= create_command("tcas2000/mode", "TCAS2000 ATC/FID", tcas2000_mode_CMDhandler)
ent_com	= create_command("tcas2000/ent", "TCAS2000 ENT", tcas2000_ent_CMDhandler)

function tcas()
    
    if simDR_tcas_disp_mod == 100 then
        tcas_lit = 0
    else
        tcas_lit = 1
    end
        simDR_vsi_brtleft = 1
        simDR_vsi_brtright = 1
        simDR_tcas_sw_mod = mode
    
    if simDR_tcas_disp_mod < 100 then
        
        if atcfid == 0 then
            if ent < 1 then
                if simDR_sqwk > 999 then
                 line = string.format("  %s", simDR_sqwk)
                 lit_atc = 1
                end
                if simDR_sqwk < 1000 and simDR_sqwk > 99 then
                 line = string.format("  0%s", simDR_sqwk)
                 lit_atc = 1
                end
                if simDR_sqwk < 100 and simDR_sqwk > 9 then
                 line = string.format("  00%s", simDR_sqwk)
                 lit_atc = 1
                end
                if simDR_sqwk < 10 then
                 line = string.format("  000%s", simDR_sqwk)
                 lit_atc = 1
                end
            else
                if simDR_sqwk > 999 then
                 line = string.format("SQ %s", simDR_sqwk)
                 lit_atc = 1
                end
                if simDR_sqwk < 1000 and simDR_sqwk > 99 then
                 line = string.format("SQ 0%s", simDR_sqwk)
                 lit_atc = 1
                end
                if simDR_sqwk < 100 and simDR_sqwk > 9 then
                 line = string.format("SQ 00%s", simDR_sqwk)
                 lit_atc = 1
                end
                if simDR_sqwk < 10 then
                 line = string.format("SQ 000%s", simDR_sqwk)
                 lit_atc = 1
                end
                lit_atc = simDR_ping_pong * 1.3
            end
             lit_fid = 0
             lit_xpndr = 0
        end 
        
        if atcfid == 1 then
             line = string.format("%s", simDR_fid)
             lit_atc = 0
             lit_fid = 1
             lit_xpndr = 0
        end 
        if simDR_tcas_disp_mod == -10 then
             line = string.format("  IDENT")
             lit_atc = 1
             lit_fid = 1
             lit_xpndr = 0
             ent = 0
        end
        if simDR_tcas_disp_mod == -1 then
             line = string.format("  ERROR")
             lit_atc = 0
             lit_fid = 0
             lit_xpndr = 1
             ent = 0
        end
        
        if simDR_tcas_disp_mod == 5 then
             line = string.format("%%%%%%%%%%%%%%%%")
            lit_atc = 1
            lit_fid = 1
            lit_xpndr = 1
        end
               
    end
    
end

function after_physics()
    tcas()
end