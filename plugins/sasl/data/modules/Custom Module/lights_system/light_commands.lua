-- lights_commands.lua
--[[
Changelog
- Grouped all property bindings through a local defineProps() helper while preserving all existing property names, Dataref paths, constructors, and their original order.
- Replaced Russian comments with English comments.
- Preserved all existing X-Plane command names and command-handler entry points.
- Kept the generic hold-command and toggle-command helpers available.
- Reused the already defined property references when registering generic light commands instead of creating duplicate property handles.
- Made the landing-light extension toggle evaluate both left and right extension switches so an asymmetric state is handled predictably.
- Made the landing-light ON command use the higher of the two current mode positions before stepping both sides upward together.
- Made the landing-light OFF command use the lower of the two current mode positions before stepping both sides downward together.
- Kept landing-light mode limits unchanged at -1 (taxi), 0 (off), and +1 (landing).
]]

-- X-Plane command handling for the lighting system.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

-- Light controls.
defineProps({
    { "nav_lights_set", "tu154/custom/lights/nav_lights_set", globalPropertyi },
    { "strobe_set", "tu154/custom/lights/strobe_set", globalPropertyi },
    { "wing_light_left_set", "tu154/custom/lights/wing_light_left_set", globalPropertyi },
    { "wing_light_right_set", "tu154/custom/lights/wing_light_right_set", globalPropertyi },
    { "tail_light_set", "tu154/custom/lights/tail_light_set", globalPropertyi },
    { "day_night_set", "tu154/custom/lights/day_night_set", globalPropertyi },
    { "landing_ext_set_L", "tu154/custom/lights/landing_ext_set_L", globalPropertyi },
    { "landing_ext_set_R", "tu154/custom/lights/landing_ext_set_R", globalPropertyi },
    { "landing_mode_set_L", "tu154/custom/lights/landing_mode_set_L", globalPropertyi },
    { "landing_mode_set_R", "tu154/custom/lights/landing_mode_set_R", globalPropertyi },
})

-- Register a command that writes one value while pressed and restores another on release.
local function setup_hold_command(off_value, on_value, cmd_name, property_ref)
    local function create_handler(off_value_inner, on_value_inner, property_ref_inner)
        return function(phase)
            if phase == 0 then
                set(property_ref_inner, on_value_inner)
            elseif phase == 2 then
                set(property_ref_inner, off_value_inner)
            end

            return 0
        end
    end

    local command = sasl.findCommand(cmd_name) or sasl.createCommand(cmd_name, 0)
    sasl.registerCommandHandler(command, 0, create_handler(off_value, on_value, property_ref))
end

-- Register a command that toggles a property between two values on command press.
local function setup_toggle_command(off_value, on_value, cmd_name, property_ref)
    local function create_handler(off_value_inner, on_value_inner, property_ref_inner)
        return function(phase)
            if phase == 0 then
                if get(property_ref_inner) ~= on_value_inner then
                    set(property_ref_inner, on_value_inner)
                else
                    set(property_ref_inner, off_value_inner)
                end
            end

            return 0
        end
    end

    local command = sasl.findCommand(cmd_name) or sasl.createCommand(cmd_name, 0)
    sasl.registerCommandHandler(command, 0, create_handler(off_value, on_value, property_ref))
end

-- Standard X-Plane light commands mapped to the custom light switches.
setup_toggle_command(0, 1, "sim/lights/nav_lights_toggle", nav_lights_set)
setup_toggle_command(0, 1, "sim/lights/strobe_lights_toggle", strobe_set)
setup_toggle_command(0, 1, "sim/lights/spot_lights_toggle", tail_light_set)

-- Toggle both landing-light extension switches together.
local landing_light_open = sasl.findCommand("sim/lights/landing_lights_toggle")

function landing_light_open_hnd(phase)
    if phase == 0 then
        local left_extended = get(landing_ext_set_L) == 1
        local right_extended = get(landing_ext_set_R) == 1

        -- If both lights are already extended, retract both.
        -- Any asymmetric or fully retracted state results in both being extended.
        local new_state = (left_extended and right_extended) and 0 or 1

        set(landing_ext_set_L, new_state)
        set(landing_ext_set_R, new_state)
    end

    return 0
end

sasl.registerCommandHandler(landing_light_open, 0, landing_light_open_hnd)

-- Step both landing-light mode switches upward toward LANDING (+1).
local landing_light_up = sasl.findCommand("sim/lights/landing_lights_on")

function landing_light_up_hnd(phase)
    if phase == 0 then
        local left_mode = get(landing_mode_set_L)
        local right_mode = get(landing_mode_set_R)

        -- For an asymmetric state, use the higher current position as the
        -- common starting point and then move both switches one step upward.
        local new_mode = math.min(math.max(left_mode, right_mode) + 1, 1)

        set(landing_mode_set_L, new_mode)
        set(landing_mode_set_R, new_mode)
    end

    return 0
end

sasl.registerCommandHandler(landing_light_up, 0, landing_light_up_hnd)

-- Step both landing-light mode switches downward toward TAXI (-1).
local landing_light_down = sasl.findCommand("sim/lights/landing_lights_off")

function landing_light_down_hnd(phase)
    if phase == 0 then
        local left_mode = get(landing_mode_set_L)
        local right_mode = get(landing_mode_set_R)

        -- For an asymmetric state, use the lower current position as the
        -- common starting point and then move both switches one step downward.
        local new_mode = math.max(math.min(left_mode, right_mode) - 1, -1)

        set(landing_mode_set_L, new_mode)
        set(landing_mode_set_R, new_mode)
    end

    return 0
end

sasl.registerCommandHandler(landing_light_down, 0, landing_light_down_hnd)

--[[
Mapped X-Plane commands:

sim/lights/nav_lights_toggle       Nav lights toggle.
sim/lights/strobe_lights_toggle    Strobe lights toggle.
sim/lights/spot_lights_toggle      Tail/logo lights toggle.
sim/lights/landing_lights_toggle   Landing-light extension toggle.
sim/lights/landing_lights_on       Landing-light mode one step up.
sim/lights/landing_lights_off      Landing-light mode one step down.
]]
