-- ============================================================================
-- TKS / GA COURSE COMPUTATION
-- Refactor goals:
-- - Preserve full functionality (no removals, no behavior changes)
-- - Improve readability and structure
-- - Reduce redundant get() calls per frame (performance)
--
-- ============================================================================

-----------------------------------------------------------------------
-- Smartcopilot
-----------------------------------------------------------------------
defineProperty("ismaster",    globalPropertyf("scp/api/ismaster"))   -- 0 = plugin not found, 1 = slave, 2 = master
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1")) -- 1 = no control, 2 = has control

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
	-- Aircraft heading / attitude / position
	{ "true_psi", "sim/flightmodel/position/true_psi", globalPropertyf },
	{ "mag_psi", "sim/flightmodel/position/mag_psi", globalPropertyf },
	{ "course_mk", "tu154/custom/tks/course_mk_1", globalPropertyf },
	{ "cur", "sim/cockpit/gyros/psi_ind_degm4", globalPropertyf },
	{ "roll", "sim/flightmodel/position/phi", globalPropertyf },
	{ "pitch", "sim/flightmodel/position/true_theta", globalPropertyf },
	{ "latitude", "sim/flightmodel/position/latitude", globalPropertyd },
	{ "longitude", "sim/flightmodel/position/longitude", globalPropertyd },

	-- Time
	{ "frame_time", "tu154/custom/time/frame_time", globalPropertyf },

	-- TKS controls
	{ "tks_mode", "tu154/custom/switchers/ovhd/tks_mode", globalPropertyi },
	{ "tks_user", "tu154/custom/switchers/ovhd/tks_mode_left", globalPropertyi },
	{ "tks_source", "tu154/custom/switchers/ovhd/tks_mode_right", globalPropertyi },
	{ "tks_course_set", "tu154/custom/switchers/ovhd/tks_course_set", globalPropertyi },
	{ "tks_corrr_button", "tu154/custom/buttons/ovhd/tks_corrr_button", globalPropertyi },
	{ "tks_lat_set", "tu154/custom/rotary/ovhd/tks_lat_set", globalPropertyf },

	{ "tks_on_1", "tu154/custom/switchers/ovhd/tks_on_1", globalPropertyi },
	{ "tks_on_2", "tu154/custom/switchers/ovhd/tks_on_2", globalPropertyi },
	{ "tks_heat", "tu154/custom/switchers/ovhd/tks_heat", globalPropertyi },
	{ "tks_corr_1", "tu154/custom/switchers/ovhd/tks_corr_1", globalPropertyi },
	{ "tks_corr_2", "tu154/custom/switchers/ovhd/tks_corr_2", globalPropertyi },

	-- Stabilization
	{ "stabil_ga_main", "tu154/custom/switchers/ovhd/stabil_ga_main", globalPropertyi },
	{ "stabil_ga_reserv", "tu154/custom/switchers/ovhd/stabil_ga_reserv", globalPropertyi },

	-- Electrical
	{ "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
	{ "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
	{ "bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf },
	{ "bus36_volt_right", "tu154/custom/elec/bus36_volt_right", globalPropertyf },
	{ "bus36_volt_pts250_1", "tu154/custom/elec/bus36_volt_pts250_1", globalPropertyf },
	{ "bus36_volt_pts250_2", "tu154/custom/elec/bus36_volt_pts250_2", globalPropertyf },
	{ "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
	{ "bus115_2_volt", "tu154/custom/elec/bus115_2_volt", globalPropertyf },
	{ "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },

	-- Failures
	{ "fail_1", "sim/operation/failures/rel_ss_dgy", globalPropertyf },
	{ "fail_2", "sim/operation/failures/rel_cop_dgy", globalPropertyf },

	-- Outputs
	{ "course_ga_1", "tu154/custom/tks/course_ga_1", globalPropertyf },
	{ "course_ga_2", "tu154/custom/tks/course_ga_2", globalPropertyf },
	{ "fail_left", "tu154/custom/tks/fail_left", globalPropertyi },
	{ "fail_right", "tu154/custom/tks/fail_right", globalPropertyi },
	{ "ga_1_cc", "tu154/custom/tks/ga_1_cc", globalPropertyf },
	{ "ga_2_cc", "tu154/custom/tks/ga_2_cc", globalPropertyf },
	{ "ga_heat_cc", "tu154/custom/tks/ga_heat_cc", globalPropertyf },

	-- Engines
	{ "eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalProperty },
	{ "eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalProperty },
	{ "eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalProperty },
})

-----------------------------------------------------------------------
-- Smartcopilot
-----------------------------------------------------------------------
defineProperty("ismaster",    globalPropertyf("scp/api/ismaster"))   -- 0 = plugin not found, 1 = slave, 2 = master
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1")) -- 1 = no control, 2 = has control

-- ----------------------------------------------------------------------------
-- State
-- ----------------------------------------------------------------------------
local course_1 = get(mag_psi)
local course_2 = get(mag_psi)
set(course_ga_1, course_1)
set(course_ga_2, course_2)

local passed = 0
local counter_1 = 0
local counter_2 = 0

local cur_last_1 = get(true_psi)
local cur_last_2 = get(true_psi)

local rotation = 0

local lat_last_1 = get(latitude)
local lon_last_1 = get(longitude)
local lat_last_2 = get(latitude)
local lon_last_2 = get(longitude)

local notLoaded = true
local start_timer = 0

-- ----------------------------------------------------------------------------
-- Reset logic
-- ----------------------------------------------------------------------------
local function sw_reset()
	-- Randomize course on cold start only when engines are not running
	if get(eng1_N1) < 5 and get(eng2_N1) < 5 and get(eng3_N1) < 5 then
		course_1 = math.random(-180, 180)
		course_2 = math.random(-180, 180)
		set(course_ga_1, course_1)
		set(course_ga_2, course_2)
	end
end

-- ----------------------------------------------------------------------------
-- Helpers (preserve original behavior)
-- ----------------------------------------------------------------------------
local function normalize180(v)
	if v > 180 then
		v = v - 360
	elseif v < -180 then
		v = v + 360
	end
	return v
end

local function normalizeDelta180(d)
	if d > 180 then
		d = d - 360
	elseif d < -180 then
		d = d + 360
	end
	return d
end

local function update_ga_course(power, course, cur_last, lat_last, lon_last, counter, curs, pitch_now, lat_now, lon_now, sin_lat_now, lat_set, sin_lat_set, passed, mag_curs, correct_dev, corr_but, mode, corr_turn, corr_side)
	-- Integrate gyro delta with earth rotation and latitude correction, then apply correction logic

	if power then
		local delta_cur = curs - cur_last
		delta_cur = normalizeDelta180(delta_cur)
		if math.abs(pitch_now) > 80 then
			delta_cur = 0
		end

		if counter > 10 then
			local lon_dif = lon_now - lon_last
			lon_dif = normalizeDelta180(lon_dif)

			local geo_corr = lon_dif * math.sin(math.rad((lat_last + lat_now) / 2))
			lat_last = lat_now
			lon_last = lon_now

			-- Preserve NaN-guard logic exactly
			if geo_corr == geo_corr then
				course = course - geo_corr
			end

			counter = 0
		end

		counter = counter + passed

		local earth_rot = 360 * sin_lat_now * passed / 86164
		course = course + delta_cur - earth_rot

		local az_corr = 360 * sin_lat_set * passed / 86164
		course = course + az_corr

		local corr = (correct_dev == corr_side)
		if corr then
			if mode == 0 then
				local corr_delta = course - mag_curs
				corr_delta = normalizeDelta180(corr_delta)

				local corr_rate = (passed * 0.1 + corr_but * passed * 10)
				if corr_delta > 1 then
					course = course - corr_rate
				elseif corr_delta < -1 then
					course = course + corr_rate
				else
					course = course - corr_delta * corr_rate
				end
			elseif mode > 0 then
				course = course + corr_turn * passed * 1
			end
		end

		course = normalize180(course)
	end

	return course, lat_last, lon_last, counter
end

-- ----------------------------------------------------------------------------
-- Update loop
-- ----------------------------------------------------------------------------
function update()
	local MASTER = get(ismaster) ~= 1

	passed = get(frame_time)
	start_timer = start_timer + passed

	if notLoaded and start_timer > 0.3 then
		if MASTER then
			sw_reset()
		end
		notLoaded = false
	end

	if passed > 0 then
		-- Cache common values for this frame
		local bus27_l = get(bus27_volt_left)
		local bus36_pts2 = get(bus36_volt_pts250_2)
		local bus36_r = get(bus36_volt_right)
		local bus115_1 = get(bus115_1_volt)

		local tks1 = get(tks_on_1)
		local tks2 = get(tks_on_2)

		local f1 = get(fail_1)
		local f2 = get(fail_2)

		local power_1 = bus27_l > 13 and bus36_pts2 > 30 and tks1 == 1 and f1 < 6
		local power_2 = bus27_l > 13 and bus36_r > 30 and tks2 == 1 and f2 < 6

		local heat_work = bool2int(bus27_l > 13 and bus115_1 > 110) * get(tks_heat)
		set(ga_heat_cc, 10 * heat_work)

		local lat_set = get(tks_lat_set)

		local curs = get(true_psi)
		local mag_curs = get(course_mk)

		local correct_dev = get(tks_source)
		local corr_but = get(tks_corrr_button)
		local mode = get(tks_mode)
		local corr_turn = get(tks_course_set)

		local pitch_now = get(pitch)
		local lat_now = get(latitude)
		local lon_now = get(longitude)

		-- Precompute sin(lat) terms used for both instruments
		local sin_lat_now = math.sin(math.rad(lat_now))
		local sin_lat_set = math.sin(math.rad(get(lat_set)))

		-- Always pull the current values from datarefs like the original code
		course_1 = get(course_ga_1)
		course_2 = get(course_ga_2)

		-- Update GA-1
		course_1, lat_last_1, lon_last_1, counter_1 = update_ga_course(
			power_1, course_1, cur_last_1, lat_last_1, lon_last_1, counter_1,
			curs, pitch_now, lat_now, lon_now, sin_lat_now,
			lat_set, sin_lat_set, passed, mag_curs, correct_dev, corr_but, mode, corr_turn, 1
		)

		-- Update GA-2
		course_2, lat_last_2, lon_last_2, counter_2 = update_ga_course(
			power_2, course_2, cur_last_2, lat_last_2, lon_last_2, counter_2,
			curs, pitch_now, lat_now, lon_now, sin_lat_now,
			lat_set, sin_lat_set, passed, mag_curs, correct_dev, corr_but, mode, corr_turn, 0
		)

		-- Fail flags
		set(fail_left, bool2int(not power_1))
		set(fail_right, bool2int(not power_2))

		-- Update last cursor angles
		cur_last_1 = curs
		cur_last_2 = curs

		-- Write outputs under MASTER gate (preserve original behavior)
		if MASTER then
			set(course_ga_1, course_1)
			set(course_ga_2, course_2)
		end

		set(ga_1_cc, bool2int(power_1))
		set(ga_2_cc, bool2int(power_2))
	end
end
