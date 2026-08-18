-- main_panel.lua

--[[
Changelog
- Translated all Russian comments to English.
- Corrected eight confirmed custom-Dataref constructor mismatches against the project Dataref creator files.
- Changed right PKP AHZ/director failure flags from globalPropertyf() to globalPropertyi().
- Changed right VBE pressure from globalPropertyf() to globalPropertyi() and flight-level setting from globalPropertyi() to globalPropertyf().
- Changed right RV-5 test button and power switch from globalPropertyf() to globalPropertyi().
- Changed right RV-5 flag from globalPropertyi() to globalPropertyf().
- Preserved component order, component names, Dataref paths, positions, arguments, and all other runtime behavior.
--]]

-- Main panel layout for panel.png gauges and 2D popup panels.

size = { 2048, 2048 }

components = {
	vers {},
	-- SmartCopilot controls
	sc_controls {},
	-- clock
	achs1 {},
	-- clock on the rear side panel
	clock24 {},
	-- aneroid instruments
	mech_aneroid {},
	-- SVS system
	svs {},
	-- thermometers
	termo {},
	-- feet altimeter
	uvid_15fk {},
	-- Mach meters
	mach_meters {},
	-- AUASP indicator
	uap14 {},
	-- turn indicator
	eup53 {},
	-- standby attitude indicator
	agr {},
	-- left attitude indicator
	pkp {},
	-- right attitude indicator
	pkp {
		-- pitch correction, positive to the right
		pitch_corr_hdl = globalPropertyf("tu154/custom/gauges/ahz/pitch_corr_R"),
		-- power switch
		pkp_on = globalPropertyi("tu154/custom/switchers/ovhd/pkp_right_on"),
		-- BKK signal: PKP failure
		pkp_fail = globalPropertyi("tu154/custom/bkk/pkp_fail_right"),
		-- power supply
		bus27_volt = globalPropertyf("tu154/custom/elec/bus27_volt_right"),
		-- power supply
		bus36_volt = globalPropertyf("tu154/custom/elec/bus36_volt_right"),
		-- pitch, positive nose up
		res_pitch = globalPropertyf("tu154/custom/gauges/ahz/pitch_R"),
		-- internal pitch value, positive up
		pitch_int = globalPropertyf("tu154/custom/gyro/ahz_pitch_int_R"),
		-- roll, positive to the right
		res_roll = globalPropertyf("tu154/custom/gauges/ahz/roll_R"),
		-- roll for BKK, positive to the right
		res_roll_bkk = globalPropertyf("tu154/custom/bkk/pkp_roll_right"),
		-- attitude indicator failure flag
		ahz_flag = globalPropertyi("tu154/custom/gauges/ahz/ahz_flag_R"),
		-- course deviation bar, positive to the right
		course_plank = globalPropertyf("tu154/custom/gauges/ahz/course_plank_R"),
		-- glideslope deviation bar, positive up
		gs_plank = globalPropertyf("tu154/custom/gauges/ahz/gs_plank_R"),
		-- roll director, positive to the right
		dir_roll = globalPropertyf("tu154/custom/gauges/ahz/dir_roll_R"),
		-- pitch director, positive up
		dir_pitch = globalPropertyf("tu154/custom/gauges/ahz/dir_pitch_R"),
		-- roll director failure flag
		dir_roll_flag = globalPropertyi("tu154/custom/gauges/ahz/dir_roll_flag_R"),
		-- pitch director failure flag
		dir_pitch_flag = globalPropertyi("tu154/custom/gauges/ahz/dir_pitch_flag_R"),
		-- PNP indication mode: 0 = off, 1 = NVU, 2 = VOR1, 3 = VOR2, 4 = landing mode
		absu_pnp_mode = globalPropertyi("tu154/custom/absu/absu_pnp_mode_2"),
		-- airspeed difference for PKP indication
		absu_at_dif = globalPropertyf("tu154/custom/absu_at_dif_right"),
		-- airspeed change indication, positive up
		speed_plank = globalPropertyf("tu154/custom/gauges/ahz/speed_plank_R"),
		-- PKP current consumption
		power_cc = globalPropertyf("tu154/custom/bkk/pkp_right_power_cc"),
		fail = globalPropertyi("sim/operation/failures/rel_cop_ahz"),
	},
	-- monitoring attitude indicator without direct display output
	mgv {},
	-- BKK roll-monitoring unit
	bkk {},
	-- electronic altimeter
	-- left electronic altimeter
	vbe_altimeter {
		position = {733, 839, 424, 424},
	},
	-- electronic altimeter
	-- right electronic altimeter
	vbe_altimeter {
		position = {1166, 839, 424, 424},
		gauge_num = 1,
		static_fail = globalPropertyi("sim/operation/failures/rel_static2"),
		-- pressure in hPa
		pressure = globalPropertyi("tu154/custom/gauges/alt/vbe_press_right"),
		-- brightness knob
		brt_knob = globalPropertyf("tu154/custom/gauges/alt/vbe_brt_right"),
		-- pressure knob
		press_knob = globalPropertyi("tu154/custom/gauges/alt/vbe_press_knob_right"),
		-- flight level knob
		fl_knob = globalPropertyi("tu154/custom/gauges/alt/vbe_fl_knob_right"),
		-- mode button
		mode_button = globalPropertyi("tu154/custom/gauges/alt/vbe_mode_but_right"),
		-- 27 V bus voltage
		bus27_volt = globalPropertyf("tu154/custom/elec/bus27_volt_right"),
		-- 115 V bus voltage
		bus115_volt = globalPropertyf("tu154/custom/elec/bus115_3_volt"),
		-- power switcher
		vbe_on = globalPropertyi("tu154/custom/switchers/ovhd/vbe_2_on"),
		-- meters/feet mode
		vbe_mode = globalPropertyi("tu154/custom/gauges/alt/vbe_mode_right"),
		-- standard pressure mode
		vbe_std = globalPropertyi("tu154/custom/gauges/alt/vbe_std_right"),
		-- indicated altitude in meters
		alt_mtr = globalPropertyf("tu154/custom/gauges/alt/vbe_alt_right"),
		-- flight level
		vbe_flightlevel = globalPropertyf("tu154/custom/gauges/alt/vbe_flightlevel_right"),
		--
		fail = globalPropertyi("sim/operation/failures/rel_cop_alt"),
	},
	rv5 {},
	rv5 {
		-- altitude, measured by gauge
		altitude = globalPropertyf("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_copilot"),
		-- DH angle
		dh_set = globalPropertyf("tu154/custom/gauges/alt/radioalt_dh_right"),
		-- test button
		test_btn = globalPropertyi("tu154/custom/gauges/alt/radioalt_button_right"),
		-- power switch
		rv_on = globalPropertyi("tu154/custom/switchers/ovhd/rv5_2_on"),
		bus27_volt = globalPropertyf("tu154/custom/elec/bus27_volt_right"),
		bus115_volt = globalPropertyf("tu154/custom/elec/bus115_3_volt"),
		-- RV needle
		rv_angle = globalPropertyf("tu154/custom/gauges/alt/radioalt_needle_right"),
		-- RV flag
		rv_flag = globalPropertyf("tu154/custom/gauges/alt/radioalt_flag_right"),
		-- RV lamp
		rv_lamp = globalPropertyf("tu154/custom/lights/small/rv5_right_dh"),
		rv5_dh_signal = globalPropertyi("tu154/custom/misc/rv5_dh_signal_right"),
		-- RV current
		rv_ = globalPropertyf("tu154/custom/elec/rv5_right_cc"),
		-- altitude on the right radio altimeter
		rv5_alt = globalPropertyf("tu154/custom/misc/rv5_alt_right"),
		-- fail
		rv_fail = globalPropertyi("tu154/custom/failures/rv2_fail"),
	},
	-- MSRP clock
	msrp_clock {
		position = {12, 762, 195, 84},
	},
	-- door and hatch indicators
	door_panel {},
	tcas {
		position = {0, 0, 2048, 2048},
	},
	taws {
		position = {1034, 1270, 1000, 770},
	},
	tks {},
	-- captain PNP
	pnp {},
	-- copilot PNP
	pnp {
		-- right
		gauge_num = 1,
		-- GA course
		course_ga = globalPropertyf("tu154/custom/tks/course_ga_2"),
		-- BGMK course
		course_bgmk = globalPropertyf("tu154/custom/tks/course_bgmk_2"),
		-- failure flag
		gyro_fail = globalPropertyi("tu154/custom/tks/fail_right"),
		-- set the course
		obs = globalPropertyf("tu154/custom/gauges/compas/pkp_obs_set_R"),
		-- set the course
		obs_side = globalPropertyf("tu154/custom/gauges/compas/pkp_obs_set_L"),
		-- controls
		-- PNP course mode: 0 = GMK, 1 = GPK
		pnp_mode = globalPropertyi("tu154/custom/switchers/ovhd/curs_pnp_mode_2"),
		-- course-setting knob
		pkp_obs_knob = globalPropertyf("tu154/custom/gauges/compas/pkp_obs_knob_R"),
		-- results
		-- PKP gyro course
		pkp_gyro_course = globalPropertyf("tu154/custom/gauges/compas/pkp_gyro_course_R"),
		-- PKP selected course
		pkp_obs = globalPropertyf("tu154/custom/gauges/compas/pkp_obs_R"),
		-- PKP helper-course yellow needle setting
		pkp_helper_course = globalPropertyf("tu154/custom/gauges/compas/pkp_helper_course_R"),
		-- PKP drift angle
		pkp_slip_angle = globalPropertyf("tu154/custom/gauges/compas/pkp_slip_angle_R"),
		-- PKP course deviation bar, positive to the right
		pkp_course_plank = globalPropertyf("tu154/custom/gauges/compas/pkp_course_plank_R"),
		-- PKP glideslope deviation bar, positive up
		pkp_gs_plank = globalPropertyf("tu154/custom/gauges/compas/pkp_gs_plank_R"),
		-- glideslope deviation failure flag
		pkp_gs_flag = globalPropertyi("tu154/custom/gauges/compas/pkp_gs_flag_R"),
		-- course deviation failure flag
		pkp_course_flag = globalPropertyi("tu154/custom/gauges/compas/pkp_course_flag_R"),
		-- course failure flag
		pkp_main_flag = globalPropertyi("tu154/custom/gauges/compas/pkp_main_flag_R"),
		-- course counter failure flag
		pkp_obs_flag = globalPropertyi("tu154/custom/gauges/compas/pkp_obs_flag_R"),
		-- course counter: units
		pkp_obs_one = globalPropertyf("tu154/custom/gauges/compas/pkp_obs_one_R"),
		-- course counter: tens
		pkp_obs_ten = globalPropertyf("tu154/custom/gauges/compas/pkp_obs_ten_R"),
		-- course counter: hundreds
		pkp_obs_hundr = globalPropertyf("tu154/custom/gauges/compas/pkp_obs_hundr_R"),
		-- PNP indication mode: 0 = off, 1 = NVU, 2 = VOR1, 3 = VOR2, 4 = landing mode
		absu_pnp_mode = globalPropertyi("tu154/custom/absu/absu_pnp_mode_2"),
		-- PNP indication mode: 0 = off, 1 = NVU, 2 = VOR1, 3 = VOR2, 4 = landing mode
		absu_pnp_mode_2 = globalPropertyi("tu154/custom/absu/absu_pnp_mode_1"),
		pnp_sp_lamp = globalPropertyf("tu154/custom/lights/small/pnp_sp_right"),
		pnp_vor_lamp = globalPropertyf("tu154/custom/lights/small/pnp_vor_right"),
		pnp_nv_lamp = globalPropertyf("tu154/custom/lights/small/pnp_nv_right"),
		bus27_volt = globalPropertyf("tu154/custom/elec/bus27_volt_left"),
		bus36_volt = globalPropertyf("tu154/custom/elec/bus36_volt_right"),
		fail_ga = globalPropertyf("sim/operation/failures/rel_cop_dgy"),
		tks_on = globalPropertyi("tu154/custom/switchers/ovhd/tks_on_2"), 
	}, 
	-- captain radio compass
	rmi {},
	rmi {
		-- sources
		-- BGMK course
		course_bgmk = globalPropertyf("tu154/custom/tks/course_bgmk_1"),
		-- power
		-- 36 V bus voltage
		bus36_volt = globalPropertyf("tu154/custom/elec/bus36_volt_pts250_2"),
		-- results
		-- radio compass course scale
		radiocomp_scale = globalPropertyf("tu154/custom/gauges/compas/radiocomp_scale_right"),
		-- radio compass bearing needle 1
		bearing_1 = globalPropertyf("tu154/custom/gauges/compas/bearing_1_right"),
		-- radio compass bearing needle 2
		bearing_2 = globalPropertyf("tu154/custom/gauges/compas/bearing_2_right"),
		-- radio compass needle 1 source: 0 = none, 1 = ARK1, 2 = ARK2, 3 = VOR1, 4 = VOR2, 5 = RSBN
		source_1_switch = globalPropertyi("tu154/custom/gauges/compas/source_1_switch_right"),
		-- radio compass needle 2 source
		source_2_switch = globalPropertyi("tu154/custom/gauges/compas/source_2_switch_right"),
	},
	-- Doppler system
	diss {},
	-- true and ground speed
	usvp {},
	-- short-range radio navigation system
	rsbn {},
	-- radio panel
	radio {
		position = {0, 0, 2048, 2048},
	},
	-- navigation calculator
	nvu {},
	-- autopilot
	absu {},
	-- various lamps
	misc_lamps {},
	radar {
		position = {0, 0, 2048, 2048},
	},
	vent {},
	water_panel {},
	gns430 {},
	misc_fails {},
}

