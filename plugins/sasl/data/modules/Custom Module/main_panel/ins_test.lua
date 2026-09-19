-- ins_test.lua
-- Test logic for INS calculations.

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
    -- Time and aircraft motion
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    { "groundspeed", "sim/flightmodel/position/groundspeed", globalPropertyf },
    { "latitude", "sim/flightmodel/position/latitude", globalPropertyd },
    { "longitude", "sim/flightmodel/position/longitude", globalPropertyd },
    -- Unused by this component and its navigation helpers.
    -- { "elevation", "sim/flightmodel/position/elevation", globalPropertyd },
    { "true_course", "sim/flightmodel/position/hpath", globalPropertyf },
})
	
include("nav_funcs.lua")

local lat_start = get(latitude)
local lon_start = get(longitude)

local lat_last = get(latitude)
local lon_last = get(longitude)

local counter = 0

local spd_last = get(groundspeed) * 1.943844492441
local crs_last = get(true_course)

function update()
	
	local passed = get(frame_time)
	
	--local lat_now = get(latitude)
	--local lon_now = get(longitude)

	if counter > 1 then
		
		-- speed
		local speed_now = get(groundspeed) * 1.943844492441
		local speed = (speed_now + spd_last) / 2
		spd_last = speed_now
		
		-- course
		local crs_now = get(true_course)
		local crs = (crs_now + crs_last) / 2
		crs_last = crs_now
		
		local de_dest = dist_new(speed, counter)
		
		--print(speed, "  ", crs, "  ", de_dest)
		
		-- try to calculate coordinates by using speed, course and last coords.
		
		local lat_new, lon_new = calcDest(lat_last, lon_last, crs, de_dest)
		
		--print(lat_new, "  ", lon_new)
		
		lat_last = lat_new
		lon_last = lon_new
		
		counter = 0
		
	end
	
	counter = counter + passed
	
end
