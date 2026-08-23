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
-- - Fixed the ground retraction interlock so it blocks retraction only, not extension.
-- - Fixed gear-lock release logic so it depends on movement direction instead of
--   requiring an arbitrary hydraulic coefficient of at least 1.0.
-- - Restored the fake-command bridge required to map X-Plane's two-position gear
--   commands to the Tu-154 three-position UP/NEUTRAL/DOWN gear lever.
-- - Restored the Tu-154 emergency gear-extension architecture:
--   hydraulic system 1 = normal extension/retraction, hydraulic system 2 =
--   emergency extension, hydraulic system 3 = backup emergency extension.
-- - Emergency extension from hydraulic system 2 is operated by the mechanical
--   emergency handle and therefore does not require 27 V electrical power.
-- - Backup emergency extension from hydraulic system 3 requires the right 27 V
--   bus, the main gear lever in NEUTRAL, and the system-2 emergency handle stowed.
-- - Emergency circuits are extension-only and bypass the normal gear actuator failure.
-- - Corrected X-Plane rel_lagear1/2/3 handling: these are retraction failures and
--   therefore no longer inhibit normal or emergency extension.
-- - Neutral now stops gear motion instead of allowing the gravity/aerodynamic terms
--   to continue moving an unlocked gear with no hydraulic circuit selected.

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

-- X-Plane has no neutral gear-handle position. When a simulator UP/DOWN command
-- moves the Tu-154 lever only one detent to NEUTRAL, a corrective opposite
-- simulator command restores X-Plane's binary handle to its previous state.
-- The guard prevents that internally generated command from moving the Tu-154
-- lever a second time.
local fake_command = false

local function run_fake_command(command)
    fake_command = true
    sasl.commandOnce(command)
    fake_command = false
end

local function is_gear_locked(direction, position)
    -- At either end stop, keep the gear locked unless hydraulic movement is
    -- commanded away from that stop.  The lock release depends on direction,
    -- not on an arbitrary minimum magnitude of the hydraulic coefficient.
    return (direction <= 0 and position <= 0)
        or (direction >= 0 and position >= 1)
end

local function gear_up_handler(phase)
    if phase == SASL_COMMAND_BEGIN then
        -- Fake commands are only used to correct X-Plane's binary gear handle.
        -- They must never advance the Tu-154 three-position lever.
        if fake_command then
            return 0
        end

        local lever = get(gear_lever)

        if lever == 1 then
            -- DOWN -> NEUTRAL. X-Plane has already processed the UP command, so
            -- restore its binary handle to DOWN while Tu-154 remains neutral.
            set(gear_lever, 0)
            run_fake_command(gear_command_down)
        elseif lever == 0 then
            -- NEUTRAL -> UP. X-Plane's original UP command already left its
            -- binary handle in the correct state.
            set(gear_lever, -1)
        end
    end

    return 0
end

local function gear_down_handler(phase)
    if phase == SASL_COMMAND_BEGIN then
        if fake_command then
            return 0
        end

        local lever = get(gear_lever)

        if lever == -1 then
            -- UP -> NEUTRAL. X-Plane has already processed the DOWN command, so
            -- restore its binary handle to UP while Tu-154 remains neutral.
            set(gear_lever, 0)
            run_fake_command(gear_command_up)
        elseif lever == 0 then
            -- NEUTRAL -> DOWN. X-Plane's original DOWN command already left its
            -- binary handle in the correct state.
            set(gear_lever, 1)
        end
    end

    return 0
end

local function gear_toggle_handler(phase)
    if phase == SASL_COMMAND_BEGIN then
        if fake_command then
            return 0
        end

        local lever = get(gear_lever)

        if lever == 1 then
            -- DOWN -> NEUTRAL. The simulator toggle has already selected UP;
            -- restore DOWN because neutral must not command retraction.
            set(gear_lever, 0)
            run_fake_command(gear_command_down)

        elseif lever == -1 then
            -- UP -> NEUTRAL. The simulator toggle has already selected DOWN;
            -- restore UP because neutral must not command extension.
            set(gear_lever, 0)
            run_fake_command(gear_command_up)

        else
            -- From NEUTRAL, choose the next detent from actual gear position.
            -- For a gear stopped in mid-travel, keep NEUTRAL and undo X-Plane's
            -- binary toggle rather than inventing a direction.
            local nose_gear_position = get(gear1_deploy)

            if nose_gear_position > 0.7 then
                set(gear_lever, -1)
                if get(gear_handle_1) ~= 0 then
                    run_fake_command(gear_command_up)
                end
            elseif nose_gear_position < 0.3 then
                set(gear_lever, 1)
                if get(gear_handle_1) ~= 1 then
                    run_fake_command(gear_command_down)
                end
            else
                -- gear_handle_1 is already the post-toggle value here; execute
                -- the opposite command to restore the pre-toggle binary state.
                if get(gear_handle_1) == 1 then
                    run_fake_command(gear_command_up)
                else
                    run_fake_command(gear_command_down)
                end
            end
        end
    end

    return 0
end

-- These handlers intentionally run AFTER X-Plane (isBefore = 0). The simulator
-- first changes its two-position handle; the handler then maps that event onto
-- one Tu-154 lever detent and, when necessary, issues a guarded corrective command.
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

    -- Hydraulic pressure is expressed in kgf/cm2 in the Tu-154 custom system.
    -- Nominal pressure is about 210 kgf/cm2.  Keeping a pressure ratio here makes
    -- normal timing unchanged at nominal pressure while degraded pressure now
    -- correctly reduces gear-drive authority.
    local function hydraulic_ratio(pressure)
        return math.min(math.max(pressure / 210, 0), 1)
    end

    local hydro_1 = hydraulic_ratio(get(gs_press_1))
    local hydro_2 = hydraulic_ratio(get(gs_press_2))
    local hydro_3 = hydraulic_ratio(get(gs_press_3))

    local power_left = bool2int(get(bus27_volt_left) > 13)
    local power_right = bool2int(get(bus27_volt_right) > 13)

    local emergency_requested = get(emerg_gear_ext) == 1
    local backup_requested = get(gears_ext_3GS) ~= 0

    -- Keep the physical cockpit lever separate from the normal hydraulic command.
    -- rel_gear_act disables the normal selector/actuator path only; the independent
    -- emergency extension circuits must remain available.
    local lever = get(gear_lever)
    local normal_lever = lever
    if get(actuator_fail) == 6 then
        normal_lever = 0
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

    -- Tu-154 gear hydraulic routing:
    --   GS1: normal extension and retraction.
    --   GS2: emergency extension via the mechanical emergency handle.
    --   GS3: backup emergency extension via the electrically operated switch.
    --
    -- Both emergency procedures require the main gear lever in NEUTRAL.
    -- The GS3 backup procedure additionally requires the GS2 emergency handle
    -- to be returned to its initial/stowed position.
    local emergency_active = emergency_requested and lever == 0
    local backup_active =
        backup_requested
        and lever == 0
        and not emergency_requested
        and power_right == 1

    local direction = 0
    local gear_move = 0
    local emergency_release_active = false

    if emergency_active then
        -- Mechanical handle: no electrical-power requirement.
        -- The GS2 hydraulic pressure opens the emergency path and the uplocks.
        direction = hydro_2 * 1.3
        gear_move = bool2int(direction > 0.001)
        emergency_release_active = gear_move == 1

    elseif backup_active then
        -- Backup emergency extension is electrically selected and fed by GS3.
        direction = hydro_3 * 1.3
        gear_move = bool2int(direction > 0.001)
        emergency_release_active = gear_move == 1

    else
        -- Normal selector: GS1 supplies both extension and retraction.
        direction = normal_lever * hydro_1 * power_left * 2
        gear_move = bool2int(math.abs(direction) > 0.001)
    end

    -- The right-main ground interlock inhibits retraction only. Extension by
    -- any of the three hydraulic systems is never blocked by the ground lock.
    local movement_allowed = direction >= 0 or retract_allowed

    if lever == -1 then
        set_sim_gear_handle(false)
    elseif lever == 1 then
        set_sim_gear_handle(true)
    end

    if lever ~= lever_last then
        sasl.al.playSample(handle_sound, false)
    end
    lever_last = lever

    -- X-Plane documents rel_lagear1/2/3 as landing-gear RETRACTION failures.
    -- They therefore inhibit only negative-direction movement.
    local front_move_ok = direction >= 0 or get(retract1_fail) < 6
    local right_move_ok = direction >= 0 or get(retract2_fail) < 6
    local left_move_ok = direction >= 0 or get(retract3_fail) < 6

    -- Emergency and backup circuits have dedicated uplock-opening paths.
    -- Release the uplocks as soon as the selected emergency hydraulic circuit
    -- actually has pressure.  Downlocks are still engaged normally at full travel.
    if emergency_release_active then
        if pos1 < 0.999 then lock1 = false end
        if pos2 < 0.999 then lock2 = false end
        if pos3 < 0.999 then lock3 = false end
    end

    -- Nose gear.
    if not lock1 and movement_allowed and front_move_ok then
        pos1 = pos1_last
            + GEAR_SPEED_FRONT
            * (
                direction
                + g_force * (math.cos(PI_OVER_4 * pos1_last) + 0.2) * G_COEF_FRONT
                - ias_sq * math.sin(PI_OVER_3 * pos1_last) * A_COEF_FRONT
            )
            * dt
            * gear_move
    end

    -- Right main gear (X-Plane gear index 1).
    if not lock2 and movement_allowed and right_move_ok then
        pos2 = pos2_last
            + GEAR_SPEED_RIGHT
            * (
                direction
                + g_force * (math.cos(PI_OVER_5 * pos2_last) + 0.3) * G_COEF_MAIN
                - ias_sq * math.sin(PI_OVER_5 * pos2_last) * A_COEF_MAIN
            )
            * dt
            * gear_move
    end

    -- Left main gear (X-Plane gear index 2).
    if not lock3 and movement_allowed and left_move_ok then
        pos3 = pos3_last
            + GEAR_SPEED_LEFT
            * (
                direction
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

    -- When either emergency circuit is active, force a clean mechanical
    -- downlock once a leg reaches the end of travel.  The emergency system never
    -- commands retraction.
    if emergency_release_active then
        if pos1 >= 0.99 then
            lock1 = true
            pos1 = 1
        end
        if pos2 >= 0.99 then
            lock2 = true
            pos2 = 1
        end
        if pos3 >= 0.99 then
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
