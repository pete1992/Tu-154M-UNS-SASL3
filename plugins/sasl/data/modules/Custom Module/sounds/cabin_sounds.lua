--[[
Changelog
- Grouped all 53 existing Dataref bindings through defineProps() while preserving property names, paths, constructors, and original binding order.
- Added X-Plane internal version detection for XP11/XP12-compatible sasl.al.playSample() calls.
- Replaced Russian comments with English comments.
- Fixed radio-altimeter DH power logic so both left and right signals require 27 V power.
- Replaced sum-based ABSU mode tracking with independent roll and pitch state tracking.
- Replaced sum-based warning-switch and cap tracking with independent state tracking.
- Reset pulsed siren and speaker timers when their corresponding warning condition is no longer active.
- Avoided running the landing-light aerodynamic noise loop below its audible 150 kt threshold.
- Cached repeatedly used frame values such as power, ground speed, gear compression, light extension, and volume controls.
- Consolidated mutable sound state and sample handles into tables to keep Lua 5.1 upvalue counts low.
- Preserved alarm priorities, warning timing, sound gains/pitches, taxi-noise threshold, failure probabilities, SmartCopilot ownership logic, and existing unused interfaces.
]]

-- Main cockpit/cabin sound logic.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- General state
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    { "external_view", "sim/graphics/view/view_is_external", globalPropertyi },
    -- Radio altimeter
    { "dh_set_L", "tu154/custom/gauges/alt/radioalt_dh_left", globalPropertyf },
    { "dh_set_R", "tu154/custom/gauges/alt/radioalt_dh_right", globalPropertyf },
    { "rv_angle_L", "tu154/custom/gauges/alt/radioalt_needle_left", globalPropertyf },
    { "rv_angle_R", "tu154/custom/gauges/alt/radioalt_needle_right", globalPropertyf },
    { "rv5_dh_signal_left", "tu154/custom/misc/rv5_dh_signal_left", globalPropertyi },
    { "rv5_dh_signal_right", "tu154/custom/misc/rv5_dh_signal_right", globalPropertyi },
    -- ABSU
    { "roll_main_mode", "tu154/custom/absu/roll_main_mode", globalPropertyi },
    { "pitch_main_mode", "tu154/custom/absu/pitch_main_mode", globalPropertyi },
    { "stu_mode", "tu154/custom/absu/stu_mode", globalPropertyi },
    { "absu_fail_signal", "tu154/custom/absu/absu_fail_signal", globalPropertyi },
    -- Main warning sources
    { "main_gear_flaps", "tu154/custom/alarm/main_gear_flaps", globalPropertyi },
    { "main_pressure", "tu154/custom/alarm/main_pressure", globalPropertyi },
    { "speaker_auasp", "tu154/custom/alarm/speaker_auasp", globalPropertyi },
    { "speaker_fuel", "tu154/custom/alarm/speaker_fuel", globalPropertyi },
    { "speaker_speed", "tu154/custom/alarm/speaker_speed", globalPropertyi },
    { "speaker_absu", "tu154/custom/alarm/speaker_absu", globalPropertyi },
    { "fire_siren", "tu154/custom/fire/fire_siren", globalPropertyi },
    -- Warning controls
    { "srd_buzzer", "tu154/custom/switchers/eng/srd_buzzer", globalPropertyi },
    { "fuel_buzzer", "tu154/custom/switchers/eng/fuel_buzzer", globalPropertyi },
    { "srd_buzzer_cap", "tu154/custom/switchers/eng/srd_buzzer_cap", globalPropertyi },
    { "fuel_buzzer_cap", "tu154/custom/switchers/eng/fuel_buzzer_cap", globalPropertyi },
    { "srd_buzzer_test", "tu154/custom/buttons/eng/srd_buzzer_test", globalPropertyi },
    -- Marker receiver
    { "outer_marker", "sim/cockpit/misc/outer_marker_lit", globalPropertyi },
    { "middle_marker", "sim/cockpit/misc/middle_marker_lit", globalPropertyi },
    { "inner_marker", "sim/cockpit/misc/inner_marker_lit", globalPropertyi },
    -- Landing-light aerodynamic noise
    { "light_open_left", "tu154/custom/anim/light_open_left", globalPropertyf },
    { "light_open_right", "tu154/custom/anim/light_open_right", globalPropertyf },
    { "airspeed", "sim/flightmodel/position/indicated_airspeed", globalPropertyf },
    -- Electrical power
    { "bus27_volt_L", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_R", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "bus27_source_left", "tu154/custom/elec/bus27_source_left", globalPropertyi },
    { "bus27_source_right", "tu154/custom/elec/bus27_source_right", globalPropertyi },
    { "pilot_Z", "sim/aircraft/view/acf_peZ", globalPropertyf },
    -- Air-conditioning
    { "air_usage_L", "tu154/custom/bleed/air_usage_L", globalPropertyf },
    { "air_usage_R", "tu154/custom/bleed/air_usage_R", globalPropertyf },
    -- Landing gear and ground roll
    { "deflection_mtr_2", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalPropertyf },
    { "deflection_mtr_3", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", globalPropertyf },
    { "groundspeed", "sim/flightmodel/position/groundspeed", globalPropertyf },
    -- Flaps
    { "flaps_lever", "tu154/custom/controll/flaps_lever", globalPropertyf },
    -- X-Plane sound volume controls
    { "engine_volume_ratio", "sim/operation/sound/engine_volume_ratio", globalPropertyf },
    { "prop_volume_ratio", "sim/operation/sound/prop_volume_ratio", globalPropertyf },
    { "ground_volume_ratio", "sim/operation/sound/ground_volume_ratio", globalPropertyf },
    { "weather_volume_ratio", "sim/operation/sound/weather_volume_ratio", globalPropertyf },
    { "warning_volume_ratio", "sim/operation/sound/warning_volume_ratio", globalPropertyf },
    { "radio_volume_ratio", "sim/operation/sound/radio_volume_ratio", globalPropertyf },
    { "fan_volume_ratio", "sim/operation/sound/fan_volume_ratio", globalPropertyf },
    -- Failures
    { "main_alarm_fail", "tu154/custom/failures/main_alarm_fail", globalPropertyi },
    { "speaker_alarm_fail", "tu154/custom/failures/speaker_alarm_fail", globalPropertyi },
    { "failures_enabled", "tu154/custom/failures/failures_enabled", globalPropertyi },
    -- SmartCopilot
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf },
})

-- Added compatibility binding; all existing bindings above remain unchanged.
defineProperty("xp_version", globalPropertyi("sim/version/xplane_internal_version"))

local XP11 = get(xp_version) > 120000

local function playPanelSample(sample, looped)
    if XP11 then
        sasl.al.playSample(sample, looped and 1 or 0)
    else
        sasl.al.playSample(sample, looped)
    end
end

-- Sound samples. Keep legacy/unused samples because other aircraft revisions
-- may still depend on these interfaces.
local SAMPLES = {
    absu = sasl.al.loadSample("Custom Sounds/short_speaker.wav"),
    long_speaker = sasl.al.loadSample("Custom Sounds/long_speaker.wav"),
    inverters = sasl.al.loadSample("Custom Sounds/inverters.wav"),
    long_siren = sasl.al.loadSample("Custom Sounds/long_siren.wav"),
    short_siren = sasl.al.loadSample("Custom Sounds/short_siren.wav"),
    bell = sasl.al.loadSample("Custom Sounds/mrp_bell.wav"),
    rv5_tone = sasl.al.loadSample("Custom Sounds/rv5_tone.wav"),
    lights_noise = sasl.al.loadSample("Custom Sounds/lights_noise.wav"),
    air_cond_noise = sasl.al.loadSample("Custom Sounds/air_noise.wav"),
    taxi_noise = sasl.al.loadSample("Custom Sounds/roll_inn.wav"),
    flaps_sound = sasl.al.loadSample("Custom Sounds/flaps_hnd.wav"),
}

local STATE = {
    rv_counter = 0,
    rv_played = true,

    roll_last = get(roll_main_mode),
    pitch_last = get(pitch_main_mode),
    stu_last = get(stu_mode),

    invert_counter = 0,

    short_siren_timer = 0,
    short_speaker_timer = 0,
    long_speaker_timer = 0, -- Preserved legacy state.

    srd_buzzer_last = 0,
    fuel_buzzer_last = 0,
    srd_cap_last = 0,
    fuel_cap_last = 0,
    button_last = 0,

    fail_counter = 0,
    check_time = math.random(15, 30),
}

playPanelSample(SAMPLES.inverters, true)
sasl.al.setSampleGain(SAMPLES.inverters, 0)

playPanelSample(SAMPLES.air_cond_noise, true)
sasl.al.setSampleGain(SAMPLES.air_cond_noise, 0)

-- Load switch/cap samples after the continuously running samples to preserve
-- the original initialization sequence.
SAMPLES.switcher = sasl.al.loadSample("Custom Sounds/metal_switch.wav")
SAMPLES.button = sasl.al.loadSample("Custom Sounds/plastic_btn.wav")
SAMPLES.cap = sasl.al.loadSample("Custom Sounds/cap.wav")

function update()
    local passed = get(frame_time)
    local run = bool2int(passed ~= 0)
    local external = get(external_view)

    local bus27_left = get(bus27_volt_L)
    local bus27_right = get(bus27_volt_R)
    local power = bus27_left > 13 or bus27_right > 13

    local warning_volume = get(warning_volume_ratio)

    --------------------------------------------------------------------------
    -- Miscellaneous controls
    --------------------------------------------------------------------------
    local srd_buzzer_now = get(srd_buzzer)
    local fuel_buzzer_now = get(fuel_buzzer)

    if srd_buzzer_now ~= STATE.srd_buzzer_last
        or fuel_buzzer_now ~= STATE.fuel_buzzer_last then
        playPanelSample(SAMPLES.switcher, false)
    end

    STATE.srd_buzzer_last = srd_buzzer_now
    STATE.fuel_buzzer_last = fuel_buzzer_now

    local srd_cap_now = get(srd_buzzer_cap)
    local fuel_cap_now = get(fuel_buzzer_cap)

    if srd_cap_now ~= STATE.srd_cap_last
        or fuel_cap_now ~= STATE.fuel_cap_last then
        playPanelSample(SAMPLES.cap, false)
    end

    STATE.srd_cap_last = srd_cap_now
    STATE.fuel_cap_last = fuel_cap_now

    local button_now = get(srd_buzzer_test)
    if button_now ~= STATE.button_last then
        playPanelSample(SAMPLES.button, false)
    end
    STATE.button_last = button_now

    --------------------------------------------------------------------------
    -- Radio altimeter DH tone
    --------------------------------------------------------------------------
    local rv_must_play = (
        get(rv5_dh_signal_left) == 1
        or get(rv5_dh_signal_right) == 1
    ) and power

    if rv_must_play and not STATE.rv_played and external == 0 then
        STATE.rv_counter = 7
        STATE.rv_played = true
    end

    if not rv_must_play then
        STATE.rv_played = false
        STATE.rv_counter = 0
    end

    STATE.rv_counter = STATE.rv_counter - passed

    if not sasl.al.isSamplePlaying(SAMPLES.rv5_tone) and STATE.rv_counter > 0 then
        playPanelSample(SAMPLES.rv5_tone, true)
    end

    if STATE.rv_counter <= 0 then
        sasl.al.stopSample(SAMPLES.rv5_tone)
    end

    sasl.al.setSampleGain(SAMPLES.rv5_tone, 1000 * warning_volume)

    --------------------------------------------------------------------------
    -- Main siren
    --------------------------------------------------------------------------
    local main_alarm_ok = get(main_alarm_fail) == 0
    local continuous_siren = (
        get(main_gear_flaps) == 1
        or get(fire_siren) == 1
    ) and power
        and srd_buzzer_now == 1
        and external == 0
        and main_alarm_ok

    local pulsed_pressure_siren = srd_buzzer_now == 1
        and get(main_pressure) == 1
        and power
        and external == 0
        and main_alarm_ok

    if continuous_siren then
        STATE.short_siren_timer = 0

        if not sasl.al.isSamplePlaying(SAMPLES.long_siren) then
            playPanelSample(SAMPLES.long_siren, true)
        end
    elseif pulsed_pressure_siren then
        STATE.short_siren_timer = STATE.short_siren_timer + passed

        if not sasl.al.isSamplePlaying(SAMPLES.long_siren)
            and STATE.short_siren_timer > 0.2 then
            playPanelSample(SAMPLES.long_siren, true)
        end

        if STATE.short_siren_timer > 0.4 then
            STATE.short_siren_timer = 0
            sasl.al.stopSample(SAMPLES.long_siren)
        end
    else
        STATE.short_siren_timer = 0
        sasl.al.stopSample(SAMPLES.long_siren)
    end

    if passed == 0 or external == 1 then
        sasl.al.stopSample(SAMPLES.long_siren)
    end

    sasl.al.setSampleGain(SAMPLES.long_siren, 1000 * warning_volume)

    --------------------------------------------------------------------------
    -- Speaker alarm
    --------------------------------------------------------------------------
    local roll_now = get(roll_main_mode)
    local pitch_now = get(pitch_main_mode)
    local stu_now = get(stu_mode)
    local speaker_alarm_ok = get(speaker_alarm_fail) == 0

    local absu_mode_changed = (
        roll_now ~= STATE.roll_last
        or pitch_now ~= STATE.pitch_last
    ) and (roll_now + pitch_now < 4)

    local stu_disconnected = STATE.stu_last >= 3 and stu_now <= 2

    if power
        and external == 0
        and fuel_buzzer_now == 1
        and speaker_alarm_ok
        and get(absu_fail_signal) == 1 then

        STATE.short_speaker_timer = 0

        if not sasl.al.isSamplePlaying(SAMPLES.absu) then
            playPanelSample(SAMPLES.absu, false)
        end
        sasl.al.stopSample(SAMPLES.long_speaker)

    elseif get(speaker_auasp) == 1
        and power
        and external == 0
        and fuel_buzzer_now == 1
        and speaker_alarm_ok then

        STATE.short_speaker_timer = 0

        if not sasl.al.isSamplePlaying(SAMPLES.long_speaker) then
            playPanelSample(SAMPLES.long_speaker, true)
        end
        sasl.al.stopSample(SAMPLES.absu)

    elseif (get(speaker_fuel) == 1 or get(speaker_speed) == 1)
        and power
        and external == 0
        and fuel_buzzer_now == 1
        and speaker_alarm_ok then

        STATE.short_speaker_timer = STATE.short_speaker_timer + passed

        if not sasl.al.isSamplePlaying(SAMPLES.long_speaker)
            and STATE.short_speaker_timer > 0.3 then
            playPanelSample(SAMPLES.long_speaker, true)
        end

        if STATE.short_speaker_timer > 0.6 then
            STATE.short_speaker_timer = 0
            sasl.al.stopSample(SAMPLES.long_speaker)
        end

        sasl.al.stopSample(SAMPLES.absu)

    elseif (absu_mode_changed or stu_disconnected)
        and power
        and external == 0
        and fuel_buzzer_now == 1
        and speaker_alarm_ok then

        STATE.short_speaker_timer = 0
        playPanelSample(SAMPLES.absu, false)
        sasl.al.stopSample(SAMPLES.long_speaker)

    else
        STATE.short_speaker_timer = 0
        sasl.al.stopSample(SAMPLES.long_speaker)
    end

    STATE.roll_last = roll_now
    STATE.pitch_last = pitch_now
    STATE.stu_last = stu_now

    sasl.al.setSampleGain(SAMPLES.long_speaker, 1000 * warning_volume)

    --------------------------------------------------------------------------
    -- Marker receiver
    --------------------------------------------------------------------------
    local marker_active = get(inner_marker) == 1
        or get(middle_marker) == 1
        or get(outer_marker) == 1

    if marker_active and power and external == 0 then
        if not sasl.al.isSamplePlaying(SAMPLES.bell) then
            playPanelSample(SAMPLES.bell, false)
        end
    end

    sasl.al.setSampleGain(SAMPLES.bell, 1000 * warning_volume)

    --------------------------------------------------------------------------
    -- Rectifier/inverter power noise
    --------------------------------------------------------------------------
    local fan_volume = get(fan_volume_ratio)
    local vu_left = get(bus27_source_left)
    local vu_right = get(bus27_source_right)

    if power then
        STATE.invert_counter = STATE.invert_counter + passed
    else
        STATE.invert_counter = STATE.invert_counter - passed * 0.3
    end

    if STATE.invert_counter > 1 then
        STATE.invert_counter = 1
    elseif STATE.invert_counter < 0 then
        STATE.invert_counter = 0
    end

    local dist = -get(pilot_Z) + 9
    local rectifier_count = bool2int(vu_left == 1 or vu_left == 2)
        + bool2int(vu_right == 1 or vu_right == 2)

    sasl.al.setSampleGain(
        SAMPLES.inverters,
        fan_volume
            * STATE.invert_counter
            * 200
            * rectifier_count
            * (1 - external)
            * math.max(dist - 25, 0)
            * 0.2
            * run
    )
    sasl.al.setSamplePitch(SAMPLES.inverters, STATE.invert_counter * 800 + 200)

    if passed == 0 or external == 1 then
        sasl.al.setSampleGain(SAMPLES.inverters, 0)
    end

    --------------------------------------------------------------------------
    -- Air-conditioning noise
    --------------------------------------------------------------------------
    local air_usage = get(air_usage_L) + get(air_usage_R)

    sasl.al.setSampleGain(
        SAMPLES.air_cond_noise,
        fan_volume
            * math.min(600, air_usage)
            * (1 - external)
            * run
    )
    sasl.al.setSamplePitch(SAMPLES.air_cond_noise, 1000)

    --------------------------------------------------------------------------
    -- High-speed ground-roll noise
    --------------------------------------------------------------------------
    local groundspeed_now = get(groundspeed)
    local gear_compression = math.max(
        get(deflection_mtr_2),
        get(deflection_mtr_3)
    )

    local taxi_gain = bool2int(gear_compression > 0.001)
        * math.max(groundspeed_now - 50, 0)
        * (1 - external)

    local taxi_pitch = 1000 + (groundspeed_now - 80) * 3

    if taxi_gain > 0 then
        if not sasl.al.isSamplePlaying(SAMPLES.taxi_noise) then
            playPanelSample(SAMPLES.taxi_noise, true)
        end
    else
        sasl.al.stopSample(SAMPLES.taxi_noise)
    end

    sasl.al.setSampleGain(
        SAMPLES.taxi_noise,
        taxi_gain * 10 * get(ground_volume_ratio)
    )
    sasl.al.setSamplePitch(SAMPLES.taxi_noise, taxi_pitch)

    --------------------------------------------------------------------------
    -- Extended landing-light aerodynamic noise
    --------------------------------------------------------------------------
    local light_left = get(light_open_left)
    local light_right = get(light_open_right)
    local light_extension = light_left + light_right
    local ias = get(airspeed)

    -- The original gain is zero at and below 150 kt. Do not run the loop there.
    if light_extension > 0.1 and ias > 150 then
        if not sasl.al.isSamplePlaying(SAMPLES.lights_noise) then
            playPanelSample(SAMPLES.lights_noise, true)
        end

        local gain = (ias - 150)
            * light_extension
            * (1 - external)
            * get(weather_volume_ratio)

        sasl.al.setSampleGain(SAMPLES.lights_noise, gain)
        sasl.al.setSamplePitch(SAMPLES.lights_noise, 250 + ias)
    else
        sasl.al.stopSample(SAMPLES.lights_noise)
    end

    --------------------------------------------------------------------------
    -- Random failures
    --------------------------------------------------------------------------
    local run_failures_locally = get(ismaster) ~= 1

    if run_failures_locally then
        local fail_level = get(failures_enabled)
        fail_level = fail_level * 0.05 * 4 ^ (fail_level * 0.5)

        if fail_level > 0 then
            STATE.fail_counter = STATE.fail_counter + passed

            if STATE.fail_counter > STATE.check_time then
                STATE.fail_counter = 0
                STATE.check_time = math.random(15, 30)

                if get(main_alarm_fail) ~= 1 then
                    set(
                        main_alarm_fail,
                        bool2int(math.random() < 0.00001 * fail_level * 0.3)
                    )
                end

                if get(speaker_alarm_fail) ~= 1 then
                    set(
                        speaker_alarm_fail,
                        bool2int(math.random() < 0.00001 * fail_level * 0.3)
                    )
                end
            end
        else
            STATE.fail_counter = 0
            set(main_alarm_fail, 0)
            set(speaker_alarm_fail, 0)
        end
    end
end
