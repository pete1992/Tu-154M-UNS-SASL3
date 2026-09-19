-- chk_before_land.lua
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

    { "stab_ind", "tu154/custom/gauges/misc/stab_ind", globalPropertyf }, --
    { "elevator_ind", "tu154/custom/gauges/misc/elevator_ind", globalPropertyf }, --
    { "flap_left_ind", "tu154/custom/gauges/misc/flap_left_ind", globalPropertyf }, --
    { "flap_right_ind", "tu154/custom/gauges/misc/flap_right_ind", globalPropertyf }, --
    { "slats_extended", "tu154/custom/lights/slats_extended", globalPropertyf }, --

    { "joy_pitch", "tu154/custom/SC/yoke_pitch_ratio", globalPropertyf },

    { "gears_green_left", "tu154/custom/lights/gears_green_left", globalPropertyf }, --
    { "gears_green_front", "tu154/custom/lights/gears_green_front", globalPropertyf }, --
    { "gears_green_right", "tu154/custom/lights/gears_green_right", globalPropertyf }, --
    { "gear_lever", "tu154/custom/controll/gear_lever", globalPropertyi }, --   . -1 - , 0 - , +1 -

    { "to_rudder", "tu154/custom/lights/to_rudder", globalPropertyf }, -- -
    { "to_elevator", "tu154/custom/lights/to_elevator", globalPropertyf }, -- -

    { "landing_ext_set_L", "tu154/custom/lights/landing_ext_set_L", globalPropertyi }, --
    { "landing_ext_set_R", "tu154/custom/lights/landing_ext_set_R", globalPropertyi }, --
})

local checklist_started = false
local stage = 0
local stage_status = 0 -- 0 question, 1+ - answers. 1 usually is false.

local speak_timer = 0

function checklist_9()

	--local passed = get(frame_time)
	
	--print(checklist_started)
	
	-- start the checklist
	if not checklist_started and get(checklist_selected) == 9 then 
		checklist_started = true 
		stage = 1
		
		-- declare checklist
		local num = find_empty()
		phrases_tbl[num] = {nav_tbl["befor_DPRM"][lang], 3}
		speak_timer = 3
		
	end
	
	-- another checklist started
	if get(checklist_selected) ~= 9 then 
		checklist_started = false
		stage = 0
		stage_status = 0 
	end
	
	-- move stages
	if checklist_started then
		if stage == 1 and get(fishka_10) == 1 then stage = 2 stage_status = 0 end -- move further if cap is closed
		if stage == 2 and get(fishka_11) == 1 then stage = 3 stage_status = 0 end -- move further if cap is closed
		if stage == 3 and get(fishka_12) == 1 then stage = 4 stage_status = 0 end -- move further if cap is closed
		if stage == 4 and get(fishka_13) == 1 then stage = 5 stage_status = 0 end -- move further if cap is closed
		if stage == 5 and get(fishka_14) == 1 then 
			stage = 100 stage_status = 0 
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["checklist_completed"][lang], 2}
		end -- end checklist
	end
	--print(stage)
	
	---------------------------------
	-- question 1. Flaps and slats --
	---------------------------------
	if stage == 1 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["flaps"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (get(flap_left_ind) < 26 or get(flap_right_ind) < 26 or get(slats_extended) == 0)  then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(flap_left_ind) > 26 and get(flap_right_ind) > 26 and get(slats_extended) > 0.1  then
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["ext_flaps_"][lang], 1.5}
			cop_say_num(math.floor(get(flap_left_ind)+0.5), 2, lang)
			
			speak_timer = 4
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 10
	if stage == 1 and stage_status == 10 and speak_timer < 0.1 then set(fishka_10, 1) end

	---------------------------------
	-- question 2. Stab RV --
	---------------------------------
	if stage == 2 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["stabilizer_RV"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (math.abs(get(joy_pitch)) > 0.1 or get(elevator_ind) > 6 or get(elevator_ind) < -2) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and math.abs(get(joy_pitch)) <= 0.1 and get(elevator_ind) < 6 and get(elevator_ind) > -2 then
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["synced"][lang], 2}
			
			speak_timer = 2
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 11
	if stage == 2 and stage_status == 10 and speak_timer < 0.1 then set(fishka_11, 1) end

	---------------------------------
	-- question 3. Gears --
	---------------------------------
	if stage == 3 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["gear"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (get(gears_green_left) * get(gears_green_front) * get(gears_green_right) == 0 or get(gear_lever) ~= 0) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(gears_green_left) * get(gears_green_front) * get(gears_green_right) ~= 0 and get(gear_lever) == 0 then
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["ext_green_neutr"][lang], 3}
			
			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 12
	if stage == 3 and stage_status == 10 and speak_timer < 0.1 then set(fishka_12, 1) end

	---------------------------------
	-- question 4. Contr force --
	---------------------------------
	if stage == 4 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["RV_RN"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and get(to_rudder) * get(to_elevator) == 0 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(to_rudder) + get(to_elevator) > 0.2 then
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["off_tablo_lit"][lang], 2}

			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 13
	if stage == 4 and stage_status == 10 and speak_timer < 0.1 then set(fishka_13, 1) end

	---------------------------------
	-- question 5. Lights --
	---------------------------------
	if stage == 5 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["landing_lights"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and get(landing_ext_set_L) * get(landing_ext_set_R) == 0 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(landing_ext_set_L) * get(landing_ext_set_R) == 1 then
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["extended"][lang], 2}

			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 14
	if stage == 5 and stage_status == 10 and speak_timer < 0.1 then set(fishka_14, 1) end
	
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

