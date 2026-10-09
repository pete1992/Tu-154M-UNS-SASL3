-- antiice_logic.lua
-- Controls windshield, probe, inlet, wing and slat heating and their electrical loads.

-- Three windshield circuits drive native XP12 thermal sources; PPD switches
-- protect pilot, copilot and standby probe groups. Existing inlet/wing logic
-- and electrical loads are retained. Native ice is observed, never reset.

-- Native simulator outputs are written every frame.

---------------------------------------------------------------------------
-- Local references for frequently used functions.
---------------------------------------------------------------------------
local get, set = get, set
local HUGE = math.huge
local abs, max, random = math.abs, math.max, math.random

-- Use the shared clamp helper when available.
local clamp = clamp
    or function(v, lo, hi)
        if v < lo then
            return lo
        end
        if v > hi then
            return hi
        end
        return v
    end

local DEFROST_SLOW = 1 / 0.015

-- true = write custom outputs only when their values change.
-- false = write outputs every frame.
local USE_WRITE_CACHE = true

---------------------------------------------------------------------------
-- Keep property handles in P to respect the Lua 5.1 upvalue limit.
---------------------------------------------------------------------------
local P = {}
local env = (getfenv and getfenv(1)) or _ENV or _G

local function defineProps(defs)
    for i = 1, #defs do
        local d = defs[i]
        local name = d[1]
        local handle = d[3](d[2])
        defineProperty(name, handle)
        -- Prefer a property already supplied by the component environment.
        P[name] = env[name] or handle
    end
end

-- SASL array-element access is one-based; callers use X-Plane's zero-based
-- index.
local function intElement(index)
    return function(path)
        return globalPropertyiae(path, index + 1)
    end
end

local function floatElement(index)
    return function(path)
        return globalPropertyfae(path, index + 1)
    end
end

local function defrostTime(path)
    return createGlobalPropertyf(path, DEFROST_SLOW)
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
    { "native_ice_rate", "sim/flightmodel/failures/ice_delta", globalPropertyf },
    { "native_ice_unheated", "sim/flightmodel/failures/window_ice_unheated", globalPropertyf },
    { "native_ice_left", "sim/flightmodel/failures/window_ice_per_window", floatElement(0) },
    { "native_ice_right", "sim/flightmodel/failures/window_ice_per_window", floatElement(1) },
    { "native_ice_center", "sim/flightmodel/failures/window_ice_per_window", floatElement(2) },
    { "rpm_high_1", "tu154/custom/gauges/engine/rpm_high_1", globalPropertyf },
    { "rpm_high_2", "tu154/custom/gauges/engine/rpm_high_2", globalPropertyf },
    { "rpm_high_3", "tu154/custom/gauges/engine/rpm_high_3", globalPropertyf },
    { "termo", "sim/weather/aircraft/temperature_ambient_deg_c", globalPropertyf },
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
})

---------------------------------------------------------------------------
-- Persistent simulation state.
---------------------------------------------------------------------------
local ice_speed = 0
local ice_timer = 20
local ice_work_timer = 150
local ice_on_wings_L, ice_on_wings_R = 0, 0
local ice_on_slats_L, ice_on_slats_R = 0, 0

---------------------------------------------------------------------------
-- Cache the last values written to custom outputs.
---------------------------------------------------------------------------
local cache = {}
local was_master = nil

local put = set
if USE_WRITE_CACHE then
    put = function(h, v)
        if cache[h] ~= v then
            cache[h] = v
            set(h, v)
        end
    end
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
-- Original weak/strong rates and each pane's electrical circuit, fed to
-- XP12's de-ice system. sw is the switch value read by the caller.
local function heatingRate(sw, dc, ac, failure, native_failure)
    if not dc or not ac or get(failure) ~= 0 or get(native_failure) == 6 then
        return 0
    end
    if sw == 1 then
        return 0.02
    end
    if sw == -1 then
        return 0.015
    end
    return 0
end

-- Return inlet heat and valve state; an OFF switch returns zero.
-- Read the failure input only when heating is requested.
local function inletHeat(sw, power, rpm, h_fail)
    if sw ~= 0 and power and get(h_fail) ~= 6 then
        return rpm and sw or 0, sw
    end
    return 0, 0
end

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------
function update()
    local MASTER = get(P.ismaster) ~= 1

    -- Republish cached outputs after a SmartCopilot authority change.
    if MASTER ~= was_master then
        cache = {}
        was_master = MASTER
    end

    local passed = get(P.frame_time)
    if passed ~= passed or passed < 0 or passed == HUGE or get(P.sim_paused) ~= 0 then
        passed = 0
    end

    local power27_L = get(P.bus27_volt_left) > 13
    local power27_R = get(P.bus27_volt_right) > 13
    local power115_1 = get(P.bus115_1_volt) > 110
    local power115_2 = get(P.bus115_2_volt) > 110
    local power115_3 = get(P.bus115_3_volt) > 110

    local out_term = get(P.termo)

    -- Read each windshield-heating switch once per frame.
    local wsw1 = get(P.window_heat_1)
    local wsw2 = get(P.window_heat_2)
    local wsw3 = get(P.window_heat_3)

    local spd1 = heatingRate(wsw1, power27_L, power115_1, P.window_heat_fail_1, P.native_window_fail_left)
    local spd2 = heatingRate(wsw2, power27_R, power115_3, P.window_heat_fail_2, P.native_window_fail_center)
    local spd3 = heatingRate(wsw3, power27_R, power115_3, P.window_heat_fail_3, P.native_window_fail_right)

    -- Own the local simulator's switches on both SmartCopilot peers.
    set(P.native_heat_left, spd1 > 0 and 1 or 0)
    set(P.native_heat_center, spd2 > 0 and 1 or 0)
    set(P.native_heat_right, spd3 > 0 and 1 or 0)
    set(P.native_heat_unused, 0)
    put(P.window_heat_time_1, wsw1 == 1 and 50 or DEFROST_SLOW)
    put(P.window_heat_time_2, wsw2 == 1 and 50 or DEFROST_SLOW)
    put(P.window_heat_time_3, wsw3 == 1 and 50 or DEFROST_SLOW)

    -- Legacy rate multiplier for the SOI/wing model; native ice untouched.
    local icing_rate = get(P.native_ice_rate)
    if icing_rate ~= icing_rate or abs(icing_rate) == HUGE then
        icing_rate = 0
    end
    ice_speed = icing_rate * 2

    if MASTER then
        -- SOI-21 ice detection logic.
        ice_timer = ice_timer + passed

        if power27_L and power27_R and get(P.soi21_on) == 1 then
            local rio_failed = get(P.rio_fail) == 1
            local ice_test = get(P.soi21_test) == 1

            if (ice_speed > 0 or ice_test) and not rio_failed then
                ice_timer = 0
            end

            -- Test indication after more than 1 s of continuous test.
            if ice_test then
                ice_work_timer = ice_work_timer + passed
                if ice_work_timer > 1 then
                    put(P.ice_detect_ok, rio_failed and 0 or 1)
                else
                    put(P.ice_detect_ok, 0)
                end
            else
                ice_work_timer = 0
                put(P.ice_detect_ok, 0)
            end
            put(P.ice_detected, ice_timer < 8 and 1 or 0)
        else
            ice_work_timer = 150
            ice_timer = 20
            put(P.ice_detect_ok, 0)
            put(P.ice_detected, 0)
        end

        -- L/C/R/all mirrors of the native ice model (observe only).
        put(P.window_ice_1, clamp(get(P.native_ice_left), 0, 1))
        put(P.window_ice_2, clamp(get(P.native_ice_center), 0, 1))
        put(P.window_ice_3, clamp(get(P.native_ice_right), 0, 1))
        put(P.window_ice_4, clamp(get(P.native_ice_unheated), 0, 1))

        put(P.ai_115_1_cc, spd1 * 250)
        put(P.ai_115_3_cc, (spd2 + spd3) * 250)
    end

    -- PPD circuits: -1 momentary test, 0 OFF, 1 HEAT.
    -- Check electrical power before the probe-heating controls.
    local pitot_sw_1 = (power27_L and get(P.pitot_heat_1) == 1 and get(P.rel_ice_pitot_heat1) ~= 6) and 1 or 0
    local pitot_sw_2 = (power27_R and get(P.pitot_heat_2) == 1 and get(P.rel_ice_pitot_heat2) ~= 6) and 1 or 0
    local pitot_sw_3 = (
        power27_R
        and get(P.pitot_heat_3) == 1
        and get(P.ppd_3_heat_fail) == 0
        and get(P.rel_ice_pitot_heat3) ~= 6
    )
            and 1
        or 0

    set(P.sim_pitot_heat_1, pitot_sw_1)
    set(P.sim_pitot_heat_2, pitot_sw_2)
    set(P.sim_pitot_heat_3, pitot_sw_3)

    -- Each probe group also protects its AoA, static and TAT sensor.
    set(P.AOA_heat_on, pitot_sw_1)
    set(P.AOA_heat_on_copilot, pitot_sw_2)
    set(P.AOA_heat_on_standby, pitot_sw_3)
    set(P.static_heat_pilot, pitot_sw_1)
    set(P.static_heat_copilot, pitot_sw_2)
    set(P.static_heat_standby, pitot_sw_3)
    set(P.TAT_heat_pilot, pitot_sw_1)
    set(P.TAT_heat_copilot, pitot_sw_2)
    set(P.TAT_heat_standby, pitot_sw_3)

    put(P.ai_27_L_cc, 10 * pitot_sw_1)
    put(P.ai_27_R_cc, 7 * pitot_sw_2 + 7 * pitot_sw_3)

    -- Engine inlet anti-ice.
    local rpm_1 = get(P.rpm_high_1) > 50
    local rpm_2 = get(P.rpm_high_2) > 50
    local rpm_3 = get(P.rpm_high_3) > 50

    local ih, eo = inletHeat(get(P.antiice_eng_1), power27_L, rpm_1, P.rel_ice_inlet_heat1)
    set(P.inlet_heat_1, ih)
    put(P.eng_heat_open_1, eo)

    ih, eo = inletHeat(get(P.antiice_eng_2), power27_R, rpm_2, P.rel_ice_inlet_heat2)
    set(P.inlet_heat_2, ih)
    put(P.eng_heat_open_2, eo)

    ih, eo = inletHeat(get(P.antiice_eng_3), power27_R, rpm_3, P.rel_ice_inlet_heat3)
    set(P.inlet_heat_3, ih)
    put(P.eng_heat_open_3, eo)

    -- Wing and slat anti-ice.
    local any_engine_running = rpm_1 or rpm_2 or rpm_3
    local antiice_power_available = power27_L or power27_R
    local wing_cond = any_engine_running and antiice_power_available
    local antiice_wing_sw = get(P.antiice_wing)

    set(P.wings_heat_on, (wing_cond and 1 or 0) * antiice_wing_sw)

    local wing_heat = ((wing_cond and get(P.rel_ice_surf_heat) < 6) and 1 or 0) * antiice_wing_sw

    -- Read slat-heating prerequisites only when heating is requested.
    local slat_sw = get(P.antiice_slats)
    local slat_heat = 0
    if slat_sw ~= 0 then
        slat_heat = (
            (
                    power115_2
                    and antiice_power_available
                    and get(P.rel_ice_surf_heat2) < 6
                    and get(P.deflection_mtr_2) < 0.1
                    and get(P.deflection_mtr_3) < 0.1
                )
                and 1
            or 0
        ) * slat_sw
    end

    put(P.wing_heating, wing_heat)
    put(P.slat_heating, slat_heat)
    put(P.ai_115_2_cc, slat_heat * 70)

    -- Wing and stabilizer duct temperatures
    -- Write only if the value read in this frame has changed.
    local indicated_airspeed = get(P.IAS)
    local wing_old = get(P.wing_heat_t)
    local wing_tube = wing_old + (out_term - wing_old) * passed * 0.1 * (1 + indicated_airspeed / 200)
    wing_tube = wing_tube + (wing_heat * 300 - wing_tube) * passed * 0.1
    if wing_tube ~= wing_old then
        set(P.wing_heat_t, wing_tube)
    end

    local stab_old = get(P.stab_heat_t)
    local stab_tube = stab_old + (out_term - stab_old) * passed * 0.1 * (1 + indicated_airspeed / 300)
    stab_tube = stab_tube + (wing_heat * 300 - stab_tube) * passed * 0.1
    if stab_tube ~= stab_old then
        set(P.stab_heat_t, stab_tube)
    end

    -- Original stochastic ice model: 4 random() calls in original order.
    local positive_wing_tube = max(0, wing_tube)

    ice_on_wings_L = ice_on_wings_L + (ice_speed * random() * 2 - positive_wing_tube * 0.0005) * passed
    ice_on_slats_L = ice_on_slats_L + (ice_speed * random() * 2 - slat_heat * 0.02) * passed

    if ice_on_wings_L < 0 then
        ice_on_wings_L = 0
    end
    if ice_on_slats_L < 0 then
        ice_on_slats_L = 0
    end

    ice_on_wings_R = ice_on_wings_R + (ice_speed * random() * 2 - positive_wing_tube * 0.0005) * passed
    ice_on_slats_R = ice_on_slats_R + (ice_speed * random() * 2 - slat_heat * 0.02) * passed

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
        set(P.frm_ice, ice_on_wings_L * 0.8 + ice_on_slats_L * 0.2)
        set(P.frm_ice2, ice_on_wings_R * 0.8 + ice_on_slats_R * 0.2)
    end
end
