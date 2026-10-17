-- Positional mechanical and touchdown audio for the existing M animations.
-- This component observes motion; it never drives aircraft controls or physics.
local function defineProps(defs)
    for _, def in ipairs(defs) do
        local prop = def[4] and def[3](def[2], def[4]) or def[3](def[2])
        defineProperty(def[1], prop)
    end
end

defineProps({
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    { "paused", "sim/time/paused", globalPropertyi },
    { "external_view", "sim/graphics/view/view_is_external", globalPropertyi },
    { "sound_on", "sim/operation/sound/sound_on", globalPropertyi },
    { "master_volume", "sim/operation/sound/master_volume_ratio", globalPropertyf },
    { "interior_volume", "sim/operation/sound/interior_volume_ratio", globalPropertyf },
    { "ground_volume", "sim/operation/sound/ground_volume_ratio", globalPropertyf },
    { "surface", "sim/flightmodel/ground/surface_texture_type", globalPropertyi },
    -- SASL array elements are one-based: native wheels 0, 1, 2.
    { "ground_nose", "sim/flightmodel2/gear/on_ground", globalPropertyiae, 1 },
    { "ground_left", "sim/flightmodel2/gear/on_ground", globalPropertyiae, 2 },
    { "ground_right", "sim/flightmodel2/gear/on_ground", globalPropertyiae, 3 },
    { "rate_nose", "sim/flightmodel2/gear/total_deflection_rate", globalPropertyfae, 1 },
    { "rate_left", "sim/flightmodel2/gear/total_deflection_rate", globalPropertyfae, 2 },
    { "rate_right", "sim/flightmodel2/gear/total_deflection_rate", globalPropertyfae, 3 },
    { "cg_y", "sim/aircraft/weight/acf_cgY_original", globalPropertyf },
    { "cg_z", "sim/aircraft/weight/acf_cgZ_original", globalPropertyf },
    { "bus27_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "bus115_left", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "bus115_right", "tu154/custom/elec/bus115_3_volt", globalPropertyf },
    { "wiper_left", "tu154/custom/switchers/wiper_left", globalPropertyi },
    { "wiper_right", "tu154/custom/switchers/wiper_right", globalPropertyi },
    { "angle_left", "tu154/custom/anim/wiper_angle_left", globalPropertyf },
    { "angle_right", "tu154/custom/anim/wiper_angle_right", globalPropertyf },
    { "door", "tu154/custom/anim/cockpit_door", globalPropertyf },
    { "arm_left", "tu154/custom/anim/rise_chair_arm_L", globalPropertyf },
    { "arm_right", "tu154/custom/anim/rise_chair_arm_R", globalPropertyf },
})

local al = sasl.al
local samples = {}
local initialized = false
local cabinVolume, impactVolume = 0, 0
local function bounded(value, upper)
    if value ~= value then return 0 end
    return math.max(0, math.min(upper, value))
end

local function load(name, x, y, z, gain, ground)
    local entry = {
        id = al.loadSample(moduleDirectory .. "/Custom Module/Custom Sounds/mechanical/" .. name .. ".wav"),
        gain = gain,
        ground = ground,
    }
    al.setSampleRelative(entry.id, 0)
    al.setSampleEnv(entry.id, SOUND_INTERNAL)
    al.setSamplePosition(entry.id, x, y, z)
    al.setSampleRefDistance(entry.id, ground and 20 or 1.5)
    al.setSampleRolloff(entry.id, ground and 0.4 or 0.8)
    al.setSampleGain(entry.id, 0)
    samples[#samples + 1] = entry
    return entry
end

-- M cockpit OBJ attachment: y=6.7 ft, z=70 ft; convert pivots to CG coordinates.
local offsetY = (6.7 - get(cg_y)) * 0.3048
local offsetZ = (70 - get(cg_z)) * 0.3048
local function cockpitSample(name, x, y, z, gain)
    return load(name, x, y + offsetY, z + offsetZ, gain, false)
end

local function gearSounds(x, y, z, name, contact, rate)
    local gy, gz = (y - get(cg_y)) * 0.3048, (z - get(cg_z)) * 0.3048
    return {
        contact = contact, rate = rate, last = false,
        hard = load(name, x * 0.3048, gy, gz, 0, true),
        rough = load("touchdown", x * 0.3048, gy, gz, 0, true),
    }
end
-- Main gear locations and wheel order come from the M ACF.
local gears = {
    gearSounds(0, -5.7, 13.92, "touch_nose_asph", ground_nose, rate_nose),
    gearSounds(-18.87, -4.7, 74.45, "touch_main_asph", ground_left, rate_left),
    gearSounds(18.87, -4.7, 74.45, "touch_main_asph", ground_right, rate_right),
}

local function wiperSounds(x, mode, angle, dc, ac)
    return {
        mode = mode, angle = angle, dc = dc, ac = ac, last = 0, moving = 0,
        slow = cockpitSample("wiper_slow", x, -1.4707, -21.9087, 300),
        fast = cockpitSample("wiper_fast", x, -1.4707, -21.9087, 300),
        motor = cockpitSample("wiper_eng", x, -1.4707, -21.9087, 130),
    }
end
local wipers = {
    wiperSounds(-0.5680, wiper_left, angle_left, bus27_left, bus115_left),
    wiperSounds(0.5678, wiper_right, angle_right, bus27_right, bus115_right),
}
local arms = {
    { property = arm_left, last = 0, sample = cockpitSample("arm", -0.49194, -1.80228, -20.6357, 350) },
    { property = arm_right, last = 0, sample = cockpitSample("arm", 0.51149, -1.80228, -20.6357, 350) },
}
local doorOpen = cockpitSample("door_open", -0.2725, -1.5296, -19.022, 450)
local doorClose = cockpitSample("door_close", -0.2725, -1.5296, -19.022, 450)
local doorLast, doorDirection = 0, 0

local function stop(entry)
    if al.isSamplePlaying(entry.id) then al.stopSample(entry.id) end
end
local function stopAll()
    for _, entry in ipairs(samples) do stop(entry) end
end
local function applyGain(entry)
    al.setSampleGain(entry.id, bounded(entry.gain * (entry.ground and impactVolume or cabinVolume), 1000))
end
local function play(entry, looped)
    applyGain(entry)
    if not al.isSamplePlaying(entry.id) then al.playSample(entry.id, looped) end
end

function update()
    local dt = get(frame_time)
    local running = dt > 0 and dt < math.huge and get(paused) == 0
    local master = bounded(get(master_volume), 1)
    cabinVolume = master * bounded(get(interior_volume), 1)
    impactVolume = cabinVolume * bounded(get(ground_volume), 1)
    local audible = running and get(sound_on) == 1 and get(external_view) == 0 and cabinVolume > 0
    if not audible then stopAll() end
    for _, entry in ipairs(samples) do applyGain(entry) end

    local surfaceType = get(surface)
    local hardSurface = surfaceType == 2 or surfaceType == 3 -- concrete or asphalt
    for _, gear in ipairs(gears) do
        local contact = get(gear.contact) ~= 0
        local rate = bounded(get(gear.rate), 5)
        if initialized and audible and impactVolume > 0 and contact and not gear.last and rate > 0.12 then
            local entry = hardSurface and gear.hard or gear.rough
            entry.gain = bounded(rate * 450, 1000)
            play(entry, false)
        end
        -- Consume contacts in every view and while paused or muted.
        gear.last = contact
    end

    for _, wiper in ipairs(wipers) do
        local angle = bounded(get(wiper.angle), 62)
        local mode = get(wiper.mode)
        local moved = math.abs(angle - wiper.last) > 0.0001
        if initialized and running and moved then wiper.moving = 0.12
        elseif running then wiper.moving = math.max(0, wiper.moving - dt)
        else wiper.moving = 0 end
        local powered = get(wiper.dc) > 13 and get(wiper.ac) > 110
        local active = initialized and audible and powered and wiper.moving > 0 and (mode ~= 0 or angle > 0)
        if active then
            local blade = mode == 1 and wiper.fast or wiper.slow
            stop(mode == 1 and wiper.slow or wiper.fast)
            -- Match the existing animation's 3 Hz / 1.5 Hz cycle; OFF parks at 1 Hz.
            al.setSamplePitch(blade.id, mode == 1 and 1800 or (mode == -1 and 960 or 640))
            play(blade, true)
            play(wiper.motor, true)
        else
            stop(wiper.slow); stop(wiper.fast); stop(wiper.motor)
        end
        wiper.last = angle
    end

    for _, arm in ipairs(arms) do
        local position = bounded(get(arm.property), 1)
        if initialized and audible and math.abs(position - arm.last) > 0.00001 then
            play(arm.sample, true)
        else stop(arm.sample) end
        arm.last = position
    end
    local position = bounded(get(door), 1)
    local delta = position - doorLast
    local direction = delta > 0.00001 and 1 or (delta < -0.00001 and -1 or 0)
    if initialized and audible and direction ~= 0 and direction ~= doorDirection then
        stop(direction == 1 and doorClose or doorOpen)
        play(direction == 1 and doorOpen or doorClose, false)
    end
    doorLast, doorDirection = position, direction
    initialized = true
end

function onModuleShutdown(isError)
    stopAll()
end
