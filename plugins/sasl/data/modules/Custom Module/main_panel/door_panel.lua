-- this is the door lights panel

-- controlls
defineProperty("test_lamps", globalPropertyi("tu154/custom/buttons/lamp_test_doors")) --     
defineProperty("day_night_set", globalPropertyf("tu154/custom/lights/day_night_set")) --   - . 0 - , 1 - .    .

-- other sources
defineProperty("bus27_volt_left", globalPropertyf("tu154/custom/elec/bus27_volt_left")) --   27
defineProperty("bus27_volt_right", globalPropertyf("tu154/custom/elec/bus27_volt_right")) --   27
defineProperty("frame_time", globalPropertyf("tu154/custom/time/frame_time")) -- flight time

defineProperty("nosewheel_turn_enable", globalPropertyi("tu154/custom/switchers/nosewheel_turn_enable")) --      
defineProperty("nosewheel_turn_sel", globalPropertyi("tu154/custom/switchers/nosewheel_turn_sel")) --     . 0 - 10, 1 - 63

-- lamps
defineProperty("other_hatches", globalPropertyf("tu154/custom/lights/other_hatches")) --    
defineProperty("left_front_pax_door", globalPropertyf("tu154/custom/lights/left_front_pax_door")) --    
defineProperty("left_mid_pax_door", globalPropertyf("tu154/custom/lights/left_mid_pax_door")) --    
defineProperty("right_mid_pax_door", globalPropertyf("tu154/custom/lights/right_mid_pax_door")) --    
defineProperty("cargo_front_door", globalPropertyf("tu154/custom/lights/cargo_front_door")) --   
defineProperty("cargo_back_door", globalPropertyf("tu154/custom/lights/cargo_back_door")) --   
defineProperty("turn63_lamp", globalPropertyf("tu154/custom/lights/turn63_lamp")) --  63 
defineProperty("nosewheel_turn_off", globalPropertyf("tu154/custom/lights/nosewheel_turn_off")) --   
defineProperty("busters_off", globalPropertyf("tu154/custom/lights/busters_off")) --  

-- hatches
defineProperty("cargo_1", globalPropertyf("tu154/custom/anim/cargo_1")) --    1. 0 - , 1 - 
defineProperty("cargo_2", globalPropertyf("tu154/custom/anim/cargo_2")) --    1. 0 - , 1 - 
defineProperty("pax_door_1", globalPropertyf("tu154/custom/anim/pax_door_1")) --    
defineProperty("pax_door_2", globalPropertyf("tu154/custom/anim/pax_door_2")) --    
defineProperty("pax_door_3", globalPropertyf("tu154/custom/anim/pax_door_3")) --    

defineProperty("busters_cap", globalPropertyi("tu154/custom/switchers/console/busters_cap")) --   

local passed = get(frame_time)

local function lamps()
	local day_night = 1 - get(day_night_set) * 0.25
	local test_btn = get(test_lamps) * math.max((get(bus27_volt_right) - 10) / 18.5, 0)
	local lamps_brt = math.max((math.max(get(bus27_volt_left), get(bus27_volt_right)) - 10) / 18.5, 0)
	
	local other_hatches_brt = math.max(0 * lamps_brt * day_night, test_btn) -- fake for now
	set(other_hatches, other_hatches_brt)
	
	local left_front_pax_door_brt = math.max(bool2int(get(pax_door_1) > 0) * lamps_brt * day_night, test_btn)
	set(left_front_pax_door, left_front_pax_door_brt)
	
	local left_mid_pax_door_brt = math.max(bool2int(get(pax_door_2) > 0) * lamps_brt * day_night, test_btn) 
	set(left_mid_pax_door, left_mid_pax_door_brt)
	
	local right_mid_pax_door_brt = math.max(bool2int(get(pax_door_3) > 0) * lamps_brt * day_night, test_btn)
	set(right_mid_pax_door, right_mid_pax_door_brt)
	
	local cargo_front_door_brt = math.max(bool2int(get(cargo_1) > 0) * lamps_brt * day_night, test_btn)
	set(cargo_front_door, cargo_front_door_brt)
	
	local cargo_back_door_brt = math.max(bool2int(get(cargo_2) > 0) * lamps_brt * day_night, test_btn)
	set(cargo_back_door, cargo_back_door_brt)
	
	local turn63_lamp_brt = math.max(get(nosewheel_turn_sel) * lamps_brt * day_night, test_btn)
	set(turn63_lamp, turn63_lamp_brt)
	
	local nosewheel_turn_off_brt = math.max((1-get(nosewheel_turn_enable)) * lamps_brt * day_night, test_btn)
	set(nosewheel_turn_off, nosewheel_turn_off_brt)
	
	local busters_off_brt = math.max(get(busters_cap) * lamps_brt * day_night, test_btn)
	set(busters_off, busters_off_brt)
	
end

local button_sound = sasl.al.loadSample('Custom Sounds/plastic_btn.wav')

local buttn_last = get(test_lamps)

function update()

	lamps()
	
	local button_sw = get(test_lamps)
	
	if button_sw ~= buttn_last then sasl.al.playSample(button_sound, false) end
	buttn_last = button_sw

end

