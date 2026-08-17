--[[
Changelog
- Preserved all 26 original Dataref bindings, paths, constructors, and binding order.
- Replaced _G-based property assignment with SASL defineProperty() registration.
- Added SmartCopilot master/slave protection so the slave does not overwrite synchronized 115 V bus state.
- Reworked bus voltage and source-current calculation to use a deterministic local output state written once per frame.
- Removed the invalid BUS_AMP_LIMIT set() calls that attempted to write through numeric local variables.
- Removed artificial 300 A bus-current clipping so generator overload logic receives the real bus demand.
- Removed the duplicate APU-generator 111 V minimum clamp; generator voltage is now modeled only in generators_logic.lua.
- Added lower/upper voltage clamping for final bus voltages only.
- Preserved every existing generator/GPU source-priority branch and its original ordering.
- Preserved emergency-bus voltage assignments and all generator/GPU current-sharing formulas.
- Updated comments to describe the implemented source distribution instead of contradicting it.
]]

-- 115/200 V AC bus logic.
-- Three main buses and two emergency buses are supplied by engine generators,
-- the APU generator, or the GPU according to the explicit priority table below.

-- SmartCopilot
defineProperty("ismaster", globalPropertyf("scp/api/ismaster"))
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1"))

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Generator and GPU voltages
    { "gen1_volt_bus", "tu154/custom/elec/gen1_volt", globalPropertyf },
    { "gen2_volt_bus", "tu154/custom/elec/gen2_volt", globalPropertyf },
    { "gen3_volt_bus", "tu154/custom/elec/gen3_volt", globalPropertyf },
    { "gen4_volt_bus", "tu154/custom/elec/gen4_volt", globalPropertyf },
    { "gpu_volt_bus", "tu154/custom/elec/gpu_volt", globalPropertyf },
    -- Generator and GPU operating status
    { "gen1_work_bus", "tu154/custom/elec/gen1_work", globalPropertyi },
    { "gen2_work_bus", "tu154/custom/elec/gen2_work", globalPropertyi },
    { "gen3_work_bus", "tu154/custom/elec/gen3_work", globalPropertyi },
    { "gen4_work_bus", "tu154/custom/elec/gen4_work", globalPropertyi },
    { "gpu_work_bus", "tu154/custom/elec/gpu_work", globalPropertyi },
    -- Main and emergency 115 V bus voltages
    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "bus115_2_volt", "tu154/custom/elec/bus115_2_volt", globalPropertyf },
    { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },
    { "bus115_em_1_volt", "tu154/custom/elec/bus115_em_1_volt", globalPropertyf },
    { "bus115_em_2_volt", "tu154/custom/elec/bus115_em_2_volt", globalPropertyf },
    -- Main and emergency 115 V bus currents
    { "bus115_1_amp", "tu154/custom/elec/bus115_1_amp", globalPropertyf },
    { "bus115_2_amp", "tu154/custom/elec/bus115_2_amp", globalPropertyf },
    { "bus115_3_amp", "tu154/custom/elec/bus115_3_amp", globalPropertyf },
    { "bus115_em_1_amp", "tu154/custom/elec/bus115_em_1_amp", globalPropertyf },
    { "bus115_em_2_amp", "tu154/custom/elec/bus115_em_2_amp", globalPropertyf },
    -- Generator and GPU output currents
    { "gen1_amp", "tu154/custom/elec/gen1_amp", globalPropertyf },
    { "gen2_amp", "tu154/custom/elec/gen2_amp", globalPropertyf },
    { "gen3_amp", "tu154/custom/elec/gen3_amp", globalPropertyf },
    { "gen4_amp", "tu154/custom/elec/gen4_amp", globalPropertyf },
    { "gpu_amp", "tu154/custom/elec/gpu_amp", globalPropertyf },
    -- Timing
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
})

local BUS_VOLT_LIMIT = 230

local function clampVoltage(value)
    if value < 0 then
        return 0
    elseif value > BUS_VOLT_LIMIT then
        return BUS_VOLT_LIMIT
    end
    return value
end

local function writeOutputs(out)
    set(bus115_1_volt, out.bus1_volt)
    set(bus115_2_volt, out.bus2_volt)
    set(bus115_3_volt, out.bus3_volt)

    set(bus115_em_1_volt, out.bus_em_1_volt)
    set(bus115_em_2_volt, out.bus_em_2_volt)

    set(gen1_amp, out.gen1_amp)
    set(gen2_amp, out.gen2_amp)
    set(gen3_amp, out.gen3_amp)
    set(gen4_amp, out.gen4_amp)
    set(gpu_amp, out.gpu_amp)
end

function update()
    if get(frame_time) <= 0 then
        return
    end

    -- SmartCopilot slave receives synchronized electrical state.
    if get(ismaster) == 1 then
        return
    end

    --------------------------------------------------------------------------
    -- Cache current bus demand and source states
    --------------------------------------------------------------------------
    local bus1_amp = get(bus115_1_amp)
    local bus2_amp = get(bus115_2_amp)
    local bus3_amp = get(bus115_3_amp)

    local gen1_work = get(gen1_work_bus) == 1
    local gen2_work = get(gen2_work_bus) == 1
    local gen3_work = get(gen3_work_bus) == 1
    local gen4_work = get(gen4_work_bus) == 1
    local gpu_work = get(gpu_work_bus) == 1

    local gen1_volt = get(gen1_volt_bus)
    local gen2_volt = get(gen2_volt_bus)
    local gen3_volt = get(gen3_volt_bus)
    local gen4_volt = get(gen4_volt_bus)
    local gpu_volt = get(gpu_volt_bus)

    -- Deterministic default state prevents stale currents/voltages.
    local out = {
        bus1_volt = 0,
        bus2_volt = 0,
        bus3_volt = 0,
        bus_em_1_volt = 0,
        bus_em_2_volt = 0,

        gen1_amp = 0,
        gen2_amp = 0,
        gen3_amp = 0,
        gen4_amp = 0,
        gpu_amp = 0,
    }

    --------------------------------------------------------------------------
    -- Explicit source-priority logic
    --------------------------------------------------------------------------

    -- All three engine generators available:
    -- each main bus is powered by its corresponding generator.
    if gen1_work and gen2_work and gen3_work then
        out.bus1_volt = gen1_volt
        out.bus2_volt = gen2_volt
        out.bus3_volt = gen3_volt

        out.gen1_amp = bus1_amp
        out.gen2_amp = bus2_amp
        out.gen3_amp = bus3_amp

    -- Generator 1 unavailable: generator 2 powers buses 1 and 2,
    -- generator 3 powers bus 3.
    elseif gen2_work and gen3_work then
        out.bus1_volt = gen2_volt
        out.bus2_volt = gen2_volt
        out.bus3_volt = gen3_volt

        out.gen2_amp = bus1_amp + bus2_amp
        out.gen3_amp = bus3_amp

    -- Generator 2 unavailable with GPU available:
    -- generator 1 powers bus 1, GPU bus 2, generator 3 bus 3.
    elseif gen1_work and gen3_work and gpu_work then
        out.bus1_volt = gen1_volt
        out.bus2_volt = gpu_volt
        out.bus3_volt = gen3_volt

        out.gen1_amp = bus1_amp
        out.gen3_amp = bus3_amp
        out.gpu_amp = bus2_amp

    -- Generator 2 unavailable without GPU:
    -- generator 1 powers buses 1 and 2, generator 3 powers bus 3.
    elseif gen1_work and gen3_work then
        out.bus1_volt = gen1_volt
        out.bus2_volt = gen1_volt
        out.bus3_volt = gen3_volt

        out.gen1_amp = bus1_amp + bus2_amp
        out.gen3_amp = bus3_amp

    -- Generator 3 unavailable with GPU available:
    -- generators 1/2 keep buses 1/2, GPU powers bus 3.
    elseif gen1_work and gen2_work and gpu_work then
        out.bus1_volt = gen1_volt
        out.bus2_volt = gen2_volt
        out.bus3_volt = gpu_volt

        out.gen1_amp = bus1_amp
        out.gen2_amp = bus2_amp
        out.gpu_amp = bus3_amp

    -- Generator 3 unavailable without GPU:
    -- generator 1 powers bus 1, generator 2 powers buses 2 and 3.
    elseif gen1_work and gen2_work then
        out.bus1_volt = gen1_volt
        out.bus2_volt = gen2_volt
        out.bus3_volt = gen2_volt

        out.gen1_amp = bus1_amp
        out.gen2_amp = bus2_amp + bus3_amp

    -- One engine generator plus APU generator:
    -- engine generator powers buses 1 and 3; APU generator powers bus 2.
    elseif gen1_work and gen4_work then
        out.bus1_volt = gen1_volt
        out.bus2_volt = gen4_volt
        out.bus3_volt = gen1_volt

        out.gen1_amp = bus1_amp + bus3_amp
        out.gen4_amp = bus2_amp

    elseif gen2_work and gen4_work then
        out.bus1_volt = gen2_volt
        out.bus2_volt = gen4_volt
        out.bus3_volt = gen2_volt

        out.gen2_amp = bus1_amp + bus3_amp
        out.gen4_amp = bus2_amp

    elseif gen3_work and gen4_work then
        out.bus1_volt = gen3_volt
        out.bus2_volt = gen4_volt
        out.bus3_volt = gen3_volt

        out.gen3_amp = bus1_amp + bus3_amp
        out.gen4_amp = bus2_amp

    -- One engine generator plus GPU.
    elseif gen1_work and gpu_work then
        out.bus1_volt = gen1_volt
        out.bus2_volt = gpu_volt
        out.bus3_volt = gpu_volt

        out.gen1_amp = bus1_amp
        out.gpu_amp = bus2_amp + bus3_amp

    elseif gen2_work and gpu_work then
        out.bus1_volt = gpu_volt
        out.bus2_volt = gen2_volt
        out.bus3_volt = gpu_volt

        out.gen2_amp = bus2_amp
        out.gpu_amp = bus1_amp + bus3_amp

    elseif gen3_work and gpu_work then
        out.bus1_volt = gpu_volt
        out.bus2_volt = gpu_volt
        out.bus3_volt = gen3_volt

        out.gen3_amp = bus3_amp
        out.gpu_amp = bus1_amp + bus2_amp

    -- Single engine generator:
    -- existing logic powers buses 1 and 3; bus 2 remains unpowered.
    elseif gen1_work then
        out.bus1_volt = gen1_volt
        out.bus2_volt = 0
        out.bus3_volt = gen1_volt

        out.gen1_amp = bus1_amp + bus3_amp

    elseif gen2_work then
        out.bus1_volt = gen2_volt
        out.bus2_volt = 0
        out.bus3_volt = gen2_volt

        out.gen2_amp = bus1_amp + bus3_amp

    elseif gen3_work then
        out.bus1_volt = gen3_volt
        out.bus2_volt = 0
        out.bus3_volt = gen3_volt

        out.gen3_amp = bus1_amp + bus3_amp

    -- APU generator plus GPU:
    -- APU powers buses 1 and 2; GPU powers bus 3.
    elseif gen4_work and gpu_work then
        out.bus1_volt = gen4_volt
        out.bus2_volt = gen4_volt
        out.bus3_volt = gpu_volt

        out.gen4_amp = bus1_amp + bus2_amp
        out.gpu_amp = bus3_amp

    -- GPU only: all three main buses supplied by GPU.
    elseif gpu_work then
        out.bus1_volt = gpu_volt
        out.bus2_volt = gpu_volt
        out.bus3_volt = gpu_volt

        out.gpu_amp = bus1_amp + bus2_amp + bus3_amp

    -- APU generator only: preserve the existing behavior where all three
    -- main buses are supplied by the APU generator.
    elseif gen4_work then
        out.bus1_volt = gen4_volt
        out.bus2_volt = gen4_volt
        out.bus3_volt = gen4_volt

        out.gen4_amp = bus1_amp + bus2_amp + bus3_amp
    end

    --------------------------------------------------------------------------
    -- Emergency buses follow main buses 1 and 3 in every powered state.
    --------------------------------------------------------------------------
    out.bus_em_1_volt = out.bus1_volt
    out.bus_em_2_volt = out.bus3_volt

    --------------------------------------------------------------------------
    -- Final voltage protection only.
    -- Bus current demand is intentionally not clipped here because generator
    -- overload logic must see the real electrical load.
    --------------------------------------------------------------------------
    out.bus1_volt = clampVoltage(out.bus1_volt)
    out.bus2_volt = clampVoltage(out.bus2_volt)
    out.bus3_volt = clampVoltage(out.bus3_volt)
    out.bus_em_1_volt = clampVoltage(out.bus_em_1_volt)
    out.bus_em_2_volt = clampVoltage(out.bus_em_2_volt)

    writeOutputs(out)
end
