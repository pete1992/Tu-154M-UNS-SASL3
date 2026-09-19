-- usvp.lua
-- USVP true-airspeed and groundspeed indicator.

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
    -- Speed inputs and frame time
    { "tas_svs", "tu154/custom/svs/true_airspeed", globalPropertyf },
    { "diss_groundspeed", "tu154/custom/nvu/diss_groundspeed", globalPropertyf },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },

    -- Source selector and instrument output
    { "speed_mid_flag", "tu154/custom/gauges/speed/speed_mid_flag", globalPropertyi },
    { "speed_mid_needle", "tu154/custom/gauges/speed/speed_mid_needle", globalPropertyf },
})

local speed_act = 0

function update()
	local passed = get(frame_time)
	
	local flag = get(speed_mid_flag)
	
	local spd = get(tas_svs)
	
	if flag == 1 then spd = get(diss_groundspeed) end
	
	speed_act = speed_act + (spd - speed_act) * passed * 5
	
	set(speed_mid_needle, speed_act / 1000 * 360)

end
