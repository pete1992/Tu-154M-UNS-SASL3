-- Tu-154M v4.3.1 aggressive asymmetric stall / flat-spin entry for XP11.55.
--
-- The user's XP11.55 DataRefs.txt does not contain X-Plane 12.1's per-element
-- element_cl/cd/cm_addition properties. This component therefore reconstructs
-- the dump-calibrated left/right wing losses with the XP10.30+ additive plugin
-- forces and moments that are explicitly present and writable in XP11.55.
--
-- It is dormant in attached flight and in a slowly approached coordinated
-- stall. A rapid near-full-aft pull latches the first weak wing for the entire
-- event, so the natural 3-4 second left/right wing-rock cannot swap the break.

defineProperty("alpha_deg", globalPropertyf("sim/flightmodel2/misc/AoA_angle_degrees"))
defineProperty("beta_deg", globalPropertyf("sim/flightmodel/position/beta"))
defineProperty("mach_no", globalPropertyf("sim/flightmodel/misc/machno"))
defineProperty("roll_rate", globalPropertyf("sim/flightmodel/position/P"))
defineProperty("pitch_rate", globalPropertyf("sim/flightmodel/position/Q"))
defineProperty("yaw_rate", globalPropertyf("sim/flightmodel/position/R"))
defineProperty("true_airspeed", globalPropertyf("sim/flightmodel/position/true_airspeed"))
defineProperty("air_density", globalPropertyf("sim/weather/rho"))
defineProperty("total_mass", globalPropertyf("sim/flightmodel/weight/m_total"))
defineProperty("gravity", globalPropertyf("sim/weather/gravity_mss"))

defineProperty("raw_pitch", globalPropertyf("tu154/custom/SC/yoke_pitch_ratio"))
defineProperty("raw_roll", globalPropertyf("tu154/custom/SC/yoke_roll_ratio"))
defineProperty("raw_yaw", globalPropertyf("tu154/custom/SC/yoke_heading_ratio"))
defineProperty("frame_time", globalPropertyf("tu154/custom/time/frame_time"))

defineProperty("flap_inner_left", globalPropertyf("sim/flightmodel/controls/wing1l_fla1def"))
defineProperty("flap_inner_right", globalPropertyf("sim/flightmodel/controls/wing1r_fla1def"))
defineProperty("flap_middle_left", globalPropertyf("sim/flightmodel/controls/wing2l_fla2def"))
defineProperty("flap_middle_right", globalPropertyf("sim/flightmodel/controls/wing2r_fla2def"))
defineProperty("slat_ratio", globalPropertyf("sim/flightmodel2/controls/slat1_deploy_ratio"))
defineProperty("gear_left", globalProperty("sim/flightmodel2/gear/deploy_ratio[1]"))
defineProperty("gear_right", globalProperty("sim/flightmodel2/gear/deploy_ratio[2]"))
defineProperty("elevator_left", globalPropertyf("sim/flightmodel/controls/hstab1_elv1def"))
defineProperty("elevator_right", globalPropertyf("sim/flightmodel/controls/hstab2_elv1def"))

defineProperty("on_ground", globalPropertyi("sim/flightmodel/failures/onground_any"))
defineProperty("paused", globalPropertyi("sim/time/paused"))
defineProperty("in_replay", globalPropertyi("sim/time/is_in_replay"))
defineProperty("smartcopilot_master", globalPropertyf("scp/api/ismaster"))

-- XP11.55-safe additive force and moment inputs. X-Plane resets these every
-- physics cycle; this component reads, adds, and writes so other plugins remain
-- additive owners of their own contributions.
defineProperty("normal_plugin", globalPropertyf("sim/flightmodel/forces/fnrml_plug_acf"))
defineProperty("axial_plugin", globalPropertyf("sim/flightmodel/forces/faxil_plug_acf"))
defineProperty("roll_plugin", globalPropertyf("sim/flightmodel/forces/L_plug_acf"))
defineProperty("pitch_plugin", globalPropertyf("sim/flightmodel/forces/M_plug_acf"))
defineProperty("yaw_plugin", globalPropertyf("sim/flightmodel/forces/N_plug_acf"))

local STATE_NORMAL = 0
local STATE_ENTRY = 1
local STATE_SPIN_HOLD = 2
local STATE_RECOVERY = 3

local SIDE_LEFT = -1
local SIDE_RIGHT = 1

-- Entry envelope and aggression detector.
local ENTRY_MACH_MIN = 0.10
local ENTRY_MACH_MAX = 0.70
local ENTRY_PITCH_MIN = 0.88
local ENTRY_ELEVATOR_MAX = -20.0
local FULL_AFT_PITCH = 0.92
local FULL_AFT_CONFIRM_TIME = 0.20
local RAPID_PULL_RATE = 0.60
local RAPID_ALPHA_RATE = 1.00
local RAPID_PITCH_RATE = 1.50
local ALPHA_RATE_FILTER_GAIN = 4.00
local AGGRESSIVE_LATCH_TIME = 8.00

-- Developed-spin and recovery gates.
local SPIN_HOLD_MIN_AGE = 1.60
local SPIN_HOLD_ROLL_RATE = 8.00
local SPIN_HOLD_YAW_RATE = 2.50
local SPIN_HOLD_BETA = 4.00
local RELEASE_PITCH = 0.20
local RELEASE_CONFIRM_TIME = 0.60
local RECOVERY_ALPHA = 8.50
local RECOVERY_FADE_TIME = 2.50

-- Force/moment calibration. Dynamic pressure is calculated in SI units from
-- rho and TAS, avoiding XP11's historically ambiguous Qstatic unit label.
local DYNAMIC_PRESSURE_MAX = 3600.0
local WING_REFERENCE_AREA = 202.1870
local WING_MOMENT_CHORD = 6.4234
local WING_SPAN = 37.55
local FLAT_SPIN_CM = 0.135
local ROLL_DAMPING_COEFFICIENT = 0.25
local YAW_DAMPING_COEFFICIENT = 0.25
local MAX_ROLL_MOMENT = 600000.0
local MAX_PITCH_MOMENT = 160000.0
local MAX_YAW_MOMENT = 350000.0

local function clamp01(value)
    if value < 0 then
        return 0
    elseif value > 1 then
        return 1
    end
    return value
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function smoothstep01(value)
    value = clamp01(value)
    return value * value * (3 - 2 * value)
end

local function smoothstepRange(edge0, edge1, value)
    if edge1 <= edge0 then
        return value >= edge1 and 1 or 0
    end
    return smoothstep01((value - edge0) / (edge1 - edge0))
end

local function mix(a, b, ratio)
    return a + (b - a) * ratio
end

local function maxAbs4(a, b, c, d)
    return math.max(math.abs(a), math.abs(b), math.abs(c), math.abs(d))
end

-- ENTRY produces the first hard break. SPIN is blended in from 14 to 19 deg
-- alpha and preserves a much larger drag difference on the latched side.
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

local WEAK_BAND_START = {[1] = 0.00, [2] = 0.30, [3] = 0.75}
local OTHER_BAND_START = {[1] = 0.18, [2] = 0.65, [3] = 1.05}
local BAND_SPREAD_TIME = {[1] = 0.35, [2] = 0.50, [3] = 0.55}
local ELEMENT_RAMP_TIME = 0.12

local elements = {}
for band = 1, 3 do
    for order = 0, 7 do
        local slot = order + 1
        elements[#elements + 1] = {
            side = SIDE_LEFT,
            band = band,
            order = order,
            area = BAND_AREA[band][slot],
            arm = BAND_ARM[band][slot],
        }
        elements[#elements + 1] = {
            side = SIDE_RIGHT,
            band = band,
            order = order,
            area = BAND_AREA[band][slot],
            arm = BAND_ARM[band][slot],
        }
    end
end

local state = STATE_NORMAL
local weak_side = SIDE_RIGHT
local next_neutral_side = SIDE_RIGHT
local event_age = 0
local recovery_age = 0
local aggressive_timer = 0
local full_aft_timer = 0
local release_timer = 0
local previous_pitch = 0
local previous_alpha = 0
local filtered_alpha_rate = 0
local derivative_ready = false

local last_normal = 0
local last_axial = 0
local last_roll = 0
local last_pitch = 0
local last_yaw = 0

local function clearLastOutputs()
    last_normal = 0
    last_axial = 0
    last_roll = 0
    last_pitch = 0
    last_yaw = 0
end

local function resetState()
    state = STATE_NORMAL
    event_age = 0
    recovery_age = 0
    aggressive_timer = 0
    full_aft_timer = 0
    release_timer = 0
    filtered_alpha_rate = 0
    derivative_ready = false
    clearLastOutputs()
end

local function isCleanConfiguration()
    local flap_max = maxAbs4(
        get(flap_inner_left),
        get(flap_inner_right),
        get(flap_middle_left),
        get(flap_middle_right)
    )
    local gear_max = math.max(get(gear_left), get(gear_right))
    return flap_max < 1.0
        and get(slat_ratio) < 0.05
        and gear_max < 0.05
end

local function entryTripAlpha(mach)
    local mach_factor = smoothstepRange(0.25, 0.50, mach)
    return 12.30 - 0.80 * mach_factor
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

local function startEntry(beta, yaw_input, roll_rate_value, roll_input)
    weak_side = chooseWeakSide(beta, yaw_input, roll_rate_value, roll_input)
    state = STATE_ENTRY
    event_age = 0
    recovery_age = 0
    release_timer = 0
end

local function startRecovery()
    if state ~= STATE_RECOVERY then
        state = STATE_RECOVERY
        recovery_age = 0
        release_timer = 0
    end
end

local function elementProgress(element)
    local weak = element.side == weak_side
    local band_start = weak and WEAK_BAND_START[element.band]
        or OTHER_BAND_START[element.band]
    local spread = BAND_SPREAD_TIME[element.band]
    local delay = band_start + spread * element.order / 7
    return smoothstepRange(delay, delay + ELEMENT_RAMP_TIME, event_age)
end

local function addPluginOutputs(normal_force, axial_force, roll_moment, pitch_moment, yaw_moment)
    set(normal_plugin, get(normal_plugin) + normal_force)
    set(axial_plugin, get(axial_plugin) + axial_force)
    set(roll_plugin, get(roll_plugin) + roll_moment)
    set(pitch_plugin, get(pitch_plugin) + pitch_moment)
    set(yaw_plugin, get(yaw_plugin) + yaw_moment)
end

local function applyActiveOutputs(alpha, trip_alpha, p_rate, q_rate, r_rate)
    local tas = math.max(0, get(true_airspeed))
    local rho = math.max(0, get(air_density))
    local dynamic_pressure = math.min(DYNAMIC_PRESSURE_MAX, 0.5 * rho * tas * tas)

    local deep_spin = state == STATE_SPIN_HOLD
        and smoothstepRange(14.00, 19.00, alpha)
        or 0
    local damping_factor = state == STATE_SPIN_HOLD
        and mix(0.75, 1.00, deep_spin)
        or 0
    local alpha_factor
    if state == STATE_ENTRY then
        alpha_factor = smoothstepRange(trip_alpha - 0.20, trip_alpha + 0.80, alpha)
    else
        alpha_factor = smoothstepRange(10.00, 12.50, alpha)
    end

    local high_alpha_factor = state == STATE_SPIN_HOLD
        and smoothstepRange(15.00, 20.50, alpha)
        or 0

    local normal_force = 0
    local axial_force = 0
    local roll_moment = 0
    local yaw_moment = 0
    local alpha_rad = math.rad(alpha)
    local sin_alpha = math.sin(alpha_rad)
    local cos_alpha = math.cos(alpha_rad)

    for _, element in ipairs(elements) do
        local weak = element.side == weak_side
        local entry = weak and ENTRY_WEAK[element.band] or ENTRY_OTHER[element.band]
        local spin = weak and SPIN_WEAK[element.band] or SPIN_OTHER[element.band]
        local progression = elementProgress(element) * alpha_factor
        local cl_value = mix(entry.cl, spin.cl, deep_spin) * progression
        local cd_value = mix(entry.cd, spin.cd, deep_spin) * progression

        -- Transform the path-axis lift loss and drag increment into the XP11
        -- aircraft Y/Z axes. At positive alpha, lost lift adds aft force while
        -- the extra drag carries a small upward component.
        local element_normal = dynamic_pressure * element.area
            * (cl_value * cos_alpha + cd_value * sin_alpha)
        local element_axial = dynamic_pressure * element.area
            * ((-cl_value) * sin_alpha + cd_value * cos_alpha)
        local lateral_position = element.side * element.arm

        normal_force = normal_force + element_normal
        axial_force = axial_force + element_axial
        roll_moment = roll_moment - element_normal * lateral_position
        yaw_moment = yaw_moment + element_axial * lateral_position
    end

    -- Cap the aggregate force vector by fractions of aircraft weight and scale
    -- its associated roll/yaw moments by the same amount.
    local aircraft_weight = math.max(1, get(total_mass) * get(gravity))
    local force_scale = 1
    local normal_cap = 0.30 * aircraft_weight
    local axial_cap = 0.15 * aircraft_weight
    if math.abs(normal_force) > normal_cap then
        force_scale = math.min(force_scale, normal_cap / math.abs(normal_force))
    end
    if axial_force > axial_cap then
        force_scale = math.min(force_scale, axial_cap / axial_force)
    end
    normal_force = normal_force * force_scale
    axial_force = axial_force * force_scale
    roll_moment = roll_moment * force_scale
    yaw_moment = yaw_moment * force_scale

    -- Non-dimensional P/R damping turns the initial wing drop into a bounded,
    -- yaw-dominant developed spin instead of an ever-faster tumble.
    local rate_speed = math.max(tas, 25.0)
    local p_hat = math.rad(p_rate) * WING_SPAN / (2 * rate_speed)
    local r_hat = math.rad(r_rate) * WING_SPAN / (2 * rate_speed)
    local roll_damping = -dynamic_pressure * WING_REFERENCE_AREA * WING_SPAN
        * ROLL_DAMPING_COEFFICIENT * p_hat * damping_factor
    local yaw_damping = -dynamic_pressure * WING_REFERENCE_AREA * WING_SPAN
        * YAW_DAMPING_COEFFICIENT * r_hat * damping_factor
    roll_moment = clamp(
        roll_moment + roll_damping,
        -MAX_ROLL_MOMENT,
        MAX_ROLL_MOMENT
    )
    yaw_moment = clamp(
        yaw_moment + yaw_damping,
        -MAX_YAW_MOMENT,
        MAX_YAW_MOMENT
    )

    -- Dump-calibrated loss of the T-tail's remaining nose-down authority.
    -- Positive M is nose-up in XP11. At alpha 24 deg and q=738.7 Pa,
    -- Cm=+0.135 gives about +130 kNm against the measured -126 kNm balance.
    local pitch_available = dynamic_pressure * WING_REFERENCE_AREA
        * WING_MOMENT_CHORD * FLAT_SPIN_CM
    local upper_alpha_limit = 1 - 0.50 * smoothstepRange(30.00, 38.00, alpha)
    local nose_up_rate_limit = 1 - 0.70 * smoothstepRange(2.00, 6.00, q_rate)
    local pitch_moment = clamp(
        pitch_available * high_alpha_factor
            * upper_alpha_limit * nose_up_rate_limit,
        0,
        MAX_PITCH_MOMENT
    )

    last_normal = normal_force
    last_axial = axial_force
    last_roll = roll_moment
    last_pitch = pitch_moment
    last_yaw = yaw_moment

    addPluginOutputs(normal_force, axial_force, roll_moment, pitch_moment, yaw_moment)
end

local function applyRecoveryOutputs(dt)
    recovery_age = recovery_age + dt
    local scale = 1 - smoothstep01(recovery_age / RECOVERY_FADE_TIME)
    addPluginOutputs(
        last_normal * scale,
        last_axial * scale,
        last_roll * scale,
        last_pitch * scale,
        last_yaw * scale
    )

    if recovery_age >= RECOVERY_FADE_TIME then
        resetState()
    end
end

function update()
    local dt = get(frame_time)
    local master = get(smartcopilot_master) ~= 1

    -- Never add forces during pause/replay/ground/slave or discontinuous time.
    -- Plugin forces are reset by X-Plane; deliberately do not write zero here,
    -- because the datarefs are additive and may also be used by other plugins.
    if dt <= 0 or dt > 0.20 or get(paused) ~= 0 or get(in_replay) ~= 0
        or get(on_ground) ~= 0 or not master then
        resetState()
        return
    end

    local alpha = get(alpha_deg)
    local beta = get(beta_deg)
    local mach = get(mach_no)
    local pitch_input = get(raw_pitch)
    local roll_input = get(raw_roll)
    local yaw_input = get(raw_yaw)
    local p_rate = get(roll_rate)
    local q_rate = get(pitch_rate)
    local r_rate = get(yaw_rate)
    local clean = isCleanConfiguration()
    local mach_valid = mach >= ENTRY_MACH_MIN and mach <= ENTRY_MACH_MAX
    local elevator_deflection = 0.5 * (get(elevator_left) + get(elevator_right))
    local elevator_ready = elevator_deflection <= ENTRY_ELEVATOR_MAX

    if not derivative_ready then
        previous_pitch = pitch_input
        previous_alpha = alpha
        filtered_alpha_rate = 0
        derivative_ready = true
    end

    local pull_rate = (pitch_input - previous_pitch) / dt
    local raw_alpha_rate = (alpha - previous_alpha) / dt
    local filter_ratio = clamp01(dt * ALPHA_RATE_FILTER_GAIN)
    filtered_alpha_rate = filtered_alpha_rate
        + (raw_alpha_rate - filtered_alpha_rate) * filter_ratio
    previous_pitch = pitch_input
    previous_alpha = alpha

    if pitch_input >= 0.85 and (
        pull_rate >= RAPID_PULL_RATE
        or filtered_alpha_rate >= RAPID_ALPHA_RATE
        or q_rate >= RAPID_PITCH_RATE
    ) then
        aggressive_timer = AGGRESSIVE_LATCH_TIME
    else
        aggressive_timer = math.max(0, aggressive_timer - dt)
    end

    if pitch_input >= FULL_AFT_PITCH then
        full_aft_timer = full_aft_timer + dt
    else
        full_aft_timer = 0
    end

    if state == STATE_NORMAL then
        if clean and mach_valid and elevator_ready
            and pitch_input >= ENTRY_PITCH_MIN then
            local trip_alpha = entryTripAlpha(mach)
            local full_aft_confirmed = full_aft_timer >= FULL_AFT_CONFIRM_TIME
            local deliberate_yaw_entry = full_aft_confirmed
                and math.abs(yaw_input) >= 0.25
            if alpha >= trip_alpha
                and (aggressive_timer > 0 or deliberate_yaw_entry) then
                startEntry(beta, yaw_input, p_rate, roll_input)
            end
        end
        return
    end

    if state == STATE_RECOVERY then
        applyRecoveryOutputs(dt)
        return
    end

    if not clean or not mach_valid then
        startRecovery()
        applyRecoveryOutputs(dt)
        return
    end

    event_age = event_age + dt

    if pitch_input < RELEASE_PITCH then
        release_timer = release_timer + dt
    else
        release_timer = 0
    end

    if alpha < RECOVERY_ALPHA or release_timer >= RELEASE_CONFIRM_TIME then
        startRecovery()
        applyRecoveryOutputs(dt)
        return
    end

    if state == STATE_ENTRY and (
        event_age >= SPIN_HOLD_MIN_AGE
        or math.abs(p_rate) >= SPIN_HOLD_ROLL_RATE
        or math.abs(r_rate) >= SPIN_HOLD_YAW_RATE
        or math.abs(beta) >= SPIN_HOLD_BETA
    ) then
        state = STATE_SPIN_HOLD
    end

    applyActiveOutputs(alpha, entryTripAlpha(mach), p_rate, q_rate, r_rate)
end

function onModuleInit()
    resetState()
end

function onAirportLoaded()
    resetState()
end

function onPlaneLoaded()
    resetState()
end

function onPlaneUnloaded()
    resetState()
end

function onModuleShutdown(is_error)
    resetState()
end

function onModuleDone()
    resetState()
    print("XP11 aggressive asymmetric stall force model released")
end
