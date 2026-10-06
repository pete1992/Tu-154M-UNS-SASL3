-- fire_panel.lua
-- Fire system panel (performance-optimierte Fassung).
--
-- Sounds, Startreset, Buzzer-Kappe, Blinktakte und Lampentest unverändert.
-- Lampenformeln in gleicher Multiplikationsreihenfolge wie im Original.

---------------------------------------------------------------------------
-- Lokalisierte Globals
---------------------------------------------------------------------------
local get, set = get, set
local max = math.max
local playSample = sasl.al.playSample

-- true  = Lampen nur bei Wertänderung schreiben
-- false = jedes Frame schreiben
local USE_WRITE_CACHE = true

---------------------------------------------------------------------------
-- Properties: Handles in lokaler Tabelle P
---------------------------------------------------------------------------
local P = {}
local env = (getfenv and getfenv(1)) or _ENV or _G

local function defineProps(defs)
    for i = 1, #defs do
        local d = defs[i]
        local name = d[1]
        local handle = d[3](d[2])
        defineProperty(name, handle)
        -- Von außen überschriebene Property bevorzugen
        P[name] = env[name] or handle
    end
end

defineProps({
    -- Controls
    { "lamp_test", "tu154/custom/buttons/lamp_test_fire_panel", globalPropertyi },
    { "lamp_test_2", "tu154/custom/buttons/lamp_test_engines", globalPropertyi },
    { "smoke_test", "tu154/custom/buttons/eng/smoke_test", globalPropertyi },
    { "ext_test", "tu154/custom/buttons/eng/ext_test", globalPropertyi },
    { "lamp_test_front", "tu154/custom/buttons/lamp_test_front", globalPropertyi },
    { "fire_ext_1", "tu154/custom/buttons/eng/fire_ext_1", globalPropertyi },
    { "fire_ext_2", "tu154/custom/buttons/eng/fire_ext_2", globalPropertyi },
    { "fire_ext_3", "tu154/custom/buttons/eng/fire_ext_3", globalPropertyi },
    { "cold_eng_1", "tu154/custom/buttons/eng/cold_eng_1", globalPropertyi },
    { "cold_eng_2", "tu154/custom/buttons/eng/cold_eng_2", globalPropertyi },
    { "cold_eng_3", "tu154/custom/buttons/eng/cold_eng_3", globalPropertyi },
    { "cold_apu", "tu154/custom/buttons/eng/cold_apu", globalPropertyi },
    { "neutral_gas", "tu154/custom/buttons/eng/neutral_gas", globalPropertyi },
    { "fire_sensor_sel", "tu154/custom/switchers/eng/fire_sensor_sel", globalPropertyi },
    { "fire_place_sel", "tu154/custom/switchers/eng/fire_place_sel", globalPropertyi },
    { "fire_main_switch", "tu154/custom/switchers/eng/fire_main_switch", globalPropertyi },
    { "fire_buzzer", "tu154/custom/switchers/eng/fire_buzzer", globalPropertyi },
    { "fire_buzzer_cap", "tu154/custom/switchers/eng/fire_buzzer_cap", globalPropertyi },
    -- Lamps
    { "smoke_1", "tu154/custom/lights/fire/smoke_1", globalPropertyf },
    { "smoke_2", "tu154/custom/lights/fire/smoke_2", globalPropertyf },
    { "smoke_zone2_left", "tu154/custom/lights/fire/smoke_zone2_left", globalPropertyf },
    { "smoke_zone2_right", "tu154/custom/lights/fire/smoke_zone2_right", globalPropertyf },
    { "smoke_zone3", "tu154/custom/lights/fire/smoke_zone3", globalPropertyf },
    { "smoke_zone4", "tu154/custom/lights/fire/smoke_zone4", globalPropertyf },
    { "smoke_zone5_left", "tu154/custom/lights/fire/smoke_zone5_left", globalPropertyf },
    { "smoke_zone5_right", "tu154/custom/lights/fire/smoke_zone5_right", globalPropertyf },
    { "smoke_zone6", "tu154/custom/lights/fire/smoke_zone6", globalPropertyf },
    { "fire_eng_1", "tu154/custom/lights/fire/fire_eng_1", globalPropertyf },
    { "fire_eng_2", "tu154/custom/lights/fire/fire_eng_2", globalPropertyf },
    { "fire_eng_3", "tu154/custom/lights/fire/fire_eng_3", globalPropertyf },
    { "overheat_eng_1", "tu154/custom/lights/fire/overheat_eng_1", globalPropertyf },
    { "overheat_eng_2", "tu154/custom/lights/fire/overheat_eng_2", globalPropertyf },
    { "overheat_eng_3", "tu154/custom/lights/fire/overheat_eng_3", globalPropertyf },
    { "fuel_off_eng_1", "tu154/custom/lights/fire/fuel_off_eng_1", globalPropertyf },
    { "fuel_off_eng_2", "tu154/custom/lights/fire/fuel_off_eng_2", globalPropertyf },
    { "fuel_off_eng_3", "tu154/custom/lights/fire/fuel_off_eng_3", globalPropertyf },
    { "check_overheat", "tu154/custom/lights/fire/check_overheat", globalPropertyf },
    { "fire_apu", "tu154/custom/lights/fire/fire_apu", globalPropertyf },
    { "turn_on_spz", "tu154/custom/lights/fire/turn_on_spz", globalPropertyf },
    { "button_fire_eng_1", "tu154/custom/lights/button/fire_eng_1", globalPropertyf },
    { "button_fire_eng_2", "tu154/custom/lights/button/fire_eng_2", globalPropertyf },
    { "button_fire_eng_3", "tu154/custom/lights/button/fire_eng_3", globalPropertyf },
    { "button_fire_apu", "tu154/custom/lights/button/fire_apu", globalPropertyf },
    { "button_fire_ng", "tu154/custom/lights/button/fire_ng", globalPropertyf },
    { "button_fire_turn_3", "tu154/custom/lights/button/fire_turn_3", globalPropertyf },
    { "button_fire_turn_2", "tu154/custom/lights/button/fire_turn_2", globalPropertyf },
    { "button_fire_turn_1", "tu154/custom/lights/button/fire_turn_1", globalPropertyf },
    { "throttle_1_fire", "tu154/custom/lights/small/throttle_1_fire", globalPropertyf },
    { "throttle_2_fire", "tu154/custom/lights/small/throttle_2_fire", globalPropertyf },
    { "throttle_3_fire", "tu154/custom/lights/small/throttle_3_fire", globalPropertyf },
    { "fire_lamp", "tu154/custom/lights/fire", globalPropertyf },
    { "eng1_dangerous_vibro", "tu154/custom/lights/engines/eng1_dangerous_vibro", globalPropertyf },
    { "eng2_dangerous_vibro", "tu154/custom/lights/engines/eng2_dangerous_vibro", globalPropertyf },
    { "eng3_dangerous_vibro", "tu154/custom/lights/engines/eng3_dangerous_vibro", globalPropertyf },
    { "day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf }, -- Tag/Nacht-Helligkeit
    -- Power
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    -- Engines
    { "eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalProperty },
    { "eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalProperty },
    { "eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalProperty },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    -- Other sources
    { "ext_used_1", "tu154/custom/fire/ext_used_1", globalPropertyi },
    { "ext_used_2", "tu154/custom/fire/ext_used_2", globalPropertyi },
    { "ext_used_3", "tu154/custom/fire/ext_used_3", globalPropertyi },
    { "ng_used", "tu154/custom/fire/ng_used", globalPropertyi },
    { "valve_open_1", "tu154/custom/fire/valve_open_1", globalPropertyi },
    { "valve_open_2", "tu154/custom/fire/valve_open_2", globalPropertyi },
    { "valve_open_3", "tu154/custom/fire/valve_open_3", globalPropertyi },
    { "valve_open_4", "tu154/custom/fire/valve_open_4", globalPropertyi },
    -- Laut Lampenlogik: >0 = Überhitzung, 2 = Feuer
    { "engine_fire_state_1", "tu154/custom/fire/engine_fire_state_1", globalPropertyi },
    { "engine_fire_state_2", "tu154/custom/fire/engine_fire_state_2", globalPropertyi },
    { "engine_fire_state_3", "tu154/custom/fire/engine_fire_state_3", globalPropertyi },
    { "engine_fire_state_4", "tu154/custom/fire/engine_fire_state_4", globalPropertyi },
    { "fire_vlv_open_1", "tu154/custom/fuel/fire_vlv_open_1", globalPropertyf },
    { "fire_vlv_open_2", "tu154/custom/fuel/fire_vlv_open_2", globalPropertyf },
    { "fire_vlv_open_3", "tu154/custom/fuel/fire_vlv_open_3", globalPropertyf },
    { "fire_detected", "tu154/custom/fire/fire_detected", globalPropertyi },
    { "fire_siren", "tu154/custom/fire/fire_siren", globalPropertyi },
})

---------------------------------------------------------------------------
-- Lampenlisten
---------------------------------------------------------------------------
local function handles(names)
    local t = {}
    for i = 1, #names do t[i] = P[names[i]] end
    return t
end

-- Alle 33 Lampen (ohne Strom alle 0)
local ALL_LAMPS = handles({
    "smoke_1", "smoke_2", "smoke_zone2_left", "smoke_zone2_right",
    "smoke_zone3", "smoke_zone4", "smoke_zone5_left", "smoke_zone5_right",
    "smoke_zone6",
    "fire_eng_1", "fire_eng_2", "fire_eng_3",
    "overheat_eng_1", "overheat_eng_2", "overheat_eng_3",
    "fuel_off_eng_1", "fuel_off_eng_2", "fuel_off_eng_3",
    "throttle_1_fire", "throttle_2_fire", "throttle_3_fire",
    "check_overheat", "fire_apu", "turn_on_spz",
    "button_fire_eng_1", "button_fire_eng_2", "button_fire_eng_3",
    "button_fire_apu", "button_fire_ng",
    "button_fire_turn_1", "button_fire_turn_2", "button_fire_turn_3",
    "fire_lamp",
})

-- Lampen mit Faktor power_sw (bei SPZ aus = Lampentest-Wert)
local POWER_LAMPS = handles({
    "fire_eng_1", "fire_eng_2", "fire_eng_3",
    "overheat_eng_1", "overheat_eng_2", "overheat_eng_3",
    "fuel_off_eng_1", "fuel_off_eng_2", "fuel_off_eng_3",
    "fire_apu",
    "button_fire_eng_1", "button_fire_eng_2", "button_fire_eng_3",
    "button_fire_apu", "button_fire_ng",
    "button_fire_turn_1", "button_fire_turn_2", "button_fire_turn_3",
})

---------------------------------------------------------------------------
-- Sounds und Zustand
---------------------------------------------------------------------------
local rotary_sound = sasl.al.loadSample('Custom Sounds/plastic_switch.wav')
local switcher_sound = sasl.al.loadSample('Custom Sounds/metal_switch.wav')
local cap_sound = sasl.al.loadSample('Custom Sounds/cap.wav')
local button_sound = sasl.al.loadSample('Custom Sounds/plastic_btn.wav')

local passed = get(P.frame_time)
local notLoaded = true
local sim_start_timer = 0

---------------------------------------------------------------------------
-- Schreib-Cache für Lampen
---------------------------------------------------------------------------
local put = set
if USE_WRITE_CACHE then
    local last = {}
    put = function(h, v)
        if last[h] ~= v then
            last[h] = v
            set(h, v)
        end
    end
end

---------------------------------------------------------------------------
-- Startreset (einmalig)
---------------------------------------------------------------------------
local function reset_switchers()
    if isColdAndDarkStart() and get(P.eng1_N1) < 5
        and get(P.eng2_N1) < 5 and get(P.eng3_N1) < 5 then
        set(P.fire_main_switch, 0)
    end
    notLoaded = false
end

---------------------------------------------------------------------------
-- Bediengeräusche (Summen-Logik wie im Original)
---------------------------------------------------------------------------
local lamp_test_last = get(P.lamp_test)
local smoke_test_last = get(P.smoke_test)
local ext_test_last = get(P.ext_test)
local fire_ext_1_last = get(P.fire_ext_1)
local fire_ext_2_last = get(P.fire_ext_2)
local fire_ext_3_last = get(P.fire_ext_3)
local cold_eng_1_last = get(P.cold_eng_1)
local cold_eng_2_last = get(P.cold_eng_2)
local cold_eng_3_last = get(P.cold_eng_3)
local cold_apu_last = get(P.cold_apu)
local neutral_gas_last = get(P.neutral_gas)
local fire_sensor_sel_last = get(P.fire_sensor_sel)
local fire_place_sel_last = get(P.fire_place_sel)
local fire_main_switch_last = get(P.fire_main_switch)
local fire_buzzer_last = get(P.fire_buzzer)
local fire_buzzer_cap_last = get(P.fire_buzzer_cap)

local function swichers_check(lamp_test_sw, smoke_test_sw, ext_test_sw,
                              fire_main_switch_sw)
    local fire_ext_1_sw = get(P.fire_ext_1)
    local fire_ext_2_sw = get(P.fire_ext_2)
    local fire_ext_3_sw = get(P.fire_ext_3)
    local cold_eng_1_sw = get(P.cold_eng_1)
    local cold_eng_2_sw = get(P.cold_eng_2)
    local cold_eng_3_sw = get(P.cold_eng_3)
    local cold_apu_sw = get(P.cold_apu)
    local neutral_gas_sw = get(P.neutral_gas)
    local fire_sensor_sel_sw = get(P.fire_sensor_sel)
    local fire_place_sel_sw = get(P.fire_place_sel)
    local fire_buzzer_sw = get(P.fire_buzzer)
    local fire_buzzer_cap_sw = get(P.fire_buzzer_cap)

    local changes_but = lamp_test_sw + smoke_test_sw + ext_test_sw
        + fire_ext_1_sw + fire_ext_2_sw + fire_ext_3_sw
        + cold_eng_1_sw + cold_eng_2_sw + cold_eng_3_sw
        + cold_apu_sw + neutral_gas_sw
        - lamp_test_last - smoke_test_last - ext_test_last
        - fire_ext_1_last - fire_ext_2_last - fire_ext_3_last
        - cold_eng_1_last - cold_eng_2_last - cold_eng_3_last
        - cold_apu_last - neutral_gas_last
    if changes_but ~= 0 then playSample(button_sound, false) end

    local changes_rot = fire_sensor_sel_sw + fire_place_sel_sw
        - fire_sensor_sel_last - fire_place_sel_last
    if changes_rot ~= 0 then playSample(rotary_sound, false) end

    local changes_sw = fire_main_switch_sw + fire_buzzer_sw
        - fire_main_switch_last - fire_buzzer_last
    if changes_sw ~= 0 then playSample(switcher_sound, false) end

    if fire_buzzer_cap_sw ~= fire_buzzer_cap_last then
        playSample(cap_sound, false)
    end

    -- Geschlossene Kappe erzwingt Buzzer an (nur schreiben, wenn nötig)
    if fire_buzzer_cap_sw == 0 and fire_buzzer_sw ~= 1 then
        set(P.fire_buzzer, 1)
    end

    lamp_test_last = lamp_test_sw
    smoke_test_last = smoke_test_sw
    ext_test_last = ext_test_sw
    fire_ext_1_last = fire_ext_1_sw
    fire_ext_2_last = fire_ext_2_sw
    fire_ext_3_last = fire_ext_3_sw
    cold_eng_1_last = cold_eng_1_sw
    cold_eng_2_last = cold_eng_2_sw
    cold_eng_3_last = cold_eng_3_sw
    cold_apu_last = cold_apu_sw
    neutral_gas_last = neutral_gas_sw
    fire_sensor_sel_last = fire_sensor_sel_sw
    fire_place_sel_last = fire_place_sel_sw
    fire_main_switch_last = fire_main_switch_sw
    fire_buzzer_last = fire_buzzer_sw
    fire_buzzer_cap_last = fire_buzzer_cap_sw
end

---------------------------------------------------------------------------
-- Blink-Logik (unabhängig vom Strom, läuft jedes Frame)
---------------------------------------------------------------------------
local sheck_smoke_lit = false
local check_smoke_counter = 0
local fire_lit = false
local fire_counter = 0

local function blink(fire_det)
    if fire_det == 1 and get(P.fire_siren) == 0 then
        sheck_smoke_lit = true
    elseif fire_det == 1 then
        check_smoke_counter = check_smoke_counter + passed
        if check_smoke_counter > 0.4 then
            check_smoke_counter = 0
            sheck_smoke_lit = not sheck_smoke_lit
        end
    else
        sheck_smoke_lit = false
    end

    if fire_det == 1 then
        fire_counter = fire_counter + passed
        if fire_counter > 0.4 then
            fire_counter = 0
            fire_lit = not fire_lit
        end
    else
        fire_lit = false
    end
end

---------------------------------------------------------------------------
-- Lampen
---------------------------------------------------------------------------
-- Faktoren pro Frame für pl()
local L_p, L_lb, L_dn, L_tb = 0, 0, 0, 0

-- Gleiche Multiplikationsreihenfolge wie im Original
local function pl(x)
    return max(x * L_p * L_lb * L_dn, L_tb)
end

local function lamps(lamp_test_sw, smoke_test_sw, ext_test_sw, main_sw)
    local bus_r = get(P.bus27_volt_right)
    local lb = max((max(get(P.bus27_volt_left), bus_r) - 10) / 18.5, 0)

    blink(get(P.fire_detected))

    -- Ohne Strom: alle Formeln ergeben 0 (auch Lampentest)
    if lb == 0 then
        for i = 1, #ALL_LAMPS do put(ALL_LAMPS[i], 0) end
        return
    end

    local r_fac = max((bus_r - 10) / 18.5, 0)
    local tb = lamp_test_sw * r_fac
    local tb_front = get(P.lamp_test_front) * r_fac
    local dn = 1 - get(P.day_night_set) * 0.25

    L_p, L_lb, L_dn, L_tb = main_sw, lb, dn, tb

    -- Rauchmelder (Testanzeige)
    local smoke_v = pl(smoke_test_sw)
    put(P.smoke_1, smoke_v)
    put(P.smoke_2, smoke_v)
    put(P.smoke_zone2_left, smoke_v)
    put(P.smoke_zone2_right, smoke_v)
    put(P.smoke_zone3, smoke_v)
    put(P.smoke_zone4, smoke_v)
    put(P.smoke_zone5_right, smoke_v)
    put(P.smoke_zone6, smoke_v)
    put(P.smoke_zone5_left,
        max(smoke_test_sw * main_sw * main_sw * lb * dn, tb))

    local f1 = get(P.engine_fire_state_1)
    local f2 = get(P.engine_fire_state_2)
    local f3 = get(P.engine_fire_state_3)

    -- Schubhebel-Lampen (ohne SPZ-Schalter, ohne Tag/Nacht)
    put(P.throttle_1_fire, max(((f1 > 0
        or get(P.eng1_dangerous_vibro) > 0) and 1 or 0) * lb, tb))
    put(P.throttle_2_fire, max(((f2 > 0
        or get(P.eng2_dangerous_vibro) > 0) and 1 or 0) * lb, tb))
    put(P.throttle_3_fire, max(((f3 > 0
        or get(P.eng3_dangerous_vibro) > 0) and 1 or 0) * lb, tb))

    -- Lampen ohne SPZ-Schalter-Faktor
    put(P.check_overheat, max((sheck_smoke_lit and 1 or 0) * lb * dn, tb))
    put(P.fire_lamp, max((fire_lit and 1 or 0) * lb * dn, tb_front))
    put(P.turn_on_spz, max((1 - main_sw) * lb * dn, tb))

    -- SPZ aus: alle Lampen mit power_sw zeigen nur den Lampentest
    if main_sw == 0 then
        for i = 1, #POWER_LAMPS do put(POWER_LAMPS[i], tb) end
        return
    end

    put(P.fire_eng_1, pl(f1 == 2 and 1 or 0))
    put(P.fire_eng_2, pl(f2 == 2 and 1 or 0))
    put(P.fire_eng_3, pl(f3 == 2 and 1 or 0))

    put(P.overheat_eng_1, pl(f1 > 0 and 1 or 0))
    put(P.overheat_eng_2, pl(f2 > 0 and 1 or 0))
    put(P.overheat_eng_3, pl(f3 > 0 and 1 or 0))

    put(P.fuel_off_eng_1, pl(get(P.fire_vlv_open_1) < 0.5 and 1 or 0))
    put(P.fuel_off_eng_2, pl(get(P.fire_vlv_open_2) < 0.5 and 1 or 0))
    put(P.fuel_off_eng_3, pl(get(P.fire_vlv_open_3) < 0.5 and 1 or 0))

    put(P.fire_apu, pl(get(P.engine_fire_state_4) > 0 and 1 or 0))

    put(P.button_fire_eng_1, pl(get(P.valve_open_1)))
    put(P.button_fire_eng_2, pl(get(P.valve_open_2)))
    put(P.button_fire_eng_3, pl(get(P.valve_open_3)))
    put(P.button_fire_apu, pl(get(P.valve_open_4)))
    put(P.button_fire_ng, pl(get(P.ng_used)))

    put(P.button_fire_turn_3, pl(max(get(P.ext_used_3), ext_test_sw)))
    put(P.button_fire_turn_2, pl(max(get(P.ext_used_2), ext_test_sw)))
    put(P.button_fire_turn_1, pl(max(get(P.ext_used_1), ext_test_sw)))
end

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------
function update()
    passed = get(P.frame_time)

    sim_start_timer = sim_start_timer + passed
    local started = sim_start_timer > 0.3
    if started and notLoaded then reset_switchers() end

    -- Gemeinsame Werte nach einem möglichen Reset lesen
    local lamp_test_sw = get(P.lamp_test)
    local smoke_test_sw = get(P.smoke_test)
    local ext_test_sw = get(P.ext_test)
    local main_sw = get(P.fire_main_switch)

    if started then
        swichers_check(lamp_test_sw, smoke_test_sw, ext_test_sw, main_sw)
    end

    lamps(lamp_test_sw, smoke_test_sw, ext_test_sw, main_sw)
end
