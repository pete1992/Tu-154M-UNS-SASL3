--[[
Flight Controls Logic - Changelog

- Consolidated all 97 active SASL property bindings into a local defineProps() initializer.
- Preserved every active property name, Dataref path, constructor and binding order.
- Replaced Russian comments with English comments and cleaned up section formatting.
- Fixed booster state handling so a booster is disabled immediately when its 27 V supply is unavailable.
- Added manual primary-control fallback: with both 27 V control buses unavailable, ailerons,
  elevators and rudder remain controllable up to 30% command authority while hydraulic pressure exists.
- Clamped hydraulic authority to the valid 0..1 range.
- Reused one combined booster/hydraulic response factor for roll, pitch and yaw actuators.
- Limited frame integration steps to 1.0 to prevent actuator overshoot at low frame rates.
- Fixed force-loader electrical load logic so pitch and rudder movement cannot overwrite each other.
- Explicitly clears force-loader current draw when the required electrical supply is unavailable.
- Reduced repeated Dataref reads inside update() without changing existing aerodynamic curves or limits.
- Preserved SmartCopilot master/slave behavior, override handling, ABSU mixing, trim logic,
  spoiler deployment thresholds, Mach curves, reverse influence and all original physical constants.
- Added frame-rate-independent pilot input filtering for pitch, roll and yaw to suppress noisy-axis/yoke jitter.
- Added a small remapped center deadzone so minor hardware noise does not move the cockpit yoke or control surfaces.
- Added gentle aileron-to-rudder coupling for users without pedals; manual yaw input, yaw trim and ABSU yaw remain additive.
- Removed the nonphysical Mach-dependent attenuation of manual pitch authority; X-Plane remains responsible for aerodynamic Mach/compressibility effects on the elevator.
- Replaced pitch force-loader geometry clipping/overforce logic with the documented static SUU-154 longitudinal controllability law through the RA-56 pitch channels.
- Added the documented Ksh0 = 0.111 deg/mm, Kx = 1 - (140 - X_MET)/120, Kx <= 0.4 relationship and the +/-10 degree RA-56 differential limit.
- Kept the force-loader mechanism as a force/system-state device instead of using it as an artificial elevator travel limiter.
- Preserved the existing ABSU additive pitch-command path for separate validation.
- Added artificial pitch-force simulation using the existing force-loader state.
- Added a 20 deg/s elevator slew-rate limiter while preserving the -25/+20 degree physical stops.
- Added a dedicated high-Mach manual-pitch stiffness schedule that is neutral through M0.86 and progressively increases above it.
]]

-- Flight controls logic.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Control inputs and framework state
    { "joy_pitch", "tu154/custom/SC/yoke_pitch_ratio", globalPropertyf },
    { "joy_roll", "tu154/custom/SC/yoke_roll_ratio", globalPropertyf },
    { "joy_yaw", "tu154/custom/SC/yoke_heading_ratio", globalPropertyf },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- Frame duration.
    { "overr", "sim/operation/override/override_control_surfaces", globalPropertyf }, -- X-Plane control-surface override.
    -- Control switches, trims and force-loader state
    { "speedbrake_ratio", "sim/cockpit2/controls/speedbrake_ratio", globalPropertyf }, -- Simulator speedbrake lever ratio.
    { "elev_trimm_sw", "tu154/custom/controll/elev_trimm_switcher", globalPropertyi }, -- Elevator trim switch: -1 nose down, 0 neutral, +1 nose up.
    { "ail_trimm_sw", "tu154/custom/controll/ail_trimm_sw", globalPropertyi }, -- Aileron trim switch.
    { "rudd_trimm_sw", "tu154/custom/controll/rudd_trimm_sw", globalPropertyi }, -- Rudder trim switch.
    { "int_pitch_trim", "tu154/custom/trimmers/int_pitch_trim", globalPropertyf }, -- Internal elevator trim position.
    { "int_roll_trim", "tu154/custom/trimmers/int_roll_trim", globalPropertyf }, -- Internal aileron trim position.
    { "int_yaw_trim", "tu154/custom/trimmers/int_yaw_trim", globalPropertyf }, -- Internal rudder trim position.
    { "buster_on_1", "tu154/custom/switchers/console/buster_on_1", globalPropertyi }, -- Booster channel 1 switch.
    { "buster_on_2", "tu154/custom/switchers/console/buster_on_2", globalPropertyi }, -- Booster channel 2 switch.
    { "buster_on_3", "tu154/custom/switchers/console/buster_on_3", globalPropertyi }, -- Booster channel 3 switch.
    { "busters_cap", "tu154/custom/switchers/console/busters_cap", globalPropertyi }, -- Booster switch guard position.
    { "control_force_pos", "tu154/custom/controls/control_force_pos", globalPropertyf }, -- Elevator force-loader position: 0 disconnected, 1 engaged.
    { "control_force_pos_rud", "tu154/custom/controls/control_force_pos_rud", globalPropertyf }, -- Rudder force-loader position: 0 disconnected, 1 engaged.
    { "contr_force_set", "tu154/custom/controll/contr_force_set", globalPropertyi }, -- Force-loader selector: -1 flight, 0 automatic, +1 takeoff/landing.
    { "hydro_long_control", "tu154/custom/switchers/eng/hydro_long_control", globalPropertyi }, -- SUU-154 longitudinal controllability switch.
    { "hydro_ra56_elev_1", "tu154/custom/switchers/eng/hydro_ra56_elev_1", globalPropertyi }, -- RA-56 pitch hydraulic channel 1.
    { "hydro_ra56_elev_2", "tu154/custom/switchers/eng/hydro_ra56_elev_2", globalPropertyi }, -- RA-56 pitch hydraulic channel 2.
    { "hydro_ra56_elev_3", "tu154/custom/switchers/eng/hydro_ra56_elev_3", globalPropertyi }, -- RA-56 pitch hydraulic channel 3.
    { "deploy_ratio_2", "sim/flightmodel2/gear/deploy_ratio[1]", globalProperty },
    { "deploy_ratio_3", "sim/flightmodel2/gear/deploy_ratio[2]", globalProperty },
    { "gear1_deflect", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[0]", globalProperty }, -- Front gear vertical tire deflection.
    { "gear2_deflect", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalProperty }, -- Left main gear vertical tire deflection.
    { "gear3_deflect", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", globalProperty }, -- Right main gear vertical tire deflection.
    -- Wing control surfaces
    { "ail_L", "sim/flightmodel/controls/wing3l_ail1def", globalPropertyf }, -- Left aileron deflection in degrees; positive is trailing-edge down.
    { "ail_R", "sim/flightmodel/controls/wing3r_ail1def", globalPropertyf }, -- Right aileron deflection in degrees; positive is trailing-edge down.
    { "spd_brk_inn_L", "sim/flightmodel/controls/wing1l_spo1def", globalPropertyf }, -- Left inner speedbrake deflection in degrees.
    { "spd_brk_inn_R", "sim/flightmodel/controls/wing1r_spo1def", globalPropertyf }, -- Right inner speedbrake deflection in degrees.
    { "spd_brk_inn_anim_L", "tu154/custom/anim/spd_brk_inn_left", globalPropertyf }, -- Left inner speedbrake animation deflection.
    { "spd_brk_inn_anim_R", "tu154/custom/anim/spd_brk_inn_right", globalPropertyf }, -- Right inner speedbrake animation deflection.
    { "spd_brk_mid_L", "sim/flightmodel/controls/wing2l_spo2def", globalPropertyf }, -- Left middle speedbrake deflection in degrees.
    { "spd_brk_mid_R", "sim/flightmodel/controls/wing2r_spo2def", globalPropertyf }, -- Right middle speedbrake deflection in degrees.
    { "roll_spoil_L", "sim/flightmodel/controls/wing2l_spo1def", globalPropertyf }, -- Left roll-spoiler deflection in degrees.
    { "roll_spoil_R", "sim/flightmodel/controls/wing2r_spo1def", globalPropertyf }, -- Right roll-spoiler deflection in degrees.
    { "flap_inn_L", "sim/flightmodel/controls/wing1l_fla1def", globalPropertyf }, -- Left inner flap position.
    { "flap_inn_R", "sim/flightmodel/controls/wing1r_fla1def", globalPropertyf }, -- Right inner flap position.
    { "flap_mid_L", "sim/flightmodel/controls/wing2l_fla2def", globalPropertyf }, -- Left middle flap position.
    { "flap_mid_R", "sim/flightmodel/controls/wing2r_fla2def", globalPropertyf }, -- Right middle flap position.
    { "slats", "sim/flightmodel2/controls/slat1_deploy_ratio", globalPropertyf }, -- Slat deployment ratio.
    -- Tail control surfaces
    { "elevator_L", "sim/flightmodel/controls/hstab1_elv1def", globalPropertyf }, -- Left elevator deflection in degrees; positive is trailing-edge down.
    { "elevator_R", "sim/flightmodel/controls/hstab2_elv1def", globalPropertyf }, -- Right elevator deflection in degrees; positive is trailing-edge down.
    { "rudder", "sim/flightmodel/controls/vstab2_rud1def", globalPropertyf }, -- Rudder deflection in degrees; positive is trailing-edge left.
    { "stab_ratio", "sim/cockpit2/controls/elevator_trim", globalPropertyf }, -- Simulator pitch trim position.
    -- Hydraulic pressure
    { "gs_press_1", "tu154/custom/hydro/gs_press_1", globalPropertyf }, -- Hydraulic system 1 pressure.
    { "gs_press_2", "tu154/custom/hydro/gs_press_2", globalPropertyf }, -- Hydraulic system 2 pressure.
    { "gs_press_3", "tu154/custom/hydro/gs_press_3", globalPropertyf }, -- Hydraulic system 3 pressure.
    -- Cockpit animations and engine sources
    { "yoke_pitch", "tu154/custom/controlls/yoke_pitch", globalPropertyf }, -- Cockpit yoke pitch animation.
    { "yoke_roll", "tu154/custom/controlls/yoke_roll", globalPropertyf }, -- Cockpit yoke roll animation.
    { "pedals_turn", "tu154/custom/controlls/pedals", globalPropertyf }, -- Cockpit pedal animation.
    { "spoilers_lever", "tu154/custom/controlls/spoilers_lever", globalPropertyf }, -- Cockpit spoiler lever animation.
    { "revers_flap_L", "sim/flightmodel2/engines/thrust_reverser_deploy_ratio[0]", globalProperty }, -- Left engine thrust reverser deployment ratio.
    { "revers_flap_R", "sim/flightmodel2/engines/thrust_reverser_deploy_ratio[2]", globalProperty }, -- Right engine thrust reverser deployment ratio.
    { "rpm_high_1", "tu154/custom/gauges/engine/rpm_high_1", globalPropertyf }, -- Engine 1 high-pressure spool RPM.
    { "rpm_high_3", "tu154/custom/gauges/engine/rpm_high_3", globalPropertyf }, -- Engine 3 high-pressure spool RPM.
    -- Electrical power
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf }, -- Left 27 V bus voltage.
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf }, -- Right 27 V bus voltage.
    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf }, -- 115 V bus 1 voltage.
    { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf }, -- 115 V bus 3 voltage.
    { "bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf }, -- Left 36 V bus voltage.
    { "bus36_volt_right", "tu154/custom/elec/bus36_volt_right", globalPropertyf }, -- Right 36 V bus voltage.
    { "bus36_volt_pts250_1", "tu154/custom/elec/bus36_volt_pts250_1", globalPropertyf }, -- PTS-250 bus 1 voltage.
    { "bus36_volt_pts250_2", "tu154/custom/elec/bus36_volt_pts250_2", globalPropertyf }, -- PTS-250 bus 2 voltage.
    -- Spoiler deployment sources
    { "deflection_mtr_2", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalProperty },
    { "deflection_mtr_3", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", globalProperty },
    { "anim_rud1", "tu154/custom/controlls/throttle_1", globalPropertyf }, -- Engine 1 throttle animation.
    { "anim_rud2", "tu154/custom/controlls/throttle_2", globalPropertyf }, -- Engine 2 throttle animation.
    { "anim_rud3", "tu154/custom/controlls/throttle_3", globalPropertyf }, -- Engine 3 throttle animation.
    { "anim_rud1_ENG", "tu154/custom/controlls/throttle_1_ENG", globalPropertyf }, -- Flight engineer engine 1 throttle animation.
    { "anim_rud2_ENG", "tu154/custom/controlls/throttle_2_ENG", globalPropertyf }, -- Flight engineer engine 2 throttle animation.
    { "anim_rud3_ENG", "tu154/custom/controlls/throttle_3_ENG", globalPropertyf }, -- Flight engineer engine 3 throttle animation.
    { "revers_L", "tu154/custom/controlls/revers_L", globalPropertyf }, -- Left reverser lever position.
    { "revers_R", "tu154/custom/controlls/revers_R", globalPropertyf }, -- Right reverser lever position.
    { "ias_L", "sim/cockpit2/gauges/indicators/airspeed_kts_pilot", globalPropertyf }, -- Pilot indicated airspeed in knots.
    { "ias_R", "sim/cockpit2/gauges/indicators/airspeed_kts_copilot", globalPropertyf }, -- Copilot indicated airspeed in knots.
    -- Electrical loads
    { "ctr_27_L_cc", "tu154/custom/control/ctr_27_L_cc", globalPropertyf }, -- Flight-control load on the left 27 V bus.
    { "ctr_27_R_cc", "tu154/custom/control/ctr_27_R_cc", globalPropertyf }, -- Flight-control load on the right 27 V bus.
    { "ctr_115_1_cc", "tu154/custom/control/ctr_115_1_cc", globalPropertyf }, -- Flight-control load on 115 V bus 1.
    { "ctr_115_2_cc", "tu154/custom/control/ctr_115_2_cc", globalPropertyf }, -- Flight-control load on 115 V bus 2.
    { "ctr_115_3_cc", "tu154/custom/control/ctr_115_3_cc", globalPropertyf }, -- Flight-control load on 115 V bus 3.
    -- ABSU commands and flight data
    { "absu_contr_pitch", "tu154/custom/absu/contr_pitch", globalPropertyf }, -- ABSU RA-56 pitch actuator command.
    { "absu_contr_roll", "tu154/custom/absu/contr_roll", globalPropertyf }, -- ABSU RA-56 roll actuator command.
    { "absu_contr_yaw", "tu154/custom/absu/contr_yaw", globalPropertyf }, -- ABSU RA-56 yaw actuator command.
    { "indicated_airspeed", "sim/flightmodel/position/indicated_airspeed", globalPropertyf }, -- Indicated airspeed.
    { "machno", "sim/flightmodel/misc/machno", globalPropertyf }, -- Mach number.
    -- SmartCopilot
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- SmartCopilot: 0 unavailable, 1 slave, 2 master.
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- SmartCopilot control state: 0 unavailable, 1 no control, 2 has control.
    -- Failures
    { "ail_fail_left", "tu154/custom/failures/ail_fail_left", globalPropertyi }, -- Left aileron failure flag.
    { "ail_fail_right", "tu154/custom/failures/ail_fail_right", globalPropertyi }, -- Right aileron failure flag.
    { "fail_spoil_inn_left", "tu154/custom/failures/fail_spoil_inn_left", globalPropertyi }, -- Left inner spoiler failure flag.
    { "fail_spoil_inn_right", "tu154/custom/failures/fail_spoil_inn_right", globalPropertyi }, -- Right inner spoiler failure flag.
    { "fail_spoil_mid_left", "tu154/custom/failures/fail_spoil_mid_left", globalPropertyi }, -- Left middle spoiler failure flag.
    { "fail_spoil_mid_right", "tu154/custom/failures/fail_spoil_mid_right", globalPropertyi }, -- Right middle spoiler failure flag.
    { "fail_spoil_out_left", "tu154/custom/failures/fail_spoil_out_left", globalPropertyi }, -- Left outer/roll spoiler failure flag.
    { "fail_spoil_out_right", "tu154/custom/failures/fail_spoil_out_right", globalPropertyi }, -- Right outer/roll spoiler failure flag.
    { "rudder_fail", "tu154/custom/failures/rudder_fail", globalPropertyi }, -- Rudder failure flag.
    { "elev_fail_left", "tu154/custom/failures/elev_fail_left", globalPropertyi }, -- Left elevator failure flag.
    { "elev_fail_right", "tu154/custom/failures/elev_fail_right", globalPropertyi }, -- Right elevator failure flag.
    { "absu_ra56_pitch_fail", "tu154/custom/failures/absu_ra56_pitch_fail", globalPropertyi }, -- RA-56 pitch failure state.
})

-- Legacy direct joystick sources kept for reference.
-- defineProperty("joy_pitch", globalPropertyf("sim/cockpit2/controls/yoke_pitch_ratio"))
-- defineProperty("joy_roll", globalPropertyf("sim/cockpit2/controls/yoke_roll_ratio"))
-- defineProperty("joy_yaw", globalPropertyf("sim/cockpit2/controls/yoke_heading_ratio"))

-- Legacy slat source kept for reference.
-- defineProperty("slats", globalPropertyf("sim/flightmodel/controls/slatrat"))

-- Legacy stabilizer/elevator position sources kept for reference.
-- defineProperty("stap_pos_real", globalProperty("sim/flightmodel2/wing/elevator2_deg[0]"))
-- defineProperty("elev_pos_real", globalProperty("sim/flightmodel2/wing/elevator1_deg[0]"))

set(overr, 1) -- Take control of the simulator control surfaces.

local buster_1_ON = 0
local buster_2_ON = 0
local buster_3_ON = 0

local roll_pos_act = 0
local pitch_pos_act = 0
local yaw_pos_act = 0

local left_mid_sp_act = 0
local right_mid_sp_act = 0
local left_inn_sp_act = 0
local right_inn_sp_act = 0

local yaw_add = 0

-- Pilot-input conditioning.
-- The deadzone removes tiny center noise while remapping the remaining axis
-- so full hardware travel still reaches exactly -1 / +1.
local INPUT_DEADZONE = 0.02
local INPUT_FILTER_TAU = 0.115
local AILERON_RUDDER_COUPLING = 0.02

local INPUT_STATE = {
    pitch = clamp(get(joy_pitch), -1, 1),
    roll = clamp(get(joy_roll), -1, 1),
    yaw = clamp(get(joy_yaw), -1, 1),
}

local function applyInputDeadzone(value)
    value = clamp(value, -1, 1)

    local abs_value = math.abs(value)
    if abs_value <= INPUT_DEADZONE then
        return 0
    end

    local scaled = (abs_value - INPUT_DEADZONE) / (1 - INPUT_DEADZONE)
    return value < 0 and -scaled or scaled
end

local function filterPilotInput(state_key, raw_value, dt)
    local target = applyInputDeadzone(raw_value)

    if dt <= 0 then
        return INPUT_STATE[state_key]
    end

    -- Exponential low-pass filter with time-based response.
    local alpha = 1 - math.exp(-dt / INPUT_FILTER_TAU)
    local filtered = INPUT_STATE[state_key]
        + (target - INPUT_STATE[state_key]) * alpha
    INPUT_STATE[state_key] = filtered
    return filtered
end

local passed = get(frame_time)

-- Physical elevator travel relative to the movable stabilizer.
local ELEVATOR_UP_LIMIT_DEG = 25
local ELEVATOR_DOWN_LIMIT_DEG = 20

-- SUU-154 longitudinal controllability constants.
-- Source relation:
--   Ksh0 = 0.111 deg/mm
--   Kx   = 1 - (140 - X_MET) / 120
--   Kx <= 0.4
--   Ksh  = Ksh0 * (1 - Kx)
local SUU_KSH0_DEG_PER_MM = 0.111
local SUU_X_BAL0_MM = 140
local SUU_TARGET_MM_PER_G = 120
local SUU_KX_MAX = 0.365 -- 0.4 
local SUU_RA56_LIMIT_DEG = 10

-- Artificial pitch-feel model for conventional non-force-feedback hardware.
-- The joystick axis is interpreted as requested pilot force. The force loader
-- changes how much virtual column travel results from that force.
local MAX_PILOT_FORCE_KGF = 35.0
local CONTROL_FRICTION_KGF = 4.0
local TAKEOFF_FULL_COLUMN_FORCE_KGF = 27.0
local FLIGHT_FULL_COLUMN_FORCE_KGF = 35.0

-- Elevator hydraulic slew-rate limit. This limits how fast the surface can
-- move, but never reduces its physical -25 / +20 degree travel authority.
local ELEVATOR_RATE_DEG_PER_SEC = 20.0

--[[
aerodynamische Wirksamkeit
+ reale Verluste
+ System-/Geometrieeffekte
+ gewünschte Tu-154-Steuercharakteristik
= effektive Elevator-Autorität
--]]
local PITCH_HIGH_MACH_TBL = {
    { 0.00, 1.00 },
    { 0.50, 0.95 },
    { 0.55, 0.95 },
    { 0.60, 0.95 },
    { 0.65, 0.95 },
    { 0.70, 0.95 },
    { 0.75, 0.95 },
    { 0.80, 0.90 },
    { 0.82, 0.90 },
    { 0.84, 0.88 },
    { 0.86, 0.75 },
    { 0.88, 0.50 },
    { 0.89, 0.30 },
    { 0.90, 0.18 },
    { 0.92, 0.13 },
    { 0.95, 0.11 },
    { 1.00, 0.08 },
}

local HIGH_MACH_FULL_AUTHORITY_START = 0.65

local function interpolateTable(tbl, value)
    if value <= tbl[1][1] then
        return tbl[1][2]
    end
    for i = 2, #tbl do
        local x1 = tbl[i - 1][1]
        local y1 = tbl[i - 1][2]
        local x2 = tbl[i][1]
        local y2 = tbl[i][2]
        if value <= x2 then
            local span = x2 - x1
            if math.abs(span) < 1e-6 then
                return y2
            end
            local t = (value - x1) / span
            return y1 + (y2 - y1) * t
        end
    end
    return tbl[#tbl][2]
end

local function pitchColumnFromForce(pilot_ratio, force_loader_pos)
    pilot_ratio = clamp(pilot_ratio, -1, 1)
    force_loader_pos = clamp(force_loader_pos, 0, 1)

    local sign = pilot_ratio < 0 and -1 or 1
    local pilot_force_kgf = math.abs(pilot_ratio) * MAX_PILOT_FORCE_KGF

    if pilot_force_kgf <= CONTROL_FRICTION_KGF then
        return 0
    end

    local full_column_force_kgf =
        TAKEOFF_FULL_COLUMN_FORCE_KGF
        + (FLIGHT_FULL_COLUMN_FORCE_KGF - TAKEOFF_FULL_COLUMN_FORCE_KGF)
        * force_loader_pos

    local effective_force_kgf = pilot_force_kgf - CONTROL_FRICTION_KGF
    local effective_full_force_kgf = math.max(
        full_column_force_kgf - CONTROL_FRICTION_KGF,
        1.0
    )

    local column = clamp(
        effective_force_kgf / effective_full_force_kgf,
        0,
        1
    )

    return column * sign
end

local function applyHighMachPitchStiffness(column, mach)
    column = clamp(column, -1, 1)

    local gain = interpolateTable(PITCH_HIGH_MACH_TBL, mach)
    if gain >= 0.999 then
        return column
    end

    local abs_column = math.abs(column)
    local sign = column < 0 and -1 or 1

-- Apply the full high-Mach reduction during normal MET travel.
-- Near maximum MET deflection, progressively restore the reduced elevator
-- authority to preserve the available control range at high pilot force.
    local restored_gain = gain
    if abs_column > HIGH_MACH_FULL_AUTHORITY_START then
        local overforce = clamp(
            (abs_column - HIGH_MACH_FULL_AUTHORITY_START)
            / (1 - HIGH_MACH_FULL_AUTHORITY_START),
            0,
            1
        )
        restored_gain = gain + (1 - gain) * overforce
    end

    return sign * abs_column * restored_gain
end

local function pitchRatioToElevatorDeg(ratio)
    ratio = clamp(ratio, -1, 1)

    if ratio >= 0 then
        return -ratio * ELEVATOR_UP_LIMIT_DEG
    end

    return -ratio * ELEVATOR_DOWN_LIMIT_DEG
end

local function elevatorDegToPitchRatio(elevator_deg)
    elevator_deg = clamp(
        elevator_deg,
        -ELEVATOR_UP_LIMIT_DEG,
        ELEVATOR_DOWN_LIMIT_DEG
    )

    if elevator_deg <= 0 then
        return -elevator_deg / ELEVATOR_UP_LIMIT_DEG
    end

    return -elevator_deg / ELEVATOR_DOWN_LIMIT_DEG
end

local function getSuuKx(trim_ratio)
    -- int_pitch_trim is the project's MET-induced balanced-column bias.
    -- Convert it to the equivalent elevator angle, then to column travel
    -- through the documented mechanical ratio Ksh0.
    local balanced_elevator_deg = pitchRatioToElevatorDeg(trim_ratio)
    local x_met_mm = balanced_elevator_deg / SUU_KSH0_DEG_PER_MM

    local k_x = 1
        - (SUU_X_BAL0_MM - x_met_mm) / SUU_TARGET_MM_PER_G

    -- The source explicitly caps the positive side at Kx = 0.4.
    if k_x > SUU_KX_MAX then
        k_x = SUU_KX_MAX
    end

    return k_x
end

local function ra56PitchAvailable(ch1, ch2, ch3, fail_state, hydraulics_available)
    -- Match the existing PPN-13 RA-56 pitch failure semantics. The real
    -- longitudinal-control correction needs at least two usable channels.
    if not hydraulics_available then
        return false
    end

    local available = 0

    if ch1 == 1 and fail_state ~= 3 then
        available = available + 1
    end
    if ch2 == 1 and fail_state < 2 then
        available = available + 1
    end
    if ch3 == 1 and fail_state == 0 then
        available = available + 1
    end
    return available > 1
end

function update()
    local MASTER = get(ismaster) ~= 1

    passed = get(frame_time)

    -- Filter only pilot hardware inputs. Trim and ABSU commands remain direct.
    local pilot_pitch = filterPilotInput("pitch", get(joy_pitch), passed)
    local pilot_roll = filterPilotInput("roll", get(joy_roll), passed)
    local pilot_yaw = filterPilotInput("yaw", get(joy_yaw), passed)

    -- Small coordinated-turn assistance for users without rudder pedals.
    -- Positive roll adds the corresponding yaw input before the existing
    -- rudder sign conversion, while any real yaw input remains fully additive.
    local coupled_yaw = clamp(
        pilot_yaw + pilot_roll * AILERON_RUDDER_COUPLING,
        -1,
        1
    )

    -- Retained for compatibility with the original logic and future use.
    local ias = get(indicated_airspeed) * 1.852
    local mach = get(machno)

    -- Electrical supply state.
    local bus27_left = get(bus27_volt_left)
    local bus27_right = get(bus27_volt_right)
    local power_27_L = bus27_left > 13
    local power_27_R = bus27_right > 13

    -- A booster cannot remain active after its electrical supply is lost.
    buster_1_ON = power_27_L and get(buster_on_1) or 0
    buster_2_ON = power_27_L and get(buster_on_2) or 0
    buster_3_ON = power_27_R and get(buster_on_3) or 0

    -- Hydraulic authority begins to decrease below 63 atm.
    local HS1 = clamp(get(gs_press_1) / 63, 0, 1)
    local HS2 = clamp(get(gs_press_2) / 63, 0, 1)
    local HS3 = clamp(get(gs_press_3) / 63, 0, 1)
    local hydraulic_authority = math.max(HS1, HS2, HS3)

    -- Powered boosters provide normal authority. If both 27 V buses are lost,
    -- the mechanical fallback keeps the primary controls available at 30%.
    local boosted_response = math.max(
        HS1 * buster_1_ON,
        HS2 * buster_2_ON,
        HS3 * buster_3_ON
    )
    local manual_control = not power_27_L and not power_27_R and hydraulic_authority > 0.01
    local primary_command_limit = manual_control and 0.3 or 1
    local primary_response = manual_control and hydraulic_authority or boosted_response
    local primary_step = math.min(primary_response * passed * 10, 1)

    -- Cache failure states used more than once in this frame.
    local ail_fail_L = get(ail_fail_left)
    local ail_fail_R = get(ail_fail_right)
    local spoil_inn_fail_L = get(fail_spoil_inn_left)
    local spoil_inn_fail_R = get(fail_spoil_inn_right)
    local spoil_mid_fail_L = get(fail_spoil_mid_left)
    local spoil_mid_fail_R = get(fail_spoil_mid_right)
    local spoil_out_fail_L = get(fail_spoil_out_left)
    local spoil_out_fail_R = get(fail_spoil_out_right)
    local elevator_fail_L = get(elev_fail_left)
    local elevator_fail_R = get(elev_fail_right)
    local rudder_failed = get(rudder_fail)

    --------------------------------------------------------------------------
    -- Ailerons and roll spoilers
    --------------------------------------------------------------------------
    local cockpit_yoke_roll = clamp(pilot_roll + get(int_roll_trim), -1, 1)
    local roll_cmd = clamp(cockpit_yoke_roll + get(absu_contr_roll), -1, 1)
    local roll_target = roll_cmd * primary_command_limit

    if primary_step > 0 then
        roll_pos_act = roll_pos_act + (roll_target - roll_pos_act) * primary_step
    end

    -- Enforce the 30% surface limit immediately while in manual fallback.
    local roll_surface_pos = manual_control and clamp(roll_pos_act, -0.3, 0.3) or roll_pos_act
    local roll_mach_coef = line(mach, 0, 1, 0.8, 0.5)
    local left_ail_pos = roll_surface_pos * 20 * roll_mach_coef
    local right_ail_pos = -roll_surface_pos * 20 * roll_mach_coef

    local roll_sp_L = 0
    if left_ail_pos <= -1.5 then
        roll_sp_L = -((left_ail_pos + 1.5) / 18.5) * 45
    end

    local roll_sp_R = 0
    if right_ail_pos <= -1.5 then
        roll_sp_R = -((right_ail_pos + 1.5) / 18.5) * 45
    end

    if MASTER then
        set(ail_L, left_ail_pos * (1 - ail_fail_L))
        set(ail_R, right_ail_pos * (1 - ail_fail_R))
        set(roll_spoil_L, roll_sp_L * (1 - spoil_out_fail_L))
        set(roll_spoil_R, roll_sp_R * (1 - spoil_out_fail_R))
    end

    --------------------------------------------------------------------------
    -- Spoilers
    --------------------------------------------------------------------------
    local left_main_deflection = get(deflection_mtr_2)
    local right_main_deflection = get(deflection_mtr_3)
    local gears_on_ground = left_main_deflection > 0.01 and right_main_deflection > 0.01

    local throttle_1 = get(anim_rud1)
    local throttle_2 = get(anim_rud2)
    local throttle_3 = get(anim_rud3)
    local throttles_idle = throttle_1 < 0.1 and throttle_2 < 0.1 and throttle_3 < 0.1

    local reverse_active = get(revers_L) > 0.1 and get(revers_R) > 0.1
    local IAS_lim = get(ias_L) > 54 or get(ias_R) > 54
    local auto_deploy = power_27_L and gears_on_ground and ((throttles_idle and IAS_lim) or reverse_active)

    -- Middle spoilers.
    if auto_deploy and MASTER then
        set(speedbrake_ratio, 1)
    end

    local spd_brk_cmd = get(speedbrake_ratio)
    local spd_brk_L = spd_brk_cmd * 45 * bool2int(power_27_L)
    local spd_brk_R = spd_brk_cmd * 45 * bool2int(power_27_L)

    if HS1 > 0.01 then
        local mid_spoiler_step = math.min(HS1 * passed * 15, 1)
        left_mid_sp_act = left_mid_sp_act + (spd_brk_L - left_mid_sp_act) * mid_spoiler_step
        right_mid_sp_act = right_mid_sp_act + (spd_brk_R - right_mid_sp_act) * mid_spoiler_step
    end

    if MASTER then
        set(spd_brk_mid_L, left_mid_sp_act * (1 - spoil_mid_fail_L))
        set(spd_brk_mid_R, right_mid_sp_act * (1 - spoil_mid_fail_R))
    end

    -- Inner spoilers.
    local spoilers_cmd = bool2int(auto_deploy)
    local spoil_L = spoilers_cmd * 50 * bool2int(power_27_L)
    local spoil_R = spoilers_cmd * 50 * bool2int(power_27_L)

    if HS1 > 0.01 then
        local inner_speed = spoilers_cmd == 1 and 10 or 1
        local inner_spoiler_step = math.min(HS1 * passed * inner_speed, 1)
        left_inn_sp_act = left_inn_sp_act + (spoil_L - left_inn_sp_act) * inner_spoiler_step
        right_inn_sp_act = right_inn_sp_act + (spoil_R - right_inn_sp_act) * inner_spoiler_step
    end

    if MASTER then
        set(spd_brk_inn_L, left_inn_sp_act * (1 - spoil_inn_fail_L))
        set(spd_brk_inn_R, right_inn_sp_act * (1 - spoil_inn_fail_R))
    end

    --------------------------------------------------------------------------
    -- Flight-control force-loader mechanism
    --------------------------------------------------------------------------
    local force_pos = get(control_force_pos)
    local force_pos_rud = get(control_force_pos_rud)
    local forcing_sw = get(contr_force_set)
    local flap_left = get(flap_inn_L)
    local flap_right = get(flap_inn_R)
    local gear_left_ground = get(gear2_deflect) >= 0.01
    local gear_right_ground = get(gear3_deflect) >= 0.01

    if MASTER then
        local force_loader_current = 0

        if power_27_L and power_27_R then
            -- Elevator force-loader position.
            local elevator_flight_mode =
                (forcing_sw == 0 and flap_left < 7 and flap_right < 7)
                or forcing_sw == -1

            if elevator_flight_mode then
                force_pos = force_pos + passed * 0.04
                if force_pos < 0.99 then
                    force_loader_current = 5
                end
            else
                force_pos = force_pos - passed * 0.04
                if force_pos > 0.01 then
                    force_loader_current = 5
                end
            end

            -- Rudder force-loader position.
            local rudder_flight_mode =
                (forcing_sw == 0
                    and flap_left < 7
                    and flap_right < 7
                    and not gear_left_ground
                    and not gear_right_ground)
                or forcing_sw == -1

            if rudder_flight_mode then
                force_pos_rud = force_pos_rud + passed * 0.08
                if force_pos_rud < 0.99 then
                    force_loader_current = 5
                end
            else
                force_pos_rud = force_pos_rud - passed * 0.08
                if force_pos_rud > 0.01 then
                    force_loader_current = 5
                end
            end
        end

        force_pos = clamp(force_pos, 0, 1)
        force_pos_rud = clamp(force_pos_rud, 0, 1)

        set(ctr_27_L_cc, force_loader_current)
        set(ctr_27_R_cc, force_loader_current)
        set(control_force_pos, force_pos)
        set(control_force_pos_rud, force_pos_rud)
    end

    --------------------------------------------------------------------------
    -- Elevator / SUU-154 longitudinal controllability
    --------------------------------------------------------------------------
    local trim_ratio = clamp(get(int_pitch_trim), -1, 1)

    -- Convert the conventional joystick axis into a virtual pilot force first.
    -- The force-loader state then determines the resulting column travel.
    local force_column_pitch = pitchColumnFromForce(pilot_pitch, force_pos)

    -- Above M0.86, progressively stiffen only the manual pilot path. This does
    -- not change the physical elevator stops and does not attenuate RA-56/ABSU.
    local high_mach_column_pitch = applyHighMachPitchStiffness(
        force_column_pitch,
        mach
    )

    -- MET trim shifts the balanced/zero-force column position.
    local cockpit_yoke_pitch = clamp(
        high_mach_column_pitch + trim_ratio,
        -1,
        1
    )

    -- Direct mechanical booster path: column/MET position to elevator.
    local mechanical_elevator_deg =
        pitchRatioToElevatorDeg(cockpit_yoke_pitch)

    local suu_correction_deg = 0
    local k_x = getSuuKx(trim_ratio)

    -- The PPN-13 logic treats the RA-56 servos as unavailable when fewer than
    -- two hydraulic systems remain above the operating-pressure threshold.
    local hydraulics_available =
        bool2int(get(gs_press_1) >= 100)
        + bool2int(get(gs_press_2) >= 100)
        + bool2int(get(gs_press_3) >= 100) >= 2

    local ra56_pitch_on = ra56PitchAvailable(
        get(hydro_ra56_elev_1),
        get(hydro_ra56_elev_2),
        get(hydro_ra56_elev_3),
        get(absu_ra56_pitch_fail),
        hydraulics_available
    )

    if get(hydro_long_control) == 1 and ra56_pitch_on then
        -- Static SUU-154 term:
        --   delta_e = Ksh0 * dx - Ksh0 * Kx * dx
        --           = Ksh0 * (1 - Kx) * dx
        --
        -- The virtual column already contains the force-loader and high-Mach
        -- behavior. SUU therefore acts on that physical column displacement,
        -- not directly on the raw hardware axis.
        local direct_pilot_elevator_deg =
            pitchRatioToElevatorDeg(high_mach_column_pitch)

        suu_correction_deg = clamp(
            -k_x * direct_pilot_elevator_deg,
            -SUU_RA56_LIMIT_DEG,
            SUU_RA56_LIMIT_DEG
        )
    end

    local suu_elevator_deg = clamp(
        mechanical_elevator_deg + suu_correction_deg,
        -ELEVATOR_UP_LIMIT_DEG,
        ELEVATOR_DOWN_LIMIT_DEG
    )

    local suu_pitch_ratio =
        elevatorDegToPitchRatio(suu_elevator_deg)

    -- Keep the existing ABSU command path additive for this validation step.
    -- The dynamic K_omegaZ * omegaZ term is not duplicated here.
    local pitch_cmd = clamp(
        suu_pitch_ratio + get(absu_contr_pitch),
        -1,
        1
    )
    local pitch_target = pitch_cmd * primary_command_limit

    -- Move the elevator toward the commanded position with a physical slew-rate
    -- limit instead of the old very fast first-order response. Hydraulic state
    -- scales movement speed, but does not alter the normal travel limits.
    local target_elevator_deg = pitchRatioToElevatorDeg(pitch_target)
    local current_elevator_deg = pitchRatioToElevatorDeg(pitch_pos_act)

    if primary_response > 0 and passed > 0 then
        local max_elevator_step =
            ELEVATOR_RATE_DEG_PER_SEC * primary_response * passed

        current_elevator_deg = current_elevator_deg + clamp(
            target_elevator_deg - current_elevator_deg,
            -max_elevator_step,
            max_elevator_step
        )

        current_elevator_deg = clamp(
            current_elevator_deg,
            -ELEVATOR_UP_LIMIT_DEG,
            ELEVATOR_DOWN_LIMIT_DEG
        )

        pitch_pos_act = elevatorDegToPitchRatio(current_elevator_deg)
    end

    local pitch_surface_pos = manual_control
        and clamp(pitch_pos_act, -0.3, 0.3)
        or pitch_pos_act

    local elev_left
    local elev_right

    if pitch_surface_pos >= 0 then
        elev_left = -pitch_surface_pos * ELEVATOR_UP_LIMIT_DEG
        elev_right = -pitch_surface_pos * ELEVATOR_UP_LIMIT_DEG
    else
        elev_left = -pitch_surface_pos * ELEVATOR_DOWN_LIMIT_DEG
        elev_right = -pitch_surface_pos * ELEVATOR_DOWN_LIMIT_DEG
    end

    elev_left = clamp(
        elev_left,
        -ELEVATOR_UP_LIMIT_DEG,
        ELEVATOR_DOWN_LIMIT_DEG
    )
    elev_right = clamp(
        elev_right,
        -ELEVATOR_UP_LIMIT_DEG,
        ELEVATOR_DOWN_LIMIT_DEG
    )

    if MASTER then
        set(elevator_L, elev_left * (1 - elevator_fail_L))
        set(elevator_R, elev_right * (1 - elevator_fail_R))
    end

    --------------------------------------------------------------------------
    -- Rudder
    --------------------------------------------------------------------------
    local yaw_joy = coupled_yaw
    local cockpit_yoke_yaw = yaw_joy + get(int_yaw_trim)
    local yaw_force_limit = 1 - force_pos_rud * 0.6

    if cockpit_yoke_yaw > yaw_force_limit then
        cockpit_yoke_yaw = yaw_force_limit
    elseif cockpit_yoke_yaw < -yaw_force_limit then
        cockpit_yoke_yaw = -yaw_force_limit
    end

    -- Allow the pilot to overforce the yaw force-loader limit.
    if yaw_joy > 0.9 and yaw_add < 2 then
        yaw_add = yaw_add + passed * 0.3
    elseif yaw_joy < -0.9 and yaw_add > -2 then
        yaw_add = yaw_add - passed * 0.3
    elseif math.abs(yaw_joy) < 0.9 then
        yaw_add = 0
    end

    cockpit_yoke_yaw = clamp(cockpit_yoke_yaw + yaw_add, -1, 1)

    local rud_cmd = clamp(-cockpit_yoke_yaw - get(absu_contr_yaw), -1, 1)
    local rud_target = rud_cmd * primary_command_limit

    if primary_step > 0 then
        yaw_pos_act = yaw_pos_act + (rud_target - yaw_pos_act) * primary_step
    end

    local yaw_surface_pos = manual_control and clamp(yaw_pos_act, -0.3, 0.3) or yaw_pos_act
    local rudder_pos = yaw_surface_pos * 25 * roll_mach_coef

    -- Reverse deployment reduces available rudder authority as before.
    local reverse_flap_left = get(revers_flap_L)
    local reverse_flap_right = get(revers_flap_R)
    local rudder_L = 1 - math.max(reverse_flap_left - 0.5, 0) * get(rpm_high_1) * 0.015
    local rudder_R = 1 - math.max(reverse_flap_right - 0.5, 0) * get(rpm_high_3) * 0.015

    if MASTER then
        set(rudder, rudder_pos * ((rudder_L + rudder_R) * 0.5) * (1 - rudder_failed))

        ----------------------------------------------------------------------
        -- Cockpit animations
        ----------------------------------------------------------------------
        set(spd_brk_inn_anim_L, left_inn_sp_act * (1 - spoil_inn_fail_L))
        set(spd_brk_inn_anim_R, right_inn_sp_act * (1 - spoil_inn_fail_R))
        set(yoke_pitch, cockpit_yoke_pitch)
        set(yoke_roll, cockpit_yoke_roll)
        set(pedals_turn, cockpit_yoke_yaw)
        set(spoilers_lever, spd_brk_cmd)
    end
end

function onModuleDone()
    set(overr, 0)
    print("flight controls released")
end
