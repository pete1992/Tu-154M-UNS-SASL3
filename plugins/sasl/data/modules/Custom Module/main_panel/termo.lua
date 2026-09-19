-- termo.lua
-- Outside-air temperature indicator.

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
    -- Temperature source, electrical supply and frame time
    { "thermo", "sim/cockpit2/temperature/outside_air_temp_degc", globalPropertyf },
    -- { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf }, -- Unused: this indicator uses the right bus only.
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },

    -- Instrument output
    { "thermo_outside", "tu154/custom/gauges/misc/thermo_outside", globalPropertyf },
})

local termENG_act = -55
function update()
	local passed = get(frame_time)
	local therm = -55
	if get(bus27_volt_right) > 13 then
		therm = get(thermo)
	end
	-- set limits
	if therm > 115 then therm = 115
	elseif therm < -55 then therm = -55 end
	
	termENG_act = termENG_act + (therm - termENG_act) * passed * 5
	
	set(thermo_outside, termENG_act)
	
end
