-- rmi.lua
-- RMI gauge logic for compass card and radio bearing needles.

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"course_bgmk", "tu154/custom/tks/course_bgmk_2", globalPropertyf},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"adf_bear_1", "tu154/custom/radio/adf_bear_1", globalPropertyf},
    {"adf_bear_2", "tu154/custom/radio/adf_bear_2", globalPropertyf},
    {"vor_bear_1", "tu154/custom/radio/vor_bear_1", globalPropertyf},
    {"vor_bear_2", "tu154/custom/radio/vor_bear_2", globalPropertyf},
    {"ark15_L_ON", "tu154/custom/radio/ark15_L_cc", globalPropertyf},
    {"ark15_R_ON", "tu154/custom/radio/ark15_R_cc", globalPropertyf},
    {"nav_L_ON", "tu154/custom/radio/nav1_pow_cc", globalPropertyf},
    {"nav_R_ON", "tu154/custom/radio/nav2_pow_cc", globalPropertyf},
    {"bus36_volt", "tu154/custom/elec/bus36_volt_right", globalPropertyf},
    {"radiocomp_scale", "tu154/custom/gauges/compas/radiocomp_scale_left", globalPropertyf},
    {"bearing_1", "tu154/custom/gauges/compas/bearing_1_left", globalPropertyf},
    {"bearing_2", "tu154/custom/gauges/compas/bearing_2_left", globalPropertyf},
    {"source_1_switch", "tu154/custom/gauges/compas/source_1_switch_left", globalPropertyi},
    {"source_2_switch", "tu154/custom/gauges/compas/source_2_switch_left", globalPropertyi},
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

local main_scale_act = math.random(-180, 180)
local nd_1_angle = math.random(-180, 180)
local nd_2_angle = math.random(-180, 180)
local nd_1_act = math.random(-180, 180)
local nd_2_act = math.random(-180, 180)

-- Initialize the shared scale only on the local/master side.
if get(ismaster) ~= 1 then
    set(radiocomp_scale, main_scale_act)
else
    main_scale_act = get(radiocomp_scale)
end

function update()
    local MASTER = get(ismaster) ~= 1
    local passed = get(frame_time)
    local power = get(bus36_volt) > 30

    -- On the SmartCopilot slave, follow the synchronized scale value.
    if not MASTER then
        main_scale_act = get(radiocomp_scale)
    end

    if power and MASTER then
        -- Move the compass card toward the current magnetic course.
        local course = get(course_bgmk)
        local cur_delta = main_scale_act - course

        if cur_delta > 180 then
            cur_delta = cur_delta - 360
        elseif cur_delta < -180 then
            cur_delta = cur_delta + 360
        end

        if cur_delta > 1 then
            main_scale_act = main_scale_act - passed * 30
        elseif cur_delta < -1 then
            main_scale_act = main_scale_act + passed * 30
        else
            main_scale_act = main_scale_act - cur_delta * passed * 20
        end
    end

    -- Keep compass card angle within the expected range.
    if main_scale_act > 180 then
        main_scale_act = main_scale_act - 360
    elseif main_scale_act < -180 then
        main_scale_act = main_scale_act + 360
    end

    if MASTER then
        set(radiocomp_scale, main_scale_act)
    end

    -- Calculate bearing needle targets.
    if power then
        local source_1 = get(source_1_switch)
        local source_2 = get(source_2_switch)

        if source_1 == 1 and get(ark15_L_ON) == 1 then
            nd_1_angle = get(adf_bear_1)
        elseif source_1 == 3 and get(nav_L_ON) == 1 then
            nd_1_angle = get(vor_bear_1)
        end

        if source_2 == 2 and get(ark15_R_ON) == 1 then
            nd_2_angle = get(adf_bear_2)
        elseif source_2 == 4 and get(nav_R_ON) == 1 then
            nd_2_angle = get(vor_bear_2)
        end

        -- Smooth first bearing needle movement.
        local delta_1 = nd_1_angle - nd_1_act

        while delta_1 > 180 do
            delta_1 = delta_1 - 360
        end

        while delta_1 < -180 do
            delta_1 = delta_1 + 360
        end

        nd_1_act = nd_1_act + delta_1 * passed * 2

        -- Smooth second bearing needle movement.
        local delta_2 = nd_2_angle - nd_2_act

        while delta_2 > 180 do
            delta_2 = delta_2 - 360
        end

        while delta_2 < -180 do
            delta_2 = delta_2 + 360
        end

        nd_2_act = nd_2_act + delta_2 * passed * 2
    end

    if MASTER then
        set(bearing_1, nd_1_act)
        set(bearing_2, nd_2_act)
    end
end
