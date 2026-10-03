--[[
Changelog
2026-10-04
- Port the SASL battery calculation to independent numeric model instances.
- Preserve capacity, voltage, temperature, source selection and restorable state.
]]

-- battery.lua
-- Single battery capacity, voltage and thermal model.
-- Numeric I/O is provided by the caller; this module has no simulator API access.

local bindings = {
    { "bat_on_bus", "tu154/custom/switchers/eng/bat1_on", "integer" },
    { "bat_source", "tu154/custom/elec/bat_is_source_1", "integer" },
    { "bat_amp_bus", "tu154/custom/elec/bat_amp_1", "float" },
    { "bat_amp_cc", "tu154/custom/elec/bat_cc_1", "float" },
    { "bat_volt_bus", "tu154/custom/elec/bat_volt_1", "float" },
    { "bat_thermo", "tu154/custom/elec/bat_therm_1", "float" },
    { "bat_fail", "tu154/custom/failures/bat_1_fail", "integer" },
    { "bat_kz", "tu154/custom/failures/bat_1_kz", "integer" },
    { "bus_volt", "tu154/custom/elec/bus27_volt_left", "float" },
    { "cockpit_temp", "tu154/custom/thermo/cockpit_temp", "float" },
    { "frame_time", "tu154/custom/time/frame_time", "float" },
    { "sim_bat_on", "sim/cockpit2/electrical/battery_on", "integer", 0 },
    { "ismaster", "scp/api/ismaster", "float" },
}

local outputs = {
    "sim_bat_on",
    "bat_amp_cc",
    "bat_volt_bus",
    "bat_thermo",
}

local function create(io, saved)
    local get = io.get
    local set = io.set
    local interpolate = io.interpolate

    local bat_on_bus = "bat_on_bus"
    local bat_source = "bat_source"
    local bat_amp_bus = "bat_amp_bus"
    local bat_amp_cc = "bat_amp_cc"
    local bat_volt_bus = "bat_volt_bus"
    local bat_thermo = "bat_thermo"
    local bat_fail = "bat_fail"
    local bat_kz = "bat_kz"
    local bus_volt = "bus_volt"
    local cockpit_temp = "cockpit_temp"
    local frame_time = "frame_time"
    local sim_bat_on = "sim_bat_on"
    local ismaster = "ismaster"

    -- Battery charge/discharge and temperature logic
    local current_table = {
        { -5000, 0 },
        { 0, 0 },
        { 600, 100 },
        { 1200, 500 },
        { 1800, 1000 },
        { 20000, 1000 }
    }

    local RATED_CAPACITY_AH = 75
    local bat_capacity
    if saved then
        bat_capacity = saved.bat_capacity
    else
        bat_capacity = RATED_CAPACITY_AH - io.random() * 1.5 -- Initial battery capacity (Ah)
    end
    local BAT_CURRENT_COEF = 2    -- Charging current per Ah
    local kz_timer = saved and saved.kz_timer or 0 -- Overheat timer (s)
    local KzTimer = 1             -- Thermal runaway increment
    local thermo = saved and saved.thermo or 20 -- Initial temperature (°C)

    -- Capacity controls endurance; state of charge controls the 27 V battery curve.
    -- Using Ah directly with the old 2.5 divisor produced 47 V at 75 Ah.
    local function batteryVoltage(capacity, thermal_loss, current)
        local state_of_charge = math.max(0, math.min(1, (capacity - thermal_loss) / RATED_CAPACITY_AH))
        return math.max(0, 17 + 10 * state_of_charge - 1.5 * current / 100)
    end

    local function update()
        local MASTER = get(ismaster) ~= 1
        local passed = get(frame_time)
        local bat_on = get(bat_on_bus)
        local bat_amp = get(bat_amp_bus)
        local fail = get(bat_fail) == 1
        local kz = get(bat_kz) == 1

        set(sim_bat_on, bat_on)

        -- Calculate max capacity based on temperature (decreases at low temp)
        local MAX_BAT_CAPACITY = 75 + get(cockpit_temp)
        if MAX_BAT_CAPACITY > 75 then MAX_BAT_CAPACITY = 75
        elseif MAX_BAT_CAPACITY < 0 then MAX_BAT_CAPACITY = 0 end

        if bat_capacity > MAX_BAT_CAPACITY then
            bat_capacity = MAX_BAT_CAPACITY
        end

        if MASTER and passed > 0 then
            local bat_volt = batteryVoltage(bat_capacity, kz_timer, bat_amp)

            if bat_on == 1 then -- Battery is ON, proceed with calculations
                -- Discharge if battery is bus source
                if get(bat_source) == 1 then
                    bat_capacity = bat_capacity - bat_amp * passed / 3600
                    bat_volt = batteryVoltage(bat_capacity, kz_timer, bat_amp)
                    if bat_capacity < 2 then bat_volt = 3 end
                    set(bat_amp_cc, 0)
                else
                    -- Battery is not a source: charge or fail logic
                    if fail then
                        bat_capacity = 0
                        bat_volt = 3
                        MAX_BAT_CAPACITY = 0
                    end

                    -- Battery voltage cannot be lower than bus voltage
                    if get(bus_volt) > bat_volt then
                        bat_volt = get(bus_volt)
                    end

                    -- Charge battery when connected to bus
                    bat_capacity = bat_capacity + passed * 0.01
                    set(bat_amp_cc, (MAX_BAT_CAPACITY - bat_capacity) * BAT_CURRENT_COEF + interpolate(current_table, kz_timer))
                end

                -- Battery overheat (thermal runaway)
                if kz and kz_timer < 1800 then
                    kz_timer = kz_timer + passed * KzTimer
                end

                MAX_BAT_CAPACITY = MAX_BAT_CAPACITY - kz_timer

                set(bat_volt_bus, bat_volt)
                if bat_capacity < 0 then bat_capacity = 0 end
                if bat_capacity > MAX_BAT_CAPACITY then bat_capacity = MAX_BAT_CAPACITY end

                -- Simulate battery temperature rise
                thermo = 20 + get(bat_amp_cc) * 0.3
                set(bat_thermo, thermo)
            else
                -- Battery switch OFF or failed
                if fail then
                    bat_capacity = 0
                    set(bat_volt_bus, 3)
                    MAX_BAT_CAPACITY = 0
                end
                set(bat_amp_cc, 0)
                -- Gradually cool down
                if thermo > 20 then
                    thermo = thermo - passed * 0.5
                end
                set(bat_thermo, thermo)
                -- Voltage latches to last state
                set(bat_volt_bus, batteryVoltage(bat_capacity, kz_timer, bat_amp))
            end
        end
    end

    return {
        update = update,
        export = function()
            return { bat_capacity = bat_capacity, kz_timer = kz_timer, thermo = thermo }
        end,
    }
end

return { bindings = bindings, outputs = outputs, create = create }
