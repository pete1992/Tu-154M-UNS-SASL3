--[[
Changelog
- Grouped all SASL property bindings through the local defineProps() initialization helper.
- Preserved all property names, Dataref paths, constructors, and binding order.
- Replaced Russian comments with English comments.
- Fixed control sound detection so simultaneous opposite switch or button changes cannot cancel each other out.
- Replaced exact APU bleed-air door endpoint comparisons with threshold-based open/closed states.
- Reduced repeated Dataref reads inside per-frame functions by caching values locally.
- Simplified the default X-Plane APU bridge without changing its intended behavior.
- Preserved all gauge curves, warning thresholds, smoothing factors, lamp latching behavior, and unused bindings.
]]

-- APU panel logic.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Controls
    { "apu_main_switch", "tu154/custom/switchers/eng/apu_main_switch", globalPropertyi }, -- APU main switch
    { "apu_start_mode", "tu154/custom/switchers/eng/apu_start_mode", globalPropertyi }, -- APU start mode
    { "apu_air_bleed", "tu154/custom/switchers/eng/apu_air_bleed", globalPropertyi }, -- Bleed-air door control: -1 close, 0 neutral, +1 open
    { "apu_start", "tu154/custom/buttons/eng/apu_start", globalPropertyi }, -- APU start button
    { "apu_stop", "tu154/custom/buttons/eng/apu_stop", globalPropertyi }, -- APU stop button
    -- Gauges
    { "apu_rpm", "tu154/custom/gauges/eng/apu_rpm", globalPropertyf }, -- APU RPM, 0-100%
    { "apu_egt_gau", "tu154/custom/gauges/eng/apu_egt", globalPropertyf }, -- APU EGT, 0-900 C
    { "apu_oil_temp", "tu154/custom/gauges/eng/apu_oil_temp", globalPropertyf }, -- APU oil temperature, -50 to 150 C
    -- Lamps
    { "low_oil", "tu154/custom/lights/apu/low_oil", globalPropertyf }, -- Low oil quantity
    { "low_oil_press", "tu154/custom/lights/apu/low_oil_press", globalPropertyf }, -- Low oil pressure
    { "high_temp", "tu154/custom/lights/apu/high_temp", globalPropertyf }, -- Excessive temperature
    { "high_rpm", "tu154/custom/lights/apu/high_rpm", globalPropertyf }, -- Excessive RPM
    { "pta6_fail", "tu154/custom/lights/apu/pta6_fail", globalPropertyf }, -- PTA-6A failure
    { "doors_open", "tu154/custom/lights/apu/doors_open", globalPropertyf }, -- APU doors open
    { "fuel_press", "tu154/custom/lights/apu/fuel_press", globalPropertyf }, -- Fuel pressure
    { "start_ready", "tu154/custom/lights/apu/start_ready", globalPropertyf }, -- Ready to start
    { "work_mode", "tu154/custom/lights/apu/work_mode", globalPropertyf }, -- APU on-speed indication
    { "start_apu", "tu154/custom/lights/apu/start_apu", globalPropertyf }, -- Start APU indication
    -- Internal APU state
    { "apu_n1", "tu154/custom/eng/apu_n1", globalPropertyf }, -- APU RPM
    { "apu_oil_t", "tu154/custom/eng/apu_oil_t", globalPropertyf }, -- APU oil temperature
    { "apu_oil_q", "tu154/custom/eng/apu_oil_q", globalPropertyf }, -- APU oil quantity
    { "apu_oil_p", "tu154/custom/eng/apu_oil_p", globalPropertyf }, -- APU oil pressure
    { "apu_egt", "tu154/custom/eng/apu_egt", globalPropertyf }, -- APU exhaust gas temperature
    { "apu_air_press", "tu154/custom/eng/apu_air_press", globalPropertyf }, -- Air pressure available for engine start
    { "apu_air_doors", "tu154/custom/eng/apu_air_doors", globalPropertyf }, -- Bleed-air door position
    { "apu_fuel_p", "tu154/custom/eng/apu_fuel_p", globalPropertyf }, -- APU fuel pressure
    -- Electrical state
    { "apu_start_bus", "tu154/custom/elec/apu_start_bus", globalPropertyf }, -- APU start bus voltage
    { "apu_start_cc", "tu154/custom/elec/apu_start_cc", globalPropertyf }, -- APU starter current draw
    { "apu_start_seq", "tu154/custom/elec/apu_start_seq", globalPropertyi }, -- APU start sequence active
    -- Animation state
    { "apu_doors", "tu154/custom/anim/apu_doors", globalPropertyf }, -- APU external door position, 0 closed to 1 open
    { "cockpit_window_left", "tu154/custom/anim/cockpit_window_left", globalPropertyf }, -- Left cockpit window position
    { "cockpit_window_right", "tu154/custom/anim/cockpit_window_right", globalPropertyf }, -- Right cockpit window position
    -- Other sources
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf }, -- Left 27 V bus voltage
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf }, -- Right 27 V bus voltage
    { "outside_air_temp", "sim/cockpit2/temperature/outside_air_temp_degc", globalPropertyf }, -- Outside air temperature
    -- Lamp sources
    { "test_lamps", "tu154/custom/buttons/lamp_test_apu", globalPropertyi }, -- APU panel lamp-test button
    { "day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf }, -- Day/night lamp brightness selector
    { "gear_vent_set", "tu154/custom/switchers/eng/gear_fan", globalPropertyi }, -- Landing gear ventilation switch
    -- Environment
    { "external_view", "sim/graphics/view/view_is_external", globalPropertyi },
    -- Time
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- Frame time
    -- Default X-Plane APU bridge
    { "APU_generator_on", "sim/cockpit2/electrical/APU_generator_on", globalPropertyi }, -- APU generator state
    { "APU_starter_switch", "sim/cockpit2/electrical/APU_starter_switch", globalPropertyi }, -- APU starter switch state
    { "APU_N1_percent", "sim/cockpit2/electrical/APU_N1_percent", globalPropertyi }, -- Default simulator APU N1
    { "APU_running", "sim/cockpit2/electrical/APU_running", globalPropertyi }, -- Default simulator APU running state
    { "acf_has_APU_switch", "sim/aircraft/overflow/acf_has_APU_switch", globalPropertyi },
    { "rel_APU_press", "sim/operation/failures/rel_APU_press", globalPropertyi },
    { "bleed_air_mode", "sim/cockpit2/pressurization/actuators/bleed_air_mode", globalPropertyi }, -- 0 off, 1 left, 2 both, 3 right, 4 APU, 5 auto
    -- Aircraft and camera coordinates
    { "local_x", "sim/flightmodel/position/local_x", globalPropertyf }, -- Aircraft X position
    { "local_y", "sim/flightmodel/position/local_y", globalPropertyf }, -- Aircraft Y position
    { "local_z", "sim/flightmodel/position/local_z", globalPropertyf }, -- Aircraft Z position
    { "view_x", "sim/graphics/view/view_x", globalPropertyf }, -- Camera X position
    { "view_y", "sim/graphics/view/view_y", globalPropertyf }, -- Camera Y position
    { "view_z", "sim/graphics/view/view_z", globalPropertyf }, -- Camera Z position
    -- Failures
    { "apu_start_fail", "tu154/custom/failures/apu_start_fail", globalPropertyi }, -- Starter failure
    { "apu_gen_fail", "tu154/custom/failures/apu_gen_fail", globalPropertyi }, -- Generator failure
    { "apu_fail_oilt", "tu154/custom/failures/apu_fail_oilt", globalPropertyi }, -- Oil-temperature failure
    { "apu_fail_egt", "tu154/custom/failures/apu_fail_egt", globalPropertyi }, -- EGT failure
    { "apu_fail_fuel_left", "tu154/custom/failures/apu_fail_fuel_left", globalPropertyi }, -- Residual-fuel start failure
    { "apu_fail", "tu154/custom/failures/apu_fail", globalPropertyi }, -- Runtime-related APU failure
    { "apu_press_fail", "tu154/custom/failures/apu_press_fail", globalPropertyi }, -- APU bleed-air failure
})

-- Sounds
local switcher_sound = loadSample('Custom Sounds/metal_switch.wav')
local button_sound = loadSample('Custom Sounds/plastic_btn.wav')
local passed = get(frame_time)

-- Keeps the default X-Plane APU active as a bridge for simulator systems.
local function default_APU()
    local bus27_left = get(bus27_volt_left)
    local bus27_right = get(bus27_volt_right)
    local has_power = bus27_left > 10 or bus27_right > 10

    set(rel_APU_press, 0)
    set(acf_has_APU_switch, 1)
    set(APU_generator_on, 1)
    set(bleed_air_mode, 4)

    -- Start the simulator APU when required and electrical power is available.
    if has_power and (get(APU_running) ~= 1 or get(APU_N1_percent) < 50) then
        set(APU_starter_switch, 2)
    elseif has_power then
        set(APU_starter_switch, 1)
    else
        set(APU_starter_switch, 0)
    end
end

local n1_table_start = {
    { -5000, 0 }, -- Workaround for interpolation outside the normal range
    { 0, 0 },
    { 8, 0 },
    { 12, 15 },
    { 14, 5 },
    { 16, 18 },
    { 18, 15 },
    { 20, 20 },
    { 110, 110 },
    { 1000, 110 }, -- Workaround for interpolation outside the normal range
}

local n1_table_off = {
    { -5000, 0 }, -- Workaround for interpolation outside the normal range
    { 0, 0 },
    { 110, 110 },
    { 1000, 110 }, -- Workaround for interpolation outside the normal range
}

local n1_actual = 0
local EGT_actual = 0
local oil_t_actual = -60

local function gauges()
    local n1 = get(apu_n1)
    local n1_angle

    -- Use the start curve while RPM is increasing to reproduce needle movement.
    if n1 > n1_actual then
        n1_angle = interpolate(n1_table_start, n1)
    else
        n1_angle = interpolate(n1_table_off, n1)
    end

    local EGT_angle = get(apu_egt)
    if EGT_angle < -10 then
        EGT_angle = -10
    end

    local oil_t_angle
    if get(bus27_volt_right) > 13 then
        oil_t_angle = get(apu_oil_t)
    else
        oil_t_angle = -75
    end

    -- n1_angle = 99
    -- EGT_angle = 300
    -- oil_t_angle = 100

    -- Smooth gauge movement using frame time.
    n1_actual = n1_actual + (n1_angle - n1_actual) * passed * 5
    EGT_actual = EGT_actual + (EGT_angle - EGT_actual) * passed * 3
    oil_t_actual = oil_t_actual + (oil_t_angle - oil_t_actual) * passed * 3

    set(apu_rpm, n1_actual)
    set(apu_egt_gau, EGT_actual)
    set(apu_oil_temp, oil_t_actual)
end

local apu_main_last = get(apu_main_switch)
local apu_start_mod_last = get(apu_start_mode)
local apu_air_last = get(apu_air_bleed)
local apu_start_last = get(apu_start)
local apu_stop_last = get(apu_stop)
local test_lamps_last = get(test_lamps)

local function check_controls()
    local apu_main_sw = get(apu_main_switch)
    local apu_start_mod_sw = get(apu_start_mode)
    local apu_air_sw = get(apu_air_bleed)
    local apu_start_but = get(apu_start)
    local apu_stop_but = get(apu_stop)
    local test_lamps_but = get(test_lamps)

    -- Compare each control directly so simultaneous opposite changes cannot cancel out.
    local switch_changed =
        apu_main_sw ~= apu_main_last
        or apu_start_mod_sw ~= apu_start_mod_last
        or apu_air_sw ~= apu_air_last

    local button_changed =
        apu_start_but ~= apu_start_last
        or apu_stop_but ~= apu_stop_last
        or test_lamps_but ~= test_lamps_last

    if switch_changed then
        playSample(switcher_sound, false)
    end
    if button_changed then
        playSample(button_sound, false)
    end

    apu_main_last = apu_main_sw
    apu_start_mod_last = apu_start_mod_sw
    apu_air_last = apu_air_sw
    apu_start_last = apu_start_but
    apu_stop_last = apu_stop_but
    test_lamps_last = test_lamps_but
end

local low_oil_press_sign = 0
local high_temp_sign = 0
local high_rpm_sign = 0
local start_ready_brt = 0

local function lamps()
    local bus27_left = get(bus27_volt_left)
    local bus27_right = get(bus27_volt_right)
    local test_btn = get(test_lamps) * math.max((bus27_right - 10) / 18.5, 0)
    local day_night = 1 - get(day_night_set) * 0.25
    local lamps_brt = math.max((math.max(bus27_left, bus27_right) - 10) / 18.5, 0) * day_night

    local rpm = get(apu_n1)
    local start_seq = get(apu_start_seq) == 1
    local thermo = get(apu_egt)
    local main_sw = get(apu_main_switch) == 1
    local oil_pressure = get(apu_oil_p)
    local oil_quantity = get(apu_oil_q)
    local fuel_pressure = get(apu_fuel_p)
    local apu_doors_pos = get(apu_doors)
    local bleed_doors_pos = get(apu_air_doors)
    local gear_vent_on = get(gear_vent_set) == 1

    -- Use thresholds instead of exact float endpoints for animated door positions.
    local apu_doors_open = apu_doors_pos > 0.9
    local bleed_doors_open = bleed_doors_pos > 0.8
    local bleed_doors_closed = bleed_doors_pos < 0.2

    -- Red warnings latch until the APU main switch is turned off.
    if oil_pressure < 1 then
        low_oil_press_sign = 1
    end
    if (start_seq and thermo > 700) or (not start_seq and thermo > 570) then
        high_temp_sign = 1
    end
    if rpm > 105 then
        high_rpm_sign = 1
    end

    if not main_sw then
        low_oil_press_sign = 0
        high_temp_sign = 0
        high_rpm_sign = 0
    end

    local low_oil_brt = oil_quantity < 0.4 and 1 or 0
    set(low_oil, math.max(low_oil_brt * lamps_brt, test_btn))

    set(low_oil_press, math.max(low_oil_press_sign * lamps_brt, test_btn))
    set(high_temp, math.max(high_temp_sign * lamps_brt, test_btn))
    set(high_rpm, math.max(high_rpm_sign * lamps_brt, test_btn))

    -- PTA-6A failure indication is currently driven only by the lamp test.
    set(pta6_fail, math.max(0, test_btn))

    local doors_open_brt = apu_doors_open and 1 or 0
    set(doors_open, math.max(doors_open_brt * lamps_brt, test_btn))

    local fuel_press_brt = fuel_pressure > 0.8 and 1 or 0
    set(fuel_press, math.max(fuel_press_brt * lamps_brt, test_btn))

    -- Keep the ready indication latched while the bleed door is between endpoints.
    if bleed_doors_closed and apu_doors_open then
        start_ready_brt = 1
    elseif bleed_doors_open or not apu_doors_open then
        start_ready_brt = 0
    end
    set(start_ready, math.max(start_ready_brt * lamps_brt, test_btn))

    local work_mode_brt = rpm > 92 and main_sw and 1 or 0
    set(work_mode, math.max(work_mode_brt * lamps_brt, test_btn))

    local start_apu_brt = rpm < 92 and gear_vent_on and 1 or 0
    set(start_apu, math.max(start_apu_brt * lamps_brt, test_btn))
end

function update()
    passed = get(frame_time)
    default_APU()
    check_controls()
    lamps()
    gauges()
    -- apu_sound()
end
