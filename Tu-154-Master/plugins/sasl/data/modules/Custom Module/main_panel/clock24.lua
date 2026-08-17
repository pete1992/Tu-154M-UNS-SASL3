-- source datarefs
defineProperty("utc_time", globalPropertyf("sim/time/zulu_time_sec"))

--[[
tu154/custom/buttons/clock_24_left	int	  24- . 0 - , 1 -  (  )
tu154/custom/buttons/clock_24_right	int	  24- 
tu154/custom/gauges/clock_24_hours	float	 
tu154/custom/gauges/clock_24_mins	float	 
tu154/custom/gauges/clock_24_red	float	 

--]]

defineProperty("clock_24_hours", globalPropertyf("tu154/custom/gauges/clock_24_hours"))
defineProperty("clock_24_mins", globalPropertyf("tu154/custom/gauges/clock_24_mins"))
defineProperty("clock_24_red", globalPropertyf("tu154/custom/gauges/clock_24_red"))

--math.randomseed( os.time() ) -- randomise random :)
set(clock_24_red, math.random(360))

function update()
	local main_time = get(utc_time) -- seconds
	
	local minutes_angle = main_time * 0.1 -- minutes
	local hour_angle = main_time * 360 / (60*60*24)
	
	set(clock_24_mins, minutes_angle)
	set(clock_24_hours, hour_angle)
	
end