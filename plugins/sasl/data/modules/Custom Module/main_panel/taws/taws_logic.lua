-- taws_logic.lua
-- TAWS main logic
size = {1000, 770}

-- controls
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
    { "but_view", "tu154/custom/buttons/srpbz/but_view", globalPropertyi }, --
    { "but_empty", "tu154/custom/buttons/srpbz/but_empty", globalPropertyi }, --  -
    { "but_down", "tu154/custom/buttons/srpbz/but_down", globalPropertyi }, --
    { "but_up", "tu154/custom/buttons/srpbz/but_up", globalPropertyi }, --

    -- { "egpws_alarm_1", "tu154/custom/switchers/ovhd/egpws_alarm_1", globalPropertyi }, --
    -- { "egpws_alarm_2", "tu154/custom/switchers/ovhd/egpws_alarm_2", globalPropertyi }, --
    -- { "egpws_alarm_1_cap", "tu154/custom/switchers/ovhd/egpws_alarm_1_cap", globalPropertyi }, --
    -- { "egpws_alarm_2_cap", "tu154/custom/switchers/ovhd/egpws_alarm_2_cap", globalPropertyi }, --
    -- { "egpws_relief", "tu154/custom/switchers/ovhd/egpws_relief", globalPropertyi }, --
    -- { "egpws_mode", "tu154/custom/switchers/ovhd/egpws_mode", globalPropertyi }, -- QNH - QFE

    { "egpws_control", "tu154/custom/buttons/ovhd/egpws_control", globalPropertyi }, --
    -- { "egpws_contr_gs", "tu154/custom/buttons/ovhd/egpws_contr_gs", globalPropertyi }, --

    -- power
    { "srpbz_on", "tu154/custom/kontur/srpbz", globalPropertyf }, -- physical TAWS master switch
    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf }, --   115
    -- { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },

    { "rv_on", "tu154/custom/switchers/ovhd/rv5_2_on", globalPropertyi },  -- switcher

    { "bus27_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf }, --   27

    { "taws_fail", "tu154/custom/failures/taws_fail", globalPropertyi }, --

    -- sources
    -- { "vvi_L", "sim/cockpit2/gauges/indicators/vvi_fpm_pilot", globalPropertyf }, -- vertical speed in ft/min
    -- { "vvi_R", "sim/cockpit2/gauges/indicators/vvi_fpm_copilot", globalPropertyf },

    -- { "rv5_alt", "tu154/custom/misc/rv5_alt_left", globalPropertyf },  --

    -- results
    { "mode_set", "tu154/custom/taws/mode_set", globalPropertyi }, --   . 0 - , 1 -  , 2 -  , 3 - , 4 -  , 5 - , 6 -
    { "distance_set", "tu154/custom/taws/distance_set", globalPropertyi }, --    , . 0 = 10, 1 = 20, 2 = 40, 3 = 80, 4 = 160, 5 = 320, 6 = 640

    { "taws_cc", "tu154/custom/taws/taws_cc", globalPropertyf }, --

    -- Smart Copilot
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- Master. 0 = plugin not found, 1 = slave 2 = master
    -- { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- Have control. 0 = plugin not found, 1 = no control 2 = has control
})

local but_view_last = 0
local but_empt_last = 0

local but_rng_up_last = 0
local but_rng_dn_last = 0

local up_counter = 0

function update()

local MASTER = get(ismaster) ~= 1	
	
if MASTER then	

	local power = get(srpbz_on) > 0 and get(bus115_1_volt) > 110 and get(bus27_volt) > 13 and get(rv_on) == 1
	
	if not power then
		set(mode_set, 0)
		set(distance_set, 1)
		set(taws_cc, 0)
		
		but_view_last = 0
		but_empt_last = 0

		but_rng_up_last = 0
		but_rng_dn_last = 0
	else

		local current_mode = get(mode_set)
		
		if current_mode == 0 then set(mode_set, 4) end -- system just started
		
		local but_view_now = get(but_view)
		local but_empty_now = get(but_empty)
		local but_down_now = get(but_down)
		local but_up_now = get(but_up)
		
		if (current_mode > 0 and current_mode < 4) or current_mode == 10 then
			
			if get(egpws_control) == 1 then set(mode_set, 5) end -- test mode
			
			if up_counter > 10 and get(ismaster) == 0 then
				set(mode_set, 6)
				up_counter = 0
			elseif get(ismaster) ~= 0 then
				up_counter = 0
			end
			
			if but_view_now == 1 and but_view_now ~= but_view_last then
				if current_mode ~= 1 then set(mode_set, 1)
				else set(mode_set, 2) end
				up_counter = 0
			end
			
			if but_empty_now == 1 and but_empty_now ~= but_empt_last then
				if current_mode ~= 3 then set(mode_set, 3)
				else set(mode_set, 1) end
				up_counter = up_counter + 1
			end
			
			if but_up_now == 1 and but_up_now ~= but_rng_up_last then
				local a = math.min(4, get(distance_set) + 1)
				set(distance_set, a)
				up_counter = 0
			end
			
			if but_down_now == 1 and but_down_now ~= but_rng_dn_last then
				local a = math.max(0, get(distance_set) - 1)
				set(distance_set, a)
				up_counter = 0
			end
			
			if get(taws_fail) == 1 then 
				set(mode_set, 10)
			elseif current_mode == 10 and get(taws_fail) == 0 then
				set(mode_set, 1)
			end
			
		end
	
		if current_mode == 6 and but_view_now == 1 and but_view_now ~= but_view_last then
			set(mode_set, 1)
		end
		
		but_view_last = but_view_now
		but_empt_last = but_empty_now

		but_rng_up_last = but_up_now
		but_rng_dn_last = but_down_now
	
		set(taws_cc, 1.5)
	end
	
end	
	
	--set(mode_set, 6) -- test game

end

