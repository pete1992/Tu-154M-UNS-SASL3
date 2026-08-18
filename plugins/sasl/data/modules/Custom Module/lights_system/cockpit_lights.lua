-- cockpit_lights.lua
--[[
Changelog
- Grouped all 145 Dataref bindings through defineProps() while preserving property names, paths, constructors, and original binding order.
- Replaced Russian comments with English comments.
- Preserved all legacy sim/weapons light parameter bindings and their original initialization values.
- Clamped 27 V and 115 V lighting coefficients to the valid 0..1 range.
- Added APU generator (generator 4) as a valid cabin-light power source.
- Corrected 27 V cockpit-light current calculation to avoid voltage being applied twice.
- Applied the non-HDR gate consistently to the default X-Plane cockpit flood light.
- Made the toilet occupied lamp deterministic during the waiting phase.
- Removed the unused current_115 local.
- Cached bus voltages and lighting controls once per frame to reduce repeated Dataref reads.
- Preserved cabin night-threshold behavior, brightness curves, light scaling, electrical-load weights, sign behavior, and the unused left spotlight interface.
]]

-- Cockpit and cabin lighting logic.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Electrical system
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },
    { "cockpit_light_cc_left", "tu154/custom/elec/cockpit_light_cc_left", globalPropertyf },
    { "cockpit_light_cc_right", "tu154/custom/elec/cockpit_light_cc_right", globalPropertyf },
    { "cockpit_light_cc_115", "tu154/custom/elec/cockpit_light_cc_115", globalPropertyf },
    -- Generator status
    { "gen1_work_bus", "tu154/custom/elec/gen1_work", globalPropertyi },
    { "gen2_work_bus", "tu154/custom/elec/gen2_work", globalPropertyi },
    { "gen3_work_bus", "tu154/custom/elec/gen3_work", globalPropertyi },
    { "gen4_work_bus", "tu154/custom/elec/gen4_work", globalPropertyi },
    { "gpu_work_bus", "tu154/custom/elec/gpu_work", globalPropertyi },
    -- Environment and X-Plane fallback lighting
    { "percent_lights_on", "sim/graphics/scenery/percent_lights_on", globalPropertyf },
    { "default_cockpit_flood", "sim/cockpit2/switches/panel_brightness_ratio[0]", globalProperty },
    { "default_eng_panel_flood", "sim/cockpit2/switches/panel_brightness_ratio[1]", globalProperty },
    { "default_pedestal_flood", "sim/cockpit2/switches/panel_brightness_ratio[2]", globalProperty },
    -- Cabin and sign lighting outputs
    { "cabin_2d_light", "tu154/custom/lights/cabin_2d_light", globalPropertyf },
    { "exit_lamp", "tu154/custom/lights/exit_lamp", globalPropertyf },
    { "fasten_seatbelts_lamp", "tu154/custom/lights/fasten_seatbelts_lamp", globalPropertyf },
    { "nosmoking_lamp", "tu154/custom/lights/nosmoking_lamp", globalPropertyf },
    { "toilet_busy_lamp", "tu154/custom/lights/toilet_busy_lamp", globalPropertyf },
    { "seats_leters_lamp", "tu154/custom/lights/seats_leters_lamp", globalPropertyf },
    -- HDR state
    { "HDR_on", "sim/graphics/settings/HDR_on", globalPropertyf },
    -- Legacy custom light parameters stored in sim/weapons datarefs
    { "l1_0", "sim/weapons/vx[0]", globalProperty },
    { "l1_1", "sim/weapons/vx[1]", globalProperty },
    { "l1_2", "sim/weapons/vx[2]", globalProperty },
    { "l1_3", "sim/weapons/vx[3]", globalProperty },
    { "l1_4", "sim/weapons/vx[4]", globalProperty },
    { "l1_5", "sim/weapons/vx[5]", globalProperty },
    { "l1_6", "sim/weapons/vx[6]", globalProperty },
    { "l1_7", "sim/weapons/vx[7]", globalProperty },
    { "l1_8", "sim/weapons/vx[8]", globalProperty },
    { "l2_0", "sim/weapons/vy[0]", globalProperty },
    { "l2_1", "sim/weapons/vy[1]", globalProperty },
    { "l2_2", "sim/weapons/vy[2]", globalProperty },
    { "l2_3", "sim/weapons/vy[3]", globalProperty },
    { "l2_4", "sim/weapons/vy[4]", globalProperty },
    { "l2_5", "sim/weapons/vy[5]", globalProperty },
    { "l2_6", "sim/weapons/vy[6]", globalProperty },
    { "l2_7", "sim/weapons/vy[7]", globalProperty },
    { "l2_8", "sim/weapons/vy[8]", globalProperty },
    { "l3_0", "sim/weapons/vz[0]", globalProperty },
    { "l3_1", "sim/weapons/vz[1]", globalProperty },
    { "l3_2", "sim/weapons/vz[2]", globalProperty },
    { "l3_3", "sim/weapons/vz[3]", globalProperty },
    { "l3_4", "sim/weapons/vz[4]", globalProperty },
    { "l3_5", "sim/weapons/vz[5]", globalProperty },
    { "l3_6", "sim/weapons/vz[6]", globalProperty },
    { "l3_7", "sim/weapons/vz[7]", globalProperty },
    { "l3_8", "sim/weapons/vz[8]", globalProperty },
    { "l4_0", "sim/weapons/x[0]", globalProperty },
    { "l4_1", "sim/weapons/x[1]", globalProperty },
    { "l4_2", "sim/weapons/x[2]", globalProperty },
    { "l4_3", "sim/weapons/x[3]", globalProperty },
    { "l4_4", "sim/weapons/x[4]", globalProperty },
    { "l4_5", "sim/weapons/x[5]", globalProperty },
    { "l4_6", "sim/weapons/x[6]", globalProperty },
    { "l4_7", "sim/weapons/x[7]", globalProperty },
    { "l4_8", "sim/weapons/x[8]", globalProperty },
    { "l5_0", "sim/weapons/y[0]", globalProperty },
    { "l5_1", "sim/weapons/y[1]", globalProperty },
    { "l5_2", "sim/weapons/y[2]", globalProperty },
    { "l5_3", "sim/weapons/y[3]", globalProperty },
    { "l5_4", "sim/weapons/y[4]", globalProperty },
    { "l5_5", "sim/weapons/y[5]", globalProperty },
    { "l5_6", "sim/weapons/y[6]", globalProperty },
    { "l5_7", "sim/weapons/y[7]", globalProperty },
    { "l5_8", "sim/weapons/y[8]", globalProperty },
    { "l6_0", "sim/weapons/z[0]", globalProperty },
    { "l6_1", "sim/weapons/z[1]", globalProperty },
    { "l6_2", "sim/weapons/z[2]", globalProperty },
    { "l6_3", "sim/weapons/z[3]", globalProperty },
    { "l6_4", "sim/weapons/z[4]", globalProperty },
    { "l6_5", "sim/weapons/z[5]", globalProperty },
    { "l6_6", "sim/weapons/z[6]", globalProperty },
    { "l6_7", "sim/weapons/z[7]", globalProperty },
    { "l6_8", "sim/weapons/z[8]", globalProperty },
    { "l7_0", "sim/weapons/L[0]", globalProperty },
    { "l7_1", "sim/weapons/L[1]", globalProperty },
    { "l7_2", "sim/weapons/L[2]", globalProperty },
    { "l7_3", "sim/weapons/L[3]", globalProperty },
    { "l7_4", "sim/weapons/L[4]", globalProperty },
    { "l7_5", "sim/weapons/L[5]", globalProperty },
    { "l7_6", "sim/weapons/L[6]", globalProperty },
    { "l7_7", "sim/weapons/L[7]", globalProperty },
    { "l7_8", "sim/weapons/L[8]", globalProperty },
    { "l7_1_0", "sim/weapons/N[0]", globalProperty },
    { "l7_1_1", "sim/weapons/N[1]", globalProperty },
    { "l7_1_2", "sim/weapons/N[2]", globalProperty },
    { "l7_1_3", "sim/weapons/N[3]", globalProperty },
    { "l7_1_4", "sim/weapons/N[4]", globalProperty },
    { "l7_1_5", "sim/weapons/N[5]", globalProperty },
    { "l7_1_6", "sim/weapons/N[6]", globalProperty },
    { "l7_1_7", "sim/weapons/N[7]", globalProperty },
    { "l7_1_8", "sim/weapons/N[8]", globalProperty },
    { "l8_0", "sim/weapons/M[0]", globalProperty },
    { "l8_1", "sim/weapons/M[1]", globalProperty },
    { "l8_2", "sim/weapons/M[2]", globalProperty },
    { "l8_3", "sim/weapons/M[3]", globalProperty },
    { "l8_4", "sim/weapons/M[4]", globalProperty },
    { "l8_5", "sim/weapons/M[5]", globalProperty },
    { "l8_6", "sim/weapons/M[6]", globalProperty },
    { "l8_7", "sim/weapons/M[7]", globalProperty },
    { "l8_8", "sim/weapons/M[8]", globalProperty },
    { "l9_0", "sim/weapons/Prad[0]", globalProperty },
    { "l9_1", "sim/weapons/Prad[1]", globalProperty },
    { "l9_2", "sim/weapons/Prad[2]", globalProperty },
    { "l9_3", "sim/weapons/Prad[3]", globalProperty },
    { "l9_4", "sim/weapons/Prad[4]", globalProperty },
    { "l9_5", "sim/weapons/Prad[5]", globalProperty },
    { "l9_6", "sim/weapons/Prad[6]", globalProperty },
    { "l9_7", "sim/weapons/Prad[7]", globalProperty },
    { "l9_8", "sim/weapons/Prad[8]", globalProperty },
    -- Custom panel-light outputs
    { "mid_left_panel_int", "tu154/custom/lights/mid_left_panel_int", globalPropertyf },
    { "left_panel_int", "tu154/custom/lights/left_panel_int", globalPropertyf },
    { "right_panel_int", "tu154/custom/lights/right_panel_int", globalPropertyf },
    { "mid_right_panel_int", "tu154/custom/lights/mid_right_panel_int", globalPropertyf },
    { "ovhd_panel_int", "tu154/custom/lights/ovhd_panel_int", globalPropertyf },
    { "left_panel_flood", "tu154/custom/lights/left_panel_flood", globalPropertyf },
    { "right_panel_flood", "tu154/custom/lights/right_panel_flood", globalPropertyf },
    { "mid_panel_flood", "tu154/custom/lights/mid_panel_flood", globalPropertyf },
    { "front_panel_flood", "tu154/custom/lights/front_panel_flood", globalPropertyf },
    { "ovhd_front_panel_flood", "tu154/custom/lights/ovhd_front_panel_flood", globalPropertyf },
    { "ovhd_back_panel_flood", "tu154/custom/lights/ovhd_back_panel_flood", globalPropertyf },
    { "eng_panel_flood", "tu154/custom/lights/eng_panel_flood", globalPropertyf },
    { "azs_panel_flood", "tu154/custom/lights/azs_panel_flood", globalPropertyf },
    { "left_spotlight_flood", "tu154/custom/lights/left_spotlight_flood", globalPropertyf },
    -- Lighting controls
    { "cabinl_flood_set", "tu154/custom/lights/cabinl_flood_set", globalPropertyi },
    { "mid_left_panel_int_set", "tu154/custom/lights/mid_left_panel_int_set", globalPropertyf },
    { "left_panel_int_set", "tu154/custom/lights/left_panel_int_set", globalPropertyf },
    { "right_panel_int_set", "tu154/custom/lights/right_panel_int_set", globalPropertyf },
    { "mid_right_panel_int_set", "tu154/custom/lights/mid_right_panel_int_set", globalPropertyf },
    { "ovhd_panel_int_set", "tu154/custom/lights/ovhd_panel_int_set", globalPropertyf },
    { "left_panel_flood_set", "tu154/custom/lights/left_panel_flood_set", globalPropertyf },
    { "right_panel_flood_set", "tu154/custom/lights/right_panel_flood_set", globalPropertyf },
    { "mid_panel_flood_set", "tu154/custom/lights/mid_panel_flood_set", globalPropertyf },
    { "front_panel_flood_set", "tu154/custom/lights/front_panel_flood_set", globalPropertyf },
    { "ovhd_front_panel_flood_set", "tu154/custom/lights/ovhd_front_panel_flood_set", globalPropertyf },
    { "ovhd_back_panel_flood_set", "tu154/custom/lights/ovhd_back_panel_flood_set", globalPropertyf },
    { "eng_panel_flood_set", "tu154/custom/lights/eng_panel_flood_set", globalPropertyf },
    { "azs_panel_flood_set", "tu154/custom/lights/azs_panel_flood_set", globalPropertyi },
    -- Cabin sign controls
    { "sign_belts", "tu154/custom/switchers/ovhd/sign_belts", globalPropertyi },
    { "sign_nosmoke", "tu154/custom/switchers/ovhd/sign_nosmoke", globalPropertyi },
    { "sign_exit", "tu154/custom/switchers/ovhd/sign_exit", globalPropertyi },
    -- Timing
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
})

-- Initialize the legacy custom light parameters.
-- These datarefs are used by the aircraft objects as light descriptors.
local function initializeLegacyLights(defs)
    for _, d in ipairs(defs) do
        set(d[1], d[2])
    end
end

initializeLegacyLights({
    { l1_0, 1 },
    { l1_1, 0.7 },
    { l1_2, 0.2 },
    { l1_3, 0 },
    { l1_4, 0.6 },
    { l1_5, 0 },
    { l1_6, 0 },
    { l1_7, -90 },
    { l1_8, 20 },
    { l2_0, 1 },
    { l2_1, 0.7 },
    { l2_2, 0.2 },
    { l2_3, 0 },
    { l2_4, 0.6 },
    { l2_5, 0 },
    { l2_6, 0 },
    { l2_7, -90 },
    { l2_8, 20 },
    { l3_0, 1 },
    { l3_1, 0.7 },
    { l3_2, 0.2 },
    { l3_3, 0 },
    { l3_4, 0.6 },
    { l3_5, 0 },
    { l3_6, 0 },
    { l3_7, -50 },
    { l3_8, 0.5 },
    { l4_0, 1 },
    { l4_1, 0.7 },
    { l4_2, 0.2 },
    { l4_3, 1 },
    { l4_4, 0.9 },
    { l4_5, 0 },
    { l4_6, 0 },
    { l4_7, -50 },
    { l4_8, 1 },
    { l5_0, 1 },
    { l5_1, 0.7 },
    { l5_2, 0.2 },
    { l5_3, 0 },
    { l5_4, 0.5 },
    { l5_5, 0 },
    { l5_6, 0 },
    { l5_7, -160 },
    { l5_8, 20 },
    { l6_0, 1 },
    { l6_1, 0.7 },
    { l6_2, 0.2 },
    { l6_3, 0 },
    { l6_4, 0.4 },
    { l6_5, 0 },
    { l6_6, 0 },
    { l6_7, 0 },
    { l6_8, -1 },
    { l7_0, 1 },
    { l7_1, 0.7 },
    { l7_2, 0.2 },
    { l7_3, 0 },
    { l7_4, 1.0 },
    { l7_5, 0 },
    { l7_6, 30 },
    { l7_7, -90 },
    { l7_8, 10 },
    { l7_1_0, 1 },
    { l7_1_1, 0.7 },
    { l7_1_2, 0.2 },
    { l7_1_3, 0 },
    { l7_1_4, 0.7 },
    { l7_1_5, 0 },
    { l7_1_6, 30 },
    { l7_1_7, -30 },
    { l7_1_8, 20 },
    { l8_0, 1 },
    { l8_1, 0.7 },
    { l8_2, 0.2 },
    { l8_3, 0 },
    { l8_4, 1.0 },
    { l8_5, 0 },
    { l8_6, 0 },
    { l8_7, -90 },
    { l8_8, 10 },
    { l9_0, 1 },
    { l9_1, 0.7 },
    { l9_2, 0.5 },
    { l9_3, 1 },
    { l9_4, 5 },
    { l9_5, 1 },
    { l9_6, 1 },
    { l9_7, 0 },
    { l9_8, 1 },
})

local BRIGHT_TABLE = {
    { -5000, 0 }, -- Lower guard point.
    { 0, 0 },
    { 0.1, 0.6 },
    { 0.5, 0.85 },
    { 1, 1 },
    { 10000, 1000 }, -- Upper guard point.
}

local TOILET = {
    wait = 90,
    use = 60,
}

local function clamp01(value)
    if value < 0 then
        return 0
    elseif value > 1 then
        return 1
    end
    return value
end

function update()
    local passed = get(frame_time)

    -- Cache bus voltages once per frame.
    local bus27_left = get(bus27_volt_left)
    local bus27_right = get(bus27_volt_right)
    local bus115_1 = get(bus115_1_volt)
    local bus115_3 = get(bus115_3_volt)
    -- Average supply coefficients. With one of two buses powered, lighting
    -- remains available at reduced brightness as in the original logic.
    local light_coef_27 = clamp01((bus27_left + bus27_right) / 58)
    local light_coef_115 = clamp01((bus115_1 + bus115_3) / 234)
    -- Cache lighting controls once per frame.
    local pedestal_int_set = get(mid_left_panel_int_set)
    local left_int_set = get(left_panel_int_set)
    local right_int_set = get(right_panel_int_set)
    local mid_int_set = get(mid_right_panel_int_set)
    local ovhd_int_set = get(ovhd_panel_int_set)
    local left_flood_set = get(left_panel_flood_set)
    local right_flood_set = get(right_panel_flood_set)
    local front_flood_set = get(front_panel_flood_set)
    local pedestal_flood_set = get(mid_panel_flood_set)
    local ovhd_front_flood_set = get(ovhd_front_panel_flood_set)
    local ovhd_back_flood_set = get(ovhd_back_panel_flood_set)
    local eng_flood_set = get(eng_panel_flood_set)
    local azs_flood_set = get(azs_panel_flood_set)
    local cockpit_flood_set = get(cabinl_flood_set)
    -- Integrated 115 V panel lighting.
    local pedestal_int = pedestal_int_set * light_coef_115
    local left_pan_int = left_int_set * light_coef_115
    local right_pan_int = right_int_set * light_coef_115
    local mid_pan_int = mid_int_set * light_coef_115
    local ovhd_pan_int = ovhd_int_set * light_coef_115
    set(mid_left_panel_int, pedestal_int * 0.1)
    set(left_panel_int, left_pan_int * 0.1)
    set(right_panel_int, right_pan_int * 0.1)
    set(mid_right_panel_int, mid_pan_int * 0.1)
    set(ovhd_panel_int, ovhd_pan_int * 0.1)
    -- 27 V panel flood lighting.
    local left_flood = left_flood_set * light_coef_27
    local right_flood = right_flood_set * light_coef_27
    local front_flood = front_flood_set * light_coef_27
    local pedestal_flood = pedestal_flood_set * light_coef_27
    local ovhd_fr_flood = ovhd_front_flood_set * light_coef_27
    local ovhd_bk_flood = ovhd_back_flood_set * light_coef_27
    local eng_flood = eng_flood_set * light_coef_27
    local azs_flood = azs_flood_set * light_coef_27
    local cockpit_flood = cockpit_flood_set * light_coef_27

    set(l1_3, left_flood * 1.5)
    set(left_panel_flood, left_flood)
    set(l2_3, right_flood * 1.5)
    set(right_panel_flood, right_flood)
    set(l3_3, front_flood * 1.5)
    set(front_panel_flood, front_flood)
    set(l4_3, pedestal_flood * 1.5)
    set(mid_panel_flood, pedestal_flood ^ 0.5)
    set(l5_3, ovhd_fr_flood * 1.5)
    set(ovhd_front_panel_flood, ovhd_fr_flood ^ 0.5)
    set(l6_3, ovhd_bk_flood * 1.5)
    set(ovhd_back_panel_flood, ovhd_bk_flood)
    set(l7_3, eng_flood * 1.5)
    set(l7_1_3, eng_flood * 1.5)
    set(eng_panel_flood, eng_flood ^ 0.5)
    set(azs_panel_flood, azs_flood)

    -- X-Plane fallback floods are used only when HDR is disabled.
    local non_HDR = 1 - clamp01(get(HDR_on))
    set(default_cockpit_flood, interpolate(BRIGHT_TABLE, cockpit_flood) * 0.8 * non_HDR)
    set(default_eng_panel_flood, interpolate(BRIGHT_TABLE, eng_flood) * non_HDR)
    set(default_pedestal_flood, interpolate(BRIGHT_TABLE, pedestal_flood) * non_HDR)

    -- Cabin lighting. Preserve the original night threshold and engine-generator
    -- requirement, while also accepting the APU generator and GPU.
    local engine_generators = get(gen1_work_bus) + get(gen2_work_bus) + get(gen3_work_bus)
    local cabin_powered = engine_generators > 1
        or get(gen4_work_bus) == 1
        or get(gpu_work_bus) == 1

    if cabin_powered and get(percent_lights_on) > 0.15 then
        set(l9_3, light_coef_115)
        set(cockpit_light_cc_115, 25)
        set(cabin_2d_light, non_HDR * light_coef_115)
    else
        set(l9_3, 0)
        set(cockpit_light_cc_115, 0)
        set(cabin_2d_light, 0)
    end

    -- Cabin signs.
    set(exit_lamp, get(sign_exit) * light_coef_27)
    set(fasten_seatbelts_lamp, get(sign_belts) * light_coef_27)
    set(nosmoking_lamp, get(sign_nosmoke) * light_coef_27)

    -- Simulated toilet occupancy.
    TOILET.wait = TOILET.wait - passed

    if TOILET.wait < 0 then
        set(toilet_busy_lamp, light_coef_27)
        TOILET.use = TOILET.use - passed

        if TOILET.use < 0 then
            TOILET.use = math.random(60, 300)
            TOILET.wait = math.random(120, 600)
            set(toilet_busy_lamp, 0)
        end
    else
        set(toilet_busy_lamp, 0)
    end

    set(seats_leters_lamp, light_coef_27)

    -- 27 V lighting load.
    -- Use raw control demand here; brightness already contains light_coef_27.
    -- Each bus receives its share once according to its own voltage.
    local current_27 = left_flood_set + right_flood_set + front_flood_set
        + pedestal_flood_set * 0.7
        + ovhd_front_flood_set * 0.7
        + ovhd_back_flood_set * 0.7
        + eng_flood_set
        + azs_flood_set * 1.5
        + cockpit_flood_set * 0.5

    set(cockpit_light_cc_left, current_27 * clamp01(bus27_left / 29) * 0.5)
    set(cockpit_light_cc_right, current_27 * clamp01(bus27_right / 29) * 0.5)
end
