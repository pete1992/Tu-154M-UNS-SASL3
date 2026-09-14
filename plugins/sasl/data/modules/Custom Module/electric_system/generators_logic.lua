local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

-- Generator logic for the Tu-154M electrical system.
-- XP12 supplies the shaft-speed-dependent voltage availability. The custom
-- 115 V system retains its own voltage/load curve, protection and contactors.

-- SASL array elements are one-based; callers below use X-Plane indices 0..2.
local function floatElement(index)
    return function(path) return globalPropertyfae(path, index + 1) end
end

local function intElement(index)
    return function(path) return globalPropertyiae(path, index + 1) end
end

defineProps({
    -- SmartCopilot
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf },

    -- Generator voltages
    { "gen1_volt_bus", "tu154/custom/elec/gen1_volt", globalPropertyf },
    { "gen2_volt_bus", "tu154/custom/elec/gen2_volt", globalPropertyf },
    { "gen3_volt_bus", "tu154/custom/elec/gen3_volt", globalPropertyf },
    { "gen4_volt_bus", "tu154/custom/elec/gen4_volt", globalPropertyf },
    { "gpu_volt_bus", "tu154/custom/elec/gpu_volt", globalPropertyf },
    -- Generator currents
    { "gen1_amp_bus", "tu154/custom/elec/gen1_amp", globalPropertyf },
    { "gen2_amp_bus", "tu154/custom/elec/gen2_amp", globalPropertyf },
    { "gen3_amp_bus", "tu154/custom/elec/gen3_amp", globalPropertyf },
    { "gen4_amp_bus", "tu154/custom/elec/gen4_amp", globalPropertyf },
    { "gpu_amp", "tu154/custom/elec/gpu_amp", globalPropertyf },
    -- Overload flags
    { "gen1_overload", "tu154/custom/elec/gen1_overload", globalPropertyi },
    { "gen2_overload", "tu154/custom/elec/gen2_overload", globalPropertyi },
    { "gen3_overload", "tu154/custom/elec/gen3_overload", globalPropertyi },
    { "gen4_overload", "tu154/custom/elec/gen4_overload", globalPropertyi },
    { "gpu_overload", "tu154/custom/elec/gpu_overload", globalPropertyi },
    -- Generator switches
    { "gen_1_on", "tu154/custom/switchers/eng/gen_1_on", globalPropertyi },
    { "gen_2_on", "tu154/custom/switchers/eng/gen_2_on", globalPropertyi },
    { "gen_3_on", "tu154/custom/switchers/eng/gen_3_on", globalPropertyi },
    { "apu_gen_on", "tu154/custom/switchers/eng/apu_gen_on", globalPropertyi },
    { "gpu_on_sw", "tu154/custom/switchers/eng/gpu_on", globalPropertyi },
    -- Emergency generator cutoffs
    { "emerg_gen_on_1", "tu154/custom/switchers/eng/emerg_gen_on_1", globalPropertyi },
    { "emerg_gen_on_2", "tu154/custom/switchers/eng/emerg_gen_on_2", globalPropertyi },
    { "emerg_gen_on_3", "tu154/custom/switchers/eng/emerg_gen_on_3", globalPropertyi },
    -- Generator operating status
    { "gen1_work", "tu154/custom/elec/gen1_work", globalPropertyi },
    { "gen2_work", "tu154/custom/elec/gen2_work", globalPropertyi },
    { "gen3_work", "tu154/custom/elec/gen3_work", globalPropertyi },
    { "gen4_work", "tu154/custom/elec/gen4_work", globalPropertyi },
    { "gpu_work_bus", "tu154/custom/elec/gpu_work", globalPropertyi },
    -- 27 V bus
    { "DC_27_volt1", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "DC_27_volt2", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    -- Core rotation and APU speed (not the remapped cockpit RPM needles).
    { "eng1_N2", "sim/flightmodel/engine/ENGN_N2_", floatElement(0) },
    { "eng2_N2", "sim/flightmodel/engine/ENGN_N2_", floatElement(1) },
    { "eng3_N2", "sim/flightmodel/engine/ENGN_N2_", floatElement(2) },
    { "eng4_N1", "tu154/custom/eng/apu_n1", globalPropertyf },
    -- Native potential voltage is available even before the contactor closes.
    -- Normalize against the ACF's native nominal voltage, not custom 115 V.
    { "sim_gen1_volt", "sim/cockpit2/electrical/generator_volts", floatElement(0) },
    { "sim_gen2_volt", "sim/cockpit2/electrical/generator_volts", floatElement(1) },
    { "sim_gen3_volt", "sim/cockpit2/electrical/generator_volts", floatElement(2) },
    { "sim_gen_nominal_volt", "sim/aircraft/electrical/acf_nom_gen_volt", globalPropertyf },
    -- X-Plane generator switches
    { "sim_gen1_on", "sim/cockpit/electrical/generator_on", intElement(0) },
    { "sim_gen2_on", "sim/cockpit/electrical/generator_on", intElement(1) },
    { "sim_gen3_on", "sim/cockpit/electrical/generator_on", intElement(2) },
    { "sim_gen4_on", "sim/cockpit2/electrical/APU_generator_on", globalPropertyi },
    -- Generator failure flags
    { "sim_gen1_fail", "sim/operation/failures/rel_genera0", globalPropertyi },
    { "sim_gen2_fail", "sim/operation/failures/rel_genera1", globalPropertyi },
    { "sim_gen3_fail", "sim/operation/failures/rel_genera2", globalPropertyi },
    { "apu_gen_fail", "tu154/custom/failures/apu_gen_fail", globalPropertyi },
    -- Timing
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
})

-- Electrical limits and thresholds.
local OVERLOAD_LIMIT = 500
local OVERLOAD_TIME = 15
local OVERLOAD_LIMIT_APU = 1500

-- Availability hysteresis belongs to the simulation adapter, not a new engine
-- idle calibration. Low-spool N1 <= 25 must not disconnect a capable generator.
local GEN_VOLTAGE_CONNECT_RATIO = 0.90
local GEN_VOLTAGE_HOLD_RATIO = 0.85
local MIN_GEN4_N1 = 92
local VOLT_ON_BUS = 13

local STATE = {
    apu_counter = 0,

    -- Keep original initialization at 1 so generators are immediately
    -- available when loading an already-running aircraft state.
    engine_counter = { 1, 1, 1 },
    engine_supply_available = { false, false, false },

    switch_last = {
        get(gen_1_on),
        get(gen_2_on),
        get(gen_3_on),
    },

    overload_timer = { 0, 0, 0, 0 },

    gpu_counter = 0, -- Preserved legacy state.
}

local ENGINE_GENERATORS = {
    {
        switch = gen_1_on,
        voltage = gen1_volt_bus,
        current = gen1_amp_bus,
        overload = gen1_overload,
        work = gen1_work,
        sim_switch = sim_gen1_on,
        sim_failure = sim_gen1_fail,
    },
    {
        switch = gen_2_on,
        voltage = gen2_volt_bus,
        current = gen2_amp_bus,
        overload = gen2_overload,
        work = gen2_work,
        sim_switch = sim_gen2_on,
        sim_failure = sim_gen2_fail,
    },
    {
        switch = gen_3_on,
        voltage = gen3_volt_bus,
        current = gen3_amp_bus,
        overload = gen3_overload,
        work = gen3_work,
        sim_switch = sim_gen3_on,
        sim_failure = sim_gen3_fail,
    },
}

local function positiveFinite(value)
    return type(value) == "number" and value > 0 and value < math.huge
end

local function engineSupplyAvailable(index, engine_n2, native_voltage, nominal_voltage)
    local available = false
    if positiveFinite(engine_n2) and positiveFinite(native_voltage) and positiveFinite(nominal_voltage) then
        local minimum_ratio = STATE.engine_supply_available[index]
            and GEN_VOLTAGE_HOLD_RATIO or GEN_VOLTAGE_CONNECT_RATIO
        available = native_voltage / nominal_voltage >= minimum_ratio
    end

    -- A stale potential reading cannot energize a stopped core. No fuel-burning
    -- flag, displayed RPM or throttle request can bypass actual supply voltage.
    STATE.engine_supply_available[index] = available
    return available
end

local function updateEngineGenerator(index, config, switch_actual, emergency_cutoff, engine_n2, native_voltage, nominal_voltage, current, dc_power, dt)
    -- Preserve the original one-frame disconnect whenever the normal switch
    -- changes. This resets the connection delay after OFF/ON/TEST transitions.
    local switch_effective = switch_actual
    if switch_actual ~= STATE.switch_last[index] then
        switch_effective = 0
    end
    STATE.switch_last[index] = switch_actual

    -- Emergency cutoff has immediate priority over both ON (+1) and TEST (-1).
    -- The normal generator switch is intentionally left untouched.
    if emergency_cutoff == 1 then
        switch_effective = 0
    end

    local supply_available = engineSupplyAvailable(index, engine_n2, native_voltage, nominal_voltage)
    local can_connect = math.abs(switch_effective) * dc_power * (supply_available and 1 or 0) == 1

    if can_connect then
        STATE.engine_counter[index] = STATE.engine_counter[index] + dt * 0.5
    else
        STATE.engine_counter[index] = 0
    end

    local connected = 0
    if STATE.engine_counter[index] > 1 then
        STATE.engine_counter[index] = 1
        connected = 1
    end

    local failed = get(config.sim_failure) == 6
        or get(config.overload) == 1

    local voltage = (122 - current / 500)
        * math.abs(switch_effective)
        * connected

    if failed then
        voltage = 0
    end

    set(config.voltage, voltage)

    -- Only the normal ON position (+1) counts as a generator feeding the bus.
    -- TEST (-1) may produce voltage but does not set the work flag.
    local working = voltage > 110 and switch_effective == 1
    set(config.work, working and 1 or 0)

    return voltage, switch_effective
end

local function updateOverload(timer_index, current, limit, overload_prop, reset_condition, dt)
    if current > limit then
        STATE.overload_timer[timer_index] = STATE.overload_timer[timer_index] + dt
    else
        STATE.overload_timer[timer_index] = 0
    end

    if STATE.overload_timer[timer_index] > OVERLOAD_TIME then
        set(overload_prop, 1)
    elseif reset_condition then
        set(overload_prop, 0)
    end
end

function update()
    local dt = get(frame_time)

    if not positiveFinite(dt) or get(ismaster) == 1 then
        return
    end

    --------------------------------------------------------------------------
    -- Cache frame inputs
    --------------------------------------------------------------------------
    local dc_power = 0
    if get(DC_27_volt1) > VOLT_ON_BUS
        or get(DC_27_volt2) > VOLT_ON_BUS then
        dc_power = 1
    end

    local switch_actual = {
        get(gen_1_on),
        get(gen_2_on),
        get(gen_3_on),
    }

    local emergency_cutoff = {
        get(emerg_gen_on_1),
        get(emerg_gen_on_2),
        get(emerg_gen_on_3),
    }

    local engine_n2 = {
        get(eng1_N2),
        get(eng2_N2),
        get(eng3_N2),
    }

    local native_voltage = {
        get(sim_gen1_volt),
        get(sim_gen2_volt),
        get(sim_gen3_volt),
    }
    local nominal_voltage = get(sim_gen_nominal_volt)

    local current = {
        get(gen1_amp_bus),
        get(gen2_amp_bus),
        get(gen3_amp_bus),
        get(gen4_amp_bus),
    }

    --------------------------------------------------------------------------
    -- Engine generators 1..3
    --------------------------------------------------------------------------
    local engine_voltage = { 0, 0, 0 }
    local switch_effective = { 0, 0, 0 }

    for i = 1, 3 do
        engine_voltage[i], switch_effective[i] = updateEngineGenerator(
            i,
            ENGINE_GENERATORS[i],
            switch_actual[i],
            emergency_cutoff[i],
            engine_n2[i],
            native_voltage[i],
            nominal_voltage,
            current[i],
            dc_power,
            dt
        )
    end

    --------------------------------------------------------------------------
    -- APU generator
    --------------------------------------------------------------------------
    local apu_switch = get(apu_gen_on)
    local apu_running = get(eng4_N1) > MIN_GEN4_N1

    local apu_connected = 0

    if apu_switch * dc_power * (apu_running and 1 or 0) == 1 then
        STATE.apu_counter = STATE.apu_counter + dt * 0.5
    else
        STATE.apu_counter = 0
    end

    if STATE.apu_counter > 1 then
        STATE.apu_counter = 1
        apu_connected = 1
    end

    -- Keep generator voltage at 0 V while the APU generator is disconnected.
    -- Apply the 111 V minimum only while the generator is actually online.
    local gen4_voltage = 0

    if apu_connected == 1 then
        gen4_voltage = 122 - current[4] / 500

        if gen4_voltage < 111 then
            gen4_voltage = 111
        end
    end

    local gen4_failed = get(gen4_overload) == 1
        or get(apu_gen_fail) == 1

    if gen4_failed then
        gen4_voltage = 0
    end

    set(gen4_volt_bus, gen4_voltage)

    local gen4_working = gen4_voltage > 110 and apu_connected == 1
    set(gen4_work, gen4_working and 1 or 0)

    --------------------------------------------------------------------------
    -- Overload latches
    --------------------------------------------------------------------------
    updateOverload(
        1,
        current[1],
        OVERLOAD_LIMIT,
        gen1_overload,
        switch_effective[1] == 0,
        dt
    )

    updateOverload(
        2,
        current[2],
        OVERLOAD_LIMIT,
        gen2_overload,
        switch_effective[2] == 0,
        dt
    )

    updateOverload(
        3,
        current[3],
        OVERLOAD_LIMIT,
        gen3_overload,
        switch_effective[3] == 0,
        dt
    )

    updateOverload(
        4,
        current[4],
        OVERLOAD_LIMIT_APU,
        gen4_overload,
        apu_connected == 0,
        dt
    )

    --------------------------------------------------------------------------
    -- Synchronize X-Plane generator switches
    --------------------------------------------------------------------------
    set(sim_gen1_on, engine_voltage[1] * switch_effective[1] > 0 and 1 or 0)
    set(sim_gen2_on, engine_voltage[2] * switch_effective[2] > 0 and 1 or 0)
    set(sim_gen3_on, engine_voltage[3] * switch_effective[3] > 0 and 1 or 0)
    set(sim_gen4_on, gen4_voltage * apu_connected > 0 and 1 or 0)
end
