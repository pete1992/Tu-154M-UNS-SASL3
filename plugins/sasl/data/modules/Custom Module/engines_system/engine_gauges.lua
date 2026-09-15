-- engine_gauges.lua
-- Engine instrument and gauge logic for the Tu-154M.
--[[
Changelog
- X-Plane 12 only: removed all XP11/version switching.
- Switched N1/N2/EGT sources to current X-Plane 12 flightmodel2 datarefs.
- Replaced frame-rate-dependent needle smoothing with stable first-order lag.
- Removed artificial EGT doubling during compressor stall; the gauge now follows the actual engine EGT.
- Removed the old low-RPM tachometer "needle jump" tables and kept one monotonic XP12 calibration per spool.
- Preserved the existing XP12 tachometer calibration so normal operating indications remain compatible with the aircraft.
- Fixed fuel-flow behavior on loss of power: needles now return to the lower stop instead of freezing.
- Reworked oil quantity as an indicated tank-quantity model with a named running-engine circulation correction.
- Reworked fuel temperature into a slow thermal state plus a separate powered instrument indication.
- Kept existing electrical supply, test-button, SmartCopilot and failure behavior unless explicitly corrected above.
- All instrument dynamics are monotonic and cannot overshoot their target values.
]]

-- local defineProps Function
local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    -- Controls
    {"control_ut", "tu154/custom/buttons/eng/control_ut", globalPropertyi},
    {"control_vibro_1", "tu154/custom/buttons/eng/control_vibro_1", globalPropertyi},
    {"control_vibro_2", "tu154/custom/buttons/eng/control_vibro_2", globalPropertyi},
    {"control_vibro_3", "tu154/custom/buttons/eng/control_vibro_3", globalPropertyi},
    {"vibro_sel_1", "tu154/custom/switchers/eng/vibro_sel_1", globalPropertyi},
    {"vibro_sel_2", "tu154/custom/switchers/eng/vibro_sel_2", globalPropertyi},
    {"vibro_sel_3", "tu154/custom/switchers/eng/vibro_sel_3", globalPropertyi},
    {"fuel_meter_on", "tu154/custom/switchers/fuel/fuel_meter_mech_on", globalPropertyi},
    {"gauges_on_1", "tu154/custom/switchers/eng/gauges_on_1", globalPropertyi},
    {"gauges_on_2", "tu154/custom/switchers/eng/gauges_on_2", globalPropertyi},
    {"gauges_on_3", "tu154/custom/switchers/eng/gauges_on_3", globalPropertyi},
    -- Gauge outputs
    {"rpm_low_1", "tu154/custom/gauges/engine/rpm_low_1", globalPropertyf},
    {"rpm_low_2", "tu154/custom/gauges/engine/rpm_low_2", globalPropertyf},
    {"rpm_low_3", "tu154/custom/gauges/engine/rpm_low_3", globalPropertyf},
    {"rpm_high_1", "tu154/custom/gauges/engine/rpm_high_1", globalPropertyf},
    {"rpm_high_2", "tu154/custom/gauges/engine/rpm_high_2", globalPropertyf},
    {"rpm_high_3", "tu154/custom/gauges/engine/rpm_high_3", globalPropertyf},
    {"egt_1", "tu154/custom/gauges/eng/egt_1", globalPropertyf},
    {"egt_2", "tu154/custom/gauges/eng/egt_2", globalPropertyf},
    {"egt_3", "tu154/custom/gauges/eng/egt_3", globalPropertyf},
    {"fuel_press_1", "tu154/custom/gauges/eng/fuel_press_1", globalPropertyf},
    {"fuel_press_2", "tu154/custom/gauges/eng/fuel_press_2", globalPropertyf},
    {"fuel_press_3", "tu154/custom/gauges/eng/fuel_press_3", globalPropertyf},
    {"oil_press_1", "tu154/custom/gauges/eng/oil_press_1", globalPropertyf},
    {"oil_press_2", "tu154/custom/gauges/eng/oil_press_2", globalPropertyf},
    {"oil_press_3", "tu154/custom/gauges/eng/oil_press_3", globalPropertyf},
    {"oil_temp_1", "tu154/custom/gauges/eng/oil_temp_1", globalPropertyf},
    {"oil_temp_2", "tu154/custom/gauges/eng/oil_temp_2", globalPropertyf},
    {"oil_temp_3", "tu154/custom/gauges/eng/oil_temp_3", globalPropertyf},
    {"fuel_flow_1", "tu154/custom/gauges/eng/fuel_flow_1", globalPropertyf},
    {"fuel_flow_2", "tu154/custom/gauges/eng/fuel_flow_2", globalPropertyf},
    {"fuel_flow_3", "tu154/custom/gauges/eng/fuel_flow_3", globalPropertyf},
    {"vibra_1", "tu154/custom/gauges/eng/vibra_1", globalPropertyf},
    {"vibra_2", "tu154/custom/gauges/eng/vibra_2", globalPropertyf},
    {"vibra_3", "tu154/custom/gauges/eng/vibra_3", globalPropertyf},
    {"oil_qty_1", "tu154/custom/gauges/eng/oil_qty_1", globalPropertyf},
    {"oil_qty_2", "tu154/custom/gauges/eng/oil_qty_2", globalPropertyf},
    {"oil_qty_3", "tu154/custom/gauges/eng/oil_qty_3", globalPropertyf},
    {"fuel_temp_1", "tu154/custom/gauges/eng/fuel_temp_1", globalPropertyf},
    {"fuel_temp_2", "tu154/custom/gauges/eng/fuel_temp_2", globalPropertyf},
    -- X-Plane 12 engine sources
    {"sim_egt_1", "sim/flightmodel2/engines/EGT_deg_C[0]", globalProperty},
    {"sim_egt_2", "sim/flightmodel2/engines/EGT_deg_C[1]", globalProperty},
    {"sim_egt_3", "sim/flightmodel2/engines/EGT_deg_C[2]", globalProperty},
    {"eng1_N1", "sim/flightmodel2/engines/N1_percent[0]", globalProperty},
    {"eng2_N1", "sim/flightmodel2/engines/N1_percent[1]", globalProperty},
    {"eng3_N1", "sim/flightmodel2/engines/N1_percent[2]", globalProperty},
    {"eng1_N2", "sim/flightmodel2/engines/N2_percent[0]", globalProperty},
    {"eng2_N2", "sim/flightmodel2/engines/N2_percent[1]", globalProperty},
    {"eng3_N2", "sim/flightmodel2/engines/N2_percent[2]", globalProperty},
    {"ENGN_FF_1", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec[0]", globalProperty},
    {"ENGN_FF_2", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec[1]", globalProperty},
    {"ENGN_FF_3", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec[2]", globalProperty},
    {"fuel_p_1", "sim/cockpit2/engine/indicators/fuel_pressure_psi[0]", globalProperty},
    {"fuel_p_2", "sim/cockpit2/engine/indicators/fuel_pressure_psi[1]", globalProperty},
    {"fuel_p_3", "sim/cockpit2/engine/indicators/fuel_pressure_psi[2]", globalProperty},
    {"oil_p_1", "sim/cockpit2/engine/indicators/oil_pressure_psi[0]", globalProperty},
    {"oil_p_2", "sim/cockpit2/engine/indicators/oil_pressure_psi[1]", globalProperty},
    {"oil_p_3", "sim/cockpit2/engine/indicators/oil_pressure_psi[2]", globalProperty},
    {"oil_t_1", "sim/cockpit2/engine/indicators/oil_temperature_deg_C[0]", globalProperty},
    {"oil_t_2", "sim/cockpit2/engine/indicators/oil_temperature_deg_C[1]", globalProperty},
    {"oil_t_3", "sim/cockpit2/engine/indicators/oil_temperature_deg_C[2]", globalProperty},
    -- Project engine sources
    {"vibration_1", "tu154/custom/eng/vibration_1", globalPropertyf},
    {"vibration_2", "tu154/custom/eng/vibration_2", globalPropertyf},
    {"vibration_3", "tu154/custom/eng/vibration_3", globalPropertyf},
    {"engn_oil_qty_1", "tu154/custom/failures/engn_oil_qty_1", globalPropertyf},
    {"engn_oil_qty_2", "tu154/custom/failures/engn_oil_qty_2", globalPropertyf},
    {"engn_oil_qty_3", "tu154/custom/failures/engn_oil_qty_3", globalPropertyf},
    -- Electrical sources
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
    {"emerg_inv115", "tu154/custom/switchers/eng/emerg_inv115", globalPropertyi},
    {"bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf},
    {"bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf},
    {"bus36_volt_right", "tu154/custom/elec/bus36_volt_right", globalPropertyf},
    -- Environment
    {"thermo", "sim/cockpit2/temperature/outside_air_temp_degc", globalPropertyf},
    {"msl_alt", "sim/flightmodel/position/elevation", globalPropertyf},
    {"baro_press", "sim/weather/barometer_sealevel_inhg", globalPropertyf},
    -- Failures
    {"fuel_flowmeter_1_fail", "tu154/custom/failures/fuel_flowmeter_1_fail", globalPropertyi},
    {"fuel_flowmeter_2_fail", "tu154/custom/failures/fuel_flowmeter_2_fail", globalPropertyi},
    {"fuel_flowmeter_3_fail", "tu154/custom/failures/fuel_flowmeter_3_fail", globalPropertyi},
    -- SmartCopilot
    {"ismaster", "scp/api/ismaster", globalPropertyf},
    -- Time
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
})

-- Electrical thresholds
local MIN_27V = 13
local MIN_36V = 30
local MIN_115V = 110

-- Instrument dynamics. These preserve the approximate response speed of the old gauges,
-- but use an exponential response which cannot overshoot on long frames.
local RPM_TAU = 0.20
local VIBRATION_TAU = 0.33
local PRESSURE_TAU = 0.33
local OIL_TEMP_TAU = 0.33
local EGT_TAU = 1.00
local FUEL_FLOW_TAU = 0.33
local OIL_QTY_TAU = 1.00
local FUEL_TEMP_GAUGE_TAU = 1.00

-- The manual does not specify fuel thermal inertia. 15 minutes is an intentionally
-- conservative approximation until a dedicated fuel thermal model is available.
local FUEL_THERMAL_TAU = 900

-- Preserve the existing running-engine tank-level correction as an explicit model:
-- at 100% N2 roughly 5 units of oil are assumed to be circulating outside the tank.
local OIL_CIRCULATION_DROP_PER_N2_PERCENT = 0.05
local OIL_QTY_NEEDLE_STOP = 4
local FUEL_FLOW_NEEDLE_STOP = 200
local FUEL_TEMP_MIN = -65
local FUEL_TEMP_MAX = 65

-- Calibration limits. Values beyond the verified XP12 tables peg at the last known
-- calibration point instead of extrapolating into a false indication.
local MAX_CALIBRATED_N1 = 110
local MAX_CALIBRATED_N2 = 110
local MAX_CALIBRATED_ALT_M = 11000

local function approach(current, target, dt, tau)
    if tau <= 0 then
        return target
    end

    local safe_dt = math.max(0, dt)
    local gain = 1 - math.exp(-safe_dt / tau)
    return current + (target - current) * gain
end

local function pressureAltitudeMeters()
    local geometric_ft = get(msl_alt) * 3.28083
    local pressure_alt_m = geometric_ft * 0.3048 + (29.92 - get(baro_press)) * 1000 * 0.3048
    return safeClamp(pressure_alt_m, 0, MAX_CALIBRATED_ALT_M, 0)
end

-- Existing XP12 calibration retained from the pre-modernization implementation.
-- It converts X-Plane spool percentages to the Tu-154M cockpit indication.
local HP_GROUND_TABLE = {
    {-100000, 0.0},
    {0, 0},
    {23, 21},
    {71.3, 60.5},
    {84.0, 82.5},
    {89.0, 86.5},
    {91.3, 88.75},
    {95.7, 91.9},
    {97.4, 93.5},
    {99.0, 95.0},
    {110.0, 105.0},
    {1000000000, 105.0},
}

local LP_GROUND_TABLE = {
    {-100000, 0.0},
    {0, 0},
    {1, 3},
    {36.3, 30},
    {59.3, 59},
    {70.5, 68.5},
    {76.2, 72.5},
    {87.5, 80},
    {92.4, 83.5},
    {97.0, 86.75},
    {110.0, 98.0},
    {1000000000, 98.0},
}

local HP_11KM_TABLE = {
    {-100000, 0.0},
    {0, 0},
    {23, 21},
    {82.4, 78.0},
    {86.7, 82.25},
    {92.9, 86.75},
    {95.2, 88.75},
    {98.3, 92.5},
    {99.3, 94.0},
    {100.9, 96.5},
    {110.0, 100.0},
    {1000000000, 100.0},
}

local LP_11KM_TABLE = {
    {-100000, 0.0},
    {0, 0},
    {1, 3},
    {55.9, 63.0},
    {65.3, 69.25},
    {80.2, 77.5},
    {86.3, 81.0},
    {94.8, 86.75},
    {97.8, 89.25},
    {102.8, 94.25},
    {110.0, 100.0},
    {1000000000, 100.0},
}

-- The three-pointer animation uses its historical display scale. These tables are
-- display calibration, not engine physics; engine warning logic continues to use raw values.
local FUEL_PRESSURE_TABLE = {
    {-100000, 0.0},
    {0, 0},
    {40, 30},
    {50, 40},
    {60, 60},
    {100, 100},
    {120, 110},
    {1000000000, 110},
}

local OIL_PRESSURE_TABLE = {
    {-100000, 0.0},
    {0, 0},
    {15, 30},
    {45, 41},
    {80, 80},
    {110, 110},
    {1000000000, 110},
}

local gauges_on = {gauges_on_1, gauges_on_2, gauges_on_3}
local vibration_src = {vibration_1, vibration_2, vibration_3}
local vibro_control = {control_vibro_1, control_vibro_2, control_vibro_3}
local vibro_selector = {vibro_sel_1, vibro_sel_2, vibro_sel_3}
local vibro_out = {vibra_1, vibra_2, vibra_3}
local n1_src = {eng1_N1, eng2_N1, eng3_N1}
local n2_src = {eng1_N2, eng2_N2, eng3_N2}
local rpm_low_out = {rpm_low_1, rpm_low_2, rpm_low_3}
local rpm_high_out = {rpm_high_1, rpm_high_2, rpm_high_3}
local egt_src = {sim_egt_1, sim_egt_2, sim_egt_3}
local egt_out = {egt_1, egt_2, egt_3}
local fuel_pressure_src = {fuel_p_1, fuel_p_2, fuel_p_3}
local fuel_pressure_out = {fuel_press_1, fuel_press_2, fuel_press_3}
local oil_pressure_src = {oil_p_1, oil_p_2, oil_p_3}
local oil_pressure_out = {oil_press_1, oil_press_2, oil_press_3}
local oil_temp_src = {oil_t_1, oil_t_2, oil_t_3}
local oil_temp_out = {oil_temp_1, oil_temp_2, oil_temp_3}
local fuel_flow_src = {ENGN_FF_1, ENGN_FF_2, ENGN_FF_3}
local fuel_flow_fail = {fuel_flowmeter_1_fail, fuel_flowmeter_2_fail, fuel_flowmeter_3_fail}
local fuel_flow_out = {fuel_flow_1, fuel_flow_2, fuel_flow_3}
local oil_qty_src = {engn_oil_qty_1, engn_oil_qty_2, engn_oil_qty_3}
local oil_qty_out = {oil_qty_1, oil_qty_2, oil_qty_3}
local rpm_high_state = {0, 0, 0}
local rpm_low_state = {0, 0, 0}
local vibration_state = {0, 0, 0}
local fuel_pressure_state = {0, 0, 0}
local oil_pressure_state = {0, 0, 0}
local oil_temp_state = {-50, -50, -50}
local egt_state = {0, 0, 0}
local fuel_flow_state = {FUEL_FLOW_NEEDLE_STOP, FUEL_FLOW_NEEDLE_STOP, FUEL_FLOW_NEEDLE_STOP}
local oil_qty_state = {OIL_QTY_NEEDLE_STOP, OIL_QTY_NEEDLE_STOP, OIL_QTY_NEEDLE_STOP}
local fuel_temp_bulk = {get(thermo), get(thermo)}
local fuel_temp_state = {get(fuel_temp_1), get(fuel_temp_2)}

local initialized = false

local function engineSidePower(left_power, right_power, engine)
    if engine == 1 then
        return left_power
    end
    return right_power
end

local function updateTachometers(dt, master)
    if not master then
        -- Keep local instrument state aligned with synchronized outputs so a later
        -- SmartCopilot ownership transfer does not make the needles jump from zero.
        for engine = 1, 3 do
            rpm_high_state[engine] = get(rpm_high_out[engine])
            rpm_low_state[engine] = get(rpm_low_out[engine])
        end
        return
    end

    local altitude = pressureAltitudeMeters()

    for engine = 1, 3 do
        local raw_n2 = safeClamp(get(n2_src[engine]), 0, MAX_CALIBRATED_N2, 0)
        local raw_n1 = safeClamp(get(n1_src[engine]), 0, MAX_CALIBRATED_N1, 0)

        local hp_ground = interpolate(HP_GROUND_TABLE, raw_n2)
        local hp_high = interpolate(HP_11KM_TABLE, raw_n2)
        local hp_target = line(altitude, 0, hp_ground, MAX_CALIBRATED_ALT_M, hp_high)

        local lp_ground = interpolate(LP_GROUND_TABLE, raw_n1)
        local lp_high = interpolate(LP_11KM_TABLE, raw_n1)
        local lp_target = line(altitude, 0, lp_ground, MAX_CALIBRATED_ALT_M, lp_high)

        if initialized then
            rpm_high_state[engine] = approach(rpm_high_state[engine], hp_target, dt, RPM_TAU)
            rpm_low_state[engine] = approach(rpm_low_state[engine], lp_target, dt, RPM_TAU)
        else
            rpm_high_state[engine] = hp_target
            rpm_low_state[engine] = lp_target
        end

        set(rpm_high_out[engine], rpm_high_state[engine])
        set(rpm_low_out[engine], rpm_low_state[engine])
    end
end

local function updateVibrationGauges(dt, power_27_left, power_27_right)
    for engine = 1, 3 do
        local powered = engineSidePower(power_27_left, power_27_right, engine)
        local target = 0

        if powered then
            if get(vibro_control[engine]) == 1 then
                target = 95 * get(gauges_on[engine])
            else
                target = get(vibration_src[engine]) * get(gauges_on[engine])
                if get(vibro_selector[engine]) == 0 then
                    target = target * 0.95
                end
            end
        end

        if initialized then
            vibration_state[engine] = approach(vibration_state[engine], target, dt, VIBRATION_TAU)
        else
            vibration_state[engine] = target
        end

        set(vibro_out[engine], vibration_state[engine])
    end
end

local function updateThreePointer(dt, power_27_left, power_27_right, power_36_left, power_36_right)
    for engine = 1, 3 do
        local power_36 = engineSidePower(power_36_left, power_36_right, engine)
        local power_27 = engineSidePower(power_27_left, power_27_right, engine)

        local fuel_pressure_target = 0
        local oil_pressure_target = 0
        local oil_temp_target = -50

        if power_36 then
            fuel_pressure_target = interpolate(FUEL_PRESSURE_TABLE, math.max(0, get(fuel_pressure_src[engine])))
            oil_pressure_target = interpolate(OIL_PRESSURE_TABLE, math.max(0, get(oil_pressure_src[engine]))) * 0.1
        end

        if power_27 then
            oil_temp_target = get(oil_temp_src[engine])
        end

        if initialized then
            fuel_pressure_state[engine] = approach(fuel_pressure_state[engine], fuel_pressure_target, dt, PRESSURE_TAU)
            oil_pressure_state[engine] = approach(oil_pressure_state[engine], oil_pressure_target, dt, PRESSURE_TAU)
            oil_temp_state[engine] = approach(oil_temp_state[engine], oil_temp_target, dt, OIL_TEMP_TAU)
        else
            fuel_pressure_state[engine] = fuel_pressure_target
            oil_pressure_state[engine] = oil_pressure_target
            oil_temp_state[engine] = oil_temp_target
        end

        set(fuel_pressure_out[engine], fuel_pressure_state[engine])
        set(oil_pressure_out[engine], oil_pressure_state[engine])
        set(oil_temp_out[engine], oil_temp_state[engine])
    end
end

local function updateEGTGauges(dt, power_27_left, power_27_right, power_115)
    local emergency_inverter = get(emerg_inv115) == 1
    local dc_available = power_27_left or power_27_right
    local ac_available = power_115 or (dc_available and emergency_inverter)
    local test_button = get(control_ut) == 1

    for engine = 1, 3 do
        local dc_power = engineSidePower(power_27_left, power_27_right, engine)
        local powered = dc_power and ac_available
        local target = 0

        if powered then
            target = math.max(0, get(egt_src[engine]))

            -- Preserve the existing instrument-test positions.
            if test_button then
                if engine == 1 then
                    target = 120
                elseif engine == 2 then
                    target = 140
                else
                    target = 130
                end
            end
        end

        if initialized then
            egt_state[engine] = approach(egt_state[engine], target, dt, EGT_TAU)
        else
            egt_state[engine] = target
        end

        set(egt_out[engine], egt_state[engine])
    end
end

local function updateFuelFlow(dt, power_27_right, power_115)
    local powered = power_27_right and power_115 and get(fuel_meter_on) == 1

    for engine = 1, 3 do
        local target = FUEL_FLOW_NEEDLE_STOP

        if powered and get(fuel_flow_fail[engine]) == 0 then
            target = math.max(FUEL_FLOW_NEEDLE_STOP, get(fuel_flow_src[engine]) * 3600)
        end

        if initialized then
            fuel_flow_state[engine] = approach(fuel_flow_state[engine], target, dt, FUEL_FLOW_TAU)
        else
            fuel_flow_state[engine] = target
        end

        set(fuel_flow_out[engine], fuel_flow_state[engine])
    end
end

local function updateOilQuantity(dt, power_36_left, power_36_right)
    local instrument_power = power_36_left and power_36_right

    for engine = 1, 3 do
        local target = OIL_QTY_NEEDLE_STOP

        if instrument_power and get(gauges_on[engine]) == 1 then
            local raw_n2 = math.max(0, get(n2_src[engine]))
            local circulating_oil = raw_n2 * OIL_CIRCULATION_DROP_PER_N2_PERCENT
            target = math.max(OIL_QTY_NEEDLE_STOP, get(oil_qty_src[engine]) - circulating_oil)
        end

        if initialized then
            oil_qty_state[engine] = approach(oil_qty_state[engine], target, dt, OIL_QTY_TAU)
        else
            oil_qty_state[engine] = target
        end

        set(oil_qty_out[engine], oil_qty_state[engine])
    end
end

local function updateFuelTemperature(dt, power_27_right)
    local ambient = safeClamp(get(thermo), FUEL_TEMP_MIN, FUEL_TEMP_MAX, 0)

    for channel = 1, 2 do
        fuel_temp_bulk[channel] = approach(fuel_temp_bulk[channel], ambient, dt, FUEL_THERMAL_TAU)
        fuel_temp_bulk[channel] = safeClamp(fuel_temp_bulk[channel], FUEL_TEMP_MIN, FUEL_TEMP_MAX, ambient)

        local target = 0
        if power_27_right then
            target = fuel_temp_bulk[channel]
        end

        if initialized then
            fuel_temp_state[channel] = approach(fuel_temp_state[channel], target, dt, FUEL_TEMP_GAUGE_TAU)
        else
            fuel_temp_state[channel] = target
        end
    end

    set(fuel_temp_1, fuel_temp_state[1])
    set(fuel_temp_2, fuel_temp_state[2])
end

function update()
    local dt = math.max(0, get(frame_time))
    local master = get(ismaster) ~= 1

    local power_27_left = get(bus27_volt_left) > MIN_27V
    local power_27_right = get(bus27_volt_right) > MIN_27V
    local power_36_left = get(bus36_volt_left) > MIN_36V
    local power_36_right = get(bus36_volt_right) > MIN_36V
    local power_115 = get(bus115_1_volt) > MIN_115V

    updateTachometers(dt, master)
    updateEGTGauges(dt, power_27_left, power_27_right, power_115)
    updateThreePointer(dt, power_27_left, power_27_right, power_36_left, power_36_right)
    updateFuelFlow(dt, power_27_right, power_115)
    updateVibrationGauges(dt, power_27_left, power_27_right)
    updateOilQuantity(dt, power_36_left, power_36_right)
    updateFuelTemperature(dt, power_27_right)

    initialized = true
end
