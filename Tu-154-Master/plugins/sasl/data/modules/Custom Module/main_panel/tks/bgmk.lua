-- ============================================================================
-- TKS BGMK COURSE COMPUTATION
-- Refactor goals:
-- - Preserve full functionality (no removals, no behavior changes)
-- - Improve readability and structure
-- - Reduce redundant get() calls per frame (performance)
-- - Keep all comments in English (line comments only)
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
	-- Inputs
	{ "course_ga_1", "tu154/custom/tks/course_ga_1", globalPropertyf },
	{ "course_ga_2", "tu154/custom/tks/course_ga_2", globalPropertyf },
	{ "course_mk_1", "tu154/custom/tks/course_mk_1", globalPropertyf },
	{ "course_mk_2", "tu154/custom/tks/course_mk_2", globalPropertyf },

	-- Time
	{ "frame_time", "tu154/custom/time/frame_time", globalPropertyf },

	-- Electrical
	{ "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
	{ "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
	{ "bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf },
	{ "bus36_volt_right", "tu154/custom/elec/bus36_volt_right", globalPropertyf },
	{ "bus36_volt_pts250_1", "tu154/custom/elec/bus36_volt_pts250_1", globalPropertyf },
	{ "bus36_volt_pts250_2", "tu154/custom/elec/bus36_volt_pts250_2", globalPropertyf },

	-- Controls
	{ "tks_mode", "tu154/custom/switchers/ovhd/tks_mode", globalPropertyi },
	{ "tks_corrr_button", "tu154/custom/buttons/ovhd/tks_corrr_button", globalPropertyi },
	{ "tks_corr_1", "tu154/custom/switchers/ovhd/tks_corr_1", globalPropertyi },
	{ "tks_corr_2", "tu154/custom/switchers/ovhd/tks_corr_2", globalPropertyi },
	{ "tks_user", "tu154/custom/switchers/ovhd/tks_mode_left", globalPropertyi },

	-- Failures
	{ "fail1", "tu154/custom/failures/tks_bgmk1_fail", globalPropertyi },
	{ "fail2", "tu154/custom/failures/tks_bgmk2_fail", globalPropertyi },

	-- Outputs
	{ "course_bgmk_1", "tu154/custom/tks/course_bgmk_1", globalPropertyf },
	{ "course_bgmk_2", "tu154/custom/tks/course_bgmk_2", globalPropertyf },
	{ "course_gpk", "tu154/custom/tks/course_gpk", globalPropertyf },
	{ "course_gmk", "tu154/custom/tks/course_gmk", globalPropertyf },
	{ "bgmk_1_cc", "tu154/custom/tks/bgmk_1_cc", globalPropertyf },
	{ "bgmk_2_cc", "tu154/custom/tks/bgmk_2_cc", globalPropertyf },

	-- Engines
	{ "eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalPropertyf },
	{ "eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalPropertyf },
	{ "eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalPropertyf },
})

-- ----------------------------------------------------------------------------
-- State
-- ----------------------------------------------------------------------------
local bgmk_corr_1 = 0
local bgmk_corr_2 = 0

local notLoaded = true
local start_timer = 0

-- ----------------------------------------------------------------------------
-- Reset logic
-- ----------------------------------------------------------------------------
local function sw_reset()
	-- Randomize BGMK correction on cold start only when engines are not running
	if get(eng1_N1) < 5 and get(eng2_N1) < 5 and get(eng3_N1) < 5 then
		bgmk_corr_1 = math.random(-180, 180)
		bgmk_corr_2 = math.random(-180, 180)
	end
end

-- ----------------------------------------------------------------------------
-- Helpers (preserve original behavior)
-- ----------------------------------------------------------------------------
local function normalizeDelta180(d)
	while d > 180 do
		d = d - 360
	end
	while d < -180 do
		d = d + 360
	end
	return d
end

local function normalize180(v)
	if v > 180 then
		v = v - 360
	elseif v < -180 then
		v = v + 360
	end
	return v
end

-- ----------------------------------------------------------------------------
-- Update loop
-- ----------------------------------------------------------------------------
function update()
	local passed = get(frame_time)
	local MASTER = get(ismaster) ~= 1

	start_timer = start_timer + passed
	if notLoaded and start_timer > 0.3 then
		sw_reset()
		notLoaded = false
	end

	-- Cache power / failure state
	local bus27_l = get(bus27_volt_left)
	local bus27_r = get(bus27_volt_right)
	local bus36_pts2 = get(bus36_volt_pts250_2)
	local bus36_r = get(bus36_volt_right)

	local f1 = get(fail1)
	local f2 = get(fail2)

	local power_1 = bus27_l > 13 and bus36_pts2 > 30 and f1 == 0
	local power_2 = bus27_r > 13 and bus36_r > 30 and f2 == 0

	local mode = get(tks_mode)
	local button = get(tks_corrr_button)

	local ga1 = get(course_ga_1)
	local ga2 = get(course_ga_2)

	-- ----------------------------
	-- BGMK #1
	-- ----------------------------
	local bgmk_cur_1 = ga1 + bgmk_corr_1
	local corr1_on = get(tks_corr_1) == 1

	if corr1_on then
		local mag_crs = get(course_mk_1)

		if mode == 0 then
			-- Mode 0 branch intentionally kept empty (as original)
		elseif mode > 0 then
			local delta = bgmk_cur_1 - mag_crs
			delta = normalizeDelta180(delta)

			if delta > 1 then
				bgmk_corr_1 = bgmk_corr_1 - (passed * 1 + button * passed * 10)
			elseif delta < -1 then
				bgmk_corr_1 = bgmk_corr_1 + (passed * 1 + button * passed * 10)
			else
				local corr_need = mag_crs - ga1
				corr_need = normalizeDelta180(corr_need)
				bgmk_corr_1 = bgmk_corr_1 + (corr_need - bgmk_corr_1) * (passed * 0.1 + button * passed * 10)
			end
		end
	end

	bgmk_corr_1 = normalize180(bgmk_corr_1)
	bgmk_cur_1 = normalize180(bgmk_cur_1)

	-- ----------------------------
	-- BGMK #2
	-- ----------------------------
	local bgmk_cur_2 = ga2 + bgmk_corr_2
	local corr2_on = get(tks_corr_2) == 1

	if corr2_on then
		local mag_crs = get(course_mk_2)

		if mode == 0 then
			local delta = bgmk_cur_2 - mag_crs
			delta = normalizeDelta180(delta)

			if delta > 1 then
				bgmk_corr_2 = bgmk_corr_2 - (passed * 0.1)
			elseif delta < -1 then
				bgmk_corr_2 = bgmk_corr_2 + (passed * 0.1)
			else
				local corr_need = mag_crs - ga2
				corr_need = normalizeDelta180(corr_need)
				bgmk_corr_2 = bgmk_corr_2 + (corr_need - bgmk_corr_2) * (passed * 0.1)
			end

		elseif mode > 0 then
			local delta = bgmk_cur_2 - mag_crs
			delta = normalizeDelta180(delta)

			if delta > 1 then
				bgmk_corr_2 = bgmk_corr_2 - (passed * 1 + button * passed * 10)
			elseif delta < -1 then
				bgmk_corr_2 = bgmk_corr_2 + (passed * 1 + button * passed * 10)
			else
				local corr_need = mag_crs - ga2
				corr_need = normalizeDelta180(corr_need)
				bgmk_corr_2 = bgmk_corr_2 + (corr_need - bgmk_corr_2) * (passed * 0.1 + button * passed * 10)
			end
		end
	end

	bgmk_corr_2 = normalize180(bgmk_corr_2)
	bgmk_cur_2 = normalize180(bgmk_cur_2)

	-- Outputs
	if MASTER then
		set(course_bgmk_1, bgmk_cur_1)
		set(course_bgmk_2, bgmk_cur_2)

		local users = get(tks_user)
		if users == 1 then
			set(course_gpk, ga1)
			set(course_gmk, bgmk_cur_1)
		else
			set(course_gpk, ga2)
			set(course_gmk, bgmk_cur_2)
		end
	end

	set(bgmk_1_cc, bool2int(power_1))
	set(bgmk_2_cc, bool2int(power_2))
end
