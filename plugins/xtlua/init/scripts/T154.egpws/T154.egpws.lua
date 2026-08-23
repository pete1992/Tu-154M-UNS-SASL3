-- T154.egpws.lua

function deferred_dataref(name,type,notifier)
    print("Deffered dataref: "..name)
    dref=XLuaCreateDataRef(name,type,"yes",notifier)
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
simDR_taws1 = find_dataref("tu154/custom/taws/taws_message")
simDR_taws2 = find_dataref("tu154/custom/sounds/taws_rus_phrase")
simDR_taws3 = find_dataref("tu154/custom/sounds/taws_eng_phrase")
simDR_taws_mode = find_dataref("tu154/custom/taws/mode_set")
simDR_alarm = find_dataref("tu154/custom/switchers/ovhd/egpws_alarm_1")
simDR_but_sound = find_dataref("tu154/custom/buttons/srpbz/but_down")
simDR_sw_sound = find_dataref("tu154/custom/switchers/console/nvu_corr_on")
simDR_passed = find_dataref("sim/operation/misc/frame_rate_period")
simDR_36vl = find_dataref("tu154/custom/elec/bus36_volt_left")
simDR_36vr = find_dataref("tu154/custom/elec/bus36_volt_right")
simDR_rv2 = find_dataref("tu154/custom/elec/rv5_right_cc")

dis_sound = deferred_dataref("tu154/custom/egpws/dis_sound","number")
dis_gear = deferred_dataref("tu154/custom/egpws/dis_gear","number")
dis_flaps = deferred_dataref("tu154/custom/egpws/dis_flaps","number")
dis_rppz = deferred_dataref("tu154/custom/egpws/dis_rppz","number")
dis_gs = deferred_dataref("tu154/custom/egpws/dis_gs","number")
srpbz = deferred_dataref("tu154/custom/kontur/srpbz","number")
srpbz_lit = deferred_dataref("tu154/custom/kontur/srpbz_lit","number")
srpbz_lit_set = deferred_dataref("tu154/custom/kontur/srpbz_lit_set","number")
srpbz_rppz_lit = deferred_dataref("tu154/custom/kontur/srpbz_rppz_lit","number")
srpbz_sppz_lit = deferred_dataref("tu154/custom/kontur/srpbz_sppz_lit","number")
srpbz_test_lit = deferred_dataref("tu154/custom/kontur/srpbz_test_lit","number")

-- EGPWS timing constants ------------------------------------------------
local POWER_MIN_VOLTAGE = 5
local POWER_DROPOUT_HOLD = 0.75
local SENSOR_DROPOUT_HOLD = 0.75
local ALERT_REARM_TIME = 1.50
local DEFAULT_ALERT_CONFIRM_TIME = 0.60

-- RPPZ warnings remain responsive, while configuration and glideslope
-- warnings require a longer stable condition before the voice is released.
local alert_confirm_time = {
    [1] = 0.35,
    [3] = 0.35,
    [4] = 0.35,
    [5] = 0.35,
    [6] = 0.35,
    [8] = 1.20,
    [9] = 1.20,
    [11] = 0.35,
    [12] = 0.35,
    [13] = 1.50,
}

local rppz_messages = {
    [1] = true,
    [3] = true,
    [4] = true,
    [5] = true,
    [6] = true,
    [11] = true,
    [12] = true,
}

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
local power_dropout_timer = 0
local rppz_dropout_timer = 0
local sppz_dropout_timer = 0
local rppz_inputs_valid = 0
local sppz_inputs_valid = 0

-- Alert debounce and repeat protection state.
local pending_message = 0
local pending_timer = 0
local pending_rus_phrase = 0
local pending_eng_phrase = 0
local confirmed_message = 0
local last_announced_message = 0
local clear_timer = ALERT_REARM_TIME

srpbz_lit_set = 0.7


local function reset_alert_filter()
    pending_message = 0
    pending_timer = 0
    pending_rus_phrase = 0
    pending_eng_phrase = 0
    confirmed_message = 0
    last_announced_message = 0
    clear_timer = ALERT_REARM_TIME
end


local function update_power_state(dt)
    local power_available = simDR_36vl > POWER_MIN_VOLTAGE or simDR_36vr > POWER_MIN_VOLTAGE

    if power_available then
        volt_36 = 1
        power_dropout_timer = 0
    elseif volt_36 > 0 then
        power_dropout_timer = power_dropout_timer + dt
        if power_dropout_timer >= POWER_DROPOUT_HOLD then
            volt_36 = 0
            power_dropout_timer = 0
        end
    else
        volt_36 = 0
        power_dropout_timer = 0
    end
end


local function update_input_validity(dt)
    vbe_on = 0
    if simDR_vbe1 > 0 or simDR_vbe2 > 0 then
        vbe_on = 1
    end

    var_on = 0
    if simDR_var1 > 0 or simDR_var2 > 0 then
        var_on = 1
    end

    -- Hold short navigation signal dropouts to avoid mode and lamp chatter.
    local rppz_valid_raw = simDR_diss > 0 and simDR_gps_power > 0
    if rppz_valid_raw then
        rppz_inputs_valid = 1
        rppz_dropout_timer = 0
    elseif rppz_inputs_valid > 0 then
        rppz_dropout_timer = rppz_dropout_timer + dt
        if rppz_dropout_timer >= SENSOR_DROPOUT_HOLD then
            rppz_inputs_valid = 0
            rppz_dropout_timer = 0
        end
    end

    local sppz_valid_raw = vbe_on > 0 and var_on > 0 and simDR_svs > 0
    if sppz_valid_raw then
        sppz_inputs_valid = 1
        sppz_dropout_timer = 0
    elseif sppz_inputs_valid > 0 then
        sppz_dropout_timer = sppz_dropout_timer + dt
        if sppz_dropout_timer >= SENSOR_DROPOUT_HOLD then
            sppz_inputs_valid = 0
            sppz_dropout_timer = 0
        end
    end
end


local function suppress_message_audio()
    simDR_taws2 = 0
    simDR_taws3 = 0
end


local function alert_is_disabled(message)
    if dis_gear > 0 and message == 8 then
        return true
    end

    if dis_flaps > 0 and message == 9 then
        return true
    end

    if dis_rppz > 0 and rppz_messages[message] then
        return true
    end

    if dis_gs > 0 and message == 13 then
        return true
    end

    return false
end


local function apply_alert_confirmation(dt)
    -- The built-in test must remain immediate and unfiltered.
    if simDR_taws_mode >= 5 then
        reset_alert_filter()
        return
    end

    -- Sound disable is always immediate. Re-enabling sound requires a fresh
    -- stable warning condition instead of replaying a stale phrase instantly.
    if dis_sound > 0 then
        suppress_message_audio()
        reset_alert_filter()
        return
    end

    local message = simDR_taws1

    if message <= 0 then
        pending_message = 0
        pending_timer = 0
        pending_rus_phrase = 0
        pending_eng_phrase = 0
        confirmed_message = 0

        if last_announced_message > 0 then
            clear_timer = clear_timer + dt
            if clear_timer >= ALERT_REARM_TIME then
                last_announced_message = 0
                clear_timer = ALERT_REARM_TIME
            end
        end
        return
    end

    clear_timer = 0

    -- A warning that is still continuously active has already passed the
    -- confirmation stage and must not be delayed again every frame.
    if confirmed_message == message then
        return
    end

    -- Prevent the same warning from immediately replaying after a very short
    -- clear interval at a threshold boundary.
    if last_announced_message == message then
        suppress_message_audio()
        return
    end

    if pending_message ~= message then
        pending_message = message
        pending_timer = dt
        pending_rus_phrase = simDR_taws2
        pending_eng_phrase = simDR_taws3
    else
        pending_timer = pending_timer + dt

        -- Capture a phrase if the TAWS source publishes it one frame later.
        if pending_rus_phrase == 0 and simDR_taws2 ~= 0 then
            pending_rus_phrase = simDR_taws2
        end
        if pending_eng_phrase == 0 and simDR_taws3 ~= 0 then
            pending_eng_phrase = simDR_taws3
        end
    end

    local confirm_time = alert_confirm_time[message] or DEFAULT_ALERT_CONFIRM_TIME

    if pending_timer < confirm_time then
        suppress_message_audio()
        return
    end

    confirmed_message = message
    last_announced_message = message
    pending_message = 0
    pending_timer = 0

    -- Restore the captured phrase once the warning has remained stable long
    -- enough. This preserves one valid announcement while rejecting spikes.
    if pending_rus_phrase ~= 0 then
        simDR_taws2 = pending_rus_phrase
    end
    if pending_eng_phrase ~= 0 then
        simDR_taws3 = pending_eng_phrase
    end

    pending_rus_phrase = 0
    pending_eng_phrase = 0
end


function dis_sound_CMDhandler(phase,duration)
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


function dis_gear_CMDhandler(phase,duration)
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


function dis_flaps_CMDhandler(phase,duration)
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


function dis_rppz_CMDhandler(phase,duration)
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


function dis_gs_CMDhandler(phase,duration)
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


function srpbz_ovhd_onoff_CMDhandler(phase,duration)
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


dis_sound_cmnd = create_command("egpws/dis_sound","EGPWS Disable sound",dis_sound_CMDhandler)
dis_gear_cmnd = create_command("egpws/dis_gear","EGPWS Disable gear",dis_gear_CMDhandler)
dis_flaps_cmnd = create_command("egpws/dis_flaps","EGPWS Disable flaps",dis_flaps_CMDhandler)
dis_rppz_cmnd = create_command("egpws/dis_rppz","EGPWS Disable rppz",dis_rppz_CMDhandler)
dis_gs_cmnd = create_command("egpws/dis_gs","EGPWS Disable GS",dis_gs_CMDhandler)
srpbz_onoff_cmnd = create_command("srpbz/onoff","SRPBZ ON/OFF",srpbz_ovhd_onoff_CMDhandler)


function egpws()
    local dt = simDR_passed
    if dt < 0 then
        dt = 0
    end

    update_power_state(dt)
    update_input_validity(dt)

    if volt_36 > 0 and srpbz > 0 then
        srpbz_lit = srpbz_lit_set

        if sppz_lit_on > 0 or simDR_taws_mode > 4 then
            srpbz_sppz_lit = srpbz_lit
        else
            srpbz_sppz_lit = 0
        end

        if rppz_lit_on > 0 or simDR_taws_mode > 4 then
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
        elseif rppz_inputs_valid > 0 then
            rppz_lit_on = 0
        else
            rppz_lit_on = 1
        end

        if simDR_taws_mode == 4 then
            sppz_lit_on = 1
        elseif sppz_inputs_valid > 0 then
            sppz_lit_on = 0
        else
            sppz_lit_on = 1
        end

        if srpbz_start > 0 then
            srpbz_timer = srpbz_timer + dt
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
        reset_alert_filter()
    end

    -- The test mode is allowed only when all required sources are available.
    -- Short input dropouts are tolerated by the validity hold above.
    if simDR_taws_mode > 4 then
        if rppz_inputs_valid > 0 and sppz_inputs_valid > 0 and simDR_on_ground > 0 then
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
    elseif sppz_test_set > 0 then
        dis_sound = 0
        dis_gear = 0
        dis_flaps = 0
        dis_rppz = 0
        dis_gs = 0
        simDR_qfeqnh = 1
        sppz_test_set = 0
    end

    -- Category disable switches stay immediate and bypass the debounce logic.
    if simDR_taws_mode < 5 then
        if dis_sound > 0 then
            suppress_message_audio()
            simDR_alarm = 0
        end

        if alert_is_disabled(simDR_taws1) then
            if dis_rppz > 0 and rppz_messages[simDR_taws1] then
                simDR_alarm = 0
            end
            simDR_taws1 = 0
            suppress_message_audio()
        end
    end

    -- Filter only the audible warning phrases. The TAWS source message itself
    -- remains untouched unless the corresponding disable switch is active.
    if volt_36 > 0 and srpbz > 0 then
        apply_alert_confirmation(dt)
    else
        reset_alert_filter()
    end

    if dis_rppz < 1 and dis_sound < 1 then
        simDR_alarm = 1
    end
end


function after_physics()
    egpws()
end
