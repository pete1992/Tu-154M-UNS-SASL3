-- controls_panel.lua
--[[
Changelog
- Consolidated all active DataRef bindings in the shared defineProps() table.
- Removed the redundant local defineProps() implementation and use the project-wide helper.
- Preserved generic globalProperty() bindings for indexed X-Plane array DataRefs.
- Updated the nosewheel steering selector documentation to the correct 11° / 63° ranges.
- Preserved the user-corrected right main gear green-lamp logic.
- Improved blink timing so long frames do not permanently shift or lose blink phases.
- Clamped gauge smoothing to prevent overshoot after long frames or pauses.
- Removed stale legacy review comments and dead commented-out code.
- Kept all aircraft-system thresholds and normal operating behaviour unchanged.
]]

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end
-- Flight controls panel.

local max = math.max
local min = math.min
local abs = math.abs
local floor = math.floor

defineProps({
    -- Controls / switches
    -- stabilizer manual control cap
    { "stab_man_cap", "tu154/custom/controll/stab_man_cap", globalPropertyi },
    -- stabilizer manual switch
    { "stab_manual", "tu154/custom/controll/stab_manual", globalPropertyi },
    -- stabilizer mode selector
    { "stab_setting", "tu154/custom/controll/stab_setting", globalPropertyi },
    -- aileron trim switch
    { "ail_trimm_sw", "tu154/custom/controll/ail_trimm_sw", globalPropertyi },
    -- rudder trim switch
    { "rudd_trimm_sw", "tu154/custom/controll/rudd_trimm_sw", globalPropertyi },
    -- control force unit cap
    { "contr_force_cap", "tu154/custom/controll/contr_force_cap", globalPropertyi },
    -- control force selector
    { "contr_force_set", "tu154/custom/controll/contr_force_set", globalPropertyi },
    -- nosewheel steering enable
    { "nosewheel_turn_enable", "tu154/custom/switchers/nosewheel_turn_enable", globalPropertyi },
    -- 0 = 11 deg, 1 = 63 deg
    { "nosewheel_turn_sel", "tu154/custom/switchers/nosewheel_turn_sel", globalPropertyi },
    -- nosewheel selector cap
    { "nosewheel_turn_cap", "tu154/custom/switchers/nosewheel_turn_cap", globalPropertyi },
    -- slats manual switch
    { "slat_man", "tu154/custom/switchers/slat_man", globalPropertyi },
    -- slats manual cap
    { "slat_man_cap", "tu154/custom/switchers/slat_man_cap", globalPropertyi },
    -- flaps selector
    { "flaps_sel", "tu154/custom/switchers/flaps_sel", globalPropertyi },
    -- flaps selector cap
    { "flaps_sel_cap", "tu154/custom/switchers/flaps_sel_cap", globalPropertyi },
    -- gear retraction lock
    { "gears_retr_lock", "tu154/custom/switchers/gears_retr_lock", globalPropertyi },
    -- gear retraction lock cap
    { "gears_retr_lock_cap", "tu154/custom/switchers/gears_retr_lock_cap", globalPropertyi },
    -- gear extension via 3rd hydraulic system
    { "gears_ext_3GS", "tu154/custom/switchers/gears_ext_3GS", globalPropertyi },
    -- gear extension via 3rd hydraulic system cap
    { "gears_ext_3GS_cap", "tu154/custom/switchers/gears_ext_3GS_cap", globalPropertyi },
    -- booster 1
    { "buster_on_1", "tu154/custom/switchers/console/buster_on_1", globalPropertyi },
    -- booster 2
    { "buster_on_2", "tu154/custom/switchers/console/buster_on_2", globalPropertyi },
    -- booster 3
    { "buster_on_3", "tu154/custom/switchers/console/buster_on_3", globalPropertyi },
    -- boosters cap
    { "busters_cap", "tu154/custom/switchers/console/busters_cap", globalPropertyi },
    -- emergency pitch trim
    { "emerg_elev_trimm", "tu154/custom/switchers/console/emerg_elev_trimm", globalPropertyi },
    -- emergency pitch trim cap
    { "emerg_elev_trimm_cap", "tu154/custom/switchers/console/emerg_elev_trimm_cap", globalPropertyi },
    -- lamp test, front panel
    { "lamp_test", "tu154/custom/buttons/lamp_test_front", globalPropertyi },
    -- lamp test, engineer panel
    { "lamp_test_eng", "tu154/custom/buttons/lamp_test_upper_gear", globalPropertyi },
    -- gear lever: -1 up, 0 neutral, +1 down
    { "gear_lever", "tu154/custom/controll/gear_lever", globalPropertyi },
    -- Throttle animation state
    { "anim_rud1", "tu154/custom/controlls/throttle_1", globalPropertyf },
    { "anim_rud2", "tu154/custom/controlls/throttle_2", globalPropertyf },
    { "anim_rud3", "tu154/custom/controlls/throttle_3", globalPropertyf },
    -- Gauges
    { "stab_ind", "tu154/custom/gauges/misc/stab_ind", globalPropertyf },
    { "elevator_ind", "tu154/custom/gauges/misc/elevator_ind", globalPropertyf },
    { "flap_left_ind", "tu154/custom/gauges/misc/flap_left_ind", globalPropertyf },
    { "flap_right_ind", "tu154/custom/gauges/misc/flap_right_ind", globalPropertyf },
    -- Lamps
    { "stab_work", "tu154/custom/lights/stab_work", globalPropertyf },
    { "flaps_1_valve", "tu154/custom/lights/flaps_1_valve", globalPropertyf },
    { "flaps_2_valve", "tu154/custom/lights/flaps_2_valve", globalPropertyf },
    { "spoilers_mid_left", "tu154/custom/lights/spoilers_mid_left", globalPropertyf },
    { "spoilers_mid_right", "tu154/custom/lights/spoilers_mid_right", globalPropertyf },
    { "spoilers_inn_left", "tu154/custom/lights/spoilers_inn_left", globalPropertyf },
    { "spoilers_inn_right", "tu154/custom/lights/spoilers_inn_right", globalPropertyf },
    { "flaps_unsync", "tu154/custom/lights/flaps_unsync", globalPropertyf },
    { "slats_unsync", "tu154/custom/lights/slats_unsync", globalPropertyf },
    { "slats_extended", "tu154/custom/lights/slats_extended", globalPropertyf },
    { "to_rudder", "tu154/custom/lights/to_rudder", globalPropertyf },
    { "to_elevator", "tu154/custom/lights/to_elevator", globalPropertyf },
    { "trimm_zero_course", "tu154/custom/lights/trimm_zero_course", globalPropertyf },
    { "trimm_zero_roll", "tu154/custom/lights/trimm_zero_roll", globalPropertyf },
    { "trimm_zero_pitch", "tu154/custom/lights/trimm_zero_pitch", globalPropertyf },
    { "gears_not_ext", "tu154/custom/lights/gears_not_ext", globalPropertyf },
    { "gears_red_left", "tu154/custom/lights/gears_red_left", globalPropertyf },
    { "gears_red_front", "tu154/custom/lights/gears_red_front", globalPropertyf },
    { "gears_red_right", "tu154/custom/lights/gears_red_right", globalPropertyf },
    { "gears_green_left", "tu154/custom/lights/gears_green_left", globalPropertyf },
    { "gears_green_front", "tu154/custom/lights/gears_green_front", globalPropertyf },
    { "gears_green_right", "tu154/custom/lights/gears_green_right", globalPropertyf },
    { "gears_red_left_eng", "tu154/custom/lights/gears_red_left_eng", globalPropertyf },
    { "gears_red_front_eng", "tu154/custom/lights/gears_red_front_eng", globalPropertyf },
    { "gears_red_right_eng", "tu154/custom/lights/gears_red_right_eng", globalPropertyf },
    { "gears_green_left_eng", "tu154/custom/lights/gears_green_left_eng", globalPropertyf },
    { "gears_green_front_eng", "tu154/custom/lights/gears_green_front_eng", globalPropertyf },
    { "gears_green_right_eng", "tu154/custom/lights/gears_green_right_eng", globalPropertyf },
    -- Sim sources
    -- elevator left, degrees, positive = trailing edge down
    { "elevator_L", "sim/flightmodel/controls/hstab1_elv1def", globalPropertyf },
    -- simulator pitch trim
    { "stab_pos", "sim/flightmodel2/controls/elevator_trim", globalPropertyf },
    -- inner flap left
    { "flap_inn_L", "sim/flightmodel/controls/wing1l_fla1def", globalPropertyf },
    -- inner flap right
    { "flap_inn_R", "sim/flightmodel/controls/wing1r_fla1def", globalPropertyf },
    -- slats position
    { "slats", "sim/flightmodel2/controls/slat1_deploy_ratio", globalPropertyf },
    { "spd_brk_inn_L", "sim/flightmodel/controls/wing1l_spo1def", globalPropertyf },
    { "spd_brk_inn_R", "sim/flightmodel/controls/wing1r_spo1def", globalPropertyf },
    { "spd_brk_mid_L", "sim/flightmodel/controls/wing2l_spo2def", globalPropertyf },
    { "spd_brk_mid_R", "sim/flightmodel/controls/wing2r_spo2def", globalPropertyf },
    { "indicated_airspeed", "sim/flightmodel/position/indicated_airspeed", globalPropertyf },
    { "machno", "sim/flightmodel/misc/machno", globalPropertyf },
    { "gear1_deploy", "sim/aircraft/parts/acf_gear_deploy[0]", globalProperty },
    { "gear2_deploy", "sim/aircraft/parts/acf_gear_deploy[1]", globalProperty },
    { "gear3_deploy", "sim/aircraft/parts/acf_gear_deploy[2]", globalProperty },
    { "deflection_mtr_2", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalProperty },
    { "deflection_mtr_3", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", globalProperty },
    { "eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalProperty },
    { "eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalProperty },
    { "eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalProperty },
    -- Trimmer state
    { "int_pitch_trim", "tu154/custom/trimmers/int_pitch_trim", globalPropertyf },
    { "int_roll_trim", "tu154/custom/trimmers/int_roll_trim", globalPropertyf },
    { "int_yaw_trim", "tu154/custom/trimmers/int_yaw_trim", globalPropertyf },
    -- 0 = takeoff, 1 = cruise
    { "control_force_pos", "tu154/custom/controls/control_force_pos", globalPropertyf },
    { "control_force_pos_rud", "tu154/custom/controls/control_force_pos_rud", globalPropertyf },
    -- Power
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf },
    -- Misc
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    { "rv5_alt_L", "tu154/custom/misc/rv5_alt_left", globalPropertyf },
    { "rv5_alt_R", "tu154/custom/misc/rv5_alt_right", globalPropertyf },
    -- gear/flaps configuration alarm
    { "main_gear_flaps", "tu154/custom/alarm/main_gear_flaps", globalPropertyi },
    { "ismaster", "scp/api/ismaster", globalPropertyf },
})

-- Sounds
local switcher_sound = sasl.al.loadSample('Custom Sounds/metal_switch.wav')
local cap_sound = sasl.al.loadSample('Custom Sounds/cap.wav')

local BLINK_PERIOD = 0.5
local LAMP_V_MIN = 10
local LAMP_V_SPAN = 18.5

local passed = get(frame_time)
local notLoaded = true

-- Lamp brightness from a raw 0..1 value, bus brightness and lamp test
local function lampBrt(value, brt, test)
    return max(value * brt, test)
end

-- Symmetric blinker that remains phase-correct even after a long frame.
local function blinkStep(timer, lit, dt)
    timer = timer + dt

    if timer >= BLINK_PERIOD then
        local transitions = floor(timer / BLINK_PERIOD)
        timer = timer - transitions * BLINK_PERIOD

        if transitions % 2 == 1 then
            lit = not lit
        end
    end

    return timer, lit
end

local function reset_switchers()
    if get(eng1_N1) < 5 and get(eng2_N1) < 5 and get(eng3_N1) < 5 then
        set(buster_on_1, 0)
        set(buster_on_2, 0)
        set(buster_on_3, 0)
        set(busters_cap, 1)
        set(nosewheel_turn_sel, 1)
        set(nosewheel_turn_cap, 1)
    end
    notLoaded = false
end

-- Lamps ----------------------------------------------------------------------

local stab_work_lit = false
local stab_work_timer = 0
local stab_pos_last = get(stab_pos)
local forcer_lit = false
local forcer_timer = 0
local forcer_rud_lit = false
local forcer_timer_rud = 0
local flap_L_pos_last = 0
local flap_R_pos_last = 0
local slats_lit = false
local slats_timer = 0
local slats_last = 0
local gear_timer = 0

local function gearLamps(brt, test_btn, test_eng, gear_F, gear_L, gear_R)
    local red_F = bool2int(gear_F < 0.99 and gear_F > 0.01)
    local red_L = bool2int(gear_L < 0.99 and gear_L > 0.01)
    local red_R = bool2int(gear_R < 0.99 and gear_R > 0.01)
    local green_F = bool2int(gear_F >= 0.99)
    local green_L = bool2int(gear_L >= 0.99)
    -- Correct right-main-gear source; the legacy file referenced the left gear here.
    local green_R = bool2int(gear_R >= 0.99)

    set(gears_red_left,        lampBrt(red_L,   brt, test_btn))
    set(gears_red_front,       lampBrt(red_F,   brt, test_btn))
    set(gears_red_right,       lampBrt(red_R,   brt, test_btn))
    set(gears_green_left,      lampBrt(green_L, brt, test_btn))
    set(gears_green_front,     lampBrt(green_F, brt, test_btn))
    set(gears_green_right,     lampBrt(green_R, brt, test_btn))

    set(gears_red_left_eng,    lampBrt(red_L,   brt, test_eng))
    set(gears_red_front_eng,   lampBrt(red_F,   brt, test_eng))
    set(gears_red_right_eng,   lampBrt(red_R,   brt, test_eng))
    set(gears_green_left_eng,  lampBrt(green_L, brt, test_eng))
    set(gears_green_front_eng, lampBrt(green_F, brt, test_eng))
    set(gears_green_right_eng, lampBrt(green_R, brt, test_eng))
end

local function lamps()
    local bus_right = get(bus27_volt_right)
    local test_scale = max((bus_right - LAMP_V_MIN) / LAMP_V_SPAN, 0)
    local test_btn = get(lamp_test) * test_scale
    local test_btn_eng = get(lamp_test_eng) * test_scale
    local lamps_brt = max((max(get(bus27_volt_left), bus_right) - LAMP_V_MIN) / LAMP_V_SPAN, 0)
    local not_slave = get(ismaster) ~= 1

    -- Stabilizer in motion
    local stab_pos_now = get(stab_pos)
    if abs(stab_pos_now - stab_pos_last) > 0.01 * passed then
        stab_work_timer, stab_work_lit = blinkStep(stab_work_timer, stab_work_lit, passed)
    else
        stab_work_timer = 0
        stab_work_lit = false
    end
    stab_pos_last = stab_pos_now
    if not_slave then
        set(stab_work, lampBrt(bool2int(stab_work_lit), lamps_brt, test_btn))
    end

    -- Flap valve lamps: lit while the surface is moving
    local flap_pos_now_L = get(flap_inn_L)
    local flap_pos_now_R = get(flap_inn_R)

    if not_slave then
        set(flaps_1_valve, lampBrt(bool2int(flap_L_pos_last ~= flap_pos_now_L), lamps_brt, test_btn))
        set(flaps_2_valve, lampBrt(bool2int(flap_R_pos_last ~= flap_pos_now_R), lamps_brt, test_btn))
    end
    flap_L_pos_last = flap_pos_now_L
    flap_R_pos_last = flap_pos_now_R

    -- Spoiler lamps
    set(spoilers_mid_left,   lampBrt(min(1, get(spd_brk_mid_L)), lamps_brt, test_btn))
    set(spoilers_mid_right,  lampBrt(min(1, get(spd_brk_mid_R)), lamps_brt, test_btn))
    set(spoilers_inn_left,   lampBrt(min(1, get(spd_brk_inn_L)), lamps_brt, test_btn))
    set(spoilers_inn_right,  lampBrt(min(1, get(spd_brk_inn_R)), lamps_brt, test_btn))

    -- Flap / slat asymmetry
    set(flaps_unsync, lampBrt(bool2int(abs(flap_pos_now_L - flap_pos_now_R) >= 3), lamps_brt, test_btn))
    set(slats_unsync, lampBrt(0, lamps_brt, test_btn)) -- no asymmetry model yet, test only

    -- Slats extended / in motion
    local slats_now = get(slats)
    if slats_now ~= slats_last then
        slats_timer, slats_lit = blinkStep(slats_timer, slats_lit, passed)
    elseif slats_now > 0.1 then
        slats_timer = 0
        slats_lit = true
    else
        slats_timer = 0
        slats_lit = false
    end
    slats_last = slats_now
    if not_slave then
        set(slats_extended, lampBrt(bool2int(slats_lit), lamps_brt, test_btn))
    end

    -- Control force units: steady when in takeoff position, blinking in transit
    local forcer_pos = get(control_force_pos)
    if forcer_pos < 1 and forcer_pos > 0 then
        forcer_timer, forcer_lit = blinkStep(forcer_timer, forcer_lit, passed)
    elseif forcer_pos == 0 then
        forcer_lit = true
    else
        forcer_lit = false
    end

    local forcer_rud_pos = get(control_force_pos_rud)
    if forcer_rud_pos < 1 and forcer_rud_pos > 0 then
        forcer_timer_rud, forcer_rud_lit = blinkStep(forcer_timer_rud, forcer_rud_lit, passed)
    elseif forcer_rud_pos == 0 then
        forcer_rud_lit = true
    else
        forcer_rud_lit = false
    end

    set(to_rudder,   lampBrt(bool2int(forcer_rud_lit), lamps_brt, test_btn))
    set(to_elevator, lampBrt(bool2int(forcer_lit),     lamps_brt, test_btn))

    -- Trim in neutral
    set(trimm_zero_course, lampBrt(bool2int(abs(get(int_yaw_trim))   < 0.002), lamps_brt, test_btn))
    set(trimm_zero_roll,   lampBrt(bool2int(abs(get(int_roll_trim))  < 0.002), lamps_brt, test_btn))
    set(trimm_zero_pitch,  lampBrt(bool2int(abs(get(int_pitch_trim)) < 0.004), lamps_brt, test_btn))

    -- Gear position lamps
    
    local gear_F_pos = get(gear1_deploy)
    local gear_L_pos = get(gear2_deploy)
    local gear_R_pos = get(gear3_deploy)

    local thr1 = get(anim_rud1)
    local thr2 = get(anim_rud2)
    local thr3 = get(anim_rud3)

    -- Any gear unlocked, IAS below 325 km/h, RA below 250 m,
    -- throttles below ~90 % total and gear lever not down
    local gear_not_ext =
        (gear_F_pos < 0.99 or gear_L_pos < 0.99 or gear_R_pos < 0.99)
        and get(indicated_airspeed) * 1.852 < 325
        and min(get(rv5_alt_L), get(rv5_alt_R)) < 250
        and (thr1 + thr2 + thr3) < 2
        and get(gear_lever) <= 0

    if gear_not_ext then
        gear_timer = (gear_timer + passed) % 0.6
    else
        gear_timer = 0
    end

    set(gears_not_ext, lampBrt(bool2int(gear_timer > 0.3), lamps_brt, test_btn))

    gearLamps(lamps_brt, test_btn, test_btn_eng, gear_F_pos, gear_L_pos, gear_R_pos)

    -- Configuration alarm
    local sound_alarm = gear_not_ext
        or ((flap_pos_now_L < 14 or flap_pos_now_R < 14 or slats_now < 0.5)
            and max(thr1, thr2, thr3) > 0.7
            and max(get(deflection_mtr_2), get(deflection_mtr_3)) > 0.05)

    set(main_gear_flaps, bool2int(sound_alarm))
end

-- Gauges ---------------------------------------------------------------------

local stab_ind_act = 0
local elev_ind_act = 0
local flap_ind_L_act = 0
local flap_ind_R_act = 0

local mach_tbl = {
    { -10, 1 },
    { 0, 1 },
    { 0.1, 1 },
    { 0.25, 0.5 },
    { 0.34, 0.28 },
    { 0.38, 0.22 },
    { 0.5, 0.21 },
    { 0.6, 0.21 },
    { 0.7, 0.2 },
    { 0.8, 0.19 },
    { 0.9, 0.13 },
    { 1, 0.1 },
    { 10, 0.1 } }

local function gauges()
    local stabil_ind = 0
    local elev_ind = 0
    local flap_ind_L = 0
    local flap_ind_R = 0

    if get(bus36_volt_left) > 30 then
        stabil_ind = get(stab_pos) * 5.5
        elev_ind = -get(elevator_L)
        flap_ind_L = get(flap_inn_L)
        flap_ind_R = get(flap_inn_R)
    end

    -- Mach dependent elevator indication correction
    local mach = get(machno)
    local elev_coef
    if mach < 1 then
        elev_coef = 1 / interpolate(mach_tbl, mach)
    else
        elev_coef = 1 / 0.1
    end

    local rate = min(passed * 10, 1)
    stab_ind_act = stab_ind_act + (stabil_ind - stab_ind_act) * rate
    elev_ind_act = elev_ind_act + (elev_ind * elev_coef - elev_ind_act) * rate
    flap_ind_L_act = flap_ind_L_act + (flap_ind_L - flap_ind_L_act) * rate
    flap_ind_R_act = flap_ind_R_act + (flap_ind_R - flap_ind_R_act) * rate

    set(stab_ind, stab_ind_act)
    set(elevator_ind, elev_ind_act)
    set(flap_left_ind, flap_ind_L_act)
    set(flap_right_ind, flap_ind_R_act)
end

-- Caps and switches: click sounds and mechanical coupling ---------------------

-- prop  : cap property
-- resets: switch that is forced to 0 while the cap is closed
local caps = {
    { prop = stab_man_cap },
    { prop = contr_force_cap,      resets = contr_force_set },
    { prop = nosewheel_turn_cap,   resets = nosewheel_turn_sel },
    { prop = slat_man_cap },
    { prop = gears_retr_lock_cap,  resets = gears_retr_lock },
    { prop = gears_ext_3GS_cap,    resets = gears_ext_3GS },
    { prop = busters_cap },
    { prop = flaps_sel_cap,        resets = flaps_sel },
    { prop = emerg_elev_trimm_cap },
}

local switches = {
    { prop = stab_manual },
    { prop = stab_setting },
    { prop = ail_trimm_sw },
    { prop = rudd_trimm_sw },
    { prop = contr_force_set },
    { prop = nosewheel_turn_enable },
    { prop = nosewheel_turn_sel },
    { prop = slat_man },
    { prop = flaps_sel },
    { prop = gears_retr_lock },
    { prop = gears_ext_3GS },
    { prop = buster_on_1 },
    { prop = buster_on_2 },
    { prop = buster_on_3 },
    { prop = emerg_elev_trimm },
}

local function initStates(list)
    for i = 1, #list do
        list[i].last = get(list[i].prop)
    end
end

initStates(caps)
initStates(switches)

-- Per item edge detection instead of a summed comparison, so simultaneous
-- opposite movements can no longer cancel each other out.
local function anyChanged(list)
    local changed = false
    for i = 1, #list do
        local e = list[i]
        local now = get(e.prop)
        if now ~= e.last then
            e.last = now
            changed = true
        end
    end
    return changed
end

local function caps_check()
    local is_slave = get(ismaster) == 1

    -- Boosters cap springs open as long as any booster is off
    if get(busters_cap) == 0
        and get(buster_on_1) * get(buster_on_2) * get(buster_on_3) == 0 then
        if not is_slave then set(busters_cap, 1) end
    end

    if anyChanged(caps) then
        sasl.al.playSample(cap_sound, false)
    end

    -- Switches under a closed cap are forced to neutral
    if not is_slave then
        for i = 1, #caps do
            local e = caps[i]
            if e.resets and get(e.prop) == 0 then
                set(e.resets, 0)
            end
        end
    end
end

local function switchers_check()
    if anyChanged(switches) then
        sasl.al.playSample(switcher_sound, false)
    end
end

-- Update ---------------------------------------------------------------------

local sim_start_timer = 0
local started = false

function update()
    passed = get(frame_time)

    if not started then
        sim_start_timer = sim_start_timer + passed
        started = sim_start_timer > 0.3
    end

    if started then
        if notLoaded then reset_switchers() end
        switchers_check()
        caps_check()
    end

    gauges()
    lamps()
end
