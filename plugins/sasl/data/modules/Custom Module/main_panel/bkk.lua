-- this is roll control system BKK

-- controll
defineProperty("bkk_on", globalPropertyi("tu154/custom/switchers/ovhd/bkk_on")) -- 
defineProperty("bkk_contr", globalPropertyi("tu154/custom/switchers/ovhd/bkk_contr")) -- 

-- roll for check
defineProperty("roll_a", globalPropertyf("tu154/custom/bkk/pkp_roll_left")) --    +  
defineProperty("roll_b", globalPropertyf("tu154/custom/bkk/pkp_roll_right")) --    +  
defineProperty("roll_c", globalPropertyf("tu154/custom/gyro/mgv_contr_roll")) --    +  

-- pitch for check
defineProperty("pitch_a", globalPropertyf("tu154/custom/gyro/ahz_pitch_int_L")) --    + 
defineProperty("pitch_b", globalPropertyf("tu154/custom/gyro/ahz_pitch_int_R")) --    + 
defineProperty("pitch_c", globalPropertyf("tu154/custom/gyro/mgv_contr_pitch")) --    + 

-- fail
defineProperty("bkk_fail", globalPropertyi("tu154/custom/failures/bkk_fail")) -- fail

-- results
defineProperty("left_roll_big", globalPropertyi("tu154/custom/bkk/left_roll_big")) --    -   
defineProperty("right_roll_big", globalPropertyi("tu154/custom/bkk/right_roll_big")) --    -   
defineProperty("mgv_contr_fail", globalPropertyi("tu154/custom/bkk/mgv_contr_fail")) --    -   
defineProperty("no_contr_ag", globalPropertyi("tu154/custom/bkk/no_contr_ag")) --    -   
defineProperty("pkp_fail_left", globalPropertyi("tu154/custom/bkk/pkp_fail_left")) --    -   
defineProperty("pkp_fail_right", globalPropertyi("tu154/custom/bkk/pkp_fail_right")) --    -   	

-- lamps
defineProperty("roll_left_high", globalPropertyf("tu154/custom/lights/roll_left_high")) --   
defineProperty("roll_right_high", globalPropertyf("tu154/custom/lights/roll_right_high")) --   
defineProperty("mgv_control_fail", globalPropertyf("tu154/custom/lights/mgv_control_fail")) --   
defineProperty("no_ag_controll", globalPropertyf("tu154/custom/lights/no_ag_controll")) --   

defineProperty("bkk_ok", globalPropertyf("tu154/custom/lights/small/bkk_ok")) -- bkk

defineProperty("mgv_flag", globalPropertyf("tu154/custom/gyro/mgv_contr_flag")) --  
defineProperty("ias", globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")) -- ias variable
defineProperty("radio_alt", globalPropertyf("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")) -- altitude in feet

defineProperty("bkk_pitch", globalPropertyf("tu154/custom/bkk/bkk_pitch")) --    
defineProperty("bkk_roll", globalPropertyf("tu154/custom/bkk/bkk_roll")) --    

--defineProperty("pitch_sub_mode", globalPropertyi("tu154/custom/absu/pitch_sub_mode")) --    . 0 - , 1 - , 2 - V, 3 - M, 4 - H, 5 - , 6 - 
defineProperty("absu_landing_on", globalPropertyi("tu154/custom/switchers/console/absu_landing_on")) --  

defineProperty("test_lamps", globalPropertyi("tu154/custom/buttons/lamp_test_front")) --    
defineProperty("day_night_set", globalPropertyf("tu154/custom/lights/day_night_set")) --   - . 0 - , 1 - .    .

defineProperty("bus27_volt_left", globalPropertyf("tu154/custom/elec/bus27_volt_left")) --   27
defineProperty("bus27_volt_right", globalPropertyf("tu154/custom/elec/bus27_volt_right")) --   27

-- result flags
local fail_a = false
local fail_b = false
local fail_c = false

local flag_ab = false
local flag_ac = false
local flag_bc = false

local roll_res = 0
local pitch_res = 0

local flight_mode = true -- true - flight mode, false - landing mode

function update()

	local power = get(bkk_on) == 1 and get(bus27_volt_left) > 13 and get(bus27_volt_right) > 13 and get(bkk_fail) == 0
	
	local a = get(roll_a)
	local b = get(roll_b)
	local c = get(roll_c)
	
	-- calculate fail flags
	if power then
		-- cross check all AHZs
		if math.abs (a - b) > 7 then flag_ab = true end
		if math.abs (a - c) > 7 then flag_ac = true end
		if math.abs (b - c) > 7 then flag_bc = true end

		if not fail_a then fail_a = flag_ab and flag_ac end
		if not fail_b then fail_b = flag_ab and flag_bc end
		if not fail_c then fail_c = flag_ac and flag_bc end
	else
		-- reset flags
		fail_a = false
		fail_b = false
		fail_c = false	
		
		flag_ab = false
		flag_ac = false
		flag_bc = false

	end
	
	-- generate signals
	local roll_left = 0
	local roll_right = 0
	local pkp_fail_l = 0
	local pkp_fail_r = 0
	local mgv_fail = 0
	local bkk_fail = 0
	local bkk_test_ok = 0
	
	local test = get(bkk_contr) ~= 0
	
	local spd = get(ias) * 1.852 -- km/hr
	local alt = get(radio_alt) * 0.3048 -- meters
	
	if spd <= 280 or (alt <= 250 and get(absu_landing_on) == 1) then flight_mode = false -- landing mode
	elseif spd >= 340 then flight_mode = true end -- flight mode
	
	if power then
		roll_left = bool2int(test or (a < -33 and flight_mode) or (a < -15 and not flight_mode))
		roll_right = bool2int(test or (a > 33 and flight_mode) or (a > 15 and not flight_mode))
		pkp_fail_l = bool2int(fail_a or test)
		pkp_fail_r = bool2int(fail_b or test)
		mgv_fail = bool2int(fail_c or get(mgv_flag) == 1 or test)
		bkk_test_ok = bool2int(test)
		--bkk_fail = bool2int(fail_a) + bool2int(fail_b) + bool2int(fail_c) > 1
		
		if test then
			fail_a = false
			fail_b = false
			fail_c = false
			
			flag_ab = false
			flag_ac = false
			flag_bc = false
		end
		
	else
		roll_left = 0
		roll_right = 0
		bkk_test_ok = 0
		bkk_fail = 1
	
	end
	
	--print(fail_a, "  ", fail_b, "  ", fail_c)
	
	if pkp_fail_l + pkp_fail_r + mgv_fail < 3 then
		roll_res = (a * (1 - pkp_fail_l) + b * (1 - pkp_fail_r) + c * (1 - mgv_fail)) / ((1 - pkp_fail_l) + (1 - pkp_fail_r) + (1 - mgv_fail))
		
		local ap = get(pitch_a)
		local bp = get(pitch_b)
		local cp = get(pitch_c)
		
		pitch_res = (ap * (1 - pkp_fail_l) + bp * (1 - pkp_fail_r) + cp * (1 - mgv_fail)) / ((1 - pkp_fail_l) + (1 - pkp_fail_r) + (1 - mgv_fail))
		
		--print(ap, "  ", bp, "  ", cp, "  ", pitch_res)
	end
	
--	print(get(pitch_a), "  ", get(pitch_b), "  ", get(pitch_c), "  ", pitch_res)
	
	set(bkk_pitch, pitch_res)
	set(bkk_roll, roll_res)
	
	-- set results
	set(left_roll_big, roll_left)
	set(right_roll_big, roll_right)
	set(mgv_contr_fail, mgv_fail)
	set(no_contr_ag, bkk_fail)
	set(pkp_fail_left, pkp_fail_l)
	set(pkp_fail_right, pkp_fail_r)
	
	-- set lamps
	local test_btn = get(test_lamps) * math.max((get(bus27_volt_right) - 10) / 18.5, 0)
	local day_night = 1 - get(day_night_set) * 0.25
	local lamps_brt = math.max((math.max(get(bus27_volt_left), get(bus27_volt_right)) - 10) / 18.5, 0) * day_night
	
	local roll_left_high_brt = math.max(roll_left * lamps_brt, test_btn)
	set(roll_left_high, roll_left_high_brt)
	
	local roll_right_high_brt = math.max(roll_right * lamps_brt, test_btn)
	set(roll_right_high, roll_right_high_brt)
	
	local mgv_control_fail_brt = math.max(mgv_fail * lamps_brt, test_btn)
	set(mgv_control_fail, mgv_control_fail_brt)
	
	local no_ag_controll_brt = math.max(bkk_fail * lamps_brt, test_btn)
	set(no_ag_controll, no_ag_controll_brt)
	
	set(bkk_ok, bkk_test_ok)
	
end

