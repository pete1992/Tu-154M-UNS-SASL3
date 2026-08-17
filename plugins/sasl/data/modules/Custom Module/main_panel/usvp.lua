-- this is USVP gauge (true airspeed and groundspeed)

-- sources
defineProperty("tas_svs", globalPropertyf("tu154/custom/svs/true_airspeed")) -- TAS
defineProperty("diss_groundspeed", globalPropertyf("tu154/custom/nvu/diss_groundspeed")) --    
-- time
defineProperty("frame_time", globalPropertyf("tu154/custom/time/frame_time")) -- flight time

-- controls
defineProperty("speed_mid_flag", globalPropertyi("tu154/custom/gauges/speed/speed_mid_flag")) --      0 - , 1 - 

-- result
defineProperty("speed_mid_needle", globalPropertyf("tu154/custom/gauges/speed/speed_mid_needle")) --     

local speed_act = 0

function update()
	local passed = get(frame_time)
	
	local flag = get(speed_mid_flag)
	
	local spd = get(tas_svs)
	
	if flag == 1 then spd = get(diss_groundspeed) end
	
	speed_act = speed_act + (spd - speed_act) * passed * 5
	
	set(speed_mid_needle, speed_act / 1000 * 360)

end
