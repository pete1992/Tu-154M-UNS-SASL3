-- chk_before_base.lua
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

    { "spoilers_mid_left", "tu154/custom/lights/spoilers_mid_left", globalPropertyf }, --
    { "spoilers_mid_right", "tu154/custom/lights/spoilers_mid_right", globalPropertyf }, --

    { "stab_setting", "tu154/custom/controll/stab_setting", globalPropertyi }, --    . 0 - , 1 - , 2 - 	1

    { "radioalt_dh_left", "tu154/custom/gauges/alt/radioalt_dh_left", globalPropertyf }, --
})

local angle2alt = {
{-100000, 0},
{0, 0},
{30, 20},
{80, 50},
{160, 100},
{314, 700},
{340, 800},
{8000000, 1000}
}

local checklist_started = false
local stage = 0
local stage_status = 0 -- 0 question, 1+ - answers. 1 usually is false.

local speak_timer = 0

function checklist_8()

	--local passed = get(frame_time)
	
	--print(checklist_started)
	
	-- start the checklist
	if not checklist_started and get(checklist_selected) == 8 then 
		checklist_started = true 
		stage = 1
		
		-- declare checklist
		local num = find_empty()
		phrases_tbl[num] = {nav_tbl["before_3_turn"][lang], 3}
		speak_timer = 3
		
	end
	
	-- another checklist started
	if get(checklist_selected) ~= 8 then 
		checklist_started = false
		stage = 0
		stage_status = 0 
	end
	
	-- move stages
	if checklist_started then
		if stage == 1 and get(fishka_1) == 1 then stage = 2 stage_status = 0 end -- move further if cap is closed
		if stage == 2 and get(fishka_2) == 1 then stage = 3 stage_status = 0 end -- move further if cap is closed
		if stage == 3 and get(fishka_3) == 1 then 
			stage = 100 stage_status = 0 
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["checklist_completed"][lang], 2}
		end -- end checklist
	end
	--print(stage)
	
	---------------------------------
	-- question 1. Spoilers --
	---------------------------------
	if stage == 1 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["speed_br"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (get(spoilers_mid_left) > 0 or get(spoilers_mid_right) > 0) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(spoilers_mid_left) == 0 and get(spoilers_mid_right) == 0 then
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["retracted"][lang], 2}
			
			speak_timer = 2
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 1
	if stage == 1 and stage_status == 10 and speak_timer < 0.1 then set(fishka_1, 1) end

	---------------------------------
	-- question 2. Stab setting --
	---------------------------------
	if stage == 2 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["stabilizer"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		--[[
		-- false answer
		if stage_status == 1 and (get(spoilers_mid_left) > 0 or get(spoilers_mid_right) > 0) then
			-- say false answer once
			stage_status = 2
		end
		--]]
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) then
			local num = find_empty()
			
			if get(stab_setting) == 0 then
				phrases_tbl[num] = {cpt_tbl["stab_set_b"][lang], 2}
			elseif get(stab_setting) == 1 then
				phrases_tbl[num] = {cpt_tbl["stab_set_m"][lang], 2}
			else 
				phrases_tbl[num] = {cpt_tbl["stab_set_f"][lang], 2}
			end
			speak_timer = 2
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 2
	if stage == 2 and stage_status == 10 and speak_timer < 0.1 then set(fishka_2, 1) end

	---------------------------------
	-- question 3. RV setting --
	---------------------------------
	if stage == 3 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["RV"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		local DH = interpolate(angle2alt, get(radioalt_dh_left))
		
		-- false answer
		if stage_status == 1 and (DH < 10 or DH > 400) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and DH < 400 and DH > 10 then
			local num = find_empty()

			phrases_tbl[num] = {cpt_tbl["turned_on2"][lang], 1}

			capt_say_num(math.floor(DH/10 + 0.5)*10, 3, lang)

			phrases_tbl[num+4] = {cpt_tbl["meters"][lang], 1}
			
			speak_timer = 5
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 3
	if stage == 3 and stage_status == 10 and speak_timer < 0.1 then set(fishka_3, 1) end

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

