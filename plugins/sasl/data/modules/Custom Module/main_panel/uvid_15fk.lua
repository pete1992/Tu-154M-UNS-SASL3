-- uvid_15fk.lua
-- UVID-15FK altimeter logic

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"static_fail_L", "sim/operation/failures/rel_static", globalPropertyi},
    {"bus27_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus115_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"uvid_fail", "tu154/custom/failures/uvid15_fail", globalPropertyi},
    {"msl_alt", "sim/flightmodel/position/elevation", globalPropertyf},
    {"msl_press", "sim/weather/barometer_sealevel_inhg", globalPropertyf},
    {"uvid_needle_left", "tu154/custom/gauges/alt/uvid_needle_left", globalPropertyf},
    {"uvid_feet_counter", "tu154/custom/gauges/alt/uvid_feet_counter", globalPropertyf},
    {"uvid_hundreads_counter", "tu154/custom/gauges/alt/uvid_hundreads_counter", globalPropertyf},
    {"uvid_thousands_counter", "tu154/custom/gauges/alt/uvid_thousands_counter", globalPropertyf},
    {"uvid_tens_thousands_counter", "tu154/custom/gauges/alt/uvid_tens_thousands_counter", globalPropertyf},
    {"uvid_pressure_knob", "tu154/custom/gauges/alt/uvid_pressure_knob", globalPropertyf},
    {"uvid_pressure_one", "tu154/custom/gauges/alt/uvid_pressure_one", globalPropertyf},
    {"uvid_pressure_ten", "tu154/custom/gauges/alt/uvid_pressure_ten", globalPropertyf},
    {"uvid_pressure_hund", "tu154/custom/gauges/alt/uvid_pressure_hund", globalPropertyf},
    {"uvid_pressure_thous", "tu154/custom/gauges/alt/uvid_pressure_thous", globalPropertyf},
    {"uvid_on", "tu154/custom/switchers/ovhd/uvid_on", globalPropertyi},
    {"sim_barometer_setting", "sim/cockpit/misc/barometer_setting", globalPropertyf},
    {"vd15_lamp", "tu154/custom/lights/small/vd15_lamp", globalPropertyf},
})

-- Sounds.
local switcher_sound = sasl.al.loadSample("Custom Sounds/metal_switch.wav")

local left_MSL = 0
local uvid_alt = 0
local uvid_alt_act = 0

local switcher_last = get(uvid_on) == 1


function update()
    local passed = get(frame_time)

    -- Calculate source altitude.
    local staticFail_left = get(static_fail_L) == 6
    local msl = get(msl_alt) * 3.28083

    if not staticFail_left then
        left_MSL = msl
    end

    -- Check electrical power and operating state.
    local power27 = get(bus27_volt) > 13
    local power115 = get(bus115_volt) > 110
    local sw_on = get(uvid_on) == 1

    local press_set = get(uvid_pressure_knob)
    local press_inHg = press_set * 0.0295300586467

    -- Switch sound.
    if switcher_last ~= sw_on then
        sasl.al.playSample(switcher_sound, false)
    end

    switcher_last = sw_on

    -- Calculate indicated altitude.
    if power27
        and power115
        and sw_on
        and get(uvid_fail) == 0 then

        uvid_alt =
            left_MSL
            + (press_inHg - get(msl_press)) * 1000
    end

    -- Smooth needle and drum movement.
    uvid_alt_act =
        uvid_alt_act
        + (uvid_alt - uvid_alt_act) * passed * 5

    -- Feet drum.
    local alt_dr_1 = uvid_alt_act % 100

    -- Hundreds drum.
    local alt_dr_100 =
        math.floor((uvid_alt_act % 1000) * 0.01)
        + math.max((alt_dr_1 - 50) / 50, 0)

    -- Thousands drum.
    local alt_dr_1000 =
        math.floor((uvid_alt_act % 10000) * 0.001)
        + math.max(alt_dr_100 - 9, 0)

    -- Tens-of-thousands drum.
    local alt_dr_10th =
        math.floor((uvid_alt_act % 100000) * 0.0001)
        + math.max(alt_dr_1000 - 9, 0)

    -- Pressure ones drum.
    local press_1 = press_set % 10

    -- Pressure tens drum.
    local press_10 =
        math.floor((press_set % 100) * 0.1)
        + math.max(press_1 - 9, 0)

    -- Pressure hundreds drum.
    local press_100 =
        math.floor((press_set % 1000) * 0.01)
        + math.max(press_10 - 9, 0)

    -- Pressure thousands drum.
    local press_1000 =
        math.floor((press_set % 10000) * 0.001)
        + math.max(press_100 - 9, 0)

    -- Warning lamp.
    local lamp_shine =
        power27
        and sw_on
        and (
            not power115
            or uvid_alt > 50000
            or press_set < 788
            or press_set > 1074
        )

    set(vd15_lamp, bool2int(lamp_shine))

    -- Gauge outputs.
    set(uvid_needle_left, uvid_alt_act * 360 / 1000)
    set(uvid_feet_counter, uvid_alt_act)
    set(uvid_hundreads_counter, alt_dr_100)
    set(uvid_thousands_counter, alt_dr_1000)
    set(uvid_tens_thousands_counter, alt_dr_10th)

    set(uvid_pressure_one, press_1)
    set(uvid_pressure_ten, press_10)
    set(uvid_pressure_hund, press_100)
    set(uvid_pressure_thous, press_1000)

    set(sim_barometer_setting, press_inHg)
end
