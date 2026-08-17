-- absu_fails.lua (refactored: bulk datarefs, helpers, MASTER logic)

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------
local function bool2int(v) return v and 1 or 0 end

-----------------------------------------------------------------------
-- DataRefs (bulk)
-----------------------------------------------------------------------
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    {"absu_ra56_roll_fail", "tu154/custom/failures/absu_ra56_roll_fail", globalPropertyi},
    {"absu_ra56_pitch_fail","tu154/custom/failures/absu_ra56_pitch_fail", globalPropertyi},
    {"absu_ra56_yaw_fail",  "tu154/custom/failures/absu_ra56_yaw_fail",   globalPropertyi},
    {"absu_at1_fail",       "tu154/custom/failures/absu_at1_fail",         globalPropertyi},
    {"absu_at2_fail",       "tu154/custom/failures/absu_at2_fail",         globalPropertyi},
    {"absu_damp_roll_fail", "tu154/custom/failures/absu_damp_roll_fail",   globalPropertyi},
    {"absu_damp_pitch_fail","tu154/custom/failures/absu_damp_pitch_fail",  globalPropertyi},
    {"absu_damp_yaw_fail",  "tu154/custom/failures/absu_damp_yaw_fail",    globalPropertyi},
    {"absu_contr_roll_fail","tu154/custom/failures/absu_contr_roll_fail",  globalPropertyi},
    {"absu_contr_pitch_fail","tu154/custom/failures/absu_contr_pitch_fail",globalPropertyi},
    {"absu_calc_toga_fail", "tu154/custom/failures/absu_calc_toga_fail",   globalPropertyi},
    {"absu_calc_roll_fail", "tu154/custom/failures/absu_calc_roll_fail",   globalPropertyi},
    {"absu_calc_pitch_fail","tu154/custom/failures/absu_calc_pitch_fail",  globalPropertyi},
    {"frame_time",          "tu154/custom/time/frame_time",                globalPropertyf},
    {"failures_enabled",    "tu154/custom/failures/failures_enabled",      globalPropertyi},

    -- SmartCopilot
    {"ismaster",            "scp/api/ismaster",                          globalPropertyf},
    {"hascontrol_1",        "scp/api/hascontrol_1",                      globalPropertyf},
})

-----------------------------------------------------------------------
-- State
-----------------------------------------------------------------------
local fail_counter = 0
local check_time = math.random(15, 30)  -- seconds between checks

-----------------------------------------------------------------------
-- Main
-----------------------------------------------------------------------
function update()
    local passed = get(frame_time) or 0
    local MASTER = (get(ismaster) == 1)

    if not MASTER then return end

    local FAIL = get(failures_enabled) or 0
    -- same shaping as original
    FAIL = FAIL * 0.05 * (4 ^ (FAIL * 0.5))

    if FAIL > 0 then
        fail_counter = fail_counter + passed
        if fail_counter > check_time then
            fail_counter = 0
            check_time = math.random(15, 30)

            -- base probability used below mirrors original scaling
            local p = 0.00001 * FAIL * 0.3

            -- AT channels
            if get(absu_at1_fail) ~= 1 then set(absu_at1_fail, bool2int(math.random() < p)) end
            if get(absu_at2_fail) ~= 1 then set(absu_at2_fail, bool2int(math.random() < p)) end

            -- RA56 roll (3-step escalation)
            local roll_1 = bool2int(get(absu_ra56_roll_fail) >= 1)
            local roll_2 = bool2int(get(absu_ra56_roll_fail) >= 2)
            local roll_3 = bool2int(get(absu_ra56_roll_fail) >= 3)
            if roll_1 ~= 1 then
                roll_1 = bool2int(math.random() < p)
            elseif roll_2 ~= 1 then
                roll_2 = bool2int(math.random() < p)
            elseif roll_3 ~= 1 then
                roll_3 = bool2int(math.random() < p)
            end
            set(absu_ra56_roll_fail, roll_1 + roll_2 + roll_3)

            -- RA56 pitch
            local pitch_1 = bool2int(get(absu_ra56_pitch_fail) >= 1)
            local pitch_2 = bool2int(get(absu_ra56_pitch_fail) >= 2)
            local pitch_3 = bool2int(get(absu_ra56_pitch_fail) >= 3)
            if pitch_1 ~= 1 then
                pitch_1 = bool2int(math.random() < p)
            elseif pitch_2 ~= 1 then
                pitch_2 = bool2int(math.random() < p)
            elseif pitch_3 ~= 1 then
                pitch_3 = bool2int(math.random() < p)
            end
            set(absu_ra56_pitch_fail, pitch_1 + pitch_2 + pitch_3)

            -- RA56 yaw
            local yaw_1 = bool2int(get(absu_ra56_yaw_fail) >= 1)
            local yaw_2 = bool2int(get(absu_ra56_yaw_fail) >= 2)
            local yaw_3 = bool2int(get(absu_ra56_yaw_fail) >= 3)
            if yaw_1 ~= 1 then
                yaw_1 = bool2int(math.random() < p)
            elseif yaw_2 ~= 1 then
                yaw_2 = bool2int(math.random() < p)
            elseif yaw_3 ~= 1 then
                yaw_3 = bool2int(math.random() < p)
            end
            set(absu_ra56_yaw_fail, yaw_1 + yaw_2 + yaw_3)

            -- Dampers / control / calculators
            if get(absu_damp_roll_fail)   ~= 1 then set(absu_damp_roll_fail,   bool2int(math.random() < p)) end
            if get(absu_damp_pitch_fail)  ~= 1 then set(absu_damp_pitch_fail,  bool2int(math.random() < p)) end
            if get(absu_damp_yaw_fail)    ~= 1 then set(absu_damp_yaw_fail,    bool2int(math.random() < p)) end
            if get(absu_contr_roll_fail)  ~= 1 then set(absu_contr_roll_fail,  bool2int(math.random() < p)) end
            if get(absu_contr_pitch_fail) ~= 1 then set(absu_contr_pitch_fail, bool2int(math.random() < p)) end
            if get(absu_calc_toga_fail)   ~= 1 then set(absu_calc_toga_fail,   bool2int(math.random() < p)) end
            if get(absu_calc_roll_fail)   ~= 1 then set(absu_calc_roll_fail,   bool2int(math.random() < p)) end
            if get(absu_calc_pitch_fail)  ~= 1 then set(absu_calc_pitch_fail,  bool2int(math.random() < p)) end
        end
    else
        -- reset all failures when disabled
        fail_counter = 0
        set(absu_ra56_roll_fail,   0)
        set(absu_ra56_pitch_fail,  0)
        set(absu_ra56_yaw_fail,    0)
        set(absu_at1_fail,         0)
        set(absu_at2_fail,         0)
        set(absu_damp_roll_fail,   0)
        set(absu_damp_pitch_fail,  0)
        set(absu_damp_yaw_fail,    0)
        set(absu_contr_roll_fail,  0)
        set(absu_contr_pitch_fail, 0)
        set(absu_calc_toga_fail,   0)
        set(absu_calc_roll_fail,   0)
        set(absu_calc_pitch_fail,  0)
    end
end
