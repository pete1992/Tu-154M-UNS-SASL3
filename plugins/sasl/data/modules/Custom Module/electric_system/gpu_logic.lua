--[[
Changelog
- Grouped all 20 original Dataref bindings through defineProps() while preserving names, paths, constructors, and order.
- Added X-Plane version detection and XP11/XP12-compatible sample playback.
- Split GPU electrical-state ownership from local sound rendering: only SmartCopilot master/no-plugin updates electrical state, while all instances can render synchronized GPU sounds.
- Preserved the existing 4-second GPU start, 10-second stop, 1-second bus connection delay, and 1-second movement-eject delay.
- Preserved the existing 900 A GPU overload threshold.
- Preserved the 27 V control-power requirement for GPU voltage output.
- Cached GPU, bus, groundspeed, camera, and aircraft-position Datarefs per frame where practical.
- Fixed the camera-speed time divisor from min(0.0001, dt) to max(0.0001, dt).
- Preserved the currently unused Doppler coefficient calculation for future sound processing.
- Fixed forced GPU ejection so all six inside/outside GPU samples are stopped.
- Preserved loadSounds() and unloadSounds() legacy helpers.
- Replaced Russian comments with English comments.
]]

-- Hobart 60 kVA GPU logic.

defineProperty("xp_version", globalPropertyi("sim/version/xplane_internal_version"))
local XP11 = get(xp_version) > 120000

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- GPU state and controls
    { "gpu_present", "tu154/custom/anim/gpu_present", globalPropertyi },
    { "gpu_work_anim", "tu154/custom/anim/gpu_work", globalPropertyf },
    { "gpu_volt", "tu154/custom/elec/gpu_volt", globalPropertyf },
    { "gpu_amp", "tu154/custom/elec/gpu_amp", globalPropertyf },
    { "gpu_overload", "tu154/custom/elec/gpu_overload", globalPropertyi },
    { "gpu_on", "tu154/custom/switchers/eng/gpu_on", globalPropertyi },
    { "gpu_work_bus", "tu154/custom/elec/gpu_work", globalPropertyi },

    -- 27 V control-power buses
    { "DC_27_volt1", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "DC_27_volt2", "tu154/custom/elec/bus27_volt_right", globalPropertyf },

    -- Simulation state
    { "GS", "sim/flightmodel/position/groundspeed", globalPropertyf },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },

    -- View state
    { "external_view", "sim/graphics/view/view_is_external", globalPropertyi },

    -- Aircraft position
    { "local_x", "sim/flightmodel/position/local_x", globalPropertyf },
    { "local_y", "sim/flightmodel/position/local_y", globalPropertyf },
    { "local_z", "sim/flightmodel/position/local_z", globalPropertyf },

    -- Camera position
    { "view_x", "sim/graphics/view/view_x", globalPropertyf },
    { "view_y", "sim/graphics/view/view_y", globalPropertyf },
    { "view_z", "sim/graphics/view/view_z", globalPropertyf },

    -- SmartCopilot
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf },
})

local GPU_START_RATE = 0.25       -- 4 seconds from stopped to running
local GPU_STOP_RATE = 0.10        -- 10 seconds from running to stopped
local GPU_CONNECT_DELAY = 1.0
local GPU_EJECT_DELAY = 1.0
local GPU_EJECT_GS = 0.1
local GPU_OUTPUT_VOLTAGE = 115
local GPU_CONTROL_VOLTAGE = 13
local GPU_OVERLOAD_LIMIT = 900

local gpu_start_out = sasl.al.loadSample("Custom Sounds/gpu_start_out.wav")
local gpu_run_out = sasl.al.loadSample("Custom Sounds/gpu_run_out.wav")
local gpu_stop_out = sasl.al.loadSample("Custom Sounds/gpu_stop_out.wav")

local gpu_start_inn = sasl.al.loadSample("Custom Sounds/gpu_start_inn.wav")
local gpu_run_inn = sasl.al.loadSample("Custom Sounds/gpu_run_inn.wav")
local gpu_stop_inn = sasl.al.loadSample("Custom Sounds/gpu_stop_inn.wav")

local STATE = {
    work_timer = 0,
    connect_timer = 0,
    eject_timer = 0,
    last_distance = 0,
    sounds_loaded = true,
}

local function playGpuSample(sample, looped)
    if XP11 then
        sasl.al.playSample(sample, looped and 1 or 0)
    else
        sasl.al.playSample(sample, looped)
    end
end

local function stopAllGpuSamples()
    sasl.al.stopSample(gpu_start_out)
    sasl.al.stopSample(gpu_run_out)
    sasl.al.stopSample(gpu_stop_out)
    sasl.al.stopSample(gpu_start_inn)
    sasl.al.stopSample(gpu_run_inn)
    sasl.al.stopSample(gpu_stop_inn)
end

local function loadSounds()
    gpu_start_out = sasl.al.loadSample("Custom Sounds/gpu_start_out.wav")
    gpu_run_out = sasl.al.loadSample("Custom Sounds/gpu_run_out.wav")
    gpu_stop_out = sasl.al.loadSample("Custom Sounds/gpu_stop_out.wav")
    gpu_start_inn = sasl.al.loadSample("Custom Sounds/gpu_start_inn.wav")
    gpu_run_inn = sasl.al.loadSample("Custom Sounds/gpu_run_inn.wav")
    gpu_stop_inn = sasl.al.loadSample("Custom Sounds/gpu_stop_inn.wav")
    STATE.sounds_loaded = true
end

local function unloadSounds()
    sasl.al.unloadSample(gpu_start_out)
    sasl.al.unloadSample(gpu_run_out)
    sasl.al.unloadSample(gpu_stop_out)
    sasl.al.unloadSample(gpu_start_inn)
    sasl.al.unloadSample(gpu_run_inn)
    sasl.al.unloadSample(gpu_stop_inn)
    STATE.sounds_loaded = false
end

local function updateElectricalState(dt)
    local present = get(gpu_present)
    local ground_speed = math.abs(get(GS))

    if ground_speed > GPU_EJECT_GS then
        STATE.eject_timer = STATE.eject_timer + dt
    else
        STATE.eject_timer = 0
    end

    if STATE.eject_timer >= GPU_EJECT_DELAY then
        STATE.work_timer = 0
        STATE.connect_timer = 0

        set(gpu_work_anim, 0)
        set(gpu_present, 0)
        set(gpu_volt, 0)
        set(gpu_overload, 0)
        set(gpu_work_bus, 0)

        stopAllGpuSamples()
        return
    end

    -- GPU spool-up / spool-down.
    if present == 1 then
        STATE.work_timer = STATE.work_timer + dt * GPU_START_RATE
    else
        STATE.work_timer = STATE.work_timer - dt * GPU_STOP_RATE
        set(gpu_overload, 0)
    end

    if STATE.work_timer >= 1 then
        STATE.work_timer = 1

        local dc_available =
            get(DC_27_volt1) > GPU_CONTROL_VOLTAGE
            or get(DC_27_volt2) > GPU_CONTROL_VOLTAGE

        if dc_available and get(gpu_overload) ~= 1 then
            set(gpu_volt, GPU_OUTPUT_VOLTAGE)
        else
            set(gpu_volt, 0)
        end
    elseif STATE.work_timer <= 0 then
        STATE.work_timer = 0
        set(gpu_volt, 0)
    elseif STATE.work_timer < 0.9 then
        -- Preserve the existing spool-down voltage behavior.
        set(gpu_volt, 0)
    end

    set(gpu_work_anim, STATE.work_timer)

    -- GPU bus connection.
    local gpu_switch = get(gpu_on)

    if gpu_switch == 1 then
        STATE.connect_timer = STATE.connect_timer + dt

        if STATE.connect_timer >= GPU_CONNECT_DELAY then
            STATE.connect_timer = GPU_CONNECT_DELAY

            if STATE.work_timer == 1 and get(gpu_overload) ~= 1 then
                set(gpu_work_bus, 1)
            else
                set(gpu_work_bus, 0)
            end
        else
            set(gpu_work_bus, 0)
        end
    else
        STATE.connect_timer = 0
        set(gpu_work_bus, 0)
    end

    -- GPU overload latch.
    if get(gpu_amp) > GPU_OVERLOAD_LIMIT then
        set(gpu_overload, 1)
    elseif gpu_switch == 0 then
        set(gpu_overload, 0)
    end
end

local function updateGpuSounds(dt)
    local work_anim = get(gpu_work_anim)
    local present = get(gpu_present)
    local external = get(external_view)

    -- Sound state.
    if work_anim > 0 and work_anim < 1 and present == 1 then
        if not sasl.al.isSamplePlaying(gpu_start_out) then
            playGpuSample(gpu_start_out, false)
            playGpuSample(gpu_start_inn, false)
        end

        sasl.al.stopSample(gpu_run_out)
        sasl.al.stopSample(gpu_run_inn)
    elseif work_anim == 1 then
        if not sasl.al.isSamplePlaying(gpu_run_out) then
            playGpuSample(gpu_run_out, true)
            playGpuSample(gpu_run_inn, true)
        end
    elseif work_anim > 0 and work_anim < 1 and present == 0 then
        if not sasl.al.isSamplePlaying(gpu_stop_out) then
            playGpuSample(gpu_stop_out, false)
            playGpuSample(gpu_stop_inn, false)
        end

        sasl.al.stopSample(gpu_start_out)
        sasl.al.stopSample(gpu_run_out)
        sasl.al.stopSample(gpu_start_inn)
        sasl.al.stopSample(gpu_run_inn)
    elseif work_anim == 0 then
        stopAllGpuSamples()
    end

    -- Camera-distance attenuation.
    local dx = get(view_x) - get(local_x)
    local dy = get(view_y) - get(local_y)
    local dz = get(view_z) - get(local_z)

    local camera_distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    if camera_distance < 1 then
        camera_distance = 1
    end

    local dist_coef = 300 / (camera_distance ^ 1.7)
    if dist_coef > 1 then
        dist_coef = 1
    end

    -- Keep the Doppler calculation for future sound-pitch processing.
    -- It is intentionally not applied because the original module did not
    -- apply the calculated coefficient either.
    local speed_dt = math.max(0.0001, dt)
    local camera_speed = -(camera_distance - STATE.last_distance) / speed_dt
    STATE.last_distance = camera_distance

    local doppler_coef = camera_speed * 0.02
    if doppler_coef > 400 then
        doppler_coef = 300
    elseif doppler_coef < -300 then
        doppler_coef = -300
    end

    local window_open = 0 -- Reserved for future window sound attenuation.

    local outside_gain =
        1000
        * (external + window_open * (1 - external))
        * dist_coef

    local inside_gain = 2000 * (1 - external)

    sasl.al.setSampleGain(gpu_start_out, outside_gain)
    sasl.al.setSampleGain(gpu_run_out, outside_gain)
    sasl.al.setSampleGain(gpu_stop_out, outside_gain)

    sasl.al.setSampleGain(gpu_start_inn, inside_gain)
    sasl.al.setSampleGain(gpu_run_inn, inside_gain)
    sasl.al.setSampleGain(gpu_stop_inn, inside_gain)
end

function update()
    local dt = get(frame_time)

    if dt <= 0 then
        return
    end

    -- Electrical GPU state is master-owned. Sound rendering remains local
    -- and follows synchronized GPU Datarefs on SmartCopilot slaves.
    if get(ismaster) ~= 1 then
        updateElectricalState(dt)
    end

    updateGpuSounds(dt)
end
