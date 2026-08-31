local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

-- Cockpit ventilator animation and sound calculations

defineProps({
    -- Ventilator animation
    {"vent_1", "tu154/custom/anim/cockpit_vent_1", globalPropertyf},
    {"vent_2", "tu154/custom/anim/cockpit_vent_2", globalPropertyf},
    {"vent_3", "tu154/custom/anim/cockpit_vent_3", globalPropertyf},

    -- Overhead controls
    {"vent_1_sw", "tu154/custom/switchers/ovhd/vent_1", globalPropertyi},
    {"vent_2_sw", "tu154/custom/switchers/ovhd/vent_2", globalPropertyi},
    {"vent_3_sw", "tu154/custom/switchers/ovhd/vent_3", globalPropertyi},

    -- Electrical
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},

    -- Timing and view
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"view_is_external", "sim/graphics/view/view_is_external", globalPropertyi},

    -- X-Plane sound settings
    {"fan_volume_ratio", "sim/operation/sound/fan_volume_ratio", globalPropertyf},
})

local FAN_ACCELERATION = 500
local FAN_DECELERATION = 100
local FAN_MAX_SPEED = 1500
local FAN_POWER_THRESHOLD = 13
local SAMPLE_MAX_GAIN = 1000

local vent1_sound = sasl.al.loadSample("Custom Sounds/cockpit_fan.wav")
local vent2_sound = sasl.al.loadSample("Custom Sounds/cockpit_fan.wav")
local vent3_sound = sasl.al.loadSample("Custom Sounds/cockpit_fan.wav")

local fans = {
    {
        angle = vent_1,
        switch = vent_1_sw,
        sound = vent1_sound,
        speed = 0,
    },
    {
        angle = vent_2,
        switch = vent_2_sw,
        sound = vent2_sound,
        speed = 0,
    },
    {
        angle = vent_3,
        switch = vent_3_sw,
        sound = vent3_sound,
        speed = 0,
    },
}

for index = 1, #fans do
    sasl.al.playSample(fans[index].sound, true)
    sasl.al.setSampleGain(fans[index].sound, 0)
end

local function updateFan(fan, dt, powered, inside_cockpit, fan_volume)
    if powered and get(fan.switch) == 1 then
        fan.speed = fan.speed + FAN_ACCELERATION * dt
    else
        fan.speed = fan.speed - FAN_DECELERATION * dt
    end

    if fan.speed > FAN_MAX_SPEED then
        fan.speed = FAN_MAX_SPEED
    elseif fan.speed < 0 then
        fan.speed = 0
    end

    local angle = get(fan.angle) + fan.speed * dt

    while angle > 360 do
        angle = angle - 360
    end

    set(fan.angle, angle)

    local gain = 0

    if inside_cockpit then
        gain = math.min(fan.speed * 10, SAMPLE_MAX_GAIN) * fan_volume
    end

    sasl.al.setSampleGain(fan.sound, gain)
    sasl.al.setSamplePitch(fan.sound, fan.speed)
end

function update()
    local dt = get(frame_time)

    local bus_left = get(bus27_volt_left)
    local bus_right = get(bus27_volt_right)
    local powered = bus_left > FAN_POWER_THRESHOLD or bus_right > FAN_POWER_THRESHOLD

    local inside_cockpit = get(view_is_external) == 0
    local fan_volume = get(fan_volume_ratio)

    for index = 1, #fans do
        updateFan(fans[index], dt, powered, inside_cockpit, fan_volume)
    end
end
