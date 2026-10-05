-- eng_fails.lua
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
    -- failures
    -- Engine lifetime
    { "engine_runtime_1", "tu154/custom/failures/engine_runtime_1", globalPropertyf },
    { "engine_runtime_2", "tu154/custom/failures/engine_runtime_2", globalPropertyf },
    { "engine_runtime_3", "tu154/custom/failures/engine_runtime_3", globalPropertyf },

    -- Oil quantity
    { "engn_oil_qty_1", "tu154/custom/failures/engn_oil_qty_1", globalPropertyf },
    { "engn_oil_qty_2", "tu154/custom/failures/engn_oil_qty_2", globalPropertyf },
    { "engn_oil_qty_3", "tu154/custom/failures/engn_oil_qty_3", globalPropertyf },

    -- Oil leaks
    { "engn_oil_leak_1", "tu154/custom/failures/engn_oil_leak_1", globalPropertyi },
    { "engn_oil_leak_2", "tu154/custom/failures/engn_oil_leak_2", globalPropertyi },
    { "engn_oil_leak_3", "tu154/custom/failures/engn_oil_leak_3", globalPropertyi },

    -- Oil pump failures
    { "oil_pump_fail_1", "sim/operation/failures/rel_oilpmp0", globalPropertyi },
    { "oil_pump_fail_2", "sim/operation/failures/rel_oilpmp1", globalPropertyi },
    { "oil_pump_fail_3", "sim/operation/failures/rel_oilpmp2", globalPropertyi },

    -- Fuel flowmeter failures
    { "fuel_flowmeter_1_fail", "tu154/custom/failures/fuel_flowmeter_1_fail", globalPropertyi },
    { "fuel_flowmeter_2_fail", "tu154/custom/failures/fuel_flowmeter_2_fail", globalPropertyi },
    { "fuel_flowmeter_3_fail", "tu154/custom/failures/fuel_flowmeter_3_fail", globalPropertyi },

    -- Engine failures
    { "eng_fail_1", "sim/operation/failures/rel_engfai0", globalPropertyi },
    { "eng_fail_2", "sim/operation/failures/rel_engfai1", globalPropertyi },
    { "eng_fail_3", "sim/operation/failures/rel_engfai2", globalPropertyi },

    -- Engine fires
    { "eng_fire_1", "sim/operation/failures/rel_engfir0", globalPropertyi },
    { "eng_fire_2", "sim/operation/failures/rel_engfir1", globalPropertyi },
    { "eng_fire_3", "sim/operation/failures/rel_engfir2", globalPropertyi },

    -- Engine flameouts
    { "eng_flame_1", "sim/operation/failures/rel_engfla0", globalPropertyi },
    { "eng_flame_2", "sim/operation/failures/rel_engfla1", globalPropertyi },
    { "eng_flame_3", "sim/operation/failures/rel_engfla2", globalPropertyi },

    -- Compressor stalls
    { "eng_stall_1", "sim/operation/failures/rel_comsta0", globalPropertyi },
    { "eng_stall_2", "sim/operation/failures/rel_comsta1", globalPropertyi },
    { "eng_stall_3", "sim/operation/failures/rel_comsta2", globalPropertyi },

    -- Engine fuel pump failures
    { "eng_fuel_pmp_fail_1", "tu154/custom/failures/eng_fuel_pmp_fail_1", globalPropertyi },
    { "eng_fuel_pmp_fail_2", "tu154/custom/failures/eng_fuel_pmp_fail_2", globalPropertyi },
    { "eng_fuel_pmp_fail_3", "tu154/custom/failures/eng_fuel_pmp_fail_3", globalPropertyi },

    -- Fuel filter failures
    { "eng_filter_1", "sim/operation/failures/rel_eng_lo0", globalPropertyi },
    { "eng_filter_2", "sim/operation/failures/rel_eng_lo1", globalPropertyi },
    { "eng_filter_3", "sim/operation/failures/rel_eng_lo2", globalPropertyi },

    -- Starter failures
    { "eng_start_1", "sim/operation/failures/rel_startr0", globalPropertyi },
    { "eng_start_2", "sim/operation/failures/rel_startr1", globalPropertyi },
    { "eng_start_3", "sim/operation/failures/rel_startr2", globalPropertyi },

    -- Ignition failures
    { "eng_ign_1", "sim/operation/failures/rel_ignitr0", globalPropertyi },
    { "eng_ign_2", "sim/operation/failures/rel_ignitr1", globalPropertyi },
    { "eng_ign_3", "sim/operation/failures/rel_ignitr2", globalPropertyi },

    -- Reverser failures
    { "eng_revrs_1", "sim/operation/failures/rel_revers0", globalPropertyi },
    { "eng_revrs_3", "sim/operation/failures/rel_revers2", globalPropertyi },

    -- Simulator oil quantity
    { "ENGN_oil_q_1", "sim/flightmodel/engine/ENGN_oil_quan", globalPropertyfae, 1 },
    { "ENGN_oil_q_2", "sim/flightmodel/engine/ENGN_oil_quan", globalPropertyfae, 2 },
    { "ENGN_oil_q_3", "sim/flightmodel/engine/ENGN_oil_quan", globalPropertyfae, 3 },

    -- Fuel flow fluctuation
    { "fuel_fluct_1", "sim/operation/failures/rel_fuelfl0", globalPropertyi }, -- Fuel Flow Fluctuation
    { "fuel_fluct_2", "sim/operation/failures/rel_fuelfl1", globalPropertyi }, -- Fuel Flow Fluctuation
    { "fuel_fluct_3", "sim/operation/failures/rel_fuelfl2", globalPropertyi }, -- Fuel Flow Fluctuation

    -- Simulator exhaust gas temperature
    { "sim_egt_1", "sim/flightmodel2/engines/EGT_deg_cel", globalPropertyfae, 1 }, -- EGT from sim
    { "sim_egt_2", "sim/flightmodel2/engines/EGT_deg_cel", globalPropertyfae, 2 }, -- EGT from sim
    { "sim_egt_3", "sim/flightmodel2/engines/EGT_deg_cel", globalPropertyfae, 3 }, -- EGT from sim

    -- Physical fire state; native failure enums remain ignition commands.
    { "engine_fire_1", "sim/flightmodel2/engines/is_on_fire", globalPropertyfae, 1 },
    { "engine_fire_2", "sim/flightmodel2/engines/is_on_fire", globalPropertyfae, 2 },
    { "engine_fire_3", "sim/flightmodel2/engines/is_on_fire", globalPropertyfae, 3 },

    -- engines data
    { "eng_rpm1", "sim/flightmodel2/engines/N2_percent", globalPropertyfae, 1 }, --     №1
    { "eng_rpm2", "sim/flightmodel2/engines/N2_percent", globalPropertyfae, 2 }, --     №2
    { "eng_rpm3", "sim/flightmodel2/engines/N2_percent", globalPropertyfae, 3 }, --     №3

    { "eng_work_1", "sim/flightmodel2/engines/engine_is_burning_fuel", globalPropertyiae, 1 },
    { "eng_work_2", "sim/flightmodel2/engines/engine_is_burning_fuel", globalPropertyiae, 2 },
    { "eng_work_3", "sim/flightmodel2/engines/engine_is_burning_fuel", globalPropertyiae, 3 },

    { "alpha", "sim/flightmodel2/misc/AoA_angle_degrees", globalPropertyf },  -- angle of attack
    { "msl_alt", "sim/flightmodel/position/elevation", globalPropertyf },  -- phisical altitude MSL. meters
    { "baro_press", "sim/weather/barometer_sealevel_inhg", globalPropertyf }, -- physical calibration altitude
    { "msl_press", "sim/weather/barometer_sealevel_inhg", globalPropertyf },  -- pressire at sea level in.Hg
    { "pressure", "tu154/custom/gauges/alt/vbe_press_left", globalPropertyf },  -- pressure in hPa

    -- time
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time

    -- Failure configuration
    { "failures_enabled", "tu154/custom/failures/failures_enabled", globalPropertyi },

    -- Smart Copilot
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- Master. 0 = plugin not found, 1 = slave 2 = master
})

-- put oil before every flight
set(engn_oil_qty_1, math.random() + 26)
set(engn_oil_qty_2, math.random() + 26)
set(engn_oil_qty_3, math.random() + 26)

set(engine_runtime_1, math.random(280,320) * 3600)
set(engine_runtime_2, math.random(280,320) * 3600)
set(engine_runtime_3, math.random(280,320) * 3600)

-- Use the same Tu-154 N2 scale as the tachometer, without its display lag.
local HP_GROUND_TABLE = {
    {-100000, 0.0},
    {0, 0},
    {23, 21},
    {73.78, 60.5},
    {89.46, 82.5},
    {93.1, 86.5},
    {94.88, 88.75},
    {97.46, 91.9},
    {98.47, 93.5},
    {99.52, 95.0},
    {110.0, 105.0},
    {1000000000, 105.0},
}

local HP_11KM_TABLE = {
    {-100000, 0.0},
    {0, 0},
    {23, 21},
    {89.67, 78.0},
    {92.83, 82.25},
    {96.94, 86.75},
    {98.31, 88.75},
    {99.95, 92.5},
    {100.5, 94.0},
    {101.3, 96.5},
    {110.0, 100.0},
    {1000000000, 100.0},
}

local function physicalRPM(native_n2, altitude)
    local rpm = safeClamp(native_n2, 0, 110, 0)
    return line(altitude, 0, interpolate(HP_GROUND_TABLE, rpm),
        11000, interpolate(HP_11KM_TABLE, rpm))
end

local engnRuntimeCoef = {
  {-1000, 0},
  {0, 0.5},
  {30, 1},
  {90, 1},
  {100, 2},
  {1000, 10} 
  }

local oilLeak1 = math.random(20, 100)
local oilLeak2 = math.random(20, 100)
local oilLeak3 = math.random(20, 100)

local minusTimer1 = 0
local minusTimer2 = 0
local minusTimer3 = 0

local fail_counter = 0
local stall_counter = 0
local check_time = math.random(15, 30)
local stall_time = math.random()

local engToCounter1 = 0
local engToCounter2 = 0
local engToCounter3 = 0

-- LOW may recover only compressor stalls caused by this local causal roll.
local low_stall_owned = {false, false, false}
local low_stall_properties = {eng_stall_1, eng_stall_2, eng_stall_3}
local engine_work_properties = {eng_work_1, eng_work_2, eng_work_3}

local function discardLowStallOwnership()
    for engine = 1, 3 do low_stall_owned[engine] = false end
end

function update()
    
	local passed = get(frame_time)
 
if get(ismaster) ~= 1 then		
	
	local level = get(failures_enabled)
	local FAIL = level * 0.05 * 4 ^ (level * 0.5)
	local random_factor = level > 1 and FAIL or 0
	local damage_factor = FAIL
	if level ~= 1 then
		discardLowStallOwnership()
	else
		-- An observed external repair or scheduling change relinquishes local ownership.
		for engine = 1, 3 do
			if low_stall_owned[engine] and get(low_stall_properties[engine]) ~= 6 then
				low_stall_owned[engine] = false
			end
		end
	end
	
	-- check failures
	if FAIL > 0 then
		local altitude = safeClamp(get(msl_alt) * 3.28083 * 0.3048
			+ (29.92 - get(baro_press)) * 1000 * 0.3048, 0, 11000, 0)
		local rpm1 = physicalRPM(get(eng_rpm1), altitude)
		local rpm2 = physicalRPM(get(eng_rpm2), altitude)
		local rpm3 = physicalRPM(get(eng_rpm3), altitude)
		
		-- check engine stall
		stall_counter = stall_counter + passed
		
		if stall_counter > stall_time then
			stall_counter = 0
			stall_time = math.random()
			
			local aoa = get(alpha) - 2
			
			local AOA_coef = 0
			
			if aoa > -80 and aoa < 80 then
				
				aoa = math.max(0, (math.abs(aoa) - 10))
				AOA_coef = math.tan(math.rad(aoa)) / 5.671
			
			else AOA_coef = 1 end
			
			local msl = get(msl_alt) * 3.28083 -- real alt MSL in feet
			local altitude_ft = msl + (get(pressure) * 0.0295300586467 - get(msl_press)) * 1000  -- calculate barometric altitude in feet
			local alt_mtr = altitude_ft * 0.3048
			local ALT_coef = math.max(0, alt_mtr - 8000) / 10000
			
			local RPM_coef_1 = math.max(0, rpm1 * 0.01 - 0.7) * 3
			local RPM_coef_2 = math.max(0, rpm2 * 0.01 - 0.7) * 3
			local RPM_coef_3 = math.max(0, rpm3 * 0.01 - 0.7) * 3
			
			if random_factor > 0 then
			if get(eng_stall_1) ~= 6 then set(eng_stall_1, bool2int(math.random() < 1 * AOA_coef * ALT_coef * RPM_coef_1) * 6) end
			if get(eng_stall_2) ~= 6 then set(eng_stall_2, bool2int(math.random() < 1 * AOA_coef * ALT_coef * RPM_coef_2) * 6) end
			if get(eng_stall_3) ~= 6 then set(eng_stall_3, bool2int(math.random() < 1 * AOA_coef * ALT_coef * RPM_coef_3) * 6) end
			
			-- reset stall, if engine is not working
			if get(eng_work_1) == 0 then set(eng_stall_1, 0) end
			if get(eng_work_2) == 0 then set(eng_stall_2, 0) end
			if get(eng_work_3) == 0 then set(eng_stall_3, 0) end
			else
				-- LOW owns only newly caused stalls; external and scheduled faults stay untouched.
				local probability1 = AOA_coef * ALT_coef * RPM_coef_1
				if probability1 > 0 and get(eng_stall_1) == 0 and get(eng_work_1) == 1 then
					if math.random() < probability1 then set(eng_stall_1, 6); low_stall_owned[1] = true end
				end
				local probability2 = AOA_coef * ALT_coef * RPM_coef_2
				if probability2 > 0 and get(eng_stall_2) == 0 and get(eng_work_2) == 1 then
					if math.random() < probability2 then set(eng_stall_2, 6); low_stall_owned[2] = true end
				end
				local probability3 = AOA_coef * ALT_coef * RPM_coef_3
				if probability3 > 0 and get(eng_stall_3) == 0 and get(eng_work_3) == 1 then
					if math.random() < probability3 then set(eng_stall_3, 6); low_stall_owned[3] = true end
				end
				-- Preserve the original stopped-engine recovery at the same stall-check time.
				for engine = 1, 3 do
					if low_stall_owned[engine] and get(engine_work_properties[engine]) == 0 then
						if get(low_stall_properties[engine]) == 6 then set(low_stall_properties[engine], 0) end
						low_stall_owned[engine] = false
					end
				end
			end
			
		end
		
		fail_counter = fail_counter + passed
		
		if fail_counter > check_time then
			fail_counter = 0
			check_time = math.random(15, 30)
			if random_factor > 0 then
			
			-- random failures
			if get(engn_oil_leak_1) ~= 1 then set(engn_oil_leak_1, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 1) end
			if get(engn_oil_leak_2) ~= 1 then set(engn_oil_leak_2, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 1) end
			if get(engn_oil_leak_3) ~= 1 then set(engn_oil_leak_3, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 1) end
			
			if get(oil_pump_fail_1) ~= 6 then set(oil_pump_fail_1, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			if get(oil_pump_fail_2) ~= 6 then set(oil_pump_fail_2, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			if get(oil_pump_fail_3) ~= 6 then set(oil_pump_fail_3, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			
			if get(fuel_flowmeter_1_fail) ~= 1 then set(fuel_flowmeter_1_fail, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 1) end
			if get(fuel_flowmeter_2_fail) ~= 1 then set(fuel_flowmeter_2_fail, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 1) end
			if get(fuel_flowmeter_3_fail) ~= 1 then set(fuel_flowmeter_3_fail, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 1) end
			
			if get(eng_fail_1) ~= 6 then set(eng_fail_1, bool2int(math.random() < 0.00001 * random_factor * 0.3 + bool2int(engToCounter1 > 300) * 0.0001) * 6) end
			if get(eng_fail_2) ~= 6 then set(eng_fail_2, bool2int(math.random() < 0.00001 * random_factor * 0.3 + bool2int(engToCounter2 > 300) * 0.0001) * 6) end
			if get(eng_fail_3) ~= 6 then set(eng_fail_3, bool2int(math.random() < 0.00001 * random_factor * 0.3 + bool2int(engToCounter3 > 300) * 0.0001) * 6) end
			
			if get(eng_work_1) == 1 then
				if get(eng_fire_1) ~= 6 then set(eng_fire_1, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
				if get(eng_fire_1) ~= 6 and get(sim_egt_1) > 600 then set(eng_fire_1, bool2int(math.random() < 0.001 * damage_factor * 0.3) * 6) end
			end
			
			if get(eng_work_2) == 1 then
				if get(eng_fire_2) ~= 6 then set(eng_fire_2, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
				if get(eng_fire_2) ~= 6 and get(sim_egt_2) > 600 then set(eng_fire_2, bool2int(math.random() < 0.001 * damage_factor * 0.3) * 6) end
			end
			
			if get(eng_work_3) == 1 then
				if get(eng_fire_3) ~= 6 then set(eng_fire_3, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
				if get(eng_fire_3) ~= 6 and get(sim_egt_3) > 600 then set(eng_fire_3, bool2int(math.random() < 0.001 * damage_factor * 0.3) * 6) end
			end
			
			if get(eng_fuel_pmp_fail_1) ~= 1 then set(eng_fuel_pmp_fail_1, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 1) end
			if get(eng_fuel_pmp_fail_2) ~= 1 then set(eng_fuel_pmp_fail_2, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 1) end
			if get(eng_fuel_pmp_fail_3) ~= 1 then set(eng_fuel_pmp_fail_3, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 1) end
			
			if get(eng_filter_1) ~= 6 then set(eng_filter_1, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			if get(eng_filter_2) ~= 6 then set(eng_filter_2, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			if get(eng_filter_3) ~= 6 then set(eng_filter_3, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			
			if get(eng_start_1) ~= 6 then set(eng_start_1, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			if get(eng_start_2) ~= 6 then set(eng_start_2, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			if get(eng_start_3) ~= 6 then set(eng_start_3, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			
			if get(eng_ign_1) ~= 6 then set(eng_ign_1, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			if get(eng_ign_2) ~= 6 then set(eng_ign_2, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			if get(eng_ign_3) ~= 6 then set(eng_ign_3, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			
			if get(eng_revrs_1) ~= 6 then set(eng_revrs_1, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			if get(eng_revrs_3) ~= 6 then set(eng_revrs_3, bool2int(math.random() < 0.00001 * random_factor * 0.3) * 6) end
			
			else
				-- LOW retains causal damage without spontaneous failures or clearing scheduled faults.
				if engToCounter1 > 300 and get(eng_fail_1) == 0 then
					if math.random() < 0.0001 then set(eng_fail_1, 6) end
				end
				if get(eng_work_1) == 1 and get(sim_egt_1) > 600 and get(eng_fire_1) == 0 then
					if math.random() < 0.001 * damage_factor * 0.3 then set(eng_fire_1, 6) end
				end
				if engToCounter2 > 300 and get(eng_fail_2) == 0 then
					if math.random() < 0.0001 then set(eng_fail_2, 6) end
				end
				if get(eng_work_2) == 1 and get(sim_egt_2) > 600 and get(eng_fire_2) == 0 then
					if math.random() < 0.001 * damage_factor * 0.3 then set(eng_fire_2, 6) end
				end
				if engToCounter3 > 300 and get(eng_fail_3) == 0 then
					if math.random() < 0.0001 then set(eng_fail_3, 6) end
				end
				if get(eng_work_3) == 1 and get(sim_egt_3) > 600 and get(eng_fire_3) == 0 then
					if math.random() < 0.001 * damage_factor * 0.3 then set(eng_fire_3, 6) end
				end
			end
		end
		
		-- dependent failures
		
		-- OIL
		-- normal usage = 1 litre/h
		set(engn_oil_qty_1, math.max(0, get(engn_oil_qty_1) - rpm1 * 0.01 * passed / 3600))
		set(engn_oil_qty_2, math.max(0, get(engn_oil_qty_2) - rpm2 * 0.01 * passed / 3600))
		set(engn_oil_qty_3, math.max(0, get(engn_oil_qty_3) - rpm3 * 0.01 * passed / 3600))
		
		-- oil leak
		set(engn_oil_qty_1, get(engn_oil_qty_1) - get(engn_oil_leak_1) * passed / 3600 * oilLeak1)
		set(engn_oil_qty_2, get(engn_oil_qty_2) - get(engn_oil_leak_2) * passed / 3600 * oilLeak2)
		set(engn_oil_qty_3, get(engn_oil_qty_3) - get(engn_oil_leak_3) * passed / 3600 * oilLeak3)
		
		-- oil pump fail if engine work
		if get(engn_oil_qty_1) < 4 and rpm1 > 20 and (random_factor > 0 or get(oil_pump_fail_1) == 0) then set(oil_pump_fail_1, 6) end
		if get(engn_oil_qty_2) < 4 and rpm2 > 20 and (random_factor > 0 or get(oil_pump_fail_2) == 0) then set(oil_pump_fail_2, 6) end
		if get(engn_oil_qty_3) < 4 and rpm3 > 20 and (random_factor > 0 or get(oil_pump_fail_3) == 0) then set(oil_pump_fail_3, 6) end
		
		-- sim oil sync
		set(ENGN_oil_q_1, math.max(0, (get(engn_oil_qty_1) - 4)/23))
		set(ENGN_oil_q_2, math.max(0, (get(engn_oil_qty_2) - 4)/23))
		set(ENGN_oil_q_3, math.max(0, (get(engn_oil_qty_3) - 4)/23))
		
		-- engine runtime
		minusTimer1 = minusTimer1 + interpolate(engnRuntimeCoef, rpm1) * passed
		minusTimer2 = minusTimer2 + interpolate(engnRuntimeCoef, rpm2) * passed
		minusTimer3 = minusTimer3 + interpolate(engnRuntimeCoef, rpm3) * passed
		
		if minusTimer1 >= 1 then
			minusTimer1 = 0
			set(engine_runtime_1, math.max(0, get(engine_runtime_1) - 1))
		end
		
		if minusTimer2 >= 1 then
			minusTimer2 = 0
			set(engine_runtime_2, math.max(0, get(engine_runtime_2) - 1))
		end

		if minusTimer3 >= 1 then
			minusTimer3 = 0
			set(engine_runtime_3, math.max(0, get(engine_runtime_3) - 1))
		end
		
		-- Exhausted service life causes native loss of power only on a working engine.
		if get(engine_runtime_1) <= 0 and get(eng_work_1) == 1 and rpm1 > 20 and get(eng_fail_1) == 0 then set(eng_fail_1, 6) end
		if get(engine_runtime_2) <= 0 and get(eng_work_2) == 1 and rpm2 > 20 and get(eng_fail_2) == 0 then set(eng_fail_2, 6) end
		if get(engine_runtime_3) <= 0 and get(eng_work_3) == 1 and rpm3 > 20 and get(eng_fail_3) == 0 then set(eng_fail_3, 6) end

		-- TakeOff mode limits
		if rpm1 > 95 or get(engn_oil_qty_1) < 4 then engToCounter1 = engToCounter1 + passed
		else engToCounter1 = engToCounter1 - passed end
		if engToCounter1 < 0 then engToCounter1 = 0 end
		
		if rpm2 > 95 or get(engn_oil_qty_2) < 4 then engToCounter2 = engToCounter2 + passed
		else engToCounter2 = engToCounter2 - passed end
		if engToCounter2 < 0 then engToCounter2 = 0 end
		
		if rpm3 > 95 or get(engn_oil_qty_3) < 4 then engToCounter3 = engToCounter3 + passed
		else engToCounter3 = engToCounter3 - passed end
		if engToCounter3 < 0 then engToCounter3 = 0 end
		
		-- fuel fluctuation
		if random_factor > 0 then set(fuel_fluct_1, get(eng_filter_1))
		elseif get(eng_filter_1) == 6 and get(fuel_fluct_1) == 0 then set(fuel_fluct_1, 6) end
		if random_factor > 0 then set(fuel_fluct_2, get(eng_filter_2))
		elseif get(eng_filter_2) == 6 and get(fuel_fluct_2) == 0 then set(fuel_fluct_2, 6) end
		if random_factor > 0 then set(fuel_fluct_3, get(eng_filter_3))
		elseif get(eng_filter_3) == 6 and get(fuel_fluct_3) == 0 then set(fuel_fluct_3, 6) end
		
		-- engine fire
		if get(engine_fire_1) > 0 and (random_factor > 0 or get(eng_flame_1) == 0) then set(eng_flame_1, 6) end
		if get(engine_fire_2) > 0 and (random_factor > 0 or get(eng_flame_2) == 0) then set(eng_flame_2, 6) end
		if get(engine_fire_3) > 0 and (random_factor > 0 or get(eng_flame_3) == 0) then set(eng_flame_3, 6) end
		
	else
		-- no failures enabled
		fail_counter = 0
		
		set(engn_oil_leak_1, 0)
		set(engn_oil_leak_2, 0)
		set(engn_oil_leak_3, 0)
		
		set(oil_pump_fail_1, 0)
		set(oil_pump_fail_2, 0)
		set(oil_pump_fail_3, 0)
		
		set(fuel_flowmeter_1_fail, 0)
		set(fuel_flowmeter_2_fail, 0)
		set(fuel_flowmeter_3_fail, 0)
		
		set(eng_fail_1, 0)
		set(eng_fail_2, 0)
		set(eng_fail_3, 0)
		
		set(eng_fire_1, 0)
		set(eng_fire_2, 0)
		set(eng_fire_3, 0)
		
		set(eng_flame_1, 0)
		set(eng_flame_2, 0)
		set(eng_flame_3, 0)
		
		set(eng_stall_1, 0) -- no comp stall if failures are disabled
		set(eng_stall_2, 0)
		set(eng_stall_3, 0)
		
		set(eng_fuel_pmp_fail_1, 0)
		set(eng_fuel_pmp_fail_2, 0)
		set(eng_fuel_pmp_fail_3, 0)
		
		set(eng_filter_1, 0)
		set(eng_filter_2, 0)
		set(eng_filter_3, 0)
		
		set(eng_start_1, 0)
		set(eng_start_2, 0)
		set(eng_start_3, 0)
		
		set(eng_ign_1, 0)
		set(eng_ign_2, 0)
		set(eng_ign_3, 0)
		
		set(eng_revrs_1, 0)
		set(eng_revrs_3, 0)
		
		set(engn_oil_qty_1, 26.5)
		set(engn_oil_qty_2, 26.5)
		set(engn_oil_qty_3, 26.5)
		
		set(ENGN_oil_q_1, 0.85)
		set(ENGN_oil_q_2, 0.85)
		set(ENGN_oil_q_3, 0.85)
		
		set(engine_runtime_1, 300*3600)
		set(engine_runtime_2, 300*3600)
		set(engine_runtime_3, 300*3600)

	end
	
else
	-- A slave relinquishes local ownership without changing synchronized native faults.
	discardLowStallOwnership()
end
    
end
