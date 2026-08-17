-- battery_logic.lua
-- Detailed logic for a single Tu-154M battery
-- including charging, discharging, thermal effects, and failures.

-- Bulk DataRef registration (excluding Smartcopilot)
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    {"bat_on_bus", "tu154/custom/switchers/eng/bat1_on", globalPropertyi}, -- Battery switch ON
    {"bat_source", "tu154/custom/elec/bat_is_source_1", globalPropertyi}, -- Battery is powering bus
    {"bat_amp_bus", "tu154/custom/elec/bat_amp_1", globalPropertyf}, -- Battery output current (A)
    {"bat_amp_cc", "tu154/custom/elec/bat_cc_1", globalPropertyf}, -- Battery charge current (A)
    {"bat_volt_bus", "tu154/custom/elec/bat_volt_1", globalPropertyf}, -- Battery voltage (V)
    {"bat_thermo", "tu154/custom/elec/bat_therm_1", globalPropertyf}, -- Battery temperature (°C)
    {"bat_fail", "tu154/custom/failures/bat_1_fail", globalPropertyi}, -- Battery failure flag
    {"bat_kz", "tu154/custom/failures/bat_1_kz", globalPropertyi}, -- Battery thermal runaway flag
    {"bus_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf}, -- 27V bus voltage (left)
    {"cockpit_temp", "tu154/custom/thermo/cockpit_temp", globalPropertyf}, -- Cockpit temperature (°C)
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf}, -- Simulation frame time (s)
    {"sim_bat_on", "sim/cockpit2/electrical/battery_on[0]", globalPropertyf}, -- X-Plane main battery switch (array [0])
})

defineProperty("ismaster",     globalPropertyf("scp/api/ismaster"))                   -- Smartcopilot master/slave state
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1"))               -- Smartcopilot control flag

-- Battery charge/discharge and temperature logic
local current_table = {
    { -5000, 0 },
    { 0, 0 },
    { 600, 100 },
    { 1200, 500 },
    { 1800, 1000 },
    { 20000, 1000 }
}

local bat_capacity = 75 - math.random() * 1.5 -- Initial battery capacity (Ah)
local BAT_CURRENT_COEF = 2    -- Charging current per Ah
local kz_timer = 0            -- Overheat timer (s)
local KzTimer = 1             -- Thermal runaway increment
local thermo = 20             -- Initial temperature (°C)

function update()
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
        local bat_volt = 17 + ((bat_capacity - kz_timer) / 2.5) - 1.5 * bat_amp / 100

        if bat_on == 1 then -- Battery is ON, proceed with calculations
            -- Discharge if battery is bus source
            if get(bat_source) == 1 then
                bat_capacity = bat_capacity - bat_amp * passed / 3600
                bat_volt = 17 + ((bat_capacity - kz_timer) / 2.5) - 1.5 * bat_amp / 100
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
            set(bat_volt_bus, 17 + ((bat_capacity - kz_timer) / 2.5) - 1.5 * bat_amp / 100)
        end
    end
end
