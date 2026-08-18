-- misc_lamps.lua
-- Miscellaneous cockpit lamp logic.

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"lamp_test", "tu154/custom/buttons/lamp_test_front", globalPropertyi},
    {"day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf},
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
    {"dh_lamp", "tu154/custom/lights/decision_height", globalPropertyf},
    {"to_not_ready", "tu154/custom/lights/to_not_ready", globalPropertyf},
    {"fuel_less_2500", "tu154/custom/lights/fuel_less_2500", globalPropertyf},
    {"sso_danger", "tu154/custom/lights/sso_danger", globalPropertyf},
    {"sso_connect", "tu154/custom/lights/sso_connect", globalPropertyf},
    {"speed_high", "tu154/custom/lights/speed_high", globalPropertyf},
    {"damper_course", "tu154/custom/lights/damper_course", globalPropertyf},
    {"damper_roll", "tu154/custom/lights/damper_roll", globalPropertyf},
    {"damper_pitch", "tu154/custom/lights/damper_pitch", globalPropertyf},
    {"no_reserve_c", "tu154/custom/lights/no_reserve_c", globalPropertyf},
    {"no_reserve_g", "tu154/custom/lights/no_reserve_g", globalPropertyf},
    {"msg_lamp", "tu154/custom/lights/msg_lamp", globalPropertyf},
    {"wpt_lamp", "tu154/custom/lights/wpt_lamp", globalPropertyf},
    {"stuard_call", "tu154/custom/lights/stuard_call", globalPropertyf},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"rv5_dh_signal_left", "tu154/custom/misc/rv5_dh_signal_left", globalPropertyi},
    {"rv5_dh_signal_right", "tu154/custom/misc/rv5_dh_signal_right", globalPropertyi},
    {"nosewheel_steer_on", "sim/cockpit2/controls/nosewheel_steer_on", globalPropertyi},
    {"nosewheel_turn_sel", "tu154/custom/switchers/nosewheel_turn_sel", globalPropertyi},
    {"cargo_1", "tu154/custom/anim/cargo_1", globalPropertyf},
    {"cargo_2", "tu154/custom/anim/cargo_2", globalPropertyf},
    {"pax_door_1", "tu154/custom/anim/pax_door_1", globalPropertyf},
    {"pax_door_2", "tu154/custom/anim/pax_door_2", globalPropertyf},
    {"pax_door_3", "tu154/custom/anim/pax_door_3", globalPropertyf},
    {"busters_cap", "tu154/custom/switchers/console/busters_cap", globalPropertyi},
    {"spd_brk_inn_L", "sim/flightmodel/controls/wing1l_spo1def", globalPropertyf},
    {"spd_brk_inn_R", "sim/flightmodel/controls/wing1r_spo1def", globalPropertyf},
    {"slats", "sim/flightmodel2/controls/slat1_deploy_ratio", globalPropertyf},
    {"gear2_deflect", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalProperty},
    {"gear3_deflect", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", globalProperty},
    {"tank1_w", "sim/flightmodel/weight/m_fuel[0]", globalProperty},
    {"ias_L", "sim/cockpit2/gauges/indicators/airspeed_kts_pilot", globalPropertyf},
    {"ias_R", "sim/cockpit2/gauges/indicators/airspeed_kts_copilot", globalPropertyf},
    {"msl_alt", "sim/flightmodel/position/elevation", globalPropertyf},
    {"msl_press", "sim/weather/barometer_sealevel_inhg", globalPropertyf},
    {"mach_sim", "sim/flightmodel/misc/machno", globalPropertyf},
    {"rel_pitot", "sim/operation/failures/rel_pitot", globalPropertyi},
    {"WPTalert", "tu154/custom/xap/KLN90/WPT", globalPropertyi},
    {"MSGalert", "tu154/custom/xap/KLN90/MSG", globalPropertyi},
    {"speaker_speed", "tu154/custom/alarm/speaker_speed", globalPropertyi},
    {"damp_roll_lamp", "tu154/custom/absu/damp_roll_lamp", globalPropertyi},
    {"damp_pitch_lamp", "tu154/custom/absu/damp_pitch_lamp", globalPropertyi},
    {"damp_yaw_lamp", "tu154/custom/absu/damp_yaw_lamp", globalPropertyi},
    {"absu_landing_on", "tu154/custom/switchers/console/absu_landing_on", globalPropertyi},
    {"nav1_pow_cc", "tu154/custom/radio/nav1_pow_cc", globalPropertyf},
    {"nav2_pow_cc", "tu154/custom/radio/nav2_pow_cc", globalPropertyf},
    {"nav1_fail", "tu154/custom/failures/nav1_fail", globalPropertyi},
    {"nav2_fail", "tu154/custom/failures/nav2_fail", globalPropertyi},
    {"to_ready", "tu154/custom/checklist/to_ready", globalPropertyi},
})

local button_sound = sasl.al.loadSample("Custom Sounds/plastic_btn.wav")

local button_last = 0
local DH = 0

local to_not_ready_counter = 0
local to_not_ready_lit = 0

local fuel2500_counter = 0
local fuel2500_lit = 0

local WPT_counter = 0
local WPT_lit = 0

local MSG_counter = 0
local MSG_lit = 0

local TO_notReadyAct = 0


function update()
    local passed = get(frame_time)

    -- Lamp test button and general lamp brightness.
    local test_btn = get(lamp_test)

    if button_last ~= test_btn then
        sasl.al.playSample(button_sound, false)
    end

    button_last = test_btn

    test_btn =
        test_btn
        * math.max((get(bus27_volt_right) - 10) / 18.5, 0)

    local day_night = 1 - get(day_night_set) * 0.25

    local lamps_brt =
        math.max(
            (math.max(get(bus27_volt_left), get(bus27_volt_right)) - 10) / 18.5,
            0
        )
        * day_night

    -- Decision height lamp.
    DH = math.max(
        get(rv5_dh_signal_left),
        get(rv5_dh_signal_right)
    )

    local dh_lamp_brt =
        math.max(DH * lamps_brt, test_btn)

    set(dh_lamp, dh_lamp_brt)

    -- Takeoff not-ready warning.
    local TO_ready =
        get(nosewheel_steer_on) == 1
        and get(nosewheel_turn_sel) == 0
        and get(busters_cap) == 0

    TO_ready =
        TO_ready
        and get(cargo_1)
            + get(cargo_2)
            + get(pax_door_1)
            + get(pax_door_2)
            + get(pax_door_3) == 0

    TO_ready =
        TO_ready
        and get(spd_brk_inn_L) + get(spd_brk_inn_R) < 1
        and get(slats) > 0.9

    -- Disable the takeoff warning once the aircraft is airborne.
    TO_ready =
        TO_ready
        or (
            get(gear2_deflect) < 0.05
            or get(gear3_deflect) < 0.05
        )

    if not TO_ready then
        to_not_ready_counter =
            to_not_ready_counter + passed

        if to_not_ready_counter > 0.3 then
            to_not_ready_lit = 1 - to_not_ready_lit
            to_not_ready_counter = 0
        end

        set(to_ready, 1)
    else
        to_not_ready_counter = 0
        to_not_ready_lit = 0

        set(to_ready, 0)
    end

    TO_notReadyAct =
        TO_notReadyAct
        + (to_not_ready_lit - TO_notReadyAct) * passed * 10

    local to_not_ready_brt =
        math.max(TO_notReadyAct * lamps_brt, test_btn)

    set(to_not_ready, to_not_ready_brt)

    -- Fuel below 2500 kg warning.
    if get(tank1_w) < 2500 then
        fuel2500_counter = fuel2500_counter + passed

        if fuel2500_counter > 0.3 then
            fuel2500_lit = 1 - fuel2500_lit
            fuel2500_counter = 0
        end
    else
        fuel2500_counter = 0
        fuel2500_lit = 0
    end

    local fuel_less_2500_brt =
        math.max(fuel2500_lit * lamps_brt, test_btn)

    set(fuel_less_2500, fuel_less_2500_brt)

    -- Overspeed warning.
    local alt_std_mtr =
        (
            get(msl_alt) * 3.28083
            + (29.92 - get(msl_press)) * 1000
        )
        / 3.28083

    local ias = get(ias_L) * 1.852

    if get(rel_pitot) == 6 then
        ias = get(ias_R) * 1.852
    end

    local mach = get(mach_sim)

    local over_spd =
        (alt_std_mtr < 7000 and ias > 600)
        or (
            alt_std_mtr >= 7000
            and alt_std_mtr < 10300
            and ias > 675
        )
        or (
            alt_std_mtr >= 10300
            and mach > 0.93
        )

    set(speaker_speed, bool2int(over_spd))

    local speed_high_brt =
        math.max(bool2int(over_spd) * lamps_brt, test_btn)

    set(speed_high, speed_high_brt)

    -- KLN MSG alert.
    if get(MSGalert) == 1 then
        MSG_counter = MSG_counter + passed

        if MSG_counter > 0.3 then
            MSG_lit = 1 - MSG_lit
            MSG_counter = 0
        end
    else
        MSG_counter = 0
        MSG_lit = 0
    end

    local msg_lamp_brt =
        math.max(MSG_lit * lamps_brt, test_btn)

    set(msg_lamp, msg_lamp_brt)

    -- KLN WPT alert.
    if get(WPTalert) == 1 then
        WPT_counter = WPT_counter + passed

        if WPT_counter > 0.3 then
            WPT_lit = 1 - WPT_lit
            WPT_counter = 0
        end
    else
        WPT_counter = 0
        WPT_lit = 0
    end

    local wpt_lamp_brt =
        math.max(WPT_lit * lamps_brt, test_btn)

    set(wpt_lamp, wpt_lamp_brt)

    -- ABSU damper lamps.
    local damper_course_brt =
        math.max(get(damp_yaw_lamp) * lamps_brt, test_btn)

    set(damper_course, damper_course_brt)

    local damper_roll_brt =
        math.max(get(damp_roll_lamp) * lamps_brt, test_btn)

    set(damper_roll, damper_roll_brt)

    local damper_pitch_brt =
        math.max(get(damp_pitch_lamp) * lamps_brt, test_btn)

    set(damper_pitch, damper_pitch_brt)

    -- CourseMP reserve lamps.
    local reserve_missing =
        get(absu_landing_on) == 1
        and (
            get(nav1_fail) == 1
            or get(nav2_fail) == 1
            or get(nav1_pow_cc) == 0
            or get(nav2_pow_cc) == 0
        )

    local no_reserve_c_brt =
        math.max(
            bool2int(reserve_missing) * lamps_brt,
            test_btn
        )

    set(no_reserve_c, no_reserve_c_brt)

    local no_reserve_g_brt =
        math.max(
            bool2int(reserve_missing) * lamps_brt,
            test_btn
        )

    set(no_reserve_g, no_reserve_g_brt)

    -- Placeholder lamps.
    set(sso_danger, test_btn)
    set(sso_connect, test_btn)
    set(stuard_call, test_btn)
end
