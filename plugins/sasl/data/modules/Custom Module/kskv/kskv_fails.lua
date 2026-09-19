-- kskv_fails.lua
-- air bleed fails

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
    { "airbleed_1", "tu154/custom/failures/airbleed_1", globalPropertyi }, --
    { "airbleed_2", "tu154/custom/failures/airbleed_2", globalPropertyi }, --
    { "airbleed_3", "tu154/custom/failures/airbleed_3", globalPropertyi }, --

    { "psvp_fail_left", "tu154/custom/failures/psvp_fail_left", globalPropertyi }, --
    { "psvp_fail_right", "tu154/custom/failures/psvp_fail_right", globalPropertyi }, --

    { "tth_left_fail", "tu154/custom/failures/tth_left_fail", globalPropertyi }, --
    { "tth_right_fail", "tu154/custom/failures/tth_right_fail", globalPropertyi }, --

    { "sard_valve_fail", "tu154/custom/failures/sard_valve_fail", globalPropertyi }, --

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
			if get(airbleed_1) ~= 1 then set(airbleed_1, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(airbleed_2) ~= 1 then set(airbleed_2, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(airbleed_3) ~= 1 then set(airbleed_3, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			
			if get(psvp_fail_left) ~= 1 then set(psvp_fail_left, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(psvp_fail_right) ~= 1 then set(psvp_fail_right, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			
			if get(tth_left_fail) ~= 1 then set(tth_left_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(tth_right_fail) ~= 1 then set(tth_right_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			
			if get(sard_valve_fail) ~= 1 then set(sard_valve_fail, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end

		end
		
		-- dependent failures
		
	else
		-- no failures enabled
		fail_counter = 0
		
		set(airbleed_1, 0)
		set(airbleed_2, 0)
		set(airbleed_3, 0)
		
		set(psvp_fail_left, 0)
		set(psvp_fail_right, 0)
		
		set(tth_left_fail, 0)
		set(tth_right_fail, 0)
		
		set(sard_valve_fail, 0)

	end
	
end

end
