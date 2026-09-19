-- chk_before_taxi.lua
-- this is before taxi checklist
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
    { "gen_1_on", "tu154/custom/switchers/eng/gen_1_on", globalPropertyi }, --   1. -1 - , 0 - , +1 -
    { "gen_2_on", "tu154/custom/switchers/eng/gen_2_on", globalPropertyi }, --   1. -1 - , 0 - , +1 -
    { "gen_3_on", "tu154/custom/switchers/eng/gen_3_on", globalPropertyi }, --   1. -1 - , 0 - , +1 -

    { "bat1_on", "tu154/custom/switchers/eng/bat1_on", globalPropertyi }, --  1
    { "bat2_on", "tu154/custom/switchers/eng/bat2_on", globalPropertyi }, --  2
    { "bat3_on", "tu154/custom/switchers/eng/bat3_on", globalPropertyi }, --  3
    { "bat4_on", "tu154/custom/switchers/eng/bat4_on", globalPropertyi }, --  4

    { "gen_fail_1", "tu154/custom/lights/small/gen_fail_1", globalPropertyf }, --
    { "gen_fail_2", "tu154/custom/lights/small/gen_fail_2", globalPropertyf }, --
    { "gen_fail_3", "tu154/custom/lights/small/gen_fail_3", globalPropertyf }, --

    { "left_bus_use_bat", "tu154/custom/lights/small/left_bus_use_bat", globalPropertyf }, --
    { "right_bus_use_bat", "tu154/custom/lights/small/right_bus_use_bat", globalPropertyf }, --

    { "sard_cabin_press_set", "tu154/custom/switchers/sard/sard_cabin_press_set", globalPropertyf }, --
    { "skv_bleed_fail_1", "tu154/custom/lights/small/skv_bleed_fail_1", globalPropertyf }, --
    { "skv_bleed_fail_2", "tu154/custom/lights/small/skv_bleed_fail_2", globalPropertyf }, --
    { "skv_bleed_fail_3", "tu154/custom/lights/small/skv_bleed_fail_3", globalPropertyf }, --

    { "skv_bleed_closed_1", "tu154/custom/lights/small/skv_bleed_closed_1", globalPropertyf }, --
    { "skv_bleed_closed_2", "tu154/custom/lights/small/skv_bleed_closed_2", globalPropertyf }, --
    { "skv_bleed_closed_3", "tu154/custom/lights/small/skv_bleed_closed_3", globalPropertyf }, --

    { "nvu_on_lit", "tu154/custom/lights/small/nvu_on", globalPropertyf }, --

    { "nav1_pow_cc", "tu154/custom/radio/nav1_pow_cc", globalPropertyf },
    { "nav2_pow_cc", "tu154/custom/radio/nav2_pow_cc", globalPropertyf },

    { "ark15_L_cc", "tu154/custom/radio/ark15_L_cc", globalPropertyf }, --
    { "ark15_R_cc", "tu154/custom/radio/ark15_R_cc", globalPropertyf }, --

    { "xpdr_mode", "sim/cockpit/radios/transponder_mode", globalPropertyf },

    -- { "buster_on_1", "tu154/custom/switchers/console/buster_on_1", globalPropertyi }, --
    -- { "buster_on_2", "tu154/custom/switchers/console/buster_on_2", globalPropertyi }, --
    -- { "buster_on_3", "tu154/custom/switchers/console/buster_on_3", globalPropertyi }, --
    { "busters_cap", "tu154/custom/switchers/console/busters_cap", globalPropertyi }, --
    { "contr_force_set", "tu154/custom/controll/contr_force_set", globalPropertyi }, --    . -1 - , 0 , +1 - -

    { "mgv_contr_fail", "tu154/custom/bkk/mgv_contr_fail", globalPropertyi }, --    -
    { "pkp_fail_left", "tu154/custom/bkk/pkp_fail_left", globalPropertyi }, --    -
    { "pkp_fail_right", "tu154/custom/bkk/pkp_fail_right", globalPropertyi }, --    -
    { "pitch_corr_hdl_1", "tu154/custom/gauges/ahz/pitch_corr_L", globalPropertyf }, --     +
    { "pitch_corr_hdl_2", "tu154/custom/gauges/ahz/pitch_corr_R", globalPropertyf }, --     +

    { "course_ga_1", "tu154/custom/tks/course_ga_1", globalPropertyf }, --   1
    { "course_ga_2", "tu154/custom/tks/course_ga_2", globalPropertyf }, --   2
    { "course_bgmk_1", "tu154/custom/tks/course_bgmk_1", globalPropertyf }, --   1
    { "course_bgmk_2", "tu154/custom/tks/course_bgmk_2", globalPropertyf }, --   2

    { "absu_work", "tu154/custom/lights/absu_work", globalPropertyf }, --
    { "absu_roll_mode", "tu154/custom/gauges/console/absu_roll_mode", globalPropertyi }, --   . 0 - , 1 - , 2 -
    { "absu_pitch_mode", "tu154/custom/gauges/console/absu_pitch_mode", globalPropertyi }, --   . 0 - , 1 - , 2 -

    { "window_heat_1", "tu154/custom/switchers/ovhd/window_heat_1", globalPropertyi }, --  . -1 - , 0 - , 1 -
    { "window_heat_2", "tu154/custom/switchers/ovhd/window_heat_2", globalPropertyi }, --  . -1 - , 0 - , 1 -
    { "window_heat_3", "tu154/custom/switchers/ovhd/window_heat_3", globalPropertyi }, --  . -1 - , 0 - , 1 -
})

local checklist_started = false
local stage = 0
local stage_status = 0 -- 0 question, 1+ - answers. 1 usually is false.

local speak_timer = 0

function checklist_2()

	--local passed = get(frame_time)
	
	--print(checklist_started)
	
	-- start the checklist
	if not checklist_started and get(checklist_selected) == 2 then 
		checklist_started = true 
		stage = 1
		
		-- declare checklist
		local num = find_empty()
		phrases_tbl[num] = {nav_tbl["before_taxiing"][lang], 2}
		speak_timer = 2
		
	end
	
	-- another checklist started
	if get(checklist_selected) ~= 2 then 
		checklist_started = false
		stage = 0
		stage_status = 0 
	end

	-- move stages
	if checklist_started then
		if stage == 1 and get(fishka_11) == 0 then stage = 2 stage_status = 0 end -- move further if cap is closed
		if stage == 2 and get(fishka_12) == 0 then stage = 3 stage_status = 0 end -- move further if cap is closed
		if stage == 3 and get(fishka_13) == 0 then stage = 4 stage_status = 0 end -- move further if cap is closed
		if stage == 4 and get(fishka_14) == 0 then stage = 5 stage_status = 0 end -- move further if cap is closed
		if stage == 5 and get(fishka_15) == 0 then stage = 6 stage_status = 0 end -- move further if cap is closed
		if stage == 6 and get(fishka_16) == 0 then stage = 7 stage_status = 0 end -- move further if cap is closed
		if stage == 7 and get(fishka_17) == 0 then stage = 8 stage_status = 0 end -- move further if cap is closed
		if stage == 8 and get(fishka_18) == 0 then stage = 9 stage_status = 0 end -- move further if cap is closed
		if stage == 9 and get(fishka_19) == 0 then stage = 10 stage_status = 0 end -- move further if cap is closed
		if stage == 10 and get(fishka_20) == 0 then 
			stage = 100 stage_status = 0 
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["checklist_completed"][lang], 2}
		end -- end checklist
	end

	------------------------------
	-- question 1. Electric system --
	---------------------------------
	if stage == 1 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["elektro_system"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (get(gen_1_on) + get(gen_2_on) + get(gen_3_on) ~= 3 or get(bat1_on) + get(bat2_on) + get(bat3_on) + get(bat4_on) ~= 4
			or get(gen_fail_1) + get(gen_fail_2) + get(gen_fail_3) > 0 or get(left_bus_use_bat) + get(right_bus_use_bat) > 0) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {eng_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(gen_1_on) + get(gen_2_on) + get(gen_3_on) == 3 and get(bat1_on) + get(bat2_on) + get(bat3_on) + get(bat4_on) == 4
			and get(gen_fail_1) + get(gen_fail_2) + get(gen_fail_3) == 0 and get(left_bus_use_bat) + get(right_bus_use_bat) == 0 then
			local num = find_empty()
			phrases_tbl[num] = {eng_tbl["chk_on"][lang], 2}
			
			speak_timer = 2
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 11
	if stage == 1 and stage_status == 10 and speak_timer < 0.1 then set(fishka_11, 0) end	
	
	------------------------------
	-- question 2. SRD --
	---------------------------------
	if stage == 2 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["SRD"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 3 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (math.abs(get(sard_cabin_press_set) - 650) > 10 or get(skv_bleed_fail_1) + get(skv_bleed_fail_2) + get(skv_bleed_fail_3) +
			get(skv_bleed_closed_1) + get(skv_bleed_closed_2) + get(skv_bleed_closed_3) > 0) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {eng_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and math.abs(get(sard_cabin_press_set) - 650) <= 10 and get(skv_bleed_fail_1) + get(skv_bleed_fail_2) + get(skv_bleed_fail_3) +
			get(skv_bleed_closed_1) + get(skv_bleed_closed_2) + get(skv_bleed_closed_3) == 0 then
			local num = find_empty()
			phrases_tbl[num] = {eng_tbl["press_650_set"][lang], 3}
			
			speak_timer = 4
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 12
	if stage == 2 and stage_status == 10 and speak_timer < 0.1 then set(fishka_12, 0) end	
	
	------------------------------
	-- question 3. NAV complex --
	---------------------------------
	if stage == 3 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["navigation_complex"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 3 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and get(nvu_on_lit) == 0 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(nvu_on_lit) > 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["switch_on"][lang], 2}
			
			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 13
	if stage == 3 and stage_status == 10 and speak_timer < 0.1 then set(fishka_13, 0) end	
	
	------------------------------
	-- question 4. CoursMP, NDB --
	---------------------------------
	if stage == 4 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["course_mp_ark"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 3 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and get(nvu_on_lit) == 0 and (get(nav1_pow_cc) == 0 or get(nav2_pow_cc) == 0 or get(ark15_L_cc) == 0 or get(ark15_R_cc) == 0) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(nav1_pow_cc) > 0 and get(nav2_pow_cc) > 0 and get(ark15_L_cc) > 0 and get(ark15_R_cc) > 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["switch_on_1"][lang], 2}
			
			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 14
	if stage == 4 and stage_status == 10 and speak_timer < 0.1 then set(fishka_14, 0) end		
	
	------------------------------
	-- question 5. SQUAWK --
	---------------------------------
	if stage == 5 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["UVD"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 3 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and get(xpdr_mode) == 0 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(xpdr_mode) > 0 then
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["turned_on"][lang], 2}
			
			speak_timer = 2
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 15
	if stage == 5 and stage_status == 10 and speak_timer < 0.1 then set(fishka_15, 0) end	
	
	---------------------------------
	-- question 6. Busters --
	---------------------------------
	if stage == 6 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["booster"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 3 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (get(busters_cap) == 1 or get(contr_force_set) ~= 0) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(busters_cap) == 0 and get(contr_force_set) == 0 then
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["turned_on_cap_closed_auto"][lang], 3}
			
			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 16
	if stage == 6 and stage_status == 10 and speak_timer < 0.1 then set(fishka_16, 0) end		
	
	---------------------------------
	-- question 7. Horizons --
	---------------------------------
	if stage == 7 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["air_horizons"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 3 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (get(mgv_contr_fail) == 1 or get(pkp_fail_left) == 1 or get(pkp_fail_right) == 1 or
			math.abs(get(pitch_corr_hdl_1)) > 0.1 or math.abs(get(pitch_corr_hdl_2)) > 0.1) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(mgv_contr_fail) == 0 and get(pkp_fail_left) == 0 and get(pkp_fail_right) == 0 and
			math.abs(get(pitch_corr_hdl_1)) < 0.1 and math.abs(get(pitch_corr_hdl_2)) < 0.1 then
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["check_lines_fit"][lang], 2}
			phrases_tbl[num+1] = {cop_tbl["chk_lines_up"][lang], 2}
			
			speak_timer = 5
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 17
	if stage == 7 and stage_status == 10 and speak_timer < 0.1 then set(fishka_17, 0) end	

	---------------------------------
	-- question 8. TKS --
	---------------------------------
	if stage == 8 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["TKS"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 3 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (math.abs(get(course_ga_1) - get(course_ga_2)) >= 0.5 or math.abs(get(course_bgmk_1) - get(course_bgmk_2)) >= 0.5) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and math.abs(get(course_ga_1) - get(course_ga_2)) < 0.5 and math.abs(get(course_bgmk_1) - get(course_bgmk_2)) < 0.5 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["switch_on_agreed"][lang], 3}
			
			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 18
	if stage == 8 and stage_status == 10 and speak_timer < 0.1 then set(fishka_18, 0) end

	---------------------------------
	-- question 9. ABSU --
	---------------------------------
	if stage == 9 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["ABSU"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 3 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (get(absu_work) == 0 or get(absu_roll_mode) ~= 1 or get(absu_pitch_mode) ~= 1) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {eng_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(absu_work) == 1 and get(absu_roll_mode) == 1 and get(absu_pitch_mode) == 1 then
			local num = find_empty()
			phrases_tbl[num] = {eng_tbl["absu_ok"][lang], 3}
			
			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 19
	if stage == 9 and stage_status == 10 and speak_timer < 0.1 then set(fishka_19, 0) end

	---------------------------------
	-- question 10. Deicers --
	---------------------------------
	if stage == 10 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["deicing"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 3 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (get(window_heat_1) + get(window_heat_2) + get(window_heat_3) > -3) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(window_heat_1) + get(window_heat_2) + get(window_heat_3) == -3 then
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["turned_on_2"][lang], 1}
			
			speak_timer = 2
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 19
	if stage == 10 and stage_status == 10 and speak_timer < 0.1 then set(fishka_20, 0) end	
	
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

end