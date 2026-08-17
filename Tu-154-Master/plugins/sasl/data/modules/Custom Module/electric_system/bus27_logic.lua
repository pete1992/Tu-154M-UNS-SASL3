--[[
Changelog
- Grouped all 56 Dataref bindings through defineProps().
- Preserved all property names, Dataref paths, constructors, and original order except for the two corrected bus source bindings.
- Corrected bus27_source_left and bus27_source_right from globalPropertyf to globalPropertyi because the source Datarefs are integer source IDs.
- Replaced Russian comments with English comments.
- Added SmartCopilot master/slave protection so the slave does not overwrite synchronized electrical state.
- Reworked the frame calculation to build all source flags, voltages, and currents locally and write them once at the end of the frame.
- Eliminated stale VU and battery current values when a source becomes unavailable.
- Eliminated stale battery-source flags when a battery is no longer supplying a bus.
- Corrected in-flight APU-start source IDs so a dead 27 V bus reports source 0 instead of battery source 3.
- Cached battery, bus, APU, VU, failure, and switch values once per frame where practical.
- Preserved the original 28.5 V rectifier output, 115 V availability threshold, 550 A overload threshold, overload reset behavior, APU-start source priority, and load-sharing ratios.
- Preserved the original ground APU-start behavior where all available batteries share bus and starter load.
- Preserved the existing connected-bus source-ID behavior to avoid changing downstream indications.
]]

-- 27 V DC bus logic.
-- Each bus can be supplied by its main rectifier, the reserve rectifier,
-- batteries, or a connected/common bus configuration.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({

    -- Controls
    { "bus27_connect", "tu154/custom/switchers/eng/bus27_connect", globalPropertyi },
    { "bus27_vu1", "tu154/custom/switchers/eng/bus27_vu1", globalPropertyi },
    { "bus27_vu2", "tu154/custom/switchers/eng/bus27_vu2", globalPropertyi },
    { "bat1_on", "tu154/custom/switchers/eng/bat1_on", globalPropertyi },
    { "bat2_on", "tu154/custom/switchers/eng/bat2_on", globalPropertyi },
    { "bat3_on", "tu154/custom/switchers/eng/bat3_on", globalPropertyi },
    { "bat4_on", "tu154/custom/switchers/eng/bat4_on", globalPropertyi },
    -- Battery voltages
    { "bat_volt_1", "tu154/custom/elec/bat_volt_1", globalPropertyf },
    { "bat_volt_2", "tu154/custom/elec/bat_volt_2", globalPropertyf },
    { "bat_volt_3", "tu154/custom/elec/bat_volt_3", globalPropertyf },
    { "bat_volt_4", "tu154/custom/elec/bat_volt_4", globalPropertyf },
    -- Battery currents
    { "bat_amp_1", "tu154/custom/elec/bat_amp_1", globalPropertyf },
    { "bat_amp_2", "tu154/custom/elec/bat_amp_2", globalPropertyf },
    { "bat_amp_3", "tu154/custom/elec/bat_amp_3", globalPropertyf },
    { "bat_amp_4", "tu154/custom/elec/bat_amp_4", globalPropertyf },
    -- Battery thermal-runaway failures
    { "bat_1_kz", "tu154/custom/failures/bat_1_kz", globalPropertyi },
    { "bat_2_kz", "tu154/custom/failures/bat_2_kz", globalPropertyi },
    { "bat_3_kz", "tu154/custom/failures/bat_3_kz", globalPropertyi },
    { "bat_4_kz", "tu154/custom/failures/bat_4_kz", globalPropertyi },
    -- Battery failures
    { "bat_fail_1", "tu154/custom/failures/bat_1_fail", globalPropertyi },
    { "bat_fail_2", "tu154/custom/failures/bat_2_fail", globalPropertyi },
    { "bat_fail_3", "tu154/custom/failures/bat_3_fail", globalPropertyi },
    { "bat_fail_4", "tu154/custom/failures/bat_4_fail", globalPropertyi },
    -- Battery source flags
    { "bat_source_1", "tu154/custom/elec/bat_is_source_1", globalPropertyi },
    { "bat_source_2", "tu154/custom/elec/bat_is_source_2", globalPropertyi },
    { "bat_source_3", "tu154/custom/elec/bat_is_source_3", globalPropertyi },
    { "bat_source_4", "tu154/custom/elec/bat_is_source_4", globalPropertyi },
    -- APU state
    { "apu_system_on", "tu154/custom/eng/apu_system_on", globalPropertyi },
    { "apu_start_seq", "tu154/custom/elec/apu_start_seq", globalPropertyi },
    -- Rectifier voltages
    { "vu1_volt", "tu154/custom/elec/vu1_volt", globalPropertyf },
    { "vu2_volt", "tu154/custom/elec/vu2_volt", globalPropertyf },
    { "vu_res_volt", "tu154/custom/elec/vu_res_volt", globalPropertyf },
    -- Rectifier currents
    { "vu1_amp", "tu154/custom/elec/vu1_amp", globalPropertyf },
    { "vu2_amp", "tu154/custom/elec/vu2_amp", globalPropertyf },
    { "vu3_amp", "tu154/custom/elec/vu_res_amp", globalPropertyf },
    -- Rectifier failures
    { "vu1_fail", "tu154/custom/failures/vu1_fail", globalPropertyi },
    { "vu2_fail", "tu154/custom/failures/vu2_fail", globalPropertyi },
    { "vu3_fail", "tu154/custom/failures/vu3_fail", globalPropertyi },
    -- 115 V supply for rectifiers
    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },
    -- APU starter bus and load
    { "apu_start_bus", "tu154/custom/elec/apu_start_bus", globalPropertyf },
    { "apu_start_cc", "tu154/custom/elec/apu_start_cc", globalPropertyf },
    -- APU control
    { "apu_main_switch", "tu154/custom/switchers/eng/apu_main_switch", globalPropertyi },
    -- Ground detection
    { "gear_defl", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalPropertyf },
    -- 27 V bus results
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "bus27_amp_left", "tu154/custom/elec/bus27_amp_left", globalPropertyf },
    { "bus27_amp_right", "tu154/custom/elec/bus27_amp_right", globalPropertyf },
    { "bus27_source_left", "tu154/custom/elec/bus27_source_left", globalPropertyi },
    { "bus27_source_right", "tu154/custom/elec/bus27_source_right", globalPropertyi },
    -- Bus connection and reserve-rectifier routing
    { "buses_connected", "tu154/custom/elec/bus_connected", globalPropertyi },
    { "vu_res_to_L", "tu154/custom/elec/vu_res_to_L", globalPropertyi },
    { "vu_res_to_R", "tu154/custom/elec/vu_res_to_R", globalPropertyi },
    -- Timing
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    -- SmartCopilot
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf },
})

-- Source IDs currently produced by this module:
-- 0 = no source
-- 1 = main/rectifier source in normal or common-bus operation
-- 2 = reserve rectifier in separated-bus operation
-- 3 = battery source
local SOURCE_NONE = 0
local SOURCE_VU = 1
local SOURCE_RESERVE_VU = 2
local SOURCE_BATTERY = 3

local VU_OUTPUT_VOLTAGE = 28.5
local VU_INPUT_MIN_VOLTAGE = 115
local VU_OVERLOAD_CURRENT = 550

local STATE = {
    vu_overload_1 = false,
    vu_overload_2 = false,
    vu_overload_3 = false,
}

-- Kept as a global helper because the original module exposed it globally.
function bool2int(value)
    if value then
        return 1
    end
    return 0
end

-- Preserved legacy helper even though this module currently does not use it.
local function int2bool(value)
    return math.abs(value) ~= 0
end

local function weightedVoltage(v1, active1, v2, active2)
    local count = active1 + active2
    if count <= 0 then
        return 0
    end
    return (v1 * active1 + v2 * active2) / count
end

local function writeOutputs(out)
    set(bus27_volt_left, out.bus_volt_L)
    set(bus27_volt_right, out.bus_volt_R)

    set(bus27_source_left, out.source_L)
    set(bus27_source_right, out.source_R)

    set(buses_connected, out.buses_connected)

    set(vu_res_to_L, out.vu3_connL)
    set(vu_res_to_R, out.vu3_connR)

    set(vu1_amp, out.vu1_amp)
    set(vu2_amp, out.vu2_amp)
    set(vu3_amp, out.vu3_amp)

    set(bat_amp_1, out.bat_amp_1)
    set(bat_amp_2, out.bat_amp_2)
    set(bat_amp_3, out.bat_amp_3)
    set(bat_amp_4, out.bat_amp_4)

    set(bat_source_1, out.bat_source_1)
    set(bat_source_2, out.bat_source_2)
    set(bat_source_3, out.bat_source_3)
    set(bat_source_4, out.bat_source_4)

    set(apu_start_bus, out.apu_volt)
end

function update()
    if get(frame_time) <= 0 then
        return
    end

    -- SmartCopilot: the slave receives synchronized values and must not
    -- calculate/write the electrical network locally.
    if get(ismaster) == 1 then
        return
    end

    --------------------------------------------------------------------------
    -- Cache switches, failures, source voltages, and current loads
    --------------------------------------------------------------------------
    local vu1_sw = get(bus27_vu1)
    local vu2_sw = get(bus27_vu2)

    local bat1_on_now = get(bat1_on)
    local bat2_on_now = get(bat2_on)
    local bat3_on_now = get(bat3_on)
    local bat4_on_now = get(bat4_on)

    local bat_works_1 = bat1_on_now
        * (1 - get(bat_1_kz))
        * (1 - get(bat_fail_1))
    local bat_works_2 = bat2_on_now
        * (1 - get(bat_2_kz))
        * (1 - get(bat_fail_2))
    local bat_works_3 = bat3_on_now
        * (1 - get(bat_3_kz))
        * (1 - get(bat_fail_3))
    local bat_works_4 = bat4_on_now
        * (1 - get(bat_4_kz))
        * (1 - get(bat_fail_4))

    local bat_volt1 = get(bat_volt_1)
    local bat_volt2 = get(bat_volt_2)
    local bat_volt3 = get(bat_volt_3)
    local bat_volt4 = get(bat_volt_4)

    local bus115_1 = get(bus115_1_volt)
    local bus115_3 = get(bus115_3_volt)

    local previous_vu1_amp = get(vu1_amp)
    local previous_vu2_amp = get(vu2_amp)
    local previous_vu3_amp = get(vu3_amp)

    local bus_amp_L = get(bus27_amp_left)
    local bus_amp_R = get(bus27_amp_right)
    local apu_amp = get(apu_start_cc)

    local apu_starting = get(apu_start_seq) == 1
    local buses_forced_connected = get(bus27_connect) == 1
        or get(apu_system_on) == 1
    local on_ground = get(gear_defl) > 0.05

    --------------------------------------------------------------------------
    -- Rectifier availability
    --------------------------------------------------------------------------
    -- Availability is evaluated from the overload state of the previous frame,
    -- matching the original one-frame overload-trip behavior.
    local vu1_work = bus115_1 >= VU_INPUT_MIN_VOLTAGE
        and get(vu1_fail) == 0
        and not STATE.vu_overload_1

    local vu2_work = bus115_3 >= VU_INPUT_MIN_VOLTAGE
        and get(vu2_fail) == 0
        and not STATE.vu_overload_2

    local vu3_work = (
        bus115_1 >= VU_INPUT_MIN_VOLTAGE
        or bus115_3 >= VU_INPUT_MIN_VOLTAGE
    )
        and get(vu3_fail) == 0
        and not STATE.vu_overload_3

    set(vu1_volt, vu1_work and VU_OUTPUT_VOLTAGE or 0)
    set(vu2_volt, vu2_work and VU_OUTPUT_VOLTAGE or 0)
    set(vu_res_volt, vu3_work and VU_OUTPUT_VOLTAGE or 0)

    local vu1_conn = bool2int(vu1_work and vu1_sw == 1)
    local vu2_conn = bool2int(vu2_work and vu2_sw == 1)
    local vu3_connL = bool2int(vu3_work and vu1_sw == -1)
    local vu3_connR = bool2int(vu3_work and vu2_sw == -1)

    --------------------------------------------------------------------------
    -- Rectifier overload latches
    --------------------------------------------------------------------------
    if previous_vu1_amp > VU_OVERLOAD_CURRENT then
        STATE.vu_overload_1 = true
    elseif vu1_sw < 1 then
        STATE.vu_overload_1 = false
    end

    if previous_vu2_amp > VU_OVERLOAD_CURRENT then
        STATE.vu_overload_2 = true
    elseif vu2_sw < 1 then
        STATE.vu_overload_2 = false
    end

    if previous_vu3_amp > VU_OVERLOAD_CURRENT then
        STATE.vu_overload_3 = true
    elseif vu1_sw > -1 and vu2_sw > -1 then
        STATE.vu_overload_3 = false
    end

    --------------------------------------------------------------------------
    -- Start each frame with deterministic zero-current / no-source outputs.
    --------------------------------------------------------------------------
    local out = {
        source_L = SOURCE_NONE,
        source_R = SOURCE_NONE,

        bus_volt_L = 0,
        bus_volt_R = 0,
        apu_volt = 0,

        buses_connected = 0,

        vu3_connL = vu3_connL,
        vu3_connR = vu3_connR,

        vu1_amp = 0,
        vu2_amp = 0,
        vu3_amp = 0,

        bat_amp_1 = 0,
        bat_amp_2 = 0,
        bat_amp_3 = 0,
        bat_amp_4 = 0,

        bat_source_1 = 0,
        bat_source_2 = 0,
        bat_source_3 = 0,
        bat_source_4 = 0,
    }

    --------------------------------------------------------------------------
    -- APU starter operation: buses are connected
    --------------------------------------------------------------------------
    if apu_starting then
        out.buses_connected = 1

        -- During APU start the reserve rectifier is automatically available
        -- as a common source whenever it can produce power.
        local vu3_auto = bool2int(vu3_work)
        local vu_count = vu1_conn + vu2_conn + vu3_auto

        if vu_count > 0 then
            local total_load = bus_amp_L + bus_amp_R + apu_amp

            out.source_L = SOURCE_VU
            out.source_R = SOURCE_VU
            out.bus_volt_L = VU_OUTPUT_VOLTAGE
            out.bus_volt_R = VU_OUTPUT_VOLTAGE
            out.apu_volt = VU_OUTPUT_VOLTAGE

            out.vu1_amp = total_load * vu1_conn / vu_count
            out.vu2_amp = total_load * vu2_conn / vu_count
            out.vu3_amp = total_load * vu3_auto / vu_count

            if vu3_work then
                out.vu3_connL = 1
                out.vu3_connR = 1
            end

        elseif on_ground then
            ------------------------------------------------------------------
            -- Ground APU start from batteries
            ------------------------------------------------------------------
            local battery_count = bat_works_1
                + bat_works_2
                + bat_works_3
                + bat_works_4

            if battery_count > 0 then
                local total_load = bus_amp_L + bus_amp_R + apu_amp
                local common_battery_voltage = (
                    bat_volt1 * bat_works_1
                    + bat_volt2 * bat_works_2
                    + bat_volt3 * bat_works_3
                    + bat_volt4 * bat_works_4
                ) / battery_count

                out.source_L = SOURCE_BATTERY
                out.source_R = SOURCE_BATTERY
                out.bus_volt_L = common_battery_voltage
                out.bus_volt_R = common_battery_voltage
                out.apu_volt = common_battery_voltage

                out.bat_source_1 = bat_works_1
                out.bat_source_2 = bat_works_2
                out.bat_source_3 = bat_works_3
                out.bat_source_4 = bat_works_4

                out.bat_amp_1 = total_load * bat_works_1 / battery_count
                out.bat_amp_2 = total_load * bat_works_2 / battery_count
                out.bat_amp_3 = total_load * bat_works_3 / battery_count
                out.bat_amp_4 = total_load * bat_works_4 / battery_count
            end

        else
            ------------------------------------------------------------------
            -- In-flight APU start from batteries
            -- Batteries 1/2 supply the 27 V buses; 3/4 supply the APU starter.
            ------------------------------------------------------------------
            local bus_battery_count = bat_works_1 + bat_works_2
            local starter_battery_count = bat_works_3 + bat_works_4

            out.bat_source_1 = bat_works_1
            out.bat_source_2 = bat_works_2
            out.bat_source_3 = bat_works_3
            out.bat_source_4 = bat_works_4

            if bus_battery_count > 0 then
                local common_bus_voltage = weightedVoltage(
                    bat_volt1, bat_works_1,
                    bat_volt2, bat_works_2
                )

                out.source_L = SOURCE_BATTERY
                out.source_R = SOURCE_BATTERY
                out.bus_volt_L = common_bus_voltage
                out.bus_volt_R = common_bus_voltage

                local total_bus_load = bus_amp_L + bus_amp_R
                out.bat_amp_1 = total_bus_load
                    * bat_works_1 / bus_battery_count
                out.bat_amp_2 = total_bus_load
                    * bat_works_2 / bus_battery_count
            end

            if starter_battery_count > 0 then
                out.apu_volt = weightedVoltage(
                    bat_volt3, bat_works_3,
                    bat_volt4, bat_works_4
                )

                out.bat_amp_3 = apu_amp
                    * bat_works_3 / starter_battery_count
                out.bat_amp_4 = apu_amp
                    * bat_works_4 / starter_battery_count
            end
        end

    --------------------------------------------------------------------------
    -- Manually connected buses or APU system switched on
    --------------------------------------------------------------------------
    elseif buses_forced_connected then
        out.buses_connected = 1

        local connected_vu_count = vu1_conn
            + vu2_conn
            + vu3_connL
            + vu3_connR

        if connected_vu_count > 0 then
            local total_bus_load = bus_amp_L + bus_amp_R

            -- Preserve original source-ID behavior for a common VU-fed bus.
            out.source_L = SOURCE_VU
            out.source_R = SOURCE_VU
            out.bus_volt_L = VU_OUTPUT_VOLTAGE
            out.bus_volt_R = VU_OUTPUT_VOLTAGE
            out.apu_volt = VU_OUTPUT_VOLTAGE

            out.vu1_amp = total_bus_load
                * vu1_conn / connected_vu_count
            out.vu2_amp = total_bus_load
                * vu2_conn / connected_vu_count
            out.vu3_amp = total_bus_load
                * (vu3_connL + vu3_connR) / connected_vu_count

        else
            local battery_count = bat_works_1
                + bat_works_2
                + bat_works_3
                + bat_works_4

            if battery_count > 0 then
                local total_bus_load = bus_amp_L + bus_amp_R
                local common_battery_voltage = (
                    bat_volt1 * bat_works_1
                    + bat_volt2 * bat_works_2
                    + bat_volt3 * bat_works_3
                    + bat_volt4 * bat_works_4
                ) / battery_count

                out.source_L = SOURCE_BATTERY
                out.source_R = SOURCE_BATTERY
                out.bus_volt_L = common_battery_voltage
                out.bus_volt_R = common_battery_voltage
                out.apu_volt = common_battery_voltage

                out.bat_source_1 = bat_works_1
                out.bat_source_2 = bat_works_2
                out.bat_source_3 = bat_works_3
                out.bat_source_4 = bat_works_4

                out.bat_amp_1 = total_bus_load
                    * bat_works_1 / battery_count
                out.bat_amp_2 = total_bus_load
                    * bat_works_2 / battery_count
                out.bat_amp_3 = total_bus_load
                    * bat_works_3 / battery_count
                out.bat_amp_4 = total_bus_load
                    * bat_works_4 / battery_count
            end
        end

    --------------------------------------------------------------------------
    -- Normal separated-bus operation
    --------------------------------------------------------------------------
    else
        ----------------------------------------------------------------------
        -- Left bus
        ----------------------------------------------------------------------
        if vu1_work and vu1_sw == 1 then
            out.source_L = SOURCE_VU
            out.bus_volt_L = VU_OUTPUT_VOLTAGE
            out.vu1_amp = bus_amp_L

        elseif vu3_work and vu1_sw == -1 then
            out.source_L = SOURCE_RESERVE_VU
            out.bus_volt_L = VU_OUTPUT_VOLTAGE
            out.vu3_amp = out.vu3_amp + bus_amp_L

        else
            local left_battery_count = bat_works_1 + bat_works_3

            if left_battery_count > 0 then
                out.source_L = SOURCE_BATTERY
                out.bus_volt_L = weightedVoltage(
                    bat_volt1, bat_works_1,
                    bat_volt3, bat_works_3
                )

                out.bat_source_1 = bat_works_1
                out.bat_source_3 = bat_works_3

                out.bat_amp_1 = bus_amp_L
                    * bat_works_1 / left_battery_count
                out.bat_amp_3 = bus_amp_L
                    * bat_works_3 / left_battery_count
            end
        end

        ----------------------------------------------------------------------
        -- Right bus
        ----------------------------------------------------------------------
        if vu2_work and vu2_sw == 1 then
            out.source_R = SOURCE_VU
            out.bus_volt_R = VU_OUTPUT_VOLTAGE
            out.vu2_amp = bus_amp_R

        elseif vu3_work and vu2_sw == -1 then
            out.source_R = SOURCE_RESERVE_VU
            out.bus_volt_R = VU_OUTPUT_VOLTAGE
            out.vu3_amp = out.vu3_amp + bus_amp_R

        else
            local right_battery_count = bat_works_2 + bat_works_4

            if right_battery_count > 0 then
                out.source_R = SOURCE_BATTERY
                out.bus_volt_R = weightedVoltage(
                    bat_volt2, bat_works_2,
                    bat_volt4, bat_works_4
                )

                out.bat_source_2 = bat_works_2
                out.bat_source_4 = bat_works_4

                out.bat_amp_2 = bus_amp_R
                    * bat_works_2 / right_battery_count
                out.bat_amp_4 = bus_amp_R
                    * bat_works_4 / right_battery_count
            end
        end
    end

    writeOutputs(out)
end
