-- ext_anim.lua
-- SASL

defineProperty("xp_version", globalPropertyi("sim/version/xplane_internal_version"))
local XP11 = get(xp_version) > 120000

local function defineProps(defs)
    -- Correct: build property handles by calling the constructor with path
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Frame timing and replay
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf}, -- time of frame
    {"replay_mode", "sim/operation/prefs/replay_mode", globalPropertyi},
    -- Reverse handles
    {"revers_L", "tu154/custom/controlls/revers_L", globalPropertyf},
    {"revers_R", "tu154/custom/controlls/revers_R", globalPropertyf},
    {"reverse_mid", "tu154/custom/anim/reverse_mid", globalPropertyf},
    -- Gear positions and deflections
    {"front_pos", "tu154/custom/anim/lg/front_pos", globalPropertyf}, -- nose gear position
    {"front_defl", "tu154/custom/anim/lg/front_defl", globalPropertyf}, -- nose gear shock absorber deflection
    {"front_turn", "tu154/custom/anim/lg/front_turn", globalPropertyf}, -- nose gear steering angle
    {"main_pos_left", "tu154/custom/anim/lg/main_pos_left", globalPropertyf}, -- left main gear position (0–1 = extend, -1…-5 = compression)
    {"main_rot_left", "tu154/custom/anim/lg/main_rot_left", globalPropertyf}, -- left bogie rotation on ground (0 = horizontal, -11 = in flight)
    {"main_pos_right", "tu154/custom/anim/lg/main_pos_right", globalPropertyf}, -- right main gear position (see above)
    {"main_rot_right", "tu154/custom/anim/lg/main_rot_right", globalPropertyf}, -- right bogie rotation on ground
    -- Tail control surfaces
    {"rudder_anim", "tu154/custom/anim/rudder_anim", globalPropertyf}, -- rudder deflection angle for animation
    {"elev_anim_L", "tu154/custom/anim/elev_anim_L", globalPropertyf}, -- elevator deflection angle (left)
    {"elev_anim_R", "tu154/custom/anim/elev_anim_R", globalPropertyf}, -- elevator deflection angle (right)
    -- Wing flex
    {"wing_flx_right", "tu154/custom/anim/wing_flx_right", globalPropertyf}, -- wing flex angle (right)
    {"wing_flx_left", "tu154/custom/anim/wing_flx_left", globalPropertyf}, -- wing flex angle (left)
    -- Windows and doors
    {"cockpit_window_left", "tu154/custom/anim/cockpit_window_left", globalPropertyf}, -- cockpit side window open
    {"cockpit_window_right", "tu154/custom/anim/cockpit_window_right", globalPropertyf}, -- cockpit side window open
    {"cargo_1", "tu154/custom/anim/cargo_1", globalPropertyf}, -- cargo door 1
    {"cargo_2", "tu154/custom/anim/cargo_2", globalPropertyf}, -- cargo door 2
    {"pax_door_1", "tu154/custom/anim/pax_door_1", globalPropertyf}, -- passenger door 1
    {"pax_door_2", "tu154/custom/anim/pax_door_2", globalPropertyf}, -- passenger door 2
    {"pax_door_3", "tu154/custom/anim/pax_door_3", globalPropertyf}, -- passenger door 3
    {"cockpit_door", "tu154/custom/anim/cockpit_door", globalPropertyf}, -- cockpit door
    {"cockpit_table_1", "tu154/custom/anim/cockpit_table_1", globalPropertyf}, -- cockpit table 1
    {"cockpit_table_2", "tu154/custom/anim/cockpit_table_2", globalPropertyf}, -- cockpit table 2
    -- Chair armrests
    {"rise_chair_arm_L", "tu154/custom/anim/rise_chair_arm_L", globalPropertyf}, -- raise left chair armrest
    {"rise_chair_arm_R", "tu154/custom/anim/rise_chair_arm_R", globalPropertyf}, -- raise right chair armrest
    -- Yokes
    {"yokes_show", "tu154/custom/anim/show_yokes", globalPropertyi}, -- show/hide yokes
    -- Sliders (custom cockpit controls)
    -- Brake levers
    {"brake_emerg", "tu154/custom/controlls/brake_emerg", globalPropertyf}, -- emergency brake
    {"brake_emerg_L", "tu154/custom/controlls/brake_emerg_L", globalPropertyf}, -- emergency brake left
    {"brake_emerg_R", "tu154/custom/controlls/brake_emerg_R", globalPropertyf}, -- emergency brake right
    {"table_up_L", "tu154/custom/anim/table_up_L", globalPropertyf}, -- raise table left
    {"table_up_R", "tu154/custom/anim/table_up_R", globalPropertyf}, -- raise table right
    -- Ground equipment
    {"ground_stuff_angle", "tu154/custom/anim/ground_stuff_angle", globalPropertyf}, -- pitch correction for ground equipment
    -- Flightmodel data
    {"groundspeed", "sim/flightmodel/position/groundspeed", globalPropertyf}, -- ground speed, m/s
    {"yaw_apd", "sim/flightmodel/position/R", globalPropertyf}, -- yaw, radians/sec
    {"rudder", "sim/flightmodel/controls/vstab2_rud1def", globalPropertyf}, -- rudder deflection, deg (pos=TE left)
    
    {"rpm_high_1", "tu154/custom/gauges/engine/rpm_high_1", globalPropertyf}, -- high pressure turbine N1
    {"rpm_high_3", "tu154/custom/gauges/engine/rpm_high_3", globalPropertyf}, -- high pressure turbine N3
    {"weel_angle1", "sim/aircraft/gear/acf_nw_steerdeg1", globalPropertyf}, -- nosewheel steer angle 1
    {"weel_angle2", "sim/aircraft/gear/acf_nw_steerdeg2", globalPropertyf}, -- nosewheel steer angle 2
    -- Brakes
    {"brake_L", "sim/flightmodel/controls/l_brake_add", globalPropertyf}, -- left brake
    {"brake_R", "sim/flightmodel/controls/r_brake_add", globalPropertyf}, -- right brake
    -- Airspeed
    {"indicated_airspeed", "sim/flightmodel/position/indicated_airspeed", globalPropertyf}, -- indicated airspeed
    -- Elevators
    {"elevator_L", "sim/flightmodel/controls/hstab1_elv1def", globalPropertyf}, -- elevator left, deg (pos=TE down)
    {"elevator_R", "sim/flightmodel/controls/hstab2_elv1def", globalPropertyf}, -- elevator right, deg (pos=TE down)
    {"gforce", "sim/flightmodel2/misc/gforce_normal", globalPropertyf}, -- G load
    -- Fuel tanks
    {"airspeed", "sim/flightmodel/position/indicated_airspeed", globalPropertyf}, -- indicated airspeed
    -- Ailerons
    {"ail_L", "sim/flightmodel/controls/wing3l_ail1def", globalPropertyf}, -- left aileron, deg (pos=TE down)
    {"ail_R", "sim/flightmodel/controls/wing3r_ail1def", globalPropertyf}, -- right aileron, deg (pos=TE down)
    -- Cabin pressure
    {"cabin_press_diff", "sim/cockpit2/pressurization/indicators/pressure_diffential_psi", globalPropertyf},
    -- Wipers
    {"wiper_left", "tu154/custom/switchers/wiper_left", globalPropertyi}, -- wiper switch (left), -1=slow, 0=off, 1=fast
    {"wiper_right", "tu154/custom/switchers/wiper_right", globalPropertyi}, -- wiper switch (right), -1=slow, 0=off, 1=fast
    -- Electrical
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
    {"bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf},
    {"bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf},
    -- Wiper animation
    {"wiper_angle_left", "tu154/custom/anim/wiper_angle_left", globalPropertyf},
    {"wiper_angle_right", "tu154/custom/anim/wiper_angle_right", globalPropertyf}, 
    
    ---------------------
    --	Arrays	--
    ---------------------
    
    -- Slider 
    {"slider_1", "sim/cockpit2/switches/custom_slider_on[0]", 
		XP11 and globalPropertyf or globalProperty },
    {"slider_2", "sim/cockpit2/switches/custom_slider_on[1]", 
		XP11 and globalPropertyf or globalProperty },
    {"slider_3", "sim/cockpit2/switches/custom_slider_on[2]", 
		XP11 and globalPropertyf or globalProperty },
    {"slider_4", "sim/cockpit2/switches/custom_slider_on[3]", 
		XP11 and globalPropertyf or globalProperty },
    {"slider_5", "sim/cockpit2/switches/custom_slider_on[4]", 
		XP11 and globalPropertyf or globalProperty },
    {"slider_6", "sim/cockpit2/switches/custom_slider_on[5]", 
		XP11 and globalPropertyf or globalProperty },
    {"slider_7", "sim/cockpit2/switches/custom_slider_on[6]", 
		XP11 and globalPropertyf or globalProperty },
    {"slider_8", "sim/cockpit2/switches/custom_slider_on[7]", 
		XP11 and globalPropertyf or globalProperty },
    {"slider_9", "sim/cockpit2/switches/custom_slider_on[8]", 
		XP11 and globalPropertyf or globalProperty },
    {"slider_10", "sim/cockpit2/switches/custom_slider_on[9]", 
		XP11 and globalPropertyf or globalProperty },
    {"slider_11", "sim/cockpit2/switches/custom_slider_on[10]", 
		XP11 and globalPropertyf or globalProperty },
    {"slider_12", "sim/cockpit2/switches/custom_slider_on[11]", 
		XP11 and globalPropertyf or globalProperty }, 
	-- right tank fuel weight
    {"tank3R_w", "sim/flightmodel/weight/m_fuel[4]", 
		XP11 and globalPropertyf or globalProperty }, 
	-- left tank fuel weight
    {"tank3L_w", "sim/flightmodel/weight/m_fuel[5]", 
		XP11 and globalPropertyf or globalProperty }, 
	-- actual steering angle
    {"tire_steer_actual_deg", "sim/flightmodel2/gear/tire_steer_actual_deg[0]", 
		XP11 and globalPropertyf or globalProperty }, 
	-- gear deploy ratio 1
    {"deploy_ratio_1", "sim/flightmodel2/gear/deploy_ratio[0]", 
		XP11 and globalPropertyf or globalProperty },
	-- gear deploy ratio 2
    {"deploy_ratio_2", "sim/flightmodel2/gear/deploy_ratio[1]", 
		XP11 and globalPropertyf or globalProperty }, 
	-- gear deploy ratio 3
    {"deploy_ratio_3", "sim/flightmodel2/gear/deploy_ratio[2]", 
		XP11 and globalPropertyf or globalProperty }, 
	-- gear strut compression 1
    {"deflection_mtr_1", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[0]", 
		XP11 and globalPropertyf or globalProperty }, 
	-- gear strut compression 2
    {"deflection_mtr_2", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", 
		XP11 and globalPropertyf or globalProperty }, 
	-- gear strut compression 3
    {"deflection_mtr_3", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", 
		XP11 and globalPropertyf or globalProperty }, 
	-- wing tip deflection
    {"wing_tip_defl", "sim/flightmodel2/wing/wing_tip_deflection_deg[0]", 
		XP11 and globalPropertyf or globalProperty }, 
	-- eagle claw angle left
    {"EC_L", "sim/flightmodel2/gear/eagle_claw_angle_deg[1]", 
		XP11 and globalPropertyf or globalProperty },
	-- eagle claw angle right
    {"EC_R", "sim/flightmodel2/gear/eagle_claw_angle_deg[2]", 
		XP11 and globalPropertyf or globalProperty },
	-- left thrust reverser
    {"revers_flap_L", "sim/flightmodel2/engines/thrust_reverser_deploy_ratio[0]", 
		XP11 and globalPropertyf or globalProperty }, 
	-- right thrust reverser
    {"revers_flap_R", "sim/flightmodel2/engines/thrust_reverser_deploy_ratio[2]", 
		XP11 and globalPropertyf or globalProperty }, 
})

-- Global helpers required by this script
function bool2int(var)
    if var then return 1 else return 0 end
end

function line(x, x1, y1, x2, y2)
    if x2 - x1 ~= 0 then
        return (x - x1) * (y2 - y1) / (x2 - x1) + y1
    else
        return 0
    end
end

local function playPanelSample(sample)
    if XP11 then
        sasl.al.playSample(sample, false)
    else
        sasl.al.playSample(sample, false)
    end
end

-- Sound samples
local window_open = sasl.al.loadSample('Custom Sounds/window_open.wav')
local window_close = sasl.al.loadSample('Custom Sounds/window_close.wav')

-- State variables
local gear_turn_pos = 0
local MAX_TURN_SPD = 40
local turn_need = 0
local wing_flx_act_L = 0
local wing_flx_act_R = 0
local wiper_pos_L = 0
local wiper_pos_R = 0
local window_L_last = get(cockpit_window_left)
local window_R_last = get(cockpit_window_right)

-- Wrap value into [0,1) range
local function wrap01(x)
    return x - math.floor(x)
end

-- Safe division with tiny epsilon guard
local function safe_div(num, den, eps)
    eps = eps or 1e-6
    if math.abs(den) < eps then return 0 end
    return num / den
end

-- Numeric guard: coerce to number, fallback 0 if not numeric
local function n(v)
    local t = type(v)
    if t == "number" then return v end
    if t == "string" then
        local vv = tonumber(v)
        if vv then return vv end
    end
    -- If v is a table (e.g. array dataref from get()), return 0 to avoid crashes
    return 0
end

-- Generic slider/door/window stepper
-- cmd is 0/1; positive/open direction is (cmd*2-1)
-- rate_cmd0 applies when cmd==0, rate_cmd1 when cmd==1
-- allow_condition governs whether opening from 0.0 is allowed (e.g., pressure)
-- Returns: new_val, should_reset_cmd
local function advance_slider(val, cmd, dt, rate_cmd0, rate_cmd1, allow_condition)
    local new_val = val
    if ((val == 0 and allow_condition) or (val > 0)) then
        local dir = cmd * 2 - 1
        local rate = (cmd == 0) and rate_cmd0 or rate_cmd1
        new_val = val + dir * dt / rate
    end
    new_val = clamp(new_val, 0, 1)
    local should_reset = (new_val <= 0.01 and (not allow_condition) and cmd == 1)
    return new_val, should_reset
end

function update()
    -- Time and dynamics
    local passed = n(get(frame_time))
    local GS = n(get(groundspeed))
    local G_force = n(get(gforce))
    -- Nose gear steering dynamics
    local turn_spd = MAX_TURN_SPD
    local defl_F = n(get(deflection_mtr_1))
    local hydro_turn = 0
    if (n(get(weel_angle1)) + n(get(weel_angle2))) > 0 then
        hydro_turn = 1
    end
    if defl_F > 0 then
        turn_spd = math.abs(GS) + hydro_turn * 0.5
        if turn_spd > MAX_TURN_SPD then turn_spd = MAX_TURN_SPD end
    end

    turn_need =
        n(get(tire_steer_actual_deg)) * hydro_turn * (1 - math.min(1, math.abs(GS) * 0.1)) +
        n(get(yaw_apd)) * 5 * math.max((1 - hydro_turn), math.min(1, math.abs(GS) * 0.1))
    turn_need = clamp(turn_need, -65, 65)

    if passed * turn_spd < 0.5 then
        gear_turn_pos = gear_turn_pos + (turn_need - gear_turn_pos) * passed * turn_spd
    else
        gear_turn_pos = gear_turn_pos + (turn_need - gear_turn_pos) * passed
    end
    set(front_turn, gear_turn_pos)

    -- Gear positions/deflections
    set(front_pos, n(get(deploy_ratio_1)))
    set(front_defl, defl_F * 10)

    local pos_L = n(get(deploy_ratio_2))
    local pos_R = n(get(deploy_ratio_3))
    local defl_L = n(get(deflection_mtr_2))
    local defl_R = n(get(deflection_mtr_3))

    -- Ground strut angle
    local stuff_angle = (defl_F - 0.215 - (defl_L + defl_R - 0.2341 * 2) / 2) * 3.03
    set(ground_stuff_angle, -stuff_angle)

    if pos_L < 0.999 then
        set(main_pos_left, pos_L)
    else
        set(main_pos_left, -defl_L * 10 - 1)
    end

    if pos_R < 0.999 then
        set(main_pos_right, pos_R)
    else
        set(main_pos_right, -defl_R * 10 - 1)
    end

    -- Gear rotation (main)
    local rot_L = n(get(EC_L))
    local rot_R = n(get(EC_R))
    if pos_L < 0.9 then rot_L = -11 end
    if pos_R < 0.9 then rot_R = -11 end

    if n(get(replay_mode)) ~= 0 then
        if pos_L < 0.9 or defl_L < 0.001 then rot_L = -11 end
        if pos_R < 0.9 or defl_R < 0.001 then rot_R = -11 end
        if defl_L >= 0.001 then rot_L = -stuff_angle end
        if defl_R >= 0.001 then rot_R = -stuff_angle end
    end

    set(main_rot_left, rot_L)
    set(main_rot_right, rot_R)

    -- Rudder animation with reverser influence
    local rudder_L = 1 - math.max(n(get(revers_flap_L)) - 0.5, 0) * n(get(rpm_high_1)) * 0.015
    local rudder_R = 1 - math.max(n(get(revers_flap_R)) - 0.5, 0) * n(get(rpm_high_3)) * 0.015
    local rudder_den = (rudder_L + rudder_R) * 0.5
    set(rudder_anim, safe_div(n(get(rudder)), rudder_den, 1e-6))

    -- Elevator animation with IAS-dependent coefficient
    local ias = n(get(indicated_airspeed)) * 1.852
    local elev_coef = 1
    if ias >= 300 and ias <= 400 then
        elev_coef = line(ias, 300, 1, 400, 3)
    elseif ias > 400 then
        elev_coef = 3
    end
    local elev_L = n(get(elevator_L)) * elev_coef
    local elev_R = n(get(elevator_R)) * elev_coef
    set(elev_anim_L, elev_L)
    set(elev_anim_R, elev_R)

    -- Wing flex dynamics
    local wing_flx = (n(get(wing_tip_defl)) + 1.3)
    local tank_coef = 0.00005
    local ail_coef = 0.00003
    local IAS = n(get(airspeed))
    local left_flx  = wing_flx - G_force * n(get(tank3L_w)) * tank_coef + n(get(ail_L)) * IAS * ail_coef
    local right_flx = wing_flx - G_force * n(get(tank3R_w)) * tank_coef + n(get(ail_R)) * IAS * ail_coef
    wing_flx_act_L = wing_flx_act_L + (left_flx - wing_flx_act_L) * passed * 10
    wing_flx_act_R = wing_flx_act_R + (right_flx - wing_flx_act_R) * passed * 10
    set(wing_flx_left, wing_flx_act_L)
    set(wing_flx_right, wing_flx_act_R)

    -- Pressurization constraint
    local door_may_open = n(get(cabin_press_diff)) * 0.0778 < 0.05

    -- Windows (L/R) with asymmetric rates preserved from original logic
    local window_but_L = n(get(slider_1))
    local window_L = n(get(cockpit_window_left))
    local reset_L
    window_L, reset_L = advance_slider(window_L, window_but_L, passed, 3, 4, door_may_open)
    if reset_L then set(slider_1, 0) end
    set(cockpit_window_left, window_L)

    local window_but_R = n(get(slider_2))
    local window_R = n(get(cockpit_window_right))
    local reset_R
    window_R, reset_R = advance_slider(window_R, window_but_R, passed, 4, 3, door_may_open)
    if reset_R then set(slider_2, 0) end
    set(cockpit_window_right, window_R)

    -- Window sound triggers
    if ((window_L ~= window_L_last) and window_L_last == 0) or ((window_R ~= window_R_last) and window_R_last == 0) then
        playPanelSample(window_open)
    elseif ((window_L ~= window_L_last) and window_L_last == 1) or ((window_R ~= window_R_last) and window_R_last == 1) then
        playPanelSample(window_close)
    end
    window_L_last = window_L
    window_R_last = window_R

    -- Cargo doors with pressure constraint
    local cargo_FWD = n(get(cargo_1))
    local cargo_1_cmd = n(get(slider_3))
    local reset_c1
    cargo_FWD, reset_c1 = advance_slider(cargo_FWD, cargo_1_cmd, passed, 5, 5, door_may_open)
    if reset_c1 then set(slider_3, 0) end
    set(cargo_1, cargo_FWD)

    local cargo_BK = n(get(cargo_2))
    local cargo_2_cmd = n(get(slider_4))
    local reset_c2
    cargo_BK, reset_c2 = advance_slider(cargo_BK, cargo_2_cmd, passed, 5, 5, door_may_open)
    if reset_c2 then set(slider_4, 0) end
    set(cargo_2, cargo_BK)

    -- Passenger doors with pressure constraint
    local door_1 = n(get(pax_door_1))
    local door_1_cmd = n(get(slider_5))
    local reset_d1
    door_1, reset_d1 = advance_slider(door_1, door_1_cmd, passed, 5, 5, door_may_open)
    if reset_d1 then set(slider_5, 0) end
    set(pax_door_1, door_1)

    local door_2 = n(get(pax_door_2))
    local door_2_cmd = n(get(slider_6))
    local reset_d2
    door_2, reset_d2 = advance_slider(door_2, door_2_cmd, passed, 5, 5, door_may_open)
    if reset_d2 then set(slider_6, 0) end
    set(pax_door_2, door_2)

    local door_3 = n(get(pax_door_3))
    local door_3_cmd = n(get(slider_7))
    local reset_d3
    door_3, reset_d3 = advance_slider(door_3, door_3_cmd, passed, 5, 5, door_may_open)
    if reset_d3 then set(slider_7, 0) end
    set(pax_door_3, door_3)

    -- Cockpit door (no pressure constraint in original)
    local door_4 = n(get(cockpit_door))
    local door_4_cmd = n(get(slider_8))
    door_4 = door_4 + (door_4_cmd * 2 - 1) * passed / 3
    door_4 = clamp(door_4, 0, 1)
    set(cockpit_door, door_4)

    -- Brakes emergency mapping
    set(brake_emerg_L, n(get(brake_emerg)))
    set(brake_emerg_R, n(get(brake_emerg)))

    -- Seat armrests
    local chair_L = n(get(rise_chair_arm_L))
    local chair_L_cmd = n(get(slider_11))
    chair_L = chair_L + (chair_L_cmd * 2 - 1) * passed
    chair_L = clamp(chair_L, 0, 1)
    set(rise_chair_arm_L, chair_L)

    local chair_R = n(get(rise_chair_arm_R))
    local chair_R_cmd = n(get(slider_12))
    chair_R = chair_R + (chair_R_cmd * 2 - 1) * passed
    chair_R = clamp(chair_R, 0, 1)
    set(rise_chair_arm_R, chair_R)

    -- Yokes visibility
    set(yokes_show, 1 - n(get(slider_9)))

    -- Wipers (power + mode -> speed)
    local wip_power_L = bool2int(n(get(bus27_volt_left)) > 13 and n(get(bus115_1_volt)) > 110)
    local wip_power_R = bool2int(n(get(bus27_volt_right)) > 13 and n(get(bus115_3_volt)) > 110)

    local wip_spd_L = 0
    local wl = n(get(wiper_left))
    if wl == -1 then
        wip_spd_L = 1.5 * wip_power_L
    elseif wl == 1 then
        wip_spd_L = 3 * wip_power_L
    else
        if wiper_pos_L > 0.1 then wip_spd_L = 1 * wip_power_L end
    end

    local wip_spd_R = 0
    local wr = n(get(wiper_right))
    if wr == -1 then
        wip_spd_R = 1.5 * wip_power_R
    elseif wr == 1 then
        wip_spd_R = 3 * wip_power_R
    else
        if wiper_pos_R > 0.1 then wip_spd_R = 1 * wip_power_R end
    end

    wiper_pos_L = wiper_pos_L + wip_spd_L * passed
    wiper_pos_R = wiper_pos_R + wip_spd_R * passed
    wiper_pos_L = wrap01(wiper_pos_L)
    wiper_pos_R = wrap01(wiper_pos_R)

    set(wiper_angle_left,  (math.cos(math.pi * wiper_pos_L * 2 - math.pi) + 1) * 0.5 * 62)
    set(wiper_angle_right, (math.cos(math.pi * wiper_pos_R * 2 - math.pi) + 1) * 0.5 * 62)

    -- Tables
    local table_pos_L = n(get(cockpit_table_1))
    local table_pos_R = n(get(cockpit_table_2))
    local table_sw_L = n(get(table_up_L))
    local table_sw_R = n(get(table_up_R))

    if table_pos_L < 1 and table_sw_L == 1 then
        table_pos_L = table_pos_L + passed * 0.5
    elseif table_pos_L > 0 and table_sw_L == 0 then
        table_pos_L = table_pos_L - passed * 0.5
    end
    table_pos_L = clamp(table_pos_L, 0, 1)

    if table_pos_R < 1 and table_sw_R == 1 then
        table_pos_R = table_pos_R + passed * 0.5
    elseif table_pos_R > 0 and table_sw_R == 0 then
        table_pos_R = table_pos_R - passed * 0.5
    end
    table_pos_R = clamp(table_pos_R, 0, 1)

    set(cockpit_table_1, table_pos_L)
    set(cockpit_table_2, table_pos_R)

    -- Reverser midpoint
    set(reverse_mid, (n(get(revers_L)) + n(get(revers_R))) / 2)
end

