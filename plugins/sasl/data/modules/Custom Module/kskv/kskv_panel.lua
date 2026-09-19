-- kskv_panel.lua
-- control panel for KSKV system

-- controls on panel
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    { "cabin_sel", "tu154/custom/switchers/airbleed/cabin_sel", globalPropertyi }, --
    { "cockpit_temp_set", "tu154/custom/switchers/airbleed/cockpit_temp_set", globalPropertyi }, --
    { "cabin1_temp_set", "tu154/custom/switchers/airbleed/cabin1_temp_set", globalPropertyi }, --
    { "cabin2_temp_set", "tu154/custom/switchers/airbleed/cabin2_temp_set", globalPropertyi }, --
    { "cockpit_mode_set", "tu154/custom/switchers/airbleed/cockpit_mode_set", globalPropertyi }, --   . 0 - . 1 - , 2 - , 3 -
    { "cabin1_mode_set", "tu154/custom/switchers/airbleed/cabin1_mode_set", globalPropertyi }, --
    { "cabin2_mode_set", "tu154/custom/switchers/airbleed/cabin2_mode_set", globalPropertyi }, --
    { "heat_close", "tu154/custom/switchers/airbleed/heat_close", globalPropertyi }, --
    { "heat_close_cap", "tu154/custom/switchers/airbleed/heat_close_cap", globalPropertyi }, --

    { "left_sys_temp_set", "tu154/custom/switchers/airbleed/left_sys_temp_set", globalPropertyi }, --
    { "right_sys_temp_set", "tu154/custom/switchers/airbleed/right_sys_temp_set", globalPropertyi }, --
    { "left_sys_mode_set", "tu154/custom/switchers/airbleed/left_sys_mode_set", globalPropertyi }, --
    { "right_sys_mode_set", "tu154/custom/switchers/airbleed/right_sys_mode_set", globalPropertyi }, --
    { "ground_cond_on", "tu154/custom/switchers/airbleed/ground_cond_on", globalPropertyi }, --
    { "ground_cond_on_cap", "tu154/custom/switchers/airbleed/ground_cond_on_cap", globalPropertyi }, --
    { "skv_faster_work", "tu154/custom/switchers/airbleed/skv_faster_work", globalPropertyi }, --  , 0 - , +1 -
    { "skv_faster_work_cap", "tu154/custom/switchers/airbleed/skv_faster_work_cap", globalPropertyi }, --  ,
    { "sys_temp_select", "tu154/custom/switchers/airbleed/sys_temp_select", globalPropertyi }, --   . 0 -  , 1 - , 2 -  1, 3 -  2, 4 -  , 5 -

    { "psvp_left_on", "tu154/custom/switchers/airbleed/psvp_left_on", globalPropertyi }, --
    { "psvp_right_on", "tu154/custom/switchers/airbleed/psvp_right_on", globalPropertyi }, --
    { "psvp_left_on_cap", "tu154/custom/switchers/airbleed/psvp_left_on_cap", globalPropertyi }, --
    { "psvp_right_on_cap", "tu154/custom/switchers/airbleed/psvp_right_on_cap", globalPropertyi }, --
    { "air_valve_left", "tu154/custom/switchers/airbleed/air_valve_left", globalPropertyi }, --  . -1 , 0 - , +1
    { "air_valve_right", "tu154/custom/switchers/airbleed/air_valve_right", globalPropertyi }, --  . -1 , 0 - , +1
    { "air_valve_both", "tu154/custom/switchers/airbleed/air_valve_both", globalPropertyi }, --  . -1 , 0 - , +1
    { "emerg_decompress", "tu154/custom/switchers/airbleed/emerg_decompress", globalPropertyi }, --
    { "emerg_decompress_cap", "tu154/custom/switchers/airbleed/emerg_decompress_cap", globalPropertyi }, --
    { "eng_valve_1", "tu154/custom/switchers/airbleed/eng_valve_1", globalPropertyi }, --
    { "eng_valve_2", "tu154/custom/switchers/airbleed/eng_valve_2", globalPropertyi }, --
    { "eng_valve_3", "tu154/custom/switchers/airbleed/eng_valve_3", globalPropertyi }, --
    { "dubler_on", "tu154/custom/switchers/airbleed/dubler_on", globalPropertyi }, --
    { "dubler_on_cap", "tu154/custom/switchers/airbleed/dubler_on_cap", globalPropertyi }, --

    { "sard_disable", "tu154/custom/switchers/eng/sard_disable", globalPropertyi }, --
    { "sard_disable_cap", "tu154/custom/switchers/eng/sard_disable_cap", globalPropertyi }, --

    { "door_heat", "tu154/custom/switchers/eng/door_heat", globalPropertyi }, --

    -- buttons
    { "lamp_test_srd", "tu154/custom/buttons/lamp_test_srd", globalPropertyi }, --
    { "lamp_test_front", "tu154/custom/buttons/lamp_test_front", globalPropertyi }, --      	0
    { "day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf }, --   - . 0 - , 1 - .    .

    { "srd_buzzer_test", "tu154/custom/buttons/eng/srd_buzzer_test", globalPropertyf }, --

    -- lamps
    { "skv_overheat", "tu154/custom/lights/small/skv_overheat", globalPropertyf }, --
    { "skv_overpress_left", "tu154/custom/lights/small/skv_overpress_left", globalPropertyf }, --
    { "skv_overpress_right", "tu154/custom/lights/small/skv_overpress_right", globalPropertyf }, --
    { "skv_tail_temp", "tu154/custom/lights/small/skv_tail_temp", globalPropertyf }, --

    { "skv_bleed_fail_1", "tu154/custom/lights/small/skv_bleed_fail_1", globalPropertyf }, --
    { "skv_bleed_fail_2", "tu154/custom/lights/small/skv_bleed_fail_2", globalPropertyf }, --
    { "skv_bleed_fail_3", "tu154/custom/lights/small/skv_bleed_fail_3", globalPropertyf }, --

    { "skv_bleed_closed_1", "tu154/custom/lights/small/skv_bleed_closed_1", globalPropertyf }, --
    { "skv_bleed_closed_2", "tu154/custom/lights/small/skv_bleed_closed_2", globalPropertyf }, --
    { "skv_bleed_closed_3", "tu154/custom/lights/small/skv_bleed_closed_3", globalPropertyf }, --

    { "srd_low_press", "tu154/custom/lights/small/srd_low_press", globalPropertyf }, --
    { "srd_overpress", "tu154/custom/lights/small/srd_overpress", globalPropertyf }, --
    { "cockpit_p_low", "tu154/custom/lights/cockpit_p_low", globalPropertyf }, --

    -- gauges
    { "cockpit_temp_gau", "tu154/custom/gauges/airbleed/cockpit_temp", globalPropertyf }, --
    { "cabin_temp_gau", "tu154/custom/gauges/airbleed/cabin_temp", globalPropertyf }, --
    { "system_temp", "tu154/custom/gauges/airbleed/system_temp", globalPropertyf }, --
    { "air_flow_1", "tu154/custom/gauges/airbleed/air_flow_1", globalPropertyf }, --  .
    { "air_flow_2", "tu154/custom/gauges/airbleed/air_flow_2", globalPropertyf }, --  .

    -- sources
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time

    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },

    { "eng_airvalve_1", "tu154/custom/bleed/eng_airvalve_1", globalPropertyf }, --
    { "eng_airvalve_2", "tu154/custom/bleed/eng_airvalve_2", globalPropertyf }, --
    { "eng_airvalve_3", "tu154/custom/bleed/eng_airvalve_3", globalPropertyf }, --

    { "air_usage_L", "tu154/custom/bleed/air_usage_L", globalPropertyf }, --
    { "air_usage_R", "tu154/custom/bleed/air_usage_R", globalPropertyf }, --

    { "door_heat_tube_t", "tu154/custom/bleed/door_heat_tube_t", globalPropertyf }, --
    { "cockpit_tube_t", "tu154/custom/bleed/cockpit_tube_t", globalPropertyf }, --
    { "cabin1_tube_t", "tu154/custom/bleed/cabin1_tube_t", globalPropertyf }, --      1
    { "cabin2_tube_t", "tu154/custom/bleed/cabin2_tube_t", globalPropertyf }, --      2
    { "cold_tube1_t", "tu154/custom/bleed/cold_tube1_t", globalPropertyf }, --    1
    { "cold_tube2_t", "tu154/custom/bleed/cold_tube2_t", globalPropertyf }, --    2

    { "cockpit_temp", "tu154/custom/bleed/cockpit_temp", globalPropertyf }, --
    { "cabin_1_temp", "tu154/custom/bleed/cabin_1_temp", globalPropertyf }, --    1
    { "cabin_2_temp", "tu154/custom/bleed/cabin_2_temp", globalPropertyf }, --    2

    -- { "hot_tube_t", "tu154/custom/bleed/hot_tube_t", globalPropertyf }, --

    { "actual_cabin_alt", "sim/cockpit2/pressurization/indicators/cabin_altitude_ft", globalPropertyf },
    { "cabin_press_diff", "sim/cockpit2/pressurization/indicators/pressure_diffential_psi", globalPropertyf },

    -- failures
    { "airbleed_1", "tu154/custom/failures/airbleed_1", globalPropertyi }, --
    { "airbleed_2", "tu154/custom/failures/airbleed_2", globalPropertyi }, --
    { "airbleed_3", "tu154/custom/failures/airbleed_3", globalPropertyi }, --

    { "main_pressure", "tu154/custom/alarm/main_pressure", globalPropertyi }, --

    -- sounds
    -- time

    -- engines
    { "eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalProperty }, -- engine 1 rpm
    { "eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalProperty }, -- engine 2 rpm
    { "eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalProperty }, -- engine 3 rpm
})

local rotary_sound = sasl.al.loadSample('Custom Sounds/plastic_switch.wav')
local switcher_sound = sasl.al.loadSample('Custom Sounds/metal_switch.wav')
local cap_sound = sasl.al.loadSample('Custom Sounds/cap.wav')
local button_sound = sasl.al.loadSample('Custom Sounds/plastic_btn.wav')
local passed = get(frame_time)

local notLoaded = true

local function reset_switchers()
	if isColdAndDarkStart() and get(eng1_N1) < 5 and get(eng2_N1) < 5 and get(eng3_N1) < 5 then
		set(cockpit_mode_set, 0)
		set(cabin1_mode_set, 0)
		set(cabin2_mode_set, 0)
		set(left_sys_mode_set, 0)
		set(right_sys_mode_set, 0)
		set(psvp_left_on, 0)
		set(psvp_right_on, 0)
		set(eng_valve_1, 0)
		set(eng_valve_2, 0)
		set(eng_valve_3, 0)
		
	end
	
	notLoaded = false
end

local lamp_test_srd_last = get(lamp_test_srd)

local cab_P_counter = 0
local cab_P_lit = 0

local cab_high_counter = 0
local cab_high_lit = 0

local function lamps()
	-- make sound for button
	local test_btn = get(lamp_test_srd)
	if test_btn ~= lamp_test_srd_last then sasl.al.playSample(button_sound, false) end
	lamp_test_srd_last = test_btn
	
	local day_night = 1 - get(day_night_set) * 0.25
	
	test_btn = test_btn * math.max((get(bus27_volt_right) - 10) / 18.5, 0)
	
	local test_btn_frnt = get(lamp_test_front)
	
	local power27_L = get(bus27_volt_left)
	local power27_R = get(bus27_volt_right)
	
	local lamps_brt = math.max((math.max(power27_L, power27_R) - 10) / 18.5, 0)
	
	local skv_overheat_brt = 0
	if get(cold_tube1_t) > 75 or get(cold_tube2_t) > 75 then skv_overheat_brt = 1 end
	skv_overheat_brt = math.max(skv_overheat_brt * lamps_brt, test_btn)
	set(skv_overheat, skv_overheat_brt)
	
	local skv_overpress_left_brt = math.max(0, test_btn) -- fake for now
	set(skv_overpress_left, skv_overpress_left_brt)	
	
	local skv_overpress_right_brt = math.max(0, test_btn) -- fake for now
	set(skv_overpress_right, skv_overpress_right_brt)	
	
	local skv_tail_temp_brt = math.max(0, test_btn) -- fake for now
	set(skv_tail_temp, skv_tail_temp_brt)	

	local skv_bleed_fail_1_brt = 0
	if get(eng_valve_1) == 1 and get(airbleed_1) == 1 and power27_L > 10 then skv_bleed_fail_1_brt = 1 end
	skv_bleed_fail_1_brt = math.max(skv_bleed_fail_1_brt * lamps_brt , test_btn)
	set(skv_bleed_fail_1, skv_bleed_fail_1_brt)	
	
	local skv_bleed_fail_2_brt = 0
	if get(eng_valve_2) == 1 and get(airbleed_2) == 1 and power27_R > 10 then skv_bleed_fail_2_brt = 1 end
	skv_bleed_fail_2_brt = math.max(skv_bleed_fail_2_brt * lamps_brt, test_btn) 
	set(skv_bleed_fail_2, skv_bleed_fail_2_brt)	

	local skv_bleed_fail_3_brt = 0
	if get(eng_valve_3) == 1 and get(airbleed_3) == 1 and power27_R > 10 then skv_bleed_fail_3_brt = 1 end
	skv_bleed_fail_3_brt = math.max(skv_bleed_fail_3_brt * lamps_brt, test_btn)
	set(skv_bleed_fail_3, skv_bleed_fail_3_brt)		

	local skv_bleed_closed_1_brt = 0
	if get(eng_airvalve_1) < 0.5 and power27_L > 10 then skv_bleed_closed_1_brt = 1 end
	skv_bleed_closed_1_brt = math.max(skv_bleed_closed_1_brt * lamps_brt, test_btn) 
	set(skv_bleed_closed_1, skv_bleed_closed_1_brt)	

	local skv_bleed_closed_2_brt = 0
	if get(eng_airvalve_2) < 0.5 and power27_R > 10 then skv_bleed_closed_2_brt = 1 end
	skv_bleed_closed_2_brt = math.max(skv_bleed_closed_2_brt * lamps_brt, test_btn) 
	set(skv_bleed_closed_2, skv_bleed_closed_2_brt)	
	
	local skv_bleed_closed_3_brt = 0
	if get(eng_airvalve_3) < 0.5 and power27_R > 10 then skv_bleed_closed_3_brt = 1 end
	skv_bleed_closed_3_brt = math.max(skv_bleed_closed_3_brt * lamps_brt, test_btn) 
	set(skv_bleed_closed_3, skv_bleed_closed_3_brt)	
	
	-- other lamps
	local buzz_test = get(srd_buzzer_test)
	local low_cab_P = get(actual_cabin_alt) * 0.3048 > 3300 or buzz_test == 1
	
	if low_cab_P then cab_P_counter = cab_P_counter + passed
	else 
		cab_P_counter = 0 
		cab_P_lit = 0	
	end
	
	if low_cab_P and cab_P_counter > 0.3 then
		cab_P_lit = math.abs(1 - cab_P_lit)
		cab_P_counter = 0
	end
	
	local high_cab_P = get(cabin_press_diff) * 0.0778 > 0.72 or buzz_test == 1

	if high_cab_P then cab_high_counter = cab_high_counter + passed
	else 
		cab_high_counter = 0 
		cab_high_lit = 0	
	end
	
	if high_cab_P and cab_high_counter > 0.3 then
		cab_high_lit = math.abs(1 - cab_high_lit)
		cab_high_counter = 0
	end	
	
	set(main_pressure, bool2int(low_cab_P or high_cab_P))
	
	local srd_low_press_brt = math.max(cab_P_lit * lamps_brt, 0)
	set(srd_low_press, srd_low_press_brt)
	
	local srd_overpress_brt = math.max(cab_high_lit * lamps_brt, 0)
	set(srd_overpress, srd_overpress_brt)
	
	local cockpit_p_low_brt = math.max(cab_P_lit * lamps_brt * day_night, test_btn_frnt)
	set(cockpit_p_low, cockpit_p_low_brt)
	
end

local cockpit_temp_set_last = get(cockpit_temp_set)
local cabin1_temp_set_last = get(cabin1_temp_set)
local cabin2_temp_set_last = get(cabin2_temp_set)
local left_sys_temp_set_last = get(left_sys_temp_set)
local right_sys_temp_set_last = get(right_sys_temp_set)
local sys_temp_select_last = get(sys_temp_select)

local function rotary_sw()

	local cockpit_temp_set_sw = get(cockpit_temp_set)
	local cabin1_temp_set_sw = get(cabin1_temp_set)
	local cabin2_temp_set_sw = get(cabin2_temp_set)
	local left_sys_temp_set_sw = get(left_sys_temp_set)
	local right_sys_temp_set_sw = get(right_sys_temp_set)
	local sys_temp_select_sw = get(sys_temp_select)
	
	local change = cockpit_temp_set_sw + cabin1_temp_set_sw + cabin2_temp_set_sw + left_sys_temp_set_sw + right_sys_temp_set_sw + sys_temp_select_sw
	change = change - cockpit_temp_set_last - cabin1_temp_set_last - cabin2_temp_set_last - left_sys_temp_set_last - right_sys_temp_set_last - sys_temp_select_last
	
if change ~= 0 then
    sasl.al.playSample(rotary_sound, false)
end
	
	cockpit_temp_set_last = cockpit_temp_set_sw
	cabin1_temp_set_last = cabin1_temp_set_sw
	cabin2_temp_set_last = cabin2_temp_set_sw
	left_sys_temp_set_last = left_sys_temp_set_sw
	right_sys_temp_set_last = right_sys_temp_set_sw
	sys_temp_select_last = sys_temp_select_sw

end

local air_gau_tbl = {{ -100000, -160 },    -- bugs walkaround
                  {  0, -160 }, -- 0.0
				  { 300, -145 },   --
				  { 400, -136 }, -- 
				  { 600, -107 }, -- 
				  { 700, -90 }, -- 
				  { 900, -45 }, -- 
				  { 1200, 48 }, --
				  { 1300, 86 }, --
				  { 1500, 160 }, -- 
				  { 1600, 190 }, -- 
          	      { 10000000, 190 }}    -- bugs walkaround

local air_temp_tbl = {{ -100000, -105 },    -- bugs walkaround
                  {  -65, -105 }, -- 0.0
				  {  -60, -100 }, -- 0.0
				  { -30, -48 },   --
				  { 0, 0 }, -- 
				  { 30, 48 }, -- 
				  { 60, 82 }, -- 
				  { 70, 92 }, -- 
				  { 100, 100 }, -- 
          	      { 10000000, 100 }}    -- bugs walkaround
				  
local flow_angle_L_act = -160
local flow_angle_R_act = -160

local cocpit_t_ang_act = -105
local cabin_t_ang_act = -105

local sys_t_act = -70

local function gauges()
	-- air flow
	local angle_L = interpolate(air_gau_tbl, get(air_usage_L))
	local angle_R = interpolate(air_gau_tbl, get(air_usage_R))
	
	if angle_L - flow_angle_L_act < 0 then
		flow_angle_L_act = flow_angle_L_act + sign(angle_L - flow_angle_L_act) * math.min(math.abs(angle_L - flow_angle_L_act), 20) * passed * 4
	else
		flow_angle_L_act = flow_angle_L_act + sign(angle_L - flow_angle_L_act) * math.min(math.abs(angle_L - flow_angle_L_act), 10) * passed * 2
	end
	
	if angle_R - flow_angle_R_act < 0 then
		flow_angle_R_act = flow_angle_R_act + sign(angle_R - flow_angle_R_act) * math.min(math.abs(angle_R - flow_angle_R_act), 20) * passed * 4
	else
		flow_angle_R_act = flow_angle_R_act + sign(angle_R - flow_angle_R_act) * math.min(math.abs(angle_R - flow_angle_R_act), 10) * passed * 2
	end
	
	set(air_flow_1, flow_angle_L_act)
	set(air_flow_2, flow_angle_R_act)

	-----------------
	-- cabins temp
	local cockpit_t_ang = -105
	local cabin_t_ang = -105
	
	if get(bus27_volt_right) > 13 then
		cockpit_t_ang = interpolate(air_temp_tbl, get(cockpit_temp))
	
		if get(cabin_sel) == 1 then
			cabin_t_ang = interpolate(air_temp_tbl, get(cabin_1_temp))
		else
			cabin_t_ang = interpolate(air_temp_tbl, get(cabin_2_temp))
		end
	end
	
	cocpit_t_ang_act = cocpit_t_ang_act + (cockpit_t_ang - cocpit_t_ang_act) * passed * 2
	cabin_t_ang_act = cabin_t_ang_act + (cabin_t_ang - cabin_t_ang_act) * passed * 2
	
	set(cockpit_temp_gau, cocpit_t_ang_act)
	set(cabin_temp_gau, cabin_t_ang_act)
	
	-- tubes temp
	local system_t = -75
	local system_gau_sel = get(sys_temp_select)
	
	if get(bus27_volt_right) > 13 then
		if system_gau_sel == 0 then
			system_t = get(door_heat_tube_t)
		elseif system_gau_sel == 1 then
			system_t = get(cockpit_tube_t)
		elseif system_gau_sel == 2 then
			system_t = get(cabin1_tube_t)
		elseif system_gau_sel == 3 then
			system_t = get(cabin2_tube_t)
		elseif system_gau_sel == 4 then
			system_t = get(cold_tube1_t)
		else
			system_t = get(cold_tube2_t)
		end
	end
	if system_t < -75 then system_t = -75
	elseif system_t > 155 then system_t = 155 end
	
	sys_t_act = sys_t_act + (system_t - sys_t_act) * passed * 2
	
	set(system_temp, sys_t_act)
	
end

local cabin_sel_last = get(cabin_sel)
local heat_close_last = get(heat_close)
local ground_cond_on_last = get(ground_cond_on)
local skv_faster_work_last = get(skv_faster_work)
local psvp_left_on_last = get(psvp_left_on)
local psvp_right_on_last = get(psvp_right_on)
local air_valve_left_last = get(air_valve_left)
local air_valve_right_last = get(air_valve_right)
local emerg_decompress_last = get(emerg_decompress)
local eng_valve_1_last = get(eng_valve_1)
local eng_valve_2_last = get(eng_valve_2)
local eng_valve_3_last = get(eng_valve_3)
local dubler_on_last = get(dubler_on)

local cockpit_mode_set_last = get(cockpit_mode_set)
local cabin1_mode_set_last = get(cabin1_mode_set)
local cabin2_mode_set_last = get(cabin2_mode_set)
local left_sys_mode_set_last = get(left_sys_mode_set)
local right_sys_mode_set_last = get(right_sys_mode_set)

local sard_disable_last = get(sard_disable)
local door_heat_last = get(door_heat)

local air_valve_both_last = get(air_valve_both)

local function check_switchers()

	local cabin_sel_sw = get(cabin_sel)
	local heat_close_sw = get(heat_close)
	local ground_cond_on_sw = get(ground_cond_on)
	local skv_faster_work_sw = get(skv_faster_work)
	local psvp_left_on_sw = get(psvp_left_on)
	local psvp_right_on_sw = get(psvp_right_on)
	local air_valve_left_sw = get(air_valve_left)
	local air_valve_right_sw = get(air_valve_right)
	local emerg_decompress_sw = get(emerg_decompress)
	local eng_valve_1_sw = get(eng_valve_1)
	local eng_valve_2_sw = get(eng_valve_2)
	local eng_valve_3_sw = get(eng_valve_3)
	local dubler_on_sw = get(dubler_on)

	local cockpit_mode_set_sw = get(cockpit_mode_set)
	local cabin1_mode_set_sw = get(cabin1_mode_set)
	local cabin2_mode_set_sw = get(cabin2_mode_set)
	local left_sys_mode_set_sw = get(left_sys_mode_set)
	local right_sys_mode_set_sw = get(right_sys_mode_set)
	
	local sard_disable_sw = get(sard_disable)
	local door_heat_sw = get(door_heat)
	
	local change = cabin_sel_sw + heat_close_sw + ground_cond_on_sw + skv_faster_work_sw + psvp_left_on_sw + psvp_right_on_sw
	change = change + air_valve_left_sw + air_valve_right_sw + emerg_decompress_sw + eng_valve_1_sw + eng_valve_2_sw + eng_valve_3_sw + dubler_on_sw
	change = change + cockpit_mode_set_sw + cabin1_mode_set_sw + cabin2_mode_set_sw + left_sys_mode_set_sw + right_sys_mode_set_sw
	change = change + sard_disable_sw + door_heat_sw
	
	change = change - cabin_sel_last - heat_close_last - ground_cond_on_last - skv_faster_work_last - psvp_left_on_last - psvp_right_on_last
	change = change - air_valve_left_last - air_valve_right_last - emerg_decompress_last - eng_valve_1_last - eng_valve_2_last - eng_valve_3_last - dubler_on_last
	change = change - cockpit_mode_set_last - cabin1_mode_set_last - cabin2_mode_set_last - left_sys_mode_set_last - right_sys_mode_set_last
	change = change - sard_disable_last - door_heat_last
	
	if change ~= 0 then sasl.al.playSample(switcher_sound, false) end
	
	cabin_sel_last = cabin_sel_sw
	heat_close_last = heat_close_sw
	ground_cond_on_last = ground_cond_on_sw
	skv_faster_work_last = skv_faster_work_sw
	psvp_left_on_last = psvp_left_on_sw
	psvp_right_on_last = psvp_right_on_sw
	air_valve_left_last = air_valve_left_sw
	air_valve_right_last = air_valve_right_sw
	emerg_decompress_last = emerg_decompress_sw
	eng_valve_1_last = eng_valve_1_sw
	eng_valve_2_last = eng_valve_2_sw
	eng_valve_3_last = eng_valve_3_sw
	dubler_on_last = dubler_on_sw
	
	cockpit_mode_set_last = cockpit_mode_set_sw
	cabin1_mode_set_last = cabin1_mode_set_sw
	cabin2_mode_set_last = cabin2_mode_set_sw
	left_sys_mode_set_last = left_sys_mode_set_sw
	right_sys_mode_set_last = right_sys_mode_set_sw
	
	sard_disable_last = sard_disable_sw
	door_heat_last = door_heat_sw
	
	local air_valve_both_sw = get(air_valve_both)
	
	if air_valve_both_sw == 1 then 
		set(air_valve_left, 1)
		set(air_valve_right, 1)
	elseif air_valve_both_sw == -1 then
		set(air_valve_left, -1)
		set(air_valve_right, -1)
	elseif air_valve_both_last ~= air_valve_both_sw and air_valve_both_sw == 0 then
		set(air_valve_left, 0)
		set(air_valve_right, 0)	
	end
	
	air_valve_both_last = air_valve_both_sw
	
end

local heat_close_cap_last = get(heat_close_cap)
local ground_cond_on_cap_last = get(ground_cond_on_cap)
local skv_faster_work_cap_last = get(skv_faster_work_cap)
local psvp_left_on_cap_last = get(psvp_left_on_cap)
local psvp_right_on_cap_last = get(psvp_right_on_cap)
local emerg_decompress_cap_last = get(emerg_decompress_cap)
local dubler_on_cap_last = get(dubler_on_cap)
local sard_disable_cap_last = get(sard_disable_cap)

local function caps_check()

	local heat_close_cap_sw = get(heat_close_cap)
	local ground_cond_on_cap_sw = get(ground_cond_on_cap)
	local skv_faster_work_cap_sw = get(skv_faster_work_cap)
	local psvp_left_on_cap_sw = get(psvp_left_on_cap)
	local psvp_right_on_cap_sw = get(psvp_right_on_cap)
	local emerg_decompress_cap_sw = get(emerg_decompress_cap)
	local dubler_on_cap_sw = get(dubler_on_cap)
	local sard_disable_cap_sw = get(sard_disable_cap)
	
	local change = heat_close_cap_sw + ground_cond_on_cap_sw + skv_faster_work_cap_sw + psvp_left_on_cap_sw + psvp_right_on_cap_sw
	change = change + emerg_decompress_cap_sw + dubler_on_cap_sw + sard_disable_cap_sw
	
	change = change - heat_close_cap_last - ground_cond_on_cap_last - skv_faster_work_cap_last - psvp_left_on_cap_last - psvp_right_on_cap_last
	change = change - emerg_decompress_cap_last - dubler_on_cap_last - sard_disable_cap_last

	if change ~= 0 then sasl.al.playSample(cap_sound, false) end

	heat_close_cap_last = heat_close_cap_sw
	ground_cond_on_cap_last = ground_cond_on_cap_sw
	skv_faster_work_cap_last = skv_faster_work_cap_sw
	psvp_left_on_cap_last = psvp_left_on_cap_sw
	psvp_right_on_cap_last = psvp_right_on_cap_sw
	emerg_decompress_cap_last = emerg_decompress_cap_sw
	dubler_on_cap_last = dubler_on_cap_sw
	sard_disable_cap_last = sard_disable_cap_sw
	
	-- check switchers position under their caps
	--if skv_faster_work_cap_sw == 0 then set(skv_faster_work, 0) end
	if dubler_on_cap_sw == 0 then set(dubler_on, 0) end
	if emerg_decompress_cap_sw == 0 then set(emerg_decompress, 0) end
	if sard_disable_cap_sw == 0 then set(sard_disable, 0) end
end

local sim_start_timer = 0

function update()
	
	passed = get(frame_time)
	
	-- reset switchers
	sim_start_timer = sim_start_timer + passed
	if sim_start_timer > 0.3 then 
		if notLoaded then reset_switchers() end
		
		rotary_sw()
		check_switchers() -- make them sound
		caps_check() -- make them sound
		lamps()
		
	end
	
	gauges()

end