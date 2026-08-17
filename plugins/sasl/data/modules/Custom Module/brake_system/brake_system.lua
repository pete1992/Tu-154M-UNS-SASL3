-- this is the brakes system

defineProperty("have_pedals", globalPropertyi("tu154/custom/have_pedals"))
-- hydro
defineProperty("gs_press_1", globalPropertyf("tu154/custom/hydro/gs_press_1")) --   1
defineProperty("gs_press_2", globalPropertyf("tu154/custom/hydro/gs_press_2")) --   2
defineProperty("gs_press_3", globalPropertyf("tu154/custom/hydro/gs_press_3")) --   3
defineProperty("gs_press_4", globalPropertyf("tu154/custom/hydro/gs_press_4")) --   4
-- time
defineProperty("frame_time", globalPropertyf("tu154/custom/time/frame_time")) -- flight time
-- sim brakes
defineProperty("l_brake_add", globalPropertyf("sim/flightmodel/controls/l_brake_add")) -- Left Brake
defineProperty("r_brake_add", globalPropertyf("sim/flightmodel/controls/r_brake_add")) -- Right Brake
defineProperty("parkbrake", globalPropertyf("sim/flightmodel/controls/parkbrake")) -- Parking Brake
defineProperty("parkbrake_2", globalPropertyf("sim/cockpit2/controls/parking_brake_ratio")) -- Parking Brake
-- controls
defineProperty("gear_blocks", globalPropertyf("tu154/custom/anim/gear_blocks")) -- Parking Brake
defineProperty("brake_emerg", globalPropertyf("tu154/custom/controlls/brake_emerg")) --  
defineProperty("brake_emerg_L", globalPropertyf("tu154/custom/controlls/brake_emerg_L")) --  
defineProperty("brake_emerg_R", globalPropertyf("tu154/custom/controlls/brake_emerg_R")) --  
-- animation
defineProperty("parking_brake", globalPropertyi("tu154/custom/controll/parking_brake")) --   
defineProperty("brake_L", globalPropertyf("tu154/custom/controlls/brake_L")) -- 
defineProperty("brake_R", globalPropertyf("tu154/custom/controlls/brake_R")) -- 
defineProperty("int_brakes_L", globalPropertyf("tu154/custom/brakes/int_brakes_L")) --   
defineProperty("int_brakes_R", globalPropertyf("tu154/custom/brakes/int_brakes_R")) --   
defineProperty("overr", globalPropertyi("sim/operation/override/override_gearbrake")) -- 
-- Smart Copilot
defineProperty("ismaster", globalPropertyf("scp/api/ismaster")) -- Master. 0 = plugin not found, 1 = slave 2 = master
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1")) -- Have control. 0 = plugin not found, 1 = no control 2 = has control
-- failures
defineProperty("brake_heat_left", globalPropertyf("tu154/custom/failures/brake_heat_left")) --  
defineProperty("brake_heat_right", globalPropertyf("tu154/custom/failures/brake_heat_right")) --  
defineProperty("brake_runtime_left", globalPropertyf("tu154/custom/failures/brake_runtime_left")) --   
defineProperty("brake_runtime_right", globalPropertyf("tu154/custom/failures/brake_runtime_right")) --   
defineProperty("rel_lbrakes", globalPropertyi("sim/operation/failures/rel_lbrakes")) --  
defineProperty("rel_rbrakes", globalPropertyi("sim/operation/failures/rel_rbrakes")) --  
defineProperty("failures_enabled", globalPropertyi("tu154/custom/failures/failures_enabled"))
-- enviroment
defineProperty("speed", globalPropertyf("sim/flightmodel/position/groundspeed"))
defineProperty("thermo", globalPropertyf("sim/cockpit2/temperature/outside_air_temp_degc")) -- outside temperature
defineProperty("gear_vent_set", globalPropertyi("tu154/custom/switchers/eng/gear_fan")) --  
defineProperty("gear2_deflect", globalProperty("sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]"))  -- vertical deflection of left gear
defineProperty("gear3_deflect", globalProperty("sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]"))  -- vertical deflection of right gear

set(brake_runtime_left, 1)
set(brake_runtime_right, 1)

-- sound
local brake_hnd_on = sasl.al.loadSample('Custom Sounds/parking_on.wav')
local brake_hnd_off = sasl.al.loadSample('Custom Sounds/parking_off.wav')

local termo_coef = {
{0, 1},
{100, 1.5},
{200, 2},
{300, 5},
{1000, 50},
{1000000, 500}
}

local joy_work_L = globalPropertyi("sim/joystick/joy_mapped_axis_avail[6]")
local joy_work_R = globalPropertyi("sim/joystick/joy_mapped_axis_avail[7]")

local joy_value_L = globalPropertyf("sim/joystick/joy_mapped_axis_value[6]")
local joy_value_R = globalPropertyf("sim/joystick/joy_mapped_axis_value[7]")

-- now we need to find axies of brakes on pedals, if there are any

local left_pedal_num = nil
local right_pedal_num = nil

local sim_brake = 0
local passed = 0
local comm_brake = 0
regular_brk_comm = sasl.findCommand("sim/flight_controls/brakes_regular")

local termo_left = get(thermo)
local termo_right = get(thermo)

function regular_brk_hnd(phase)
	if 1 == phase then -- hold
		set(parking_brake, 0)
		sim_brake = sim_brake + passed * 2
		if sim_brake > 1 then sim_brake = 1 end
	else 
		sim_brake = 0
		if get(hascontrol_1) ~= 1 then
			set(l_brake_add, 0)
			set(r_brake_add, 0)
		end
	end
	
	return 0
end

sasl.registerCommandHandler(regular_brk_comm, 0, regular_brk_hnd)
max_brk_comm = sasl.findCommand("sim/flight_controls/brakes_max")

function max_brk_hnd(phase)
	if 1 == phase then -- hold
		set(parking_brake, 0)
		sim_brake = sim_brake + passed * 4
		if sim_brake > 1 then sim_brake = 1 end
	else 
		sim_brake = 0
		if get(hascontrol_1) ~= 1 then
			set(l_brake_add, 0)
			set(r_brake_add, 0)
		end
	end
	
	return 0
end

sasl.registerCommandHandler(max_brk_comm, 0, max_brk_hnd)
park_brk_max_comm = sasl.findCommand("sim/flight_controls/brakes_toggle_max")

function park_brk_max_hnd(phase)
	if 0 == phase then -- toggle
		local brk = 1 - get(parking_brake)
		
		if brk == 0 and get(hascontrol_1) ~= 1 then
			set(l_brake_add, 0) -- release pedals
			set(r_brake_add, 0) -- release pedals
		end
		set(parking_brake, brk)
	else 
	end
	return 0
end

sasl.registerCommandHandler(park_brk_max_comm, 0, park_brk_max_hnd)
park_brk_reg_comm = sasl.findCommand("sim/flight_controls/brakes_toggle_regular")

function park_brk_reg_hnd(phase)
	if 0 == phase then -- toggle
		local brk = 1 - get(parking_brake)
		
		if brk == 0 and get(hascontrol_1) ~= 1 then
			set(l_brake_add, 0) -- release pedals
			set(r_brake_add, 0) -- release pedals
		end
		set(parking_brake, brk)
	else 
	end
	return 0
end

sasl.registerCommandHandler(park_brk_reg_comm, 0, park_brk_reg_hnd)

local left_brk_cmd = sasl.findCommand("sim/flight_controls/left_brake")
local right_brk_cmd = sasl.findCommand("sim/flight_controls/right_brake")
local left_brk = 0
local right_brk = 0

function left_brk_cmd_hnd(phase)
	if 1 == phase then -- hold
		left_brk = left_brk + passed * 2
		if left_brk > 1 then left_brk = 1 end
		set(parking_brake, 0)
	else 
		left_brk = 0
	end
	return 0
end

function right_brk_cmd_hnd(phase)
	if 1 == phase then -- hold
		right_brk = right_brk + passed * 2
		if right_brk > 1 then right_brk = 1 end
		set(parking_brake, 0)
	else 
		right_brk = 0
	end
	
	return 0
end

sasl.registerCommandHandler(left_brk_cmd, 0, left_brk_cmd_hnd)
sasl.registerCommandHandler(right_brk_cmd, 0, right_brk_cmd_hnd)
set(parking_brake, 1)
set(overr, 1)

local park_lever_last = get(parking_brake)
local e_brake_last = get(brake_emerg)

local axisCheckTimer = 0
local fail_counter = 0
local check_time = math.random(15, 30)
local resetTimer = 0

set(joy_value_L, 0)
set(joy_value_R, 0)

function update()
	passed = get(frame_time)
	-- controls
	-- pedals
	local brake_1 = get(joy_value_L)
	local brake_2 = get(joy_value_R)
	-- parking brake
	local park_lvr = get(parking_brake)
	-- emerg brakes
	local e_brake = get(brake_emerg)
	
	-- reset pedals, when park brake released
	if (park_lever_last ~= park_lvr and park_lvr == 0) --[[ or (e_brake_last ~= e_brake and e_brake < 0.05) --]] then 
		brake_1 = 0
		brake_2 = 0
	end	
	
	-- sounds
	if park_lever_last ~= park_lvr then
		if park_lvr == 1 then sasl.al.playSample(brake_hnd_on, false)
		else sasl.al.playSample(brake_hnd_off, false) end
	end
	
	park_lever_last = park_lvr
	e_brake_last = e_brake
	-- blocks
	local blocks = get(gear_blocks)
	-- pressures
	local main_press = math.min(get(gs_press_1) / 120, 1)
	local emer_press = math.min(get(gs_press_4) / 120, 1)
	local left_blake = math.max(brake_1 * main_press, sim_brake * main_press, left_brk * main_press)--, park_lvr * main_press) 
	local right_blake = math.max(brake_2 * main_press, sim_brake * main_press, right_brk * main_press)--, park_lvr * main_press) 
	local park = math.max(blocks * 5, e_brake * emer_press, park_lvr * main_press)
	-- bug workaround
	if left_blake < 0.07 then left_blake = 0 end
	if right_blake < 0.07 then right_blake = 0 end
	-- failures
	left_blake = left_blake * bool2int(get(rel_lbrakes) ~= 6)
	right_blake = right_blake * bool2int(get(rel_rbrakes) ~= 6)

if get(ismaster) ~= 1 then			
	local FAIL = get(failures_enabled)
	FAIL = FAIL * 0.05 * 4 ^ (FAIL * 0.5)
	
	if FAIL > 0 then
		fail_counter = fail_counter + passed
		if fail_counter > check_time then
			fail_counter = 0
			check_time = math.random(15, 30)
			-- random failures
			if get(rel_lbrakes) ~= 1 then set(rel_lbrakes, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6) end
			if get(rel_rbrakes) ~= 1 then set(rel_rbrakes, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6) end
			-- runtime failure
			if get(brake_runtime_left) == 0 and left_blake > 0.1 then
				if get(rel_lbrakes) ~= 1 then set(rel_lbrakes, bool2int(math.random() < 0.1) * 6) end
			end
			if get(brake_runtime_right) == 0 and right_blake > 0.1 then
				if get(rel_rbrakes) ~= 1 then set(rel_rbrakes, bool2int(math.random() < 0.1) * 6) end
			end
		end
		
		if get(gear2_deflect) > 0.05 then
			set(brake_runtime_left, math.max(0, get(brake_runtime_left) - passed * left_blake * get(speed) * 0.00002 * interpolate(termo_coef, math.max(0, termo_left))))
		end
		if get(gear3_deflect) > 0.05 then
			set(brake_runtime_right, math.max(0, get(brake_runtime_right) - passed * right_blake * get(speed) * 0.00002 * interpolate(termo_coef, math.max(0, termo_right))))
		end
	else
		set(brake_runtime_left, 1)
		set(brake_runtime_right, 1)
		set(rel_lbrakes, 0)
		set(rel_rbrakes, 0)
	end
end	
	
	termo_left = termo_left + left_blake * get(speed) * 0.9 * bool2int(get(gear2_deflect) > 0.05) * passed 
	termo_left = termo_left + (get(thermo) - termo_left) * passed * (1 + get(gear_vent_set) * 4) * 0.01
	termo_right = termo_right + right_blake * get(speed) * 0.9 * bool2int(get(gear3_deflect) > 0.05) * passed 
	termo_right = termo_right + (get(thermo) - termo_right) * passed * (1 + get(gear_vent_set) * 4) * 0.01
	set(brake_heat_left, termo_left)
	set(brake_heat_right, termo_right)
	
local have_control = get(hascontrol_1) ~= 1

if have_control then
	-- set results
	set(l_brake_add, left_blake)
	set(r_brake_add, right_blake)
	set(int_brakes_L, math.max(left_blake, park))
	set(int_brakes_R, math.max(right_blake, park))
	set(parkbrake, park)
	set(parkbrake_2, park)
	
	if brake_1 > 0.8 and brake_2 > 0.8 then set(parking_brake, 0) end -- release park lever, if pedals pressed.
end

	set(brake_L, math.max(left_blake, brake_1, park_lvr))
	set(brake_R, math.max(right_blake, brake_2, park_lvr))	
end

function onModuleDone()
	set(overr, 0)
end
