-- nvu_panel.lua
-- Remaining cockpit services from the former NVU panel.
-- Keep the BDK needle, shared switch sounds, switch initialization and lamp test.
-- Retired NVU counters, entry buttons and coordinate/correction indications are gone.

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
    -- This switch still has a cockpit manipulator; aircraft_init sets its start state.
    { "nvu_power_on", "tu154/custom/switchers/console/nvu_power_on", globalPropertyi },
    -- Shared sound trigger used by UNS, radio, Kontur, EGPWS and other xTlua systems.
    { "switch_sound_trigger", "tu154/custom/switchers/console/nvu_corr_on", globalPropertyi },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    { "eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalProperty },
    { "eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalProperty },
    { "eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalProperty },

    -- BDK needle still animated by cockpit_1_RUS.obj.
    { "compas_big_needle", "tu154/custom/gauges/misc/compas_big_needle", globalPropertyf },
    { "compas_knob", "tu154/custom/gauges/misc/compas_knob", globalPropertyf },

    -- These four annunciators reach the cockpit via T154.zsmooth_lights.
    { "test_lamps", "tu154/custom/buttons/lamp_test_front", globalPropertyi },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "nvu_fail_lit", "tu154/custom/lights/nvu_fail", globalPropertyf },
    { "nvu_vor_automat", "tu154/custom/lights/nvu_vor_automat", globalPropertyf },
    { "correct_on_lit", "tu154/custom/lights/correct_on", globalPropertyf },
    { "change_ch_o", "tu154/custom/lights/change_ch_o", globalPropertyf },
})

local switcher_sound = sasl.al.loadSample('Custom Sounds/metal_switch.wav')
local switch_state = 0
local sound_trigger = 0
local start_timer = 0
local initialized = false

function update()
    -- Compare separately so simultaneous opposite changes do not cancel a click.
    local power = get(nvu_power_on)
    local trigger = get(switch_sound_trigger)
    if power ~= switch_state or trigger ~= sound_trigger then
        sasl.al.playSample(switcher_sound, false)
    end
    switch_state = power
    sound_trigger = trigger

    set(compas_big_needle, get(compas_knob) * 36)

    -- Retired NVU functions cannot assert operational indications.
    -- Preserve the original front-panel lamp-test voltage scaling.
    local test = get(test_lamps) * math.max((get(bus27_volt_right) - 10) / 18.5, 0)
    set(nvu_fail_lit, test)
    set(nvu_vor_automat, test)
    set(correct_on_lit, test)
    set(change_ch_o, test)

    if not initialized then
        start_timer = start_timer + get(frame_time)
        if start_timer > 0.3 then
            if isColdAndDarkStart() and get(eng1_N1) < 5 and get(eng2_N1) < 5 and get(eng3_N1) < 5 then
                set(nvu_power_on, 0)
            end
            initialized = true
        end
    end
end
