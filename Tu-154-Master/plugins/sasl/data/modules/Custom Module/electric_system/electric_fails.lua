-- electric_fails.lua
local function defineProps(defs)
    for _, d in ipairs(defs) do
        _G[d[1]] = d[3](d[2])
    end
end

-- Electrical system failures and sources
defineProps({
    -- Battery failures
    {"bat_fail_1", "tu154/custom/failures/bat_1_fail", globalPropertyi}, -- Battery 1 failure
    {"bat_fail_2", "tu154/custom/failures/bat_2_fail", globalPropertyi}, -- Battery 2 failure
    {"bat_fail_3", "tu154/custom/failures/bat_3_fail", globalPropertyi}, -- Battery 3 failure
    {"bat_fail_4", "tu154/custom/failures/bat_4_fail", globalPropertyi}, -- Battery 4 failure
    -- Battery thermal runaway
    {"bat_1_kz", "tu154/custom/failures/bat_1_kz", globalPropertyi}, -- Battery 1 thermal runaway
    {"bat_2_kz", "tu154/custom/failures/bat_2_kz", globalPropertyi}, -- Battery 2 thermal runaway
    {"bat_3_kz", "tu154/custom/failures/bat_3_kz", globalPropertyi}, -- Battery 3 thermal runaway
    {"bat_4_kz", "tu154/custom/failures/bat_4_kz", globalPropertyi}, -- Battery 4 thermal runaway
    -- VU (converter) failures
    {"vu1_fail", "tu154/custom/failures/vu1_fail", globalPropertyi}, -- VU1 failure
    {"vu2_fail", "tu154/custom/failures/vu2_fail", globalPropertyi}, -- VU2 failure
    {"vu3_fail", "tu154/custom/failures/vu3_fail", globalPropertyi}, -- VU3 (reserve) failure
    -- Transformer and inverter failures
    {"tr1_fail", "tu154/custom/failures/tr1_fail", globalPropertyi}, -- TR1 failure
    {"tr2_fail", "tu154/custom/failures/tr2_fail", globalPropertyi}, -- TR2 failure
    {"pts250_1_fail", "tu154/custom/failures/pts250_1_fail", globalPropertyi}, -- PTS250 1 failure
    {"pts250_2_fail", "tu154/custom/failures/pts250_2_fail", globalPropertyi}, -- PTS250 2 failure
    {"inv115_fail", "tu154/custom/failures/inv115_fail", globalPropertyf}, -- Inverter 115V failure
    -- Sim generator failures
    {"sim_gen1_fail", "sim/operation/failures/rel_genera0", globalPropertyi}, -- Sim generator 1 failure
    {"sim_gen2_fail", "sim/operation/failures/rel_genera1", globalPropertyi}, -- Sim generator 2 failure
    {"sim_gen3_fail", "sim/operation/failures/rel_genera2", globalPropertyi}, -- Sim generator 3 failure
    -- Sources and control
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf}, -- Simulation frame time
    {"failures_enabled", "tu154/custom/failures/failures_enabled", globalPropertyi}, -- Failures enabled flag
    -- VU converter amps
    {"vu1_amp", "tu154/custom/elec/vu1_amp", globalPropertyf}, -- VU1 current (A)
    {"vu2_amp", "tu154/custom/elec/vu2_amp", globalPropertyf}, -- VU2 current (A)
    {"vu3_amp", "tu154/custom/elec/vu_res_amp", globalPropertyf}, -- VU3 (reserve) current (A)
})

-- Smart Copilot
defineProperty("ismaster", globalPropertyf("scp/api/ismaster")) -- Master. 0 = plugin not found, 1 = slave 2 = master
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1")) -- Have control. 0 = plugin not found, 1 = no control 2 = has control

local function bool2int(v) return v and 1 or 0 end

-- timers for VU failures. maximum - 180 sec.
local vu_timer_1 = 0
local vu_timer_2 = 0
local vu_timer_3 = 0

local fail_counter = 0
local check_time = math.random(15, 30)

function update()
    local passed = get(frame_time)
    local MASTER = get(ismaster) ~= 1

    if MASTER then
        local FAIL = get(failures_enabled)
        FAIL = FAIL * 0.05 * 4 ^ (FAIL * 0.5)
        
        -- check failures
        if FAIL > 0 then
            fail_counter = fail_counter + passed
            if fail_counter > check_time then
                fail_counter = 0
                check_time = math.random(15, 30)
                -- random failures
                if get(bat_fail_1) ~= 1 then set(bat_fail_1, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(bat_fail_2) ~= 1 then set(bat_fail_2, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(bat_fail_3) ~= 1 then set(bat_fail_3, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(bat_fail_4) ~= 1 then set(bat_fail_4, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end

                if get(bat_1_kz) ~= 1 then set(bat_1_kz, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(bat_2_kz) ~= 1 then set(bat_2_kz, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(bat_3_kz) ~= 1 then set(bat_3_kz, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(bat_4_kz) ~= 1 then set(bat_4_kz, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end

                if get(vu1_fail) ~= 1 then set(vu1_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(vu2_fail) ~= 1 then set(vu2_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(vu3_fail) ~= 1 then set(vu3_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end

                if get(tr1_fail) ~= 1 then set(tr1_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(tr2_fail) ~= 1 then set(tr2_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(pts250_1_fail) ~= 1 then set(pts250_1_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(pts250_2_fail) ~= 1 then set(pts250_2_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(inv115_fail) ~= 1 then set(inv115_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end

                if get(sim_gen1_fail) ~= 1 then set(sim_gen1_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(sim_gen2_fail) ~= 1 then set(sim_gen2_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
                if get(sim_gen3_fail) ~= 1 then set(sim_gen3_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3)) end
            end

            -- Dependent VU failure logic (time overcurrent protection)
            -- Over 500A for 3 minutes (180s) will burn the VU; over 600A will burn in 5s
            local vu_amp_1 = get(vu1_amp)
            if vu_amp_1 > 500 then
                vu_timer_1 = vu_timer_1 + passed * (vu_amp_1 - 297.5) * 0.4
            elseif vu_timer_1 > 0 then
                vu_timer_1 = vu_timer_1 - passed * 3
            end
            if vu_timer_1 > 180 then set(vu1_fail, 1) end

            local vu_amp_2 = get(vu2_amp)
            if vu_amp_2 > 500 then
                vu_timer_2 = vu_timer_2 + passed * (vu_amp_2 - 297.5) * 0.4
            elseif vu_timer_2 > 0 then
                vu_timer_2 = vu_timer_2 - passed * 3
            end
            if vu_timer_2 > 180 then set(vu2_fail, 1) end

            local vu_amp_3 = get(vu3_amp)
            if vu_amp_3 > 500 then
                vu_timer_3 = vu_timer_3 + passed * (vu_amp_3 - 297.5) * 0.4
            elseif vu_timer_3 > 0 then
                vu_timer_3 = vu_timer_3 - passed * 3
            end
            if vu_timer_3 > 180 then set(vu3_fail, 1) end

        else
            -- No failures enabled, reset all states
            fail_counter = 0
            set(bat_fail_1, 0)
            set(bat_fail_2, 0)
            set(bat_fail_3, 0)
            set(bat_fail_4, 0)

            set(bat_1_kz, 0)
            set(bat_2_kz, 0)
            set(bat_3_kz, 0)
            set(bat_4_kz, 0)

            set(vu1_fail, 0)
            set(vu2_fail, 0)
            set(vu3_fail, 0)

            set(tr1_fail, 0)
            set(tr2_fail, 0)
            set(pts250_1_fail, 0)
            set(pts250_2_fail, 0)
            set(inv115_fail, 0)

            set(sim_gen1_fail, 0)
            set(sim_gen2_fail, 0)
            set(sim_gen3_fail, 0)
        end
    end
end
