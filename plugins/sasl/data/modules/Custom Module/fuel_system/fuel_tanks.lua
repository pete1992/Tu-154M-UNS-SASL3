-- fuel_tanks.lua
-- this is fuel tanks manipulating logic

-- fuel quantity
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
    { "tank1_w", "sim/flightmodel/weight/m_fuel[0]", globalProperty }, -- fuel weight
    { "tank4_w", "sim/flightmodel/weight/m_fuel[1]", globalProperty }, -- fuel weight
    { "tank2R_w", "sim/flightmodel/weight/m_fuel[2]", globalProperty }, -- fuel weight
    { "tank2L_w", "sim/flightmodel/weight/m_fuel[3]", globalProperty }, -- fuel weight
    { "tank3R_w", "sim/flightmodel/weight/m_fuel[4]", globalProperty }, -- fuel weight
    { "tank3L_w", "sim/flightmodel/weight/m_fuel[5]", globalProperty }, -- fuel weight

    { "tank_all", "sim/flightmodel/weight/m_fuel_total", globalPropertyf }, -- total fuel weight

    -- fuel tanks pumps control
    { "tank1_pump", "sim/cockpit2/fuel/fuel_tank_pump_on[0]", globalProperty },
    { "tank4_pump", "sim/cockpit2/fuel/fuel_tank_pump_on[1]", globalProperty },
    { "tank2R_pump", "sim/cockpit2/fuel/fuel_tank_pump_on[2]", globalProperty },
    { "tank2L_pump", "sim/cockpit2/fuel/fuel_tank_pump_on[3]", globalProperty },
    { "tank3R_pump", "sim/cockpit2/fuel/fuel_tank_pump_on[4]", globalProperty },
    { "tank3L_pump", "sim/cockpit2/fuel/fuel_tank_pump_on[5]", globalProperty },

    { "fuel_trans", "tu154/custom/switchers/fuel/fuel_trans", globalPropertyi }, --
    { "fuel_porc", "tu154/custom/switchers/fuel/fuel_porc", globalPropertyi }, --

    -- fuel pumps work
    { "pump_tank2_left_work", "tu154/custom/fuel/pump_tank2_left_work", globalPropertyi }, -- number of working pumps
    { "pump_tank2_right_work", "tu154/custom/fuel/pump_tank2_right_work", globalPropertyi },
    { "pump_tank3_left_work", "tu154/custom/fuel/pump_tank3_left_work", globalPropertyi },
    { "pump_tank3_right_work", "tu154/custom/fuel/pump_tank3_right_work", globalPropertyi },
    { "pump_tank4_work", "tu154/custom/fuel/pump_tank4_work", globalPropertyi },
    -- { "pump_tank1_1_work", "tu154/custom/fuel/pump_tank1_1_work", globalPropertyi },
    -- { "pump_tank1_2_work", "tu154/custom/fuel/pump_tank1_2_work", globalPropertyi },
    -- { "pump_tank1_3_work", "tu154/custom/fuel/pump_tank1_3_work", globalPropertyi },
    -- { "pump_tank1_4_work", "tu154/custom/fuel/pump_tank1_4_work", globalPropertyi },

    { "reserv_trans", "tu154/custom/fuel/reserv_trans", globalPropertyi },

    { "apu_burn_fuel", "tu154/custom/elec/apu_burning_fuel", globalPropertyf }, --

    -- fuel flow per engine
    -- { "ENGN_FF_1", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec[0]", globalProperty }, -- FF from sim kg/second
    -- { "ENGN_FF_2", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec[1]", globalProperty }, -- FF from sim kg/second
    -- { "ENGN_FF_3", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec[2]", globalProperty }, -- FF from sim kg/second

    -- altitude
    { "msl_alt", "sim/flightmodel/position/elevation", globalPropertyf },  -- phisical altitude MSL. meters

    { "gear_defl_L", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalProperty }, --
    { "gear_defl_R", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", globalProperty }, --

    -- failures
    { "rel_fuelcap", "sim/operation/failures/rel_fuelcap", globalPropertyi }, -- Fuel Cap left off
    { "fuel_porc_fail", "tu154/custom/failures/fuel_porc_fail", globalPropertyi },
    -- time
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time

    -- test
    -- { "test", "sim/operation/failures/rel_fuepmp0", globalPropertyf }, --

    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf }, --   27
})

--     - 160-240 /    .

-- make active tank 1 only
set(tank1_pump, 1)
set(tank4_pump, 0)
set(tank2R_pump, 0)
set(tank2L_pump, 0)
set(tank3R_pump, 0)
set(tank3L_pump, 0)

function onModuleDone()
	
	set(tank1_pump, 1)
	set(tank4_pump, 1)
	set(tank2R_pump, 1)
	set(tank2L_pump, 1)
	set(tank3R_pump, 1)
	set(tank3L_pump, 1)	

end

local passed = get(frame_time)

local porc_open = false
local transfer = false -- fuel goes aside porc

local tank_all_last = get(tank_all)
local tank_all_calc_last = get(tank_all)
local calc_counter = 0

-- fuel tanks ammount
local tank1_qty = get(tank1_w)
local tank4_qty = get(tank4_w)
local tank2L_qty = get(tank2L_w)
local tank2R_qty = get(tank2R_w)
local tank3L_qty = get(tank3L_w)
local tank3R_qty = get(tank3R_w)

local trans_pos = 0

-- fuel pumps random
local tank2L_rnd = math.random(95, 105) * 0.01
local tank2R_rnd = math.random(95, 105) * 0.01
local tank3L_rnd = math.random(95, 105) * 0.01
local tank3R_rnd = math.random(95, 105) * 0.01

function update()
	passed = get(frame_time)
	
	-- fuel tanks ammount
	local tank1_qty = get(tank1_w)
	local tank4_qty = get(tank4_w)
	local tank2L_qty = get(tank2L_w)
	local tank2R_qty = get(tank2R_w)
	local tank3L_qty = get(tank3L_w)
	local tank3R_qty = get(tank3R_w)	
	local power27 = get(bus27_volt_right) > 13
--[[	
	-- test fuel flow
	local tank_all_now = get(tank_all)
	local tank_all_calc = tank1_qty + tank4_qty + tank2L_qty + tank2R_qty + tank3L_qty + tank3R_qty
	calc_counter = calc_counter + passed
	if calc_counter > 5 then
		print(get(ENGN_FF_1) + get(ENGN_FF_2) + get(ENGN_FF_3))
		print((tank_all_last - tank_all_now) / calc_counter, (tank_all_calc_last - tank_all_calc) / calc_counter, tank_all_now)
		tank_all_last = tank_all_now
		tank_all_calc_last = tank_all_calc
		calc_counter = 0
	end
--]]	
	-- check tank 1 quantity
	local tank1_full = tank1_qty >= 3300
	
	-- porcioner manipulations
	if (tank1_qty < 3150 and get(fuel_porc_fail) == 0) or (get(fuel_porc) == 1 and power27 and not tank1_full) then porc_open = true -- open porc
	elseif tank1_full then porc_open = false end -- close it
	
	-- reserv fuel transfer
	if get(fuel_trans) == 1 and trans_pos < 1 and power27 then
		trans_pos = trans_pos + passed
	elseif trans_pos > 0 and power27 then
		trans_pos = trans_pos - passed
	end
	
	transfer = trans_pos > 0.9
	set(reserv_trans, bool2int(trans_pos > 0.9))
	
	-- calculate fuel pumps speed depending on altitude
	local spd = 1.55 - get(msl_alt) * 1.11 / 14000 -- kg/sec
	-- check pumps work
	local pump2L = get(pump_tank2_left_work) * spd * tank2L_rnd -- tank can give fuel
	local pump2R = get(pump_tank2_right_work) * spd * tank2R_rnd -- tank can give fuel
	local pump3L = get(pump_tank3_left_work) * spd * tank3L_rnd -- tank can give fuel
	local pump3R = get(pump_tank3_right_work) * spd * tank3R_rnd -- tank can give fuel	
	local pump4 = get(pump_tank4_work) * spd -- tank can give fuel	
	
	-- transfer fuel from othe tanks
	if porc_open or (transfer and not tank1_full) then
		-- take fuel from tanks 2, 3, 4
		tank2L_qty = tank2L_qty - passed * pump2L
		tank2R_qty = tank2R_qty - passed * pump2R
		tank3L_qty = tank3L_qty - passed * pump3L
		tank3R_qty = tank3R_qty - passed * pump3R
		tank4_qty = tank4_qty - passed * pump4
		-- give it to tank 1
		tank1_qty = tank1_qty + (pump2L + pump2R + pump3L + pump3R + pump4) * passed
	-- transfer fuel from tank 1 to tank 2 on ground
	elseif transfer and tank1_full and (tank2L_qty < 9500 or tank2R_qty < 9500) and get(gear_defl_L) + get(gear_defl_R) > 0.05 then
		local tank2L_take = bool2int(tank2L_qty < 9500)
		local tank2R_take = bool2int(tank2R_qty < 9500)
		-- take fuel from tanks 3 and 4 
		tank2L_qty = tank2L_qty - passed * pump2L
		tank2R_qty = tank2R_qty - passed * pump2R
		tank3L_qty = tank3L_qty - passed * pump3L
		tank3R_qty = tank3R_qty - passed * pump3R
		tank4_qty = tank4_qty - passed * pump4		
		-- move it to tanks 2
		tank2L_qty = tank2L_qty + (pump2L + pump2R + pump3L + pump3R + pump4) * passed / (tank2L_take + tank2R_take)
		tank2R_qty = tank2R_qty + (pump2L + pump2R  + pump3L + pump3R + pump4) * passed / (tank2L_take + tank2R_take)
	end
	
	-- take fuel for APU
	if get(apu_burn_fuel) == 1 then 
		tank1_qty = tank1_qty - passed * 0.0556
	end
	
	-- limit fuel amount in tanks
	if tank1_qty > 3350 then tank1_qty = 3350 end
	if tank2L_qty > 9550 then tank2L_qty = 9550 end
	if tank2R_qty > 9550 then tank2R_qty = 9550 end
	if tank3L_qty > 5425 then tank3L_qty = 5425 end
	if tank3R_qty > 5425 then tank3R_qty = 5425 end
	if tank4_qty > 6600 then tank4_qty = 6600 end
	
	-- set results
	set(tank1_w, tank1_qty)
	set(tank4_w, tank4_qty)
	set(tank2L_w, tank2L_qty)
	set(tank2R_w, tank2R_qty)
	set(tank3L_w, tank3L_qty)
	set(tank3R_w, tank3R_qty)
	
	-- fix stupid failures
	set(rel_fuelcap, 0)

end

