-- misc_fails.lua
-- Inject miscellaneous aircraft-system failures and manage native random-failure settings.

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

defineProps({
    -- Aircraft failures
    { "diss_fail", "tu154/custom/failures/diss_fail", globalPropertyi },
    { "nvu_fail", "tu154/custom/failures/nvu_fail", globalPropertyi },
    { "radar_fail", "tu154/custom/failures/radar_fail", globalPropertyi },
    { "rsbn_fail", "tu154/custom/failures/rsbn_fail", globalPropertyi },
    { "taws_fail", "tu154/custom/failures/taws_fail", globalPropertyi },
    { "acs1_fail", "tu154/custom/failures/acs1_fail", globalPropertyi },
    { "acs2_fail", "tu154/custom/failures/acs2_fail", globalPropertyi },
    { "acs3_fail", "tu154/custom/failures/acs3_fail", globalPropertyi },
    { "agr_fail", "tu154/custom/failures/agr_fail", globalPropertyi },
    { "bkk_fail", "tu154/custom/failures/bkk_fail", globalPropertyi },
    { "pitot1", "tu154/custom/failures/pitot1", globalPropertyi },
    { "pitot2", "tu154/custom/failures/pitot2", globalPropertyi },
    { "static1", "tu154/custom/failures/static1", globalPropertyi },
    { "static2", "tu154/custom/failures/static2", globalPropertyi },
    { "mgv_fail", "tu154/custom/failures/mgv_fail", globalPropertyi },
    { "rv1_fail", "tu154/custom/failures/rv1_fail", globalPropertyi },
    { "rv2_fail", "tu154/custom/failures/rv2_fail", globalPropertyi },
    { "AOA", "tu154/custom/failures/AOA", globalPropertyi },
    { "uvid15_fail", "tu154/custom/failures/uvid15_fail", globalPropertyi },

    -- Simulator failures
    { "rel_ss_alt", "sim/operation/failures/rel_ss_alt", globalPropertyi },
    { "rel_cop_alt", "sim/operation/failures/rel_cop_alt", globalPropertyi },
    { "rel_ss_tsi", "sim/operation/failures/rel_ss_tsi", globalPropertyi },
    { "rel_adc_comp", "sim/operation/failures/rel_adc_comp", globalPropertyi },
    { "rel_ss_ahz", "sim/operation/failures/rel_ss_ahz", globalPropertyi },
    { "rel_cop_ahz", "sim/operation/failures/rel_cop_ahz", globalPropertyi },
    { "rel_stall_warn", "sim/operation/failures/rel_stall_warn", globalPropertyi },
    { "rel_ss_vvi", "sim/operation/failures/rel_ss_vvi", globalPropertyi },
    { "rel_cop_vvi", "sim/operation/failures/rel_cop_vvi", globalPropertyi },

    -- X-Plane random scheduling is independent of the aircraft failure rolls.
    { "native_random_failures", "sim/operation/failures/enable_random_failures", globalPropertyi },
    -- Time and failure settings
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    { "failures_enabled", "tu154/custom/failures/failures_enabled", globalPropertyi },

    -- SmartCopilot: only the master injects failures.
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- 0 = absent, 1 = slave, 2 = master
    -- Unused: control ownership does not gate failure injection.
})

local fail_counter = 0
local check_time = math.random(15, 30)

-- Restore only the scheduler preference captured by this component.
-- Actual failure enums and the simulator MTBF duration remain untouched.
local native_random_preference = nil

local function restoreNativeRandomFailures()
    if native_random_preference ~= nil then
        set(native_random_failures, native_random_preference)
        native_random_preference = nil
    end
end

local function updateNativeRandomFailures(low_mode)
    if low_mode then
        local current = get(native_random_failures)
        if native_random_preference == nil then
            native_random_preference = current
        end
        if current ~= 0 then
            set(native_random_failures, 0)
        end
    else
        restoreNativeRandomFailures()
    end
end

function onModuleShutdown(isError)
    restoreNativeRandomFailures()
end

function update()
    local passed = get(frame_time)

    local MASTER = get(ismaster) ~= 1
    if not MASTER then
        updateNativeRandomFailures(get(failures_enabled) == 1)
    end

    if MASTER then
        local failure_level = get(failures_enabled)
        local FAIL = failure_level
        updateNativeRandomFailures(failure_level == 1)
        FAIL = FAIL * 0.05 * 4 ^ (FAIL * 0.5)
        -- check failures
        if FAIL > 0 then
            fail_counter = fail_counter + passed

            if fail_counter > check_time then
                fail_counter = 0
                check_time = math.random(15, 30)

                -- random failures
                if failure_level >= 2 then -- LOW retains causal damage only.
                    if get(diss_fail) ~= 1 then
                        set(diss_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(nvu_fail) ~= 1 then
                        set(nvu_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(radar_fail) ~= 1 then
                        set(radar_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(rsbn_fail) ~= 1 then
                        set(rsbn_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(taws_fail) ~= 1 then
                        set(taws_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end

                    if get(acs1_fail) ~= 1 then
                        set(acs1_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(acs2_fail) ~= 1 then
                        set(acs2_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(acs3_fail) ~= 1 then
                        set(acs3_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end

                    if get(agr_fail) ~= 1 then
                        set(agr_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(bkk_fail) ~= 1 then
                        set(bkk_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end

                    if get(pitot1) ~= 1 then
                        set(pitot1, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(pitot2) ~= 1 then
                        set(pitot2, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(static1) ~= 1 then
                        set(static1, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(static2) ~= 1 then
                        set(static2, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end

                    if get(mgv_fail) ~= 1 then
                        set(mgv_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(rv1_fail) ~= 1 then
                        set(rv1_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(rv2_fail) ~= 1 then
                        set(rv2_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(AOA) ~= 1 then
                        set(AOA, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end
                    if get(uvid15_fail) ~= 1 then
                        set(uvid15_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1)
                    end

                    if get(rel_ss_alt) ~= 6 then
                        set(rel_ss_alt, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6)
                    end
                    if get(rel_cop_alt) ~= 6 then
                        set(rel_cop_alt, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6)
                    end
                    if get(rel_ss_tsi) ~= 6 then
                        set(rel_ss_tsi, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6)
                    end

                    if get(rel_adc_comp) ~= 6 then
                        set(rel_adc_comp, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6)
                    end
                    if get(rel_ss_ahz) ~= 6 then
                        set(rel_ss_ahz, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6)
                    end
                    if get(rel_cop_ahz) ~= 6 then
                        set(rel_cop_ahz, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6)
                    end
                    if get(rel_stall_warn) ~= 6 then
                        set(rel_stall_warn, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6)
                    end
                    if get(rel_ss_vvi) ~= 6 then
                        set(rel_ss_vvi, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6)
                    end
                    if get(rel_cop_vvi) ~= 6 then
                        set(rel_cop_vvi, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6)
                    end
                end
            end

        -- dependent failures
        else
            -- no failures enabled
            fail_counter = 0

            set(diss_fail, 0)
            set(nvu_fail, 0)
            set(radar_fail, 0)
            set(rsbn_fail, 0)
            set(taws_fail, 0)

            set(acs1_fail, 0)
            set(acs2_fail, 0)
            set(acs3_fail, 0)

            set(agr_fail, 0)
            set(bkk_fail, 0)

            set(pitot1, 0)
            set(pitot2, 0)
            set(static1, 0)
            set(static2, 0)

            set(mgv_fail, 0)
            set(rv1_fail, 0)
            set(rv2_fail, 0)
            set(AOA, 0)
            set(uvid15_fail, 0)

            set(rel_ss_alt, 0)
            set(rel_cop_alt, 0)
            set(rel_ss_tsi, 0)

            set(rel_adc_comp, 0)
            set(rel_ss_ahz, 0)
            set(rel_cop_ahz, 0)
            set(rel_stall_warn, 0)
            set(rel_ss_vvi, 0)
            set(rel_cop_vvi, 0)
        end
    end
end
