-- agr.lua
-- Auxiliary attitude horizon logic.

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"pitch_sim", "sim/flightmodel/position/theta", globalPropertyf},
    {"roll_sim", "sim/flightmodel/position/phi", globalPropertyf},
    {"N1", "sim/flightmodel/engine/ENGN_N2_[1]", globalProperty},
    {"N2", "sim/flightmodel/engine/ENGN_N2_[0]", globalProperty},
    {"N3", "sim/flightmodel/engine/ENGN_N2_[2]", globalProperty},
    {"pitch_corr_hdl", "tu154/custom/gauges/ahz/pitch_corr_C", globalPropertyf},
    {"agr_on", "tu154/custom/switchers/ovhd/agr_on", globalPropertyi},
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus36_volt_pts250_1", "tu154/custom/elec/bus36_volt_pts250_1", globalPropertyf},
    {"agr_fail", "tu154/custom/failures/agr_fail", globalPropertyi},
    {"res_pitch", "tu154/custom/gauges/ahz/pitch_C", globalPropertyf},
    {"res_roll", "tu154/custom/gauges/ahz/roll_C", globalPropertyf},
    {"agr_cc", "tu154/custom/ahz/agr_cc", globalPropertyf},
    {"ahz_flag", "tu154/custom/gauges/ahz/ahz_flag_C", globalPropertyf},
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

local initial_roll_err = 0
local roll_corr = 0
local roll_show = 0
local roll_off = 0

local initial_pitch_err = 0
local pitch_corr = 0
local pitch_show = 0
local pitch_off = 0

local power_roll = 0
local power_pitch = 0

local time_counter = 0
local notLoaded = true

local roll_show_2 = roll_show
local pitch_show_2 = pitch_show


function update()
    local passed = get(frame_time)

    local power =
        get(bus27_volt_left) > 13
        and get(bus36_volt_pts250_1) > 30
        and get(agr_on) == 1
        and get(agr_fail) == 0

    set(agr_cc, bool2int(power))

    time_counter = time_counter + passed

    -- Initialize once after startup. Do not depend on hitting a narrow
    -- frame-time window, because a long frame could skip it entirely.
    if time_counter > 0.3 and notLoaded then
        if get(N1) < 10 and get(N2) < 10 and get(N3) < 10 then
            initial_roll_err = math.random(-30, 30)
            initial_pitch_err = math.random(-30, 30)
        end

        roll_off = math.random(-1, 1)
        pitch_off = math.random(-1, 1)
        notLoaded = false
    end

    -- Store aircraft attitude while the horizon is unpowered.
    if not power then
        power_roll = get(roll_sim)
        power_pitch = get(pitch_sim)
    end

    -- Calculate powered and unpowered initial roll and pitch errors.
    if not power then
        if math.abs(initial_roll_err) < 30 then
            initial_roll_err =
                initial_roll_err + passed * roll_off * 0.1
        end

        if math.abs(initial_pitch_err) < 30 then
            initial_pitch_err =
                initial_pitch_err + passed * pitch_off * 0.1
        end
    else
        if initial_roll_err > 0.1 then
            initial_roll_err = initial_roll_err - passed * 0.3
        elseif initial_roll_err < -0.1 then
            initial_roll_err = initial_roll_err + passed * 0.3
        else
            initial_roll_err = 0
        end

        if initial_pitch_err > 0.1 then
            initial_pitch_err = initial_pitch_err - passed * 0.3
        elseif initial_pitch_err < -0.1 then
            initial_pitch_err = initial_pitch_err + passed * 0.3
        else
            initial_pitch_err = 0
        end

        -- Reset stored power-off attitude and internal corrections.
        if power_roll > 0.05 then
            power_roll = power_roll - passed * 0.1
        elseif power_roll < -0.05 then
            power_roll = power_roll + passed * 0.1
        else
            power_roll = 0
        end

        if power_pitch > 0.05 then
            power_pitch = power_pitch - passed * 0.1
        elseif power_pitch < -0.05 then
            power_pitch = power_pitch + passed * 0.1
        else
            power_pitch = 0
        end

        if roll_corr > 0.05 then
            roll_corr = roll_corr - 0.1 * passed
        elseif roll_corr < -0.05 then
            roll_corr = roll_corr + 0.1 * passed
        else
            roll_corr = 0
        end

        if pitch_corr > 0.05 then
            pitch_corr = pitch_corr - 0.1 * passed
        elseif pitch_corr < -0.05 then
            pitch_corr = pitch_corr + 0.1 * passed
        else
            pitch_corr = 0
        end
    end

    -- Calculate current indicated attitude.
    roll_show =
        get(roll_sim)
        - power_roll
        + initial_roll_err
        - roll_corr

    pitch_show =
        get(pitch_sim)
        - power_pitch
        + initial_pitch_err
        - pitch_corr
        - get(pitch_corr_hdl) * 20

    if pitch_show > 90 then
        pitch_show = 90
    elseif pitch_show < -90 then
        pitch_show = -90
    end

    -- Smooth indication.
    local roll_delta = roll_show - roll_show_2

    if roll_delta > 180 then
        roll_delta = roll_delta - 360
    elseif roll_delta < -180 then
        roll_delta = roll_delta + 360
    end

    roll_show_2 =
        roll_show_2 + roll_delta * passed * 8

    pitch_show_2 =
        pitch_show_2
        + (pitch_show - pitch_show_2) * passed * 8

    -- Show the flag while unpowered or while the gyro is still aligning.
    local flag =
        bool2int(
            not power
            or math.abs(initial_roll_err)
                + math.abs(initial_pitch_err)
                + math.abs(power_roll)
                + math.abs(power_pitch) > 5
        )

    local MASTER = get(ismaster) ~= 1

    if MASTER then
        set(res_pitch, pitch_show_2)
        set(res_roll, roll_show_2)
        set(ahz_flag, flag)
    end
end
