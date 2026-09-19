-- mach_meters.lua
-- Captain and copilot Mach indicators.

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
    -- Mach sources and pitot failures
    { "mach", "sim/flightmodel/misc/machno", globalPropertyf },
    { "mach_svs", "tu154/custom/svs/machno", globalPropertyf },
    -- { "rel_pitot", "sim/operation/failures/rel_pitot", globalPropertyi }, -- Unused: the captain's input is already supplied by SVS.
    { "rel_pitot2", "sim/operation/failures/rel_pitot2", globalPropertyi },

    -- Timing
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },

    -- Indicator outputs
    { "mach_ind_left", "tu154/custom/gauges/speed/mach_left", globalPropertyf },
    { "mach_ind_right", "tu154/custom/gauges/speed/mach_right", globalPropertyf },
})

local mach_ind_L = 0
local mach_ind_R = 0

local mach_L_act = 0
local mach_R_act = 0

function update()

	local passed = get(frame_time)
	local mach_sim = get(mach)
	
	-----------------
	mach_ind_L = get(mach_svs)
	
	if mach_ind_L > 0.89 then mach_ind_L = 0.89
	elseif mach_ind_L < 0 then mach_ind_L = 0 end
	
	mach_L_act = mach_L_act + (mach_ind_L - mach_L_act) * passed * 10
	
	-----------------
	if get(rel_pitot2) < 6 then mach_ind_R = mach_sim end

	if mach_ind_R > 1.03 then mach_ind_R = 1.03 
	elseif mach_ind_R < 0 then mach_ind_R = 0 end

	mach_R_act = mach_R_act + (mach_ind_R - mach_R_act) * passed * 10
	
	set(mach_ind_left, mach_L_act)
	set(mach_ind_right, mach_R_act)

end
