-- gpu_logic.lua
--[[
Changelog
2026-10-04
- Move GPU electrical calculation to T154.electric/models/gpu.lua.
- Retain SASL sound playback and remove bindings used only by the migrated calculation.

Earlier changes
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

-- Hobart 60 kVA GPU sounds; electrical calculation lives in T154.electric/models/gpu.lua.

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
    { "xp_version", "sim/version/xplane_internal_version", globalPropertyi },

    -- GPU state and controls
    { "gpu_present", "tu154/custom/anim/gpu_present", globalPropertyi },
    { "gpu_work_anim", "tu154/custom/anim/gpu_work", globalPropertyf },
    -- { "gpu_volt", "tu154/custom/elec/gpu_volt", globalPropertyf }, -- Electrical binding moved to the worker model.
    -- { "gpu_amp", "tu154/custom/elec/gpu_amp", globalPropertyf }, -- Electrical binding moved to the worker model.
    -- { "gpu_overload", "tu154/custom/elec/gpu_overload", globalPropertyi }, -- Electrical binding moved to the worker model.
    -- { "gpu_on", "tu154/custom/switchers/eng/gpu_on", globalPropertyi }, -- Electrical binding moved to the worker model.
    -- { "gpu_work_bus", "tu154/custom/elec/gpu_work", globalPropertyi }, -- Electrical binding moved to the worker model.

    -- 27 V control-power buses
    -- { "DC_27_volt1", "tu154/custom/elec/bus27_volt_left", globalPropertyf }, -- Electrical binding moved to the worker model.
    -- { "DC_27_volt2", "tu154/custom/elec/bus27_volt_right", globalPropertyf }, -- Electrical binding moved to the worker model.

    -- Simulation state
    -- { "GS", "sim/flightmodel/position/groundspeed", globalPropertyf }, -- Electrical binding moved to the worker model.
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
    -- { "ismaster", "scp/api/ismaster", globalPropertyf }, -- Electrical binding moved to the worker model.
})

local XP11 = get(xp_version) < 120000

local gpu_start_out = sasl.al.loadSample("Custom Sounds/gpu_start_out.wav")
local gpu_run_out = sasl.al.loadSample("Custom Sounds/gpu_run_out.wav")
local gpu_stop_out = sasl.al.loadSample("Custom Sounds/gpu_stop_out.wav")
local gpu_start_inn = sasl.al.loadSample("Custom Sounds/gpu_start_inn.wav")
local gpu_run_inn = sasl.al.loadSample("Custom Sounds/gpu_run_inn.wav")
local gpu_stop_inn = sasl.al.loadSample("Custom Sounds/gpu_stop_inn.wav")

local STATE = {
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
    -- The electric worker adapter publishes GPU state before this callback.
    -- Sound rendering remains local on master and SmartCopilot slave alike.
    updateGpuSounds(dt)
end
