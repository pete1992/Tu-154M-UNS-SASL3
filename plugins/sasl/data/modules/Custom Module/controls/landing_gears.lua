-- landing_gears.lua
-- Tu-154M landing gear extension/retraction logic.
--
-- Changelog
-- - Migrated all active DataRef bindings to the shared defineProps() table.
-- - Preserved generic globalProperty() bindings for indexed X-Plane gear arrays.
-- - Removed unused DataRef bindings and dead local variables.
-- - Removed obsolete commented-out code and unreadable legacy comment blocks.
-- - Cached frequently used DataRef values once per frame.
-- - Reduced repeated calculations and duplicate simulator gear-handle writes.
-- - Made boolean expressions and gear-lock logic explicit without changing behavior.
-- - Preserved the existing SmartCopilot master/slave synchronization logic.
-- - Preserved the existing gear timing, hydraulic coefficients, failures, sounds,
--   emergency extension behavior, and startup/reset behavior.
-- - Corrected the legacy main-gear aerodynamic calculation so each main gear
--   uses its own deployment position instead of the nose-gear position.
-- - Verified the retraction ground interlock remains tied to X-Plane gear index 1,
--   which represents the right main gear in this aircraft.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end


defineProps({
    -- Hydraulics
    {"gs_press_1", "tu154/custom/hydro/gs_press_1", globalPropertyf},
    {"gs_press_2", "tu154/custom/hydro/gs_press_2", globalPropertyf},
    {"gs_press_3", "tu154/custom/hydro/gs_press_3", globalPropertyf},
    -- Controls
    {"gears_retr_lock", "tu154/custom/switchers/gears_retr_lock", globalPropertyi},
    {"gears_ext_3GS", "tu154/custom/switchers/gears_ext_3GS", globalPropertyi},
    {"emerg_gear_ext", "tu154/custom/controll/emerg_gear_ext", globalPropertyi},
    {"gear_lever", "tu154/custom/controll/gear_lever", globalPropertyi},
    -- X-Plane gear arrays
    -- Keep generic indexed bindings: these are the known-working compatibility path.
    -- Aircraft mapping: [0] nose, [1] right main, [2] left main.
    -- The real Tu-154 ground retraction interlock is actuated by the right main strut.
    {"gear2_deflect", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalProperty},
    {"gear1_deploy", "sim/aircraft/parts/acf_gear_deploy[0]", globalProperty},
    {"gear2_deploy", "sim/aircraft/parts/acf_gear_deploy[1]", globalProperty},
    {"gear3_deploy", "sim/aircraft/parts/acf_gear_deploy[2]", globalProperty},
    -- Environment
    {"airspeed", "sim/flightmodel/position/indicated_airspeed", globalPropertyf},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"G", "sim/flightmodel2/misc/gforce_normal", globalPropertyf},
    {"total_time", "sim/time/total_flight_time_sec", globalPropertyf},
    {"agl", "sim/flightmodel/position/y_agl", globalPropertyf},
    -- Failures
    {"retract1_fail", "sim/operation/failures/rel_lagear1", globalPropertyi},
    {"retract2_fail", "sim/operation/failures/rel_lagear2", globalPropertyi},
    {"retract3_fail", "sim/operation/failures/rel_lagear3", globalPropertyi},
    {"actuator_fail", "sim/operation/failures/rel_gear_act", globalPropertyi},
    {"rel_wing1L", "sim/operation/failures/rel_wing1L", globalPropertyi},
    {"rel_wing1R", "sim/operation/failures/rel_wing1R", globalPropertyi},
    {"rel_collapse1", "sim/operation/failures/rel_collapse1", globalPropertyi},
    {"rel_collapse2", "sim/operation/failures/rel_collapse2", globalPropertyi},
    {"rel_collapse3", "sim/operation/failures/rel_collapse3", globalPropertyi},
    -- Electrical power
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
    -- Simulator gear handle
    {"gear_handle_1", "sim/cockpit/switches/gear_handle_status", globalPropertyi},
    {"gear_handle_2", "sim/cockpit2/controls/gear_handle_down", globalPropertyi},
    -- SmartCopilot
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

local lock_sound = sasl.al.loadSample("Custom Sounds/gear_lock.wav")
local handle_sound = sasl.al.loadSample("Custom Sounds/geal_lvr.wav")
local gear_command_up = sasl.findCommand("sim/flight_controls/landing_gear_up")
local gear_command_down = sasl.findCommand("sim/flight_controls/landing_gear_down")
local gear_toggle = sasl.findCommand("sim/flight_controls/landing_gear_toggle")

-- Gear movement constants.
local GEAR_SPEED_FRONT = 0.039
local GEAR_SPEED_LEFT = 0.039
local GEAR_SPEED_RIGHT = 0.039

local G_COEF_FRONT = 0.08
local G_COEF_MAIN = 0.08
local A_COEF_FRONT = 0.000025
local A_COEF_MAIN = 0.00003

local PI_OVER_3 = math.pi / 3
local PI_OVER_4 = math.pi / 4
local PI_OVER_5 = math.pi / 5

-- X-Plane uses a two-position handle while the Tu-154 uses three positions.
local function set_sim_gear_handle(down)
    local value = down and 1 or 0
    set(gear_handle_1, value)
    set(gear_handle_2, value)
end

local function is_gear_locked(direction, position)
    return (direction < 1 and position == 0)
        or (direction > -1 and position == 1)
end

local function gear_up_handler(phase)
    if phase == 0 then
        local lever = get(gear_lever)
        if lever > -1 then
            set(gear_lever, lever - 1)
        end
        set_sim_gear_handle(false)
    end
    return 0
end

local function gear_down_handler(phase)
    if phase == 0 then
        local lever = get(gear_lever)
        if lever < 1 then
            set(gear_lever, lever + 1)
        end
        set_sim_gear_handle(true)
    end
    return 0
end

local function gear_toggle_handler(phase)
    if phase == 0 then
        local lever = get(gear_lever)

        if lever ~= 0 then
            if lever == 1 then
                set_sim_gear_handle(true)
            elseif lever == -1 then
                set_sim_gear_handle(false)
            end
            lever = 0
        else
            local nose_gear_position = get(gear1_deploy)

            if nose_gear_position > 0.7 then
                lever = -1
                set_sim_gear_handle(false)
            elseif nose_gear_position < 0.3 then
                lever = 1
                set_sim_gear_handle(true)
            end
        end

        set(gear_lever, lever)
    end

    return 0
end

sasl.registerCommandHandler(gear_command_up, 0, gear_up_handler)
sasl.registerCommandHandler(gear_command_down, 0, gear_down_handler)
sasl.registerCommandHandler(gear_toggle, 0, gear_toggle_handler)

-- Start with all X-Plane gear deployment ratios extended.
set(gear1_deploy, 1)
set(gear2_deploy, 1)
set(gear3_deploy, 1)

local lock1 = true
local lock2 = true
local lock3 = true

local lock1_last = lock1
local lock2_last = lock2
local lock3_last = lock3

local pos1 = get(gear1_deploy)
local pos2 = get(gear2_deploy)
local pos3 = get(gear3_deploy)

if pos1 < 0.5 then
    pos1 = 0
    lock1 = true
elseif pos1 > 0 then
    pos1 = 1
end

if pos2 < 0.5 then
    pos2 = 0
    lock2 = true
elseif pos2 > 0 then
    pos2 = 1
end

if pos3 < 0.5 then
    pos3 = 0
    lock3 = true
elseif pos3 > 0 then
    pos3 = 1
end

local pos1_last = pos1
local pos2_last = pos2
local pos3_last = pos3

local lever_last = get(gear_lever)

function update()
    local total_flight_time = get(total_time)
    local height_agl = get(agl)

    -- Initial gear state follows whether the aircraft starts on the ground or airborne.
    if total_flight_time < 5 then
        if height_agl < 50 then
            pos1 = 1
            pos2 = 1
            pos3 = 1
        else
            pos1 = 0
            pos2 = 0
            pos3 = 0
        end
    end

    local dt = get(frame_time)
    if dt <= 0 then
        return
    end

    -- SmartCopilot: 0 = plugin unavailable, 1 = slave, 2 = master.
    local is_master = get(ismaster) ~= 1

    -- Cache hydraulic and electrical states once per frame.
    local main_hydro = math.min(get(gs_press_1) / 100, 1)
    local main_hydro_2 = math.min(get(gs_press_2) / 100, 1)
    local aux_hydro = math.min(get(gs_press_3) / 100, 1)

    local power_left = bool2int(get(bus27_volt_left) > 13)
    local power_right = bool2int(get(bus27_volt_right) > 13)

    local gs_in_use = get(gears_ext_3GS)
    local emergency_extension = get(emerg_gear_ext)

    local lever = get(gear_lever)
    if get(actuator_fail) == 6 then
        lever = 0
    end

    local indicated_airspeed = get(airspeed)
    local ias_sq = indicated_airspeed * indicated_airspeed
    local g_force = get(G)

    -- Ground retraction interlock:
    -- gear index 1 is the right main gear. Retraction is enabled when the
    -- right main strut is unloaded, or when the cockpit unlock switch is used.
    local retract_allowed =
        get(gear2_deflect) < 0.01
        or get(gears_retr_lock) ~= 0

    -- Select the normal or third hydraulic system, plus emergency extension.
    local direction =
        lever * main_hydro * power_left * (1 - gs_in_use) * 2
        + lever * aux_hydro * power_right * gs_in_use * 1.3
        + emergency_extension * main_hydro_2 * 1.3

    if lever == -1 then
        set_sim_gear_handle(false)
    elseif lever == 1 then
        set_sim_gear_handle(true)
    end

    if lever ~= lever_last then
        sasl.al.playSample(handle_sound, false)
    end
    lever_last = lever

    local gear_move = bool2int(
        power_left * (1 - gs_in_use) == 1
        or power_right * gs_in_use == 1
    )

    local front_retract_ok = get(retract1_fail) < 6
    local right_retract_ok = get(retract2_fail) < 6
    local left_retract_ok = get(retract3_fail) < 6

    -- Nose gear.
    if not lock1 and retract_allowed then
        pos1 = pos1_last
            + GEAR_SPEED_FRONT
            * (
                direction * bool2int(front_retract_ok)
                + g_force * (math.cos(PI_OVER_4 * pos1_last) + 0.2) * G_COEF_FRONT
                - ias_sq * math.sin(PI_OVER_3 * pos1_last) * A_COEF_FRONT
            )
            * dt
            * gear_move
    end

    -- Right main gear (X-Plane gear index 1).
    if not lock2 and retract_allowed then
        pos2 = pos2_last
            + GEAR_SPEED_RIGHT
            * (
                direction * bool2int(right_retract_ok)
                + g_force * (math.cos(PI_OVER_5 * pos2_last) + 0.3) * G_COEF_MAIN
                - ias_sq * math.sin(PI_OVER_5 * pos2_last) * A_COEF_MAIN
            )
            * dt
            * gear_move
    end

    -- Left main gear (X-Plane gear index 2).
    if not lock3 and retract_allowed then
        pos3 = pos3_last
            + GEAR_SPEED_LEFT
            * (
                direction * bool2int(left_retract_ok)
                + g_force * (math.cos(PI_OVER_5 * pos3_last) + 0.3) * G_COEF_MAIN
                - ias_sq * math.sin(PI_OVER_5 * pos3_last) * A_COEF_MAIN
            )
            * dt
            * gear_move
    end

    pos1 = clamp(pos1, 0, 1)
    pos2 = clamp(pos2, 0, 1)
    pos3 = clamp(pos3, 0, 1)

    lock1 = is_gear_locked(direction, pos1)
    lock2 = is_gear_locked(direction, pos2)
    lock3 = is_gear_locked(direction, pos3)

    -- Emergency extension unlocks any gear that has not yet reached downlock.
    if emergency_extension == 1 then
        if pos1 < 0.9 then lock1 = false end
        if pos2 < 0.9 then lock2 = false end
        if pos3 < 0.9 then lock3 = false end

        if pos1 > 0.99 then
            lock1 = true
            pos1 = 1
        end
        if pos2 > 0.99 then
            lock2 = true
            pos2 = 1
        end
        if pos3 > 0.99 then
            lock3 = true
            pos3 = 1
        end
    end

    -- Preserve the original behavior: only the nose-gear lock transition plays this sound.
    if lock1_last ~= lock1 then
        sasl.al.playSample(lock_sound, false)
    end

    -- Gear collapse failures.
    if get(rel_collapse1) == 6 then pos1 = 0.1 end
    if get(rel_collapse2) == 6 then pos2 = 0.1 end
    if get(rel_collapse3) == 6 then pos3 = 0.1 end

    -- Wing separation removes the corresponding main gear.
    if get(rel_wing1L) == 6 then pos3 = 0 end
    if get(rel_wing1R) == 6 then pos2 = 0 end

    if is_master then
        set(gear1_deploy, pos1)
        set(gear2_deploy, pos2)
        set(gear3_deploy, pos3)
    else
        -- Slave reads synchronized deployment ratios from X-Plane.
        pos1 = get(gear1_deploy)
        pos2 = get(gear2_deploy)
        pos3 = get(gear3_deploy)
    end

    pos1_last = pos1
    pos2_last = pos2
    pos3_last = pos3

    lock1_last = lock1
    lock2_last = lock2
    lock3_last = lock3
end

function onModuleDone()
    set(gear1_deploy, 1)
    set(gear2_deploy, 1)
    set(gear3_deploy, 1)
    print("gears reset to extended")
end
