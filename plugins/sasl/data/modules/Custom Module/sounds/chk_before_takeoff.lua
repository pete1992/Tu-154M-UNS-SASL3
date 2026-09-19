-- chk_before_takeoff.lua
-- this is before lineup checklist
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
    { "course_ga_1", "tu154/custom/tks/course_ga_1", globalPropertyf }, --   1
    { "course_ga_2", "tu154/custom/tks/course_ga_2", globalPropertyf }, --   2
    { "course_bgmk_1", "tu154/custom/tks/course_bgmk_1", globalPropertyf }, --   1
    { "course_bgmk_2", "tu154/custom/tks/course_bgmk_2", globalPropertyf }, --   2

    { "pitot_heat_1", "tu154/custom/switchers/ovhd/pitot_heat_1", globalPropertyi }, --
    { "pitot_heat_2", "tu154/custom/switchers/ovhd/pitot_heat_2", globalPropertyi }, --
    { "pitot_heat_3", "tu154/custom/switchers/ovhd/pitot_heat_3", globalPropertyi }, --

    { "xpdr_mode", "sim/cockpit/radios/transponder_mode", globalPropertyf },

    { "to_ready", "tu154/custom/checklist/to_ready", globalPropertyi }, --
})

local checklist_started = false
local stage = 0
local stage_status = 0 -- 0 question, 1+ - answers. 1 usually is false.

local speak_timer = 0

function checklist_5()

	--local passed = get(frame_time)
	
	--print(checklist_started)
	
	-- start the checklist
	if not checklist_started and get(checklist_selected) == 5 then 
		checklist_started = true 
		stage = 1
		
		-- declare checklist
		local num = find_empty()
		phrases_tbl[num] = {nav_tbl["takeoff_start"][lang], 2}
		speak_timer = 1
		
	end
	
	-- another checklist started
	if get(checklist_selected) ~= 5 then 
		checklist_started = false
		stage = 0
		stage_status = 0 
	end
	
	-- move stages
	if checklist_started then
		if stage == 1 and get(fishka_13) == 1 then 
			stage = 100 stage_status = 0 
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["checklist_completed"][lang], 2}
		end -- end checklist
	end
	
	------------------------------
	-- question 1. ready for takeoff --
	---------------------------------
	if stage == 1 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["ready_takeoff"][lang], 2}
			
			phrases_tbl[num+1] = {eng_tbl["ready"][lang], 1}
			
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer. Nav
		if stage_status == 1 and (math.abs(get(course_ga_1) - get(course_ga_2)) > 0.5 or math.abs(get(course_bgmk_1) - get(course_bgmk_2)) > 0.5) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer. Nav
		if (stage_status == 1 or stage_status == 2) and math.abs(get(course_ga_1) - get(course_ga_2)) < 0.5 and math.abs(get(course_bgmk_1) - get(course_bgmk_2)) < 0.5 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["TKS_ready"][lang], 2}
			local crs = math.floor(get(course_ga_1) + 0.5)
			while crs <= 0 do crs = crs + 360 end
			while crs > 360 do crs = crs - 360 end
			
			nav_say_num(crs, 3, lang)
			phrases_tbl[num+4] = {nav_tbl["ready"][lang], 2}
			
			speak_timer = 6
			stage_status = 3 -- next
		end
		
		-- false answer. Cop
		if stage_status == 1 and get(pitot_heat_1) + get(pitot_heat_2) + get(pitot_heat_3) < 3 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 4
		end		
		
		-- true answer. Cop
		if (stage_status == 3 or stage_status == 4) and get(pitot_heat_1) + get(pitot_heat_2) + get(pitot_heat_3) == 3 then
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["ready"][lang], 2}
		
			speak_timer = 3
			stage_status = 5 -- next
		end		
		
		-- false answer. Cpt
		if stage_status == 1 and (get(xpdr_mode) ~= 2 or get(to_ready) == 1) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 6
		end		
		
		-- true answer. Cpt
		if (stage_status == 5 or stage_status == 6) and get(xpdr_mode) == 2 and get(to_ready) == 0 then
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["ready_to_takeoff"][lang], 5}
		
			speak_timer = 6
			stage_status = 10 -- finish
		end		
		
	end
	
	-- move fishka 13
	if stage == 1 and stage_status == 10 and speak_timer < 0.1 then set(fishka_13, 1) end

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