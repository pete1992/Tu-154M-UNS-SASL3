-- absu_ppn13.lua
-- PPN-13 ABSU monitoring panel

--[[
Changelog
- Preserved the existing PPN-13 manipulator animation, failure lookup sequence,
  diagnostic annunciators, lamp test, smoothing, and hydraulic/failure indications.
- Replaced the unused absu_work readiness source with direct ABSU readiness logic.
- Restored the original readiness criteria for PKP/MGV references, hydraulic pressure,
  RA-56 servo availability, SAU/STU, TKS, ABSU damper/control failures, and STU test.
- Kept the current RA-56 channel-to-failure mapping used by the PPN-13 failure scan so
  the READY indication and diagnostic sequence cannot disagree.
- The ABSU READY output now illuminates whenever the monitored ABSU systems are healthy;
  lamp brightness and lamp-test behavior remain unchanged.
- Kept all Dataref bindings in one defineProps() block.
--]]

-- local defineProps Function
local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},

    -- Manipulator inputs.
    {"ack",       "tu154/custom/manipulators/buttons/absu/ppn13_ack",       globalPropertyi},
    {"flt",       "tu154/custom/manipulators/buttons/absu/ppn13_flt",       globalPropertyi},
    {"lookup",    "tu154/custom/manipulators/buttons/absu/ppn13_lookup",    globalPropertyi},
    {"poweroff",  "tu154/custom/manipulators/buttons/absu/ppn13_poweroff",  globalPropertyi},
    {"snp",       "tu154/custom/manipulators/buttons/absu/ppn13_snp",       globalPropertyi},
    {"t1",        "tu154/custom/manipulators/buttons/absu/ppn13_t1",        globalPropertyi},
    {"t2",        "tu154/custom/manipulators/buttons/absu/ppn13_t2",        globalPropertyi},
    {"t3",        "tu154/custom/manipulators/buttons/absu/ppn13_t3",        globalPropertyi},
    {"test_absu", "tu154/custom/manipulators/buttons/absu/ppn13_test_absu", globalPropertyi},
    {"test_svk",  "tu154/custom/manipulators/buttons/absu/ppn13_test_svk",  globalPropertyi},
    {"lid",       "tu154/custom/manipulators/buttons/absu/ppn13_lid",       globalPropertyi},

    -- Animated object outputs.
    {"ack_anim",       "tu154/custom/manipulators/buttons/absu/ppn13_ack_anim",       globalPropertyf},
    {"flt_anim",       "tu154/custom/manipulators/buttons/absu/ppn13_flt_anim",       globalPropertyf},
    {"lookup_anim",    "tu154/custom/manipulators/buttons/absu/ppn13_lookup_anim",    globalPropertyf},
    {"poweroff_anim",  "tu154/custom/manipulators/buttons/absu/ppn13_poweroff_anim",  globalPropertyf},
    {"snp_anim",       "tu154/custom/manipulators/buttons/absu/ppn13_snp_anim",       globalPropertyf},
    {"t1_anim",        "tu154/custom/manipulators/buttons/absu/ppn13_t1_anim",        globalPropertyf},
    {"t2_anim",        "tu154/custom/manipulators/buttons/absu/ppn13_t2_anim",        globalPropertyf},
    {"t3_anim",        "tu154/custom/manipulators/buttons/absu/ppn13_t3_anim",        globalPropertyf},
    {"test_absu_anim", "tu154/custom/manipulators/switches/absu/ppn13_test_absu_anim", globalPropertyf},
    {"test_svk_anim",  "tu154/custom/manipulators/switches/absu/ppn13_test_svk_anim",  globalPropertyf},
    {"lid_anim",       "tu154/custom/manipulators/caps/ppn13_lid",                    globalPropertyf},

    -- Hydraulic switches and indications used by the failure scan.
    {"hydro_ra56_rud_1",  "tu154/custom/switchers/eng/hydro_ra56_rud_1",  globalPropertyi},
    {"hydro_ra56_rud_2",  "tu154/custom/switchers/eng/hydro_ra56_rud_2",  globalPropertyi},
    {"hydro_ra56_rud_3",  "tu154/custom/switchers/eng/hydro_ra56_rud_3",  globalPropertyi},
    {"hydro_ra56_ail_1",  "tu154/custom/switchers/eng/hydro_ra56_ail_1",  globalPropertyi},
    {"hydro_ra56_ail_2",  "tu154/custom/switchers/eng/hydro_ra56_ail_2",  globalPropertyi},
    {"hydro_ra56_ail_3",  "tu154/custom/switchers/eng/hydro_ra56_ail_3",  globalPropertyi},
    {"hydro_ra56_elev_1", "tu154/custom/switchers/eng/hydro_ra56_elev_1", globalPropertyi},
    {"hydro_ra56_elev_2", "tu154/custom/switchers/eng/hydro_ra56_elev_2", globalPropertyi},
    {"hydro_ra56_elev_3", "tu154/custom/switchers/eng/hydro_ra56_elev_3", globalPropertyi},
    {"pressure_ind_1", "tu154/custom/gauges/hydro/pressure_ind_1", globalPropertyf},
    {"pressure_ind_2", "tu154/custom/gauges/hydro/pressure_ind_2", globalPropertyf},
    {"pressure_ind_3", "tu154/custom/gauges/hydro/pressure_ind_3", globalPropertyf},

    -- ABSU failures.
    {"absu_ra56_roll_fail",  "tu154/custom/failures/absu_ra56_roll_fail",  globalPropertyi},
    {"absu_ra56_pitch_fail", "tu154/custom/failures/absu_ra56_pitch_fail", globalPropertyi},
    {"absu_ra56_yaw_fail",   "tu154/custom/failures/absu_ra56_yaw_fail",   globalPropertyi},
    {"absu_damp_roll_fail",  "tu154/custom/failures/absu_damp_roll_fail",  globalPropertyi},
    {"absu_damp_pitch_fail", "tu154/custom/failures/absu_damp_pitch_fail", globalPropertyi},
    {"absu_damp_yaw_fail",   "tu154/custom/failures/absu_damp_yaw_fail",   globalPropertyi},
    {"absu_contr_roll_fail", "tu154/custom/failures/absu_contr_roll_fail", globalPropertyi},
    {"absu_contr_pitch_fail","tu154/custom/failures/absu_contr_pitch_fail",globalPropertyi},

    -- ABSU readiness sources.
    {"pkp_fail_left",  "tu154/custom/bkk/pkp_fail_left",  globalPropertyi},
    {"pkp_fail_right", "tu154/custom/bkk/pkp_fail_right", globalPropertyi},
    {"mgv_contr_fail", "tu154/custom/bkk/mgv_contr_fail", globalPropertyi},
    {"sau_stu_on",     "tu154/custom/switchers/ovhd/sau_stu_on", globalPropertyi},
    {"tks_fail_left",  "tu154/custom/tks/fail_left",  globalPropertyi},
    {"tks_fail_right", "tu154/custom/tks/fail_right", globalPropertyi},
    {"absu_nav_on",       "tu154/custom/switchers/console/absu_nav_on",       globalPropertyi},
    {"absu_landing_on",   "tu154/custom/switchers/console/absu_landing_on",   globalPropertyi},
    {"absu_speed_test_2", "tu154/custom/buttons/console/absu_speed_test_2",    globalPropertyi},

    -- Power and lamp test.
    {"bus27_volt_left",  "tu154/custom/elec/bus27_volt_left",  globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
    {"test_lights",      "tu154/custom/buttons/lamp_test_pa56", globalPropertyi},

    -- PPN-13 annunciator outputs.
    {"servo_pitch_lt", "tu154/custom/systems/absu/ppn13/servo_pitch_lt", globalPropertyf},
    {"servo_roll_lt",  "tu154/custom/systems/absu/ppn13/servo_roll_lt",  globalPropertyf},
    {"servo_yaw_lt",   "tu154/custom/systems/absu/ppn13/servo_yaw_lt",   globalPropertyf},
    {"bdg_pitch_lt",   "tu154/custom/systems/absu/ppn13/bdg_pitch_lt",   globalPropertyf},
    {"bdg_roll_lt",    "tu154/custom/systems/absu/ppn13/bdg_roll_lt",    globalPropertyf},
    {"bdg_yaw_lt",     "tu154/custom/systems/absu/ppn13/bdg_yaw_lt",     globalPropertyf},
    {"cws1_lt",        "tu154/custom/systems/absu/ppn13/cws1_lt",        globalPropertyf},
    {"cws2_lt",        "tu154/custom/systems/absu/ppn13/cws2_lt",        globalPropertyf},
    {"bns_p_lt",       "tu154/custom/systems/absu/ppn13/bns_p_lt",       globalPropertyf},
    {"bap_p_lt",       "tu154/custom/systems/absu/ppn13/bap_p_lt",       globalPropertyf},
    {"bap_r_lt",       "tu154/custom/systems/absu/ppn13/bap_r_lt",       globalPropertyf},
    {"vkv_lt",         "tu154/custom/systems/absu/ppn13/vkv_lt",         globalPropertyf},
    {"vu_lt",          "tu154/custom/systems/absu/ppn13/vu_lt",          globalPropertyf},
    {"ute_lt",         "tu154/custom/systems/absu/ppn13/ute_lt",         globalPropertyf},
    {"stu_p_lt",       "tu154/custom/systems/absu/ppn13/stu_p_lt",       globalPropertyf},
    {"stu_r_lt",       "tu154/custom/systems/absu/ppn13/stu_r_lt",       globalPropertyf},
    {"at_lt",          "tu154/custom/systems/absu/ppn13/at_lt",          globalPropertyf},
    {"bsn_lt",         "tu154/custom/systems/absu/ppn13/bsn_lt",         globalPropertyf},
    {"mgv_p_stu_lt",   "tu154/custom/systems/absu/ppn13/mgv_p_stu_lt",   globalPropertyf},
    {"mgv_r_stu_lt",   "tu154/custom/systems/absu/ppn13/mgv_r_stu_lt",   globalPropertyf},
    {"mgv_p_sau_lt",   "tu154/custom/systems/absu/ppn13/mgv_p_sau_lt",   globalPropertyf},
    {"mgv_r_sau_lt",   "tu154/custom/systems/absu/ppn13/mgv_r_sau_lt",   globalPropertyf},
    {"ks_lt",          "tu154/custom/systems/absu/ppn13/ks_lt",          globalPropertyf},
    {"bns_r_lt",       "tu154/custom/systems/absu/ppn13/bns_r_lt",       globalPropertyf},
    {"ch1_lt",         "tu154/custom/systems/absu/ppn13/ch1_lt",         globalPropertyf},
    {"ch2_lt",         "tu154/custom/systems/absu/ppn13/ch2_lt",         globalPropertyf},
    {"ch3_lt",         "tu154/custom/systems/absu/ppn13/ch3_lt",         globalPropertyf},
    {"ch4_lt",         "tu154/custom/systems/absu/ppn13/ch4_lt",         globalPropertyf},
    {"absu_ready_lt",  "tu154/custom/systems/absu/ppn13/absu_ready_lt",  globalPropertyf},
})

local function bool2int(value)
    return value and 1 or 0
end

local lightOutputs = {
    servo_pitch_lt = servo_pitch_lt,
    servo_roll_lt = servo_roll_lt,
    servo_yaw_lt = servo_yaw_lt,
    bdg_pitch_lt = bdg_pitch_lt,
    bdg_roll_lt = bdg_roll_lt,
    bdg_yaw_lt = bdg_yaw_lt,
    cws1_lt = cws1_lt,
    cws2_lt = cws2_lt,
    bns_p_lt = bns_p_lt,
    bap_p_lt = bap_p_lt,
    bap_r_lt = bap_r_lt,
    vkv_lt = vkv_lt,
    vu_lt = vu_lt,
    ute_lt = ute_lt,
    stu_p_lt = stu_p_lt,
    stu_r_lt = stu_r_lt,
    at_lt = at_lt,
    bsn_lt = bsn_lt,
    mgv_p_stu_lt = mgv_p_stu_lt,
    mgv_r_stu_lt = mgv_r_stu_lt,
    mgv_p_sau_lt = mgv_p_sau_lt,
    mgv_r_sau_lt = mgv_r_sau_lt,
    ks_lt = ks_lt,
    bns_r_lt = bns_r_lt,
    ch1_lt = ch1_lt,
    ch2_lt = ch2_lt,
    ch3_lt = ch3_lt,
    ch4_lt = ch4_lt,
    absu_ready_lt = absu_ready_lt,
}

local diagnosticLightNames = {
    "servo_pitch_lt", "servo_roll_lt", "servo_yaw_lt",
    "bdg_pitch_lt", "bdg_roll_lt", "bdg_yaw_lt", "cws1_lt", "cws2_lt",
    "bns_p_lt", "bap_p_lt", "bap_r_lt", "vkv_lt", "vu_lt", "ute_lt",
    "stu_p_lt", "stu_r_lt", "at_lt", "bsn_lt", "mgv_p_stu_lt",
    "mgv_r_stu_lt", "mgv_p_sau_lt", "mgv_r_sau_lt", "ks_lt", "bns_r_lt",
    "ch1_lt", "ch2_lt", "ch3_lt", "ch4_lt",
}

local lampTargets = {}
for name in pairs(lightOutputs) do
    lampTargets[name] = 0
end

local animationPairs = {
    {ack, ack_anim}, {flt, flt_anim}, {lookup, lookup_anim},
    {poweroff, poweroff_anim}, {snp, snp_anim},
    {t1, t1_anim}, {t2, t2_anim}, {t3, t3_anim},
    {test_absu, test_absu_anim}, {test_svk, test_svk_anim}, {lid, lid_anim},
}

-----------------------------------------------------------------------
-- Animation and lamp smoothing
-----------------------------------------------------------------------
local function smoothValue(target, current, frameTime, factor)
    local step = math.min(1, math.max(frameTime, 0) * factor)
    if target >= 0.999 and current >= 0.99 then
        return 1
    elseif target <= 0.001 and current <= 0.01 then
        return 0
    end
    return current + (target - current) * step
end

local function updateAnimations(frameTime)
    for _, pair in ipairs(animationPairs) do
        set(pair[2], smoothValue(get(pair[1]), get(pair[2]), frameTime, 9.5))
    end

    -- The covered test switches cannot remain selected under a closed lid.
    if get(lid_anim) < 0.5 then
        if get(test_svk) ~= 0 then set(test_svk, 0) end
        if get(test_absu) ~= 0 then set(test_absu, 0) end
    end
end

-----------------------------------------------------------------------
-- ABSU readiness
-----------------------------------------------------------------------
local stuTestElapsed = 0

local function hasSufficientHydraulicPressure()
    local lowPressureSystems =
        bool2int(get(pressure_ind_1) < 100) +
        bool2int(get(pressure_ind_2) < 100) +
        bool2int(get(pressure_ind_3) < 100)

    return lowPressureSystems < 2
end

local function getPitchServoChannels()
    local failure = get(absu_ra56_pitch_fail)

    local channel1 =
        get(hydro_ra56_elev_1) ~= 0
        and failure ~= 3

    local channel2 =
        get(hydro_ra56_elev_2) ~= 0
        and failure < 2

    local channel3 =
        get(hydro_ra56_elev_3) ~= 0
        and failure == 0

    return channel1, channel2, channel3
end

local function getRollServoChannels()
    local failure = get(absu_ra56_roll_fail)

    local channel1 =
        get(hydro_ra56_ail_1) ~= 0
        and failure ~= 3

    local channel2 =
        get(hydro_ra56_ail_2) ~= 0
        and failure < 1

    local channel3 =
        get(hydro_ra56_ail_3) ~= 0
        and failure < 2

    return channel1, channel2, channel3
end

local function getYawServoChannels()
    local failure = get(absu_ra56_yaw_fail)

    local channel1 =
        get(hydro_ra56_rud_1) ~= 0
        and failure ~= 3

    local channel2 =
        get(hydro_ra56_rud_2) ~= 0
        and failure < 1

    local channel3 =
        get(hydro_ra56_rud_3) ~= 0
        and failure < 2

    return channel1, channel2, channel3
end

local function updateStuTestTimer(frameTime)
    local navPrepared = get(absu_nav_on) == 1
    local landingPrepared = get(absu_landing_on) == 1

    if get(absu_speed_test_2) == 1 and (navPrepared or landingPrepared) then
        stuTestElapsed = stuTestElapsed + frameTime
    else
        stuTestElapsed = 0
    end
end

local function isAbsuReady(frameTime)
    updateStuTestTimer(frameTime)

    if not hasSufficientHydraulicPressure() then
        return false
    end

    local pitch1, pitch2, pitch3 = getPitchServoChannels()
    local roll1, roll2, roll3 = getRollServoChannels()
    local yaw1, yaw2, yaw3 = getYawServoChannels()

    local pitchServosReady =
        bool2int(pitch1) + bool2int(pitch2) + bool2int(pitch3) > 1

    local rollServosReady =
        bool2int(roll1) + bool2int(roll2) + bool2int(roll3) > 1

    local yawServosReady =
        bool2int(yaw1) + bool2int(yaw2) + bool2int(yaw3) > 1

    local channel1Working = pitch1 or roll1 or yaw1
    local channel2Working = pitch2 or roll2 or yaw2
    local channel3Working = pitch3 or roll3 or yaw3

    local attitudeReferencesReady =
        get(pkp_fail_left)
        + get(pkp_fail_right)
        + get(mgv_contr_fail) < 2

    local tksReady =
        get(tks_fail_left) + get(tks_fail_right) == 0

    local dampersReady =
        get(absu_damp_roll_fail) == 0
        and get(absu_damp_pitch_fail) == 0
        and get(absu_damp_yaw_fail) == 0

    local controlsReady =
        get(absu_contr_roll_fail) == 0
        and get(absu_contr_pitch_fail) == 0

    return attitudeReferencesReady
        and pitchServosReady
        and rollServosReady
        and yawServosReady
        and channel1Working
        and channel2Working
        and channel3Working
        and get(sau_stu_on) == 1
        and tksReady
        and stuTestElapsed < 0.5
        and dampersReady
        and controlsReady
end

-----------------------------------------------------------------------
-- Failure lookup sequence
-----------------------------------------------------------------------
local states = {
    servo_pitch = 0,
    servo_roll = 1,
    servo_yaw = 2,
    bdg_pitch = 3,
    bdg_roll = 4,
    bdg_yaw = 5,
    cws1 = 6,
    cws2 = 7,
}

local scan = {
    active = false,
    state = states.servo_pitch,
    elapsed = 0,
}

local function clearDiagnosticLights()
    for _, name in ipairs(diagnosticLightNames) do
        lampTargets[name] = 0
    end
end

local function resetScan()
    scan.state = states.servo_pitch
    scan.elapsed = 0
    clearDiagnosticLights()
end

local function nextState()
    scan.state = scan.state + 1
    scan.elapsed = 0
    clearDiagnosticLights()
end

local function showServoFailure(mainLight, channel1, channel2, channel3)
    local failedChannels = bool2int(channel1) + bool2int(channel2) + bool2int(channel3)
    lampTargets[mainLight] = bool2int(failedChannels > 1)
    lampTargets.ch1_lt = bool2int(channel1)
    lampTargets.ch2_lt = bool2int(channel2)
    lampTargets.ch3_lt = bool2int(channel3)

    -- Healthy servo groups are skipped. A failed group remains displayed
    -- until ACK is pressed, matching the later automatic failure steps.
    if failedChannels == 0 then
        nextState()
    elseif scan.elapsed > 0.3 and get(ack) == 1 then
        nextState()
    end
end

local function showTimedFailure(lightName, failed, lastState)
    lampTargets[lightName] = bool2int(failed)
    if not failed or scan.elapsed > 1 then
        if lastState then
            resetScan()
        else
            nextState()
        end
    end
end

local function updateFailureScan(frameTime)
    if get(lookup) ~= 1 then
        if scan.active then
            scan.active = false
            resetScan()
        end
        return
    end

    if not scan.active then
        scan.active = true
        resetScan()
    end
    scan.elapsed = scan.elapsed + frameTime

    local hydraulicsAvailable = hasSufficientHydraulicPressure()

    if scan.state == states.servo_pitch then
        local failure = get(absu_ra56_pitch_fail)
        showServoFailure(
            "servo_pitch_lt",
            get(hydro_ra56_elev_1) == 0 or failure == 3 or not hydraulicsAvailable,
            get(hydro_ra56_elev_2) == 0 or failure >= 2 or not hydraulicsAvailable,
            get(hydro_ra56_elev_3) == 0 or failure >= 1 or not hydraulicsAvailable
        )
    elseif scan.state == states.servo_roll then
        local failure = get(absu_ra56_roll_fail)
        showServoFailure(
            "servo_roll_lt",
            get(hydro_ra56_ail_1) == 0 or failure == 3 or not hydraulicsAvailable,
            get(hydro_ra56_ail_2) == 0 or failure >= 1 or not hydraulicsAvailable,
            get(hydro_ra56_ail_3) == 0 or failure >= 2 or not hydraulicsAvailable
        )
    elseif scan.state == states.servo_yaw then
        local failure = get(absu_ra56_yaw_fail)
        showServoFailure(
            "servo_yaw_lt",
            get(hydro_ra56_rud_1) == 0 or failure == 3 or not hydraulicsAvailable,
            get(hydro_ra56_rud_2) == 0 or failure >= 1 or not hydraulicsAvailable,
            get(hydro_ra56_rud_3) == 0 or failure >= 2 or not hydraulicsAvailable
        )
    elseif scan.state == states.bdg_pitch then
        showTimedFailure("bdg_pitch_lt", get(absu_damp_pitch_fail) == 1, false)
    elseif scan.state == states.bdg_roll then
        showTimedFailure("bdg_roll_lt", get(absu_damp_roll_fail) == 1, false)
    elseif scan.state == states.bdg_yaw then
        showTimedFailure("bdg_yaw_lt", get(absu_damp_yaw_fail) == 1, false)
    elseif scan.state == states.cws1 then
        showTimedFailure("cws1_lt", get(absu_contr_pitch_fail) == 1, false)
    elseif scan.state == states.cws2 then
        showTimedFailure("cws2_lt", get(absu_contr_roll_fail) == 1, true)
    end
end

-----------------------------------------------------------------------
-- Lamp outputs
-----------------------------------------------------------------------
local function updateLights(frameTime)
    local rightVoltage = math.max((get(bus27_volt_right) - 10) / 18.5, 0)
    local normalBrightness = math.max(
        (math.max(get(bus27_volt_left), get(bus27_volt_right)) - 10) / 18.5,
        0
    )
    local testBrightness = get(test_lights) * rightVoltage

    lampTargets.absu_ready_lt = bool2int(isAbsuReady(frameTime))

    for name, property in pairs(lightOutputs) do
        local target = math.max(lampTargets[name] * normalBrightness, testBrightness)
        set(property, smoothValue(target, get(property), frameTime, 11))
    end
end


function update()
    local frameTime = math.max(get(frame_time), 0)
    updateFailureScan(frameTime)
    updateLights(frameTime)
    updateAnimations(frameTime)
end
