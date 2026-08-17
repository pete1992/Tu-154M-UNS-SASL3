--[[
Changelog
- Grouped the original SASL property bindings through defineProps() while preserving names, Dataref paths and order.
- Moved all property comments above their entries and replaced Russian comments with English comments.
- Corrected apd_working_1, apd_working_2 and apd_working_3 from globalPropertyf to globalPropertyi to match their creator definitions.
- Added local X-Plane 11 / X-Plane 12-compatible panel-sound playback.
- Replaced sum-based switch and button sound detection with direct state comparison so opposite simultaneous changes cannot cancel each other.
- Replaced individual *_last locals with compact persistent state tables.
- Added SmartCopilot ownership for cap-forced switch writes, lamps and starter-pressure output; panel sounds remain local.
- Clamped panel lamp brightness to the valid 0..1 range using the project-wide clamp() helper.
- Reduced repeated bus-voltage reads.
- Preserved the starter-cap behavior, starter-mode exception, 36 V power condition and starter-pressure gauge response.
]]

-- Added for X-Plane 11 / X-Plane 12 compatibility.
defineProperty("xp_version", globalPropertyi("sim/version/xplane_internal_version"))
local XP11 = get(xp_version) > 120000

-- Start-up panel logic.
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Starter-system pressure gauge
    { "starter_press", "tu154/custom/gauges/eng/starter_press", globalPropertyf },
    -- Starter-panel guard
    { "starter_cap", "tu154/custom/switchers/eng/starter_cap", globalPropertyi },
    -- Starter power switch
    { "starter_switch", "tu154/custom/switchers/eng/starter_switch", globalPropertyi },
    -- Engine selector
    { "starter_eng_select", "tu154/custom/switchers/eng/starter_eng_select", globalPropertyi },
    -- Starter mode selector
    { "starter_mode", "tu154/custom/switchers/eng/starter_mode", globalPropertyi },
    -- Starter start button
    { "starter_start", "tu154/custom/buttons/eng/starter_start", globalPropertyi },
    -- Starter stop button
    { "starter_stop", "tu154/custom/buttons/eng/starter_stop", globalPropertyi },
    -- In-flight start button, engine 1
    { "flight_start_1", "tu154/custom/buttons/eng/flight_start_1", globalPropertyi },
    -- In-flight start button, engine 2
    { "flight_start_2", "tu154/custom/buttons/eng/flight_start_2", globalPropertyi },
    -- In-flight start button, engine 3
    { "flight_start_3", "tu154/custom/buttons/eng/flight_start_3", globalPropertyi },
    -- Reserve fuel-pump test button
    { "reserv_pump_test", "tu154/custom/buttons/eng/reserv_pump_test", globalPropertyi },
    -- APD operating lamp, engine 1
    { "apd_work_1", "tu154/custom/lights/small/apd_work_1", globalPropertyf },
    -- APD operating lamp, engine 2
    { "apd_work_2", "tu154/custom/lights/small/apd_work_2", globalPropertyf },
    -- APD operating lamp, engine 3
    { "apd_work_3", "tu154/custom/lights/small/apd_work_3", globalPropertyf },
    -- Left 27 V bus voltage
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    -- Right 27 V bus voltage
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    -- Left 36 V bus voltage
    { "bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf },
    -- Right 36 V bus voltage
    { "bus36_volt_right", "tu154/custom/elec/bus36_volt_right", globalPropertyf },
    -- Frame duration
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    -- Starter-system pressure source
    { "starter_pressure", "tu154/custom/start/starter_pressure", globalPropertyf },
    -- APD operating state, engine 1
    { "apd_working_1", "tu154/custom/start/apd_working_1", globalPropertyi },
    -- APD operating state, engine 2
    { "apd_working_2", "tu154/custom/start/apd_working_2", globalPropertyi },
    -- APD operating state, engine 3
    { "apd_working_3", "tu154/custom/start/apd_working_3", globalPropertyi },
    -- SmartCopilot master state: 0 unavailable, 1 slave, 2 master
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    -- SmartCopilot control state: 0 unavailable, 1 no control, 2 has control
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf },
})

-- Panel sounds
local switcher_sound = loadSample("Custom Sounds/metal_switch.wav")
local cap_sound = loadSample("Custom Sounds/cap.wav")
local button_sound = loadSample("Custom Sounds/plastic_btn.wav")

local function playPanelSample(sample)
    if XP11 then
        playSample(sample, false)
    else
        playSample(sample, false)
    end
end

-- Persistent sound states.
-- Entry format: { property, last_value }
local SWITCH_STATE = {
    { starter_switch, get(starter_switch) },
    { starter_eng_select, get(starter_eng_select) },
    { starter_mode, get(starter_mode) },
}

local CAP_STATE = {
    { starter_cap, get(starter_cap) },
}

local BUTTON_STATE = {
    { starter_start, get(starter_start) },
    { starter_stop, get(starter_stop) },
    { flight_start_1, get(flight_start_1) },
    { flight_start_2, get(flight_start_2) },
    { flight_start_3, get(flight_start_3) },
    { reserv_pump_test, get(reserv_pump_test) },
}

local function stateChanged(state)
    local changed = false

    for i = 1, #state do
        local entry = state[i]
        local value = get(entry[1])

        if value ~= entry[2] then
            changed = true
        end

        entry[2] = value
    end

    return changed
end

local function check_controls(MASTER)
    if stateChanged(CAP_STATE) then
        playPanelSample(cap_sound)
    end

    if stateChanged(SWITCH_STATE) then
        playPanelSample(switcher_sound)
    end

    if stateChanged(BUTTON_STATE) then
        playPanelSample(button_sound)
    end

    if not MASTER then
        return
    end

    if get(starter_cap) == 0 then
        set(starter_switch, 0)
        set(starter_eng_select, 0)

        -- Intentionally preserved from the original script.
        -- set(starter_mode, 0)
    end
end

local function lamps()
    local bus_left = get(bus27_volt_left)
    local bus_right = get(bus27_volt_right)

    local lamps_brt = clamp(
        (math.max(bus_left, bus_right) - 10) / 18.5,
        0,
        1
    )

    set(apd_work_1, get(apd_working_1) * lamps_brt)
    set(apd_work_2, get(apd_working_2) * lamps_brt)
    set(apd_work_3, get(apd_working_3) * lamps_brt)
end

local start_press_act = 0

local function updateStarterPressure(dt, MASTER)
    local bus_left = get(bus36_volt_left)
    local bus_right = get(bus36_volt_right)

    local start_press = 0

    if bus_left > 30 and bus_right > 30 then
        start_press = get(starter_pressure)
    end

    -- Preserve the original gauge response.
    start_press_act =
        start_press_act
        + (start_press - start_press_act) * dt * 2

    if MASTER then
        set(starter_press, start_press_act)
    end
end

function update()
    local dt = get(frame_time)
    local MASTER = get(ismaster) ~= 1

    -- Panel sounds remain local on all SmartCopilot instances.
    check_controls(MASTER)

    if MASTER then
        lamps()
    end

    -- Internal pressure state continues to track on every instance so an
    -- ownership change does not start from a stale gauge state.
    updateStarterPressure(dt, MASTER)
end
