-- mrp.lua
-- Marker receiver logic

--[[
Changelog
- Preserved the existing MRP mode, altitude-limit, power, failure, marker-signal,
  current-consumption, day/night, and lamp behavior unless noted below.
- Fixed the lamp-test brightness calculation by correcting the missing parentheses
  around the right 27 V bus voltage scaling.
- Replaced persistent marker-light state variables with local per-frame values.
- Cached repeatedly used Dataref values inside update().
- Kept all Dataref bindings in one defineProps() block.
--]]

-- local defineProps Function
local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    -- X-Plane marker receiver
    {"outer_marker", "sim/cockpit/misc/outer_marker_lit", globalPropertyi},
    {"middle_marker", "sim/cockpit/misc/middle_marker_lit", globalPropertyi},
    {"inner_marker", "sim/cockpit/misc/inner_marker_lit", globalPropertyi},
    {"alt", "sim/flightmodel/position/y_agl", globalPropertyf},
    {"sim_fail", "sim/operation/failures/rel_marker", globalPropertyi},
    -- Controls
    {"mrp_mode", "tu154/custom/switchers/ovhd/sp50_nav_mode", globalPropertyi},
    {"lamp_test", "tu154/custom/buttons/lamp_test_front", globalPropertyi},
    {"day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf},
    -- Electrical
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
    {"mrp_cc", "tu154/custom/xap/An24_gauges/mrp_cc", globalPropertyf},
    -- Failures
    {"mrp_fail", "tu154/custom/failures/mrp_fail", globalPropertyi},
    -- Marker lamps
    {"marker_1", "tu154/custom/lights/marker_1", globalPropertyf},
    {"marker_2", "tu154/custom/lights/marker_2", globalPropertyf},
    {"marker_3", "tu154/custom/lights/marker_3", globalPropertyf},
})

size = {2048, 2048}

local MRP_POWER_THRESHOLD = 13
local MRP_NAV_ALTITUDE_LIMIT = 5000
local MRP_CURRENT = 2

function update()
    local mode = get(mrp_mode)
    local altitude = get(alt)
    local bus_left = get(bus27_volt_left)
    local bus_right = get(bus27_volt_right)
    local failed = get(mrp_fail) ~= 0

    local mrp_available =
        bus_left > MRP_POWER_THRESHOLD
        and not failed
        and (
            mode == 0
            or (mode == 1 and altitude < MRP_NAV_ALTITUDE_LIMIT)
        )

    local outer_lit = 0
    local middle_lit = 0
    local inner_lit = 0

    if mrp_available then
        set(mrp_cc, MRP_CURRENT)
        set(sim_fail, 0)

        outer_lit = get(outer_marker)
        middle_lit = get(middle_marker)
        inner_lit = get(inner_marker)
    else
        set(mrp_cc, 0)
        set(sim_fail, 6)
    end

    local lamp_test_brightness =
        get(lamp_test) * math.max((bus_right - 10) / 18.5, 0)

    local day_night = 1 - get(day_night_set) * 0.25

    local lamps_brightness =
        math.max((math.max(bus_left, bus_right) - 10) / 18.5, 0)
        * day_night

    set(marker_1, math.max(outer_lit * lamps_brightness, lamp_test_brightness))
    set(marker_2, math.max(middle_lit * lamps_brightness, lamp_test_brightness))
    set(marker_3, math.max(inner_lit * lamps_brightness, lamp_test_brightness))
end
