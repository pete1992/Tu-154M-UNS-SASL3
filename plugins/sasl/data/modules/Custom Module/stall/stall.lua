-- stall.lua
-- Tu-154M: flow-driven asymmetric stall supplement for X-Plane 12 / SASL 3.
-- Version 4.5.0-XP12.

--[[ Changelog
2026-10-02 | 4.5.0-XP12
    - Extend the clean-configuration envelope from M 0.70 to M 0.83.
    - M <= 0.70: thresholds, coefficients and outputs numerically unchanged.
    - Above M 0.70: separation CL from the Korn drag-divergence relation,
      converted to alpha with a DATCOM swept-wing lift slope.
    - Recovery alpha defined as CL fraction (0.50 -> 0.75 with Mach).
    - Alpha widths, uncommanded margin and elevator gate scale with the
      available alpha span (alpha_trip - alpha_0).
    - dCL/dCD increments scale with CL_trip / CL_ref; Lock-law wave drag
      is added only beyond the separation boundary.
    - High-Mach spanwise sequence: mid/outboard first, reduced asymmetry,
      reduced autorotation share.
    - Sweep pitch-up moment from the virtual elements' lift loss.
    - T-tail compensation referenced to absolute alpha above M 0.70.
    - Dynamic pressure cap blends to the n = 2.5 separation pressure.
    - New diagnostics; header text aligned with code (5.0 deg, 90 %).

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
    Empirical simulator tuning; coefficients are not measured real-Tu-154
    post-stall derivatives. Forces/moments are additive only; no rates,
    attitudes, native coefficients, deflections or overrides are written.

    Clean flap/slat/gear configuration, Mach 0.10..0.83.

    M 0.10..0.70 (calibrated range, unchanged):
        Entry: alpha >= threshold with elevator <= -18 deg for 0.20 s,
        OR alpha >= threshold + 1.25 deg. Threshold 12.3..11.5 deg.
        Recovery: alpha < 5.0 deg continuously for 0.40 s.

    M 0.70..0.83 (compressible extension, engineering estimate):
        h        = smoothstep(0.70, 0.83, M)
        CLa(M)   = 2 pi A / (2 + sqrt(4 + A^2/eta^2 (1 - M^2 + tan^2 Lc2)))
        CL_sep   = 10 cos^3 L * (kA / cos L - (t/c) / cos^2 L - M)  (Korn)
        CL_trip  = max(0.35, min(CL_ref, CL_sep))
        a_trip   = a0 + CL_trip / CLa(M)
        a_rec    = a0 + f(h) * (a_trip - a0),  f = 0.50 .. 0.75
        dCD_wave = 20 [(M - Mcrit(CL_local))^4 - (M - Mcrit(CL_trip))^4]+
        dM_wing  = -sum(N_i * (y_i - y_centroid) * tan L)  (nose-up > 0)
        q_cap    = mix(3600, max(3600, n W / (S CL_trip)), h), n = 2.5
        a0, kA and t/c are assumptions: calibrate against the native model.

    Pitch compensation (T-tail balance correction) removes at most 90 % of
    the CURRENT negative native M_aero, bounded by q*S*c*0.23 and 900 kNm.
    Above M 0.70 its alpha reference is absolute (11.5 deg), not a_trip.
    Native M_aero excludes plugin contributions; never substitute M_total
    or M_plug_acf here (that would create feedback).

Diagnostics: tu154/custom/stall_xp12/
    state: 0 normal, 1 entry, 2 developed separation, 3 recovery
    side: -1 left, +1 right, 0 inactive; NOT a measured native stall flag
    alpha_entry_deg, elevator_deg, yoke_pitch, dynamic_pressure_Pa
    separation, force_blend, normal_N, axial_N, roll_Nm, pitch_Nm, yaw_Nm
    native_pitch_Nm, entry_elapsed_s, recovery_elapsed_s, release_elapsed_s
    exit_reason: 0 none, 1 low alpha, 2 configuration/Mach
    reset_reason: 0 none, 1 ground, 2 pause/replay, 3 slave, 4 invalid input
    high_mach_blend, cl_separation, recovery_alpha_deg, elevator_gate_deg,
    pressure_cap_Pa, wing_pitch_Nm (part of pitch_Nm), wave_cd

References
    https://developer.x-plane.com/article/movingtheplane/
    https://1-sim.com/files/SASL3Manual.pdf
]]

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
    {"diag_mach_blend", "tu154/custom/stall_xp12/high_mach_blend", diagnosticFloat},
    {"diag_cl_trip", "tu154/custom/stall_xp12/cl_separation", diagnosticFloat},
    {"diag_recovery_alpha", "tu154/custom/stall_xp12/recovery_alpha_deg", diagnosticFloat},
    {"diag_elevator_gate", "tu154/custom/stall_xp12/elevator_gate_deg", diagnosticFloat},
    {"diag_pressure_cap", "tu154/custom/stall_xp12/pressure_cap_Pa", diagnosticFloat},
    {"diag_wing_pitch", "tu154/custom/stall_xp12/wing_pitch_Nm", diagnosticFloat},
    {"diag_wave_cd", "tu154/custom/stall_xp12/wave_cd", diagnosticFloat},
})

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local STATE_NORMAL = 0
local STATE_ENTRY = 1
local STATE_DEVELOPED = 2
local STATE_RECOVERY = 3
local SIDE_LEFT = -1
local SIDE_RIGHT = 1

local ENTRY_MACH_MIN = 0.10
local LOW_MACH_LIMIT = 0.70         -- end of the 4.4.0 calibrated range
local ENTRY_MACH_MAX = 0.83         -- end of the compressible extension
local ENTRY_ELEVATOR_MAX = -18.0
local ELEVATOR_GATE_LIMIT = -8.0    -- gate never less nose-up than this
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
-- Compressible extension. Values marked (A) are assumptions to calibrate.
local LOW_TRIP_REFERENCE = 11.50    -- low-Mach trip alpha at M 0.70
local ALPHA_ZERO_LIFT = -1.50       -- (A) body-axis zero-lift alpha, clean
local WING_SWEEP_QUARTER_DEG = 35.0 -- quarter-chord sweep
local WING_SWEEP_HALF_DEG = 32.0    -- (A) half-chord sweep
local THICKNESS_RATIO = 0.11        -- (A) mean t/c
local KORN_KAPPA = 0.90             -- (A) Korn technology factor
local SPAN_EFFICIENCY_ETA = 0.95    -- DATCOM section lift-slope ratio
local LOCK_COEFFICIENT = 20.0       -- Lock wave-drag law
local WAVE_EXCESS_MAX = 0.20        -- bound Lock law outside its validity
local CL_TRIP_FLOOR = 0.35
local HIGH_MACH_RECOVERY_FRACTION = 0.75
local HIGH_MACH_SYMMETRY = 0.35     -- other wing approaches weak wing
local HIGH_MACH_SPIN_FACTOR = 0.50  -- reduced autorotation share at M 0.83
local LOAD_FACTOR_LIMIT = 2.5       -- q-cap: separation at n = 2.5
local WING_PITCH_GAIN = 1.0
local CG_AFT_OF_REFERENCE = 0.0     -- (A) m, CG aft of area-centroid c/4

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- Compressible aerodynamics
-------------------------------------------------------------------------------
local ASPECT_RATIO = WING_SPAN * WING_SPAN / WING_REFERENCE_AREA
local COS_SWEEP = math.cos(math.rad(WING_SWEEP_QUARTER_DEG))
local TAN_SWEEP = math.tan(math.rad(WING_SWEEP_QUARTER_DEG))
local TAN_HALF_SQ = math.tan(math.rad(WING_SWEEP_HALF_DEG)) ^ 2
local KORN_MDD_ZERO = KORN_KAPPA / COS_SWEEP
    - THICKNESS_RATIO / (COS_SWEEP * COS_SWEEP)
local KORN_CL_GAIN = 10 * COS_SWEEP ^ 3
local LOCK_OFFSET = (0.1 / 80) ^ (1 / 3)

-- DATCOM/Helmbold swept-wing lift slope, 1/rad (Prandtl-Glauert inside).
local function liftSlope(mach)
    local m = clamp(mach, 0, 0.90)
    local a = ASPECT_RATIO
    local root = 4 + a * a / (SPAN_EFFICIENCY_ETA * SPAN_EFFICIENCY_ETA)
        * (1 - m * m + TAN_HALF_SQ)
    return 2 * math.pi * a / (2 + math.sqrt(root))
end

-- Korn: CL at which the current Mach equals drag-divergence Mach.
local function kornSeparationCl(mach)
    return KORN_CL_GAIN * (KORN_MDD_ZERO - mach)
end

local function kornDivergenceMach(cl)
    return KORN_MDD_ZERO - cl / KORN_CL_GAIN
end

local function lockWaveDrag(mach, cl)
    local m_crit = kornDivergenceMach(cl) - LOCK_OFFSET
    local excess = clamp(mach - m_crit, 0, WAVE_EXCESS_MAX)
    return LOCK_COEFFICIENT * excess ^ 4
end

local function lowMachTripAlpha(mach)
    return 12.30 - 0.80 * smoothstepRange(0.25, 0.50, mach)
end

local REFERENCE_ALPHA_SPAN = LOW_TRIP_REFERENCE - ALPHA_ZERO_LIFT
local CL_REFERENCE = liftSlope(LOW_MACH_LIMIT) * math.rad(REFERENCE_ALPHA_SPAN)
local RECOVERY_CL_FRACTION = (RECOVERY_ALPHA - ALPHA_ZERO_LIFT)
    / REFERENCE_ALPHA_SPAN

-- Per-frame Mach regime; reused table (no per-frame allocation).
local regime = {}

local function updateRegime(mach, weight)
    local m = clamp(mach, 0, ENTRY_MACH_MAX)
    local high = smoothstepRange(LOW_MACH_LIMIT, ENTRY_MACH_MAX, m)
    local slope = liftSlope(m)
    regime.mach = m
    regime.high = high
    regime.slope = slope

    if m <= LOW_MACH_LIMIT then
        local trip = lowMachTripAlpha(m)
        regime.trip = trip
        regime.recovery = RECOVERY_ALPHA
        regime.alpha_scale = 1
        regime.cl_trip = slope * math.rad(trip - ALPHA_ZERO_LIFT)
        regime.cl_scale = 1
        regime.elevator_gate = ENTRY_ELEVATOR_MAX
        regime.pressure_cap = DYNAMIC_PRESSURE_MAX
        return
    end

    local cl_trip = math.max(CL_TRIP_FLOOR,
        math.min(CL_REFERENCE, kornSeparationCl(m)))
    local span = math.deg(cl_trip / slope)
    local scale = clamp(span / REFERENCE_ALPHA_SPAN, 0.30, 1.0)
    local fraction = mix(RECOVERY_CL_FRACTION, HIGH_MACH_RECOVERY_FRACTION, high)
    regime.trip = ALPHA_ZERO_LIFT + span
    regime.recovery = ALPHA_ZERO_LIFT + fraction * span
    regime.alpha_scale = scale
    regime.cl_trip = cl_trip
    regime.cl_scale = cl_trip / CL_REFERENCE
    regime.elevator_gate = math.min(ELEVATOR_GATE_LIMIT,
        ENTRY_ELEVATOR_MAX * mix(1, scale, high))
    local q_load = LOAD_FACTOR_LIMIT * weight / (WING_REFERENCE_AREA * cl_trip)
    regime.pressure_cap = mix(DYNAMIC_PRESSURE_MAX,
        math.max(DYNAMIC_PRESSURE_MAX, q_load), high)
end
updateRegime(0, 0)

-------------------------------------------------------------------------------
-- Element tables
-------------------------------------------------------------------------------
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

-- Low Mach: inboard first. High Mach: shock-induced, mid/outboard first.
local WEAK_BAND_START = {[1] = 0.00, [2] = 0.18, [3] = 0.40}
local OTHER_BAND_START = {[1] = 0.10, [2] = 0.35, [3] = 0.62}
local WEAK_BAND_START_HIGH = {[1] = 0.30, [2] = 0.00, [3] = 0.08}
local OTHER_BAND_START_HIGH = {[1] = 0.40, [2] = 0.10, [3] = 0.18}
local BAND_SPREAD_TIME = {[1] = 0.20, [2] = 0.30, [3] = 0.38}
local ELEMENT_RAMP_TIME = 0.10

local elements = {}
local virtual_area = 0
local side_area, side_moment = 0, 0
for band = 1, 3 do
    for order = 0, 7 do
        for _, side in ipairs({SIDE_LEFT, SIDE_RIGHT}) do
            local slot = order + 1
            local area, arm = BAND_AREA[band][slot], BAND_ARM[band][slot]
            elements[#elements + 1] = {
                side = side, band = band, order = order,
                area = area, arm = arm, x_aft = 0,
            }
            virtual_area = virtual_area + area
            if side == SIDE_RIGHT then
                side_area = side_area + area
                side_moment = side_moment + area * arm
            end
        end
    end
end

-- Longitudinal arm of each element's c/4 point behind the area centroid.
local AREA_CENTROID_ARM = side_moment / side_area   -- approx. 8.11 m
for _, element in ipairs(elements) do
    element.x_aft = (element.arm - AREA_CENTROID_ARM) * TAN_SWEEP
        - CG_AFT_OF_REFERENCE
end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------
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
    set(diag_wing_pitch, 0)
    set(diag_wave_cd, 0)
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

local function publishRegime()
    set(diag_mach_blend, regime.high)
    set(diag_cl_trip, regime.cl_trip)
    set(diag_recovery_alpha, regime.recovery)
    set(diag_elevator_gate, regime.elevator_gate)
    set(diag_pressure_cap, regime.pressure_cap)
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
    set(diag_mach_blend, 0)
    set(diag_cl_trip, 0)
    set(diag_recovery_alpha, 0)
    set(diag_elevator_gate, 0)
    set(diag_pressure_cap, 0)
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

local function timeProgress(element, high)
    local weak = element.side == weak_side
    local low_start = weak and WEAK_BAND_START or OTHER_BAND_START
    local high_start = weak and WEAK_BAND_START_HIGH or OTHER_BAND_START_HIGH
    local band = element.band
    local delay = mix(low_start[band], high_start[band], high)
        + BAND_SPREAD_TIME[band] * element.order / 7
    return smoothstepRange(delay, delay + ELEMENT_RAMP_TIME, event_age)
end

-------------------------------------------------------------------------------
-- Force/moment computation
-------------------------------------------------------------------------------
local function applyOutputs(alpha, p_rate, r_rate, tas, pressure,
        mass, grav, elevator, native_m, fade)
    local trip_alpha = regime.trip
    local s = regime.alpha_scale
    local high = regime.high
    local cl_scale = regime.cl_scale
    local developed = smoothstepRange(0.35, DEVELOPED_TIME, event_age)
    local deep_spin = developed
        * smoothstepRange(trip_alpha + 0.70 * s, trip_alpha + 4.00 * s, alpha)
        * mix(1, HIGH_MACH_SPIN_FACTOR, high)
    local symmetry = HIGH_MACH_SYMMETRY * high
    local wave_reference = 0
    if high > 0 then
        wave_reference = lockWaveDrag(regime.mach, regime.cl_trip)
    end
    local sine = math.sin(math.rad(alpha))
    local cosine = math.cos(math.rad(alpha))
    local rate_speed = math.max(tas, 25.0)
    local normal_force, axial_force, roll_moment, yaw_moment = 0, 0, 0, 0
    local wing_pitch = 0
    local separated_area = 0
    local wave_area = 0

    for _, element in ipairs(elements) do
        local band = element.band
        local ew, sw = ENTRY_WEAK[band], SPIN_WEAK[band]
        local entry_cl, entry_cd, spin_cl, spin_cd
        if element.side == weak_side then
            entry_cl, entry_cd = ew.cl, ew.cd
            spin_cl, spin_cd = sw.cl, sw.cd
        else
            local eo, so = ENTRY_OTHER[band], SPIN_OTHER[band]
            entry_cl = mix(eo.cl, ew.cl, symmetry)
            entry_cd = mix(eo.cd, ew.cd, symmetry)
            spin_cl = mix(so.cl, sw.cl, symmetry)
            spin_cd = mix(so.cd, sw.cd, symmetry)
        end

        local lateral = element.side * element.arm
        -- Positive P lowers the right wing, increasing its local AoA.
        local roll_alpha = clamp(math.deg(math.atan(
            math.rad(p_rate) * lateral / rate_speed)), -8, 8)
        local local_alpha = alpha + roll_alpha
        local onset = smoothstepRange(trip_alpha - 0.20 * s,
            trip_alpha + 0.80 * s, local_alpha)
        local held = smoothstepRange(regime.recovery,
            trip_alpha + 0.20 * s, local_alpha)
        local separation = timeProgress(element, high)
            * mix(onset, held, developed)

        -- Extra wave drag beyond the separation boundary only.
        local wave_cd = 0
        if high > 0 then
            local local_cl = regime.slope
                * math.rad(local_alpha - ALPHA_ZERO_LIFT)
            wave_cd = high * math.max(0,
                lockWaveDrag(regime.mach, local_cl) - wave_reference)
        end

        local cl_value = mix(entry_cl, spin_cl, deep_spin) * cl_scale * separation
        local cd_value = (mix(entry_cd, spin_cd, deep_spin) * cl_scale + wave_cd)
            * separation
        local normal = pressure * element.area * (cl_value * cosine + cd_value * sine)
        local axial = pressure * element.area * (-cl_value * sine + cd_value * cosine)
        normal_force = normal_force + normal
        axial_force = axial_force + axial
        roll_moment = roll_moment - normal * lateral
        yaw_moment = yaw_moment + axial * lateral
        -- Lift loss aft of the reference gives nose-up (positive) moment.
        wing_pitch = wing_pitch - normal * element.x_aft
        separated_area = separated_area + element.area * separation
        wave_area = wave_area + element.area * wave_cd * separation
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
    -- Sweep pitch-up is a compressible-range term only (h = 0 at M <= 0.70).
    wing_pitch = wing_pitch * force_scale * high * WING_PITCH_GAIN

    local damping = separation * developed
    local p_hat = math.rad(p_rate) * WING_SPAN / (2 * rate_speed)
    local r_hat = math.rad(r_rate) * WING_SPAN / (2 * rate_speed)
    local p_damping = ROLL_DAMPING_COEFFICIENT
        + 0.12 * smoothstepRange(20, 60, math.abs(p_rate))
    local r_damping = YAW_DAMPING_COEFFICIENT
        + 0.15 * smoothstepRange(10, 40, math.abs(r_rate))
    roll_moment = clamp(roll_moment - pressure * WING_REFERENCE_AREA * WING_SPAN
        * p_damping * p_hat * damping, -MAX_ROLL_MOMENT, MAX_ROLL_MOMENT)
    yaw_moment = clamp(yaw_moment - pressure * WING_REFERENCE_AREA * WING_SPAN
        * r_damping * r_hat * damping, -MAX_YAW_MOMENT, MAX_YAW_MOMENT)

    -- T-tail balance correction: attenuation of native NOSE-DOWN moment.
    -- Wake immersion is geometric, so above M 0.70 the reference is absolute.
    local tail_reference = math.max(trip_alpha, LOW_TRIP_REFERENCE)
    local alpha_blend = smoothstepRange(tail_reference - 0.30,
        tail_reference + 3.70, alpha)
    local elevator_blend = smoothstepRange(8.0, 22.0, -elevator)
    local negative_native = math.max(0, -native_m)
    local pitch_request = PITCH_COMPENSATION_FRACTION
        * math.min(filtered_nose_down, negative_native)
        * alpha_blend * elevator_blend * separation
    local pitch_limit = math.min(MAX_PITCH_MOMENT,
        pressure * WING_REFERENCE_AREA * WING_MOMENT_CHORD * MAX_PITCH_CM)
    local tail_pitch = math.min(pitch_request, pitch_limit)
    local pitch_moment = clamp(tail_pitch + wing_pitch,
        -MAX_PITCH_MOMENT, MAX_PITCH_MOMENT)

    normal_force = normal_force * fade
    axial_force = axial_force * fade
    roll_moment = roll_moment * fade
    pitch_moment = pitch_moment * fade
    yaw_moment = yaw_moment * fade

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
    set(diag_wing_pitch, wing_pitch * fade)
    set(diag_wave_cd, wave_area / virtual_area * fade)
    set(diag_separation, separation * fade)
    publishState()
end

-------------------------------------------------------------------------------
-- Update
-------------------------------------------------------------------------------
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
        or tas < 0 or tas > 2000 or rho < 0 or rho > 10 or mach < 0
        or mass < 1000 or mass > 1000000 or grav <= 0 or grav > 30
        or math.abs(alpha) > 180 or math.abs(beta) > 180
        or math.abs(p_rate) > 2000 or math.abs(q_rate) > 2000
        or math.abs(r_rate) > 2000
        or math.abs(left_elevator) > 90 or math.abs(right_elevator) > 90 then
        resetState(4)
        return
    end

    local elevator = 0.5 * (left_elevator + right_elevator)
    updateRegime(mach, mass * grav)
    local trip_alpha = regime.trip
    local pressure = math.min(regime.pressure_cap, 0.5 * rho * tas * tas)
    local envelope = clean and mach >= ENTRY_MACH_MIN and mach <= ENTRY_MACH_MAX

    local negative_native = math.max(0, -native_m)
    if not pitch_filter_ready then
        filtered_nose_down = negative_native
        pitch_filter_ready = true
    else
        local gain = 1 - math.exp(-dt / NATIVE_PITCH_FILTER_TIME)
        filtered_nose_down = filtered_nose_down
            + gain * (negative_native - filtered_nose_down)
    end

    set(diag_reset_reason, 0)
    set(diag_alpha_entry, trip_alpha)
    set(diag_elevator, elevator)
    local yoke = get(raw_pitch)
    set(diag_yoke, finite(yoke) and yoke or 0)
    set(diag_pressure, pressure)
    set(diag_native_pitch, native_m)
    publishRegime()
    publishZeroForces()

    if state == STATE_NORMAL then
        local entry = envelope and pressure > 1 and alpha >= trip_alpha
            and (elevator <= regime.elevator_gate
                or alpha >= trip_alpha
                    + UNCOMMANDED_ALPHA_MARGIN * regime.alpha_scale)
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
            applyOutputs(alpha, p_rate, r_rate, tas, pressure,
                mass, grav, elevator, native_m, output_blend)
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
        if alpha < regime.recovery then
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
    applyOutputs(alpha, p_rate, r_rate, tas, pressure,
        mass, grav, elevator, native_m, output_blend)
end

function onModuleInit() resetState(0) end
function onAirportLoaded() resetState(0) end
function onPlaneLoaded() resetState(0) end
function onPlaneUnloaded() resetState(0) end
function onModuleShutdown(is_error) resetState(0) end
function onModuleDone()
    resetState(0)
    print("XP12 asymmetric stall supplement v4.5.0 released")
end