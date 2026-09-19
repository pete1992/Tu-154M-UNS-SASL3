-- stall.lua
-- Tu-154M: flow-driven asymmetric stall supplement for X-Plane 12 / SASL 3.
-- Version 4.4.0-XP12.

--[[ Changelog
2026-09-14 | 4.4.0-XP12
    - Replace raw-yoke/aggression gates with actual elevator and sustained AoA.
    - Keep separation active with trim-held elevator and neutral joystick.
    - Recover after sustained low AoA; re-evaluate forces during the fade.
    - Permit re-entry during recovery without changing the latched weak side.
    - Add roll-induced local AoA to the 48 virtual elements; shorten progression.
    - Reduce separation-dependent P/R damping, retaining high-rate damping.
    - Replace late fixed pitch assist with limited native nose-down attenuation.
    - Publish this component's own state and five force/moment contributions.
    - Reject invalid inputs without modifying other plugins' accumulators.

2026-09-08 | 4.3.2-XP12
    - Port the v4.3.1 supplement to XP12 and use local gravity.
    - Retain additive aircraft-axis forces and the single-component lifecycle.

Integration
    Replace the installed aggressive_stall.lua; register aggressive_stall {}
    exactly once after frame_time and flight_controls {} in SASL.
    This is a SASL component, not a standalone FlyWithLua/XTLua script.
    Keep the existing airfoil, flap, stabilizer and flight_controls files.
    Do not run another stall supplement in parallel.
    SmartCopilot mode 1 is slave; modes 0/2 permit local computation.

Calibration and scope
    This is an empirical simulator tuning revision based on Data(2).txt.
    It adds forces/moments; it does not write rates, attitude, native element
    coefficients, deflections or simulator overrides. It has no thrust gate.
    Its coefficients are not measured real-Tu-154 post-stall derivatives.
    A log replay verifies software response, not the resulting flight path.

    Clean flap/slat/gear configuration and Mach 0.10..0.70 are retained.
    Entry: alpha >= entry threshold with actual elevator <= -18 deg for
    0.20 s, OR alpha >= threshold + 1.25 deg regardless of elevator/yoke.
    Threshold: 12.3..11.5 deg with Mach. Raw pitch is diagnostic only.
    All elements finish time progression by 1.10 s, subject to local flow.
    The lower wing's roll-induced AoA can increase its separation.

    Recovery: alpha < 9 deg continuously for 0.40 s, or envelope exit.
    Force fade: 1.25 s, recomputed from current air data and rates.
    Re-entry above the threshold preserves event side/age and restores the
    current output blend over 0.20 s, without a full-strength one-frame step.
    Changing the joystick or elevator alone never declares reattachment.
    Direction uses beta, rotation and lateral controls; with neutral cues,
    successive events alternate sides deterministically.

    Pitch compensation starts above threshold - 0.30 deg and reaches its
    full alpha blend at threshold + 3.70 deg. It can remove at most 80% of
    the CURRENT negative native M_aero, and is further bounded by q*S*c*0.23
    and 900 kNm. Actual elevator relief removes this correction; it does not
    erase wing separation. Positive native M is never amplified. This is a
    balance correction, not a claim that all M_aero comes from the tail.
    Forces use N, moments Nm. Native M_aero excludes plugin contributions;
    never substitute M_total or M_plug_acf here (that would create feedback).

Diagnostics: tu154/custom/stall_xp12/
    state: 0 normal, 1 entry, 2 developed separation, 3 recovery
    side: -1 left, +1 right, 0 inactive; NOT a measured native stall flag
    alpha_entry_deg, elevator_deg, yoke_pitch, dynamic_pressure_Pa
    separation: area-weighted virtual-element progression, 0..1
    force_blend: recovery/re-entry output envelope, 0..1
    normal_N, axial_N, roll_Nm, pitch_Nm, yaw_Nm: THIS component only
    native_pitch_Nm: sampled native aerodynamic moment
    entry_elapsed_s, recovery_elapsed_s, release_elapsed_s
    exit_reason: 0 none, 1 low alpha, 2 configuration/Mach
    reset_reason: 0 none, 1 ground, 2 pause/replay, 3 slave, 4 invalid input
    These properties are SASL-owned and do not control the model.

References
    https://developer.x-plane.com/article/movingtheplane/
    https://1-sim.com/files/SASL3Manual.pdf
]]

-- local defineProps Function
local function defineProps(defs)
    for _, def in ipairs(defs) do
        local prop
        if def[4] ~= nil then
            prop = def[3](def[2], def[4])
        else
            prop = def[3](def[2])
        end
        defineProperty(def[1], prop)
    end
end

local function diagnosticFloat(path)
    return createGlobalPropertyf(path, 0, false, false, true)
end

local function diagnosticInt(path)
    return createGlobalPropertyi(path, 0, false, false, true)
end

defineProps({
    {"alpha_deg", "sim/flightmodel2/misc/AoA_angle_degrees", globalPropertyf},
    {"beta_deg", "sim/flightmodel/position/beta", globalPropertyf},
    {"mach_no", "sim/flightmodel/misc/machno", globalPropertyf},
    {"roll_rate", "sim/flightmodel/position/P", globalPropertyf},
    {"pitch_rate", "sim/flightmodel/position/Q", globalPropertyf},
    {"yaw_rate", "sim/flightmodel/position/R", globalPropertyf},
    {"true_airspeed", "sim/flightmodel/position/true_airspeed", globalPropertyf},
    {"air_density", "sim/weather/rho", globalPropertyf},
    {"total_mass", "sim/flightmodel/weight/m_total", globalPropertyf},
    {"gravity", "sim/weather/aircraft/gravity_mss", globalPropertyf},
    {"raw_pitch", "tu154/custom/SC/yoke_pitch_ratio", globalPropertyf},
    {"raw_roll", "tu154/custom/SC/yoke_roll_ratio", globalPropertyf},
    {"raw_yaw", "tu154/custom/SC/yoke_heading_ratio", globalPropertyf},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"flap_inner_left", "sim/flightmodel/controls/wing1l_fla1def", globalPropertyf},
    {"flap_inner_right", "sim/flightmodel/controls/wing1r_fla1def", globalPropertyf},
    {"flap_middle_left", "sim/flightmodel/controls/wing2l_fla2def", globalPropertyf},
    {"flap_middle_right", "sim/flightmodel/controls/wing2r_fla2def", globalPropertyf},
    {"slat_ratio", "sim/flightmodel2/controls/slat1_deploy_ratio", globalPropertyf},
    {"gear_nose", "sim/flightmodel2/gear/deploy_ratio[0]", globalProperty},
    {"gear_left", "sim/flightmodel2/gear/deploy_ratio[1]", globalProperty},
    {"gear_right", "sim/flightmodel2/gear/deploy_ratio[2]", globalProperty},
    {"elevator_left", "sim/flightmodel/controls/hstab1_elv1def", globalPropertyf},
    {"elevator_right", "sim/flightmodel/controls/hstab2_elv1def", globalPropertyf},
    {"on_ground", "sim/flightmodel/failures/onground_any", globalPropertyi},
    {"paused", "sim/time/paused", globalPropertyi},
    {"in_replay", "sim/time/is_in_replay", globalPropertyi},
    {"smartcopilot_master", "scp/api/ismaster", globalPropertyf},
    {"native_pitch_moment", "sim/flightmodel/forces/M_aero", globalPropertyf},
    {"normal_plugin", "sim/flightmodel/forces/fnrml_plug_acf", globalPropertyf},
    {"axial_plugin", "sim/flightmodel/forces/faxil_plug_acf", globalPropertyf},
    {"roll_plugin", "sim/flightmodel/forces/L_plug_acf", globalPropertyf},
    {"pitch_plugin", "sim/flightmodel/forces/M_plug_acf", globalPropertyf},
    {"yaw_plugin", "sim/flightmodel/forces/N_plug_acf", globalPropertyf},

    -- SASL-owned diagnostics; published for DataRefTool and custom recorders.

    {"diag_state", "tu154/custom/stall_xp12/state", diagnosticInt},
    {"diag_side", "tu154/custom/stall_xp12/side", diagnosticInt},
    {"diag_alpha_entry", "tu154/custom/stall_xp12/alpha_entry_deg", diagnosticFloat},
    {"diag_elevator", "tu154/custom/stall_xp12/elevator_deg", diagnosticFloat},
    {"diag_yoke", "tu154/custom/stall_xp12/yoke_pitch", diagnosticFloat},
    {"diag_pressure", "tu154/custom/stall_xp12/dynamic_pressure_Pa", diagnosticFloat},
    {"diag_separation", "tu154/custom/stall_xp12/separation", diagnosticFloat},
    {"diag_blend", "tu154/custom/stall_xp12/force_blend", diagnosticFloat},
    {"diag_normal", "tu154/custom/stall_xp12/normal_N", diagnosticFloat},
    {"diag_axial", "tu154/custom/stall_xp12/axial_N", diagnosticFloat},
    {"diag_roll", "tu154/custom/stall_xp12/roll_Nm", diagnosticFloat},
    {"diag_pitch", "tu154/custom/stall_xp12/pitch_Nm", diagnosticFloat},
    {"diag_yaw", "tu154/custom/stall_xp12/yaw_Nm", diagnosticFloat},
    {"diag_native_pitch", "tu154/custom/stall_xp12/native_pitch_Nm", diagnosticFloat},
    {"diag_entry_age", "tu154/custom/stall_xp12/entry_elapsed_s", diagnosticFloat},
    {"diag_recovery_age", "tu154/custom/stall_xp12/recovery_elapsed_s", diagnosticFloat},
    {"diag_release_age", "tu154/custom/stall_xp12/release_elapsed_s", diagnosticFloat},
    {"diag_exit_reason", "tu154/custom/stall_xp12/exit_reason", diagnosticInt},
    {"diag_reset_reason", "tu154/custom/stall_xp12/reset_reason", diagnosticInt},
})

local STATE_NORMAL = 0
local STATE_ENTRY = 1
local STATE_DEVELOPED = 2
local STATE_RECOVERY = 3
local SIDE_LEFT = -1
local SIDE_RIGHT = 1
local ENTRY_MACH_MIN = 0.10
local ENTRY_MACH_MAX = 0.70
local ENTRY_ELEVATOR_MAX = -18.0
local UNCOMMANDED_ALPHA_MARGIN = 1.25
local ENTRY_CONFIRM_TIME = 0.20
local DEVELOPED_TIME = 1.10
local RECOVERY_ALPHA = 5.00
local RECOVERY_CONFIRM_TIME = 0.40
local RECOVERY_FADE_TIME = 1.25
local REENTRY_BLEND_TIME = 0.20
local DYNAMIC_PRESSURE_MAX = 3600.0
local WING_REFERENCE_AREA = 202.1870
local WING_MOMENT_CHORD = 6.4234
local WING_SPAN = 37.55
local ROLL_DAMPING_COEFFICIENT = 0.12
local YAW_DAMPING_COEFFICIENT = 0.02
local MAX_ROLL_MOMENT = 600000.0
local MAX_PITCH_MOMENT = 900000.0
local MAX_YAW_MOMENT = 950000.0
local PITCH_COMPENSATION_FRACTION = 0.90
local MAX_PITCH_CM = 0.23
local NATIVE_PITCH_FILTER_TIME = 0.12

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end
local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end
local function clamp01(value)
    return clamp(value, 0, 1)
end
local function smoothstep01(value)
    value = clamp01(value)
    return value * value * (3 - 2 * value)
end
local function smoothstepRange(edge0, edge1, value)
    return smoothstep01((value - edge0) / (edge1 - edge0))
end
local function mix(a, b, ratio)
    return a + (b - a) * ratio
end

-- Existing per-band increments retained; development now reaches them sooner.
local ENTRY_WEAK = {
    [1] = {cl = -0.38, cd = 0.14},
    [2] = {cl = -0.30, cd = 0.12},
    [3] = {cl = -0.16, cd = 0.08},
}

local ENTRY_OTHER = {
    [1] = {cl = -0.22, cd = 0.06},
    [2] = {cl = -0.16, cd = 0.05},
    [3] = {cl = -0.08, cd = 0.03},
}

local SPIN_WEAK = {
    [1] = {cl = -0.44, cd = 0.30},
    [2] = {cl = -0.40, cd = 0.28},
    [3] = {cl = -0.30, cd = 0.25},
}

local SPIN_OTHER = {
    [1] = {cl = -0.32, cd = 0.10},
    [2] = {cl = -0.28, cd = 0.08},
    [3] = {cl = -0.20, cd = 0.06},
}

-- Exact active element areas and lateral arms from Cycle Dump
-- (20260830-161425). Wing-1 elements 0/1 remain native inside the fuselage.
local BAND_AREA = {
    [1] = {6.1499, 5.7808, 5.4117, 5.0426, 4.6735, 4.3044, 3.9353, 3.5663},
    [2] = {5.2949, 5.0271, 4.7593, 4.4915, 4.2238, 3.9560, 3.6882, 3.4205},
    [3] = {2.0705, 1.9775, 1.8845, 1.7916, 1.6986, 1.6056, 1.5126, 1.4197},
}

local BAND_ARM = {
    [1] = {1.58, 2.22, 2.85, 3.49, 4.12, 4.75, 5.39, 6.02},
    [2] = {6.82, 7.78, 8.75, 9.71, 10.67, 11.63, 12.60, 13.56},
    [3] = {14.35, 14.98, 15.61, 16.23, 16.86, 17.48, 18.11, 18.73},
}


local WEAK_BAND_START = {[1] = 0.00, [2] = 0.18, [3] = 0.40}
local OTHER_BAND_START = {[1] = 0.10, [2] = 0.35, [3] = 0.62}
local BAND_SPREAD_TIME = {[1] = 0.20, [2] = 0.30, [3] = 0.38}
local ELEMENT_RAMP_TIME = 0.10
local elements = {}
local virtual_area = 0
for band = 1, 3 do
    for order = 0, 7 do
        for _, side in ipairs({SIDE_LEFT, SIDE_RIGHT}) do
            local slot = order + 1
            elements[#elements + 1] = {
                side = side, band = band, order = order,
                area = BAND_AREA[band][slot], arm = BAND_ARM[band][slot],
            }
            virtual_area = virtual_area + BAND_AREA[band][slot]
        end
    end
end

local state = STATE_NORMAL
local weak_side = SIDE_RIGHT
local next_neutral_side = SIDE_RIGHT
local event_age = 0
local entry_timer = 0
local recovery_age = 0
local release_timer = 0
local exit_reason = 0
local output_blend = 1
local recovery_start_blend = 1
local resume_start_blend = 1
local resume_age = REENTRY_BLEND_TIME
local filtered_nose_down = 0
local pitch_filter_ready = false

local function publishZeroForces()
    set(diag_normal, 0)
    set(diag_axial, 0)
    set(diag_roll, 0)
    set(diag_pitch, 0)
    set(diag_yaw, 0)
    set(diag_separation, 0)
end
local function publishState()
    set(diag_state, state)
    set(diag_side, state == STATE_NORMAL and 0 or weak_side)
    set(diag_entry_age, event_age)
    set(diag_recovery_age, recovery_age)
    set(diag_release_age, release_timer)
    set(diag_exit_reason, exit_reason)
    set(diag_blend, state == STATE_NORMAL and 0 or output_blend)
end
local function resetState(reason)
    state = STATE_NORMAL
    event_age = 0
    entry_timer = 0
    recovery_age = 0
    release_timer = 0
    exit_reason = 0
    output_blend = 1
    recovery_start_blend = 1
    resume_start_blend = 1
    resume_age = REENTRY_BLEND_TIME
    filtered_nose_down = 0
    pitch_filter_ready = false
    publishZeroForces()
    publishState()
    set(diag_reset_reason, reason or 0)
    set(diag_pressure, 0)
    set(diag_alpha_entry, 0)
    set(diag_elevator, 0)
    set(diag_yoke, 0)
    set(diag_native_pitch, 0)
    -- Never clear shared plugin force accumulators here.
end
local config_properties = {
    flap_inner_left, flap_inner_right, flap_middle_left, flap_middle_right,
    slat_ratio, gear_nose, gear_left, gear_right,
}
local function cleanConfiguration()
    local clean = true
    for i, property in ipairs(config_properties) do
        local value = get(property)
        if not finite(value) then
            return nil
        end
        if i <= 4 then
            if math.abs(value) >= 1.0 then clean = false end
        elseif math.abs(value) >= 0.05 then
            clean = false
        end
    end
    return clean
end
local function entryTripAlpha(mach)
    return 12.30 - 0.80 * smoothstepRange(0.25, 0.50, mach)
end
local function chooseWeakSide(beta, yaw_input, roll_rate_value, roll_input)
    if beta > 1.00 then
        return SIDE_RIGHT
    elseif beta < -1.00 then
        return SIDE_LEFT
    elseif roll_rate_value > 0.40 then
        return SIDE_RIGHT
    elseif roll_rate_value < -0.40 then
        return SIDE_LEFT
    elseif yaw_input > 0.08 then
        return SIDE_RIGHT
    elseif yaw_input < -0.08 then
        return SIDE_LEFT
    elseif beta > 0.30 then
        return SIDE_RIGHT
    elseif beta < -0.30 then
        return SIDE_LEFT
    elseif roll_input > 0.08 then
        return SIDE_RIGHT
    elseif roll_input < -0.08 then
        return SIDE_LEFT
    end

    local selected = next_neutral_side
    next_neutral_side = -next_neutral_side
    return selected
end


local function startEntry(beta, yaw_input, p_rate, roll_input)
    weak_side = chooseWeakSide(beta, yaw_input, p_rate, roll_input)
    state = STATE_ENTRY
    event_age = 0
    entry_timer = 0
    recovery_age = 0
    release_timer = 0
    exit_reason = 0
    output_blend = 1
    resume_start_blend = 1
    resume_age = REENTRY_BLEND_TIME
end
local function startRecovery(reason)
    state = STATE_RECOVERY
    recovery_age = 0
    release_timer = 0
    exit_reason = reason
    recovery_start_blend = output_blend
end
local function timeProgress(element)
    local starts = element.side == weak_side and WEAK_BAND_START or OTHER_BAND_START
    local delay = starts[element.band]
        + BAND_SPREAD_TIME[element.band] * element.order / 7
    return smoothstepRange(delay, delay + ELEMENT_RAMP_TIME, event_age)
end

local function applyOutputs(alpha, trip_alpha, p_rate, q_rate, r_rate,
        tas, pressure, mass, grav, elevator, native_m, fade)
    local developed = smoothstepRange(0.35, DEVELOPED_TIME, event_age)
    local deep_spin = developed * smoothstepRange(trip_alpha + 0.70, trip_alpha + 4.00, alpha)
    local sine = math.sin(math.rad(alpha))
    local cosine = math.cos(math.rad(alpha))
    local rate_speed = math.max(tas, 25.0)
    local normal_force, axial_force, roll_moment, yaw_moment = 0, 0, 0, 0
    local separated_area = 0

    for _, element in ipairs(elements) do
        local weak = element.side == weak_side
        local entry = weak and ENTRY_WEAK[element.band] or ENTRY_OTHER[element.band]
        local spin = weak and SPIN_WEAK[element.band] or SPIN_OTHER[element.band]
        local lateral = element.side * element.arm
        -- Positive P lowers the right wing, increasing its local AoA.
        -- Bound this approximation at extreme rates; it is not a native lookup.
        local roll_alpha = clamp(math.deg(math.atan(math.rad(p_rate) * lateral / rate_speed)), -8, 8)
        local local_alpha = alpha + roll_alpha
        local onset = smoothstepRange(trip_alpha - 0.20, trip_alpha + 0.80, local_alpha)
        local held = smoothstepRange(RECOVERY_ALPHA, trip_alpha + 0.20, local_alpha)
        local separation = timeProgress(element) * mix(onset, held, developed)
        local cl_value = mix(entry.cl, spin.cl, deep_spin) * separation
        local cd_value = mix(entry.cd, spin.cd, deep_spin) * separation
        local normal = pressure * element.area * (cl_value * cosine + cd_value * sine)
        local axial = pressure * element.area * (-cl_value * sine + cd_value * cosine)
        normal_force = normal_force + normal
        axial_force = axial_force + axial
        roll_moment = roll_moment - normal * lateral
        yaw_moment = yaw_moment + axial * lateral
        separated_area = separated_area + element.area * separation
    end

    local separation = clamp01(separated_area / virtual_area)
    local weight = mass * grav
    local force_scale = 1
    if math.abs(normal_force) > 0.30 * weight then
        force_scale = math.min(force_scale, 0.30 * weight / math.abs(normal_force))
    end
    if axial_force > 0.15 * weight then
        force_scale = math.min(force_scale, 0.15 * weight / axial_force)
    end
    normal_force = normal_force * force_scale
    axial_force = axial_force * force_scale
    roll_moment = roll_moment * force_scale
    yaw_moment = yaw_moment * force_scale

    -- Retain damping, but do not let it erase the asymmetric break at low rates.
    -- It vanishes with separation and increases again at extreme rotation rates.
    local damping = separation * developed
    local p_hat = math.rad(p_rate) * WING_SPAN / (2 * rate_speed)
    local r_hat = math.rad(r_rate) * WING_SPAN / (2 * rate_speed)
    local p_damping = ROLL_DAMPING_COEFFICIENT + 0.12 * smoothstepRange(20, 60, math.abs(p_rate))
    local r_damping = YAW_DAMPING_COEFFICIENT + 0.15 * smoothstepRange(10, 40, math.abs(r_rate))
    roll_moment = clamp(roll_moment - pressure * WING_REFERENCE_AREA * WING_SPAN
        * p_damping * p_hat * damping, -MAX_ROLL_MOMENT, MAX_ROLL_MOMENT)
    yaw_moment = clamp(yaw_moment - pressure * WING_REFERENCE_AREA * WING_SPAN
        * r_damping * r_hat * damping, -MAX_YAW_MOMENT, MAX_YAW_MOMENT)

    -- Feed-forward attenuation of native NOSE-DOWN balance, never M_total.
    -- Limiting by the current negative value preserves at least 20% of it.
    -- Relief of the physical elevator removes this aid even if the wing is
    -- still separated. It does not trigger artificial reattachment.
    local alpha_blend = smoothstepRange(trip_alpha - 0.30, trip_alpha + 3.70, alpha)
    local elevator_blend = smoothstepRange(8.0, 22.0, -elevator)
    local negative_native = math.max(0, -native_m)
    local pitch_request = PITCH_COMPENSATION_FRACTION
        * math.min(filtered_nose_down, negative_native)
        * alpha_blend * elevator_blend * separation
    local pitch_limit = math.min(MAX_PITCH_MOMENT,
        pressure * WING_REFERENCE_AREA * WING_MOMENT_CHORD * MAX_PITCH_CM)
    local pitch_moment = math.min(pitch_request, pitch_limit)

    normal_force = normal_force * fade
    axial_force = axial_force * fade
    roll_moment = roll_moment * fade
    pitch_moment = pitch_moment * fade
    yaw_moment = yaw_moment * fade

    -- Apply the entire vector only when all shared accumulators are valid.
    local base_n, base_a = get(normal_plugin), get(axial_plugin)
    local base_l, base_m, base_r = get(roll_plugin), get(pitch_plugin), get(yaw_plugin)
    if not (finite(base_n) and finite(base_a) and finite(base_l)
        and finite(base_m) and finite(base_r)) then
        resetState(4)
        return
    end
    set(normal_plugin, base_n + normal_force)
    set(axial_plugin, base_a + axial_force)
    set(roll_plugin, base_l + roll_moment)
    set(pitch_plugin, base_m + pitch_moment)
    set(yaw_plugin, base_r + yaw_moment)
    set(diag_normal, normal_force)
    set(diag_axial, axial_force)
    set(diag_roll, roll_moment)
    set(diag_pitch, pitch_moment)
    set(diag_yaw, yaw_moment)
    set(diag_separation, separation * fade)
    publishState()
end

function update()
    local dt = get(frame_time)
    local grounded, pause_value, replay_value = get(on_ground), get(paused), get(in_replay)
    local master = get(smartcopilot_master)
    if not (finite(dt) and finite(grounded) and finite(pause_value)
        and finite(replay_value) and finite(master)) or dt <= 0 or dt > 0.20 then
        resetState(4)
        return
    end
    if grounded ~= 0 then resetState(1); return end
    if pause_value ~= 0 or replay_value ~= 0 then resetState(2); return end
    if master == 1 then resetState(3); return end

    local alpha, beta, mach = get(alpha_deg), get(beta_deg), get(mach_no)
    local p_rate, q_rate, r_rate = get(roll_rate), get(pitch_rate), get(yaw_rate)
    local tas, rho = get(true_airspeed), get(air_density)
    local mass, grav = get(total_mass), get(gravity)
    local left_elevator, right_elevator = get(elevator_left), get(elevator_right)
    local native_m = get(native_pitch_moment)
    local roll_input, yaw_input = get(raw_roll), get(raw_yaw)
    local clean = cleanConfiguration()
    if not (finite(alpha) and finite(beta) and finite(mach) and finite(p_rate)
        and finite(q_rate) and finite(r_rate) and finite(tas) and finite(rho)
        and finite(mass) and finite(grav) and finite(left_elevator)
        and finite(right_elevator) and finite(native_m)
        and finite(roll_input) and finite(yaw_input)) or clean == nil
        or tas < 0 or tas > 2000 or rho < 0 or rho > 10
        or mass < 1000 or mass > 1000000 or grav <= 0 or grav > 30
        or math.abs(alpha) > 180 or math.abs(beta) > 180
        or math.abs(p_rate) > 2000 or math.abs(q_rate) > 2000 or math.abs(r_rate) > 2000
        or math.abs(left_elevator) > 90 or math.abs(right_elevator) > 90 then
        resetState(4)
        return
    end
    local elevator = 0.5 * (left_elevator + right_elevator)
    local trip_alpha = entryTripAlpha(mach)
    local pressure = math.min(DYNAMIC_PRESSURE_MAX, 0.5 * rho * tas * tas)
    local envelope = clean and mach >= ENTRY_MACH_MIN and mach <= ENTRY_MACH_MAX
    local negative_native = math.max(0, -native_m)
    if not pitch_filter_ready then
        filtered_nose_down = negative_native
        pitch_filter_ready = true
    else
        local gain = 1 - math.exp(-dt / NATIVE_PITCH_FILTER_TIME)
        filtered_nose_down = filtered_nose_down + gain * (negative_native - filtered_nose_down)
    end
    set(diag_reset_reason, 0)
    set(diag_alpha_entry, trip_alpha)
    set(diag_elevator, elevator)
    local yoke = get(raw_pitch)
    set(diag_yoke, finite(yoke) and yoke or 0)
    set(diag_pressure, pressure)
    set(diag_native_pitch, native_m)
    publishZeroForces()

    if state == STATE_NORMAL then
        local entry = envelope and pressure > 1 and alpha >= trip_alpha
            and (elevator <= ENTRY_ELEVATOR_MAX
                or alpha >= trip_alpha + UNCOMMANDED_ALPHA_MARGIN)
        if entry then entry_timer = entry_timer + dt else entry_timer = 0 end
        if entry_timer + 1e-9 >= ENTRY_CONFIRM_TIME then
            startEntry(beta, yaw_input, p_rate, roll_input)
        end
        publishState()
        return
    end

    if state == STATE_RECOVERY then
        if envelope and alpha >= trip_alpha and pressure > 1 then
            state = event_age >= DEVELOPED_TIME and STATE_DEVELOPED or STATE_ENTRY
            resume_start_blend = output_blend
            resume_age = 0
            recovery_age = 0
            release_timer = 0
            exit_reason = 0
        else
            recovery_age = recovery_age + dt
            if recovery_age + 1e-9 >= RECOVERY_FADE_TIME then
                resetState(0)
                return
            end
            output_blend = recovery_start_blend
                * (1 - smoothstep01(recovery_age / RECOVERY_FADE_TIME))
            applyOutputs(alpha, trip_alpha, p_rate, q_rate, r_rate,
                tas, pressure, mass, grav, elevator, native_m, output_blend)
            return
        end
    end

    event_age = event_age + dt
    resume_age = math.min(REENTRY_BLEND_TIME, resume_age + dt)
    output_blend = mix(resume_start_blend, 1,
        smoothstep01(resume_age / REENTRY_BLEND_TIME))
    if not envelope then
        startRecovery(2)
    else
        if alpha < RECOVERY_ALPHA then
            release_timer = release_timer + dt
        else
            release_timer = 0
        end
        if release_timer + 1e-9 >= RECOVERY_CONFIRM_TIME then
            startRecovery(1)
        elseif event_age >= DEVELOPED_TIME then
            state = STATE_DEVELOPED
        end
    end
    applyOutputs(alpha, trip_alpha, p_rate, q_rate, r_rate,
        tas, pressure, mass, grav, elevator, native_m, output_blend)
end

function onModuleInit() resetState(0) end
function onAirportLoaded() resetState(0) end
function onPlaneLoaded() resetState(0) end
function onPlaneUnloaded() resetState(0) end
function onModuleShutdown(is_error) resetState(0) end
function onModuleDone()
    resetState(0)
    print("XP12 asymmetric stall supplement v4.4.0 released")
end
