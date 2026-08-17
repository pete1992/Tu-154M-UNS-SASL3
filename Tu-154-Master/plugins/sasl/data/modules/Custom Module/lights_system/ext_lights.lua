--[[
Changelog
- Grouped all property bindings through a local defineProps() helper while preserving every existing property name, Dataref path, constructor, and binding order.
- Replaced Russian comments with English comments.
- Cached frequently used Dataref values once per frame to reduce repeated property reads.
- Clamped 27 V bus coefficients to the valid 0..1 range so overvoltage cannot increase light output or landing-light deployment speed above the intended maximum.
- Preserved the existing landing-light grouping: the left extension/mode control drives the wing landing-light pair, while the right extension/mode control drives the front landing-light pair.
- Coupled landing-light brightness to the actual deployment position instead of switching to full brightness immediately when deployment starts.
- Changed nosewheel taxi-light visibility so it is enabled only when the nose gear is more than 90 percent deployed.
- Applied the nosewheel taxi-light gear interlock before electrical current calculations so hidden taxi lights no longer consume simulated current.
- Corrected flight-signal current calculations so each electrical bus is scaled only by its own voltage coefficient instead of applying the voltage factor twice.
- Preserved landing-light failure handling, landing-light master cutoff behavior, output scaling, animation speed, beacon/nav timing, and the Virtual Airlines landing-light workaround unless explicitly listed above.
- Preserved currently unused properties, counters, and legacy commented logic for project compatibility and future use.
]]

-- External lighting system logic.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

-- Electrical system.
defineProps({
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "ext_light_cc_left", "tu154/custom/elec/ext_light_cc_left", globalPropertyf },
    { "ext_light_cc_right", "tu154/custom/elec/ext_light_cc_right", globalPropertyf },

    -- X-Plane light outputs.
    { "sim_nav_light", "sim/cockpit2/switches/navigation_lights_on", globalPropertyf },
    { "sim_beacon", "sim/cockpit2/switches/beacon_on", globalPropertyf },
    { "sim_strobes", "sim/cockpit2/switches/strobe_lights_on", globalPropertyf },
    { "sim_lan_FL", "sim/cockpit2/switches/landing_lights_switch[7]", globalPropertyf },
    { "sim_lan_FR", "sim/cockpit2/switches/landing_lights_switch[6]", globalPropertyf },
    { "sim_lan_WL", "sim/cockpit2/switches/landing_lights_switch[5]", globalPropertyf },
    { "sim_lan_WR", "sim/cockpit2/switches/landing_lights_switch[4]", globalPropertyf },
    { "sim_NW_L", "sim/cockpit2/switches/landing_lights_switch[9]", globalPropertyf },
    { "sim_NW_R", "sim/cockpit2/switches/landing_lights_switch[8]", globalPropertyf },
    { "sim_spot", "sim/cockpit2/switches/spot_light_on", globalPropertyf },
    { "sim_anticollision_light", "sim/cockpit2/switches/anticollision_light_switch[0]", globalPropertyf },
    -- Legacy custom anti-collision output binding remains intentionally disabled:
    -- defineProperty("anticoll_light", globalPropertyi("tu154/custom/lights/anticoll_light"))
    { "sim_logo", "sim/cockpit2/switches/generic_lights_switch[0]", globalPropertyf },
    { "sim_wings_L", "sim/cockpit2/switches/generic_lights_switch[1]", globalPropertyf },
    { "sim_wings_R", "sim/cockpit2/switches/generic_lights_switch[2]", globalPropertyf },
    { "sim_cargo_1", "sim/cockpit2/switches/generic_lights_switch[3]", globalPropertyf },
    { "sim_cargo_2", "sim/cockpit2/switches/generic_lights_switch[4]", globalPropertyf },
    { "sim_lan_brt", "sim/flightmodel2/lights/landing_lights_brightness_ratio[1]", globalPropertyf },
    { "sim_landing", "sim/cockpit/electrical/landing_lights_on", globalPropertyi },

    -- Animation and custom light outputs.
    { "light_open_left", "tu154/custom/anim/light_open_left", globalPropertyf },
    { "light_open_right", "tu154/custom/anim/light_open_right", globalPropertyf },
    { "white_light_left", "tu154/custom/lights/white_light_left", globalPropertyi },
    { "white_light_right", "tu154/custom/lights/white_light_right", globalPropertyi },
    { "beacon_light_B", "tu154/custom/lights/beacon_light_B", globalPropertyi },
    { "beacon_light_T", "tu154/custom/lights/beacon_light_T", globalPropertyi },
    { "gear_defl", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalPropertyf },
    { "deploy_ratio_1", "sim/flightmodel2/gear/deploy_ratio[0]", globalPropertyf },
    { "lamp_deploy_FL", "sim/aircraft/parts/acf_gear_deploy[3]", globalPropertyf },
    { "lamp_deploy_FR", "sim/aircraft/parts/acf_gear_deploy[4]", globalPropertyf },
    { "lamp_deploy_WL", "sim/aircraft/parts/acf_gear_deploy[5]", globalPropertyf },
    { "lamp_deploy_WR", "sim/aircraft/parts/acf_gear_deploy[6]", globalPropertyf },

    -- Controls.
    { "nav_lights_set", "tu154/custom/lights/nav_lights_set", globalPropertyf },
    { "strobe_set", "tu154/custom/lights/strobe_set", globalPropertyf },
    { "wing_light_left_set", "tu154/custom/lights/wing_light_left_set", globalPropertyf },
    { "wing_light_right_set", "tu154/custom/lights/wing_light_right_set", globalPropertyf },
    { "tail_light_set", "tu154/custom/lights/tail_light_set", globalPropertyf },
    { "day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf },
    { "wing_light", "tu154/custom/switchers/eng/wing_light", globalPropertyf },
    { "cargo_1", "tu154/custom/lights/cargo_light_1_set", globalPropertyf },
    { "cargo_2", "tu154/custom/lights/cargo_light_2_set", globalPropertyf },
    { "landing_ext_set_L", "tu154/custom/lights/landing_ext_set_L", globalPropertyf },
    { "landing_ext_set_R", "tu154/custom/lights/landing_ext_set_R", globalPropertyf },
    { "landing_mode_set_L", "tu154/custom/lights/landing_mode_set_L", globalPropertyf },
    { "landing_mode_set_R", "tu154/custom/lights/landing_mode_set_R", globalPropertyf },
    { "light_signal_set", "tu154/custom/lights/light_signal_set", globalPropertyf },
    { "landing_light_off", "tu154/custom/lights/landing_light_off", globalPropertyi },
    { "landing_light_off_cap", "tu154/custom/lights/landing_light_off_cap", globalPropertyi },

    -- Time.
    { "sim_run_time", "sim/time/total_running_time_sec", globalPropertyf },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },

    -- Failures.
    { "lan_lamp_fail_FL", "tu154/custom/failures/lan_lamp_fail_FL", globalPropertyi },
    { "lan_lamp_fail_FR", "tu154/custom/failures/lan_lamp_fail_FR", globalPropertyi },
    { "lan_lamp_fail_WL", "tu154/custom/failures/lan_lamp_fail_WL", globalPropertyi },
    { "lan_lamp_fail_WR", "tu154/custom/failures/lan_lamp_fail_WR", globalPropertyi },
    { "rel_lites_nav", "sim/operation/failures/rel_lites_nav", globalPropertyi },
    { "rel_lites_beac", "sim/operation/failures/rel_lites_beac", globalPropertyi },
    { "sim_lights_switch", "sim/cockpit2/switches/landing_lights_switch", globalPropertyi },
})

-- Preserve original initialization behavior.
set(sim_strobes, 0)
set(lamp_deploy_FL, 0)
set(lamp_deploy_FR, 0)
set(lamp_deploy_WL, 0)
set(lamp_deploy_WR, 0)

local beacon_counter_B = 0
local beacon_counter_T = 0
local nav_counter = 0

local lan_light_counter_L = 0
local lan_light_counter_R = 0
local anticoll_counter = 0

function update()
    local passed = get(frame_time)

    -- Electrical supply coefficients.
    local coef_27_L = clamp(get(bus27_volt_left) / 28, 0, 1)
    local coef_27_R = clamp(get(bus27_volt_right) / 28, 0, 1)
    local coef_115 = bool2int(get(bus115_1_volt) > 110)

    -- Cache control states used more than once during this frame.
    local landing_ext_L = get(landing_ext_set_L)
    local landing_ext_R = get(landing_ext_set_R)
    local landing_mode_L = get(landing_mode_set_L)
    local landing_mode_R = get(landing_mode_set_R)
    local landing_master = 1 - get(landing_light_off)

    -- Landing-light failures.
    local fail_FL = get(lan_lamp_fail_FL)
    local fail_FR = get(lan_lamp_fail_FR)
    local fail_WL = get(lan_lamp_fail_WL)
    local fail_WR = get(lan_lamp_fail_WR)

    -- Landing-light deployment animation.
    -- Project grouping is intentionally preserved:
    -- left control -> wing landing-light pair, right control -> front landing-light pair.
    if landing_ext_L == 1 and lan_light_counter_L < 1 then
        lan_light_counter_L = lan_light_counter_L + passed * 0.1 * coef_27_L
    elseif landing_ext_L == 0 and lan_light_counter_L > 0 then
        lan_light_counter_L = lan_light_counter_L - passed * 0.1 * coef_27_L
    end
    lan_light_counter_L = clamp(lan_light_counter_L, 0, 1)

    if landing_ext_R == 1 and lan_light_counter_R < 1 then
        lan_light_counter_R = lan_light_counter_R + passed * 0.1 * coef_27_R
    elseif landing_ext_R == 0 and lan_light_counter_R > 0 then
        lan_light_counter_R = lan_light_counter_R - passed * 0.1 * coef_27_R
    end
    lan_light_counter_R = clamp(lan_light_counter_R, 0, 1)

    set(light_open_left, lan_light_counter_L)
    set(lamp_deploy_FL, lan_light_counter_R)
    set(lamp_deploy_WL, lan_light_counter_L)

    set(light_open_right, lan_light_counter_R)
    set(lamp_deploy_FR, lan_light_counter_R)
    set(lamp_deploy_WR, lan_light_counter_L)

    -- Landing- and taxi-light output calculations.
    local lan_light_WL = 0
    local lan_light_WR = 0
    local lan_light_FL = 0
    local lan_light_FR = 0
    local taxi_lit_L = 0
    local taxi_lit_R = 0

    if landing_mode_L == 1 then
        -- Wing landing-light pair follows the actual deployment position.
        lan_light_WL = coef_27_L * lan_light_counter_L * (1 - fail_WL) * landing_master
        lan_light_WR = coef_27_R * lan_light_counter_L * (1 - fail_WR) * landing_master
    elseif landing_mode_L == -1 then
        taxi_lit_L = coef_27_L
    end

    if landing_mode_R == 1 then
        -- Front landing-light pair follows the actual deployment position.
        lan_light_FL = coef_27_L * lan_light_counter_R * (1 - fail_FL) * landing_master
        lan_light_FR = coef_27_R * lan_light_counter_R * (1 - fail_FR) * landing_master
    elseif landing_mode_R == -1 then
        taxi_lit_R = coef_27_R
    end

    -- Nosewheel taxi lights must remain hidden until the nose gear is almost fully deployed.
    if get(deploy_ratio_1) <= 0.9 then
        taxi_lit_L = 0
        taxi_lit_R = 0
    end

    -- Flight signal lights.
    local light_signal = get(light_signal_set)
    local flight_lit = light_signal * (coef_27_L + coef_27_R) * 0.5
    set(sim_spot, flight_lit)

    -- Navigation lights.
    local nav_lit = get(nav_lights_set) * coef_27_R * bool2int(get(rel_lites_nav) ~= 6)
    if nav_lit > 0 then
        nav_lit = 1
    end
    set(sim_nav_light, nav_lit)

    -- White wing navigation strobes.
    -- Legacy alternating logic is intentionally retained as comments for future use.
    -- if nav_counter < 1 and nav_lit == 1 and get(gear_defl) > 0.05 and get(wing_light) == 1 then
    --     set(white_light_left, 1)
    --     set(white_light_right, 0)
    -- elseif nav_counter > 1 and nav_lit == 1 and get(gear_defl) > 0.05 and get(wing_light) == 1 then
    --     set(white_light_left, 0)
    --     set(white_light_right, 1)
    -- else
    --     set(white_light_left, 0)
    --     set(white_light_right, 0)
    -- end

    if nav_counter < 0.03 and nav_lit == 1 then
        set(white_light_left, 1)
        set(white_light_right, 1)
    else
        set(white_light_left, 0)
        set(white_light_right, 0)
    end

    nav_counter = nav_counter + passed
    if nav_counter > 1.1 then
        nav_counter = 0
    end

    -- Legacy anti-collision logic is intentionally retained as comments for future use.
    -- local anticoll_lit = get(sim_anticollision_light) * coef_27_R * coef_115
    -- if anticoll_lit > 0 then anticoll_lit = 1 end
    --
    -- if anticoll_counter < 0.05 and anticoll_lit == 1 then
    --     set(anticoll_light, 1)
    -- else
    --     set(anticoll_light, 0)
    -- end
    --
    -- anticoll_counter = anticoll_counter + passed
    -- if anticoll_counter > 1.1 then anticoll_counter = 0 end

    -- Red beacons.
    local beacons_lit = get(strobe_set) * coef_27_R * coef_115 * bool2int(get(rel_lites_beac) ~= 6)
    if beacons_lit > 0 then
        beacons_lit = 1
    end

    set(sim_beacon, beacons_lit)

    if beacon_counter_B < 0.05 and beacons_lit == 1 then
        set(beacon_light_B, 1)
    else
        set(beacon_light_B, 0)
    end

    beacon_counter_B = beacon_counter_B + passed
    if beacon_counter_B > 1.3 then
        beacon_counter_B = 0
    end

    if beacon_counter_T < 0.05 and beacons_lit == 1 then
        set(beacon_light_T, 1)
    else
        set(beacon_light_T, 0)
    end

    beacon_counter_T = beacon_counter_T + passed
    if beacon_counter_T > 1.4 then
        beacon_counter_T = 0
    end

    -- Tail logo light.
    local logo_lit = get(tail_light_set) * coef_27_R
    set(sim_logo, logo_lit)

    -- Wing and cargo lights.
    local wing_L_lit = get(wing_light_left_set) * coef_27_L
    local wing_R_lit = get(wing_light_right_set) * coef_27_R
    local cargo_1_lit = get(cargo_1) * coef_27_L
    local cargo_2_lit = get(cargo_2) * coef_27_R

    -- Electrical current consumption.
    -- Flight-signal current is calculated independently for each bus to avoid double voltage scaling.
    local current_L =
        (lan_light_WL + lan_light_FL) * 40
        + taxi_lit_L * 16
        + light_signal * coef_27_L * 16
        + wing_L_lit * 2
        + cargo_1_lit * 2

    local current_R =
        (lan_light_WR + lan_light_FR) * 40
        + taxi_lit_R * 16
        + light_signal * coef_27_R * 16
        + nav_lit * 8
        + logo_lit * 6
        + wing_R_lit * 1.5
        + cargo_2_lit * 2

    -- X-Plane light outputs. Original landing-light brightness scaling is preserved.
    set(sim_lan_FL, lan_light_FL * 1.5)
    set(sim_lan_FR, lan_light_FR * 1.5)
    set(sim_lan_WL, lan_light_WL * 1.5)
    set(sim_lan_WR, lan_light_WR * 1.5)
    set(sim_NW_L, taxi_lit_L)
    set(sim_NW_R, taxi_lit_R)
    set(sim_wings_L, wing_L_lit)
    set(sim_wings_R, wing_R_lit)
    set(sim_cargo_1, cargo_1_lit)
    set(sim_cargo_2, cargo_2_lit)

    -- Virtual Airlines compatibility workaround.
    if lan_light_WL + lan_light_WR + lan_light_FL + lan_light_FR > 0 then
        set(sim_lights_switch, 1)
    else
        set(sim_lights_switch, 0)
    end

    set(ext_light_cc_left, current_L)
    set(ext_light_cc_right, current_R)
end
