-- ============================================================================
-- DISS / NVU WIND CALCULATION LOGIC
-- Functional improvements applied:
-- A) Mode robustness: hysteresis + delay + hold-last-good
-- B) Measurement quality: absolute wind-dir filtering + exponential smoothing + validity gates
-- ============================================================================

-----------------------------------------------------------------------
-- Smartcopilot
-----------------------------------------------------------------------
-- 0 = not found, 1 = slave, 2 = master
defineProperty("ismaster",    globalPropertyf("scp/api/ismaster"))
-- 1 = no control, 2 = has control
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1"))

-- ----------------------------------------------------------------------------
-- Property binder
-- ----------------------------------------------------------------------------
local function defineProps(defs)
	for _, d in ipairs(defs) do
		defineProperty(d[1], d[3](d[2]))
	end
end

-- ----------------------------------------------------------------------------
-- Properties
-- ----------------------------------------------------------------------------
defineProps({
	-- Time / power / controls
	{ "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
	{ "diss_on", "tu154/custom/switchers/ovhd/diss_on", globalPropertyi },
	{ "diss_mode_sw", "tu154/custom/switchers/ovhd/diss_mode", globalPropertyi },
	{ "nvu_calc_set", "tu154/custom/switchers/ovhd/nvu_calc_set", globalPropertyi },
	{ "wind_set", "tu154/custom/rotary/console/wind_set", globalPropertyf },
	{ "wind_course_left", "tu154/custom/button/console/wind_course_left", globalPropertyi },
	{ "wind_course_ctr", "tu154/custom/button/console/wind_course_ctr", globalPropertyi },
	{ "wind_course_right", "tu154/custom/button/console/wind_course_right", globalPropertyi },
	{ "wind_spd_left", "tu154/custom/button/console/wind_spd_left", globalPropertyi },
	{ "wind_spd_ctr", "tu154/custom/button/console/wind_spd_ctr", globalPropertyi },
	{ "wind_spd_right", "tu154/custom/button/console/wind_spd_right", globalPropertyi },
	-- Aircraft state
	{ "deg1", "sim/flightmodel/position/psi", globalPropertyf },
	{ "deg2", "sim/flightmodel/position/hpath", globalPropertyf },
	{ "groundspeed", "sim/flightmodel/position/groundspeed", globalPropertyf },
	{ "tas_svs", "tu154/custom/svs/true_airspeed", globalPropertyf },
	{ "course_gpk", "tu154/custom/tks/course_gpk", globalPropertyf },
	{ "acf_roll", "sim/flightmodel/position/true_phi", globalPropertyf },
	{ "acf_pitch", "sim/flightmodel/position/true_theta", globalPropertyf },
	-- Position / environment
	{ "pos_x", "sim/flightmodel/position/local_x", globalPropertyf },
	{ "pos_y", "sim/flightmodel/position/local_y", globalPropertyf },
	{ "pos_z", "sim/flightmodel/position/local_z", globalPropertyf },
	{ "wave_amplitude", "sim/weather/wave_amplitude", globalPropertyf },
	-- Electrical
	{ "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
	{ "bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf },
	{ "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
	-- DISS / NVU outputs & internal state
	{ "diss_wind_course", "tu154/custom/nvu/diss_wind_course", globalPropertyf },
	{ "diss_wind_spd", "tu154/custom/nvu/diss_wind_spd", globalPropertyf },
	{ "diss_groundspeed", "tu154/custom/nvu/diss_groundspeed", globalPropertyf },
	{ "diss_slip_angle", "tu154/custom/nvu/diss_slip_angle", globalPropertyf },
	{ "diss_mode", "tu154/custom/nvu/diss_mode", globalPropertyi },
	{ "diss_cc", "tu154/custom/nvu/diss_cc", globalPropertyf },
	-- Failures
	{ "diss_fail", "tu154/custom/failures/diss_fail", globalPropertyi },
})

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------
local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function wrap360(a)
	a = a % 360
	if a < 0 then a = a + 360 end
	return a
end

local function shortestDeltaDeg(target, current)
	local d = target - current
	if d > 180 then d = d - 360 end
	if d < -180 then d = d + 360 end
	return d
end

local function expAlpha(dt, tau)
	-- tau in seconds; dt in seconds
	if tau <= 0 then return 1 end
	-- Guard against extreme dt spikes
	if dt < 0 then return 0 end
	-- Numerical stability for very small dt
	return 1 - math.exp(-dt / tau)
end

-- ----------------------------------------------------------------------------
-- A) Mode robustness parameters
-- ----------------------------------------------------------------------------
-- Hysteresis thresholds (km/h and degrees)
local AUTO_GS_ON_KMH   = 190
local AUTO_GS_OFF_KMH  = 170
local AUTO_ROLL_ON_DEG = 18
local AUTO_ROLL_OFF_DEG = 22

-- Enable/disable delay to suppress mode chatter (seconds)
local AUTO_ENABLE_DELAY_S  = 2.0
local AUTO_DISABLE_DELAY_S = 0.5

-- Hold last good auto solution when auto becomes temporarily invalid (seconds)
local AUTO_HOLD_LAST_GOOD_S = 15.0

-- ----------------------------------------------------------------------------
-- B) Filtering parameters (seconds)
-- ----------------------------------------------------------------------------
-- Time constants for exponential smoothing
local TAU_WIND_DIR_S = 3.0
local TAU_WIND_SPD_S = 4.0

-- ----------------------------------------------------------------------------
-- State
-- ----------------------------------------------------------------------------
local diss_wind_dir_rel = 0          -- Target wind direction relative to aircraft course (deg)
local diss_wind_speed_ms = 0         -- Target wind speed (m/s)
local g_spd = 0                      -- m/s
local slip_angle = 0                 -- deg

-- Absolute filtered outputs (B3/B4)
local wind_dir_abs_act = wrap360(get(diss_wind_course))     -- absolute 0..360
local wind_spd_act_ms  = get(diss_wind_spd) / 3.6           -- m/s

-- Auto-mode latch and timing (A1)
local auto_latched = false
local auto_enable_timer = 0
local auto_disable_timer = 0

-- Last-good auto solution and age (A2 + B5)
local last_auto_dir_abs = wind_dir_abs_act
local last_auto_spd_ms  = wind_spd_act_ms
local last_auto_g_spd   = 0
local last_auto_slip    = 0
local last_auto_age_s   = 1e9

-- ----------------------------------------------------------------------------
-- Update loop
-- ----------------------------------------------------------------------------
function update()
	-- Power logic (preserve original condition exactly)
	local diss_on_val = get(diss_on)
	local bus27_v = get(bus27_volt_left)
	local bus36_v = get(bus36_volt_left)
	local bus115_v = get(bus115_1_volt)
	local power = diss_on_val == 1 and bus27_v > 13 and bus36_v > 30 and bus115_v > 110
	set(diss_cc, bool2int(power))

	-- Frame time
	local passed = get(frame_time)
	if passed < 0 then passed = 0 end

	-- Failure state
	local fail = get(diss_fail) == 1

	-- Aircraft position for terrain probe
	local plane_x = get(pos_x)
	local plane_y = get(pos_y)
	local plane_z = get(pos_z)

	-- Terrain probe (keep exact call signature and returns)
	local prob, locationX, locationY, locationZ, normalX, normalY, normalZ, velocityX, velocityY, vlocityZ, isWet = sasl.probeTerrain(
		plane_x, plane_y, plane_z
	)

	-- NVU mode selector
	local nvu_mode = get(nvu_calc_set)

	-- Cache commonly used values for this frame
	local TAS_ms = get(tas_svs) / 3.6
	local acf_course = get(course_gpk)
	local roll_abs = math.abs(get(acf_roll))
	local wave_amp = get(wave_amplitude)
	local diss_sw = get(diss_mode_sw)
	local GS_kmh = get(groundspeed) * 3.6

	-- Track age of last good auto solution
	last_auto_age_s = last_auto_age_s + passed

	-- ----------------------------------------------------------------------------
	-- A1) Auto availability with hysteresis + enable/disable delay
	-- ----------------------------------------------------------------------------
	-- Base constraints (same intent as original, but made hysteresis-aware)
	local wet_block = (isWet and diss_sw == 1) or (wave_amp < 0.1 and isWet)

	-- Hysteresis thresholds depend on latch state
	local gs_ok = false
	local roll_ok = false
	if auto_latched then
		gs_ok = GS_kmh >= AUTO_GS_OFF_KMH
		roll_ok = roll_abs <= AUTO_ROLL_OFF_DEG
	else
		gs_ok = GS_kmh >= AUTO_GS_ON_KMH
		roll_ok = roll_abs <= AUTO_ROLL_ON_DEG
	end

	local auto_candidate = (power and not fail and nvu_mode == 1 and roll_ok and gs_ok and not wet_block)

	-- Apply enable/disable delays
	if nvu_mode ~= 1 or not power or fail then
		-- Hard reset latch outside auto request, power, or on failure
		auto_latched = false
		auto_enable_timer = 0
		auto_disable_timer = 0
	else
		if auto_candidate then
			auto_disable_timer = 0
			auto_enable_timer = auto_enable_timer + passed
			if not auto_latched and auto_enable_timer >= AUTO_ENABLE_DELAY_S then
				auto_latched = true
				auto_enable_timer = 0
			end
		else
			auto_enable_timer = 0
			auto_disable_timer = auto_disable_timer + passed
			if auto_latched and auto_disable_timer >= AUTO_DISABLE_DELAY_S then
				auto_latched = false
				auto_disable_timer = 0
			end
		end
	end

	-- ----------------------------------------------------------------------------
	-- Determine mode (kept aligned with original intent; auto is now latched)
	-- ----------------------------------------------------------------------------
	local mode = 0
	if power and fail then
		mode = 2
	elseif power and nvu_mode == 1 and auto_latched then
		mode = 1
	elseif power and nvu_mode ~= -1 then
		mode = 2
	elseif power and nvu_mode == -1 then
		mode = 3
	elseif not power then
		g_spd = 0
		slip_angle = 0
	end

	-- ----------------------------------------------------------------------------
	-- Mode computations
	-- ----------------------------------------------------------------------------
	if mode == 1 then
		-- Automatic wind calculation from measured ground track vs heading
		g_spd = math.abs(get(groundspeed))

		local deg2_val = get(deg2)
		local deg1_val = get(deg1)
		slip_angle = deg2_val - deg1_val

		if slip_angle > 180 then
			slip_angle = slip_angle - 360
		elseif slip_angle < -180 then
			slip_angle = slip_angle + 360
		end

		slip_angle = clamp(slip_angle, -30, 30)

		-- B5) Validity gate: refuse to update auto solution if inputs are not credible
		-- Auto is only meaningful if TAS and GS are above minimal levels and we have stable dt
		local auto_valid = (passed > 0) and (TAS_ms > 30) and (g_spd > 30)

		if auto_valid then
			local slip_rad = math.rad(slip_angle)
			local g_sin = g_spd * math.sin(slip_rad)
			local g_cos = g_spd * math.cos(slip_rad)

			diss_wind_speed_ms = math.sqrt((g_sin)^2 + (g_cos - TAS_ms)^2)
			diss_wind_dir_rel = math.deg(math.atan2(g_sin, g_cos - TAS_ms))

			-- Keep relative direction in a sane range (0..360 for later absolute conversion)
			if diss_wind_dir_rel > 360 then
				diss_wind_dir_rel = diss_wind_dir_rel - 360
			elseif diss_wind_dir_rel < 0 then
				diss_wind_dir_rel = diss_wind_dir_rel + 360
			end

			-- A2) Update last good auto solution (absolute)
			last_auto_dir_abs = wrap360(acf_course + diss_wind_dir_rel)
			last_auto_spd_ms  = diss_wind_speed_ms
			last_auto_g_spd   = g_spd
			last_auto_slip    = slip_angle
			last_auto_age_s   = 0
		else
			-- If auto math is invalid, fall back immediately to last-good within hold window
			if last_auto_age_s <= AUTO_HOLD_LAST_GOOD_S then
				diss_wind_speed_ms = last_auto_spd_ms
				diss_wind_dir_rel  = wrap360(last_auto_dir_abs - acf_course)
				g_spd              = last_auto_g_spd
				slip_angle         = last_auto_slip
			else
				-- If no valid auto solution exists, keep current targets unchanged (no abrupt reset)
				-- This avoids injecting garbage into the filter chain.
			end
		end

	elseif mode == 2 then
		-- Manual wind entry / DISS computed groundspeed and slip
		diss_wind_speed_ms = get(diss_wind_spd) / 3.6
		diss_wind_dir_rel = get(diss_wind_course) - acf_course

		local wind_dir_rad = math.rad(diss_wind_dir_rel)
		local w_sin = diss_wind_speed_ms * math.sin(wind_dir_rad)
		local w_cos = diss_wind_speed_ms * math.cos(wind_dir_rad)

		g_spd = math.sqrt((w_sin)^2 + (TAS_ms + w_cos)^2)
		slip_angle = math.deg(math.atan2(w_sin, w_cos + TAS_ms))

		-- Wind direction adjust buttons
		local but_C_L = get(wind_course_left)
		local but_C_C = get(wind_course_ctr)
		local but_C_R = get(wind_course_right)
		diss_wind_dir_rel = diss_wind_dir_rel + (but_C_R - but_C_L) * (1 + 9 * but_C_C) * passed * 3

		-- Wind speed adjust buttons
		local but_S_L = get(wind_spd_left)
		local but_S_C = get(wind_spd_ctr)
		local but_S_R = get(wind_spd_right)
		diss_wind_speed_ms = diss_wind_speed_ms + (but_S_R - but_S_L) * (1 + 9 * but_S_C) * passed * 0.7
		diss_wind_speed_ms = clamp(diss_wind_speed_ms, 0, 300)

		-- A2) If user is in auto-request (nvu_mode==1) but auto is temporarily not latched,
		-- hold last-good auto for a short window unless there is active manual button input.
		-- This prevents abrupt jumps to manual-derived values when auto drops briefly.
		local manual_activity = (but_C_L ~= 0) or (but_C_C ~= 0) or (but_C_R ~= 0) or (but_S_L ~= 0) or (but_S_C ~= 0) or (but_S_R ~= 0)
		if nvu_mode == 1 and not auto_latched and not manual_activity and last_auto_age_s <= AUTO_HOLD_LAST_GOOD_S then
			diss_wind_speed_ms = last_auto_spd_ms
			diss_wind_dir_rel  = wrap360(last_auto_dir_abs - acf_course)
			g_spd              = last_auto_g_spd
			slip_angle         = last_auto_slip
		end

	elseif mode == 3 then
		-- Default / fallback
		g_spd = 197.222
		slip_angle = 0

	elseif mode == 10 then
		-- Reserved mode (kept for compatibility)
		g_spd = 0
		slip_angle = 0
	end

	-- Clamp slip angle (preserve original clamp)
	slip_angle = clamp(slip_angle, -30, 30)

	-- ----------------------------------------------------------------------------
	-- B3/B4) Absolute-direction filtering + exponential smoothing
	-- ----------------------------------------------------------------------------
	-- Convert relative target to absolute target for filtering
	local target_dir_abs = wrap360(acf_course + diss_wind_dir_rel)
	local target_spd_ms  = diss_wind_speed_ms

	-- Exponential smoothing factors
	local a_dir = expAlpha(passed, TAU_WIND_DIR_S)
	local a_spd = expAlpha(passed, TAU_WIND_SPD_S)

	-- Smooth absolute wind direction using shortest arc
	local d_dir = shortestDeltaDeg(target_dir_abs, wind_dir_abs_act)
	wind_dir_abs_act = wrap360(wind_dir_abs_act + d_dir * a_dir)

	-- Smooth wind speed
	wind_spd_act_ms = wind_spd_act_ms + (target_spd_ms - wind_spd_act_ms) * a_spd

	-- ----------------------------------------------------------------------------
	-- Write outputs (preserve original MASTER logic exactly)
	-- ----------------------------------------------------------------------------
	local MASTER = get(ismaster) ~= 1
	if MASTER then
		set(diss_wind_course, wind_dir_abs_act)
		set(diss_wind_spd, wind_spd_act_ms * 3.6)
		set(diss_groundspeed, g_spd * 3.6)
		set(diss_slip_angle, slip_angle)
		set(diss_mode, mode)
	end
end

