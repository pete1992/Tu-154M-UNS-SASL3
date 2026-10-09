-- ext_anim.lua
-- Animates landing gear, control surfaces, doors, wipers and cabin fittings.

---------------------------------------------------------------------------
-- Local references for frequently used functions.
---------------------------------------------------------------------------
local get, set = get, set
local type, tonumber = type, tonumber
local abs, min, floor, cos = math.abs, math.min, math.floor, math.cos
local HUGE = math.huge
local TWO_PI = 2 * math.pi
local playSample = sasl.al.playSample

-- Use the shared clamp helper when available.
local clamp = clamp
    or function(v, lo, hi)
        if v < lo then
            return lo
        end
        if v > hi then
            return hi
        end
        return v
    end

-- true = write animation outputs only when their values change.
-- false = write outputs every frame.
local USE_WRITE_CACHE = true

---------------------------------------------------------------------------
-- Resolve property handles once and retain them in P.
-- A handle table keeps closures within the Lua 5.1 upvalue limit.
---------------------------------------------------------------------------
local P = {}
local env = (getfenv and getfenv(1)) or _ENV or _G

local function defineProps(defs)
    for i = 1, #defs do
        local d = defs[i]
        local name = d[1]
        local handle = d[3](d[2])
        defineProperty(name, handle)
        -- Prefer a property already supplied by the component environment.
        P[name] = env[name] or handle
    end
end

defineProps({
    -- Frame timing and replay
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    { "replay_mode", "sim/operation/prefs/replay_mode", globalPropertyi },
    -- Reverse handles
    { "revers_L", "tu154/custom/controlls/revers_L", globalPropertyf },
    { "revers_R", "tu154/custom/controlls/revers_R", globalPropertyf },
    { "reverse_mid", "tu154/custom/anim/reverse_mid", globalPropertyf },
    -- Gear positions and deflections
    { "front_pos", "tu154/custom/anim/lg/front_pos", globalPropertyf },
    { "front_defl", "tu154/custom/anim/lg/front_defl", globalPropertyf },
    { "front_turn", "tu154/custom/anim/lg/front_turn", globalPropertyf },
    { "main_pos_left", "tu154/custom/anim/lg/main_pos_left", globalPropertyf },
    { "main_rot_left", "tu154/custom/anim/lg/main_rot_left", globalPropertyf },
    { "main_pos_right", "tu154/custom/anim/lg/main_pos_right", globalPropertyf },
    { "main_rot_right", "tu154/custom/anim/lg/main_rot_right", globalPropertyf },
    -- Tail control surfaces
    { "rudder_anim", "tu154/custom/anim/rudder_anim", globalPropertyf },
    { "elev_anim_L", "tu154/custom/anim/elev_anim_L", globalPropertyf },
    { "elev_anim_R", "tu154/custom/anim/elev_anim_R", globalPropertyf },
    -- Wing flex
    { "wing_flx_right", "tu154/custom/anim/wing_flx_right", globalPropertyf },
    { "wing_flx_left", "tu154/custom/anim/wing_flx_left", globalPropertyf },
    -- Windows and doors
    { "cockpit_window_left", "tu154/custom/anim/cockpit_window_left", globalPropertyf },
    { "cockpit_window_right", "tu154/custom/anim/cockpit_window_right", globalPropertyf },
    { "cargo_1", "tu154/custom/anim/cargo_1", globalPropertyf },
    { "cargo_2", "tu154/custom/anim/cargo_2", globalPropertyf },
    { "pax_door_1", "tu154/custom/anim/pax_door_1", globalPropertyf },
    { "pax_door_2", "tu154/custom/anim/pax_door_2", globalPropertyf },
    { "pax_door_3", "tu154/custom/anim/pax_door_3", globalPropertyf },
    { "cockpit_door", "tu154/custom/anim/cockpit_door", globalPropertyf },
    { "cockpit_table_1", "tu154/custom/anim/cockpit_table_1", globalPropertyf },
    { "cockpit_table_2", "tu154/custom/anim/cockpit_table_2", globalPropertyf },
    -- Chair armrests
    { "rise_chair_arm_L", "tu154/custom/anim/rise_chair_arm_L", globalPropertyf },
    { "rise_chair_arm_R", "tu154/custom/anim/rise_chair_arm_R", globalPropertyf },
    -- Yokes
    { "yokes_show", "tu154/custom/anim/show_yokes", globalPropertyi },
    -- Brake levers
    { "brake_emerg", "tu154/custom/controlls/brake_emerg", globalPropertyf },
    { "brake_emerg_L", "tu154/custom/controlls/brake_emerg_L", globalPropertyf },
    { "brake_emerg_R", "tu154/custom/controlls/brake_emerg_R", globalPropertyf },
    { "table_up_L", "tu154/custom/anim/table_up_L", globalPropertyf },
    { "table_up_R", "tu154/custom/anim/table_up_R", globalPropertyf },
    -- Ground equipment
    { "ground_stuff_angle", "tu154/custom/anim/ground_stuff_angle", globalPropertyf },
    -- Flightmodel data
    { "groundspeed", "sim/flightmodel/position/groundspeed", globalPropertyf },
    { "yaw_apd", "sim/flightmodel/position/R", globalPropertyf },
    { "rudder", "sim/flightmodel/controls/vstab2_rud1def", globalPropertyf },
    { "rpm_high_1", "tu154/custom/gauges/engine/rpm_high_1", globalPropertyf },
    { "rpm_high_3", "tu154/custom/gauges/engine/rpm_high_3", globalPropertyf },
    { "weel_angle1", "sim/aircraft/gear/acf_nw_steerdeg1", globalPropertyf },
    { "weel_angle2", "sim/aircraft/gear/acf_nw_steerdeg2", globalPropertyf },
    -- Elevators
    { "elevator_L", "sim/flightmodel/controls/hstab1_elv1def", globalPropertyf },
    { "elevator_R", "sim/flightmodel/controls/hstab2_elv1def", globalPropertyf },
    { "gforce", "sim/flightmodel2/misc/gforce_normal", globalPropertyf },
    { "airspeed", "sim/flightmodel/position/indicated_airspeed", globalPropertyf },
    -- Ailerons
    { "ail_L", "sim/flightmodel/controls/wing3l_ail1def", globalPropertyf },
    { "ail_R", "sim/flightmodel/controls/wing3r_ail1def", globalPropertyf },
    -- Cabin pressure
    {
        "cabin_press_diff",
        "sim/cockpit2/pressurization/indicators/pressure_diffential_psi",
        globalPropertyf,
    },
    -- Wipers (-1 = slow, 0 = off, 1 = fast)
    { "wiper_left", "tu154/custom/switchers/wiper_left", globalPropertyi },
    { "wiper_right", "tu154/custom/switchers/wiper_right", globalPropertyi },
    -- Electrical
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },
    -- Wiper animation
    { "wiper_angle_left", "tu154/custom/anim/wiper_angle_left", globalPropertyf },
    { "wiper_angle_right", "tu154/custom/anim/wiper_angle_right", globalPropertyf },

    -- Arrays ---------------------------------------------------------------
    { "slider_1", "sim/cockpit2/switches/custom_slider_on[0]", globalProperty },
    { "slider_2", "sim/cockpit2/switches/custom_slider_on[1]", globalProperty },
    { "slider_3", "sim/cockpit2/switches/custom_slider_on[2]", globalProperty },
    { "slider_4", "sim/cockpit2/switches/custom_slider_on[3]", globalProperty },
    { "slider_5", "sim/cockpit2/switches/custom_slider_on[4]", globalProperty },
    { "slider_6", "sim/cockpit2/switches/custom_slider_on[5]", globalProperty },
    { "slider_7", "sim/cockpit2/switches/custom_slider_on[6]", globalProperty },
    { "slider_8", "sim/cockpit2/switches/custom_slider_on[7]", globalProperty },
    { "slider_9", "sim/cockpit2/switches/custom_slider_on[8]", globalProperty },
    { "slider_11", "sim/cockpit2/switches/custom_slider_on[10]", globalProperty },
    { "slider_12", "sim/cockpit2/switches/custom_slider_on[11]", globalProperty },
    { "tank3R_w", "sim/flightmodel/weight/m_fuel[4]", globalProperty },
    { "tank3L_w", "sim/flightmodel/weight/m_fuel[5]", globalProperty },
    { "tire_steer_actual_deg", "sim/flightmodel2/gear/tire_steer_actual_deg[0]", globalProperty },
    { "deploy_ratio_1", "sim/flightmodel2/gear/deploy_ratio[0]", globalProperty },
    { "deploy_ratio_2", "sim/flightmodel2/gear/deploy_ratio[1]", globalProperty },
    { "deploy_ratio_3", "sim/flightmodel2/gear/deploy_ratio[2]", globalProperty },
    { "deflection_mtr_1", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[0]", globalProperty },
    { "deflection_mtr_2", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalProperty },
    { "deflection_mtr_3", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", globalProperty },
    { "wing_tip_defl", "sim/flightmodel2/wing/wing_tip_deflection_deg[0]", globalProperty },
    { "EC_L", "sim/flightmodel2/gear/eagle_claw_angle_deg[1]", globalProperty },
    { "EC_R", "sim/flightmodel2/gear/eagle_claw_angle_deg[2]", globalProperty },
    { "revers_flap_L", "sim/flightmodel2/engines/thrust_reverser_deploy_ratio[0]", globalProperty },
    { "revers_flap_R", "sim/flightmodel2/engines/thrust_reverser_deploy_ratio[2]", globalProperty },
})

---------------------------------------------------------------------------
-- Sound samples and persistent state.
---------------------------------------------------------------------------
local window_open = sasl.al.loadSample("Custom Sounds/window_open.wav")
local window_close = sasl.al.loadSample("Custom Sounds/window_close.wav")

local MAX_TURN_SPD = 40
local gear_turn_pos = 0
local turn_need = 0
local wing_flx_act_L, wing_flx_act_R = 0, 0
local wiper_pos_L, wiper_pos_R = 0, 0
local wiper_drawn_L, wiper_drawn_R = nil, nil
local window_L_last = get(P.cockpit_window_left)
local window_R_last = get(P.cockpit_window_right)

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
-- Accept numbers, convert numeric strings and use zero for other values.
local function n(v)
    local t = type(v)
    if t == "number" then
        return v
    end
    if t == "string" then
        return tonumber(v) or 0
    end
    return 0
end

-- Cache the last values written to output DataRefs.
local last_written = {}
local put = set
if USE_WRITE_CACHE then
    put = function(h, v)
        if last_written[h] ~= v then
            last_written[h] = v
            set(h, v)
        end
    end
end

local function wrap01(x)
    return x - floor(x)
end

-- Retain wiper phase without power; OFF completes the cycle at the parked position.
local function advance_wiper(phase, mode, powered, dt)
    if not powered or dt <= 0 or dt ~= dt or dt == HUGE then
        return phase
    end
    if mode == -1 then
        return wrap01(phase + 1.5 * dt)
    elseif mode == 1 then
        return wrap01(phase + 3 * dt)
    elseif phase > 0 then
        local p = phase + dt
        return p >= 1 and 0 or p
    end
    return 0
end

-- Return the new position and whether the opening command must be reset.
local function advance_slider(val, cmd, dt, rate_cmd0, rate_cmd1, allow)
    local new_val = val
    if (val == 0 and allow) or val > 0 then
        local rate = (cmd == 0) and rate_cmd0 or rate_cmd1
        new_val = val + (cmd * 2 - 1) * dt / rate
    end
    new_val = clamp(new_val, 0, 1)
    return new_val, (new_val <= 0.01 and not allow and cmd == 1)
end

-- Move a pressure-interlocked door or window and write changed values.
local function step_door(h_val, h_cmd, dt, r0, r1, allow)
    local val = n(get(h_val))
    local new_val, reset = advance_slider(val, n(get(h_cmd)), dt, r0, r1, allow)
    if reset then
        set(h_cmd, 0)
    end
    if new_val ~= val then
        set(h_val, new_val)
    end
    return new_val
end

-- Move cabin fittings without a pressure interlock.
local function step_linear(h_val, h_cmd, dt, div)
    local val = n(get(h_val))
    local new_val = clamp(val + (n(get(h_cmd)) * 2 - 1) * dt / div, 0, 1)
    if new_val ~= val then
        set(h_val, new_val)
    end
end

-- Folding cockpit tables.
local function step_table(h_pos, h_sw, dt)
    local pos = n(get(h_pos))
    local sw = n(get(h_sw))
    local new_pos = pos
    if pos < 1 and sw == 1 then
        new_pos = pos + dt * 0.5
    elseif pos > 0 and sw == 0 then
        new_pos = pos - dt * 0.5
    end
    new_pos = clamp(new_pos, 0, 1)
    if new_pos ~= pos then
        set(h_pos, new_pos)
    end
end

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------
function update()
    local passed = n(get(P.frame_time))
    local absGS = abs(n(get(P.groundspeed)))
    local gs_fac = min(1, absGS * 0.1)

    -- Nose-gear steering animation.
    local defl_F = n(get(P.deflection_mtr_1))
    local hydro = (n(get(P.weel_angle1)) + n(get(P.weel_angle2))) > 0

    local turn_spd = MAX_TURN_SPD
    if defl_F > 0 then
        turn_spd = absGS + (hydro and 0.5 or 0)
        if turn_spd > MAX_TURN_SPD then
            turn_spd = MAX_TURN_SPD
        end
    end

    local yaw_term = n(get(P.yaw_apd)) * 5
    if hydro then
        turn_need = n(get(P.tire_steer_actual_deg)) * (1 - gs_fac) + yaw_term * gs_fac
    else
        turn_need = yaw_term
    end
    turn_need = clamp(turn_need, -65, 65)

    local k = passed * turn_spd
    if not (k < 0.5) then
        k = passed
    end
    gear_turn_pos = gear_turn_pos + (turn_need - gear_turn_pos) * k
    put(P.front_turn, gear_turn_pos)

    -- Landing-gear positions and strut deflections.
    put(P.front_pos, n(get(P.deploy_ratio_1)))
    put(P.front_defl, defl_F * 10)

    local pos_L = n(get(P.deploy_ratio_2))
    local pos_R = n(get(P.deploy_ratio_3))
    local defl_L = n(get(P.deflection_mtr_2))
    local defl_R = n(get(P.deflection_mtr_3))

    local stuff_angle = (defl_F - 0.215 - (defl_L + defl_R - 0.2341 * 2) / 2) * 3.03
    put(P.ground_stuff_angle, -stuff_angle)

    if pos_L < 0.999 then
        put(P.main_pos_left, pos_L)
    else
        put(P.main_pos_left, -defl_L * 10 - 1)
    end
    if pos_R < 0.999 then
        put(P.main_pos_right, pos_R)
    else
        put(P.main_pos_right, -defl_R * 10 - 1)
    end

    -- Use ground geometry for bogie rotation in replay mode.
    local rot_L, rot_R
    if n(get(P.replay_mode)) ~= 0 then
        rot_L = (defl_L >= 0.001) and -stuff_angle or -11
        rot_R = (defl_R >= 0.001) and -stuff_angle or -11
    else
        rot_L = (pos_L < 0.9) and -11 or n(get(P.EC_L))
        rot_R = (pos_R < 0.9) and -11 or n(get(P.EC_R))
    end
    put(P.main_rot_left, rot_L)
    put(P.main_rot_right, rot_R)

    -- Compensate rudder animation for thrust-reverser influence.
    local rudder_L, rudder_R = 1, 1
    local rf = n(get(P.revers_flap_L)) - 0.5
    if rf > 0 then
        rudder_L = 1 - rf * n(get(P.rpm_high_1)) * 0.015
    end
    rf = n(get(P.revers_flap_R)) - 0.5
    if rf > 0 then
        rudder_R = 1 - rf * n(get(P.rpm_high_3)) * 0.015
    end
    local den = (rudder_L + rudder_R) * 0.5
    local rud = n(get(P.rudder))
    put(P.rudder_anim, (abs(den) < 1e-6) and 0 or rud / den)

    -- Elevator limits: 25 degrees trailing edge up and 20 degrees down.
    put(P.elev_anim_L, clamp(n(get(P.elevator_L)), -25, 20))
    put(P.elev_anim_R, clamp(n(get(P.elevator_R)), -25, 20))

    -- Wing flex from aerodynamic load, fuel mass and aileron position.
    local G_force = n(get(P.gforce))
    local wing_flx = n(get(P.wing_tip_defl)) + 1.3
    local IAS = n(get(P.airspeed))
    local left_flx = wing_flx - G_force * n(get(P.tank3L_w)) * 0.00005 + n(get(P.ail_L)) * IAS * 0.00003
    local right_flx = wing_flx - G_force * n(get(P.tank3R_w)) * 0.00005 + n(get(P.ail_R)) * IAS * 0.00003
    local a = passed * 10
    wing_flx_act_L = wing_flx_act_L + (left_flx - wing_flx_act_L) * a
    wing_flx_act_R = wing_flx_act_R + (right_flx - wing_flx_act_R) * a
    put(P.wing_flx_left, wing_flx_act_L)
    put(P.wing_flx_right, wing_flx_act_R)

    -- Pressure differential permitting doors and windows to open.
    local may_open = n(get(P.cabin_press_diff)) * 0.0778 < 0.05

    -- Cockpit windows use asymmetric opening and closing rates.
    local window_L = step_door(P.cockpit_window_left, P.slider_1, passed, 3, 4, may_open)
    local window_R = step_door(P.cockpit_window_right, P.slider_2, passed, 4, 3, may_open)

    if window_L ~= window_L_last or window_R ~= window_R_last then
        if (window_L ~= window_L_last and window_L_last == 0) or (window_R ~= window_R_last and window_R_last == 0) then
            playSample(window_open, false)
        elseif
            (window_L ~= window_L_last and window_L_last == 1)
            or (window_R ~= window_R_last and window_R_last == 1)
        then
            playSample(window_close, false)
        end
        window_L_last = window_L
        window_R_last = window_R
    end

    -- Cargo and passenger doors.
    step_door(P.cargo_1, P.slider_3, passed, 5, 5, may_open)
    step_door(P.cargo_2, P.slider_4, passed, 5, 5, may_open)
    step_door(P.pax_door_1, P.slider_5, passed, 5, 5, may_open)
    step_door(P.pax_door_2, P.slider_6, passed, 5, 5, may_open)
    step_door(P.pax_door_3, P.slider_7, passed, 5, 5, may_open)

    -- Cockpit door, without a pressure interlock.
    step_linear(P.cockpit_door, P.slider_8, passed, 3)

    -- Publish emergency-brake lever positions each frame.
    local be = n(get(P.brake_emerg))
    set(P.brake_emerg_L, be)
    set(P.brake_emerg_R, be)

    -- Chair armrests.
    step_linear(P.rise_chair_arm_L, P.slider_11, passed, 1)
    step_linear(P.rise_chair_arm_R, P.slider_12, passed, 1)

    -- Control-yoke visibility.
    put(P.yokes_show, 1 - n(get(P.slider_9)))

    -- Wipers use separate DC/AC supplies and a 62-degree sweep.
    local pwr_L = n(get(P.bus27_volt_left)) > 13 and n(get(P.bus115_1_volt)) > 110
    local pwr_R = n(get(P.bus27_volt_right)) > 13 and n(get(P.bus115_3_volt)) > 110

    wiper_pos_L = advance_wiper(wiper_pos_L, n(get(P.wiper_left)), pwr_L, passed)
    wiper_pos_R = advance_wiper(wiper_pos_R, n(get(P.wiper_right)), pwr_R, passed)

    -- (cos(2*pi*p - pi) + 1) * 0.5 * 62  ==  (1 - cos(2*pi*p)) * 31
    if not USE_WRITE_CACHE or wiper_pos_L ~= wiper_drawn_L then
        wiper_drawn_L = wiper_pos_L
        put(P.wiper_angle_left, (1 - cos(TWO_PI * wiper_pos_L)) * 31)
    end
    if not USE_WRITE_CACHE or wiper_pos_R ~= wiper_drawn_R then
        wiper_drawn_R = wiper_pos_R
        put(P.wiper_angle_right, (1 - cos(TWO_PI * wiper_pos_R)) * 31)
    end

    -- Folding cockpit tables.
    step_table(P.cockpit_table_1, P.table_up_L, passed)
    step_table(P.cockpit_table_2, P.table_up_R, passed)

    -- Mean thrust-reverser animation position.
    put(P.reverse_mid, (n(get(P.revers_L)) + n(get(P.revers_R))) / 2)
end
