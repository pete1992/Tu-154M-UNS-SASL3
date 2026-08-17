-- ============================================================================
-- TKS FAILURE INJECTION
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
	-- Failures
	{ "gyro_fail_1", "sim/operation/failures/rel_ss_dgy", globalPropertyi },
	{ "gyro_fail_2", "sim/operation/failures/rel_cop_dgy", globalPropertyi },
	{ "tks_km1_fail", "tu154/custom/failures/tks_km1_fail", globalPropertyi },
	{ "tks_km2_fail", "tu154/custom/failures/tks_km2_fail", globalPropertyi },
	{ "tks_bgmk1_fail", "tu154/custom/failures/tks_bgmk1_fail", globalPropertyi },
	{ "tks_bgmk2_fail", "tu154/custom/failures/tks_bgmk2_fail", globalPropertyi },

	-- Time / settings
	{ "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
	{ "failures_enabled", "tu154/custom/failures/failures_enabled", globalPropertyi },
})

-- ----------------------------------------------------------------------------
-- State
-- ----------------------------------------------------------------------------
local fail_counter = 0
local check_time = math.random(15, 30)

-- ----------------------------------------------------------------------------
-- Helpers (preserve original behavior)
-- ----------------------------------------------------------------------------
local function maybe_set_failure(prop, fail_value, probability)
	-- Preserve original behavior:
	-- - Only set if current value is not already the fail value
	-- - Set to (bool2int(random < probability) * fail_value)
	if get(prop) ~= fail_value then
		set(prop, bool2int(math.random() < probability) * fail_value)
	end
end

local function clear_failures()
	set(gyro_fail_1, 0)
	set(gyro_fail_2, 0)
	set(tks_km1_fail, 0)
	set(tks_km2_fail, 0)
	set(tks_bgmk1_fail, 0)
	set(tks_bgmk2_fail, 0)
end

-- ----------------------------------------------------------------------------
-- Update loop
-- ----------------------------------------------------------------------------
function update()
	local passed = get(frame_time)
	local MASTER = get(ismaster) ~= 1

	if MASTER then
		local FAIL = get(failures_enabled)

		-- Preserve original scaling exactly
		FAIL = FAIL * 0.05 * 4 ^ (FAIL * 0.5)

		if FAIL > 0 then
			fail_counter = fail_counter + passed

			if fail_counter > check_time then
				fail_counter = 0
				check_time = math.random(15, 30)

				-- Preserve original probability and per-device scaling exactly
				local p = 0.0001 * FAIL * 0.3

				maybe_set_failure(gyro_fail_1, 6, p)
				maybe_set_failure(gyro_fail_2, 6, p)
				maybe_set_failure(tks_km1_fail, 1, p)
				maybe_set_failure(tks_km2_fail, 1, p)
				maybe_set_failure(tks_bgmk1_fail, 1, p)
				maybe_set_failure(tks_bgmk2_fail, 1, p)
			end
		else
			fail_counter = 0
			clear_failures()
		end
	end
end
