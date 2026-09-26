-- taws_sound.lua
-- taws sound logic

local function defineProps(defs)
    for _, def in ipairs(defs) do
        local prop
        if def[4] ~= nil then
            prop = def[3](def[2], def[4])
        else
            prop = def[3](def[2])
        end
        defineProperty(def[1], prop)
    end
end

defineProps({
    -- Existing TAWS voice selection and playback requests.
    {"taws_english", "tu154/custom/taws/taws_english", globalPropertyi},
    {"taws_eng_phrase", "tu154/custom/sounds/taws_eng_phrase", globalPropertyi},
    {"taws_rus_phrase", "tu154/custom/sounds/taws_rus_phrase", globalPropertyi},
    {"external_view", "sim/graphics/view/view_is_external", globalPropertyi},
    -- Enforce controls at playback too: cross-plugin phrase writes are asynchronous.
    {"taws_mode", "tu154/custom/taws/mode_set", globalPropertyi},
    {"taws_message", "tu154/custom/taws/taws_message", globalPropertyi},
    {"srpbz", "tu154/custom/kontur/srpbz", globalPropertyf},
    {"egpws_alarm_1", "tu154/custom/switchers/ovhd/egpws_alarm_1", globalPropertyi},
    {"egpws_alarm_2", "tu154/custom/switchers/ovhd/egpws_alarm_2", globalPropertyi},
    {"dis_sound", "tu154/custom/egpws/dis_sound", globalPropertyf},
    {"dis_gear", "tu154/custom/egpws/dis_gear", globalPropertyf},
    {"dis_flaps", "tu154/custom/egpws/dis_flaps", globalPropertyf},
    {"dis_rppz", "tu154/custom/egpws/dis_rppz", globalPropertyf},
    {"dis_gs", "tu154/custom/egpws/dis_gs", globalPropertyf},
    {"taws_bus36_right", "tu154/custom/elec/bus36_volt_right", globalPropertyf},
    -- Native alert level; PWS mode alone only describes takeoff/approach readiness.
    {"windshear_warning", "sim/cockpit2/annunciators/windshear_warning_systems", globalPropertyi},
    {"windshear_auto", "tu154/custom/wx2000_windshear", globalPropertyf},
    {"weather_ready", "tu154/custom/kontur/weather_ready", globalPropertyf},
    {"weather_sys", "tu154/custom/kontur/weather_sys", globalPropertyf},
    {"weather_bus36", "tu154/custom/elec/bus36_volt_left", globalPropertyf},
})

-- sounds

local eng_alt_50 = sasl.al.loadSample('Custom Sounds/taws/eng/alt_50.wav')
local eng_alt_200 = sasl.al.loadSample('Custom Sounds/taws/eng/alt_200.wav')
local eng_alt_500 = sasl.al.loadSample('Custom Sounds/taws/eng/alt_500.wav')
local eng_alt_1000 = sasl.al.loadSample('Custom Sounds/taws/eng/alt_1000.wav')
local eng_check_alt = sasl.al.loadSample('Custom Sounds/taws/eng/check_alt.wav')
local eng_dont_sink = sasl.al.loadSample('Custom Sounds/taws/eng/dont_sink.wav')
local eng_glideslope = sasl.al.loadSample('Custom Sounds/taws/eng/glideslope.wav')
local eng_pull_up = sasl.al.loadSample('Custom Sounds/taws/eng/pull_up.wav')
local eng_sink_rate = sasl.al.loadSample('Custom Sounds/taws/eng/sink_rate.wav')
local eng_terrain = sasl.al.loadSample('Custom Sounds/taws/eng/terrain.wav')
local eng_terrain_ahead = sasl.al.loadSample('Custom Sounds/taws/eng/terrain_ahead.wav')
local eng_too_low_flaps = sasl.al.loadSample('Custom Sounds/taws/eng/too_low_flaps.wav')
local eng_too_low_gear = sasl.al.loadSample('Custom Sounds/taws/eng/too_low_gear.wav')
local eng_too_low_terrain = sasl.al.loadSample('Custom Sounds/taws/eng/too_low_terrain.wav')

-- The legacy "rus" directory now contains a second English TAWS voice set.
-- Its radio-altimeter callouts announce feet, so keep the spoken value in the
-- filename and let taws_warn_logic.lua trigger them at the matching height.
local rus_alt_5 = sasl.al.loadSample('Custom Sounds/taws/rus/5ft.wav')
local rus_alt_10 = sasl.al.loadSample('Custom Sounds/taws/rus/10ft.wav')
local rus_alt_20 = sasl.al.loadSample('Custom Sounds/taws/rus/20ft.wav')
local rus_alt_30 = sasl.al.loadSample('Custom Sounds/taws/rus/30ft.wav')
local rus_alt_40 = sasl.al.loadSample('Custom Sounds/taws/rus/40ft.wav')
local rus_alt_50 = sasl.al.loadSample('Custom Sounds/taws/rus/50ft.wav')
local rus_alt_60 = sasl.al.loadSample('Custom Sounds/taws/rus/60ft.wav')
local rus_alt_70 = sasl.al.loadSample('Custom Sounds/taws/rus/70ft.wav')
local rus_alt_100 = sasl.al.loadSample('Custom Sounds/taws/rus/100ft.wav')
local rus_alt_200 = sasl.al.loadSample('Custom Sounds/taws/rus/200ft.wav')
local rus_alt_300 = sasl.al.loadSample('Custom Sounds/taws/rus/300ft.wav')
local rus_alt_400 = sasl.al.loadSample('Custom Sounds/taws/rus/400ft.wav')
local rus_alt_500 = sasl.al.loadSample('Custom Sounds/taws/rus/500ft.wav')
local rus_alt_1000 = sasl.al.loadSample('Custom Sounds/taws/rus/1000ft.wav')
local rus_alt_2500 = sasl.al.loadSample('Custom Sounds/taws/rus/2500ft.wav')
local rus_check_alt = sasl.al.loadSample('Custom Sounds/taws/rus/altitude_alert.wav')
local rus_glideslope = sasl.al.loadSample('Custom Sounds/taws/rus/glideslope.wav')
local rus_pull_up = sasl.al.loadSample('Custom Sounds/taws/rus/pull.wav')
local rus_sink_rate = sasl.al.loadSample('Custom Sounds/taws/rus/sink.wav')

-- The imported set does not contain these phrases.  Reuse the existing
-- English TAWS recordings instead of loading missing files.
local rus_dont_sink = eng_dont_sink
local rus_terrain = eng_terrain
local rus_terrain_ahead = eng_terrain_ahead
local rus_too_low_flaps = eng_too_low_flaps
local rus_too_low_gear = eng_too_low_gear
local rus_too_low_terrain = eng_too_low_terrain

-- Both voices use the same warning IDs (11..20); their height-callout IDs differ.
-- Keeping sample handles here also lets an OFF switch stop a phrase already playing.
local voice_samples = {
    {
        [1] = eng_alt_50, [2] = eng_alt_200, [3] = eng_alt_500, [4] = eng_alt_1000,
        [11] = eng_check_alt, [12] = eng_dont_sink, [13] = eng_glideslope,
        [14] = eng_pull_up, [15] = eng_sink_rate, [16] = eng_terrain,
        [17] = eng_terrain_ahead, [18] = eng_too_low_flaps,
        [19] = eng_too_low_gear, [20] = eng_too_low_terrain,
    },
    {
        [1] = rus_alt_5, [2] = rus_alt_10, [3] = rus_alt_20, [4] = rus_alt_30,
        [5] = rus_alt_40, [6] = rus_alt_50, [7] = rus_alt_60, [8] = rus_alt_70,
        [9] = rus_alt_100, [10] = rus_alt_200, [11] = rus_check_alt,
        [12] = rus_dont_sink, [13] = rus_glideslope, [14] = rus_pull_up,
        [15] = rus_sink_rate, [16] = rus_terrain, [17] = rus_terrain_ahead,
        [18] = rus_too_low_flaps, [19] = rus_too_low_gear, [20] = rus_too_low_terrain,
        [21] = rus_alt_300, [22] = rus_alt_400, [23] = rus_alt_500,
        [24] = rus_alt_1000, [25] = rus_alt_2500,
    },
}

local rppz_phrases = { [12] = true, [14] = true, [15] = true,
    [16] = true, [17] = true, [20] = true }

local function updateTawsSound()
    local eng_phrase = get(taws_eng_phrase)
    local rus_phrase = get(taws_rus_phrase)
    -- Drop both requests even when muted or in an external view, never queue them
    -- for a later unmute, voice-selection change, or return to the cockpit.
    set(taws_eng_phrase, 0)
    set(taws_rus_phrase, 0)

    local mode = get(taws_mode)
    local message = get(taws_message)
    local test_mode = mode == 5
    local sound_enabled = get(external_view) == 0 and get(srpbz) > 0
        and ((mode > 0 and mode < 4) or test_mode)
        and (get(weather_bus36) > 5 or get(taws_bus36_right) > 5)
    -- The built-in test temporarily raises dis_* as test indications, not mute requests.
    local muted = not test_mode and get(dis_sound) > 0
    local warnings_enabled = get(egpws_alarm_1) == 1
    local flaps_disabled = get(egpws_alarm_2) ~= 1
        or (not test_mode and get(dis_flaps) > 0)
    local gear_disabled = not test_mode and get(dis_gear) > 0
    local terrain_disabled = not test_mode and get(dis_rppz) > 0
    local gs_disabled = not test_mode and get(dis_gs) > 0

    local function allowed(phrase)
        if not sound_enabled or muted then return false end
        if phrase < 11 or phrase > 20 then return true end -- height callout, not warning
        if not warnings_enabled then return false end
        if phrase == 18 and flaps_disabled then return false end
        if phrase == 19 and gear_disabled then return false end
        if phrase == 13 and gs_disabled then return false end
        -- The source cancels these warnings as soon as the approach/signal or gear
        -- condition clears. Reject a late cross-plugin replay and stop its old sample.
        if not test_mode and phrase == 13 and message ~= 13 then return false end
        if not test_mode and phrase == 19 and message ~= 8 then return false end
        if rppz_phrases[phrase] and terrain_disabled then return false end
        return true
    end

    for _, samples in ipairs(voice_samples) do
        for phrase, sample in pairs(samples) do
            if not allowed(phrase) and sasl.al.isSamplePlaying(sample) then
                sasl.al.stopSample(sample)
            end
        end
    end

    local english = get(taws_english) == 1
    local phrase = english and eng_phrase or rus_phrase
    local sample = voice_samples[english and 1 or 2][phrase]
    if sample and allowed(phrase) then
        sasl.al.playSample(sample, false)
    end
end

local windshear_sample = nil
local windshear_sample_loaded = false

local function updateWindshearSound()
    if not windshear_sample_loaded then
        -- Resolve the user's aircraft-level WAV after the aircraft has loaded.
        windshear_sample = sasl.al.loadSample(sasl.getAircraftPath() .. "/sounds/alert/wshr.wav")
        windshear_sample_loaded = true
    end
    if not windshear_sample then return end

    local warning = get(windshear_warning)
    -- 1 is a visual advisory; 2/3/4 are predictive caution/takeoff/approach alerts.
    local predictive = (warning == 2 or warning == 3 or warning == 4)
        and get(windshear_auto) == 1 and get(weather_ready) > 0
        and get(weather_sys) > 0 and get(weather_bus36) > 0
    -- Reactive warning (5) is independent of the radar's predictive AUTO/OFF switch.
    local audible = get(external_view) == 0 and (predictive or warning == 5)
    if audible then
        -- Repeat while the alert is active without restarting the WAV every frame.
        if not sasl.al.isSamplePlaying(windshear_sample) then
            sasl.al.playSample(windshear_sample, true)
        end
    elseif sasl.al.isSamplePlaying(windshear_sample) then
        sasl.al.stopSample(windshear_sample)
    end
end

function update()
    updateWindshearSound()
    updateTawsSound()
end

local function stopAllSounds()
    set(taws_eng_phrase, 0)
    set(taws_rus_phrase, 0)
    for _, samples in ipairs(voice_samples) do
        for _, sample in pairs(samples) do
            if sasl.al.isSamplePlaying(sample) then sasl.al.stopSample(sample) end
        end
    end
    if windshear_sample and sasl.al.isSamplePlaying(windshear_sample) then
        sasl.al.stopSample(windshear_sample)
    end
end

function onAirportLoaded(flightIndex)
    -- A new flight/reposition must not retain a phrase from the previous approach.
    stopAllSounds()
end

function onModuleShutdown(isError)
    stopAllSounds()
end
