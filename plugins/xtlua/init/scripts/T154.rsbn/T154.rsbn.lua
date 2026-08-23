-- T154.rsbn.lua

function tu154_channel_change_DRhandler() end
function tu154_channel_DRhandler() end

function deferred_dataref(name,type,notifier)
    print("Deffered dataref: "..name)
    dref=XLuaCreateDataRef(name,type,"yes",notifier)
    return wrap_dref_any(dref,type)
end

-- Existing X-Plane and Tu-154 datarefs ---------------------------------
local datarefs = {
    {"simDR_rsbn_azi","tu154/custom/rsbn/azimuth"},
    {"simDR_passed","sim/operation/misc/frame_rate_period"},
    {"simDR_rsbn_10","tu154/custom/buttons/ovhd/rsbn_ch_ten"},
    {"simDR_rsbn_1","tu154/custom/buttons/ovhd/rsbn_ch_one"},
    {"simDR_real_dist","tu154/custom/rsbn/distance"},
    {"simDR_rsbn_power","tu154/custom/radio/rsbn_cc"},
    {"simDR_control_azim","tu154/custom/buttons/ovhd/rsbn_control_azimuth"},
    {"simDR_control_dist","tu154/custom/buttons/ovhd/rsbn_control_distance"},
    {"simDR_groundspeed","sim/flightmodel/position/groundspeed"},
}

local env = getfenv(1)
for _,dataref in ipairs(datarefs) do
    env[dataref[1]] = find_dataref(dataref[2])
end


-- Datarefs owned by this xTLua module ----------------------------------
local deferred_datarefs = {
    {"tu154_real_azimuth","tu154/custom/rsbn/real_azimuth","number"},
    {"no_signal","tu154/custom/rsbn/no_signal","number"},
    {"rsbn_channel","tu154/custom/rsbn/channel","number",tu154_channel_DRhandler},
    {"channel_change","tu154/custom/rsbn/channel_change","number",tu154_channel_change_DRhandler},
}

for _,dataref in ipairs(deferred_datarefs) do
    env[dataref[1]] = deferred_dataref(dataref[2],dataref[3],dataref[4])
end


-- RSBN configuration ----------------------------------------------------
-- The Tu-154 RSBN-2 family uses channels 1 through 40.
-- Channel 00 is retained as the control/test position used by this model.
local RSBN_CHANNEL_MIN = 0
local RSBN_CHANNEL_MAX = 40

-- Channel selector repeat timing.
local CHANNEL_REPEAT_DELAY = 0.30
local CHANNEL_REPEAT_INTERVAL = 0.12
local CHANNEL_FAST_REPEAT_START = 2.00
local CHANNEL_FAST_REPEAT_INTERVAL = 0.06

-- Signal validation timing.
local SIGNAL_SAMPLE_INTERVAL = 0.50
local SIGNAL_STALE_TIME = 20.0
local SIGNAL_RECOVERY_TIME = 1.0

-- Movement and change thresholds used only for stale-signal detection.
-- The source RSBN values historically freeze when reception is lost.
local MIN_GROUND_SPEED = 5.0
local DIST_CHANGE_EPSILON = 0.001
local AZI_CHANGE_EPSILON = 0.01


-- Internal state --------------------------------------------------------
local left_next_repeat = CHANNEL_REPEAT_DELAY
local right_next_repeat = CHANNEL_REPEAT_DELAY

local last_channel = 0

local signal_sample_timer = 0
local signal_stale_timer = 0
local signal_recovery_timer = 0
local signal_acquisition_timer = 0

local signal_last_dist = 0
local signal_last_azi = 0

local signal_initialized = false
local signal_acquiring = false
local rsbn_was_powered = false


-- Utility functions -----------------------------------------------------
local function clamp(value,min_value,max_value)
    if value < min_value then
        return min_value
    elseif value > max_value then
        return max_value
    end
    return value
end


local function normalize_channel(value)
    local rounded = math.floor(value + 0.5)
    return clamp(rounded,RSBN_CHANNEL_MIN,RSBN_CHANNEL_MAX)
end


local function normalize_azimuth(value)
    return ((value % 360) + 360) % 360
end


local function azimuth_difference(a,b)
    local delta = math.abs(a - b) % 360
    if delta > 180 then
        delta = 360 - delta
    end
    return delta
end


local function capture_signal_sample()
    signal_last_dist = simDR_real_dist
    signal_last_azi = tu154_real_azimuth
    signal_initialized = true
end


local function reset_signal_timers()
    signal_sample_timer = 0
    signal_stale_timer = 0
    signal_recovery_timer = 0
    signal_acquisition_timer = 0
end


local function begin_channel_acquisition()
    reset_signal_timers()
    capture_signal_sample()

    if rsbn_channel > 0 then
        signal_acquiring = true
        no_signal = 0
    else
        signal_acquiring = false
    end
end


local function set_channel(value,direction)
    local new_channel = normalize_channel(value)

    if new_channel ~= rsbn_channel then
        rsbn_channel = new_channel
        last_channel = new_channel
        begin_channel_acquisition()
    end

    if direction ~= nil then
        channel_change = direction
    end
end


local function step_channel(direction)
    set_channel(rsbn_channel + direction,direction)
end


local function handle_channel_repeat(direction,duration,next_repeat)
    while duration >= next_repeat do
        step_channel(direction)

        if next_repeat >= CHANNEL_FAST_REPEAT_START then
            next_repeat = next_repeat + CHANNEL_FAST_REPEAT_INTERVAL
        else
            next_repeat = next_repeat + CHANNEL_REPEAT_INTERVAL
        end
    end

    return next_repeat
end


-- RSBN channel selector commands ---------------------------------------
function rsbn_l_CMDhandler(phase,duration)
    if phase == 0 then
        step_channel(-1)
        left_next_repeat = CHANNEL_REPEAT_DELAY

    elseif phase == 1 then
        left_next_repeat = handle_channel_repeat(-1,duration,left_next_repeat)

    elseif phase == 2 then
        channel_change = 0
        left_next_repeat = CHANNEL_REPEAT_DELAY
    end
end


function rsbn_r_CMDhandler(phase,duration)
    if phase == 0 then
        step_channel(1)
        right_next_repeat = CHANNEL_REPEAT_DELAY

    elseif phase == 1 then
        right_next_repeat = handle_channel_repeat(1,duration,right_next_repeat)

    elseif phase == 2 then
        channel_change = 0
        right_next_repeat = CHANNEL_REPEAT_DELAY
    end
end


rsbn_cmnd_l = create_command("rsbn/channel_l","RSBN CH L",rsbn_l_CMDhandler)
rsbn_cmnd_r = create_command("rsbn/channel_r","RSBN CH R",rsbn_r_CMDhandler)


-- Channel display and azimuth normalization -----------------------------
function tu154_rsbn()
    tu154_real_azimuth = normalize_azimuth(simDR_rsbn_azi)

    -- Sanitize external writes to the writable channel dataref.
    local normalized_channel = normalize_channel(rsbn_channel)

    if normalized_channel ~= rsbn_channel then
        rsbn_channel = normalized_channel
    end

    -- Detect channel changes made outside the two xTLua commands.
    if normalized_channel ~= last_channel then
        last_channel = normalized_channel
        begin_channel_acquisition()
    end

    simDR_rsbn_10 = math.floor(normalized_channel / 10)
    simDR_rsbn_1 = normalized_channel - (simDR_rsbn_10 * 10)
end


-- Signal validation -----------------------------------------------------
function rsbn_reset()
    local powered = simDR_rsbn_power > 0

    -- An unpowered RSBN cannot provide a valid navigation signal.
    if not powered then
        no_signal = 1
        rsbn_was_powered = false
        signal_initialized = false
        signal_acquiring = false
        reset_signal_timers()
        return
    end

    -- On power restoration, start with a clean sample but do not declare
    -- a failure just because the aircraft is stationary.
    if not rsbn_was_powered then
        rsbn_was_powered = true
        reset_signal_timers()
        capture_signal_sample()
        signal_acquiring = false

        if rsbn_channel > 0 then
            no_signal = 0
        end
    end

    -- Channel 00 is the original control/test position.
    if rsbn_channel == 0 then
        signal_acquiring = false
        reset_signal_timers()
        capture_signal_sample()

        if simDR_control_azim < 1 and simDR_control_dist < 1 then
            no_signal = 1
        else
            no_signal = 0
        end

        return
    end

    if not signal_initialized then
        capture_signal_sample()
    end

    signal_sample_timer = signal_sample_timer + simDR_passed

    if signal_sample_timer < SIGNAL_SAMPLE_INTERVAL then
        return
    end

    local sample_time = signal_sample_timer
    signal_sample_timer = 0

    local dist_delta = math.abs(simDR_real_dist - signal_last_dist)
    local azi_delta = azimuth_difference(tu154_real_azimuth,signal_last_azi)

    local signal_changed =
        dist_delta > DIST_CHANGE_EPSILON or
        azi_delta > AZI_CHANGE_EPSILON

    -- After a channel change, require the selected channel to produce
    -- changed navigation data within the acquisition window.
    if signal_acquiring then
        if signal_changed then
            signal_acquiring = false
            signal_acquisition_timer = 0
            signal_stale_timer = 0
            signal_recovery_timer = 0
            no_signal = 0
        else
            local source_is_zero =
                math.abs(simDR_real_dist) <= DIST_CHANGE_EPSILON and
                math.abs(tu154_real_azimuth) <= AZI_CHANGE_EPSILON

            -- A stationary aircraft can legitimately show constant RSBN data.
            -- Only expire channel acquisition when movement should cause the
            -- received values to change, or when both source values are empty.
            if simDR_groundspeed > MIN_GROUND_SPEED or source_is_zero then
                signal_acquisition_timer = signal_acquisition_timer + sample_time

                if signal_acquisition_timer >= SIGNAL_STALE_TIME then
                    no_signal = 1
                    signal_acquiring = false
                    signal_acquisition_timer = 0
                end
            else
                signal_acquisition_timer = 0
            end
        end

    elseif signal_changed then
        -- Changed navigation data immediately clears the stale timer.
        signal_stale_timer = 0

        -- If reception was previously considered lost, require sustained
        -- activity before restoring the valid-signal state.
        if no_signal > 0 then
            signal_recovery_timer = signal_recovery_timer + sample_time

            if signal_recovery_timer >= SIGNAL_RECOVERY_TIME then
                no_signal = 0
                signal_recovery_timer = 0
            end
        else
            signal_recovery_timer = 0
        end

    else
        signal_recovery_timer = 0

        -- A stationary aircraft can legitimately keep the same azimuth and
        -- distance. Only use frozen values as a loss indication while the
        -- aircraft is moving, or when both source values are effectively zero.
        local source_is_zero =
            math.abs(simDR_real_dist) <= DIST_CHANGE_EPSILON and
            math.abs(tu154_real_azimuth) <= AZI_CHANGE_EPSILON

        if simDR_groundspeed > MIN_GROUND_SPEED or source_is_zero then
            signal_stale_timer = signal_stale_timer + sample_time

            if signal_stale_timer >= SIGNAL_STALE_TIME then
                no_signal = 1
                signal_stale_timer = SIGNAL_STALE_TIME
            end
        else
            signal_stale_timer = 0
        end
    end

    capture_signal_sample()
end


function after_physics()
    tu154_rsbn()
    rsbn_reset()
end
