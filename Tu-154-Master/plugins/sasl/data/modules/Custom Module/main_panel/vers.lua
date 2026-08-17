print("Tu154 M UNS rewritten by pete92 v2.0.7")

--defineProperty("mem", globalPropertyf("sim/private/stats/lua/total_bytes_alloc_maximum")) -- memory count
--[[
defineProperty("frame_time", globalPropertyf("tu154/custom/time/frame_time")) -- time of frame
local counter = 0
function update()
	counter = counter + get(frame_time)
	if counter > 1 then
		counter = 0
		print(get(mem))
	end
end

--]]