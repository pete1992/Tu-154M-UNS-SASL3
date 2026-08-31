-- Water panel on the flight engineer's upper panel

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    -- X-Plane
    {"deploy_ratio_1", "sim/flightmodel2/gear/deploy_ratio[0]", globalProperty},
    {"deploy_ratio_2", "sim/flightmodel2/gear/deploy_ratio[1]", globalProperty},
    {"deploy_ratio_3", "sim/flightmodel2/gear/deploy_ratio[2]", globalProperty},
    {"groundspeed", "sim/flightmodel/position/groundspeed", globalPropertyf},
    {"eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalProperty},
    {"eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalProperty},
    {"eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalProperty},

    -- Controls
    {"wing_light", "tu154/custom/switchers/eng/wing_light", globalPropertyi},
    {"gear_fan", "tu154/custom/switchers/eng/gear_fan", globalPropertyi},
    {"galley_heat", "tu154/custom/switchers/eng/galley_heat", globalPropertyi},
    {"lavatory_heat", "tu154/custom/switchers/eng/lavatory_heat", globalPropertyi},
    {"water_meter", "tu154/custom/switchers/eng/water_meter", globalPropertyi},
    {"water_compressor_1", "tu154/custom/switchers/eng/water_compressor_1", globalPropertyi},
    {"water_compressor_2", "tu154/custom/switchers/eng/water_compressor_2", globalPropertyi},
    {"tail_temp_signal", "tu154/custom/switchers/eng/tail_temp_signal", globalPropertyi},
    {"tail_temp_heat", "tu154/custom/switchers/eng/tail_temp_heat", globalPropertyi},

    -- Pushbuttons
    {"tail_temp_signal_control_1", "tu154/custom/buttons/eng/tail_temp_signal_control_1", globalPropertyi},
    {"tail_temp_signal_control_2", "tu154/custom/buttons/eng/tail_temp_signal_control_2", globalPropertyi},
    {"lamp_test_eng_up_1", "tu154/custom/buttons/lamp_test_eng_up_1", globalPropertyi},
    {"lamp_test_eng_up_2", "tu154/custom/buttons/lamp_test_eng_up_2", globalPropertyi},

    -- Gauges and lights
    {"water_pressure", "tu154/custom/gauges/eng/water_pressure", globalPropertyf},
    {"water_level_1", "tu154/custom/lights/water_level_1", globalPropertyf},
    {"water_level_12", "tu154/custom/lights/water_level_12", globalPropertyf},
    {"water_level_14", "tu154/custom/lights/water_level_14", globalPropertyf},
    {"water_level_0", "tu154/custom/lights/water_level_0", globalPropertyf},
    {"tail_temp_high", "tu154/custom/lights/small/tail_temp_high", globalPropertyf},
    {"lavatory_heat_lamp", "tu154/custom/lights/small/lavatory_heat", globalPropertyf},
    {"galley_heat_lamp", "tu154/custom/lights/small/galley_heat", globalPropertyf},

    -- Electrical
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},

    -- Timing
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},

    -- Water system state
    {"water_lvl", "tu154/custom/misc/water_level", globalPropertyf},

    -- SmartCopilot
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

local INITIALIZATION_DELAY = 0.3
local ENGINE_STOPPED_N1 = 5
local GEAR_RETRACTED_THRESHOLD = 0.1
local GROUND_STOPPED_SPEED = 0.1
local WATER_CONSUMPTION_TIME = 8 * 3600
local WATER_REFILL_TIME = 0.1 * 3600
local WATER_MIN = 0
local WATER_MAX = 1
local WATER_PRESSURE_MIN_LEVEL = 0.1
local WATER_PRESSURE_PER_COMPRESSOR = 70
local MIN_DC_VOLTAGE = 13

local switch_sound = sasl.al.loadSample("Custom Sounds/metal_switch.wav")
local button_sound = sasl.al.loadSample("Custom Sounds/plastic_btn.wav")

local switch_properties = {
    wing_light,
    gear_fan,
    galley_heat,
    lavatory_heat,
    water_meter,
    water_compressor_1,
    water_compressor_2,
    tail_temp_signal,
    tail_temp_heat,
}

local button_properties = {
    tail_temp_signal_control_1,
    tail_temp_signal_control_2,
    lamp_test_eng_up_1,
    lamp_test_eng_up_2,
}

local function read_property_states(properties)
    local states = {}

    for index = 1, #properties do
        states[index] = get(properties[index])
    end

    return states
end

local function update_property_sound(properties, states, sample)
    local changed = false

    for index = 1, #properties do
        local current_value = get(properties[index])

        if current_value ~= states[index] then
            changed = true
        end

        states[index] = current_value
    end

    if changed then
        sasl.al.playSample(sample, false)
    end
end

local switch_states = read_property_states(switch_properties)
local button_states = read_property_states(button_properties)

local water_level = get(water_lvl)
local initialization_pending = true
local initialization_elapsed = 0
local press_act = 0

local function can_write_shared_state()
    -- SmartCopilot: 0 = plugin absent, 1 = slave, 2 = master.
    return get(ismaster) ~= 1
end

local function engines_are_stopped()
    return get(eng1_N1) < ENGINE_STOPPED_N1
        and get(eng2_N1) < ENGINE_STOPPED_N1
        and get(eng3_N1) < ENGINE_STOPPED_N1
end

local function initialize_water_level(dt)
    if not initialization_pending then
        return false
    end

    initialization_elapsed = initialization_elapsed + dt

    if initialization_elapsed <= INITIALIZATION_DELAY then
        water_level = get(water_lvl)
        return false
    end

    if can_write_shared_state() then
        -- Cold and dark retains the original randomized fill level.
        -- Any non-cold-and-dark start always begins with a full water tank.
        water_level = engines_are_stopped() and math.random() or WATER_MAX
        set(water_lvl, water_level)
    else
        water_level = get(water_lvl)
    end

    initialization_pending = false
    return true
end

local function update_controls()
    update_property_sound(switch_properties, switch_states, switch_sound)
    update_property_sound(button_properties, button_states, button_sound)
end

local function update_water_level(dt)
    local initialized_this_frame = initialize_water_level(dt)

    if initialization_pending or initialized_this_frame then
        return
    end

    if not can_write_shared_state() then
        water_level = get(water_lvl)
        return
    end

    local compressor_1 = get(water_compressor_1)
    local compressor_2 = get(water_compressor_2)
    local compressor_sum = compressor_1 + compressor_2

    local gear_retracted = get(deploy_ratio_1) < GEAR_RETRACTED_THRESHOLD
        and get(deploy_ratio_2) < GEAR_RETRACTED_THRESHOLD
        and get(deploy_ratio_3) < GEAR_RETRACTED_THRESHOLD

    if gear_retracted then
        water_level = water_level - dt * compressor_sum / WATER_CONSUMPTION_TIME
    elseif get(groundspeed) < GROUND_STOPPED_SPEED then
        water_level = water_level + dt / WATER_REFILL_TIME
    end

    if water_level < WATER_MIN then
        water_level = WATER_MIN
    elseif water_level > WATER_MAX then
        water_level = WATER_MAX
    end

    set(water_lvl, water_level)
end

local function update_lamps()
    local bus_left = get(bus27_volt_left)
    local bus_right = get(bus27_volt_right)
    local lamps_brt = math.max((math.max(bus_right, bus_left) - 10) / 18.5, 0)
    local right_bus_brt = math.max((bus_right - 10) / 18.5, 0)

    local test_btn_1 = get(lamp_test_eng_up_1) * right_bus_brt
    local test_btn_2 = get(lamp_test_eng_up_2) * right_bus_brt
    local level_meter = get(water_meter) == 1

    local level_full = math.max(
        bool2int(water_level >= 0.9 and level_meter) * lamps_brt,
        test_btn_1,
        test_btn_2
    )
    set(water_level_1, level_full)

    local level_half = math.max(
        bool2int(water_level < 0.9 and water_level >= 0.5 and level_meter) * lamps_brt,
        test_btn_1,
        test_btn_2
    )
    set(water_level_12, level_half)

    local level_quarter = math.max(
        bool2int(water_level < 0.5 and water_level >= 0.25 and level_meter) * lamps_brt,
        test_btn_1,
        test_btn_2
    )
    set(water_level_14, level_quarter)

    local level_empty = math.max(
        bool2int(water_level < 0.25 and water_level >= WATER_MIN and level_meter) * lamps_brt,
        test_btn_1,
        test_btn_2
    )
    set(water_level_0, level_empty)

    local tail_test_pressed = get(tail_temp_signal_control_1) + get(tail_temp_signal_control_2) > 0
    local tail_temp_high_brt = math.max(
        bool2int(tail_test_pressed) * get(tail_temp_signal) * lamps_brt,
        test_btn_1
    )
    set(tail_temp_high, tail_temp_high_brt)

    local lavatory_heat_brt = math.max(
        bool2int(get(lavatory_heat) < 0) * lamps_brt,
        test_btn_1
    )
    set(lavatory_heat_lamp, lavatory_heat_brt)

    local galley_heat_brt = math.max(
        bool2int(get(galley_heat) < 0) * lamps_brt,
        test_btn_1
    )
    set(galley_heat_lamp, galley_heat_brt)
end

local function update_water_pressure(dt)
    local bus_left = get(bus27_volt_left)
    local bus_right = get(bus27_volt_right)
    local powered = (bus_right + bus_left) / 2 > MIN_DC_VOLTAGE
    local target_pressure = 0

    if powered then
        local compressor_sum = get(water_compressor_1) + get(water_compressor_2)
        target_pressure = compressor_sum
            * bool2int(water_level > WATER_PRESSURE_MIN_LEVEL)
            * WATER_PRESSURE_PER_COMPRESSOR
    end

    press_act = press_act + (target_pressure - press_act) * dt
    set(water_pressure, press_act)
end

function update()
    local dt = get(frame_time)

    update_controls()
    update_water_level(dt)
    update_lamps()
    update_water_pressure(dt)
end
