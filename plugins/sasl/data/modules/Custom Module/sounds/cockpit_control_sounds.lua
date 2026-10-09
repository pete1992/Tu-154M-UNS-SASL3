-- cockpit_control_sounds.lua
-- Plays mechanical sounds when monitored cockpit controls change.

-- Observe inputs only; control ownership, interlocks and system logic stay with
-- their existing components. Existing TCAS/WX power and button proxies stay there.

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    -- KATET selectors.
    { "katet_mode", "tu154/custom/katet/mode", globalPropertyi },
    { "katet_nav_mode", "tu154/custom/katet/nav_mode", globalPropertyi },
    { "katet_night_day", "tu154/custom/katet/night_day", globalPropertyi },
    { "katet_dme_rsbn", "tu154/custom/katet/dme_rsbn", globalPropertyi },

    -- TCAS digit knobs move only on accepted cockpit rotation commands.
    { "tcas_l1", "tu154/custom/tcas2000/l1", globalPropertyf },
    { "tcas_l2", "tu154/custom/tcas2000/l2", globalPropertyf },
    { "tcas_r1", "tu154/custom/tcas2000/r1", globalPropertyf },
    { "tcas_r2", "tu154/custom/tcas2000/r2", globalPropertyf },
    { "tcas_level", "tu154/custom/tcas/level_mode", globalPropertyi },

    -- WX controls; radar power already uses the shared switch-sound trigger.
    { "wx_mode", "tu154/custom/kontur/weather_mode", globalPropertyf },
    { "wx_tilt", "tu154/custom/wx2000_tilt", globalPropertyf },
    { "wx_gain", "tu154/custom/wx2000_gain", globalPropertyf },
    { "wx_windshear", "tu154/custom/wx2000_windshear", globalPropertyf },

    -- Engineer emergency trim and generator controls.
    { "trim_cutoff_1", "tu154/custom/switchers/eng/hydro_trimm_rud_1", globalPropertyi },
    { "trim_cutoff_2", "tu154/custom/switchers/eng/hydro_trimm_rud_2", globalPropertyi },
    { "trim_cap_1", "tu154/custom/switchers/eng/hydro_trimm_rud_1_cap", globalPropertyi },
    { "trim_cap_2", "tu154/custom/switchers/eng/hydro_trimm_rud_2_cap", globalPropertyi },
    { "generator_cutoff_1", "tu154/custom/switchers/eng/emerg_gen_on_1", globalPropertyi },
    { "generator_cutoff_2", "tu154/custom/switchers/eng/emerg_gen_on_2", globalPropertyi },
    { "generator_cutoff_3", "tu154/custom/switchers/eng/emerg_gen_on_3", globalPropertyi },
    { "generator_cap_1", "tu154/custom/switchers/eng/emerg_gen_on_1_cap", globalPropertyi },
    { "generator_cap_2", "tu154/custom/switchers/eng/emerg_gen_on_2_cap", globalPropertyi },
    { "generator_cap_3", "tu154/custom/switchers/eng/emerg_gen_on_3_cap", globalPropertyi },

    -- PPN-13 raw inputs; smoothed animation outputs must not retrigger clicks.
    { "ppn_ack", "tu154/custom/manipulators/buttons/absu/ppn13_ack", globalPropertyi },
    { "ppn_flt", "tu154/custom/manipulators/buttons/absu/ppn13_flt", globalPropertyi },
    { "ppn_lookup", "tu154/custom/manipulators/buttons/absu/ppn13_lookup", globalPropertyi },
    { "ppn_poweroff", "tu154/custom/manipulators/buttons/absu/ppn13_poweroff", globalPropertyi },
    { "ppn_snp", "tu154/custom/manipulators/buttons/absu/ppn13_snp", globalPropertyi },
    { "ppn_t1", "tu154/custom/manipulators/buttons/absu/ppn13_t1", globalPropertyi },
    { "ppn_t2", "tu154/custom/manipulators/buttons/absu/ppn13_t2", globalPropertyi },
    { "ppn_t3", "tu154/custom/manipulators/buttons/absu/ppn13_t3", globalPropertyi },
    { "ppn_test_absu", "tu154/custom/manipulators/buttons/absu/ppn13_test_absu", globalPropertyi },
    { "ppn_test_svk", "tu154/custom/manipulators/buttons/absu/ppn13_test_svk", globalPropertyi },
    { "ppn_lid", "tu154/custom/manipulators/buttons/absu/ppn13_lid", globalPropertyi },

    -- New guards on existing, already sounded switches.
    { "szt_test_cap", "tu154/custom/switchers/eng/szt_test_cap", globalPropertyf },
    { "fuel_pump_cap_1", "tu154/custom/switchers/fuel/pump_tank1_1_cap", globalPropertyf },
    { "fuel_pump_cap_2", "tu154/custom/switchers/fuel/pump_tank1_2_cap", globalPropertyf },
    { "fuel_pump_cap_3", "tu154/custom/switchers/fuel/pump_tank1_3_cap", globalPropertyf },
    { "fuel_pump_cap_4", "tu154/custom/switchers/fuel/pump_tank1_4_cap", globalPropertyf },
    { "vbe_select_cap", "tu154/custom/switchers/vbe_select_cap", globalPropertyf },

    -- Match the existing ARM-406 cockpit audio preferences.
    { "external_view", "sim/graphics/view/view_is_external", globalPropertyi },
    { "paused", "sim/time/paused", globalPropertyi },
    { "sound_on", "sim/operation/sound/sound_on", globalPropertyi },
    { "warning_volume", "sim/operation/sound/warning_volume_ratio", globalPropertyf },
})

local samples = {
    rotary = sasl.al.loadSample("Custom Sounds/rot_click.wav"),
    switch = sasl.al.loadSample("Custom Sounds/metal_switch.wav"),
    button = sasl.al.loadSample("Custom Sounds/plastic_btn.wav"),
    cap = sasl.al.loadSample("Custom Sounds/cap.wav"),
}

-- Optional third field is the OBJ control's detent/wheel step. Comparing each
-- control separately catches simultaneous opposite changes and rotary wrapping.
local controls = {
    { katet_mode, "rotary" },
    { katet_nav_mode, "switch" },
    { katet_night_day, "switch" },
    { katet_dme_rsbn, "switch" },
    { tcas_l1, "rotary" },
    { tcas_l2, "rotary" },
    { tcas_r1, "rotary" },
    { tcas_r2, "rotary" },
    { tcas_level, "rotary" },
    { wx_mode, "rotary" },
    { wx_tilt, "rotary", 0.5 },
    { wx_gain, "rotary", 0.1 },
    { wx_windshear, "switch" },
    { trim_cutoff_1, "switch" },
    { trim_cutoff_2, "switch" },
    { trim_cap_1, "cap" },
    { trim_cap_2, "cap" },
    { generator_cutoff_1, "switch" },
    { generator_cutoff_2, "switch" },
    { generator_cutoff_3, "switch" },
    { generator_cap_1, "cap" },
    { generator_cap_2, "cap" },
    { generator_cap_3, "cap" },
    { ppn_ack, "button" },
    { ppn_flt, "button" },
    { ppn_lookup, "button" },
    { ppn_poweroff, "button" },
    { ppn_snp, "button" },
    { ppn_t1, "button" },
    { ppn_t2, "button" },
    { ppn_t3, "button" },
    { ppn_test_absu, "switch" },
    { ppn_test_svk, "switch" },
    { ppn_lid, "cap" },
    { szt_test_cap, "cap" },
    { fuel_pump_cap_1, "cap" },
    { fuel_pump_cap_2, "cap" },
    { fuel_pump_cap_3, "cap" },
    { fuel_pump_cap_4, "cap" },
    { vbe_select_cap, "cap" },
}

local states = {}
local initialized = false

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) ~= math.huge
end

local function controlValue(control)
    local value = get(control[1])
    if not finite(value) then
        return nil
    end
    if control[3] then
        return math.floor(value / control[3] + 0.5)
    end
    return value
end

local function stopSamples()
    for _, sample in pairs(samples) do
        if sample and sasl.al.isSamplePlaying(sample) then
            sasl.al.stopSample(sample)
        end
    end
end

function update()
    local changed = {}
    for index, control in ipairs(controls) do
        local value = controlValue(control)
        if initialized and value ~= nil and states[index] ~= nil and value ~= states[index] then
            changed[control[2]] = true
        end
        -- Always consume transitions, including while cockpit audio is muted.
        states[index] = value
    end
    -- The first snapshot follows aircraft_init, avoiding hot/cold preset clicks.
    initialized = true

    local volume = get(warning_volume)
    local gain = finite(volume) and math.max(0, math.min(1, volume)) * 600 or 0
    if get(paused) ~= 0 or get(external_view) ~= 0 or get(sound_on) ~= 1 or gain == 0 then
        stopSamples()
        return
    end

    -- Restart a sample at most once per frame, even if several controls move.
    for kind in pairs(changed) do
        local sample = samples[kind]
        if sample then
            sasl.al.setSampleGain(sample, gain)
            sasl.al.playSample(sample, false)
        end
    end
end

function onAirportLoaded()
    -- The existing flight preset is applied before the next sounds update.
    initialized = false
end

function onModuleShutdown()
    stopSamples()
end
