-- chk_after_press_set.lua
-- this is after pressure set checklist
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
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- time of frame

    -- { "side", "tu154/custom/checklist/side", globalPropertyi }, --   . 0 -  , 1 -

    { "fishka_1", "tu154/custom/checklist/fishka_1", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_2", "tu154/custom/checklist/fishka_2", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_3", "tu154/custom/checklist/fishka_3", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_4", "tu154/custom/checklist/fishka_4", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_5", "tu154/custom/checklist/fishka_5", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_6", "tu154/custom/checklist/fishka_6", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_7", "tu154/custom/checklist/fishka_7", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_8", "tu154/custom/checklist/fishka_8", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_9", "tu154/custom/checklist/fishka_9", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_10", "tu154/custom/checklist/fishka_10", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_11", "tu154/custom/checklist/fishka_11", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_12", "tu154/custom/checklist/fishka_12", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_13", "tu154/custom/checklist/fishka_13", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_14", "tu154/custom/checklist/fishka_14", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_15", "tu154/custom/checklist/fishka_15", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_16", "tu154/custom/checklist/fishka_16", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_17", "tu154/custom/checklist/fishka_17", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_18", "tu154/custom/checklist/fishka_18", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_19", "tu154/custom/checklist/fishka_19", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_20", "tu154/custom/checklist/fishka_20", globalPropertyi }, --  . 0 - , 1 -

    { "checklist_selected", "tu154/custom/checklist/checklist_selected", globalPropertyi }, --

    -- sources

    { "pressure", "tu154/custom/gauges/alt/vbe_press_left", globalPropertyf },  -- pressure in hPa

    { "frequency", "sim/cockpit2/radios/actuators/nav1_frequency_hz", globalPropertyf },  -- set the frequency
    { "nav_pow_cc", "tu154/custom/radio/nav1_pow_cc", globalPropertyf }, --

    { "obs", "tu154/custom/gauges/compas/pkp_obs_set_L", globalPropertyf },  -- set the course

    { "ark15_cc_1", "tu154/custom/radio/ark15_L_cc", globalPropertyf }, --
    { "ark15_cc_2", "tu154/custom/radio/ark15_R_cc", globalPropertyf }, --

    { "absu_landing_on", "tu154/custom/switchers/console/absu_landing_on", globalPropertyi }, --
    { "absu_speed_prepare", "tu154/custom/switchers/console/absu_speed_prepare", globalPropertyi }, --

    { "at_1_lamp", "tu154/custom/lights/small/at_1", globalPropertyf }, --  1
    { "at_2_lamp", "tu154/custom/lights/small/at_2", globalPropertyf }, --  2
})

local checklist_started = false
local stage = 0
local stage_status = 0 -- 0 question, 1+ - answers. 1 usually is false.

local speak_timer = 0

function checklist_7()

	--local passed = get(frame_time)
	
	--print(checklist_started)
	
	-- start the checklist
	if not checklist_started and get(checklist_selected) == 7 then 
		checklist_started = true 
		stage = 1
		
		-- declare checklist
		local num = find_empty()
		phrases_tbl[num] = {nav_tbl["pressure_of_the_airfield"][lang], 3}
		speak_timer = 3
		
	end
	
	-- another checklist started
	if get(checklist_selected) ~= 7 then 
		checklist_started = false
		stage = 0
		stage_status = 0 
	end
	
	-- move stages
	if checklist_started then
		if stage == 1 and get(fishka_15) == 0 then stage = 2 stage_status = 0 end -- move further if cap is closed
		if stage == 2 and get(fishka_16) == 0 then stage = 3 stage_status = 0 end -- move further if cap is closed
		if stage == 3 and get(fishka_17) == 0 then stage = 4 stage_status = 0 end -- move further if cap is closed
		if stage == 4 and get(fishka_18) == 0 then stage = 5 stage_status = 0 end -- move further if cap is closed
		if stage == 5 and get(fishka_19) == 0 then 
			stage = 100 stage_status = 0 
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["checklist_completed"][lang], 2}
		end -- end checklist
	end
	--print(stage)
	
	---------------------------------
	-- question 1. Altimeters --
	---------------------------------
	if stage == 1 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["altimeters"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		--[[
		-- false answer
		if stage_status == 1 and get(mars_on) ~= 1 and get(bus27_volt_left) < 13 and get(bus27_volt_right) < 13 then
			-- say false answer once
			stage_status = 2
		end
		--]]
		-- true answer
		if (stage_status == 1 or stage_status == 2) then
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["pressure_set_to"][lang], 1.5}
			capt_say_num(get(pressure), 4, lang)
			
			speak_timer = 5
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 15
	if stage == 1 and stage_status == 10 and speak_timer < 0.1 then set(fishka_15, 0) end

	---------------------------------
	-- question 2. ILS --
	---------------------------------
	if stage == 2 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["course_mp"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
	
		-- false answer
		if stage_status == 1 and get(nav_pow_cc) == 0 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(nav_pow_cc) ~= 0 then
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["turned_on2"][lang], 1}
			capt_say_num(get(frequency), 5, lang)
			
			speak_timer = 5
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 16
	if stage == 2 and stage_status == 10 and speak_timer < 0.1 then set(fishka_16, 0) end

	---------------------------------
	-- question 3. Course PNP --
	---------------------------------
	if stage == 3 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["course_PNP"][lang], 3}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
	--[[
		-- false answer
		if stage_status == 1 then
			-- say false answer once
			stage_status = 2
		end
		--]]
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(nav_pow_cc) ~= 0 then
			--local num = find_empty()
			--phrases_tbl[num] = {cpt_tbl["turned_on2"][lang], 1}
			local crs = math.floor(get(obs) + 0.5)
			if crs == 0 then crs = 360 end
			
			capt_say_num(crs, 3, lang)
			
			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 17
	if stage == 3 and stage_status == 10 and speak_timer < 0.1 then set(fishka_17, 0) end

	---------------------------------
	-- question 4. ARK --
	---------------------------------
	if stage == 4 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["ARK"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
	
		-- false answer
		if stage_status == 1 and get(ark15_cc_1) * get(ark15_cc_2) == 0 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(ark15_cc_1) ~= 0 and get(ark15_cc_2) ~= 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["switch_on_1"][lang], 2}
			
			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 18
	if stage == 4 and stage_status == 10 and speak_timer < 0.1 then set(fishka_18, 0) end

	---------------------------------
	-- question 5. PN5 PN6 --
	---------------------------------
	if stage == 5 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["PN-5_PN-6"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
	
		-- false answer
		if stage_status == 1 and get(absu_landing_on) * get(absu_speed_prepare) * get(at_1_lamp) * get(at_2_lamp) == 0 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(absu_landing_on) * get(absu_speed_prepare) * get(at_1_lamp) * get(at_2_lamp) ~= 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["prepared"][lang], 2}
			
			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 19
	if stage == 5 and stage_status == 10 and speak_timer < 0.1 then set(fishka_19, 0) end

	speak_timer = speak_timer - passed_time
	
	-- hold timer, if voice que is not empty
	if speak_timer < 0.2 and find_empty() > 1 then speak_timer = phrases_tbl[1][2]
	elseif speak_timer < 0.2 then speak_timer = 0
	end
	
	-- end checklist if all stack moved left
	if checklist_started then
		if stage == 100 then
			checklist_started = false
			set(checklist_selected, 0)
			stage = 0
			stage_status = 0
		end
	
	end
	
	--print(checklist_started)

end
