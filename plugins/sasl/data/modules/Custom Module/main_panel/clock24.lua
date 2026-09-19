-- clock24.lua
-- Rear-panel 24-hour clock.

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
    -- UTC source and clock-hand outputs
    { "utc_time", "sim/time/zulu_time_sec", globalPropertyf },
    { "clock_24_hours", "tu154/custom/gauges/clock_24_hours", globalPropertyf },
    { "clock_24_mins", "tu154/custom/gauges/clock_24_mins", globalPropertyf },
    { "clock_24_red", "tu154/custom/gauges/clock_24_red", globalPropertyf },
})

--[[
tu154/custom/buttons/clock_24_left	int	  24- . 0 - , 1 -  (  )
tu154/custom/buttons/clock_24_right	int	  24- 
tu154/custom/gauges/clock_24_hours	float	 
tu154/custom/gauges/clock_24_mins	float	 
tu154/custom/gauges/clock_24_red	float	 

--]]


--math.randomseed( os.time() ) -- randomise random :)
set(clock_24_red, math.random(360))

function update()
	local main_time = get(utc_time) -- seconds
	
	local minutes_angle = main_time * 0.1 -- minutes
	local hour_angle = main_time * 360 / (60*60*24)
	
	set(clock_24_mins, minutes_angle)
	set(clock_24_hours, hour_angle)
	
end
