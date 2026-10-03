--[[
Changelog
2026-10-04
- Port engine and APU generator calculations to the numeric worker model.
- Preserve contactor delays, protection latches and SmartCopilot gates.
]]

-- generators.lua
-- Engine and APU generator availability, contactors and protection.
-- Numeric I/O is provided by the caller; this module has no simulator API access.

local bindings = {
    { "ismaster", "scp/api/ismaster", "float" },
    { "gen1_volt_bus", "tu154/custom/elec/gen1_volt", "float" },
    { "gen2_volt_bus", "tu154/custom/elec/gen2_volt", "float" },
    { "gen3_volt_bus", "tu154/custom/elec/gen3_volt", "float" },
    { "gen4_volt_bus", "tu154/custom/elec/gen4_volt", "float" },
    { "gen1_amp_bus", "tu154/custom/elec/gen1_amp", "float" },
    { "gen2_amp_bus", "tu154/custom/elec/gen2_amp", "float" },
    { "gen3_amp_bus", "tu154/custom/elec/gen3_amp", "float" },
    { "gen4_amp_bus", "tu154/custom/elec/gen4_amp", "float" },
    { "gen1_overload", "tu154/custom/elec/gen1_overload", "integer" },
    { "gen2_overload", "tu154/custom/elec/gen2_overload", "integer" },
    { "gen3_overload", "tu154/custom/elec/gen3_overload", "integer" },
    { "gen4_overload", "tu154/custom/elec/gen4_overload", "integer" },
    { "gen_1_on", "tu154/custom/switchers/eng/gen_1_on", "integer" },
    { "gen_2_on", "tu154/custom/switchers/eng/gen_2_on", "integer" },
    { "gen_3_on", "tu154/custom/switchers/eng/gen_3_on", "integer" },
    { "apu_gen_on", "tu154/custom/switchers/eng/apu_gen_on", "integer" },
    { "emerg_gen_on_1", "tu154/custom/switchers/eng/emerg_gen_on_1", "integer" },
    { "emerg_gen_on_2", "tu154/custom/switchers/eng/emerg_gen_on_2", "integer" },
    { "emerg_gen_on_3", "tu154/custom/switchers/eng/emerg_gen_on_3", "integer" },
    { "gen1_work", "tu154/custom/elec/gen1_work", "integer" },
    { "gen2_work", "tu154/custom/elec/gen2_work", "integer" },
    { "gen3_work", "tu154/custom/elec/gen3_work", "integer" },
    { "gen4_work", "tu154/custom/elec/gen4_work", "integer" },
    { "DC_27_volt1", "tu154/custom/elec/bus27_volt_left", "float" },
    { "DC_27_volt2", "tu154/custom/elec/bus27_volt_right", "float" },
    { "eng1_N2", "sim/flightmodel/engine/ENGN_N2_", "float", 0 },
    { "eng2_N2", "sim/flightmodel/engine/ENGN_N2_", "float", 1 },
    { "eng3_N2", "sim/flightmodel/engine/ENGN_N2_", "float", 2 },
    { "eng4_N1", "tu154/custom/eng/apu_n1", "float" },
    { "sim_gen1_volt", "sim/cockpit2/electrical/generator_volts", "float", 0 },
    { "sim_gen2_volt", "sim/cockpit2/electrical/generator_volts", "float", 1 },
    { "sim_gen3_volt", "sim/cockpit2/electrical/generator_volts", "float", 2 },
    { "sim_gen_nominal_volt", "sim/aircraft/electrical/acf_nom_gen_volt", "float" },
    { "sim_gen1_on", "sim/cockpit/electrical/generator_on", "integer", 0 },
    { "sim_gen2_on", "sim/cockpit/electrical/generator_on", "integer", 1 },
    { "sim_gen3_on", "sim/cockpit/electrical/generator_on", "integer", 2 },
    { "sim_gen4_on", "sim/cockpit2/electrical/APU_generator_on", "integer" },
    { "sim_gen1_fail", "sim/operation/failures/rel_genera0", "integer" },
    { "sim_gen2_fail", "sim/operation/failures/rel_genera1", "integer" },
    { "sim_gen3_fail", "sim/operation/failures/rel_genera2", "integer" },
    { "apu_gen_fail", "tu154/custom/failures/apu_gen_fail", "integer" },
    { "frame_time", "tu154/custom/time/frame_time", "float" },
}

local outputs = {
    "gen4_volt_bus",
    "gen4_work",
    "sim_gen1_on",
    "sim_gen2_on",
    "sim_gen3_on",
    "sim_gen4_on",
    "gen1_volt_bus",
    "gen2_volt_bus",
    "gen3_volt_bus",
    "gen1_work",
    "gen2_work",
    "gen3_work",
    "gen1_overload",
    "gen2_overload",
    "gen3_overload",
    "gen4_overload",
}

local function copyState(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, item in pairs(value) do
        copy[key] = copyState(item)
    end
    return copy
end

local function create(io, saved)
    local get = io.get
    local set = io.set

    local ismaster = "ismaster"
    local gen1_volt_bus = "gen1_volt_bus"
    local gen2_volt_bus = "gen2_volt_bus"
    local gen3_volt_bus = "gen3_volt_bus"
    local gen4_volt_bus = "gen4_volt_bus"
    local gen1_amp_bus = "gen1_amp_bus"
    local gen2_amp_bus = "gen2_amp_bus"
    local gen3_amp_bus = "gen3_amp_bus"
    local gen4_amp_bus = "gen4_amp_bus"
    local gen1_overload = "gen1_overload"
    local gen2_overload = "gen2_overload"
    local gen3_overload = "gen3_overload"
    local gen4_overload = "gen4_overload"
    local gen_1_on = "gen_1_on"
    local gen_2_on = "gen_2_on"
    local gen_3_on = "gen_3_on"
    local apu_gen_on = "apu_gen_on"
    local emerg_gen_on_1 = "emerg_gen_on_1"
    local emerg_gen_on_2 = "emerg_gen_on_2"
    local emerg_gen_on_3 = "emerg_gen_on_3"
    local gen1_work = "gen1_work"
    local gen2_work = "gen2_work"
    local gen3_work = "gen3_work"
    local gen4_work = "gen4_work"
    local DC_27_volt1 = "DC_27_volt1"
    local DC_27_volt2 = "DC_27_volt2"
    local eng1_N2 = "eng1_N2"
    local eng2_N2 = "eng2_N2"
    local eng3_N2 = "eng3_N2"
    local eng4_N1 = "eng4_N1"
    local sim_gen1_volt = "sim_gen1_volt"
    local sim_gen2_volt = "sim_gen2_volt"
    local sim_gen3_volt = "sim_gen3_volt"
    local sim_gen_nominal_volt = "sim_gen_nominal_volt"
    local sim_gen1_on = "sim_gen1_on"
    local sim_gen2_on = "sim_gen2_on"
    local sim_gen3_on = "sim_gen3_on"
    local sim_gen4_on = "sim_gen4_on"
    local sim_gen1_fail = "sim_gen1_fail"
    local sim_gen2_fail = "sim_gen2_fail"
    local sim_gen3_fail = "sim_gen3_fail"
    local apu_gen_fail = "apu_gen_fail"
    local frame_time = "frame_time"

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

    local STATE = saved and copyState(saved) or {
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

    local function update()
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

    return {
        update = update,
        export = function()
            return copyState(STATE)
        end,
    }
end

return { bindings = bindings, outputs = outputs, create = create }
