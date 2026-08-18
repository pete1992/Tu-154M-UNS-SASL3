-- achs1.lua
-- ACHS-1 clock, flight timer and chronograph logic.

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"utc_time", "sim/time/zulu_time_sec", globalPropertyf},
    {"sim_run_time", "sim/time/total_running_time_sec", globalPropertyf},
    {"needle_hours_1", "tu154/custom/gauges/acs1/needle_hours", globalPropertyf},
    {"needle_mins_1", "tu154/custom/gauges/acs1/needle_mins", globalPropertyf},
    {"flight_timer_hours_1", "tu154/custom/gauges/acs1/flight_timer_hours", globalPropertyf},
    {"flight_timer_mins_1", "tu154/custom/gauges/acs1/flight_timer_mins", globalPropertyf},
    {"stopwatch_mins_1", "tu154/custom/gauges/acs1/stopwatch_mins", globalPropertyf},
    {"needle_secs_1", "tu154/custom/gauges/acs1/needle_secs", globalPropertyf},
    {"LK1", "tu154/custom/gauges/acs1/left_knob_press", globalPropertyi},
    {"RK1", "tu154/custom/gauges/acs1/right_knob_press", globalPropertyi},
    {"flag_pos_1", "tu154/custom/gauges/acs1/flag_pos", globalPropertyi},
    {"needle_hours_2", "tu154/custom/gauges/acs2/needle_hours", globalPropertyf},
    {"needle_mins_2", "tu154/custom/gauges/acs2/needle_mins", globalPropertyf},
    {"flight_timer_hours_2", "tu154/custom/gauges/acs2/flight_timer_hours", globalPropertyf},
    {"flight_timer_mins_2", "tu154/custom/gauges/acs2/flight_timer_mins", globalPropertyf},
    {"stopwatch_mins_2", "tu154/custom/gauges/acs2/stopwatch_mins", globalPropertyf},
    {"needle_secs_2", "tu154/custom/gauges/acs2/needle_secs", globalPropertyf},
    {"LK2", "tu154/custom/gauges/acs2/left_knob_press", globalPropertyi},
    {"RK2", "tu154/custom/gauges/acs2/right_knob_press", globalPropertyi},
    {"flag_pos_2", "tu154/custom/gauges/acs2/flag_pos", globalPropertyi},
    {"needle_hours_3", "tu154/custom/gauges/acs3/needle_hours", globalPropertyf},
    {"needle_mins_3", "tu154/custom/gauges/acs3/needle_mins", globalPropertyf},
    {"flight_timer_hours_3", "tu154/custom/gauges/acs3/flight_timer_hours", globalPropertyf},
    {"flight_timer_mins_3", "tu154/custom/gauges/acs3/flight_timer_mins", globalPropertyf},
    {"stopwatch_mins_3", "tu154/custom/gauges/acs3/stopwatch_mins", globalPropertyf},
    {"needle_secs_3", "tu154/custom/gauges/acs3/needle_secs", globalPropertyf},
    {"LK3", "tu154/custom/gauges/acs3/left_knob_press", globalPropertyi},
    {"RK3", "tu154/custom/gauges/acs3/right_knob_press", globalPropertyi},
    {"flag_pos_3", "tu154/custom/gauges/acs3/flag_pos", globalPropertyi},
    {"failures_enabled", "tu154/custom/failures/failures_enabled", globalPropertyi},
    {"acs1_fail", "tu154/custom/failures/acs1_fail", globalPropertyi},
    {"acs2_fail", "tu154/custom/failures/acs2_fail", globalPropertyi},
    {"acs3_fail", "tu154/custom/failures/acs3_fail", globalPropertyi},
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

local btn_click = sasl.al.loadSample("Custom Sounds/acs_btn.wav")

-- Chronograph state.
local sec_mode_1 = 0
local sec_mode_2 = 0
local sec_mode_3 = 0

local chrono_sec_angle_1 = 0
local chrono_sec_angle_2 = 0
local chrono_sec_angle_3 = 0

local chrono_min_angle_1 = 0
local chrono_min_angle_2 = 0
local chrono_min_angle_3 = 0

local sec_time_1 = 0
local sec_time_2 = 0
local sec_time_3 = 0

local start_sec_1 = 0
local start_sec_2 = 0
local start_sec_3 = 0

-- Flight timer state.
local flight_mode_1 = 0
local flight_mode_2 = 0
local flight_mode_3 = 0

local flight_time_1 = 0
local flight_time_2 = 0
local flight_time_3 = 0

local flight_hour_angle_1 = 0
local flight_hour_angle_2 = 0
local flight_hour_angle_3 = 0

local flight_min_angle_1 = 0
local flight_min_angle_2 = 0
local flight_min_angle_3 = 0

local start_flight_1 = 0
local start_flight_2 = 0
local start_flight_3 = 0

-- Individual button states are required so one pressed button can be
-- replaced by another without losing the second rising edge.
local LK1_last = get(LK1)
local RK1_last = get(RK1)
local LK2_last = get(LK2)
local RK2_last = get(RK2)
local LK3_last = get(LK3)
local RK3_last = get(RK3)

local function nextMode(mode)
    mode = mode + 1

    if mode > 2 then
        mode = 0
    end

    return mode
end

local function knob_work()
    local sim_time = get(sim_run_time)

    local lk1 = get(LK1)
    local rk1 = get(RK1)
    local lk2 = get(LK2)
    local rk2 = get(RK2)
    local lk3 = get(LK3)
    local rk3 = get(RK3)

    local clicked = false

    if lk1 == 1 and LK1_last ~= 1 then
        flight_mode_1 = nextMode(flight_mode_1)
        start_flight_1 = sim_time
        clicked = true
    end

    if rk1 == 1 and RK1_last ~= 1 then
        sec_mode_1 = nextMode(sec_mode_1)
        start_sec_1 = sim_time
        clicked = true
    end

    if lk2 == 1 and LK2_last ~= 1 then
        flight_mode_2 = nextMode(flight_mode_2)
        start_flight_2 = sim_time
        clicked = true
    end

    if rk2 == 1 and RK2_last ~= 1 then
        sec_mode_2 = nextMode(sec_mode_2)
        start_sec_2 = sim_time
        clicked = true
    end

    if lk3 == 1 and LK3_last ~= 1 then
        flight_mode_3 = nextMode(flight_mode_3)
        start_flight_3 = sim_time
        clicked = true
    end

    if rk3 == 1 and RK3_last ~= 1 then
        sec_mode_3 = nextMode(sec_mode_3)
        start_sec_3 = sim_time
        clicked = true
    end

    if clicked then
        sasl.al.playSample(btn_click, false)
    end

    LK1_last = lk1
    RK1_last = rk1
    LK2_last = lk2
    RK2_last = rk2
    LK3_last = lk3
    RK3_last = rk3
end

function update()
    knob_work()

    local sim_time = get(sim_run_time)
    local main_time = get(utc_time)

    local fail_enabled = get(failures_enabled)
    local fail_1 = get(acs1_fail)
    local fail_2 = get(acs2_fail)
    local fail_3 = get(acs3_fail)

    local MASTER = get(ismaster) ~= 1

    -- Main UTC clock.
    local main_sec_angle = main_time * 360 / 60
    local main_min_angle = main_sec_angle / 60
    local main_hour_angle = main_min_angle / 12

    if fail_enabled * fail_1 == 0 then
        set(needle_hours_1, main_hour_angle)
        set(needle_mins_1, main_min_angle)
    end

    if fail_enabled * fail_2 == 0 then
        set(needle_hours_2, main_hour_angle)
        set(needle_mins_2, main_min_angle)
    end

    if fail_enabled * fail_3 == 0 then
        set(needle_hours_3, main_hour_angle)
        set(needle_mins_3, main_min_angle)
    end

    if MASTER then
        -- Chronograph 1.
        if sec_mode_1 == 0 then
            sec_time_1 = 0
            chrono_min_angle_1 = 0
            chrono_sec_angle_1 = 0
        elseif sec_mode_1 == 1 then
            sec_time_1 = sim_time - start_sec_1
            sec_time_1 = math.floor(sec_time_1 * 5) / 5

            chrono_min_angle_1 = sec_time_1 * 360 / (60 * 60)
            chrono_sec_angle_1 = chrono_min_angle_1 * 60
        else
            chrono_min_angle_1 = sec_time_1 * 360 / (60 * 60)
            chrono_sec_angle_1 = chrono_min_angle_1 * 60
        end

        if fail_enabled * fail_1 == 0 then
            set(needle_secs_1, chrono_sec_angle_1)
            set(stopwatch_mins_1, chrono_min_angle_1)
        end

        -- Chronograph 2.
        if sec_mode_2 == 0 then
            sec_time_2 = 0
            chrono_min_angle_2 = 0
            chrono_sec_angle_2 = 0
        elseif sec_mode_2 == 1 then
            sec_time_2 = sim_time - start_sec_2
            sec_time_2 = math.floor(sec_time_2 * 5) / 5

            chrono_min_angle_2 = sec_time_2 * 360 / (60 * 60)
            chrono_sec_angle_2 = chrono_min_angle_2 * 60
        else
            chrono_min_angle_2 = sec_time_2 * 360 / (60 * 60)
            chrono_sec_angle_2 = chrono_min_angle_2 * 60
        end

        if fail_enabled * fail_2 == 0 then
            set(needle_secs_2, chrono_sec_angle_2)
            set(stopwatch_mins_2, chrono_min_angle_2)
        end

        -- Chronograph 3.
        if sec_mode_3 == 0 then
            sec_time_3 = 0
            chrono_min_angle_3 = 0
            chrono_sec_angle_3 = 0
        elseif sec_mode_3 == 1 then
            sec_time_3 = sim_time - start_sec_3
            sec_time_3 = math.floor(sec_time_3 * 5) / 5

            chrono_min_angle_3 = sec_time_3 * 360 / (60 * 60)
            chrono_sec_angle_3 = chrono_min_angle_3 * 60
        else
            chrono_min_angle_3 = sec_time_3 * 360 / (60 * 60)
            chrono_sec_angle_3 = chrono_min_angle_3 * 60
        end

        if fail_enabled * fail_3 == 0 then
            set(needle_secs_3, chrono_sec_angle_3)
            set(stopwatch_mins_3, chrono_min_angle_3)
        end

        -- Flight timer 1.
        if flight_mode_1 == 0 then
            flight_time_1 = 0
            flight_hour_angle_1 = 0
            flight_min_angle_1 = 0
            set(flag_pos_1, -1)
        elseif flight_mode_1 == 1 then
            flight_time_1 = sim_time - start_flight_1
            flight_hour_angle_1 = flight_time_1 * 360 / (60 * 60 * 12)
            flight_min_angle_1 = flight_hour_angle_1 * 12
            set(flag_pos_1, 1)
        else
            flight_hour_angle_1 = flight_time_1 * 360 / (60 * 60 * 12)
            flight_min_angle_1 = flight_hour_angle_1 * 12
            set(flag_pos_1, 0)
        end

        if fail_enabled * fail_1 == 0 then
            set(flight_timer_mins_1, flight_min_angle_1)
            set(flight_timer_hours_1, flight_hour_angle_1)
        end

        -- Flight timer 2.
        if flight_mode_2 == 0 then
            flight_time_2 = 0
            flight_hour_angle_2 = 0
            flight_min_angle_2 = 0
            set(flag_pos_2, -1)
        elseif flight_mode_2 == 1 then
            flight_time_2 = sim_time - start_flight_2
            flight_hour_angle_2 = flight_time_2 * 360 / (60 * 60 * 12)
            flight_min_angle_2 = flight_hour_angle_2 * 12
            set(flag_pos_2, 1)
        else
            flight_hour_angle_2 = flight_time_2 * 360 / (60 * 60 * 12)
            flight_min_angle_2 = flight_hour_angle_2 * 12
            set(flag_pos_2, 0)
        end

        if fail_enabled * fail_2 == 0 then
            set(flight_timer_mins_2, flight_min_angle_2)
            set(flight_timer_hours_2, flight_hour_angle_2)
        end

        -- Flight timer 3.
        if flight_mode_3 == 0 then
            flight_time_3 = 0
            flight_hour_angle_3 = 0
            flight_min_angle_3 = 0
            set(flag_pos_3, -1)
        elseif flight_mode_3 == 1 then
            flight_time_3 = sim_time - start_flight_3
            flight_hour_angle_3 = flight_time_3 * 360 / (60 * 60 * 12)
            flight_min_angle_3 = flight_hour_angle_3 * 12
            set(flag_pos_3, 1)
        else
            flight_hour_angle_3 = flight_time_3 * 360 / (60 * 60 * 12)
            flight_min_angle_3 = flight_hour_angle_3 * 12
            set(flag_pos_3, 0)
        end

        if fail_enabled * fail_3 == 0 then
            set(flight_timer_mins_3, flight_min_angle_3)
            set(flight_timer_hours_3, flight_hour_angle_3)
        end
    end
end
