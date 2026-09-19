-- chk_before_descend.lua
-- this is before descend checklist
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

    -- Source

    { "cg_pos_actual", "tu154/custom/misc/cg_pos_actual", globalPropertyf }, --   CG
    { "weight_actual", "tu154/custom/misc/weight_actual", globalPropertyf }, --

    { "course_mk_1", "tu154/custom/tks/course_mk_1", globalPropertyf }, --   MK5
    { "course_mk_2", "tu154/custom/tks/course_mk_2", globalPropertyf }, --   MK5

    { "course_ga_1", "tu154/custom/tks/course_ga_1", globalPropertyf }, --   1
    { "course_ga_2", "tu154/custom/tks/course_ga_2", globalPropertyf }, --   2

    { "radioalt_dh_left", "tu154/custom/gauges/alt/radioalt_dh_left", globalPropertyf }, --

    { "fuel_meter_summ", "tu154/custom/gauges/fuel/fuel_meter_summ", globalPropertyf }, --
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

function checklist_6()

	--local passed = get(frame_time)
	
	--print(checklist_started)
	
	-- start the checklist
	if not checklist_started and get(checklist_selected) == 6 then 
		checklist_started = true 
		stage = 1
		
		-- declare checklist
		local num = find_empty()
		phrases_tbl[num] = {nav_tbl["TOD"][lang], 2}
		speak_timer = 2
		
	end
	
	-- another checklist started
	if get(checklist_selected) ~= 6 then 
		checklist_started = false
		stage = 0
		stage_status = 0 
	end
	
	-- move stages
	if checklist_started then
		if stage == 1 and get(fishka_8) == 0 then stage = 2 stage_status = 0 end -- move further if cap is closed
		if stage == 2 and get(fishka_9) == 0 then stage = 3 stage_status = 0 end -- move further if cap is closed
		if stage == 3 and get(fishka_10) == 0 then stage = 4 stage_status = 0 end -- move further if cap is closed
		if stage == 4 and get(fishka_11) == 0 then stage = 5 stage_status = 0 end -- move further if cap is closed
		if stage == 5 and get(fishka_12) == 0 then 
			stage = 100 stage_status = 0 
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["checklist_completed"][lang], 2}
		end -- end checklist
	end
	--print(stage)
	
	---------------------------------
	-- question 1. Charts --
	---------------------------------
	if stage == 1 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["plan"][lang], 1}
	
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
			phrases_tbl[num] = {cpt_tbl["read"][lang], 2}
			
			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 8
	if stage == 1 and stage_status == 10 and speak_timer < 0.1 then set(fishka_8, 0) end

	---------------------------------
	-- question 2. Landing data --
	---------------------------------
	if stage == 2 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["landing_date"][lang], 2}
	
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
			phrases_tbl[num] = {cop_tbl["weight"][lang], 1}
			
			cop_say_num(math.floor(get(weight_actual)/1000 + 0.5), 3, lang)
			
			phrases_tbl[num+4] = {cop_tbl["cg_pos"][lang], 1}
			
			cop_say_num(math.floor(get(cg_pos_actual)+0.5), 2, lang)
			
			speak_timer = 5
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 9
	if stage == 2 and stage_status == 10 and speak_timer < 0.1 then set(fishka_9, 0) end

	---------------------------------
	-- question 3. TKS --
	---------------------------------
	if stage == 3 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["TKS"][lang], 1}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and get(mars_on) ~= 1 and (math.abs(get(course_mk_1) - get(course_ga_1)) > 3 or math.abs(get(course_mk_2) - get(course_ga_2)) > 3) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and math.abs(get(course_mk_1) - get(course_ga_1)) < 3 and math.abs(get(course_mk_2) - get(course_ga_2)) < 3 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["TKS_aligned"][lang], 5}
			
			speak_timer = 6
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 10
	if stage == 3 and stage_status == 10 and speak_timer < 0.1 then set(fishka_10, 0) end

	---------------------------------
	-- question 4. RV setting --
	---------------------------------
	if stage == 4 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["RV"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		local DH = interpolate(angle2alt, get(radioalt_dh_left))
		
		-- false answer
		if stage_status == 1 and get(mars_on) ~= 1 and DH < 400 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and DH >= 400 then
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["rv_setting"][lang], 1}
			
			cop_say_num(math.floor(DH/10+0.5)*10, 3, lang)
			
			speak_timer = 4
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 11
	if stage == 4 and stage_status == 10 and speak_timer < 0.1 then set(fishka_11, 0) end

	---------------------------------
	-- question 5. Fuel --
	---------------------------------
	if stage == 5 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["fuel_quantity"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		local DH = interpolate(angle2alt, get(radioalt_dh_left))
		--[[
		-- false answer
		if stage_status == 1 and get(mars_on) ~= 1 and DH < 400 then
			-- say false answer once
			stage_status = 2
		end
		-=]]
		-- true answer
		if (stage_status == 1 or stage_status == 2) then
			
			eng_say_num(math.floor(get(fuel_meter_summ) * 0.001 + 0.5), 2, lang)
			
			local num = find_empty()
			phrases_tbl[num] = {eng_tbl["tonns"][lang], 1}
			
			speak_timer = 4
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 12
	if stage == 5 and stage_status == 10 and speak_timer < 0.1 then set(fishka_12, 0) end

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