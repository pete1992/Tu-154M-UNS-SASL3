-- course_mp.lua
-- CourseMP VOR/DME panel and navigation logic.

size = {420, 90}

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"frequency", "sim/cockpit2/radios/actuators/nav1_frequency_hz", globalPropertyf},
    {"v_plank", "sim/cockpit2/radios/indicators/nav1_hdef_dots_pilot", globalPropertyf},
    {"h_plank", "sim/cockpit2/radios/indicators/nav1_vdef_dots_pilot", globalPropertyf},
    {"cr_flag", "sim/cockpit2/radios/indicators/nav1_flag_from_to_pilot", globalPropertyf},
    {"gs_flag", "sim/cockpit/radios/nav1_CDI", globalPropertyf},
    {"nav_deg", "sim/cockpit2/radios/indicators/nav1_relative_bearing_deg", globalPropertyf},
    {"sim_fail", "sim/operation/failures/rel_nav1", globalPropertyi},
    {"nav_fail", "tu154/custom/failures/nav1_fail", globalPropertyi},
    {"dme_fail", "tu154/custom/failures/dme1_fail", globalPropertyi},
    {"distance", "sim/cockpit2/radios/indicators/nav1_dme_distance_nm", globalPropertyf},
    {"obs", "sim/cockpit2/radios/actuators/nav1_obs_deg_mag_pilot", globalPropertyf},
    {"sd75_on", "tu154/custom/switchers/ovhd/sd75_1_on", globalPropertyi},
    {"curs_np_on", "tu154/custom/switchers/ovhd/curs_np_on_1", globalPropertyi},
    {"nav_mode", "tu154/custom/switchers/nav_1_mode", globalPropertyi},
    {"nav_man_auto", "tu154/custom/switchers/nav_1_man_auto", globalPropertyi},
    {"nav_mile_km", "tu154/custom/switchers/nav_1_mile_km", globalPropertyi},
    {"nav_left", "tu154/custom/rotary/ovhd/nav_1_left", globalPropertyi},
    {"nav_right", "tu154/custom/rotary/ovhd/nav_1_right", globalPropertyi},
    {"nav_but_1", "tu154/custom/buttons/ovhd/nav_1_but_1", globalPropertyi},
    {"nav_but_2", "tu154/custom/buttons/ovhd/nav_1_but_2", globalPropertyi},
    {"nav_but_3", "tu154/custom/buttons/ovhd/nav_1_but_3", globalPropertyi},
    {"nav_course", "tu154/custom/rotary/console/nav_1_course", globalPropertyi},
    {"test_lamps", "tu154/custom/buttons/lamp_test_front", globalPropertyi},
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
    {"bus36_volt", "tu154/custom/elec/bus36_volt_pts250_2", globalPropertyf},
    {"bus115_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf},
    {"nav_pow_cc", "tu154/custom/radio/nav1_pow_cc", globalPropertyf},
    {"vor_dme", "tu154/custom/radio/vor_dme_1", globalPropertyf},
    {"vor_bear", "tu154/custom/radio/vor_bear_1", globalPropertyf},
    {"nav_cs", "tu154/custom/radio/nav1_cs", globalPropertyf},
    {"nav_gs", "tu154/custom/radio/nav1_gs", globalPropertyf},
    {"nav_cs_flag", "tu154/custom/radio/nav1_cs_flag", globalPropertyi},
    {"nav_gs_flag", "tu154/custom/radio/nav1_gs_flag", globalPropertyi},
    {"nav_course_1", "tu154/custom/rotary/console/nav_1_course_1", globalPropertyf},
    {"nav_course_10", "tu154/custom/rotary/console/nav_1_course_10", globalPropertyf},
    {"nav_course_100", "tu154/custom/rotary/console/nav_1_course_100", globalPropertyf},
    {"nav_to_lit", "tu154/custom/lights/small/nav_1_to", globalPropertyf},
    {"nav_from_lit", "tu154/custom/lights/small/nav_1_from", globalPropertyf},
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

local rot_small_sound = sasl.al.loadSample('Custom Sounds/cursmp.wav')
local button_sound = sasl.al.loadSample('Custom Sounds/plastic_btn.wav')
local switcher_sound = sasl.al.loadSample('Custom Sounds/plastic_switch.wav')
local text_font = sasl.gl.loadFont("digibold.ttf")
sasl.gl.setFontGlyphSpacingFactor(text_font, 1.5)
local FONT_SIZE = 58
local TEXT_X = 87
local TEXT_Y = 32
local TEXT_COLOR = {1, 0.3, 0.2, 1}
sasl.al.setSampleGain(rot_small_sound, 700)

local rot_summ_last = 0

local function rotary()
	local nav_left_sw = get(nav_left)
	local nav_right_sw = get(nav_right)
	
	local summ = nav_left_sw + nav_right_sw
	
	if summ ~= rot_summ_last then sasl.al.playSample(rot_small_sound, false) end

	rot_summ_last = summ

end

local but_summ_last = 0

local function buttons()
	local nav_but_1_sw = get(nav_but_1)
	local nav_but_2_sw = get(nav_but_2)
	local nav_but_3_sw = get(nav_but_3)
	
	local summ = nav_but_1_sw + nav_but_2_sw + nav_but_3_sw
	
	if summ ~= but_summ_last then sasl.al.playSample(button_sound, false) end
	
	but_summ_last = summ
	
end

local sw_summ_last = 0

local function switchers()
	local nav_mode_sw = get(nav_mode)
	local nav_man_auto_sw = get(nav_man_auto)
	local nav_mile_km_sw = get(nav_mile_km)
	
	local summ = nav_mode_sw + nav_man_auto_sw + nav_mile_km_sw
	
	if summ ~= sw_summ_last then sasl.al.playSample(switcher_sound, false) end
	
	sw_summ_last = summ

end

local function lamps(flag)
	
	local test_btn = get(test_lamps) * math.max((get(bus27_volt_right) - 10) / 18.5, 0)
	--local day_night = 1 - get(day_night_set) * 0.25
	local lamps_brt = math.max((math.max(get(bus27_volt_left), get(bus27_volt_right)) - 10) / 18.5, 0)

	local nav_to_lit_brt = math.max(bool2int(flag == 1) * lamps_brt, test_btn)
	set(nav_to_lit, nav_to_lit_brt)
	
	local nav_from_lit_brt = math.max(bool2int(flag == 2) * lamps_brt, test_btn)
	set(nav_from_lit, nav_from_lit_brt)
	
end



-- variables for separate manipulations

local freq_100 = 0  -- digits before period
local freq_10 = 0  -- digits after period

local freq_show = ""

local power = false

local knob_last_L = get(nav_left)
local knob_last_R = get(nav_right)

local dist_now = 0
local dist_show = 0

local bearing = math.random(-180, 180)
local dir_ran = 1

local course = 0 --get(v_plank)
local glidesl = 0 --get(h_plank)

local obs_knob_last = 0
local obs_now = get(obs)

function update()
	
	set(sim_fail, 0)
	
	rotary()
	buttons()
	switchers()
	
	local MASTER = get(ismaster) ~= 1	
	
	local passed = get(frame_time)
	
	local FAIL = get(nav_fail) == 1
	
	local freq = get(frequency)
	power = get(curs_np_on) == 1 and get(bus36_volt) > 30 and get(bus115_volt) > 110 
	
	set(nav_pow_cc, bool2int(power))
	
	-- Split NAV frequency into MHz and 0.01 MHz units.
	freq_100 = math.floor(freq / 100)
	freq_10 = freq - freq_100 * 100
	freq_show = string.format("%d.%03d", freq_100, math.floor(freq_10 * 10 + 0.5))
	
	-- knobs cycle
	local left_knob = get(nav_left)
	local right_knob = get(nav_right)
	
	while left_knob > 26 do
		left_knob = left_knob - 36
	end
	
	while left_knob < -10 do
		left_knob = left_knob + 36
	end
	
	while right_knob > 26 do
		right_knob = right_knob - 36
	end
	
	while right_knob < -10 do
		right_knob = right_knob + 36
	end
	
	set(nav_left, left_knob)
	set(nav_right, right_knob)
	
if MASTER then
	
	-- change frequency
	if power then
		local knob_diff_L = left_knob - knob_last_L
		local knob_diff_R = right_knob - knob_last_R
		
		if math.abs(knob_diff_L) < 10 then
			freq_100 = freq_100 + knob_diff_L
		end
			
		if math.abs(knob_diff_R) < 5 then
			freq_10 = freq_10 + 5 * knob_diff_R
		end
	
	end
	
	if freq_100 > 117 then freq_100 = 108
	elseif freq_100 < 108 then freq_100 = 117 end
	
	if freq_10 > 95 then freq_10 = 0
	elseif freq_10 < 0 then freq_10 = 95 end
	
	set(frequency, freq_100 * 100 + freq_10)

end	
	
	knob_last_L = left_knob
	knob_last_R = right_knob
	
	-- DME calculations
	
	local dist = get(distance)

if MASTER then
	
	local delta_dist = dist - dist_now 
			
	if delta_dist > 1 then dist_now = dist_now + passed * 20
	elseif delta_dist < -1 then dist_now = dist_now - passed * 20
	else dist_now = dist_now + delta_dist * passed * 20
	end
	
	if get(nav_mile_km) == 1 then dist_show = dist_now * 1.852 
	else dist_show = dist_now
	end
	
	local dme_power = get(bus36_volt) > 30 and get(bus115_volt) > 110 and get(sd75_on) == 1 and get(dme_fail) == 0
	if not dme_power then dist_show = 0 end
	
	if dist_show > 999.9 then dist_show = 999.9
	elseif dist_show < 0 then dist_show = 0 end
	
	set(vor_dme, dist_show)
end	
	
	-- bearing calculations
	local bear = get(nav_deg)
	
	if (bear > 90.01 or bear < 89.99) and power and not FAIL then -- valid bearing
		bearing = bear + (math.random() - 0.49999) * 30 * passed

	elseif power and not FAIL then -- no signal
		bearing = bearing + (math.random() - 0.2) * 30 * passed * (dir_ran * 2 - 1)
	end	
	
	-- change dirrection of random movement
	if math.random() > 0.99 then dir_ran = (1 - dir_ran) end
	
	if MASTER then set(vor_bear, bearing) end
	
	-- flags calculations
	local nav_flag = get(cr_flag) * bool2int(power)  -- Nav-To-From indication, nav1, pilot, 0 is flag, 1 is to, 2 is from.
	local glide_flag = get(gs_flag) * bool2int(power)  -- glideslope flag. 0 - flag is shown
	
	-- set lamps To and From
	lamps(nav_flag)
	
	-- set course and glide planks
	if power and not FAIL then 
		course = get(v_plank) / 2.5
		glidesl = get(h_plank) / 2.5
	else
		course = 0
		glidesl = 0
	end

	-- add random noise deflection for planks
	if nav_flag == 0 and power and not FAIL and math.random() > 0.999 then 
		course = (math.random() - 0.49999) * 10
		nav_flag = math.random(1, 2)
	end	
	if glide_flag == 0 and power and not FAIL and math.random() > 0.999 then 
		glidesl = (math.random() - 0.49999) * 10
		glide_flag = 1
	end	
	
	-- add test buttons
	local but = get(nav_but_1) + get(nav_but_2) * 2 + get(nav_but_3) * 3
	if power and not FAIL then
		if but == 1 then
			course = -1
			glidesl = -1
		elseif but == 2 then
			course = 0
			glidesl = 0	
		elseif but == 3 then
			course = 1
			glidesl = 1
		end
	end	

if MASTER then	
	set(nav_cs, course)
	set(nav_gs, glidesl)
	
	set(nav_cs_flag, bool2int(nav_flag == 0 or not power or FAIL))
	set(nav_gs_flag, bool2int(glide_flag == 0 or not power or FAIL))
end	
	
	-- set OBS
	local obs_knob_now = get(nav_course)
	
	while obs_knob_now > 360 do
		obs_knob_now = obs_knob_now - 360
	end
	
	while obs_knob_now < 0 do
		obs_knob_now = obs_knob_now + 360
	end
	
	if MASTER then set(nav_course, obs_knob_now) end
	
	local knob_diff = obs_knob_now - obs_knob_last
	
	obs_knob_last = obs_knob_now
	
	obs_now = get(obs)

if MASTER then	
	
	if math.abs(knob_diff) < 50 then
		obs_now = obs_now + knob_diff
	end
	
	while obs_now > 360 do
		obs_now = obs_now - 360
	end
	
	while obs_now < 1 do
		obs_now = obs_now + 360
	end
	
	obs_now = math.floor(obs_now)
	
	set(obs, obs_now)

end
	
	-- Set OBS display digits.
	local obs_1 = math.floor(obs_now % 10)
	local obs_10 = math.floor((obs_now % 100) * 0.1)
	local obs_100 = math.floor((obs_now % 1000) * 0.01)
	
	set(nav_course_100, obs_100)
	set(nav_course_10, obs_10)
	set(nav_course_1, obs_1)	


end

function draw()
    if not power then
        return
    end

    sasl.gl.drawText(
        text_font,
        TEXT_X,
        TEXT_Y,
        freq_show,
        FONT_SIZE,
        false,
        false,
        TEXT_ALIGN_LEFT,
        TEXT_COLOR
    )
end
