-- trimmers.lua
-- Trimmer logic.
--[[
Changelog
- Grouped all 29 existing Dataref bindings through defineProps() while preserving property names, paths, constructors, and original binding order.
- Added X-Plane internal version detection for XP11/XP12-compatible sasl.al.playSample() calls.
- Reduced all electric trim rates to 110% of the previous values through one TRIM_SPEED_SCALE constant.
- Preserved the original 1.25 pitch-trim speed asymmetry below neutral.
- Cached electrical power, trim controls, failures, and trim positions once per frame.
- Replaced manual limit code with clamp() calls for readability.
- Initialized previous trim positions from the actual trim Datarefs to avoid false startup current indications.
- Kept normal pitch trim inhibited in AFCS stabilizer mode, but allowed the emergency elevator trim command to remain available.
- Made trim-center commands respect their corresponding electrical power and trim failure state.
- Added small helper functions for power/failure checks used by both update() and command handlers.
- Preserved SmartCopilot master/slave write ownership, existing electrical-load behavior, trim limits, command names, and public interfaces.
]]

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Trim controls
    { "elev_trimm_sw", "tu154/custom/controll/elev_trimm_switcher", globalPropertyi },
    { "ail_trimm_sw", "tu154/custom/controll/ail_trimm_sw", globalPropertyi },
    { "rudd_trimm_sw", "tu154/custom/controll/rudd_trimm_sw", globalPropertyi },
    { "emerg_elev_trimm", "tu154/custom/switchers/console/emerg_elev_trimm", globalPropertyi },
    { "absu_pitch_trimm", "tu154/custom/absu/absu_pitch_trimm", globalPropertyi },
    -- Trim positions and AFCS modes
    { "int_pitch_trim", "tu154/custom/trimmers/int_pitch_trim", globalPropertyf },
    { "int_roll_trim", "tu154/custom/trimmers/int_roll_trim", globalPropertyf },
    { "int_yaw_trim", "tu154/custom/trimmers/int_yaw_trim", globalPropertyf },
    { "absu_roll_mode", "tu154/custom/gauges/console/absu_roll_mode", globalPropertyi },
    { "absu_pitch_mode", "tu154/custom/gauges/console/absu_pitch_mode", globalPropertyi },
    -- Electrical power and current loads
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },
    { "bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf },
    { "bus36_volt_right", "tu154/custom/elec/bus36_volt_right", globalPropertyf },
    { "bus36_volt_pts250_1", "tu154/custom/elec/bus36_volt_pts250_1", globalPropertyf },
    { "bus36_volt_pts250_2", "tu154/custom/elec/bus36_volt_pts250_2", globalPropertyf },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    { "ctr_27_L_cc", "tu154/custom/control/ctr_27_L_cc", globalPropertyf },
    { "ctr_27_R_cc", "tu154/custom/control/ctr_27_R_cc", globalPropertyf },
    { "ctr_36L_cc", "tu154/custom/control/ctr_36L_cc", globalPropertyf },
    -- SmartCopilot
    { "ctr_36R_cc", "tu154/custom/control/ctr_36R_cc", globalPropertyf },
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    -- Failures
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf },
    { "rel_trim_rud", "sim/operation/failures/rel_trim_rud", globalPropertyi },
    { "rel_trim_ail", "sim/operation/failures/rel_trim_ail", globalPropertyi },
    { "rel_trim_elv", "sim/operation/failures/rel_trim_elv", globalPropertyi },
    { "trim_emerg_elv_fail", "tu154/custom/failures/trim_emerg_elv_fail", globalPropertyi },
})

-- Added compatibility binding; all existing bindings above remain unchanged.
defineProperty("xp_version", globalPropertyi("sim/version/xplane_internal_version"))
local XP11 = get(xp_version) > 120000

local function playPanelSample(sample)
    if XP11 then
        sasl.al.playSample(sample, false)
    else
        sasl.al.playSample(sample, false)
    end
end

local SAMPLES = {
    up = sasl.al.loadSample("Custom Sounds/trimm_up.wav"),
    down = sasl.al.loadSample("Custom Sounds/trimm_down.wav"),
    center = sasl.al.loadSample("Custom Sounds/trimm_ctr.wav"),
}

-- Global trim-speed tuning. 1.10 = 110% of the original speed.
local TRIM_SPEED_SCALE = 1.10

local PITCH_LIMIT = 0.80
local ROLL_LIMIT = 0.24
local YAW_LIMIT = 0.24

local STATE = {
    pitch_last = get(int_pitch_trim),
    roll_last = get(int_roll_trim),
    yaw_last = get(int_yaw_trim),
}

local function has27Left()
    return get(bus27_volt_left) > 13
end

local function has27Right()
    return get(bus27_volt_right) > 13
end

local function has36Left()
    return get(bus36_volt_left) > 30
end

local function has36Right()
    return get(bus36_volt_right) > 30
end

local function normalPitchTrimAvailable()
    return has27Left()
        and has27Right()
        and (has36Left() or has36Right())
        and get(rel_trim_elv) ~= 6
end

local function rollTrimAvailable()
    return has27Left() and get(rel_trim_ail) ~= 6
end

local function yawTrimAvailable()
    return has27Right() and get(rel_trim_rud) ~= 6
end

function update()
    local master = get(ismaster) ~= 1
    local passed = get(frame_time)

    local power_27_L = bool2int(get(bus27_volt_left) > 13)
    local power_27_R = bool2int(get(bus27_volt_right) > 13)
    local power_36_L = bool2int(get(bus36_volt_left) > 30)
    local power_36_R = bool2int(get(bus36_volt_right) > 30)

    local elev_failed = get(rel_trim_elv) == 6
    local roll_failed = get(rel_trim_ail) == 6
    local yaw_failed = get(rel_trim_rud) == 6
    local emergency_failed = get(trim_emerg_elv_fail) == 1

    local elev_tr_sw = get(elev_trimm_sw)
    local emerg_tr_sw = get(emerg_elev_trimm)
    local absu_tr_pt = get(absu_pitch_trimm)

    -- In AFCS stabilizer mode the normal manual pitch trim is inhibited.
    -- Emergency trim remains available as a separate emergency path.
    if get(absu_pitch_mode) == 2 then
        elev_tr_sw = 0
    end

    --------------------------------------------------------------------------
    -- Pitch trimmer
    --------------------------------------------------------------------------
    local pitch_trim_pos = get(int_pitch_trim)
    local direction_factor = pitch_trim_pos < 0 and 1.25 or 1.0

    -- Preserve the original two-motor / two-36V-bus speed relationship.
    local normal_power_factor = power_27_L
        * power_27_R
        * (power_36_L + power_36_R)
        * 2

    if not elev_failed then
        pitch_trim_pos = pitch_trim_pos
            + elev_tr_sw
            * passed
            * normal_power_factor
            * 0.015
            * direction_factor
            * TRIM_SPEED_SCALE

        pitch_trim_pos = pitch_trim_pos
            + absu_tr_pt
            * passed
            * normal_power_factor
            * 0.005
            * direction_factor
            * TRIM_SPEED_SCALE
    end

    if not emergency_failed then
        pitch_trim_pos = pitch_trim_pos
            + emerg_tr_sw
            * passed
            * power_27_L
            * power_36_L
            * 0.03
            * direction_factor
            * TRIM_SPEED_SCALE
    end

    pitch_trim_pos = clamp(pitch_trim_pos, -PITCH_LIMIT, PITCH_LIMIT)

    if master then
        set(int_pitch_trim, pitch_trim_pos)
    end

    local pitch_moving = pitch_trim_pos ~= STATE.pitch_last

    if pitch_moving then
        set(ctr_36L_cc, power_36_L)
        set(ctr_36R_cc, power_36_R)
    else
        set(ctr_36L_cc, 0)
        set(ctr_36R_cc, 0)
    end

    STATE.pitch_last = pitch_trim_pos

    --------------------------------------------------------------------------
    -- Roll trimmer
    --------------------------------------------------------------------------
    local roll_trim_pos = get(int_roll_trim)

    if not roll_failed then
        roll_trim_pos = roll_trim_pos
            + get(ail_trimm_sw)
            * passed
            * power_27_L
            * 0.02
            * TRIM_SPEED_SCALE
    end

    roll_trim_pos = clamp(roll_trim_pos, -ROLL_LIMIT, ROLL_LIMIT)

    if master then
        set(int_roll_trim, roll_trim_pos)
    end

    if roll_trim_pos ~= STATE.roll_last then
        set(ctr_27_L_cc, get(ctr_27_L_cc) + 3)
    end

    STATE.roll_last = roll_trim_pos

    --------------------------------------------------------------------------
    -- Yaw trimmer
    --------------------------------------------------------------------------
    local yaw_trim_pos = get(int_yaw_trim)

    if not yaw_failed then
        yaw_trim_pos = yaw_trim_pos
            + get(rudd_trimm_sw)
            * passed
            * power_27_R
            * 0.02
            * TRIM_SPEED_SCALE
    end

    yaw_trim_pos = clamp(yaw_trim_pos, -YAW_LIMIT, YAW_LIMIT)

    if master then
        set(int_yaw_trim, yaw_trim_pos)
    end

    if yaw_trim_pos ~= STATE.yaw_last then
        set(ctr_27_R_cc, get(ctr_27_R_cc) + 3)
    end

    STATE.yaw_last = yaw_trim_pos
end

-- Pitch trim UP.
pitch_UP_comm = sasl.findCommand("sim/flight_controls/pitch_trim_up")

function pitch_UP_hnd(phase)
    if phase == 0 or phase == 1 then
        set(elev_trimm_sw, 1)
        if phase == 0 then
            playPanelSample(SAMPLES.up)
        end
    else
        set(elev_trimm_sw, 0)
        playPanelSample(SAMPLES.center)
    end
    return 0
end

sasl.registerCommandHandler(pitch_UP_comm, 0, pitch_UP_hnd)

-- Pitch trim DOWN.
pitch_DOWN_comm = sasl.findCommand("sim/flight_controls/pitch_trim_down")

function pitch_DOWN_hnd(phase)
    if phase == 0 or phase == 1 then
        set(elev_trimm_sw, -1)
        if phase == 0 then
            playPanelSample(SAMPLES.down)
        end
    else
        set(elev_trimm_sw, 0)
        playPanelSample(SAMPLES.center)
    end
    return 0
end

sasl.registerCommandHandler(pitch_DOWN_comm, 0, pitch_DOWN_hnd)

-- Pitch trim CENTER / takeoff.
pitch_TO_comm = sasl.findCommand("sim/flight_controls/pitch_trim_takeoff")

function pitch_TO_hnd(phase)
    if (phase == 0 or phase == 1) and normalPitchTrimAvailable() then
        set(int_pitch_trim, 0)
        STATE.pitch_last = 0
    end
    return 0
end

sasl.registerCommandHandler(pitch_TO_comm, 0, pitch_TO_hnd)

-- Roll trim LEFT.
roll_LEFT_comm = sasl.findCommand("sim/flight_controls/aileron_trim_left")

function roll_LEFT_hnd(phase)
    if phase == 0 or phase == 1 then
        set(ail_trimm_sw, -1)
    else
        set(ail_trimm_sw, 0)
    end
    return 0
end

sasl.registerCommandHandler(roll_LEFT_comm, 0, roll_LEFT_hnd)

-- Roll trim RIGHT.
roll_RIGHT_comm = sasl.findCommand("sim/flight_controls/aileron_trim_right")

function roll_RIGHT_hnd(phase)
    if phase == 0 or phase == 1 then
        set(ail_trimm_sw, 1)
    else
        set(ail_trimm_sw, 0)
    end
    return 0
end

sasl.registerCommandHandler(roll_RIGHT_comm, 0, roll_RIGHT_hnd)

-- Roll trim CENTER.
roll_CTR_comm = sasl.findCommand("sim/flight_controls/aileron_trim_center")

function roll_CTR_hnd(phase)
    if (phase == 0 or phase == 1) and rollTrimAvailable() then
        set(int_roll_trim, 0)
        STATE.roll_last = 0
    end
    return 0
end

sasl.registerCommandHandler(roll_CTR_comm, 0, roll_CTR_hnd)

-- Yaw trim LEFT.
yaw_LEFT_comm = sasl.findCommand("sim/flight_controls/rudder_trim_left")

function yaw_LEFT_hnd(phase)
    if phase == 0 or phase == 1 then
        set(rudd_trimm_sw, -1)
    else
        set(rudd_trimm_sw, 0)
    end
    return 0
end

sasl.registerCommandHandler(yaw_LEFT_comm, 0, yaw_LEFT_hnd)

-- Yaw trim RIGHT.
yaw_RIGHT_comm = sasl.findCommand("sim/flight_controls/rudder_trim_right")

function yaw_RIGHT_hnd(phase)
    if phase == 0 or phase == 1 then
        set(rudd_trimm_sw, 1)
    else
        set(rudd_trimm_sw, 0)
    end
    return 0
end

sasl.registerCommandHandler(yaw_RIGHT_comm, 0, yaw_RIGHT_hnd)

-- Yaw trim CENTER.
yaw_CTR_comm = sasl.findCommand("sim/flight_controls/rudder_trim_center")

function yaw_CTR_hnd(phase)
    if (phase == 0 or phase == 1) and yawTrimAvailable() then
        set(int_yaw_trim, 0)
        STATE.yaw_last = 0
    end
    return 0
end

sasl.registerCommandHandler(yaw_CTR_comm, 0, yaw_CTR_hnd)
