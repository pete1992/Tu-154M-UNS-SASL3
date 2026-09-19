-- antiice_logic.lua
-- Anti-ice system logic.

-- Three windshield circuits drive native XP12 thermal sources; PPD switches
-- protect pilot, copilot and standby probe groups. Existing inlet/wing logic
-- and electrical loads are retained. Native ice is observed, never reset.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

-- SASL array-element access is one-based; callers use X-Plane's zero-based index.
local function intElement(index)
    return function(path) return globalPropertyiae(path, index + 1) end
end

local function floatElement(index)
    return function(path) return globalPropertyfae(path, index + 1) end
end

local function defrostTime(path)
    return createGlobalPropertyf(path, 1 / 0.015)
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
    -- { "window_ice", "sim/flightmodel/failures/window_ice", globalPropertyf },
    -- The native accretion rate remains meaningful at zero/full ice and does not
    -- require corrupting a visible windshield's ice ratio to use it as a sensor.
    { "native_ice_rate", "sim/flightmodel/failures/ice_delta", globalPropertyf },
    { "native_ice_unheated", "sim/flightmodel/failures/window_ice_unheated", globalPropertyf },
    { "native_ice_left", "sim/flightmodel/failures/window_ice_per_window", floatElement(0) },
    { "native_ice_right", "sim/flightmodel/failures/window_ice_per_window", floatElement(1) },
    { "native_ice_center", "sim/flightmodel/failures/window_ice_per_window", floatElement(2) },
    { "rpm_high_1", "tu154/custom/gauges/engine/rpm_high_1", globalPropertyf },
    { "rpm_high_2", "tu154/custom/gauges/engine/rpm_high_2", globalPropertyf },
    { "rpm_high_3", "tu154/custom/gauges/engine/rpm_high_3", globalPropertyf },
    { "termo", "sim/weather/temperature_ambient_c", globalPropertyf },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    { "sim_paused", "sim/time/paused", globalPropertyi },
    { "IAS", "sim/flightmodel/position/indicated_airspeed", globalPropertyf },
    { "deflection_mtr_2", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalProperty },
    { "deflection_mtr_3", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", globalProperty },
    -- Failures
    { "ppd_3_heat_fail", "tu154/custom/antiice/ppd_3_heat_fail", globalPropertyi },
    { "rel_ice_inlet_heat1", "sim/operation/failures/rel_ice_inlet_heat", globalPropertyi },
    { "rel_ice_inlet_heat2", "sim/operation/failures/rel_ice_inlet_heat2", globalPropertyi },
    { "rel_ice_inlet_heat3", "sim/operation/failures/rel_ice_inlet_heat3", globalPropertyi },
    { "rel_ice_pitot_heat1", "sim/operation/failures/rel_ice_pitot_heat1", globalPropertyi },
    { "rel_ice_pitot_heat2", "sim/operation/failures/rel_ice_pitot_heat2", globalPropertyi },
    { "rel_ice_pitot_heat3", "sim/operation/failures/rel_ice_pitot_heat_stby", globalPropertyi },
    { "native_window_fail_left", "sim/operation/failures/rel_ice_window_heat", globalPropertyi },
    { "native_window_fail_right", "sim/operation/failures/rel_ice_window_heat_cop", globalPropertyi },
    { "native_window_fail_center", "sim/operation/failures/rel_ice_window_heat_l_side", globalPropertyi },
    { "rel_ice_surf_heat", "sim/operation/failures/rel_ice_surf_heat", globalPropertyi },
    { "rel_ice_surf_heat2", "sim/operation/failures/rel_ice_surf_heat2", globalPropertyi },
    { "rio_fail", "tu154/custom/failures/rio_fail", globalPropertyi },
    { "window_heat_fail_1", "tu154/custom/failures/window_heat_fail_1", globalPropertyi },
    { "window_heat_fail_2", "tu154/custom/failures/window_heat_fail_2", globalPropertyi },
    { "window_heat_fail_3", "tu154/custom/failures/window_heat_fail_3", globalPropertyi },
    -- Anti-ice outputs and simulator state
    { "ice_detected", "tu154/custom/antiice/ice_detected", globalPropertyi },
    { "ice_detect_ok", "tu154/custom/antiice/ice_detect_ok", globalPropertyi },
    -- { "ice_window_heat_on", "sim/cockpit2/ice/ice_window_heat_on", globalPropertyi },
    -- This model uses XP12 thermal channels 0/1/2 for left/right/center front
    -- panes. Channel 3 is unused; passenger windows have no electric heater.
    { "native_heat_left", "sim/cockpit2/ice/ice_window_heat_on_window", intElement(0) },
    { "native_heat_right", "sim/cockpit2/ice/ice_window_heat_on_window", intElement(1) },
    { "native_heat_center", "sim/cockpit2/ice/ice_window_heat_on_window", intElement(2) },
    { "native_heat_unused", "sim/cockpit2/ice/ice_window_heat_on_window", intElement(3) },
    { "window_heat_time_1", "tu154/custom/antiice/window_heat_time_1", defrostTime },
    { "window_heat_time_2", "tu154/custom/antiice/window_heat_time_2", defrostTime },
    { "window_heat_time_3", "tu154/custom/antiice/window_heat_time_3", defrostTime },
    { "window_ice_1", "tu154/custom/anim/window_ice_1", globalPropertyf },
    { "window_ice_2", "tu154/custom/anim/window_ice_2", globalPropertyf },
    { "window_ice_3", "tu154/custom/anim/window_ice_3", globalPropertyf },
    { "window_ice_4", "tu154/custom/anim/window_ice_4", globalPropertyf },
    { "inlet_heat_1", "sim/cockpit2/ice/ice_inlet_heat_on_per_engine[0]", globalProperty },
    { "inlet_heat_2", "sim/cockpit2/ice/ice_inlet_heat_on_per_engine[1]", globalProperty },
    { "inlet_heat_3", "sim/cockpit2/ice/ice_inlet_heat_on_per_engine[2]", globalProperty },
    { "sim_pitot_heat_1", "sim/cockpit2/ice/ice_pitot_heat_on_pilot", globalPropertyi },
    { "sim_pitot_heat_2", "sim/cockpit2/ice/ice_pitot_heat_on_copilot", globalPropertyi },
    { "sim_pitot_heat_3", "sim/cockpit2/ice/ice_pitot_heat_on_standby", globalPropertyi },
    { "AOA_heat_on", "sim/cockpit2/ice/ice_AOA_heat_on", globalPropertyi },
    { "AOA_heat_on_copilot", "sim/cockpit2/ice/ice_AOA_heat_on_copilot", globalPropertyi },
    { "AOA_heat_on_standby", "sim/cockpit2/ice/ice_AOA_heat_on_stby", globalPropertyi },
    { "static_heat_pilot", "sim/cockpit2/ice/ice_static_heat_on_pilot", globalPropertyi },
    { "static_heat_copilot", "sim/cockpit2/ice/ice_static_heat_on_copilot", globalPropertyi },
    { "static_heat_standby", "sim/cockpit2/ice/ice_static_heat_on_standby", globalPropertyi },
    { "TAT_heat_pilot", "sim/cockpit2/ice/ice_TAT_heat_on", globalPropertyi },
    { "TAT_heat_copilot", "sim/cockpit2/ice/ice_TAT_heat_on_copilot", globalPropertyi },
    { "TAT_heat_standby", "sim/cockpit2/ice/ice_TAT_heat_on_stby", globalPropertyi },
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
    -- { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf },
})

-- Legacy source bindings kept disabled intentionally.
-- defineProperty("hot_tube_t", globalPropertyf("tu154/custom/bleed/hot_tube_t")) -- Hot-air duct temperature.
-- defineProperty("eng_airvalve_1", globalPropertyf("tu154/custom/bleed/eng_airvalve_1")) -- Engine 1 bleed-air valve position.
-- defineProperty("eng_airvalve_2", globalPropertyf("tu154/custom/bleed/eng_airvalve_2")) -- Engine 2 bleed-air valve position.
-- defineProperty("eng_airvalve_3", globalPropertyf("tu154/custom/bleed/eng_airvalve_3")) -- Engine 3 bleed-air valve position.

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
    if passed ~= passed or passed < 0 or passed == math.huge or get(sim_paused) ~= 0 then
        passed = 0
    end

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

    -- Preserve the original weak/strong rates and each pane's electrical circuit,
    -- but feed them to XP12's actual de-ice system instead of a dark LIT overlay.
    local function heatingRate(switch, dc, ac, failure, native_failure)
        if not dc or not ac or get(failure) ~= 0 or get(native_failure) == 6 then return 0 end
        if get(switch) == 1 then return 0.02 end
        if get(switch) == -1 then return 0.015 end
        return 0
    end
    local window_heat_spd_1 = heatingRate(window_heat_1, power27_L, power115_1,
        window_heat_fail_1, native_window_fail_left)
    local window_heat_spd_2 = heatingRate(window_heat_2, power27_R, power115_3,
        window_heat_fail_2, native_window_fail_center)
    local window_heat_spd_3 = heatingRate(window_heat_3, power27_R, power115_3,
        window_heat_fail_3, native_window_fail_right)

    -- Own the local simulator's switches on both SmartCopilot peers. Display
    -- mirrors and windshield AC loads below retain their master-only updates.
    set(native_heat_left, bool2int(window_heat_spd_1 > 0))
    set(native_heat_center, bool2int(window_heat_spd_2 > 0))
    set(native_heat_right, bool2int(window_heat_spd_3 > 0))
    set(native_heat_unused, 0)
    set(window_heat_time_1, get(window_heat_1) == 1 and 50 or 1 / 0.015)
    set(window_heat_time_2, get(window_heat_2) == 1 and 50 or 1 / 0.015)
    set(window_heat_time_3, get(window_heat_3) == 1 and 50 or 1 / 0.015)

    -- Retain the legacy rate multiplier for the existing SOI/wing model, while
    -- removing the previous reset of native windshield ice to 0.5 every frame.
    local icing_rate = get(native_ice_rate)
    if icing_rate ~= icing_rate or math.abs(icing_rate) == math.huge then icing_rate = 0 end
    ice_speed = icing_rate * 2

    if MASTER then
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
        end

        -- Existing consumers keep their L/C/R/all DataRefs, now mirrored from the
        -- native ice model. Do not clear or inject ice in X-Plane itself.
        set(window_ice_1, clamp(get(native_ice_left), 0, 1))
        set(window_ice_2, clamp(get(native_ice_center), 0, 1))
        set(window_ice_3, clamp(get(native_ice_right), 0, 1))
        set(window_ice_4, clamp(get(native_ice_unheated), 0, 1))

        set(ai_115_1_cc, window_heat_spd_1 * 250)
        set(ai_115_3_cc, (window_heat_spd_2 + window_heat_spd_3) * 250)
    end

    -- PPD circuits: -1 is the momentary diagnostic test, 0 OFF, 1 HEAT.
    -- XP12 has a real standby Pitot channel; the old code only charged its bus.
    local pitot_sw_1 = bool2int(get(pitot_heat_1) == 1 and power27_L and get(rel_ice_pitot_heat1) ~= 6)
    local pitot_sw_2 = bool2int(get(pitot_heat_2) == 1 and power27_R and get(rel_ice_pitot_heat2) ~= 6)
    local pitot_sw_3 = bool2int(get(pitot_heat_3) == 1 and power27_R
        and get(ppd_3_heat_fail) == 0 and get(rel_ice_pitot_heat3) ~= 6)
    set(sim_pitot_heat_1, pitot_sw_1)
    set(sim_pitot_heat_2, pitot_sw_2)
    set(sim_pitot_heat_3, pitot_sw_3)

    -- Each probe group also protects its associated AoA, static and TAT sensor.
    -- In particular, the copilot AoA is no longer powered by the pilot switch.
    -- X-Plane applies the individual native sensor-heater failure states.
    set(AOA_heat_on, pitot_sw_1)
    set(AOA_heat_on_copilot, pitot_sw_2)
    set(AOA_heat_on_standby, pitot_sw_3)
    set(static_heat_pilot, pitot_sw_1)
    set(static_heat_copilot, pitot_sw_2)
    set(static_heat_standby, pitot_sw_3)
    set(TAT_heat_pilot, pitot_sw_1)
    set(TAT_heat_copilot, pitot_sw_2)
    set(TAT_heat_standby, pitot_sw_3)
    -- Retain the established custom electrical circuit loads.
    set(ai_27_L_cc, 10 * pitot_sw_1)
    set(ai_27_R_cc, 7 * pitot_sw_2 + 7 * pitot_sw_3)

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

end
