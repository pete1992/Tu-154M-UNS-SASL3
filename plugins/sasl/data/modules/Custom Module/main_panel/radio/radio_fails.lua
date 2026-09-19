-- radio_fails.lua
-- Radio fails

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
    { "rel_adf1", "sim/operation/failures/rel_adf1", globalPropertyi },
    { "rel_adf2", "sim/operation/failures/rel_adf2", globalPropertyi },
    { "nav1_fail", "tu154/custom/failures/nav1_fail", globalPropertyi },
    { "nav2_fail", "tu154/custom/failures/nav2_fail", globalPropertyi },
    { "dme1_fail", "tu154/custom/failures/dme1_fail", globalPropertyi },
    { "dme2_fail", "tu154/custom/failures/dme2_fail", globalPropertyi },

    { "mrp_fail", "tu154/custom/failures/mrp_fail", globalPropertyi },

    -- define sources
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time
    { "failures_enabled", "tu154/custom/failures/failures_enabled", globalPropertyi },

    -- Smart Copilot
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- Master. 0 = plugin not found, 1 = slave 2 = master
    -- { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- Have control. 0 = plugin not found, 1 = no control 2 = has control
})

local fail_counter = 0
local check_time = math.random(15, 30)

function update()
	local passed = get(frame_time)
	
local MASTER = get(ismaster) ~= 1	
	
if MASTER then	

	local FAIL = get(failures_enabled)
	FAIL = FAIL * 0.05 * 4 ^ (FAIL * 0.5)
	-- check failures
	if FAIL > 0 then
		
		fail_counter = fail_counter + passed
		
		if fail_counter > check_time then
			fail_counter = 0
			check_time = math.random(15, 30)
			
			-- random failures
			if get(rel_adf1) ~= 6 then set(rel_adf1, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6) end
			if get(rel_adf2) ~= 6 then set(rel_adf2, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6) end
			if get(nav1_fail) ~= 1 then set(nav1_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(nav2_fail) ~= 1 then set(nav2_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(dme1_fail) ~= 1 then set(dme1_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(dme2_fail) ~= 1 then set(dme2_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			
			if get(mrp_fail) ~= 1 then set(mrp_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end

		end
		
		-- dependent failures
		
	else
		-- no failures enabled
		fail_counter = 0
		
		set(rel_adf1, 0)
		set(rel_adf2, 0)
		set(nav1_fail, 0)
		set(nav2_fail, 0)
		set(dme1_fail, 0)
		set(dme2_fail, 0)
		set(mrp_fail, 0)

	end
	
end

end