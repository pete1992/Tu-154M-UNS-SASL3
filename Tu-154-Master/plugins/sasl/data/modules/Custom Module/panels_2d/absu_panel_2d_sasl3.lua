-- absu_panel_2d.lua
-- ABSU 2D control panel.

size = {917, 597}

defineProperty("hide_eng_objects", globalPropertyi("tu154/custom/lang/hide_eng_objects")) -- Hide English cockpit objects

-- time
defineProperty("frame_time", globalPropertyf("tu154/custom/time/frame_time")) -- Time between frames. When rewinding, does not take negative values. If FPS is less than 10, sets frame time = 0.1

defineProperty("show_absu_panel",globalPropertyi("tu154/custom/panels/show_absu_panel")) -- Show ABSU panel
-- gauges
defineProperty("absu_roll_mode", globalPropertyi("tu154/custom/gauges/console/absu_roll_mode")) -- ABSU roll mode. 0 - off, 1 - yoke, 2 - stab
defineProperty("absu_pitch_mode", globalPropertyi("tu154/custom/gauges/console/absu_pitch_mode")) -- ABSU pitch mode. 0 - off, 1 - yoke, 2 - stab

-- controls
defineProperty("absu_zpu_sel", globalPropertyi("tu154/custom/switchers/console/absu_zpu_sel")) -- ZPU selector. left - right
defineProperty("absu_nav_on", globalPropertyi("tu154/custom/switchers/console/absu_nav_on")) -- Navigation needles
defineProperty("absu_landing_on", globalPropertyi("tu154/custom/switchers/console/absu_landing_on")) -- Landing needles
defineProperty("absu_needles_on", globalPropertyi("tu154/custom/switchers/console/absu_needles_on")) -- Needles
defineProperty("absu_speed_mode", globalPropertyi("tu154/custom/switchers/console/absu_speed_mode")) -- STU mode. 0 - off, 1 - nvu, 2 - az1, 3 - az2, 4 - app
defineProperty("absu_speed_change", globalPropertyi("tu154/custom/switchers/console/absu_speed_change")) -- Speed change knob
defineProperty("absu_speed_off", globalPropertyi("tu154/custom/switchers/console/absu_speed_off")) -- Disable 1 and 2
defineProperty("absu_speed_prepare", globalPropertyi("tu154/custom/switchers/console/absu_speed_prepare")) -- Preparation
defineProperty("absu_speed_us_right_left", globalPropertyi("tu154/custom/switchers/console/absu_speed_us_right_left")) -- Preparation

defineProperty("absu_roll_ch_on", globalPropertyi("tu154/custom/switchers/console/absu_roll_ch_on")) -- Roll channel switch
defineProperty("absu_pitch_ch_on", globalPropertyi("tu154/custom/switchers/console/absu_pitch_ch_on")) -- Pitch channel switch
defineProperty("absu_smooth_on", globalPropertyi("tu154/custom/switchers/console/absu_smooth_on")) -- "Turbulence" switch

defineProperty("absu_turn_handle", globalPropertyi("tu154/custom/switchers/console/absu_turn_handle")) -- Turn handle
defineProperty("absu_pitch_wheel", globalPropertyf("tu154/custom/switchers/console/absu_pitch_wheel")) -- Descent/ascent wheel
defineProperty("absu_pitch_wheel_dir", globalPropertyi("tu154/custom/switchers/console/absu_pitch_wheel_dir")) -- Descent/ascent wheel direction

-- buttons
defineProperty("absu_zk", globalPropertyi("tu154/custom/buttons/console/absu_zk")) -- ZK button on ABSU panel
defineProperty("absu_reset", globalPropertyi("tu154/custom/buttons/console/absu_reset")) -- Program reset button on ABSU panel
defineProperty("absu_nvu", globalPropertyi("tu154/custom/buttons/console/absu_nvu")) -- NVU button on ABSU panel
defineProperty("absu_az1", globalPropertyi("tu154/custom/buttons/console/absu_az1")) -- AZ 1 button on ABSU panel
defineProperty("absu_az2", globalPropertyi("tu154/custom/buttons/console/absu_az2")) -- AZ 2 button on ABSU panel
defineProperty("absu_app", globalPropertyi("tu154/custom/buttons/console/absu_app")) -- Approach button on ABSU panel
defineProperty("absu_gs", globalPropertyi("tu154/custom/buttons/console/absu_gs")) -- Glideslope button on ABSU panel
defineProperty("absu_stab_m", globalPropertyi("tu154/custom/buttons/console/absu_stab_m")) -- M button on ABSU panel
defineProperty("absu_stab_v", globalPropertyi("tu154/custom/buttons/console/absu_stab_v")) -- V button on ABSU panel
defineProperty("absu_stab_h", globalPropertyi("tu154/custom/buttons/console/absu_stab_h")) -- H button on ABSU panel
defineProperty("absu_stab", globalPropertyi("tu154/custom/buttons/console/absu_stab")) -- STAB button on ABSU panel

defineProperty("absu_arrest", globalPropertyi("tu154/custom/buttons/console/absu_arrest")) -- Arresting buttons
defineProperty("absu_speed_test_1", globalPropertyi("tu154/custom/buttons/console/absu_speed_test_1")) -- STU test button lower
defineProperty("absu_speed_test_2", globalPropertyi("tu154/custom/buttons/console/absu_speed_test_2")) -- STU test button upper

defineProperty("absu_stab_speed", globalPropertyi("tu154/custom/buttons/console/absu_stab_speed")) -- C button on ABSU panel
defineProperty("absu_throt_off_1", globalPropertyi("tu154/custom/buttons/console/absu_throt_off_1")) -- Throttle 1 off button on ABSU panel
defineProperty("absu_throt_off_2", globalPropertyi("tu154/custom/buttons/console/absu_throt_off_2")) -- Throttle 2 off button on ABSU panel
defineProperty("absu_throt_off_3", globalPropertyi("tu154/custom/buttons/console/absu_throt_off_3")) -- Throttle 3 off button on ABSU panel

-- caps
defineProperty("absu_arrest_cap", globalPropertyi("tu154/custom/buttons/console/absu_arrest_cap")) -- Arresting buttons cover
defineProperty("absu_smooth_on_cap", globalPropertyi("tu154/custom/switchers/console/absu_smooth_on_cap")) -- "Turbulence" switch
defineProperty("absu_speed_prepare_cap", globalPropertyi("tu154/custom/switchers/console/absu_speed_prepare_cap")) -- Preparation
defineProperty("absu_speed_off_cap", globalPropertyi("tu154/custom/switchers/console/absu_speed_off_cap")) -- Disable 1 and 2

-- lamps
defineProperty("absu_zk_lamp", globalPropertyf("tu154/custom/lights/button/absu_zk")) -- ABSU ZK
defineProperty("absu_reset_lamp", globalPropertyf("tu154/custom/lights/button/absu_reset")) -- ABSU reset
defineProperty("absu_nvu_lamp", globalPropertyf("tu154/custom/lights/button/absu_nvu")) -- ABSU NVU
defineProperty("absu_az1_lamp", globalPropertyf("tu154/custom/lights/button/absu_az1")) -- ABSU AZ1
defineProperty("absu_az2_lamp", globalPropertyf("tu154/custom/lights/button/absu_az2")) -- ABSU AZ2
defineProperty("absu_app_lamp", globalPropertyf("tu154/custom/lights/button/absu_app")) -- ABSU approach
defineProperty("absu_gz_lamp", globalPropertyf("tu154/custom/lights/button/absu_gz")) -- ABSU glideslope
defineProperty("absu_stab_m_lamp", globalPropertyf("tu154/custom/lights/button/absu_stab_m")) -- ABSU stab M
defineProperty("absu_stab_v_lamp", globalPropertyf("tu154/custom/lights/button/absu_stab_v")) -- ABSU stab V
defineProperty("absu_stab_h_lamp", globalPropertyf("tu154/custom/lights/button/absu_stab_h")) -- ABSU stab H
defineProperty("absu_stab_lamp", globalPropertyf("tu154/custom/lights/button/absu_stab")) -- ABSU stab H
defineProperty("absu_stab_spd_lamp", globalPropertyf("tu154/custom/lights/button/absu_stab_spd")) -- ABSU speed stabilization
defineProperty("absu_thro1_lamp", globalPropertyf("tu154/custom/lights/button/absu_thro1")) -- ABSU throttle 1 off
defineProperty("absu_thro2_lamp", globalPropertyf("tu154/custom/lights/button/absu_thro2")) -- ABSU throttle 2 off
defineProperty("absu_thro3_lamp", globalPropertyf("tu154/custom/lights/button/absu_thro3")) -- ABSU throttle 3 off

defineProperty("stu_roll_lamp", globalPropertyf("tu154/custom/lights/small/stu_roll")) -- STU lateral
defineProperty("stu_pitch_lamp", globalPropertyf("tu154/custom/lights/small/stu_pitch")) -- STU longitudinal
defineProperty("stu_toga_lamp", globalPropertyf("tu154/custom/lights/small/stu_toga")) -- GO-AROUND

defineProperty("at_1_lamp", globalPropertyf("tu154/custom/lights/small/at_1")) -- AT 1
defineProperty("at_2_lamp", globalPropertyf("tu154/custom/lights/small/at_2")) -- AT 2

-- English texture resources
local bg_img = loadImage("absu_bk.png")

local contr_off_img = loadImage("absu_ess.png", 6, 342, 85, 69)
local contr_stab_img = loadImage("absu_ess.png", 6, 412, 85, 69)

local reset_lamp_img = loadImage("absu_ess.png", 359, 160, 54, 54)
local zk_lamp_img = loadImage("absu_ess.png", 243, 160, 54, 54)
local nvu_lamp_img = loadImage("absu_ess.png", 243, 217, 54, 54)
local az1_lamp_img = loadImage("absu_ess.png", 301, 217, 54, 54)
local az2_lamp_img = loadImage("absu_ess.png", 360, 217, 54, 54)
local app_lamp_img = loadImage("absu_ess.png", 243, 273, 54, 54)
local gs_lamp_img = loadImage("absu_ess.png", 360, 273, 54, 54)
local m_lamp_img = loadImage("absu_ess.png", 243, 330, 54, 54)
local v_lamp_img = loadImage("absu_ess.png", 302, 330, 54, 54)
local h_lamp_img = loadImage("absu_ess.png", 361, 330, 54, 54)
local stab_lamp_img = loadImage("absu_ess.png", 302, 273, 54, 54)
local off_1_lamp_img = loadImage("absu_ess.png", 243, 388, 54, 54)
local off_2_lamp_img = loadImage("absu_ess.png", 303, 388, 54, 54)
local off_3_lamp_img = loadImage("absu_ess.png", 361, 388, 54, 54)

local sw_dn_img = loadImage("absu_ess.png", 86, 7, 32, 110)
local sw_up_img = loadImage("absu_ess.png", 125, 7, 32, 110)
local sw_ctr_img = loadImage("absu_ess.png", 165, 88, 36, 36)

local switcher_big = loadImage("absu_ess.png", 0, 0, 78, 124)
local roll_knob = loadImage("absu_ess.png", 2, 132, 196, 196)

local spd_hnd = loadImage("absu_ess.png", 445, 13, 52, 114)
local wheel_img = loadImage("absu_ess.png", 212, 0, 21, 512)

local arrest_cap_closed = loadImage("absu_ess.png", 244, 11, 55, 92)
local arrest_cap_open = loadImage("absu_ess.png", 243, 115, 55, 37)

local smooth_cap_closed = loadImage("absu_ess.png", 315, 14, 47, 89)
local smooth_cap_open = loadImage("absu_ess.png", 314, 115, 48, 37)

local black_cap_closed = loadImage("absu_ess.png", 374, 14, 56, 86)
local black_cap_open = loadImage("absu_ess.png", 374, 114, 56, 37)

local small_lamp = loadImage("absu_ess.png", 167, 9, 31, 31)

-- Russian texture resources
local bg_img_RUS = loadImage("absu_bk_RUS.png")

local contr_off_img_RUS = loadImage("absu_ess_RUS.png", 6, 342, 85, 69)
local contr_stab_img_RUS = loadImage("absu_ess_RUS.png", 6, 412, 85, 69)

local reset_lamp_img_RUS = loadImage("absu_ess_RUS.png", 359, 160, 54, 54)
local zk_lamp_img_RUS = loadImage("absu_ess_RUS.png", 243, 160, 54, 54)
local nvu_lamp_img_RUS = loadImage("absu_ess_RUS.png", 243, 217, 54, 54)
local az1_lamp_img_RUS = loadImage("absu_ess_RUS.png", 301, 217, 54, 54)
local az2_lamp_img_RUS = loadImage("absu_ess_RUS.png", 360, 217, 54, 54)
local app_lamp_img_RUS = loadImage("absu_ess_RUS.png", 243, 273, 54, 54)
local gs_lamp_img_RUS = loadImage("absu_ess_RUS.png", 360, 273, 54, 54)
local stab_lamp_img_RUS = loadImage("absu_ess_RUS.png", 302, 273, 54, 54)
local off_1_lamp_img_RUS = loadImage("absu_ess_RUS.png", 243, 388, 54, 54)
local off_2_lamp_img_RUS = loadImage("absu_ess_RUS.png", 303, 388, 54, 54)
local off_3_lamp_img_RUS = loadImage("absu_ess_RUS.png", 361, 388, 54, 54)

local arrest_cap_closed_RUS = loadImage("absu_ess_RUS.png", 244, 11, 55, 92)

local RUS = true


-- Updates the language-dependent texture selection.
function update()
    RUS = get(hide_eng_objects) == 1
end

components = {

	-- background

	textureLit {
		position = {0, 0, size[1], size[2]},
		image = bg_img,
		visible = function()
			return not RUS
		end,
	},
	textureLit {
		position = {0, 0, size[1], size[2]},
		image = bg_img_RUS,
		visible = function()
			return RUS
		end,
	},

	----------------
	-- Gauges --
	----------------

	-- roll off
	textureLit {
		position = {327, 443, 83, 68},
		image = contr_off_img,
		visible = function()
			return get(absu_roll_mode) == 0 and not RUS
		end,
	},
	textureLit {
		position = {327, 443, 83, 68},
		image = contr_off_img_RUS,
		visible = function()
			return get(absu_roll_mode) == 0 and RUS
		end,
	},

	-- roll stab
	textureLit {
		position = {327, 443, 83, 68},
		image = contr_stab_img,
		visible = function()
			return get(absu_roll_mode) == 2 and not RUS
		end,
	},
	textureLit {
		position = {327, 443, 83, 68},
		image = contr_stab_img_RUS,
		visible = function()
			return get(absu_roll_mode) == 2 and RUS
		end,
	},

	-- pitch off
	textureLit {
		position = {512, 443, 83, 68},
		image = contr_off_img,
		visible = function()
			return get(absu_pitch_mode) == 0 and not RUS
		end,
	},
	textureLit {
		position = {512, 443, 83, 68},
		image = contr_off_img_RUS,
		visible = function()
			return get(absu_pitch_mode) == 0 and RUS
		end,
	},

	-- pitch stab
	textureLit {
		position = {512, 443, 83, 68},
		image = contr_stab_img,
		visible = function()
			return get(absu_pitch_mode) == 2 and not RUS
		end,
	},
	textureLit {
		position = {512, 443, 83, 68},
		image = contr_stab_img_RUS,
		visible = function()
			return get(absu_pitch_mode) == 2 and RUS
		end,
	},

	----------------
	-- Indicator lamps --
	----------------

	-- reset
	textureLit {
		position = {218, 471, 54, 54},
		image = reset_lamp_img,
		visible = function()
			return get(absu_reset_lamp) > 0.5 and not RUS
		end,
	},
	textureLit {
		position = {218, 471, 54, 54},
		image = reset_lamp_img_RUS,
		visible = function()
			return get(absu_reset_lamp) > 0.5 and RUS
		end,
	},

	-- ZK
	textureLit {
		position = {43, 471, 54, 54},
		image = zk_lamp_img,
		visible = function()
			return get(absu_zk_lamp) > 0.5 and not RUS
		end,
	},
	textureLit {
		position = {43, 471, 54, 54},
		image = zk_lamp_img_RUS,
		visible = function()
			return get(absu_zk_lamp) > 0.5 and RUS
		end,
	},

	-- NVU
	textureLit {
		position = {43, 382, 54, 54},
		image = nvu_lamp_img,
		visible = function()
			return get(absu_nvu_lamp) > 0.5 and not RUS
		end,
	},
	textureLit {
		position = {43, 382, 54, 54},
		image = nvu_lamp_img_RUS,
		visible = function()
			return get(absu_nvu_lamp) > 0.5 and RUS
		end,
	},

	-- AZ1
	textureLit {
		position = {130, 382, 54, 54},
		image = az1_lamp_img,
		visible = function()
			return get(absu_az1_lamp) > 0.5 and not RUS
		end,
	},
	textureLit {
		position = {130, 382, 54, 54},
		image = az1_lamp_img_RUS,
		visible = function()
			return get(absu_az1_lamp) > 0.5 and RUS
		end,
	},

	-- AZ2
	textureLit {
		position = {219, 382, 54, 54},
		image = az2_lamp_img,
		visible = function()
			return get(absu_az2_lamp) > 0.5 and not RUS
		end,
	},
	textureLit {
		position = {219, 382, 54, 54},
		image = az2_lamp_img_RUS,
		visible = function()
			return get(absu_az2_lamp) > 0.5 and RUS
		end,
	},

	-- APP
	textureLit {
		position = {43, 102, 54, 54},
		image = app_lamp_img,
		visible = function()
			return get(absu_app_lamp) > 0.5 and not RUS
		end,
	},
	textureLit {
		position = {43, 102, 54, 54},
		image = app_lamp_img_RUS,
		visible = function()
			return get(absu_app_lamp) > 0.5 and RUS
		end,
	},

	-- GS
	textureLit {
		position = {219, 102, 54, 54},
		image = gs_lamp_img,
		visible = function()
			return get(absu_gz_lamp) > 0.5 and not RUS
		end,
	},
	textureLit {
		position = {219, 102, 54, 54},
		image = gs_lamp_img_RUS,
		visible = function()
			return get(absu_gz_lamp) > 0.5 and RUS
		end,
	},

	-- M
	textureLit {
		position = {347, 326, 54, 54},
		image = m_lamp_img,
		visible = function()
			return get(absu_stab_m_lamp) > 0.5
		end,
	},

	-- V
	textureLit {
		position = {435, 326, 54, 54},
		image = v_lamp_img,
		visible = function()
			return get(absu_stab_v_lamp) > 0.5
		end,
	},

	-- H
	textureLit {
		position = {523, 326, 54, 54},
		image = h_lamp_img,
		visible = function()
			return get(absu_stab_h_lamp) > 0.5
		end,
	},

	-- STAB
	textureLit {
		position = {712, 321, 54, 54},
		image = stab_lamp_img,
		visible = function()
			return get(absu_stab_spd_lamp) > 0.5 and not RUS
		end,
	},
	textureLit {
		position = {712, 321, 54, 54},
		image = stab_lamp_img_RUS,
		visible = function()
			return get(absu_stab_spd_lamp) > 0.5 and RUS
		end,
	},

	-- 1 off
	textureLit {
		position = {659, 57, 54, 54},
		image = off_1_lamp_img,
		visible = function()
			return get(absu_thro1_lamp) > 0.5 and not RUS
		end,
	},
	textureLit {
		position = {659, 57, 54, 54},
		image = off_1_lamp_img_RUS,
		visible = function()
			return get(absu_thro1_lamp) > 0.5 and RUS
		end,
	},

	-- 2 off
	textureLit {
		position = {735, 57, 54, 54},
		image = off_2_lamp_img,
		visible = function()
			return get(absu_thro2_lamp) > 0.5 and not RUS
		end,
	},
	textureLit {
		position = {735, 57, 54, 54},
		image = off_2_lamp_img_RUS,
		visible = function()
			return get(absu_thro2_lamp) > 0.5 and RUS
		end,
	},

	-- 3 off
	textureLit {
		position = {809, 57, 54, 54},
		image = off_3_lamp_img,
		visible = function()
			return get(absu_thro3_lamp) > 0.5 and not RUS
		end,
	},
	textureLit {
		position = {809, 57, 54, 54},
		image = off_3_lamp_img_RUS,
		visible = function()
			return get(absu_thro3_lamp) > 0.5 and RUS
		end,
	},

	-- AT 1
	textureLit {
		position = {651, 188, 23, 23},
		image = small_lamp,
		visible = function()
			return get(at_1_lamp) > 0.5
		end,
	},

	-- AT 2
	textureLit {
		position = {651, 248, 23, 23},
		image = small_lamp,
		visible = function()
			return get(at_2_lamp) > 0.5
		end,
	},

	-- TOGA
	textureLit {
		position = {651, 374, 23, 23},
		image = small_lamp,
		visible = function()
			return get(stu_toga_lamp) > 0.5
		end,
	},

	-- PITCH
	textureLit {
		position = {651, 436, 23, 23},
		image = small_lamp,
		visible = function()
			return get(stu_pitch_lamp) > 0.5
		end,
	},

	-- ROLL
	textureLit {
		position = {651, 494, 23, 23},
		image = small_lamp,
		visible = function()
			return get(stu_roll_lamp) > 0.5
		end,
	},

	---------------------------
	-- Switches and rotary controls --
	---------------------------

	-- NAV on
	switch_lit {
		position = {54, 188, 32, 110},
		btnOn = sw_up_img,
		btnOff = sw_dn_img,
		state = function()
			return get(absu_nav_on) == 1
		end,
		onMouseHold = function()
			set(absu_nav_on, 1 - get(absu_nav_on))
			return true
		end,
	},

	-- LAND on
	switch_lit {
		position = {230, 188, 32, 110},
		btnOn = sw_up_img,
		btnOff = sw_dn_img,
		state = function()
			return get(absu_landing_on) == 1
		end,
		onMouseHold = function()
			set(absu_landing_on, 1 - get(absu_landing_on))
			return true
		end,
	},

	-- needles on
	switch_lit {
		position = {142, 81, 32, 110},
		btnOn = sw_up_img,
		btnOff = sw_dn_img,
		state = function()
			return get(absu_needles_on) == 1
		end,
		onMouseHold = function()
			set(absu_needles_on, 1 - get(absu_needles_on))
			return true
		end,
	},

	-- roll on
	switch_lit {
		position = {353, 11, 32, 110},
		btnOn = sw_up_img,
		btnOff = sw_dn_img,
		state = function()
			return get(absu_roll_ch_on) == 1
		end,
		onMouseHold = function()
			set(absu_roll_ch_on, 1 - get(absu_roll_ch_on))
			return true
		end,
	},

	-- pitch on
	switch_lit {
		position = {534, 11, 32, 110},
		btnOn = sw_up_img,
		btnOff = sw_dn_img,
		state = function()
			return get(absu_pitch_ch_on) == 1
		end,
		onMouseHold = function()
			set(absu_pitch_ch_on, 1 - get(absu_pitch_ch_on))
			return true
		end,
	},

	-- smooth on
	switch_lit {
		position = {445, 13, 28, 100},
		btnOn = sw_up_img,
		btnOff = sw_dn_img,
		state = function()
			return get(absu_smooth_on) == 1
		end,
		onMouseHold = function()
			set(absu_smooth_on, 1 - get(absu_smooth_on))
			return true
		end,
		visible = function()
			return get(absu_smooth_on_cap) == 1
		end,
	},

	-- prepare
	switch_lit {
		position = {782, 148, 28, 100},
		btnOn = sw_up_img,
		btnOff = sw_dn_img,
		state = function()
			return get(absu_speed_prepare) == 1
		end,
		onMouseHold = function()
			set(absu_speed_prepare, 1 - get(absu_speed_prepare))
			return true
		end,
		visible = function()
			return get(absu_speed_prepare_cap) == 1
		end,
	},

	-- US
	switch_lit {
		position = {842, 148, 28, 100},
		btnOn = sw_up_img,
		btnOff = sw_dn_img,
		state = function()
			return get(absu_speed_us_right_left) == 1
		end,
		onMouseHold = function()
			set(absu_speed_us_right_left, 1 - get(absu_speed_us_right_left))
			return true
		end,
	},

	-- off 1-2
	textureLit {
		position = {714, 148, 28, 100},
		image = sw_up_img,
		visible = function()
			return get(absu_speed_off) == 1 and get(absu_speed_off_cap) == 1
		end,
	},
	textureLit {
		position = {714, 148, 28, 100},
		image = sw_dn_img,
		visible = function()
			return get(absu_speed_off) == -1 and get(absu_speed_off_cap) == 1
		end,

	},
	textureLit {
		position = {714, 182, 28, 28},
		image = sw_ctr_img,
		visible = function()
			return get(absu_speed_off) == 0 and get(absu_speed_off_cap) == 1
		end,
	},

	interactive {
		position = {714, 148, 28, 50},

		onMouseHold = function()

			local a = get(absu_speed_off) - 1
			if a < -1 then a = 0 end
			set(absu_speed_off, a)

			return true
		end,
		visible = function()
			return get(absu_speed_off_cap) == 1
		end,
	},
	interactive {
		position = {714, 198, 28, 50},

		onMouseHold = function()

			local a = get(absu_speed_off) + 1
			if a > 1 then a = 0 end
			set(absu_speed_off, a)

			return true
		end,
		visible = function()
			return get(absu_speed_off_cap) == 1
		end,
	},

	-- ZK select
	needleLit {
		position = {115, 458, 85, 85},
		image = switcher_big,
		angle = function()
			return -15 + get(absu_zpu_sel) * 30

		end,
	},
	interactive {
		position = {115, 458, 85, 85},

		onMouseHold = function()
			set(absu_zpu_sel, 1 - get(absu_zpu_sel))

			return true
		end,
	},

	-- ROLL knob
	needleLit {
		position = {341, 157, 112, 112},
		image = roll_knob,
		angle = function()
			return get(absu_turn_handle) * 3

		end,
	},
	interactive {
		position = {341, 157, 50, 50},

		onMouseHold = function()
			local a = get(absu_turn_handle) - 5
			if a < -50 then a = -50 end
			set(absu_turn_handle, a)

			return true
		end,
	},
	interactive {
		position = {403, 157, 50, 50},

		onMouseHold = function()
			local a = get(absu_turn_handle) + 5
			if a > 50 then a = 50 end
			set(absu_turn_handle, a)

			return true
		end,
	},
	interactive {
		position = {372, 217, 50, 50},

		onMouseHold = function()
			set(absu_turn_handle, 0)

			return true
		end,
	},

	----------------------------
	-- Push buttons --
	---------------------------

	-- reset
	interactive {
		position = {211, 464, 68, 68},

		onMouseDown = function()
			set(absu_reset, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_reset, 0)
			return true
		end,
	},

	-- ZK
	interactive {
		position = {35, 464, 68, 68},

		onMouseDown = function()
			set(absu_zk, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_zk, 0)
			return true
		end,
	},

	-- NVU
	interactive {
		position = {35, 376, 68, 68},

		onMouseDown = function()
			set(absu_nvu, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_nvu, 0)
			return true
		end,
	},

	-- AZ1
	interactive {
		position = {123, 376, 68, 68},

		onMouseDown = function()
			set(absu_az1, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_az1, 0)
			return true
		end,
	},

	-- AZ2
	interactive {
		position = {211, 376, 68, 68},

		onMouseDown = function()
			set(absu_az2, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_az2, 0)
			return true
		end,
	},

	-- APP
	interactive {
		position = {35, 96, 68, 68},

		onMouseDown = function()
			set(absu_app, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_app, 0)
			return true
		end,
	},

	-- GS
	interactive {
		position = {211, 96, 68, 68},

		onMouseDown = function()
			set(absu_gs, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_gs, 0)
			return true
		end,
	},

	-- M
	interactive {
		position = {340, 319, 68, 68},

		onMouseDown = function()
			set(absu_stab_m, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_stab_m, 0)
			return true
		end,
	},

	-- V
	interactive {
		position = {428, 319, 68, 68},

		onMouseDown = function()
			set(absu_stab_v, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_stab_v, 0)
			return true
		end,
	},

	-- H
	interactive {
		position = {516, 319, 68, 68},

		onMouseDown = function()
			set(absu_stab_h, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_stab_h, 0)
			return true
		end,
	},

	-- STAB
	interactive {
		position = {460, 266, 50, 50},

		onMouseDown = function()
			set(absu_stab, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_stab, 0)
			return true
		end,
	},

	-- SPEED STAB
	interactive {
		position = {704, 315, 68, 68},

		onMouseDown = function()
			set(absu_stab_speed, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_stab_speed, 0)
			return true
		end,
	},

	-- thr1
	interactive {
		position = {653, 53, 68, 68},

		onMouseDown = function()
			set(absu_throt_off_1, 1 - get(absu_throt_off_1))
			return true
		end,
	},

	-- thr2
	interactive {
		position = {728, 53, 68, 68},

		onMouseDown = function()
			set(absu_throt_off_2, 1 - get(absu_throt_off_2))
			return true
		end,
	},

	-- thr3
	interactive {
		position = {803, 53, 68, 68},

		onMouseDown = function()
			set(absu_throt_off_3, 1 - get(absu_throt_off_3))
			return true
		end,
	},

	free_texture_lit {
		image = spd_hnd,
		position_x = 817,
		width = 30,
		height = 65,
		position_y = function()
			return 315 + get(absu_speed_change) * 7

		end,

	},

	-- SPEED UP
	interactive {
		position = {805, 355, 50, 50},

		onMouseDown = function()
			set(absu_speed_change, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_speed_change, 0)
			return true
		end,
	},
	-- SPEED DN
	interactive {
		position = {805, 297, 50, 50},

		onMouseDown = function()
			set(absu_speed_change, -1)
			return true
		end,
		onMouseUp = function()
			set(absu_speed_change, 0)
			return true
		end,
	},

	-- absu_speed_test_1
	interactive {
		position = {639, 120, 50, 50},

		onMouseDown = function()
			set(absu_speed_test_1, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_speed_test_1, 0)
			return true
		end,
	},

	-- absu_speed_test_2
	interactive {
		position = {639, 299, 50, 50},

		onMouseDown = function()
			set(absu_speed_test_2, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_speed_test_2, 0)
			return true
		end,
	},

	-- PNP mode
	needleLit {
		position = {783, 443, 80, 80},
		image = switcher_big,
		angle = function()
			return -70 + get(absu_speed_mode) * 27

		end,
	},

	interactive {
		position = {783, 443, 40, 80},

		onMouseHold = function()
			local a = get(absu_speed_mode) - 1
			if a < 0 then a = 0 end
			set(absu_speed_mode, a)
			return true
		end,
	},

	interactive {
		position = {823, 443, 40, 80},

		onMouseHold = function()
			local a = get(absu_speed_mode) + 1
			if a > 4 then a = 4 end
			set(absu_speed_mode, a)
			return true
		end,
	},

	-- pitch wheel
	tape_lit {
		image = wheel_img,
		position = {546, 165, 15, 100},
		window = {1.0, 0.3},
		scrollY = function()
			return 0.3 - get(absu_pitch_wheel) * 0.0165

		end,
	},

	interactive {
		position = {528, 150, 50, 60},

		onMouseDown = function()
			set(absu_pitch_wheel_dir, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_pitch_wheel_dir, 0)
			return true
		end,
	},

	interactive {
		position = {528, 220, 50, 60},

		onMouseDown = function()
			set(absu_pitch_wheel_dir, -1)
			return true
		end,
		onMouseUp = function()
			set(absu_pitch_wheel_dir, 0)
			return true
		end,
	},

	-- ARREST
	interactive {
		position = {437, 467, 40, 80},

		onMouseDown = function()
			set(absu_arrest, 1)
			return true
		end,
		onMouseUp = function()
			set(absu_arrest, 0)
			return true
		end,
		visible = function()
			return get(absu_arrest_cap) == 1
		end,
	},

	------------------------------
	-- Safety covers --
	---------------------

	-- Arrest buttons cover
	textureLit {
		position = {433, 463, 55, 92},
		image = arrest_cap_closed,
		visible = function()
			return get(absu_arrest_cap) == 0 and not RUS
		end,
	},
	textureLit {
		position = {433, 463, 55, 92},
		image = arrest_cap_closed_RUS,
		visible = function()
			return get(absu_arrest_cap) == 0 and RUS
		end,
	},

	textureLit {
		position = {433, 545, 55, 37},
		image = arrest_cap_open,
		visible = function()
			return get(absu_arrest_cap) == 1
		end,
	},

	interactive {
		position = {433, 545, 55, 37},

		onMouseDown = function()
			set(absu_arrest_cap, 1 - get(absu_arrest_cap))
			return true
		end,
	},

	--------------------------

	-- Arrest buttons cover
	textureLit {
		position = {431, 5, 58, 110},
		image = smooth_cap_closed,
		visible = function()
			return get(absu_smooth_on_cap) == 0
		end,
	},

	textureLit {
		position = {431, 102, 58, 40},
		image = smooth_cap_open,
		visible = function()
			return get(absu_smooth_on_cap) == 1
		end,
	},

	interactive {
		position = {429, 113, 62, 40},

		onMouseDown = function()
			set(absu_smooth_on_cap, 1 - get(absu_smooth_on_cap))
			return true
		end,
	},

	--------------------------

	-- Autothrottle OFF cover
	textureLit {
		position = {700, 150, 56, 100},
		image = black_cap_closed,
		visible = function()
			return get(absu_speed_off_cap) == 0
		end,
	},

	textureLit {
		position = {700, 230, 58, 40},
		image = black_cap_open,
		visible = function()
			return get(absu_speed_off_cap) == 1
		end,
	},

	interactive {
		position = {700, 240, 58, 40},

		onMouseDown = function()
			set(absu_speed_off_cap, 1 - get(absu_speed_off_cap))
			return true
		end,
	},

	--------------------------

	-- Autothrottle PREPARE cover
	textureLit {
		position = {770, 150, 56, 100},
		image = black_cap_closed,
		visible = function()
			return get(absu_speed_prepare_cap) == 0
		end,
	},

	textureLit {
		position = {770, 230, 58, 40},
		image = black_cap_open,
		visible = function()
			return get(absu_speed_prepare_cap) == 1
		end,
	},

	interactive {
		position = {770, 240, 58, 40},

		onMouseDown = function()
			set(absu_speed_prepare_cap, 1 - get(absu_speed_prepare_cap))
			return true
		end,
	},

	--------------------------------

	-- close button
	interactive {
		position = {size[1] - 30, size[2] - 30, 30, 30 },

		onMouseHold = function()
			set(show_absu_panel, 0)

			return true
		end,
	},

}

-- Draws all child components of the ABSU 2D panel.
function draw()
    drawAll(components)
end
