-- spu.lua
-- this is simple SPU logic
size = {140, 180}

-- define property table
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
    { "audio_selection_com1", "sim/cockpit2/radios/actuators/audio_selection_com1", globalPropertyi },
    { "audio_selection_com2", "sim/cockpit2/radios/actuators/audio_selection_com2", globalPropertyi },
    { "audio_selection_nav1", "sim/cockpit2/radios/actuators/audio_selection_nav1", globalPropertyi },
    { "audio_selection_nav2", "sim/cockpit2/radios/actuators/audio_selection_nav2", globalPropertyi },
    { "audio_selection_adf1", "sim/cockpit2/radios/actuators/audio_selection_adf1", globalPropertyi },
    { "audio_selection_adf2", "sim/cockpit2/radios/actuators/audio_selection_adf2", globalPropertyi },
    --defineProperty("audio_dme_enabled", globalPropertyi("sim/cockpit2/radios/actuators/audio_dme_enabled"))

    { "com1_right_is_selected", "sim/cockpit2/radios/actuators/com1_right_is_selected", globalPropertyi },

    { "VHF2Freq", "sim/cockpit2/radios/actuators/com2_frequency_hz", globalPropertyf },  -- set the frequency
    { "VHF1Freq", "sim/cockpit2/radios/actuators/com1_frequency_hz", globalPropertyf },  -- set the frequency

    { "spu_power_sw", "tu154/custom/switchers/spu_1_power", globalPropertyi },
    -- { "spu_mode", "tu154/custom/switchers/spu_1_mode", globalPropertyi },
    { "spu_source", "tu154/custom/switchers/spu_1_source", globalPropertyi },
    { "bus27_L", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_R", "tu154/custom/elec/bus27_volt_right", globalPropertyf },

    { "vhf_1_on", "tu154/custom/switchers/ovhd/vhf_1_on", globalPropertyi },  -- power switch
    { "vhf_2_on", "tu154/custom/switchers/ovhd/vhf_2_on", globalPropertyi },  -- power switch

    { "ark_mode_1", "tu154/custom/switchers/ovhd/ark_1_mode", globalPropertyi }, --   1 0 - , 1 - , 2 - , 3 -
    { "ark_mode_2", "tu154/custom/switchers/ovhd/ark_2_mode", globalPropertyi }, --   2 0 - , 1 - , 2 - , 3 -

    -- { "com1_power", "sim/cockpit2/radios/actuators/com1_power", globalPropertyi },
    -- { "com2_power", "sim/cockpit2/radios/actuators/com2_power", globalPropertyi },
})

local switch_sound = sasl.al.loadSample('Custom Sounds/metal_switch.wav')
local cap_sound = sasl.al.loadSample('Custom Sounds/cap.wav')
local btn_click = sasl.al.loadSample('Custom Sounds/plastic_btn.wav')
local rot_click = sasl.al.loadSample('Custom Sounds/rot_click.wav')
local plastic_sound = sasl.al.loadSample('Custom Sounds/plastic_switch.wav')

local mode_last = get(spu_source)

function update()

	local mode = get(spu_source)
	local power = get(spu_power_sw) == 1 and get(bus27_L) > 13
	
	set(VHF2Freq, get(VHF1Freq))
	
	if mode ~= mode_last then sasl.al.playSample(switch_sound, false) end
	mode_last = mode
	
	if mode == 0 and power then -- COM 1
		set(audio_selection_com1, bool2int(get(bus27_L) > 20 and get(vhf_1_on) == 1))
		set(audio_selection_com2, 0)
		set(audio_selection_nav1, 0)
		set(audio_selection_nav2, 0)
		set(audio_selection_adf1, 0)
		set(audio_selection_adf2, 0)
		set(com1_right_is_selected, 0)
	elseif mode == 1 and power then -- COM 2
		set(audio_selection_com1, bool2int(get(bus27_R) > 20 and get(vhf_2_on) == 1))
		set(audio_selection_com2, 0)
		set(audio_selection_nav1, 0)
		set(audio_selection_nav2, 0)
		set(audio_selection_adf1, 0)
		set(audio_selection_adf2, 0)
		set(com1_right_is_selected, 1)
	elseif mode == 4 and power then -- NAV 1 or ADF 1
		if get(ark_mode_1) == 2 then
			set(audio_selection_com1, 0)
			set(audio_selection_com2, 0)
			set(audio_selection_nav1, 0)
			set(audio_selection_nav2, 0)
			set(audio_selection_adf1, 1)
			set(audio_selection_adf2, 0)
			set(com1_right_is_selected, 1)
		else
			set(audio_selection_com1, 0)
			set(audio_selection_com2, 0)
			set(audio_selection_nav1, 1)
			set(audio_selection_nav2, 0)
			set(audio_selection_adf1, 0)
			set(audio_selection_adf2, 0)
			set(com1_right_is_selected, 1)
		end
	elseif mode == 5 and power then -- NAV 2 or ADF 2
		if get(ark_mode_2) == 2 then
			set(audio_selection_com1, 0)
			set(audio_selection_com2, 0)
			set(audio_selection_nav1, 0)
			set(audio_selection_nav2, 0)
			set(audio_selection_adf1, 0)
			set(audio_selection_adf2, 1)
			set(com1_right_is_selected, 1)
		else
			set(audio_selection_com1, 0)
			set(audio_selection_com2, 0)
			set(audio_selection_nav1, 0)
			set(audio_selection_nav2, 1)
			set(audio_selection_adf1, 0)
			set(audio_selection_adf2, 0)
			set(com1_right_is_selected, 1)
		end
	else -- none
		set(audio_selection_com1, 0)
		set(audio_selection_com2, 0)
		set(audio_selection_nav1, 0)
		set(audio_selection_nav2, 0)
		set(audio_selection_adf1, 0)
		set(audio_selection_adf2, 0)
		set(com1_right_is_selected, 1)
	end

end

