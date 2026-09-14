-- this is fire system panel
-- controls
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    { "lamp_test", "tu154/custom/buttons/lamp_test_fire_panel", globalPropertyi }, --      	0
    { "lamp_test_2", "tu154/custom/buttons/lamp_test_engines", globalPropertyi }, --      	0
    { "smoke_test", "tu154/custom/buttons/eng/smoke_test", globalPropertyi }, --
    { "ext_test", "tu154/custom/buttons/eng/ext_test", globalPropertyi }, --

    { "lamp_test_front", "tu154/custom/buttons/lamp_test_front", globalPropertyi }, --

    { "fire_ext_1", "tu154/custom/buttons/eng/fire_ext_1", globalPropertyi }, --
    { "fire_ext_2", "tu154/custom/buttons/eng/fire_ext_2", globalPropertyi }, --
    { "fire_ext_3", "tu154/custom/buttons/eng/fire_ext_3", globalPropertyi }, --
    { "cold_eng_1", "tu154/custom/buttons/eng/cold_eng_1", globalPropertyi }, --
    { "cold_eng_2", "tu154/custom/buttons/eng/cold_eng_2", globalPropertyi }, --
    { "cold_eng_3", "tu154/custom/buttons/eng/cold_eng_3", globalPropertyi }, --
    { "cold_apu", "tu154/custom/buttons/eng/cold_apu", globalPropertyi }, --
    { "neutral_gas", "tu154/custom/buttons/eng/neutral_gas", globalPropertyi }, --

    { "fire_sensor_sel", "tu154/custom/switchers/eng/fire_sensor_sel", globalPropertyi }, --
    { "fire_place_sel", "tu154/custom/switchers/eng/fire_place_sel", globalPropertyi }, --

    { "fire_main_switch", "tu154/custom/switchers/eng/fire_main_switch", globalPropertyi }, --
    { "fire_buzzer", "tu154/custom/switchers/eng/fire_buzzer", globalPropertyi }, --
    { "fire_buzzer_cap", "tu154/custom/switchers/eng/fire_buzzer_cap", globalPropertyi }, --

    -- lamps
    { "smoke_1", "tu154/custom/lights/fire/smoke_1", globalPropertyf }, --
    { "smoke_2", "tu154/custom/lights/fire/smoke_2", globalPropertyf }, --
    { "smoke_zone2_left", "tu154/custom/lights/fire/smoke_zone2_left", globalPropertyf }, --
    { "smoke_zone2_right", "tu154/custom/lights/fire/smoke_zone2_right", globalPropertyf }, --
    { "smoke_zone3", "tu154/custom/lights/fire/smoke_zone3", globalPropertyf }, --
    { "smoke_zone4", "tu154/custom/lights/fire/smoke_zone4", globalPropertyf }, --
    { "smoke_zone5_left", "tu154/custom/lights/fire/smoke_zone5_left", globalPropertyf }, --
    { "smoke_zone5_right", "tu154/custom/lights/fire/smoke_zone5_right", globalPropertyf }, --
    { "smoke_zone6", "tu154/custom/lights/fire/smoke_zone6", globalPropertyf }, --

    { "fire_eng_1", "tu154/custom/lights/fire/fire_eng_1", globalPropertyf }, --
    { "fire_eng_2", "tu154/custom/lights/fire/fire_eng_2", globalPropertyf }, --
    { "fire_eng_3", "tu154/custom/lights/fire/fire_eng_3", globalPropertyf }, --

    { "overheat_eng_1", "tu154/custom/lights/fire/overheat_eng_1", globalPropertyf }, --
    { "overheat_eng_2", "tu154/custom/lights/fire/overheat_eng_2", globalPropertyf }, --
    { "overheat_eng_3", "tu154/custom/lights/fire/overheat_eng_3", globalPropertyf }, --

    { "fuel_off_eng_1", "tu154/custom/lights/fire/fuel_off_eng_1", globalPropertyf }, --
    { "fuel_off_eng_2", "tu154/custom/lights/fire/fuel_off_eng_2", globalPropertyf }, --
    { "fuel_off_eng_3", "tu154/custom/lights/fire/fuel_off_eng_3", globalPropertyf }, --

    { "check_overheat", "tu154/custom/lights/fire/check_overheat", globalPropertyf }, --
    { "fire_apu", "tu154/custom/lights/fire/fire_apu", globalPropertyf }, --
    { "turn_on_spz", "tu154/custom/lights/fire/turn_on_spz", globalPropertyf }, --

    { "button_fire_eng_1", "tu154/custom/lights/button/fire_eng_1", globalPropertyf }, --    1
    { "button_fire_eng_2", "tu154/custom/lights/button/fire_eng_2", globalPropertyf }, --    2
    { "button_fire_eng_3", "tu154/custom/lights/button/fire_eng_3", globalPropertyf }, --    3
    { "button_fire_apu", "tu154/custom/lights/button/fire_apu", globalPropertyf }, --
    { "button_fire_ng", "tu154/custom/lights/button/fire_ng", globalPropertyf }, --
    { "button_fire_turn_3", "tu154/custom/lights/button/fire_turn_3", globalPropertyf }, --    1
    { "button_fire_turn_2", "tu154/custom/lights/button/fire_turn_2", globalPropertyf }, --    1
    { "button_fire_turn_1", "tu154/custom/lights/button/fire_turn_1", globalPropertyf }, --    1

    { "throttle_1_fire", "tu154/custom/lights/small/throttle_1_fire", globalPropertyf }, --
    { "throttle_2_fire", "tu154/custom/lights/small/throttle_2_fire", globalPropertyf }, --
    { "throttle_3_fire", "tu154/custom/lights/small/throttle_3_fire", globalPropertyf }, --

    { "fire_lamp", "tu154/custom/lights/fire", globalPropertyf }, --

    { "eng1_dangerous_vibro", "tu154/custom/lights/engines/eng1_dangerous_vibro", globalPropertyf }, --
    { "eng2_dangerous_vibro", "tu154/custom/lights/engines/eng2_dangerous_vibro", globalPropertyf }, --
    { "eng3_dangerous_vibro", "tu154/custom/lights/engines/eng3_dangerous_vibro", globalPropertyf }, --

    { "day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf }, --   - . 0 - , 1 - .    .

    -- power
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },

    -- engines
    { "eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalProperty }, -- engine 1 rpm
    { "eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalProperty }, -- engine 2 rpm
    { "eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalProperty }, -- engine 3 rpm

    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time

    -- other sources

    { "ext_used_1", "tu154/custom/fire/ext_used_1", globalPropertyi }, --
    { "ext_used_2", "tu154/custom/fire/ext_used_2", globalPropertyi }, --
    { "ext_used_3", "tu154/custom/fire/ext_used_3", globalPropertyi }, --

    { "ng_used", "tu154/custom/fire/ng_used", globalPropertyi }, --

    { "valve_open_1", "tu154/custom/fire/valve_open_1", globalPropertyi }, --    1
    { "valve_open_2", "tu154/custom/fire/valve_open_2", globalPropertyi }, --    2
    { "valve_open_3", "tu154/custom/fire/valve_open_3", globalPropertyi }, --    3
    { "valve_open_4", "tu154/custom/fire/valve_open_4", globalPropertyi }, --

    { "engine_fire_state_1", "tu154/custom/fire/engine_fire_state_1", globalPropertyi }, --  . 0 - , 1 - , 2 -
    { "engine_fire_state_2", "tu154/custom/fire/engine_fire_state_2", globalPropertyi }, --  . 0 - , 1 - , 2 -
    { "engine_fire_state_3", "tu154/custom/fire/engine_fire_state_3", globalPropertyi }, --  . 0 - , 1 - , 2 -
    { "engine_fire_state_4", "tu154/custom/fire/engine_fire_state_4", globalPropertyi }, --  . 0 - , 1 - , 2 -

    { "engine_fuel_cut_1", "tu154/custom/fire/engine_fuel_cut_1", globalPropertyi }, --
    { "engine_fuel_cut_2", "tu154/custom/fire/engine_fuel_cut_2", globalPropertyi }, --
    { "engine_fuel_cut_3", "tu154/custom/fire/engine_fuel_cut_3", globalPropertyi }, --

    { "fire_vlv_open_1", "tu154/custom/fuel/fire_vlv_open_1", globalPropertyf }, --
    { "fire_vlv_open_2", "tu154/custom/fuel/fire_vlv_open_2", globalPropertyf }, --
    { "fire_vlv_open_3", "tu154/custom/fuel/fire_vlv_open_3", globalPropertyf }, --

    { "fire_detected", "tu154/custom/fire/fire_detected", globalPropertyi }, --
    { "fire_siren", "tu154/custom/fire/fire_siren", globalPropertyi }, --
})


-- sounds
local rotary_sound = sasl.al.loadSample('Custom Sounds/plastic_switch.wav')
local switcher_sound = sasl.al.loadSample('Custom Sounds/metal_switch.wav')
local cap_sound = sasl.al.loadSample('Custom Sounds/cap.wav')
local button_sound = sasl.al.loadSample('Custom Sounds/plastic_btn.wav')

local passed = get(frame_time)

local notLoaded = true

local function reset_switchers()
	if isColdAndDarkStart() and get(eng1_N1) < 5 and get(eng2_N1) < 5 and get(eng3_N1) < 5 then
		set(fire_main_switch, 0)

	end
	
	notLoaded = false
end

local lamp_test_last = get(lamp_test)
local smoke_test_last = get(smoke_test)
local ext_test_last = get(ext_test)
local fire_ext_1_last = get(fire_ext_1)
local fire_ext_2_last = get(fire_ext_2)
local fire_ext_3_last = get(fire_ext_3)
local cold_eng_1_last = get(cold_eng_1)
local cold_eng_2_last = get(cold_eng_2)
local cold_eng_3_last = get(cold_eng_3)
local cold_apu_last = get(cold_apu)
local neutral_gas_last = get(neutral_gas)

local fire_sensor_sel_last = get(fire_sensor_sel)
local fire_place_sel_last = get(fire_place_sel)

local fire_main_switch_last = get(fire_main_switch)
local fire_buzzer_last = get(fire_buzzer)

local fire_buzzer_cap_last = get(fire_buzzer_cap)

local function swichers_check()

	local lamp_test_sw = get(lamp_test)
	local smoke_test_sw = get(smoke_test)
	local ext_test_sw = get(ext_test)
	local fire_ext_1_sw = get(fire_ext_1)
	local fire_ext_2_sw = get(fire_ext_2)
	local fire_ext_3_sw = get(fire_ext_3)
	local cold_eng_1_sw = get(cold_eng_1)
	local cold_eng_2_sw = get(cold_eng_2)
	local cold_eng_3_sw = get(cold_eng_3)
	local cold_apu_sw = get(cold_apu)
	local neutral_gas_sw = get(neutral_gas)

	local fire_sensor_sel_sw = get(fire_sensor_sel)
	local fire_place_sel_sw = get(fire_place_sel)

	local fire_main_switch_sw = get(fire_main_switch)
	local fire_buzzer_sw = get(fire_buzzer)

	local fire_buzzer_cap_sw = get(fire_buzzer_cap)
	
	local changes_but = lamp_test_sw + smoke_test_sw + ext_test_sw + fire_ext_1_sw + fire_ext_2_sw + fire_ext_3_sw
	changes_but = changes_but + cold_eng_1_sw + cold_eng_2_sw + cold_eng_3_sw + cold_apu_sw + neutral_gas_sw
	
	changes_but = changes_but - lamp_test_last - smoke_test_last - ext_test_last - fire_ext_1_last - fire_ext_2_last - fire_ext_3_last
	changes_but = changes_but - cold_eng_1_last - cold_eng_2_last - cold_eng_3_last - cold_apu_last - neutral_gas_last
	
	if changes_but ~= 0 then sasl.al.playSample(button_sound, false) end -- play sound
	
	local changes_rot = fire_sensor_sel_sw + fire_place_sel_sw - fire_sensor_sel_last - fire_place_sel_last
	
	if changes_rot ~= 0 then sasl.al.playSample(rotary_sound, false) end -- play sound
	
	local changes_sw = fire_main_switch_sw + fire_buzzer_sw - fire_main_switch_last - fire_buzzer_last
	
	if changes_sw ~= 0 then sasl.al.playSample(switcher_sound, false) end -- play sound
	
	if fire_buzzer_cap_sw ~= fire_buzzer_cap_last then sasl.al.playSample(cap_sound, false) end -- play sound
	
	if fire_buzzer_cap_sw == 0 then set(fire_buzzer, 1) end
	
	lamp_test_last = lamp_test_sw
	smoke_test_last = smoke_test_sw
	ext_test_last = ext_test_sw
	fire_ext_1_last = fire_ext_1_sw
	fire_ext_2_last = fire_ext_2_sw
	fire_ext_3_last = fire_ext_3_sw
	cold_eng_1_last = cold_eng_1_sw
	cold_eng_2_last = cold_eng_2_sw
	cold_eng_3_last = cold_eng_3_sw
	cold_apu_last = cold_apu_sw
	neutral_gas_last = neutral_gas_sw
	
	fire_sensor_sel_last = fire_sensor_sel_sw
	fire_place_sel_last = fire_place_sel_sw

	fire_main_switch_last = fire_main_switch_sw
	fire_buzzer_last = fire_buzzer_sw

	fire_buzzer_cap_last = fire_buzzer_cap_sw

end

local sheck_smoke_lit = false
local check_smoke_counter = 0

local fire_lit = false
local fire_counter = 0

local function lamps()

	local power_sw = get(fire_main_switch)
	local test_btn = get(lamp_test) * math.max((get(bus27_volt_right) - 10) / 18.5, 0)-- * power_sw
	local test_btn_2 = get(lamp_test_2) * math.max((get(bus27_volt_right) - 10) / 18.5, 0)-- * power_sw
	
	local test_btn_frnt = get(lamp_test_front) * math.max((get(bus27_volt_right) - 10) / 18.5, 0)-- * power_sw
	
	local day_night = 1 - get(day_night_set) * 0.25
	local lamps_brt = math.max((math.max(get(bus27_volt_left), get(bus27_volt_right)) - 10) / 18.5, 0)
	
	local smoke_test_but = get(smoke_test)
	
	local smoke_1_brt = math.max(smoke_test_but * power_sw * lamps_brt * day_night, test_btn) -- fake for now
	set(smoke_1, smoke_1_brt)
	
	local smoke_2_brt = math.max(smoke_test_but * power_sw * lamps_brt * day_night, test_btn) -- fake for now
	set(smoke_2, smoke_2_brt)	

	local smoke_zone2_left_brt = math.max(smoke_test_but * power_sw * lamps_brt * day_night, test_btn) -- fake for now
	set(smoke_zone2_left, smoke_zone2_left_brt)
	
	local smoke_zone2_right_brt = math.max(smoke_test_but * power_sw * lamps_brt * day_night, test_btn) -- fake for now
	set(smoke_zone2_right, smoke_zone2_right_brt)

	local smoke_zone3_brt = math.max(smoke_test_but * power_sw * lamps_brt * day_night, test_btn) -- fake for now
	set(smoke_zone3, smoke_zone3_brt)
	
	local smoke_zone4_brt = math.max(smoke_test_but * power_sw * lamps_brt * day_night, test_btn) -- fake for now
	set(smoke_zone4, smoke_zone4_brt)
	
	local smoke_zone5_left_brt = math.max(smoke_test_but * power_sw * power_sw * lamps_brt * day_night, test_btn) -- fake for now
	set(smoke_zone5_left, smoke_zone5_left_brt)
	
	local smoke_zone5_right_brt = math.max(smoke_test_but * power_sw * lamps_brt * day_night, test_btn) -- fake for now
	set(smoke_zone5_right, smoke_zone5_right_brt)
	
	local smoke_zone6_brt = math.max(smoke_test_but * power_sw * lamps_brt * day_night, test_btn) -- fake for now
	set(smoke_zone6, smoke_zone6_brt)
	
	local eng_fire_1 = get(engine_fire_state_1)
	local eng_fire_2 = get(engine_fire_state_2)
	local eng_fire_3 = get(engine_fire_state_3)
	
	local fire_eng_1_brt = 0
	if eng_fire_1 == 2 then fire_eng_1_brt = 1 end
	fire_eng_1_brt = math.max(fire_eng_1_brt * power_sw * lamps_brt * day_night, test_btn)
	set(fire_eng_1, fire_eng_1_brt)
	
	local fire_eng_2_brt = 0
	if eng_fire_2 == 2 then fire_eng_2_brt = 1 end
	fire_eng_2_brt = math.max(fire_eng_2_brt * power_sw * lamps_brt * day_night, test_btn)
	set(fire_eng_2, fire_eng_2_brt)
	
	local fire_eng_3_brt = 0
	if eng_fire_3 == 2 then fire_eng_3_brt = 1 end
	fire_eng_3_brt = math.max(fire_eng_3_brt * power_sw * lamps_brt * day_night, test_btn)
	set(fire_eng_3, fire_eng_3_brt)
	
	local overheat_eng_1_brt = 0
	if eng_fire_1 > 0 then overheat_eng_1_brt = 1 end
	overheat_eng_1_brt = math.max(overheat_eng_1_brt * power_sw * lamps_brt * day_night, test_btn)
	set(overheat_eng_1, overheat_eng_1_brt)
	
	local overheat_eng_2_brt = 0
	if eng_fire_2 > 0 then overheat_eng_2_brt = 1 end
	overheat_eng_2_brt = math.max(overheat_eng_2_brt * power_sw * lamps_brt * day_night, test_btn)
	set(overheat_eng_2, overheat_eng_2_brt)
	
	local overheat_eng_3_brt = 0
	if eng_fire_3 > 0 then overheat_eng_3_brt = 1 end
	overheat_eng_3_brt = math.max(overheat_eng_3_brt * power_sw * lamps_brt * day_night, test_btn)
	set(overheat_eng_3, overheat_eng_3_brt)

	local throttle_1_fire_brt = 0
	if eng_fire_1 > 0 or get(eng1_dangerous_vibro) > 0 then throttle_1_fire_brt = 1 end
	throttle_1_fire_brt = math.max(throttle_1_fire_brt * lamps_brt, test_btn)
	set(throttle_1_fire, throttle_1_fire_brt)

	local throttle_2_fire_brt = 0
	if eng_fire_2 > 0 or get(eng2_dangerous_vibro) > 0 then throttle_2_fire_brt = 1 end
	throttle_2_fire_brt = math.max(throttle_2_fire_brt * lamps_brt, test_btn)
	set(throttle_2_fire, throttle_2_fire_brt)
	
	local throttle_3_fire_brt = 0
	if eng_fire_3 > 0 or get(eng3_dangerous_vibro) > 0 then throttle_3_fire_brt = 1 end
	throttle_3_fire_brt = math.max(throttle_3_fire_brt * lamps_brt, test_btn)
	set(throttle_3_fire, throttle_3_fire_brt)

	local fuel_off_eng_1_brt = 0
	if get(fire_vlv_open_1) < 0.5 then fuel_off_eng_1_brt = 1 end
	fuel_off_eng_1_brt = math.max(fuel_off_eng_1_brt * power_sw * lamps_brt * day_night, test_btn)
	set(fuel_off_eng_1, fuel_off_eng_1_brt)
	
	local fuel_off_eng_2_brt = 0
	if get(fire_vlv_open_2) < 0.5 then fuel_off_eng_2_brt = 1 end
	fuel_off_eng_2_brt = math.max(fuel_off_eng_2_brt * power_sw * lamps_brt * day_night, test_btn)
	set(fuel_off_eng_2, fuel_off_eng_2_brt)
	
	local fuel_off_eng_3_brt = 0
	if get(fire_vlv_open_3) < 0.5 then fuel_off_eng_3_brt = 1 end
	fuel_off_eng_3_brt = math.max(fuel_off_eng_3_brt * power_sw * lamps_brt * day_night, test_btn)
	set(fuel_off_eng_3, fuel_off_eng_3_brt)
	
	local fire_det = get(fire_detected)
	if fire_det == 1 and get(fire_siren) == 0 then 
		sheck_smoke_lit = true
	elseif fire_det == 1 then
		check_smoke_counter = check_smoke_counter + passed
		if check_smoke_counter > 0.4 then
			check_smoke_counter = 0
			sheck_smoke_lit = not sheck_smoke_lit
		end
	else 
		sheck_smoke_lit = false 
	end
		
	local check_overheat_brt = 0
	if sheck_smoke_lit then check_overheat_brt = 1 end
	check_overheat_brt = math.max(check_overheat_brt * lamps_brt * day_night, test_btn)
	set(check_overheat, check_overheat_brt)
	
	local fire_apu_brt = 0
	if get(engine_fire_state_4) > 0 then fire_apu_brt = 1 end
	fire_apu_brt = math.max(fire_apu_brt * power_sw * lamps_brt * day_night, test_btn)
	set(fire_apu, fire_apu_brt)
	
	local turn_on_spz_brt = math.max((1 - power_sw) * lamps_brt * day_night, test_btn)
	set(turn_on_spz, turn_on_spz_brt)
	
	local button_fire_eng_1_brt = math.max(get(valve_open_1) * power_sw * lamps_brt * day_night, test_btn)
	set(button_fire_eng_1, button_fire_eng_1_brt)
	
	local button_fire_eng_2_brt = math.max(get(valve_open_2) * power_sw * lamps_brt * day_night, test_btn)
	set(button_fire_eng_2, button_fire_eng_2_brt)
	
	local button_fire_eng_3_brt = math.max(get(valve_open_3) * power_sw * lamps_brt * day_night, test_btn)
	set(button_fire_eng_3, button_fire_eng_3_brt)
	
	local button_fire_apu_brt = math.max(get(valve_open_4) * power_sw * lamps_brt * day_night, test_btn)
	set(button_fire_apu, button_fire_apu_brt)
	
	local button_fire_ng_brt = math.max(get(ng_used) * power_sw * lamps_brt * day_night, test_btn)
	set(button_fire_ng, button_fire_ng_brt)
	
	local ext_test_but = get(ext_test)
	
	local button_fire_turn_3_brt = math.max(math.max(get(ext_used_3), ext_test_but) * power_sw * lamps_brt * day_night, test_btn)
	set(button_fire_turn_3, button_fire_turn_3_brt)
	
	local button_fire_turn_2_brt = math.max(math.max(get(ext_used_2), ext_test_but) * power_sw * lamps_brt * day_night, test_btn)
	set(button_fire_turn_2, button_fire_turn_2_brt)

	local button_fire_turn_1_brt = math.max(math.max(get(ext_used_1), ext_test_but) * power_sw * lamps_brt * day_night, test_btn)
	set(button_fire_turn_1, button_fire_turn_1_brt)	
	
	if fire_det == 1 then
		fire_counter = fire_counter + passed
		if fire_counter > 0.4 then
			fire_counter = 0
			fire_lit = not fire_lit
		end
	else 
		fire_lit = false 
	end
		
	local fire_lamp_brt = 0
	if fire_lit then fire_lamp_brt = 1 end
	fire_lamp_brt = math.max(fire_lamp_brt * lamps_brt * day_night, test_btn_frnt)
	set(fire_lamp, fire_lamp_brt)

end

local sim_start_timer = 0

function update()
	
	passed = get(frame_time)
	
	-- reset switchers
	sim_start_timer = sim_start_timer + passed
	if sim_start_timer > 0.3 then 
		if notLoaded then reset_switchers() end
	
		swichers_check() -- make them sound
	end
	
	lamps()
	
end