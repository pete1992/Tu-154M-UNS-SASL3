-- Anti-ice system logic.

--[[
- 70 aktive Property-Bindungen in eine lokale defineProps()-Struktur überführt.
- Property-Namen, Dataref-Pfade, Konstruktoren und Reihenfolge 1:1 beibehalten.
- Alle russischen Kommentare entfernt bzw. durch englische ersetzt.
- update() vollständig neu formatiert und logisch gegliedert.

- Wiederholte Reads reduziert:
	IAS
	Engine-Anti-Ice-Schalter
	Engine-Icing-Failures
	rio_fail
	bus115_2_volt
	Außentemperaturberechnung
	math.max(out_term * 1, 0) wird nur noch einmal pro Frame berechnet.
	math.max(0, wing_tube) wird für beide Tragflächen nur einmal berechnet.
	power115_2 wird jetzt tatsächlich für die Slat-Logik verwendet, statt das Dataref erneut abzufragen.
	Window-Ice-Zustände verwenden jetzt clamp(..., 0, 1).
	Die drei bislang ungenutzten power_CC_115_*-Variablen wurden nicht entfernt.
	hascontrol_1 bleibt ebenfalls erhalten.
	Die deaktivierten alten hot_tube_t-/eng_airvalve_*-Bindungen bleiben als deaktivierte Referenzen vorhanden.
--]]

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Controls
    { "soi21_on", "tu154/custom/switchers/eng/soi21_on", globalPropertyi },
    { "soi21_test", "tu154/custom/buttons/eng/soi21_test", globalPropertyi },
    { "antiice_slats", "tu154/custom/switchers/eng/antiice_slats", globalPropertyi },
    { "antiice_eng_1", "tu154/custom/switchers/eng/antiice_eng_1", globalPropertyi },
    { "antiice_eng_2", "tu154/custom/switchers/eng/antiice_eng_2", globalPropertyi },
    { "antiice_eng_3", "tu154/custom/switchers/eng/antiice_eng_3", globalPropertyi },
    { "antiice_wing", "tu154/custom/switchers/eng/antiice_wing", globalPropertyi },
    { "window_heat_1", "tu154/custom/switchers/ovhd/window_heat_1", globalPropertyi },
    { "window_heat_2", "tu154/custom/switchers/ovhd/window_heat_2", globalPropertyi },
    { "window_heat_3", "tu154/custom/switchers/ovhd/window_heat_3", globalPropertyi },
    { "pitot_heat_1", "tu154/custom/switchers/ovhd/pitot_heat_1", globalPropertyi },
    { "pitot_heat_2", "tu154/custom/switchers/ovhd/pitot_heat_2", globalPropertyi },
    { "pitot_heat_3", "tu154/custom/switchers/ovhd/pitot_heat_3", globalPropertyi },
    -- Power supply
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "bus115_2_volt", "tu154/custom/elec/bus115_2_volt", globalPropertyf },
    { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },
    -- Icing sources and environmental data
    { "window_ice", "sim/flightmodel/failures/window_ice", globalPropertyf },
    { "rpm_high_1", "tu154/custom/gauges/engine/rpm_high_1", globalPropertyf },
    { "rpm_high_2", "tu154/custom/gauges/engine/rpm_high_2", globalPropertyf },
    { "rpm_high_3", "tu154/custom/gauges/engine/rpm_high_3", globalPropertyf },
    { "termo", "sim/weather/temperature_ambient_c", globalPropertyf },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    { "IAS", "sim/flightmodel/position/indicated_airspeed", globalPropertyf },
    { "deflection_mtr_2", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalPropertyf },
    { "deflection_mtr_3", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", globalPropertyf },
    -- Failures
    { "ppd_3_heat_fail", "tu154/custom/antiice/ppd_3_heat_fail", globalPropertyi },
    { "rel_ice_inlet_heat1", "sim/operation/failures/rel_ice_inlet_heat", globalPropertyi },
    { "rel_ice_inlet_heat2", "sim/operation/failures/rel_ice_inlet_heat2", globalPropertyi },
    { "rel_ice_inlet_heat3", "sim/operation/failures/rel_ice_inlet_heat3", globalPropertyi },
    { "rel_ice_pitot_heat1", "sim/operation/failures/rel_ice_pitot_heat1", globalPropertyi },
    { "rel_ice_pitot_heat2", "sim/operation/failures/rel_ice_pitot_heat2", globalPropertyi },
    { "rel_ice_surf_heat", "sim/operation/failures/rel_ice_surf_heat", globalPropertyi },
    { "rel_ice_surf_heat2", "sim/operation/failures/rel_ice_surf_heat2", globalPropertyi },
    { "rio_fail", "tu154/custom/failures/rio_fail", globalPropertyi },
    { "window_heat_fail_1", "tu154/custom/failures/window_heat_fail_1", globalPropertyi },
    { "window_heat_fail_2", "tu154/custom/failures/window_heat_fail_2", globalPropertyi },
    { "window_heat_fail_3", "tu154/custom/failures/window_heat_fail_3", globalPropertyi },
    -- Anti-ice outputs and simulator state
    { "ice_detected", "tu154/custom/antiice/ice_detected", globalPropertyi },
    { "ice_detect_ok", "tu154/custom/antiice/ice_detect_ok", globalPropertyi },
    { "ice_window_heat_on", "sim/cockpit2/ice/ice_window_heat_on", globalPropertyi },
    { "window_ice_1", "tu154/custom/anim/window_ice_1", globalPropertyf },
    { "window_ice_2", "tu154/custom/anim/window_ice_2", globalPropertyf },
    { "window_ice_3", "tu154/custom/anim/window_ice_3", globalPropertyf },
    { "window_ice_4", "tu154/custom/anim/window_ice_4", globalPropertyf },
    { "inlet_heat_1", "sim/cockpit2/ice/ice_inlet_heat_on_per_engine[0]", globalPropertyi },
    { "inlet_heat_2", "sim/cockpit2/ice/ice_inlet_heat_on_per_engine[1]", globalPropertyi },
    { "inlet_heat_3", "sim/cockpit2/ice/ice_inlet_heat_on_per_engine[2]", globalPropertyi },
    { "sim_pitot_heat_1", "sim/cockpit2/ice/ice_pitot_heat_on_pilot", globalPropertyi },
    { "sim_pitot_heat_2", "sim/cockpit2/ice/ice_pitot_heat_on_copilot", globalPropertyi },
    { "AOA_heat_on", "sim/cockpit2/ice/ice_AOA_heat_on", globalPropertyi },
    { "AOA_heat_on_copilot", "sim/cockpit2/ice/ice_AOA_heat_on_copilot", globalPropertyi },
    { "wings_heat_on", "sim/cockpit2/ice/ice_surfce_heat_on", globalPropertyi },
    { "frm_ice", "sim/flightmodel/failures/frm_ice", globalPropertyf },
    { "frm_ice2", "sim/flightmodel/failures/frm_ice2", globalPropertyf },
    { "wing_heating", "tu154/custom/antiice/wing_heating", globalPropertyi },
    { "slat_heating", "tu154/custom/antiice/slat_heating", globalPropertyi },
    { "ai_27_L_cc", "tu154/custom/antiice/ai_27_L_cc", globalPropertyf },
    { "ai_27_R_cc", "tu154/custom/antiice/ai_27_R_cc", globalPropertyf },
    { "ai_115_1_cc", "tu154/custom/antiice/ai_115_1_cc", globalPropertyf },
    { "ai_115_2_cc", "tu154/custom/antiice/ai_115_2_cc", globalPropertyf },
    { "ai_115_3_cc", "tu154/custom/antiice/ai_115_3_cc", globalPropertyf },
    { "eng_heat_open_1", "tu154/custom/antiice/eng_heat_open_1", globalPropertyi },
    { "eng_heat_open_2", "tu154/custom/antiice/eng_heat_open_2", globalPropertyi },
    { "eng_heat_open_3", "tu154/custom/antiice/eng_heat_open_3", globalPropertyi },
    -- Temperature gauges
    { "wing_heat_t", "tu154/custom/antiice/wing_heat_t", globalPropertyf },
    { "stab_heat_t", "tu154/custom/antiice/stab_heat_t", globalPropertyf },
    -- SmartCopilot
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf },
})

-- Legacy source bindings kept disabled intentionally.
-- defineProperty("hot_tube_t", globalPropertyf("tu154/custom/bleed/hot_tube_t")) -- Hot-air duct temperature.
-- defineProperty("eng_airvalve_1", globalPropertyf("tu154/custom/bleed/eng_airvalve_1")) -- Engine 1 bleed-air valve position.
-- defineProperty("eng_airvalve_2", globalPropertyf("tu154/custom/bleed/eng_airvalve_2")) -- Engine 2 bleed-air valve position.
-- defineProperty("eng_airvalve_3", globalPropertyf("tu154/custom/bleed/eng_airvalve_3")) -- Engine 3 bleed-air valve position.

local ice_reseted = false
local ice_ratio_last = get(window_ice)
local ice_speed = 0

local ice_timer = 20
local ice_work_timer = 150

local ice_on_wings_L = 0
local ice_on_wings_R = 0
local ice_on_slats_L = 0
local ice_on_slats_R = 0

--[[
set(window_ice_1, 1)
set(window_ice_2, 1)
set(window_ice_3, 1)
set(window_ice_4, 1)
--]]

function update()
    local MASTER = get(ismaster) ~= 1
    local passed = get(frame_time)

    local power27_L = get(bus27_volt_left) > 13
    local power27_R = get(bus27_volt_right) > 13
    local power115_1 = get(bus115_1_volt) > 110
    local power115_2 = get(bus115_2_volt) > 110
    local power115_3 = get(bus115_3_volt) > 110

    -- Reserved legacy variables. They are intentionally retained even though
    -- the current implementation writes the resulting loads directly.
    local power_CC_115_1 = 0
    local power_CC_115_2 = 0
    local power_CC_115_3 = 0

    local out_term = get(termo)
    local positive_out_term = math.max(out_term, 0)
    local ice_ratio = get(window_ice)

    if MASTER then
        -- Normalize the simulator icing ratio when it approaches its limits.
        if ice_ratio > 0.9 or ice_ratio < 0.1 then
            ice_ratio = 0.5
            set(window_ice, 0.5)
            ice_reseted = true
        else
            ice_reseted = false
        end

        -- Derive the icing rate while ignoring large ratio jumps.
        if passed ~= 0 and not ice_reseted then
            if math.abs(ice_ratio - ice_ratio_last) > 0.01 then
                ice_speed = 0
            else
                ice_speed = (ice_ratio - ice_ratio_last) * 2 / passed
            end
        end

        ice_ratio_last = ice_ratio

        -- SOI-21 ice detection logic.
        local rio_failed = get(rio_fail) == 1
        local ice_test = get(soi21_test) == 1

        ice_timer = ice_timer + passed

        if power27_L and power27_R and get(soi21_on) == 1 then
            if (ice_speed > 0 or ice_test) and not rio_failed then
                ice_timer = 0
            end

            -- Preserve the original delayed test indication behavior.
            if ice_test then
                ice_work_timer = 0
            else
                ice_work_timer = ice_work_timer + passed
            end

            set(
                ice_detect_ok,
                bool2int(ice_work_timer > 30 and ice_work_timer < 55 and not rio_failed)
            )

            --[[
            if ice_test then
                ice_work_timer = ice_work_timer + passed
                if ice_work_timer > 1 then
                    set(ice_detect_ok, bool2int(not rio_failed))
                else
                    set(ice_detect_ok, 0)
                end
            else
                ice_work_timer = 0
                set(ice_detect_ok, 0)
            end
            --]]

            set(ice_detected, bool2int(ice_timer < 8))
        else
            ice_work_timer = 150
            ice_timer = 20

            set(ice_detect_ok, 0)
            set(ice_detected, 0)
            -- set(ice_window_heat_on, 0)
        end

        -- Calculate windshield heating rates from switch, power and failure states.
        local window_heat_spd_1 = 0
        local win_heat_sw_1 = get(window_heat_1)
        local window_heat_fail_factor_1 = 1 - get(window_heat_fail_1)

        if win_heat_sw_1 == 1 and power27_L and power115_1 then
            window_heat_spd_1 = 0.02 * window_heat_fail_factor_1
        elseif win_heat_sw_1 == -1 and power27_L and power115_1 then
            window_heat_spd_1 = 0.015 * window_heat_fail_factor_1
        end

        local window_heat_spd_2 = 0
        local win_heat_sw_2 = get(window_heat_2)
        local window_heat_fail_factor_2 = 1 - get(window_heat_fail_2)

        if win_heat_sw_2 == 1 and power27_R and power115_3 then
            window_heat_spd_2 = 0.02 * window_heat_fail_factor_2
        elseif win_heat_sw_2 == -1 and power27_R and power115_3 then
            window_heat_spd_2 = 0.015 * window_heat_fail_factor_2
        end

        local window_heat_spd_3 = 0
        local win_heat_sw_3 = get(window_heat_3)
        local window_heat_fail_factor_3 = 1 - get(window_heat_fail_3)

        if win_heat_sw_3 == 1 and power27_R and power115_3 then
            window_heat_spd_3 = 0.02 * window_heat_fail_factor_3
        elseif win_heat_sw_3 == -1 and power27_R and power115_3 then
            window_heat_spd_3 = 0.015 * window_heat_fail_factor_3
        end

        -- Update visual windshield ice and clamp each state to its valid range.
        local win_ice_1 = get(window_ice_1)
            + (ice_speed - window_heat_spd_1 - positive_out_term) * passed
        local win_ice_2 = get(window_ice_2)
            + (ice_speed - window_heat_spd_2 - positive_out_term) * passed
        local win_ice_3 = get(window_ice_3)
            + (ice_speed - window_heat_spd_3 - positive_out_term) * passed
        local win_ice_4 = get(window_ice_4)
            + (ice_speed - positive_out_term) * passed

        set(window_ice_1, clamp(win_ice_1, 0, 1))
        set(window_ice_2, clamp(win_ice_2, 0, 1))
        set(window_ice_3, clamp(win_ice_3, 0, 1))
        set(window_ice_4, clamp(win_ice_4, 0, 1))

        set(ai_115_1_cc, window_heat_spd_1 * 250)
        set(ai_115_3_cc, (window_heat_spd_2 + window_heat_spd_3) * 250)
    end

    -- Heat Pitot probes and AOA sensors.
    local pitot_sw_1 = math.max(
        get(pitot_heat_1) * bool2int(get(rel_ice_pitot_heat1) ~= 6),
        0
    )
    local pitot_sw_2 = math.max(
        get(pitot_heat_2) * bool2int(get(rel_ice_pitot_heat2) ~= 6),
        0
    )
    local pitot_sw_3 = math.max(
        get(pitot_heat_3) * bool2int(get(ppd_3_heat_fail) ~= 1),
        0
    )

    if power27_L then
        set(sim_pitot_heat_1, pitot_sw_1)
        set(AOA_heat_on, pitot_sw_1)
        set(AOA_heat_on_copilot, pitot_sw_1)
        set(ai_27_L_cc, 10 * pitot_sw_1)
    else
        set(sim_pitot_heat_1, 0)
        set(AOA_heat_on, 0)
        set(AOA_heat_on_copilot, 0)
        set(ai_27_L_cc, 0)
    end

    if power27_R then
        -- PPD-3 is represented in the electrical load only because no separate
        -- third simulator Pitot-heat output is defined in the project references.
        set(sim_pitot_heat_2, pitot_sw_2)
        set(ai_27_R_cc, 7 * pitot_sw_2 + 7 * pitot_sw_3)
    else
        set(sim_pitot_heat_2, 0)
        set(ai_27_R_cc, 0)
    end

    -- Engine inlet anti-ice.
    local rpm_1 = get(rpm_high_1) > 50
    local rpm_2 = get(rpm_high_2) > 50
    local rpm_3 = get(rpm_high_3) > 50

    local inlet_heat_ok_1 = get(rel_ice_inlet_heat1) ~= 6
    local inlet_heat_ok_2 = get(rel_ice_inlet_heat2) ~= 6
    local inlet_heat_ok_3 = get(rel_ice_inlet_heat3) ~= 6

    local antiice_eng_sw_1 = get(antiice_eng_1)
    local antiice_eng_sw_2 = get(antiice_eng_2)
    local antiice_eng_sw_3 = get(antiice_eng_3)

    set(
        inlet_heat_1,
        bool2int(inlet_heat_ok_1 and rpm_1 and power27_L) * antiice_eng_sw_1
    )
    set(
        eng_heat_open_1,
        bool2int(inlet_heat_ok_1 and power27_L) * antiice_eng_sw_1
    )

    set(
        inlet_heat_2,
        bool2int(rpm_2 and power27_R) * antiice_eng_sw_2 * bool2int(inlet_heat_ok_2)
    )
    set(
        eng_heat_open_2,
        bool2int(inlet_heat_ok_2 and power27_R) * antiice_eng_sw_2
    )

    set(
        inlet_heat_3,
        bool2int(rpm_3 and power27_R) * antiice_eng_sw_3 * bool2int(inlet_heat_ok_3)
    )
    set(
        eng_heat_open_3,
        bool2int(inlet_heat_ok_3 and power27_R) * antiice_eng_sw_3
    )

    -- Wing and slat anti-ice.
    local any_engine_running = rpm_1 or rpm_2 or rpm_3
    local antiice_power_available = power27_L or power27_R
    local antiice_wing_sw = get(antiice_wing)

    set(
        wings_heat_on,
        bool2int(any_engine_running and antiice_power_available) * antiice_wing_sw
    )

    local wing_heat = bool2int(
        any_engine_running
            and antiice_power_available
            and get(rel_ice_surf_heat) < 6
    ) * antiice_wing_sw

    local slat_heat = bool2int(
        power115_2
            and antiice_power_available
            and get(rel_ice_surf_heat2) < 6
            and get(deflection_mtr_2) < 0.1
            and get(deflection_mtr_3) < 0.1
    ) * get(antiice_slats)

    set(wing_heating, wing_heat)
    set(slat_heating, slat_heat)
    set(ai_115_2_cc, slat_heat * 70)

    -- Model wing and stabilizer anti-ice duct temperatures.
    local indicated_airspeed = get(IAS)
    local wing_tube = get(wing_heat_t)

    wing_tube = wing_tube
        + (out_term - wing_tube) * passed * 0.1 * (1 + indicated_airspeed / 200)
    wing_tube = wing_tube
        + (wing_heat * 300 - wing_tube) * passed * 0.1

    set(wing_heat_t, wing_tube)

    local stab_tube = get(stab_heat_t)

    stab_tube = stab_tube
        + (out_term - stab_tube) * passed * 0.1 * (1 + indicated_airspeed / 300)
    stab_tube = stab_tube
        + (wing_heat * 300 - stab_tube) * passed * 0.1

    set(stab_heat_t, stab_tube)

    -- print(wing_tube, "  ", stab_tube)

    -- Accumulate ice on wings and slats using the original stochastic model.
    local positive_wing_tube = math.max(0, wing_tube)

    ice_on_wings_L = ice_on_wings_L
        + (ice_speed * math.random() * 2 - positive_wing_tube * 0.0005) * passed
    ice_on_slats_L = ice_on_slats_L
        + (ice_speed * math.random() * 2 - slat_heat * 0.02) * passed

    if ice_on_wings_L < 0 then
        ice_on_wings_L = 0
    end
    if ice_on_slats_L < 0 then
        ice_on_slats_L = 0
    end

    ice_on_wings_R = ice_on_wings_R
        + (ice_speed * math.random() * 2 - positive_wing_tube * 0.0005) * passed
    ice_on_slats_R = ice_on_slats_R
        + (ice_speed * math.random() * 2 - slat_heat * 0.02) * passed

    if ice_on_wings_R < 0 then
        ice_on_wings_R = 0
    end
    if ice_on_slats_R < 0 then
        ice_on_slats_R = 0
    end

    if ice_on_slats_L > 0.2 then
        ice_on_slats_L = 0.2
    end
    if ice_on_slats_R > 0.2 then
        ice_on_slats_R = 0.2
    end

    if MASTER then
        set(frm_ice, ice_on_wings_L * 0.8 + ice_on_slats_L * 0.2)
        set(frm_ice2, ice_on_wings_R * 0.8 + ice_on_slats_R * 0.2)
    end

    set(ice_window_heat_on, 0)
end
