-- nosewheel.lua
--[[
Changelog
- Added hydraulic-pressure-dependent steering rate.
- Added nose-strut-compression-dependent steering rate and ground detection.
- Added groundspeed influence on steering response.
- Added automatic steering centering as the nose strut unloads.
- Added X-Plane runway-condition influence using sim/weather/runway_friction.
- Preserved BetterPushback steering handoff: the script does not overwrite
  the steering command while pushback is connected and the aircraft
  nosewheel steering system is unpowered.
- Consolidated active DataRef bindings into defineProps().
- Preserved generic globalProperty() bindings for indexed X-Plane array
  DataRefs because these are the currently verified working bindings in
  this aircraft.
- Removed unused DataRefs and dead/commented-out legacy code.
- Kept SmartCopilot master/slave behavior and the existing nosewheel
  steering toggle command.
]]


local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end


-- Nosewheel steering limits.
local MAX_TILLER_ANGLE = 63
local MAX_RUDDER_ANGLE = 63
local NWS_LOW_ANGLE = 11

local NOMINAL_HYD_PRESS = 210
local MIN_DC_VOLTAGE = 13


defineProps({

    -- Aircraft controls and systems.
    {"nosewheel_turn_enable",
        "tu154/custom/switchers/nosewheel_turn_enable",
        globalPropertyi},
    {"nosewheel_turn_power",
        "tu154/custom/hydro/nosewheel_turn_power",
        globalPropertyi},
    {"nosewheel_turn_sel",
        "tu154/custom/switchers/nosewheel_turn_sel",
        globalPropertyi},
    {"bus27_volt_left",
        "tu154/custom/elec/bus27_volt_left",
        globalPropertyf},
    {"gs_press_2",
        "tu154/custom/hydro/gs_press_2",
        globalPropertyf},
    -- User-selected steering input from the 2D panel:
    -- 1 = Tiller
    -- 0 = Rudder/Yaw
    {"have_pedals",
        "tu154/custom/have_pedals",
        globalPropertyi},
    -- SmartCopilot / synchronized pilot inputs.
    {"tiller_val",
        "tu154/custom/SC/gear/tire_steer_command_deg",
        globalPropertyf},
    {"joy_yaw",
        "tu154/custom/SC/yoke_heading_ratio",
        globalPropertyf},
    {"ismaster",
        "scp/api/ismaster",
        globalPropertyf},
    -- X-Plane steering and gear state.
    {"tire_steer_command_deg",
        "sim/flightmodel2/gear/tire_steer_command_deg[0]",
        globalProperty},
    {"deflection_mtr_1",
        "sim/flightmodel2/gear/tire_vertical_deflection_mtr[0]",
        globalProperty},
    {"override_wheel_steer",
        "sim/operation/override/override_wheel_steer",
        globalPropertyi},
    {"lock",
        "sim/cockpit2/controls/nosewheel_steer_on",
        globalPropertyi},
    {"groundspeed",
        "sim/flightmodel/position/groundspeed",
        globalPropertyf},
    -- X-Plane runway condition:
    --   0     dry
    --   1-3   wet
    --   4-6   puddly
    --   7-9   snowy
    --   10-12 icy
    --   13-15 snowy/icy
    {"runway_friction",
        "sim/weather/runway_friction",
        globalPropertyf},
    -- X-Plane nosewheel steering limits.
    {"weel_angle1",
        "sim/aircraft/gear/acf_nw_steerdeg1",
        globalPropertyf},
    {"weel_angle2",
        "sim/aircraft/gear/acf_nw_steerdeg2",
        globalPropertyf},
    -- Animation and timing.
    {"tiller_angle",
        "tu154/custom/anim/tiller_pos",
        globalPropertyf},
    {"frame_time",
        "tu154/custom/time/frame_time",
        globalPropertyf},
    -- BetterPushback.
    {"pushback",
        "bp/connected",
        globalPropertyi},
})


-- Steering response factor versus X-Plane runway condition.
--
-- X-Plane values:
--   0     dry
--   1-3   wet
--   4-6   puddly
--   7-9   snowy
--   10-12 icy
--   13-15 snowy/icy
local frict_tbl = {
    {0,  1.00},
    {1,  0.95},
    {2,  0.90},
    {3,  0.80},
    {4,  0.90},
    {5,  0.85},
    {6,  0.80},
    {7,  0.85},
    {8,  0.80},
    {9,  0.75},
    {10, 0.75},
    {11, 0.70},
    {12, 0.65},
    {13, 0.75},
    {14, 0.70},
    {15, 0.65},
}


-- Maximum steering rate versus nose-strut compression.
local turn_speed_tbl = {
    {-1.00, 20},
    { 0.10, 20},
    { 0.30, 20},
    { 0.43, 17},
    { 1.00, 17},
}


-- Actual simulated nosewheel steering position.
local gear_turn_pos = 0


-- X-Plane keeps the mechanical steering range at the full Tu-154 limit.
-- The cockpit 11° / 63° selector restricts the commanded steering angle.
set(weel_angle1, MAX_TILLER_ANGLE)
set(weel_angle2, MAX_TILLER_ANGLE)



function update()

    set(override_wheel_steer, 1)
    set(lock, 1)


    -- SmartCopilot:
    -- ismaster == 1 means this instance is the slave.
    if get(ismaster) == 1 then
        return
    end


    local dt = get(frame_time)

    if dt <= 0 then
        return
    end


    -- Current system state.
    local compression =
        math.max(get(deflection_mtr_1), 0)

    local hydraulic_pressure =
        math.max(get(gs_press_2), 0)

    local groundspeed =
        math.max(get(groundspeed), 0)

    local on_ground =
        compression > 0

    local pushback_connected =
        get(pushback) == 1

    local steering_enabled =
        get(nosewheel_turn_enable) == 1

    local electrical_power =
        get(bus27_volt_left) > MIN_DC_VOLTAGE


    -- Cockpit steering-range selector:
    --
    -- 0 = +/-11°
    -- 1 = +/-63°
    local high_range =
        get(nosewheel_turn_sel) == 1


    -- Nosewheel steering power.
    local nws_power = bool2int(
        electrical_power
        and steering_enabled
        and on_ground
    )

    set(nosewheel_turn_power, nws_power)


    --------------------------------------------------------------------------
    -- Steering dynamics
    --------------------------------------------------------------------------

    local friction_factor =
        interpolate(
            frict_tbl,
            get(runway_friction)
        )

    if friction_factor <= 0 then
        friction_factor = 1
    end


    -- Maximum hydraulic steering movement rate.
    --
    -- Steering response depends on:
    --   - nose-strut compression
    --   - runway condition
    --   - groundspeed
    --   - hydraulic pressure
    local turn_max =
        math.min(
            interpolate(
                turn_speed_tbl,
                compression
            )
            / friction_factor
            + groundspeed * 2,
            20
        )
        * 1.2
        * hydraulic_pressure
        / NOMINAL_HYD_PRESS


    -- With insufficient hydraulic pressure for the current nose load,
    -- steering movement stops.
    if hydraulic_pressure < compression * 100 then
        turn_max = 0
    end


    --------------------------------------------------------------------------
    -- Steering input
    --------------------------------------------------------------------------

    -- Steering input is selected manually in the 2D panel:
    --
    -- have_pedals = 1 -> Tiller
    -- have_pedals = 0 -> Rudder/Yaw
    --
    -- Tiller and rudder are never combined.
    local use_tiller =
        get(have_pedals) == 1


    -- Both steering methods use the cockpit-selected range.
    local max_input_angle

    if use_tiller then

        if high_range then
            max_input_angle = MAX_TILLER_ANGLE
        else
            max_input_angle = NWS_LOW_ANGLE
        end

    else

        if high_range then
            max_input_angle = MAX_RUDDER_ANGLE
        else
            max_input_angle = NWS_LOW_ANGLE
        end

    end


    local requested_angle


    if use_tiller then

        local tiller_input =
            clamp(
                get(tiller_val),
                -1,
                1
            )

        requested_angle =
            tiller_input
            * max_input_angle


        -- Physical tiller animation follows the user's tiller input,
        -- independent of the selected 11° / 63° steering range.
        set(
            tiller_angle,
            tiller_input
        )


    else

        local rudder_input =
            clamp(
                get(joy_yaw),
                -1,
                1
            )

        requested_angle =
            rudder_input
            * max_input_angle


        -- No tiller animation while the user selected rudder steering.
        set(tiller_angle, 0)
    end


    requested_angle =
        clamp(
            requested_angle,
            -max_input_angle,
            max_input_angle
        )


    --------------------------------------------------------------------------
    -- Hydraulic steering movement
    --------------------------------------------------------------------------

    local turn_rate =
        requested_angle
        - gear_turn_pos


    -- Rate-limit nosewheel movement.
    if turn_rate < -turn_max then

        turn_rate = -turn_max

    elseif turn_rate > turn_max then

        turn_rate = turn_max

    end


    -- Powered hydraulic steering plus automatic centering
    -- as the nose strut unloads.
    gear_turn_pos =
        gear_turn_pos
        + turn_rate
        * nws_power
        * dt
        - gear_turn_pos
        * dt
        * math.max(
            0.5 - compression * 3,
            0
        )


    -- Absolute mechanical limit.
    gear_turn_pos =
        clamp(
            gear_turn_pos,
            -MAX_TILLER_ANGLE,
            MAX_TILLER_ANGLE
        )


    --------------------------------------------------------------------------
    -- X-Plane output / BetterPushback handoff
    --------------------------------------------------------------------------

    -- BetterPushback may control the wheel while connected.
    -- Do not overwrite its steering command while the aircraft NWS
    -- is unpowered.
    if not pushback_connected
    or nws_power > 0 then

        set(
            tire_steer_command_deg,
            gear_turn_pos
        )

    end

end



local gear_toggle_command =
    findCommand(
        "sim/flight_controls/nwheel_steer_toggle"
    )


local function gear_toggle_handler(phase)

    if phase == 0 then

        set(
            nosewheel_turn_enable,
            get(nosewheel_turn_enable) == 1
                and 0
                or 1
        )

    end

    return 0
end


registerCommandHandler(gear_toggle_command, 0, gear_toggle_handler)



function onModuleDone()
    set(override_wheel_steer, 0)
end
