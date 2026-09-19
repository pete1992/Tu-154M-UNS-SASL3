-- eup53.lua
-- Turn-and-slip indicator.

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
    -- Motion inputs and frame time
    { "turn", "sim/cockpit2/gauges/indicators/turn_rate_heading_deg_pilot", globalPropertyf },
    { "slip", "sim/flightmodel/misc/slip", globalPropertyf },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },

    -- Power and failure state
    { "bus27_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "eup_on", "tu154/custom/switchers/ovhd/eup_on", globalPropertyi },
    { "eup_fail", "sim/operation/failures/rel_ss_tsi", globalPropertyi },

    -- Instrument outputs
    { "slip_rate_ind", "tu154/custom/gauges/misc/slip_rate_ind", globalPropertyf },
    { "turn_rate_ind", "tu154/custom/gauges/misc/turn_rate_ind", globalPropertyf },

    -- SmartCopilot authority: 0 = absent, 1 = slave, 2 = master
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    -- { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- Unused in this leaf component.
})

local slip_act = 0
local turn_act = 0

function update()

local MASTER = get(ismaster) ~= 1

	local passed = get(frame_time)
	-- slip ind
	slip_act = slip_act + (get(slip) - slip_act) * passed * 0.8
	
	if slip_act > 7 then slip_act = 7
	elseif slip_act < -7 then slip_act = -7 end
	
if MASTER then set(slip_rate_ind, slip_act) end
	
	-- turn rate
	local power = get(bus27_volt) > 13 and get(eup_on) == 1 and get(eup_fail) < 6
	local turn_need = 0
	if power then turn_need = get(turn) * 1.5 end
	
	turn_act = turn_act + (turn_need - turn_act) * passed * 2
	
	if turn_act > 50 then turn_act = 50
	elseif turn_act < -50 then turn_act = -50 end
	
if MASTER then set(turn_rate_ind, turn_act) end
	
end
