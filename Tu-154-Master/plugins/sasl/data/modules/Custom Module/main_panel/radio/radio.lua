-- thi is radio panel main script. VHF radios, CourseMP and ARK
size = {2048, 2048}

components = {

	vhf {
		position = {13, 658, 420, 93},
	},
	
	vhf {
		position = {13, 556, 420, 93},
		num = 1,
		--frequency = globalPropertyf("sim/cockpit2/radios/actuators/com2_frequency_hz"),  -- set the frequency
		-- controls
		vhf_left = globalPropertyi("tu154/custom/rotary/ovhd/vhf_2_left"),  -- knob
		vhf_right = globalPropertyi("tu154/custom/rotary/ovhd/vhf_2_right"),  -- knob
		vhf_on = globalPropertyi("tu154/custom/switchers/ovhd/vhf_2_on"),  -- power switch
		bus27_volt = globalPropertyf("tu154/custom/elec/bus27_volt_right"), -- power
		com_power = globalPropertyi("sim/cockpit2/radios/actuators/com2_power"), -- sim com power
		vhf_cc = globalPropertyf("tu154/custom/radio/vhf2_cc"),
	},
	
	course_mp {
		position = {288, 914, 410, 108},
	
	},
	
	course_mp {
		position = {288, 797, 410, 108},
		-- sources
		frequency = globalPropertyf("sim/cockpit2/radios/actuators/nav2_frequency_hz"),  -- set the frequency
		v_plank = globalPropertyf("sim/cockpit2/radios/indicators/nav2_hdef_dots_pilot"), -- horizontal deflection on course
		h_plank = globalPropertyf("sim/cockpit2/radios/indicators/nav2_vdef_dots_pilot"), -- vertical deflection on glideslope
		cr_flag = globalPropertyf("sim/cockpit2/radios/indicators/nav2_flag_from_to_pilot"), -- Nav-To-From indication, nav1, pilot, 0 is flag, 1 is to, 2 is from.
		gs_flag = globalPropertyf("sim/cockpit/radios/nav2_CDI"),  -- glideslope flag. 0 - flag is shown
		nav_deg = globalPropertyf("sim/cockpit2/radios/indicators/nav2_relative_bearing_deg"), -- nav1 bearing
		sim_fail = globalPropertyi("sim/operation/failures/rel_nav2"), -- fail
		distance = globalPropertyf("sim/cockpit2/radios/indicators/nav2_dme_distance_nm"),  -- distance in NM
		obs = globalPropertyi("sim/cockpit2/radios/actuators/nav2_obs_deg_mag_pilot"), -- OBS course
		nav_fail = globalPropertyi("tu154/custom/failures/nav2_fail"), -- fail
		dme_fail = globalPropertyi("tu154/custom/failures/dme2_fail"), -- fail
		-- controls
		sd75_on = globalPropertyi("tu154/custom/switchers/ovhd/sd75_2_on"), -- switch on
		curs_np_on = globalPropertyi("tu154/custom/switchers/ovhd/curs_np_on_2"), -- switch on
		-- power
		bus36_volt = globalPropertyf("tu154/custom/elec/bus36_volt_right"),
		bus115_volt = globalPropertyf("tu154/custom/elec/bus115_3_volt"),
		nav_pow_cc = globalPropertyf("tu154/custom/radio/nav2_pow_cc"), --    
		nav_mode = globalPropertyi("tu154/custom/switchers/nav_2_mode"), --  1.  - VOR-DME
		nav_man_auto = globalPropertyi("tu154/custom/switchers/nav_2_man_auto"), --   - 
		nav_mile_km = globalPropertyi("tu154/custom/switchers/nav_2_mile_km"), --   - 
		nav_left = globalPropertyi("tu154/custom/rotary/ovhd/nav_2_left"), --  
		nav_right = globalPropertyi("tu154/custom/rotary/ovhd/nav_2_right"), --  
		nav_but_1 = globalPropertyi("tu154/custom/buttons/ovhd/nav_2_but_1"), --  1
		nav_but_2 = globalPropertyi("tu154/custom/buttons/ovhd/nav_2_but_2"), --  2
		nav_but_3 = globalPropertyi("tu154/custom/buttons/ovhd/nav_2_but_3"), --  3
		nav_course = globalPropertyi("tu154/custom/rotary/console/nav_2_course"), --   
		-- results
		vor_dme = globalPropertyf("tu154/custom/radio/vor_dme_2"), -- distance
		vor_bear = globalPropertyf("tu154/custom/radio/vor_bear_2"), -- bearing
		nav_cs = globalPropertyf("tu154/custom/radio/nav2_cs"),
		nav_gs = globalPropertyf("tu154/custom/radio/nav2_gs"),
		nav_cs_flag = globalPropertyi("tu154/custom/radio/nav2_cs_flag"),
		nav_gs_flag = globalPropertyi("tu154/custom/radio/nav2_gs_flag"),
		nav_course_1 = globalPropertyf("tu154/custom/rotary/console/nav_2_course_1"),
		nav_course_10 = globalPropertyf("tu154/custom/rotary/console/nav_2_course_10"),
		nav_course_100 = globalPropertyf("tu154/custom/rotary/console/nav_2_course_100"),
		nav_to_lit = globalPropertyf("tu154/custom/lights/small/nav_2_to"),
		nav_from_lit = globalPropertyf("tu154/custom/lights/small/nav_2_from"),
	},
	
	ark15 {},
	
	ark15 {
		-- source
		left_freq = globalPropertyf("sim/cockpit2/radios/actuators/adf2_left_frequency_hz"),  -- left frequency
		right_freq = globalPropertyf("sim/cockpit2/radios/actuators/adf2_right_frequency_hz"),  -- right frequency
		active = globalPropertyf("sim/cockpit2/radios/actuators/adf2_right_is_selected"),  -- selector of active disk. 0 - left, 1 - right 
		fail = globalPropertyf("sim/operation/failures/rel_adf2"),
		adf = globalPropertyf("sim/cockpit2/radios/indicators/adf2_relative_bearing_deg"),
		audio_selection = globalPropertyi("sim/cockpit2/radios/actuators/audio_selection_adf2"),
		-- controls
		ark_mode = globalPropertyi("tu154/custom/switchers/ovhd/ark_2_mode"), --   1 0 - , 1 - , 2 - , 3 - 
		ark_channel = globalPropertyi("tu154/custom/switchers/ovhd/ark_2_channel"), --   1
		ark_hundr_left = globalPropertyi("tu154/custom/switchers/ovhd/ark_2_hundr_left"), --   1 - 17
		ark_tens_left = globalPropertyi("tu154/custom/switchers/ovhd/ark_2_tens_left"), --   1 - 10 (0)
		ark_ones_left = globalPropertyi("tu154/custom/switchers/ovhd/ark_2_ones_left"), --   0 - 9
		ark_hundr_right = globalPropertyi("tu154/custom/switchers/ovhd/ark_2_hundr_right"), --   1 - 17
		ark_tens_right = globalPropertyi("tu154/custom/switchers/ovhd/ark_2_tens_right"), --   1 - 10 (0)
		ark_ones_right = globalPropertyi("tu154/custom/switchers/ovhd/ark_2_ones_right"), --   0 - 9
		ark_ramka = globalPropertyi("tu154/custom/buttons/ovhd/ark_2_ramka"), --  

		-- light
		ark_left_lit = globalPropertyf("tu154/custom/lights/ark2_left_lit"), --     1
		ark_right_lit = globalPropertyf("tu154/custom/lights/ark2_right_lit"), --     1
		ark_all_lit = globalPropertyf("tu154/custom/lights/ark2_all_lit"), --   1
		
		bus27_volt = globalPropertyf("tu154/custom/elec/bus27_volt_right"),
		bus36_volt = globalPropertyf("tu154/custom/elec/bus36_volt_right"),
		ark15_cc = globalPropertyf("tu154/custom/radio/ark15_R_cc"), --   
		-- results
		adf_bear = globalPropertyf("tu154/custom/radio/adf_bear_2"),
	
	},
	
	dme {
		position = {1616, 1176, 215, 70},
	
	},

	dme {
		position = {1616, 1102, 215, 70},
		vor_dme = globalPropertyf("tu154/custom/radio/vor_dme_2"), -- distance
		sd75_on = globalPropertyi("tu154/custom/switchers/ovhd/sd75_2_on"), -- switch on
		nav_mile_km = globalPropertyi("tu154/custom/switchers/nav_2_mile_km"), --   - 	
		-- lamps
		dme_mile_lit = globalPropertyf("tu154/custom/lights/small/dme_mile_right"), -- mile lamp
		dme_km_lit = globalPropertyf("tu154/custom/lights/small/dme_km_right"), -- km lamp
		-- power
		bus27_volt = globalPropertyf("tu154/custom/elec/bus27_volt_right"),
		bus115_volt = globalPropertyf("tu154/custom/elec/bus115_3_volt"),
	},
	
	spu {},
	mrp {}, -- marker receiver
	radio_fails {},
	
}

