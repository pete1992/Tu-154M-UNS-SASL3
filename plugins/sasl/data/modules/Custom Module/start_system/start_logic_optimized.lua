--[[
Changelog
- Preserved all original Dataref names and paths, including the legacy sim_vers alias and unused compatibility bindings.
- Added the project-standard X-Plane 11 / X-Plane 12 array handling: XP11 keeps the original i/f accessor, XP12 uses globalProperty.
- Added xp_version separately before defineProps() for compatibility decisions.
- Moved asu_press into defineProps() while preserving its original global property name and float type.
- Corrected apd_working_1..3 and start_sys_work from globalPropertyf to globalPropertyi to match their creator definitions.
- Replaced the three duplicated engine-start sequences with one persistent three-engine state table and shared helpers.
- Fixed start abort handling so timeout, engine-cover and ground-start power-loss aborts also clear the internal starting state.
- Prevented an engine-cover abort from being followed by sasl.commandBegin() again in the same frame.
- Turned ignition and igniters off when a ground or air start finishes.
- Made all simulator/system side effects master-owned for SmartCopilot while keeping the internal state machine active on every instance.
- Limited the APU N1 and starter-torque workarounds to X-Plane 11.
- Replaced interpolate() with the project-wide fastInterpolate() helper for the static starter-air pressure table.
- Reduced repeated Dataref reads and preserved all original start thresholds, pressure formulas and selector mappings.
]]

-- Added for X-Plane 11 / X-Plane 12 compatibility.
defineProperty("xp_version", globalPropertyi("sim/version/xplane_internal_version"))
local XP11 = get(xp_version) > 120000

-- Engine start logic.
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Starter-panel guard
    { "starter_cap", "tu154/custom/switchers/eng/starter_cap", globalPropertyi },
    -- Starter-system power switch
    { "starter_switch", "tu154/custom/switchers/eng/starter_switch", globalPropertyi },
    -- Engine selector
    { "starter_eng_select", "tu154/custom/switchers/eng/starter_eng_select", globalPropertyi },
    -- Starter mode selector
    { "starter_mode", "tu154/custom/switchers/eng/starter_mode", globalPropertyi },
    -- Ground-start button
    { "starter_start", "tu154/custom/buttons/eng/starter_start", globalPropertyi },
    -- Start-stop button
    { "starter_stop", "tu154/custom/buttons/eng/starter_stop", globalPropertyi },
    -- In-flight start button, engine 1
    { "flight_start_1", "tu154/custom/buttons/eng/flight_start_1", globalPropertyi },
    -- In-flight start button, engine 2
    { "flight_start_2", "tu154/custom/buttons/eng/flight_start_2", globalPropertyi },
    -- In-flight start button, engine 3
    { "flight_start_3", "tu154/custom/buttons/eng/flight_start_3", globalPropertyi },

    -- Arrays
    -- Engine 1 igniter state
    { "sim_igniter1", "sim/cockpit2/engine/actuators/igniter_on[0]",
        XP11 and globalPropertyi or globalProperty },
    -- Engine 2 igniter state
    { "sim_igniter2", "sim/cockpit2/engine/actuators/igniter_on[1]",
        XP11 and globalPropertyi or globalProperty },
    -- Engine 3 igniter state
    { "sim_igniter3", "sim/cockpit2/engine/actuators/igniter_on[2]",
        XP11 and globalPropertyi or globalProperty },
    -- Engine 1 ignition state
    { "sim_ignition1", "sim/cockpit2/engine/actuators/ignition_on[0]",
        XP11 and globalPropertyi or globalProperty },
    -- Engine 2 ignition state
    { "sim_ignition2", "sim/cockpit2/engine/actuators/ignition_on[1]",
        XP11 and globalPropertyi or globalProperty },
    -- Engine 3 ignition state
    { "sim_ignition3", "sim/cockpit2/engine/actuators/ignition_on[2]",
        XP11 and globalPropertyi or globalProperty },
    -- Starter duration, engine 1 mapping
    { "sim_starter1", "sim/cockpit/engine/starter_duration[1]",
        XP11 and globalPropertyf or globalProperty },
    -- Starter duration, engine 2 mapping
    { "sim_starter2", "sim/cockpit/engine/starter_duration[0]",
        XP11 and globalPropertyf or globalProperty },
    -- Starter duration, engine 3 mapping
    { "sim_starter3", "sim/cockpit/engine/starter_duration[2]",
        XP11 and globalPropertyf or globalProperty },
    -- Starter torque state, engine 1 mapping
    { "sim_start1", "sim/flightmodel2/engines/starter_making_torque[1]",
        XP11 and globalPropertyf or globalProperty },
    -- Starter torque state, engine 2 mapping
    { "sim_start2", "sim/flightmodel2/engines/starter_making_torque[0]",
        XP11 and globalPropertyf or globalProperty },
    -- Starter torque state, engine 3 mapping
    { "sim_start3", "sim/flightmodel2/engines/starter_making_torque[2]",
        XP11 and globalPropertyf or globalProperty },

    -- Left 27 V bus voltage
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    -- Right 27 V bus voltage
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    -- APU air-door position
    { "apu_air_doors", "tu154/custom/eng/apu_air_doors", globalPropertyf },
    -- APU N1
    { "apu_n1", "tu154/custom/eng/apu_n1", globalPropertyf },

    -- Arrays
    -- Engine 1 N2
    { "eng_rpm1", "sim/flightmodel/engine/ENGN_N2_[0]",
        XP11 and globalPropertyf or globalProperty },
    -- Engine 2 N2
    { "eng_rpm2", "sim/flightmodel/engine/ENGN_N2_[1]",
        XP11 and globalPropertyf or globalProperty },
    -- Engine 3 N2
    { "eng_rpm3", "sim/flightmodel/engine/ENGN_N2_[2]",
        XP11 and globalPropertyf or globalProperty },
    -- Engine 1 burning-fuel state
    { "eng_work1", "sim/flightmodel2/engines/engine_is_burning_fuel[0]",
        XP11 and globalPropertyf or globalProperty },
    -- Engine 2 burning-fuel state
    { "eng_work2", "sim/flightmodel2/engines/engine_is_burning_fuel[1]",
        XP11 and globalPropertyf or globalProperty },
    -- Engine 3 burning-fuel state
    { "eng_work3", "sim/flightmodel2/engines/engine_is_burning_fuel[2]",
        XP11 and globalPropertyf or globalProperty },

    -- Engine 1 bleed-air valve position
    { "eng_airvalve_1", "tu154/custom/bleed/eng_airvalve_1", globalPropertyf },
    -- Engine 2 bleed-air valve position
    { "eng_airvalve_2", "tu154/custom/bleed/eng_airvalve_2", globalPropertyf },
    -- Engine 3 bleed-air valve position
    { "eng_airvalve_3", "tu154/custom/bleed/eng_airvalve_3", globalPropertyf },
    -- Tank 1 pump 1 operating state
    { "tank1_1", "tu154/custom/fuel/pump_tank1_1_work", globalPropertyi },
    -- Tank 1 pump 2 operating state
    { "tank1_2", "tu154/custom/fuel/pump_tank1_2_work", globalPropertyi },
    -- Tank 1 pump 3 operating state
    { "tank1_3", "tu154/custom/fuel/pump_tank1_3_work", globalPropertyi },
    -- Tank 1 pump 4 operating state
    { "tank1_4", "tu154/custom/fuel/pump_tank1_4_work", globalPropertyi },
    -- Automatic tank selection state
    { "auto_tanks_turn", "tu154/custom/fuel/auto_tanks_turn", globalPropertyi },
    -- Fuel-flow mode selector
    { "fuel_flow_mode", "tu154/custom/switchers/fuel/fuel_flow_mode", globalPropertyi },
    -- Engine covers installed
    { "engine_caps", "tu154/custom/anim/engine_caps", globalPropertyi },
    -- Frame duration
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    -- Simulator running time
    { "sim_run_time", "sim/time/total_running_time_sec", globalPropertyf },
    -- Starter-system air pressure
    { "starter_pressure", "tu154/custom/start/starter_pressure", globalPropertyf },
    -- APD operating state, engine 1
    { "apd_working_1", "tu154/custom/start/apd_working_1", globalPropertyi },
    -- APD operating state, engine 2
    { "apd_working_2", "tu154/custom/start/apd_working_2", globalPropertyi },
    -- APD operating state, engine 3
    { "apd_working_3", "tu154/custom/start/apd_working_3", globalPropertyi },
    -- Starter-system operating state
    { "start_sys_work", "tu154/custom/start/start_sys_work", globalPropertyi },
    -- Starter-system fuel command, engine 1
    { "fuel_in_1", "tu154/custom/start/fuel_in_1", globalPropertyi },
    -- Starter-system fuel command, engine 2
    { "fuel_in_2", "tu154/custom/start/fuel_in_2", globalPropertyi },
    -- Starter-system fuel command, engine 3
    { "fuel_in_3", "tu154/custom/start/fuel_in_3", globalPropertyi },
    -- Starter torque ratio
    { "starter_torq", "sim/aircraft/engine/acf_starter_torque_ratio", globalPropertyf },
    -- Starter maximum RPM ratio
    { "starter_rpm", "sim/aircraft/engine/acf_starter_max_rpm_ratio", globalPropertyf },
    -- Jet-engine spool-up time
    { "jet_spoolup_time", "sim/aircraft/engine/acf_spooltime_jet", globalPropertyf },
    -- SmartCopilot master state: 0 unavailable, 1 slave, 2 master
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    -- SmartCopilot control state: 0 unavailable, 1 no control, 2 has control
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf },
    -- Legacy X-Plane APU starter switch
    { "APU_switch", "sim/cockpit/engine/APU_switch", globalPropertyf },
    -- Legacy X-Plane APU running state
    { "APU_running", "sim/cockpit/engine/APU_running", globalPropertyf },
    -- Legacy X-Plane APU N1
    { "APU_N1", "sim/cockpit/engine/APU_N1", globalPropertyf },
    -- Legacy X-Plane APU bleed-air actuator
    { "apu_bleed", "sim/cockpit2/bleedair/actuators/apu_bleed", globalPropertyf },
    -- External ASU air pressure
    { "asu_press", "tu154/custom/asu/press", globalPropertyf },
    -- Legacy simulator-version alias retained for compatibility
    { "sim_vers", "sim/version/xplane_internal_version", globalPropertyi },
})

-- Simulator starter commands.
starter_1 = sasl.findCommand("sim/starters/engage_starter_1")
starter_2 = sasl.findCommand("sim/starters/engage_starter_2")
starter_3 = sasl.findCommand("sim/starters/engage_starter_3")

local START_SEQ_TIME = 56
local RPM_FOR_FUEL_IN = 16
local RPM_FOR_IGNITER = 20
local RPM_APD_OFF = 47

-- Starter-air pressure contribution versus engine N2.
local eng_start_press_t = {
    { -100000, 0.0 },
    { 0, 0.0 },
    { 70, 0.35 },
    { 83, 1.05 },
    { 100, 1.3 },
    { 1000000000, 110 },
}

local time_last = get(sim_run_time)

-- Persistent engine state.
local ENGINES = {
    {
        selector = 1,
        rpm = eng_rpm1,
        burning = eng_work1,
        airvalve = eng_airvalve_1,
        fuel = fuel_in_1,
        ignition = sim_ignition1,
        igniter = sim_igniter1,
        flight_start = flight_start_1,
        apd = apd_working_1,
        command = starter_1,
        left_bus = true,
        start_time = time_last - 100,
        ground_starting = false,
        air_starting = false,
        rpm_value = 0,
    },
    {
        selector = 2,
        rpm = eng_rpm2,
        burning = eng_work2,
        airvalve = eng_airvalve_2,
        fuel = fuel_in_2,
        ignition = sim_ignition2,
        igniter = sim_igniter2,
        flight_start = flight_start_2,
        apd = apd_working_2,
        command = starter_2,
        left_bus = false,
        start_time = time_last - 100,
        ground_starting = false,
        air_starting = false,
        rpm_value = 0,
    },
    {
        selector = 3,
        rpm = eng_rpm3,
        burning = eng_work3,
        airvalve = eng_airvalve_3,
        fuel = fuel_in_3,
        ignition = sim_ignition3,
        igniter = sim_igniter3,
        flight_start = flight_start_3,
        apd = apd_working_3,
        command = starter_3,
        left_bus = false,
        start_time = time_last - 100,
        ground_starting = false,
        air_starting = false,
        rpm_value = 0,
    },
}

-- Legacy/reserved state retained from the original script.
local eng1_rpm_check = false
local eng2_rpm_check = false
local eng3_rpm_check = false
local start_button_pressed = false

local select_last = get(starter_eng_select)
local starter_press = 0
local xp11_torque_initialized = not XP11

local function engineHasPower(engine, power27L, power27R)
    if engine.left_bus then
        return power27L
    end

    return power27R
end

local function setEngineIgnition(engine, value, MASTER)
    if not MASTER then
        return
    end

    set(engine.ignition, value)
    set(engine.igniter, value)
end

local function endStarterCommand(engine, MASTER)
    if MASTER then
        sasl.commandEnd(engine.command)
    end
end

local function abortStart(engine, MASTER)
    if MASTER then
        set(engine.fuel, 0)
        set(engine.ignition, 0)
        set(engine.igniter, 0)
        sasl.commandEnd(engine.command)
    end

    engine.ground_starting = false
    engine.air_starting = false
end

local function finishStart(engine, MASTER)
    if MASTER then
        set(engine.ignition, 0)
        set(engine.igniter, 0)
        sasl.commandEnd(engine.command)
    end

    engine.ground_starting = false
    engine.air_starting = false
end

local function anyGroundStartActive()
    for i = 1, #ENGINES do
        if ENGINES[i].ground_starting then
            return true
        end
    end

    return false
end

local function clearAllStartStates()
    for i = 1, #ENGINES do
        ENGINES[i].ground_starting = false
        ENGINES[i].air_starting = false
    end
end

local function beginSelectedGroundStart(
    eng_select,
    time_now,
    power27L,
    power27R
)
    local engine = ENGINES[eng_select]

    if not engine then
        return
    end

    if not engineHasPower(engine, power27L, power27R) then
        return
    end

    if engine.rpm_value >= RPM_APD_OFF then
        return
    end

    clearAllStartStates()

    engine.start_time = time_now
    engine.ground_starting = true
end

local function processGroundStart(
    engine,
    time_now,
    start_mode,
    stop_button,
    power27L,
    power27R,
    MASTER
)
    if not engine.ground_starting or engine.air_starting then
        return
    end

    if not engineHasPower(engine, power27L, power27R) then
        abortStart(engine, MASTER)
        return
    end

    if stop_button then
        engine.start_time = engine.start_time - 70
        abortStart(engine, MASTER)
        return
    end

    local elapsed = time_now - engine.start_time
    local rpm = engine.rpm_value

    if elapsed > 1 and elapsed <= START_SEQ_TIME and MASTER then
        sasl.commandBegin(engine.command)
    end

    if rpm > RPM_APD_OFF then
        finishStart(engine, MASTER)
        return
    end

    if elapsed > START_SEQ_TIME then
        abortStart(engine, MASTER)
        return
    end

    if MASTER and rpm >= RPM_FOR_FUEL_IN then
        set(engine.fuel, start_mode)
    end

    if rpm >= RPM_FOR_IGNITER then
        setEngineIgnition(engine, 1, MASTER)
    end
end

local function processAirStart(
    engine,
    time_now,
    power27L,
    power27R,
    MASTER
)
    local rpm = engine.rpm_value
    local has_power = engineHasPower(engine, power27L, power27R)

    if not engine.ground_starting
        and not engine.air_starting
        and get(engine.flight_start) == 1
        and rpm > RPM_FOR_IGNITER
        and has_power
    then
        engine.start_time = time_now
        engine.air_starting = true
    end

    if not engine.air_starting then
        return
    end

    local elapsed = time_now - engine.start_time

    if elapsed < START_SEQ_TIME
        and rpm > RPM_FOR_IGNITER
        and rpm < RPM_APD_OFF + 20
    then
        if MASTER then
            set(engine.ignition, 1)
            set(engine.igniter, 1)
            sasl.commandBegin(engine.command)
            set(engine.fuel, 1)
        end
    else
        finishStart(engine, MASTER)
    end
end

-- Stop any stale starter command when this component is initialized.
if get(ismaster) ~= 1 then
    sasl.commandEnd(starter_1)
    sasl.commandEnd(starter_2)
    sasl.commandEnd(starter_3)
end

function update()
    local MASTER = get(ismaster) ~= 1
    local passed = get(frame_time)
    local time_now = get(sim_run_time)

    -- XP11-only workarounds.
    if MASTER and XP11 then
        set(APU_N1, 100)

        if not xp11_torque_initialized then
            if get(xp_version) >= 111000 then
                set(starter_torq, 0.2)
            end

            xp11_torque_initialized = true
        end
    end

    starter_press = get(starter_pressure)

    local power27L = get(bus27_volt_left) > 13
    local power27R = get(bus27_volt_right) > 13
    local blocked = get(engine_caps) == 1

    -- Cache engine RPM once per frame.
    for i = 1, #ENGINES do
        local engine = ENGINES[i]
        engine.rpm_value = get(engine.rpm)
    end

    -- Automatic fuel/ignition cutoff after a failed start or with engine
    -- covers installed. Clearing the local state prevents a later
    -- sasl.commandBegin() from reactivating the starter in the same frame.
    for i = 1, #ENGINES do
        local engine = ENGINES[i]
        local rpm = engine.rpm_value
        local timed_out =
            time_now - engine.start_time > START_SEQ_TIME
            and rpm < RPM_APD_OFF

        if timed_out or (blocked and rpm >= 5) then
            abortStart(engine, MASTER)
        elseif engine.ground_starting
            and not engineHasPower(engine, power27L, power27R)
        then
            -- A ground start cannot continue without its 27 V supply.
            abortStart(engine, MASTER)
        end
    end

    local pressure_from_engines = 0

    for i = 1, #ENGINES do
        local engine = ENGINES[i]

        pressure_from_engines =
            pressure_from_engines
            + get(engine.burning)
            * get(engine.airvalve)
            * fastInterpolate(eng_start_press_t, engine.rpm_value)
    end

    local start_mode = get(starter_mode)
    local power_sys =
        get(starter_switch) == 1
        and power27L
        and power27R

    local start_button = get(starter_start) == 1
    local eng_select = get(starter_eng_select)

    -- Changing the engine selector simulates pressing the stop control.
    local stop_button =
        get(starter_stop) == 1
        or eng_select ~= select_last

    select_last = eng_select

    if power_sys then
        if MASTER then
            set(start_sys_work, 1)
        end

        local apu_air = get(apu_air_doors) * get(apu_n1) * 0.01

        starter_press =
            starter_press
            + (apu_air + pressure_from_engines) * passed

        local external_air = get(asu_press)

        if external_air > 0 then
            starter_press = external_air
        end

        local fuel_system =
            get(auto_tanks_turn) > 0
            and get(fuel_flow_mode) == 1
            and get(tank1_1)
                + get(tank1_2)
                + get(tank1_3)
                + get(tank1_4) == 4

        if not blocked
            and not anyGroundStartActive()
            and start_button
            and starter_press > 3
            and fuel_system
        then
            beginSelectedGroundStart(
                eng_select,
                time_now,
                power27L,
                power27R
            )
        end
    elseif MASTER then
        set(start_sys_work, 0)
    end

    -- Process all three engines through the same ground/air-start logic.
    for i = 1, #ENGINES do
        local engine = ENGINES[i]

        processGroundStart(
            engine,
            time_now,
            start_mode,
            stop_button,
            power27L,
            power27R,
            MASTER
        )

        processAirStart(
            engine,
            time_now,
            power27L,
            power27R,
            MASTER
        )
    end

    -- Starter-command safety cleanup.
    if MASTER then
        for i = 1, #ENGINES do
            local engine = ENGINES[i]

            if not engine.ground_starting and not engine.air_starting then
                sasl.commandEnd(engine.command)
            end
        end
    end

    -- Preserve the original starter-pressure decay.
    starter_press =
        starter_press
        - (0.2 * passed) * (starter_press + 1)

    starter_press =
        starter_press
        - bool2int(anyGroundStartActive()) * passed * 0.4

    starter_press = clamp(starter_press, 0, 4.8)

    if MASTER then
        set(starter_pressure, starter_press)

        for i = 1, #ENGINES do
            local engine = ENGINES[i]

            set(
                engine.apd,
                bool2int(
                    engine.ground_starting
                    or engine.air_starting
                )
            )
        end
    end
end
