-- arm406.lua
-- ARM-406 / PDU-406: manual-only, simulated emergency locator transmitter.
-- The B2 T154.arm406 self-test supplied the ten-second test concept. Emergency
-- operation is implemented here with the existing M panel properties and SASL
-- audio; it does not depend on B2 DataRefs, xTlua, FMOD, PA3 or another plugin.
-- No crash/G switch, COM tuning, network traffic or real distress transmission.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

local function newInt(path)
    return createGlobalPropertyi(path, 0)
end

local function newFloat(path)
    return createGlobalPropertyf(path, 0)
end

defineProps({
    -- Existing cockpit controls and electrical supply.
    { "arm_switch", "tu154/custom/switchers/ovhd/arm406", globalPropertyi },
    { "test_button", "tu154/custom/buttons/console/pdu406_control", globalPropertyi },
    { "mute_button", "tu154/custom/buttons/console/pdu406_sound_off", globalPropertyi },
    { "manual_button", "tu154/custom/arm406/manual_button", newInt },
    { "bus_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    { "paused", "sim/time/paused", globalPropertyi },

    -- Existing button legends and new annunciators, all in the M namespace.
    { "test_lit", "tu154/custom/lights/button/dejur_contr", globalPropertyf },
    { "mute_lit", "tu154/custom/lights/button/sound_off", globalPropertyf },
    { "arm_lit", "tu154/custom/arm406/arm_lit", newFloat },
    { "emergency_lit", "tu154/custom/arm406/emergency_lit", newFloat },
    { "fault_lit", "tu154/custom/arm406/fault_lit", newFloat },

    -- Published simulation state. Outputs are derived and refreshed each frame.
    -- mode: 0 off/unpowered, 1 ready, 2 self-test, 3 emergency, 4 fault.
    { "mode", "tu154/custom/arm406/mode", newInt },
    { "emergency_latched", "tu154/custom/arm406/emergency_latched", newInt },
    { "test_active", "tu154/custom/arm406/test_active", newInt },
    { "test_passed", "tu154/custom/arm406/test_passed", newInt },
    { "muted", "tu154/custom/arm406/muted", newInt },
    { "tx_1215", "tu154/custom/arm406/tx_1215", newInt },
    { "tx_406", "tu154/custom/arm406/tx_406", newInt },
    { "aural_active", "tu154/custom/arm406/aural_active", newInt },

    -- Optional fault injection: 0 serviceable, 1 failed. The simplified internal
    -- battery supports an already activated beacon; battery ageing is not modeled.
    { "unit_failed", "tu154/custom/arm406/unit_failed", newInt },
    { "battery_failed", "tu154/custom/arm406/battery_failed", newInt },

    -- The PDU monitor is cockpit audio, not a COM receiver or an external siren.
    { "external_view", "sim/graphics/view/view_is_external", globalPropertyi },
    { "sound_on", "sim/operation/sound/sound_on", globalPropertyi },
    { "warning_volume", "sim/operation/sound/warning_volume_ratio", globalPropertyf },
})

local TEST_SECONDS = 10
local MANUAL_HOLD_SECONDS = 2
-- Nominal, deterministic simulation cadence, not a real encoded 406 MHz message.
local BURST_PERIOD = 50
local BURST_SECONDS = 0.5

local latched, silent = false, false
local test_elapsed, transmit_elapsed = -1, 0
local hold_elapsed, qualified_press = 0, false
local last_manual = get(manual_button) > 0
local last_test = get(test_button) > 0
local last_mute = get(mute_button) > 0
local monitor_sample = sasl.al.loadSample("Custom Sounds/arm406_monitor.wav")
local button_sample = sasl.al.loadSample("Custom Sounds/plastic_btn.wav")

local function flag(value)
    return value and 1 or 0
end

local function finite(value, fallback)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return fallback
    end
    return value
end

-- These optional key/joystick commands use exactly the same momentary inputs as
-- the 3D manipulators. A held TEST or SOUND OFF must never toggle every frame.
local function registerButton(name, description, property)
    local command = sasl.createCommand("tu154/arm406/" .. name, description)
    sasl.registerCommandHandler(command, 0, function(phase)
        if phase == 0 then set(property, 1)
        elseif phase == 2 then set(property, 0) end
        return 0
    end)
end

registerButton("activate", "ARM-406: hold 2 seconds for simulated distress", manual_button)
registerButton("test", "ARM-406: start self-test (no distress transmission)", test_button)
registerButton("sound_off", "ARM-406: silence the PDU monitor only", mute_button)

local function stopSample(sample)
    if sample and sasl.al.isSamplePlaying(sample) then sasl.al.stopSample(sample) end
end

function update()
    local is_paused = get(paused) ~= 0
    -- Clamp stalled frames so a single delayed frame cannot complete the guarded
    -- activation. Pause, invalid and negative deltas cannot advance any timer.
    local dt = is_paused and 0 or math.min(math.max(finite(get(frame_time), 0), 0), 1)
    local enabled = get(arm_switch) > 0
    -- Test each bus independently. Two weak buses are not one usable supply;
    -- numeric zero must never be used as a Lua boolean (a defect in the donor).
    local bus_power = finite(get(bus_left), 0) > 13 or finite(get(bus_right), 0) > 13
    local remote_power = enabled and bus_power
    local battery_ok = get(battery_failed) == 0
    local unit_ok = get(unit_failed) == 0
    local manual = get(manual_button) > 0
    local test = get(test_button) > 0
    local mute = get(mute_button) > 0
    local manual_edge = manual and not last_manual
    local test_edge = test and not last_test
    local mute_edge = mute and not last_mute
    local gain = math.max(0, math.min(1, finite(get(warning_volume), 0))) * 600
    local audible = not is_paused and get(external_view) == 0 and get(sound_on) == 1 and gain > 0

    if audible and button_sample and (manual ~= last_manual or test ~= last_test or mute ~= last_mute) then
        sasl.al.setSampleGain(button_sample, gain)
        sasl.al.playSample(button_sample, false)
    end

    if not enabled then
        -- Deliberately switching ARM-406 OFF is the cockpit reset. Merely losing
        -- a bus, pressing TEST or silencing the monitor must not reset distress.
        latched, silent = false, false
        test_elapsed, transmit_elapsed = -1, 0
        hold_elapsed, qualified_press = 0, false
        set(test_passed, 0)
    else
        if not remote_power then
            qualified_press, hold_elapsed = false, 0
            test_elapsed = -1
            set(test_passed, 0)
        end
        if not unit_ok then qualified_press, hold_elapsed = false, 0 end

        -- Require a fresh press made while the remote panel is powered. Holding
        -- the button through OFF/ON or power restoration cannot trigger distress.
        if manual_edge and remote_power and unit_ok and not is_paused then
            qualified_press, hold_elapsed = true, 0
        end
        if not manual then qualified_press, hold_elapsed = false, 0 end
        if qualified_press and not latched then
            hold_elapsed = hold_elapsed + dt
            if hold_elapsed >= MANUAL_HOLD_SECONDS then
                latched, silent = true, false
                test_elapsed, transmit_elapsed = -1, 0
                qualified_press = false
            end
        end

        if test_edge and remote_power and not latched and not is_paused then
            test_elapsed, silent = 0, false
            set(test_passed, 0)
        end
        if test_elapsed >= 0 then
            test_elapsed = test_elapsed + dt
            if test_elapsed >= TEST_SECONDS then
                test_elapsed = -1
                set(test_passed, flag(unit_ok and battery_ok))
            end
        end
        if mute_edge and (latched or test_elapsed >= 0) and not is_paused then silent = true end
    end

    local testing = test_elapsed >= 0
    local transmitting = enabled and latched and unit_ok and (bus_power or battery_ok)
    local panel_power = remote_power or (enabled and latched and battery_ok)
    local fault = not unit_ok or not battery_ok
    local pulse = transmit_elapsed % 1 < 0.5
    -- The ten-second self-test exercises indicators and the local monitor ONLY.
    local test_fault = testing and test_elapsed >= 2 and test_elapsed < 4
    local test_emergency = testing and ((test_elapsed >= 0.4 and test_elapsed < 2)
        or (test_elapsed >= 3 and test_elapsed < 4.6)
        or (test_elapsed >= 5.6 and test_elapsed < 6.6) or test_elapsed >= 7.2)
    local test_tone = testing and test_elapsed >= 3.2 and test_elapsed < 6
    local monitor = (transmitting or test_tone) and not silent

    set(mode, not panel_power and 0 or (fault and 4 or (latched and 3 or (testing and 2 or 1))))
    set(emergency_latched, flag(latched))
    set(test_active, flag(testing))
    set(muted, flag(silent))
    set(tx_1215, flag(transmitting))
    set(tx_406, flag(transmitting and transmit_elapsed % BURST_PERIOD < BURST_SECONDS))
    set(aural_active, flag(monitor))
    set(arm_lit, flag(panel_power and unit_ok))
    set(emergency_lit, flag(panel_power and ((transmitting and pulse) or test_emergency)))
    set(fault_lit, flag(panel_power and (fault or test_fault)))
    set(test_lit, panel_power and (testing and (test_elapsed % 1 < 0.5 and 1 or 0.15) or 1) or 0)
    set(mute_lit, panel_power and (silent and 1 or 0.15) or 0)
    if transmitting then transmit_elapsed = (transmit_elapsed + dt) % BURST_PERIOD end

    if monitor_sample then
        if monitor and audible then
            sasl.al.setSampleGain(monitor_sample, gain)
            if not sasl.al.isSamplePlaying(monitor_sample) then sasl.al.playSample(monitor_sample, true) end
        else
            stopSample(monitor_sample)
        end
    end
    if not audible then stopSample(button_sample) end
    last_manual, last_test, last_mute = manual, test, mute
end

function onModuleShutdown()
    stopSample(monitor_sample)
    stopSample(button_sample)
    -- Do not leave apparent transmission or a held local activation after unload.
    for _, property in ipairs({manual_button, mode, emergency_latched, test_active,
        test_passed, muted, tx_1215, tx_406, aural_active, arm_lit, emergency_lit,
        fault_lit, test_lit, mute_lit}) do
        set(property, 0)
    end
end
