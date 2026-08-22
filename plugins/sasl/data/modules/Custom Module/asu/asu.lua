-- TA-6A ground air-start unit (ASU) logic for Tu-154M.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    {"rpm", "tu154/custom/asu/rpm", globalPropertyf},
    {"air_press", "tu154/custom/asu/press", globalPropertyf},
    {"work", "tu154/custom/asu/work", globalPropertyi},
    {"sim_period", "sim/operation/misc/frame_rate_period", globalPropertyf},
    {"GS", "sim/flightmodel/position/groundspeed", globalPropertyf},
    {"show", "tu154/custom/anim/asu_show", globalPropertyf},
})

local MAX_FRAME_TIME = 0.2
local MAX_GROUND_SPEED = 0.1
local RUN_RPM = 100
local BLEED_RPM = 90
local RUN_PRESSURE = 3.8
local RPM_START_RATE = 0.1
local RPM_STOP_RATE = 1
local PRESSURE_START_RATE = 0.1
local PRESSURE_STOP_RATE = 1

local function approach(current, target, rate, passed)
    local factor = math.min(1, rate * passed)
    return current + (target - current) * factor
end

function update()
    local passed = tonumber(get(sim_period)) or 0
    passed = math.max(0, math.min(passed, MAX_FRAME_TIME))

    local requested = get(work) == 1
    local stationary = math.abs(tonumber(get(GS)) or 0) <= MAX_GROUND_SPEED

    if requested and stationary then
        set(show, 1)

        local next_rpm = approach(
            math.max(0, tonumber(get(rpm)) or 0),
            RUN_RPM,
            RPM_START_RATE,
            passed
        )

        if RUN_RPM - next_rpm < 0.01 then
            next_rpm = RUN_RPM
        end

        set(rpm, next_rpm)

        local target_pressure = 0
        local pressure_rate = PRESSURE_STOP_RATE

        if next_rpm > BLEED_RPM then
            target_pressure = RUN_PRESSURE
            pressure_rate = PRESSURE_START_RATE
        end

        local next_pressure = approach(
            math.max(0, tonumber(get(air_press)) or 0),
            target_pressure,
            pressure_rate,
            passed
        )

        set(air_press, next_pressure)
        return
    end

    -- The ASU must not remain commanded while the aircraft is moving.  Use
    -- absolute groundspeed so rolling backwards is handled as safely as
    -- rolling forwards.
    if requested then
        set(work, 0)
    end

    local next_rpm = approach(
        math.max(0, tonumber(get(rpm)) or 0),
        0,
        RPM_STOP_RATE,
        passed
    )
    local next_pressure = approach(
        math.max(0, tonumber(get(air_press)) or 0),
        0,
        PRESSURE_STOP_RATE,
        passed
    )

    if next_rpm < 0.1 then
        next_rpm = 0
    end

    if next_pressure < 0.01 then
        next_pressure = 0
    end

    set(rpm, next_rpm)
    set(air_press, next_pressure)
    set(show, (next_rpm > 0 or next_pressure > 0) and 1 or 0)
end
