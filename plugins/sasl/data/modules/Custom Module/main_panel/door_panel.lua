-- door_panel.lua
-- Door, hatch and steering annunciator panel.

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
    -- Lamp controls
    { "test_lamps", "tu154/custom/buttons/lamp_test_doors", globalPropertyi },
    { "day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf },

    -- Power, timing and steering controls
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    -- { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- Unused: no time-dependent logic in this component.
    { "nosewheel_turn_enable", "tu154/custom/switchers/nosewheel_turn_enable", globalPropertyi },
    { "nosewheel_turn_sel", "tu154/custom/switchers/nosewheel_turn_sel", globalPropertyi }, -- 0 = 10 degrees, 1 = 63 degrees

    -- Annunciator outputs
    { "other_hatches", "tu154/custom/lights/other_hatches", globalPropertyf },
    { "left_front_pax_door", "tu154/custom/lights/left_front_pax_door", globalPropertyf },
    { "left_mid_pax_door", "tu154/custom/lights/left_mid_pax_door", globalPropertyf },
    { "right_mid_pax_door", "tu154/custom/lights/right_mid_pax_door", globalPropertyf },
    { "cargo_front_door", "tu154/custom/lights/cargo_front_door", globalPropertyf },
    { "cargo_back_door", "tu154/custom/lights/cargo_back_door", globalPropertyf },
    { "turn63_lamp", "tu154/custom/lights/turn63_lamp", globalPropertyf },
    { "nosewheel_turn_off", "tu154/custom/lights/nosewheel_turn_off", globalPropertyf },
    { "busters_off", "tu154/custom/lights/busters_off", globalPropertyf },

    -- Door and switch-cover positions
    { "cargo_1", "tu154/custom/anim/cargo_1", globalPropertyf },
    { "cargo_2", "tu154/custom/anim/cargo_2", globalPropertyf },
    { "pax_door_1", "tu154/custom/anim/pax_door_1", globalPropertyf },
    { "pax_door_2", "tu154/custom/anim/pax_door_2", globalPropertyf },
    { "pax_door_3", "tu154/custom/anim/pax_door_3", globalPropertyf },
    { "busters_cap", "tu154/custom/switchers/console/busters_cap", globalPropertyi },
})

-- local passed = get(frame_time) -- Unused initialization; no consumer of passed.

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

