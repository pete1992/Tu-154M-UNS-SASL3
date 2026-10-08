-- light_fails.lua
-- light system failures

-- failures
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
    { "lan_lamp_fail_FL", "tu154/custom/failures/lan_lamp_fail_FL", globalPropertyi }, --
    { "lan_lamp_fail_FR", "tu154/custom/failures/lan_lamp_fail_FR", globalPropertyi }, --
    { "lan_lamp_fail_WL", "tu154/custom/failures/lan_lamp_fail_WL", globalPropertyi }, --
    { "lan_lamp_fail_WR", "tu154/custom/failures/lan_lamp_fail_WR", globalPropertyi }, --

    { "rel_lites_nav", "sim/operation/failures/rel_lites_nav", globalPropertyi }, --
    { "rel_lites_beac", "sim/operation/failures/rel_lites_beac", globalPropertyi }, --

    -- sources
    { "sim_lan_FL", "sim/cockpit2/switches/landing_lights_switch[7]", globalProperty }, -- front left landing light
    { "sim_lan_FR", "sim/cockpit2/switches/landing_lights_switch[6]", globalProperty }, -- front right landing light
    { "sim_lan_WL", "sim/cockpit2/switches/landing_lights_switch[5]", globalProperty }, -- wing left landing light
    { "sim_lan_WR", "sim/cockpit2/switches/landing_lights_switch[4]", globalProperty }, -- wing right landing light

    -- define sources
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time
    { "failures_enabled", "tu154/custom/failures/failures_enabled", globalPropertyi },

    -- Smart Copilot
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- Master. 0 = plugin not found, 1 = slave 2 = master
    -- { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- Have control. 0 = plugin not found, 1 = no control 2 = has control
})

local timeToFail_FL = math.random(40, 50) * 60 -- Continuous full-power exposure: 40..50 minutes.
local timeToFail_FR = math.random(40, 50) * 60
local timeToFail_WL = math.random(40, 50) * 60
local timeToFail_WR = math.random(40, 50) * 60

local timer_FL = 0 -- timer to fail
local timer_FR = 0 -- timer to fail
local timer_WL = 0 -- timer to fail
local timer_WR = 0 -- timer to fail

-- A cleared failure flag means maintenance replaced that lamp.
local failed_FL = false
local failed_FR = false
local failed_WL = false
local failed_WR = false

local time_table = {{ -5000, -2},    -- bugs workaround
				  { 0, -2 },   -- 
				  { 0.6, -0.5 },   -- 
            	  { 1.5,  1 },   -- 
          		  { 1000, 1 }}   -- bugs workaround

local fail_counter = 0
local check_time = math.random(15, 30)

function update()
	local passed = get(frame_time)

local MASTER = get(ismaster) ~= 1	
	
if MASTER then	
	
	local failure_level = get(failures_enabled)
	local FAIL = failure_level
	FAIL = FAIL * 0.05 * 4 ^ (FAIL * 0.5)
	-- check failures
	if FAIL > 0 then
		
		fail_counter = fail_counter + passed
		
		-- Reset exposure only for an observed lamp repair.
		if failed_FL and get(lan_lamp_fail_FL) ~= 1 then timer_FL = 0 end
		if failed_FR and get(lan_lamp_fail_FR) ~= 1 then timer_FR = 0 end
		if failed_WL and get(lan_lamp_fail_WL) ~= 1 then timer_WL = 0 end
		if failed_WR and get(lan_lamp_fail_WR) ~= 1 then timer_WR = 0 end

		-- calculate timers
		timer_FL = timer_FL + interpolate(time_table, get(sim_lan_FL)) * passed
		timer_FR = timer_FR + interpolate(time_table, get(sim_lan_FR)) * passed
		timer_WL = timer_WL + interpolate(time_table, get(sim_lan_WL)) * passed
		timer_WR = timer_WR + interpolate(time_table, get(sim_lan_WR)) * passed
		
		-- set fails
		if timer_FL > timeToFail_FL then set(lan_lamp_fail_FL, 1) end
		if timer_FR > timeToFail_FR then set(lan_lamp_fail_FR, 1) end
		if timer_WL > timeToFail_WL then set(lan_lamp_fail_WL, 1) end
		if timer_WR > timeToFail_WR then set(lan_lamp_fail_WR, 1) end
		
		-- set limits
		if timer_FL < 0 then timer_FL = 0 end
		if timer_FR < 0 then timer_FR = 0 end
		if timer_WL < 0 then timer_WL = 0 end
		if timer_WR < 0 then timer_WR = 0 end	
		
		if fail_counter > check_time then
			fail_counter = 0
			check_time = math.random(15, 30)
			
			-- random failures
			if failure_level >= 2 then -- LOW retains causal damage only.
			if get(lan_lamp_fail_FL) ~= 1 then set(lan_lamp_fail_FL, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(lan_lamp_fail_FR) ~= 1 then set(lan_lamp_fail_FR, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(lan_lamp_fail_WL) ~= 1 then set(lan_lamp_fail_WL, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			if get(lan_lamp_fail_WR) ~= 1 then set(lan_lamp_fail_WR, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 1) end
			
			if get(rel_lites_nav) ~= 6 then set(rel_lites_nav, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6) end
			if get(rel_lites_beac) ~= 6 then set(rel_lites_beac, bool2int(math.random() < 0.00001 * FAIL * 0.3) * 6) end
			end
			
		end
		
		-- dependent failures
		
	else
		-- no failures enabled
		fail_counter = 0
		timer_FL = 0
		timer_FR = 0
		timer_WL = 0
		timer_WR = 0
		
		set(lan_lamp_fail_FL, 0)
		set(lan_lamp_fail_FR, 0)
		set(lan_lamp_fail_WL, 0)
		set(lan_lamp_fail_WR, 0)
		
		set(rel_lites_nav, 0)
		set(rel_lites_beac, 0)
	
	end
	
	failed_FL = get(lan_lamp_fail_FL) == 1
	failed_FR = get(lan_lamp_fail_FR) == 1
	failed_WL = get(lan_lamp_fail_WL) == 1
	failed_WR = get(lan_lamp_fail_WR) == 1

end

end