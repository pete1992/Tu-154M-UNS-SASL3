function deferred_command(name,desc,nilFunc)
	c = XLuaCreateCommand(name,desc)
	print("Deferred command: "..name)
	--XLuaReplaceCommand(c,null_command)
	return nil --make_command_obj(c)
end
function deferred_dataref(name,type,notifier)
	print("Deffereed dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end

def_ladd1_call = find_dataref("tu154/custom/anim/ladder_1_call")
def_ladd2_call = find_dataref("tu154/custom/anim/ladder_2_call")
def_ladd1 = find_dataref("tu154/custom/anim/ladder_1")
def_ladd2 = find_dataref("tu154/custom/anim/ladder_2")
gear_blocks = find_dataref("tu154/custom/anim/gear_blocks")
door1 = find_dataref("tu154/custom/anim/pax_door_1")
door2 = find_dataref("tu154/custom/anim/pax_door_2")
efb_popup6 = find_dataref("tu154/custom/t154_efb/popup_6")
efb_popup7 = find_dataref("tu154/custom/t154_efb/popup_7")
simDR_gs = find_dataref("sim/flightmodel2/position/groundspeed")
hide_autoladder = find_dataref("tu154/custom/t154cfg/hide_autoladder")
stremya1 = deferred_dataref("tu154/custom/t154gnd/stremya1", "number")
stremya1_call = deferred_dataref("tu154/custom/t154gnd/stremya1_call", "number")
ladd1 = deferred_dataref("tu154/custom/t154gnd/ladd1", "number")
ladd1_call = deferred_dataref("tu154/custom/t154gnd/ladd1_call", "number")
stremya2 = deferred_dataref("tu154/custom/t154gnd/stremya2", "number")
stremya2_call = deferred_dataref("tu154/custom/t154gnd/stremya2_call", "number")
ladd2 = deferred_dataref("tu154/custom/t154gnd/ladd2", "number")
ladd2_call = deferred_dataref("tu154/custom/t154gnd/ladd2_call", "number")
autoladd = deferred_dataref("tu154/custom/t154gnd/autoladd", "number")
autoladd_call = deferred_dataref("tu154/custom/t154gnd/autoladd_call", "number")
trap1_lit = deferred_dataref("tu154/custom/t154gnd/trap1_lit", "number")
trap2_lit = deferred_dataref("tu154/custom/t154gnd/trap2_lit", "number")

local will_change = 0
ladd1 = 28
ladd2 = 28

function stremyanka_call_CMDhandler(phase, duration)
     if phase == 0 then
        if efb_popup6 > 0 then
            if stremya1_call < 1 then
                def_ladd1_call = 0
                ladd1_call = 0
                will_change = 1
            else
                stremya1_call = 0
            end
        end
        if efb_popup7 > 0 then
            if stremya2_call < 1 then
                def_ladd2_call = 0
                ladd2_call = 0
                autoladd_call = 0
                will_change = 1
            else
                stremya2_call = 0
            end
        end
     elseif phase == 2 then
        if efb_popup6 > 0 then
            if (def_ladd1_call+ladd1_call) < 1 and will_change > 0 then
                stremya1_call = 1
                will_change = 0
            end
        end
        if efb_popup7 > 0 then
            if (def_ladd2_call+ladd2_call+autoladd_call) < 1 and will_change > 0 then
                stremya2_call = 1
                will_change = 0
            end
        end
     end
end

function lestnica_call_CMDhandler(phase, duration)
     if phase == 0 then
        if efb_popup6 > 0 then
            if ladd1_call < 1 then
                def_ladd1_call = 0
                stremya1_call = 0
                autoladd_call = 0
                will_change = 1
            else
                ladd1_call = 0
            end
        end
        if efb_popup7 > 0 then
            if ladd2_call < 1 then
                def_ladd2_call = 0
                stremya2_call = 0
                autoladd_call = 0
                will_change = 1
            else
                ladd2_call = 0
            end
        end
     elseif phase == 2 then
        if efb_popup6 > 0 then
            if (def_ladd1_call+stremya1_call) < 1 and will_change > 0 then
                ladd1_call = 1
                will_change = 0
            end
        end
        if efb_popup7 > 0 then
            if (def_ladd2_call+stremya2_call+autoladd_call) < 1 and will_change > 0 then
                ladd2_call = 1
                will_change = 0
            end
        end
     end
end

function autolestnica_call_CMDhandler(phase, duration)
     if phase == 0 then
        if efb_popup7 > 0 then
            if autoladd_call < 1 then
                def_ladd2_call = 0
                stremya2_call = 0
                ladd2_call = 0
                will_change = 1
            else
                autoladd_call = 0
            end
        end
     elseif phase == 2 then
        if efb_popup7 > 0 then
            if (def_ladd2_call+stremya2_call+ladd2_call) < 1 and will_change > 0 then
                autoladd_call = 1
                will_change = 0
            end
        end
     end
end

call_stremyanka	= create_command("t154gnd/call_stremyanka", "Call Stremyanka", stremyanka_call_CMDhandler)
call_lestnica	= create_command("t154gnd/call_lestnica", "Call Lestnica", lestnica_call_CMDhandler)
call_autolest	= create_command("t154gnd/call_autolest", "Call Autolest", autolestnica_call_CMDhandler)

function misc_gnd()
    
    trap1_lit = def_ladd1_call + ladd1_call + stremya1_call
    trap2_lit = def_ladd2_call + ladd2_call + stremya2_call + autoladd_call
    
    if def_ladd1_call > 0 then
        ladd1_call = 0
        stremya1_call = 0
    end
    if def_ladd2_call > 0 then
        ladd2_call = 0
        stremya2_call = 0
        autoladd_call = 0
    end
      
    if hide_autoladder > 0 then
       autoladd_call = 0
       autoladd = 0
    end
        
    if door1 > 0 and simDR_gs < 0.35 then
        if stremya1_call > 0 and door1 > 0.9 and ladd1 > 15 and def_ladd1 > 25 then
             if stremya1 < 20 then
                stremya1 = stremya1 + 3*SIM_PERIOD
             else
                stremya1 = 20
             end
        elseif stremya1_call > 0 and door1 > 0.9 and ladd1 > 15 and def_ladd1 < -25 then
             if stremya1 < 20 then
                stremya1 = stremya1 + 3*SIM_PERIOD
             else
                stremya1 = 20
             end
        else
             if stremya1 > 0 then
                stremya1 = stremya1 - 3*SIM_PERIOD
             else
                stremya1 = 0
             end
        end
    else
         if stremya1 > 0 then
            stremya1 = stremya1 - 15*SIM_PERIOD
         else
            stremya1 = 0
         end
        stremya1_call = 0
    end

    if gear_blocks > 0 and def_ladd1 > 48 then
        if ladd1_call > 0 then
             if ladd1 > 0 then
                ladd1 = ladd1 - 2*SIM_PERIOD
             else
                ladd1 = 0
             end
        else
             if ladd1 < 28 then
                ladd1 = ladd1 + 2*SIM_PERIOD
             else
                ladd1 = 28
             end
        end
    elseif gear_blocks > 0 and def_ladd1 < -48 then
        if ladd1_call > 0 then
             if ladd1 > 0 then
                ladd1 = ladd1 - 2*SIM_PERIOD
             else
                ladd1 = 0
             end
        else
             if ladd1 < 28 then
                ladd1 = ladd1 + 2*SIM_PERIOD
             else
                ladd1 = 28
             end
        end
    elseif gear_blocks < 1 then
         if ladd1 < 28 then
            ladd1 = ladd1 + 3*SIM_PERIOD
         else
            ladd1 = 28
         end
         ladd1_call = 0
    else
         if ladd1 < 28 then
            ladd1 = ladd1 + 3*SIM_PERIOD
         else
            ladd1 = 28
         end
    end
   
    if door2 > 0 and simDR_gs < 0.35 then
        if stremya2_call > 0 and door2 > 0.9 and ladd2 > 15 and def_ladd2 > 25 and autoladd == 0 then
             if stremya2 < 20 then
                stremya2 = stremya2 + 3*SIM_PERIOD
             else
                stremya2 = 20
             end
        elseif stremya2_call > 0 and door2 > 0.9 and ladd2 > 15 and def_ladd2 < -25 and autoladd == 0 then
             if stremya2 < 20 then
                stremya2 = stremya2 + 3*SIM_PERIOD
             else
                stremya2 = 20
             end
        else
             if stremya2 > 0 then
                stremya2 = stremya2 - 3*SIM_PERIOD
             else
                stremya2 = 0
             end
        end
    else
         if stremya2 > 0 then
            stremya2 = stremya2 - 15*SIM_PERIOD
         else
            stremya2 = 0
         end
        stremya2_call = 0
    end
    
    if door2 > 0 and simDR_gs < 0.35 then
        if autoladd_call > 0 and door2 > 0.9 and stremya2 == 0 and ladd2 > 15 and def_ladd2 > 25 and stremya2 == 0 then
             if autoladd < 20 then
                autoladd = autoladd + 3*SIM_PERIOD
             else
                autoladd = 20
             end
        elseif autoladd_call > 0 and door2 > 0.9 and stremya2 == 0 and ladd2 > 15 and def_ladd2 < -25 and stremya2 == 0 then
             if autoladd < 20 then
                autoladd = autoladd + 3*SIM_PERIOD
             else
                autoladd = 20
             end
        else
             if autoladd > 0 then
                autoladd = autoladd - 3*SIM_PERIOD
             else
                autoladd = 0
             end
        end
    else
         if autoladd > 0 then
            autoladd = autoladd - 15*SIM_PERIOD
         else
            autoladd = 0
         end
        autoladd_call = 0
    end

    if gear_blocks > 0 and def_ladd2 > 48 then
        if ladd2_call > 0 then
             if ladd2 > 0 then
                ladd2 = ladd2 - 2*SIM_PERIOD
             else
                ladd2 = 0
             end
        else
             if ladd2 < 28 then
                ladd2 = ladd2 + 2*SIM_PERIOD
             else
                ladd2 = 28
             end
        end
    elseif gear_blocks > 0 and def_ladd2 < -48 then
        if ladd2_call > 0 then
             if ladd2 > 0 then
                ladd2 = ladd2 - 2*SIM_PERIOD
             else
                ladd2 = 0
             end
        else
             if ladd2 < 28 then
                ladd2 = ladd2 + 2*SIM_PERIOD
             else
                ladd2 = 28
             end
        end
    elseif gear_blocks < 1 then
         if ladd2 < 28 then
            ladd2 = ladd2 + 3*SIM_PERIOD
         else
            ladd2 = 28
         end
         ladd2_call = 0
    else
         if ladd2 < 28 then
            ladd2 = ladd2 + 3*SIM_PERIOD
         else
            ladd2 = 28
         end
    end
   
end

function after_physics()
    misc_gnd()
end

