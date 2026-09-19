-- fuel_pumps.lua
-- this is fuel pumps logic

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Fuel quantities
    { "tank1_w", "sim/flightmodel/weight/m_fuel[0]", globalProperty },
    { "tank4_w", "sim/flightmodel/weight/m_fuel[1]", globalProperty },
    { "tank2R_w", "sim/flightmodel/weight/m_fuel[2]", globalProperty },
    { "tank2L_w", "sim/flightmodel/weight/m_fuel[3]", globalProperty },
    { "tank3R_w", "sim/flightmodel/weight/m_fuel[4]", globalProperty },
    { "tank3L_w", "sim/flightmodel/weight/m_fuel[5]", globalProperty },

    -- Controls
    { "pump_tank2_left", "tu154/custom/switchers/fuel/pump_tank2_left", globalPropertyi },
    { "pump_tank2_right", "tu154/custom/switchers/fuel/pump_tank2_right", globalPropertyi },
    { "pump_tank3_left", "tu154/custom/switchers/fuel/pump_tank3_left", globalPropertyi },
    { "pump_tank3_right", "tu154/custom/switchers/fuel/pump_tank3_right", globalPropertyi },
    { "pump_tank4", "tu154/custom/switchers/fuel/pump_tank4", globalPropertyi },
    { "pump_tank1_1", "tu154/custom/switchers/fuel/pump_tank1_1", globalPropertyi },
    { "pump_tank1_2", "tu154/custom/switchers/fuel/pump_tank1_2", globalPropertyi },
    { "pump_tank1_3", "tu154/custom/switchers/fuel/pump_tank1_3", globalPropertyi },
    { "pump_tank1_4", "tu154/custom/switchers/fuel/pump_tank1_4", globalPropertyi },
    { "fuel_level", "tu154/custom/switchers/fuel/fuel_level", globalPropertyi },
    { "fuel_flow_mode", "tu154/custom/switchers/fuel/fuel_flow_mode", globalPropertyi },
    { "fuel_flow_on", "tu154/custom/switchers/fuel/fuel_flow_on", globalPropertyi },

    -- Power sources
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    -- { "bus115_2_volt", "tu154/custom/elec/bus115_2_volt", globalPropertyf },

    -- Failures (pump values count the failed pumps)
    { "fuel_auto_fail", "tu154/custom/failures/fuel_auto_fail", globalPropertyi },
    { "fuel_level_fail", "tu154/custom/failures/fuel_level_fail", globalPropertyi },
    { "fuel_pump_2l_fail", "tu154/custom/failures/fuel_pump_2l_fail", globalPropertyi },
    { "fuel_pump_2r_fail", "tu154/custom/failures/fuel_pump_2r_fail", globalPropertyi },
    { "fuel_pump_3l_fail", "tu154/custom/failures/fuel_pump_3l_fail", globalPropertyi },
    { "fuel_pump_3r_fail", "tu154/custom/failures/fuel_pump_3r_fail", globalPropertyi },
    { "fuel_pump_1_fail", "tu154/custom/failures/fuel_pump_1_fail", globalPropertyi },
    { "fuel_pump_4_fail", "tu154/custom/failures/fuel_pump_4_fail", globalPropertyi },

    -- Pump operating states
    { "pump_tank2_left_work", "tu154/custom/fuel/pump_tank2_left_work", globalPropertyi },
    { "pump_tank2_right_work", "tu154/custom/fuel/pump_tank2_right_work", globalPropertyi },
    { "pump_tank3_left_work", "tu154/custom/fuel/pump_tank3_left_work", globalPropertyi },
    { "pump_tank3_right_work", "tu154/custom/fuel/pump_tank3_right_work", globalPropertyi },
    { "pump_tank4_work", "tu154/custom/fuel/pump_tank4_work", globalPropertyi },
    { "pump_tank1_1_work", "tu154/custom/fuel/pump_tank1_1_work", globalPropertyi },
    { "pump_tank1_2_work", "tu154/custom/fuel/pump_tank1_2_work", globalPropertyi },
    { "pump_tank1_3_work", "tu154/custom/fuel/pump_tank1_3_work", globalPropertyi },
    { "pump_tank1_4_work", "tu154/custom/fuel/pump_tank1_4_work", globalPropertyi },
    -- Automatic tank sequence: 0=none, 1=tank 2, 2=tanks 2+3, 3=tank 3, 4=tank 4
    { "auto_tanks_turn", "tu154/custom/fuel/auto_tanks_turn", globalPropertyi },
    -- Tank-level balancing: -1=left, 0=none, +1=right
    { "auto_tank_level_2", "tu154/custom/fuel/auto_tank_level_2", globalPropertyi },
    { "auto_tank_level_3", "tu154/custom/fuel/auto_tank_level_3", globalPropertyi },
    { "fuel_pumps_115_1_cc", "tu154/custom/elec/fuel_pumps_115_1_cc", globalPropertyf },
    { "fuel_pumps_115_3_cc", "tu154/custom/elec/fuel_pumps_115_3_cc", globalPropertyf },

    -- Simulation time
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
})

-- fuel press after pumps
local pump_1_1_P = 1
local pump_1_2_P = 1
local pump_1_3_P = 1
local pump_1_4_P = 1

local pump_2L_P = 1
local pump_2R_P = 1

local pump_3L_P = 1
local pump_3R_P = 1

local pump_4_P = 1

-- Hold the pressure endpoints while the pump state is unchanged. Letting a
-- powered pump decay at full pressure makes the start permissive flicker at low FPS.
local function pumpPressure(pressure, running, passed)
    local change = math.max(0, passed) * 0.8
    if running then return math.min(1, pressure + change) end
    return math.max(0, pressure - change)
end

function update()
	local passed = get(frame_time)
	
	-- check power
	local power_27L = get(bus27_volt_left) > 13
	local power_27R = get(bus27_volt_right) > 13
	local power115 = get(bus115_1_volt) > 110
	
	-- fuel quantity
	local tank_qty_2L = get(tank2L_w)
	local tank_qty_2R = get(tank2R_w)
	local tank_qty_3L = get(tank3L_w)
	local tank_qty_3R = get(tank3R_w)
	local tank_qty_4 = get(tank4_w)
	
	-- tanks has fuel
	local fuel_1 = get(tank1_w) > 150
	local fuel_2L = tank_qty_2L > 60
	local fuel_2R = tank_qty_2R > 60
	local fuel_3L = tank_qty_3L > 200
	local fuel_3R = tank_qty_3R > 200
	local fuel_4 = tank_qty_4 > 50
	
	-- main pumps logic
	local pump2L_work = 0
	local pump2R_work = 0
	local pump3L_work = 0
	local pump3R_work = 0
	local pump4_work = 0
	
	local pump1_1_work = 0
	local pump1_2_work = 0
	local pump1_3_work = 0
	local pump1_4_work = 0

	local tank_level_2 = 0
	local tank_level_3 = 0
	
	-- calculate automatic cue mode
	local tanks_turn = 0 -- 0 = none, 1 = 2, 2 = 2+3, 3 = 3, 4 = 4
	if (power_27L or power_27R) and get(fuel_flow_on) == 1 and get(fuel_auto_fail) == 0 then
		if tank_qty_2L + tank_qty_2R > 7400 then tanks_turn = 1
		elseif tank_qty_2L + tank_qty_2R <= 7400 and (fuel_2L or fuel_2R) and (fuel_3L or fuel_3R) then tanks_turn = 2
		elseif fuel_3L or fuel_3R then tanks_turn = 3
		elseif fuel_2L or fuel_2R then tanks_turn = 1
		elseif fuel_4 then tanks_turn = 4
		end
	end
	
	-- manipulate pumps by automatic cue
	if power115 then
		if tanks_turn > 0 and get(fuel_flow_mode) == 1 then -- automatic mode
			if tanks_turn == 1 then
				-- tank 2
				if tank_qty_2L > 500 then pump2L_work = math.max(0, 2 - get(fuel_pump_2l_fail))
				elseif fuel_2L then pump2L_work = math.max(0, get(pump_tank2_left) * 2 - get(fuel_pump_2l_fail)) end
		
				if tank_qty_2R > 500 then pump2R_work = math.max(0, 2 - get(fuel_pump_2r_fail))
				elseif fuel_2R then pump2R_work = math.max(0, get(pump_tank2_right) * 2 - get(fuel_pump_2r_fail)) end
				
			elseif tanks_turn == 2 then
				-- tank 2
				if tank_qty_2L > 500 then pump2L_work = math.max(0, 2 - get(fuel_pump_2l_fail))
				elseif fuel_2L then pump2L_work = math.max(0, get(pump_tank2_left) * 2 - get(fuel_pump_2l_fail)) end
		
				if tank_qty_2R > 500 then pump2R_work = math.max(0, 2 - get(fuel_pump_2r_fail))
				elseif fuel_2R then pump2R_work = math.max(0, get(pump_tank2_right) * 2 - get(fuel_pump_2r_fail)) end
			
				-- tank 3
				if tank_qty_3L > 2200 then pump3L_work = math.max(0, 3 - get(fuel_pump_3l_fail))
				elseif fuel_3L then pump3L_work = math.max(0, get(pump_tank3_left) * 3 - get(fuel_pump_3l_fail)) end
		
				if tank_qty_3R > 2200 then pump3R_work = math.max(0, 3 - get(fuel_pump_3r_fail))
				elseif fuel_3R then pump3R_work = math.max(0, get(pump_tank3_right) * 3 - get(fuel_pump_3r_fail)) end
				
			elseif tanks_turn == 3 then
				-- tank 3
				if tank_qty_3L > 2200 then pump3L_work = math.max(0, 3 - get(fuel_pump_3l_fail))
				elseif fuel_3L then pump3L_work = math.max(0, get(pump_tank3_left) * 3 - get(fuel_pump_3l_fail)) end
		
				if tank_qty_3R > 2200 then pump3R_work = math.max(0, 3 - get(fuel_pump_3r_fail))
				elseif fuel_3R then pump3R_work = math.max(0, get(pump_tank3_right) * 3 - get(fuel_pump_3r_fail)) end
			
			elseif tanks_turn == 4 then
				-- tank 4
				if tank_qty_4 > 600 then pump4_work = math.max(0, 2 - get(fuel_pump_4_fail))
				elseif fuel_4 then pump4_work = math.max(0, get(pump_tank4) * 2 - get(fuel_pump_4_fail)) end
			
			end
			
		else -- manual mode
			
			if fuel_2L then pump2L_work = math.max(0, get(pump_tank2_left) * 2 - get(fuel_pump_2l_fail)) end
			if fuel_2R then pump2R_work = math.max(0, get(pump_tank2_right) * 2 - get(fuel_pump_2r_fail)) end
			
			if fuel_3L then pump3L_work = math.max(0, get(pump_tank3_left) * 3 - get(fuel_pump_3l_fail)) end
			if fuel_3R then pump3R_work = math.max(0, get(pump_tank3_right) * 3 - get(fuel_pump_3r_fail)) end
			
			if fuel_4 then pump4_work = math.max(0, get(pump_tank4) * 2 - get(fuel_pump_4_fail)) end
			
			--print(pump3L_work.."  "..pump3R_work)
			
		end
		
		-- leveling logic. 		
		if get(fuel_level) == 1 and get(fuel_level_fail) == 0 then
			if tank_qty_2R - tank_qty_2L > 350 then
				tank_level_2 = -1
				pump2L_work = 0
			elseif tank_qty_2L - tank_qty_2R > 350 then
				tank_level_2 = 1
				pump2R_work = 0	
			else
				tank_level_2 = 0
			end
			
			if tank_qty_3R - tank_qty_3L > 300 then
				tank_level_3 = -1
				pump3L_work = 0
			elseif tank_qty_3L - tank_qty_3R > 300 then
				tank_level_3 = 1
				pump3R_work = 0	
			else
				tank_level_3 = 0
			end
		
		end
		
		-- pumps 1 works separately from atomatics
		if fuel_1 then
			pump1_1_work = get(pump_tank1_1) * bool2int(get(fuel_pump_1_fail) < 1)
			pump1_2_work = get(pump_tank1_2) * bool2int(get(fuel_pump_1_fail) < 4)
			pump1_3_work = get(pump_tank1_3) * bool2int(get(fuel_pump_1_fail) < 3)
			pump1_4_work = get(pump_tank1_4) * bool2int(get(fuel_pump_1_fail) < 2)
		end
	
	end
	
	-- calculate pressures
	pump_2L_P = pumpPressure(pump_2L_P, pump2L_work > 0, passed)
	pump_2R_P = pumpPressure(pump_2R_P, pump2R_work > 0, passed)
	pump_3L_P = pumpPressure(pump_3L_P, pump3L_work > 0, passed)
	pump_3R_P = pumpPressure(pump_3R_P, pump3R_work > 0, passed)
	pump_4_P = pumpPressure(pump_4_P, pump4_work > 0, passed)
	pump_1_1_P = pumpPressure(pump_1_1_P, pump1_1_work > 0, passed)
	pump_1_2_P = pumpPressure(pump_1_2_P, pump1_2_work > 0, passed)
	pump_1_3_P = pumpPressure(pump_1_3_P, pump1_3_work > 0, passed)
	pump_1_4_P = pumpPressure(pump_1_4_P, pump1_4_work > 0, passed)
	
	-- calculate electrics
	local bus_1_load = (pump1_1_work + pump1_3_work) * 8.3 + (pump4_work + pump2L_work * 0.5 + pump2R_work * 0.5 + (pump3L_work * 0.3 + pump3R_work * 0.3) * 2) * 2.6
	local bus_3_load = (pump1_2_work + pump1_4_work) * 8.3 + (pump4_work + pump2L_work * 0.5 + pump2R_work * 0.5 + pump3L_work * 0.3 + pump3R_work * 0.3) * 2.6
	
	-- pump for APU consumes 15A from 27v bus
	
	-- set results
	set(pump_tank2_left_work, math.max(0, bool2int(pump_2L_P > 0.9) * 2 - get(fuel_pump_2l_fail)))
	set(pump_tank2_right_work, math.max(0, bool2int(pump_2R_P > 0.9) * 2 - get(fuel_pump_2r_fail)))
	set(pump_tank3_left_work, math.max(0, bool2int(pump_3L_P > 0.9) * 3 - get(fuel_pump_3l_fail)))
	set(pump_tank3_right_work, math.max(0, bool2int(pump_3R_P > 0.9) * 3 - get(fuel_pump_3r_fail)))
	set(pump_tank4_work, math.max(0, bool2int(pump_4_P > 0.9) * 2 - get(fuel_pump_4_fail)))
	set(pump_tank1_1_work, bool2int(pump_1_1_P > 0.9))
	set(pump_tank1_2_work, bool2int(pump_1_2_P > 0.9))
	set(pump_tank1_3_work, bool2int(pump_1_3_P > 0.9))
	set(pump_tank1_4_work, bool2int(pump_1_4_P > 0.9))

	set(auto_tanks_turn, tanks_turn)
	set(auto_tank_level_2, tank_level_2)
	set(auto_tank_level_3, tank_level_3)
	
	set(fuel_pumps_115_1_cc, bus_1_load)
	set(fuel_pumps_115_3_cc, bus_3_load)
	
end

