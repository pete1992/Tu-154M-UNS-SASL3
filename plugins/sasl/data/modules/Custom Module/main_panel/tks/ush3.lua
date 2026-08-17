-- ============================================================================
-- TKS BIG NEEDLES / MODE LIGHTS
-- Refactor goals:
-- - Preserve full functionality (no removals, no behavior changes)
-- - Improve readability and structure
-- - Reduce redundant get() calls per frame (performance)
-- - Keep all comments in English (line comments only)
-- ============================================================================

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
	{ "diss_slip_angle", "tu154/custom/nvu/diss_slip_angle", globalPropertyf },
	{ "tks_mode", "tu154/custom/switchers/ovhd/tks_mode", globalPropertyi },

	-- Time / power
	{ "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
	{ "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },

	-- Mode lights
	{ "tks_mode_lit_mk", "tu154/custom/lights/tks_mode_lit_mk", globalPropertyf },
	{ "tks_mode_lit_ak", "tu154/custom/lights/tks_mode_lit_ak", globalPropertyf },
	{ "tks_mode_lit_gpk", "tu154/custom/lights/tks_mode_lit_gpk", globalPropertyf },

	-- Needles / outputs
	{ "big_course_needle", "tu154/custom/gauges/compas/big_course_needle", globalPropertyf },
	{ "big_true_course_needle", "tu154/custom/gauges/compas/big_true_course_needle", globalPropertyf },
	{ "big_tri_needle", "tu154/custom/gauges/compas/big_tri_needle", globalPropertyf },
	{ "ush_cc", "tu154/custom/tks/ush_cc", globalPropertyf },
})

-- ----------------------------------------------------------------------------
-- State initialization
-- ----------------------------------------------------------------------------
local course_main = math.random(-180, 180)
local course_aux = math.random(-180, 180)
local course_pu = course_main

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

local function follow_target(current, target, passed)
	-- Preserve original behavior:
	-- - If delta > 1: move by -passed*30
	-- - If delta < -1: move by +passed*30
	-- - Else: move by -delta*passed*20
	local delta = current - target
	delta = normalizeDelta180(delta)

	if delta > 1 then
		current = current - passed * 30
	elseif delta < -1 then
		current = current + passed * 30
	else
		current = current - delta * passed * 20
	end

	return current
end

-- ----------------------------------------------------------------------------
-- Update loop
-- ----------------------------------------------------------------------------
function update()
	local passed = get(frame_time)
	local power = get(bus27_volt_right) > 13

	local main_ga = get(course_ga_1)
	local aux_ga = get(course_ga_2)
	local slip = get(diss_slip_angle)

	if power then
		-- Main and auxiliary needles track their sources
		course_main = follow_target(course_main, main_ga, passed)
		course_aux = follow_target(course_aux, aux_ga, passed)

		-- True course needle tracks main + slip
		course_pu = follow_target(course_pu, course_main + slip, passed)

		-- Mode lights
		local mode = get(tks_mode)
		if mode == 0 then
			set(tks_mode_lit_mk, 1)
			set(tks_mode_lit_gpk, 0)
			set(tks_mode_lit_ak, 0)
		elseif mode == 1 then
			set(tks_mode_lit_mk, 0)
			set(tks_mode_lit_gpk, 1)
			set(tks_mode_lit_ak, 0)
		else
			set(tks_mode_lit_mk, 0)
			set(tks_mode_lit_gpk, 0)
			set(tks_mode_lit_ak, 1)
		end
	else
		-- No power: all mode lights off
		set(tks_mode_lit_mk, 0)
		set(tks_mode_lit_gpk, 0)
		set(tks_mode_lit_ak, 0)
	end

	-- Outputs are always written (preserve original behavior)
	set(big_course_needle, course_main)
	set(big_tri_needle, course_aux)
	set(big_true_course_needle, course_pu)
	set(ush_cc, bool2int(power))
end
