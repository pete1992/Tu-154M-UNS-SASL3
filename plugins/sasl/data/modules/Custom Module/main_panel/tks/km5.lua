-- ============================================================================
-- KM-5 (MK COURSE) INDICATOR LOGIC
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
	{ "mag_psi", "sim/flightmodel/position/mag_psi", globalPropertyf },
	{ "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
	{ "gforce_fwd", "sim/flightmodel2/misc/gforce_axil", globalPropertyf },
	{ "gforce_side", "sim/flightmodel2/misc/gforce_side", globalPropertyf },
	-- Electrical / failure
	{ "bus27_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
	{ "bus36_volt", "tu154/custom/elec/bus36_volt_pts250_2", globalPropertyf },
	{ "fail", "tu154/custom/failures/tks_km1_fail", globalPropertyf },
	-- Gauge controls / outputs
	{ "km5_knob", "tu154/custom/gauges/eng/km5_knob_1", globalPropertyf },
	{ "km5_scale", "tu154/custom/gauges/eng/km5_scale_1", globalPropertyf },
	{ "km5_needle", "tu154/custom/gauges/eng/km5_needle_1", globalPropertyf },
	{ "course_mk", "tu154/custom/tks/course_mk_1", globalPropertyf },
	{ "km5_cc", "tu154/custom/tks/km5_1_cc", globalPropertyf },
})

-- ----------------------------------------------------------------------------
-- State initialization
-- ----------------------------------------------------------------------------
local mag_course = get(mag_psi)
local needle_act = math.random(-180, 180)
set(km5_needle, needle_act)
local course = 0
local cur_dev_sign = math.random(0, 1) * 2 - 1
local cur_dev_act = 0

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
	local bus36_v = get(bus36_volt)
	local bus27_v = get(bus27_volt)
	local fail_val = get(fail)
	local power = bus36_v > 30 and bus27_v > 13 and fail_val == 0
	-- Knob normalization (preserve while-loop behavior)
	local knob = get(km5_knob)
	knob = normalizeDelta180(knob)

	if MASTER then
		set(km5_scale, knob)
	end

	needle_act = get(km5_needle)

	if MASTER then
		if power then
			local g_fwd = get(gforce_fwd)
			local g_side = get(gforce_side)

			mag_course = get(mag_psi) + cur_dev_act
			cur_dev_act = cur_dev_act + (cur_dev_sign * (g_fwd + g_side) * 20 - cur_dev_act) * passed * 0.5

			mag_course = normalize180(mag_course)

			local cur_dif = mag_course - needle_act
			cur_dif = normalizeDelta180(cur_dif)

			if cur_dif > 1 then
				needle_act = needle_act + passed * 20
			elseif cur_dif < -1 then
				needle_act = needle_act - passed * 20
			else
				needle_act = needle_act + cur_dif * passed * 10
			end
		end
		set(km5_needle, needle_act)
	end

	if power then
		course = needle_act - knob
	end

	course = normalize180(course)
	set(course_mk, course)
	set(km5_cc, bool2int(power))
end
