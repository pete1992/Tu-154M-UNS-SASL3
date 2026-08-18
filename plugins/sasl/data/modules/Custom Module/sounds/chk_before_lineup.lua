-- this is before lineup checklist
defineProperty("frame_time", globalPropertyf("tu154/custom/time/frame_time")) -- time of frame

defineProperty("side",globalPropertyi("tu154/custom/checklist/side")) --   . 0 -  , 1 -  

defineProperty("fishka_1",globalPropertyi("tu154/custom/checklist/fishka_1")) --  . 0 - , 1 - 
defineProperty("fishka_2",globalPropertyi("tu154/custom/checklist/fishka_2")) --  . 0 - , 1 - 
defineProperty("fishka_3",globalPropertyi("tu154/custom/checklist/fishka_3")) --  . 0 - , 1 - 
defineProperty("fishka_4",globalPropertyi("tu154/custom/checklist/fishka_4")) --  . 0 - , 1 - 
defineProperty("fishka_5",globalPropertyi("tu154/custom/checklist/fishka_5")) --  . 0 - , 1 - 
defineProperty("fishka_6",globalPropertyi("tu154/custom/checklist/fishka_6")) --  . 0 - , 1 - 
defineProperty("fishka_7",globalPropertyi("tu154/custom/checklist/fishka_7")) --  . 0 - , 1 - 
defineProperty("fishka_8",globalPropertyi("tu154/custom/checklist/fishka_8")) --  . 0 - , 1 - 
defineProperty("fishka_9",globalPropertyi("tu154/custom/checklist/fishka_9")) --  . 0 - , 1 - 
defineProperty("fishka_10",globalPropertyi("tu154/custom/checklist/fishka_10")) --  . 0 - , 1 - 
defineProperty("fishka_11",globalPropertyi("tu154/custom/checklist/fishka_11")) --  . 0 - , 1 - 
defineProperty("fishka_12",globalPropertyi("tu154/custom/checklist/fishka_12")) --  . 0 - , 1 - 
defineProperty("fishka_13",globalPropertyi("tu154/custom/checklist/fishka_13")) --  . 0 - , 1 - 
defineProperty("fishka_14",globalPropertyi("tu154/custom/checklist/fishka_14")) --  . 0 - , 1 - 
defineProperty("fishka_15",globalPropertyi("tu154/custom/checklist/fishka_15")) --  . 0 - , 1 - 
defineProperty("fishka_16",globalPropertyi("tu154/custom/checklist/fishka_16")) --  . 0 - , 1 - 
defineProperty("fishka_17",globalPropertyi("tu154/custom/checklist/fishka_17")) --  . 0 - , 1 - 
defineProperty("fishka_18",globalPropertyi("tu154/custom/checklist/fishka_18")) --  . 0 - , 1 - 
defineProperty("fishka_19",globalPropertyi("tu154/custom/checklist/fishka_19")) --  . 0 - , 1 - 
defineProperty("fishka_20",globalPropertyi("tu154/custom/checklist/fishka_20")) --  . 0 - , 1 - 

defineProperty("checklist_selected",globalPropertyi("tu154/custom/checklist/checklist_selected")) --  

-- sources

defineProperty("vbe_pressure", globalPropertyf("tu154/custom/gauges/alt/vbe_press_left"))  -- pressure in hPa
defineProperty("vbe_on_1", globalPropertyi("tu154/custom/switchers/ovhd/vbe_1_on"))
defineProperty("vbe_on_2", globalPropertyi("tu154/custom/switchers/ovhd/vbe_2_on"))

defineProperty("rv_flag_1", globalPropertyf("tu154/custom/gauges/alt/radioalt_flag_left"))  -- RV flag
defineProperty("rv_flag_2", globalPropertyf("tu154/custom/gauges/alt/radioalt_flag_right"))  -- RV flag

defineProperty("stab_ind", globalPropertyf("tu154/custom/gauges/misc/stab_ind")) --   
defineProperty("elevator_ind", globalPropertyf("tu154/custom/gauges/misc/elevator_ind")) --   
defineProperty("flap_left_ind", globalPropertyf("tu154/custom/gauges/misc/flap_left_ind")) --   
defineProperty("flap_right_ind", globalPropertyf("tu154/custom/gauges/misc/flap_right_ind")) --   
defineProperty("slats_extended", globalPropertyf("tu154/custom/lights/slats_extended")) --  

defineProperty("to_rudder", globalPropertyf("tu154/custom/lights/to_rudder")) -- - 
defineProperty("to_elevator", globalPropertyf("tu154/custom/lights/to_elevator")) -- - 

defineProperty("spoilers_mid_left", globalPropertyf("tu154/custom/lights/spoilers_mid_left")) --   
defineProperty("spoilers_mid_right", globalPropertyf("tu154/custom/lights/spoilers_mid_right")) --   
defineProperty("spoilers_inn_left", globalPropertyf("tu154/custom/lights/spoilers_inn_left")) --   
defineProperty("spoilers_inn_right", globalPropertyf("tu154/custom/lights/spoilers_inn_right")) --   

defineProperty("mgv_contr_fail", globalPropertyi("tu154/custom/bkk/mgv_contr_fail")) --    -   
defineProperty("pkp_fail_left", globalPropertyi("tu154/custom/bkk/pkp_fail_left")) --    -   
defineProperty("pkp_fail_right", globalPropertyi("tu154/custom/bkk/pkp_fail_right")) --    -   	
defineProperty("pitch_corr_hdl_1", globalPropertyf("tu154/custom/gauges/ahz/pitch_corr_L")) --     + 
defineProperty("pitch_corr_hdl_2", globalPropertyf("tu154/custom/gauges/ahz/pitch_corr_R")) --     + 

defineProperty("cockpit_window_left", globalPropertyf("tu154/custom/anim/cockpit_window_left")) --  
defineProperty("cockpit_window_right", globalPropertyf("tu154/custom/anim/cockpit_window_right")) --  

defineProperty("apu_rpm", globalPropertyf("tu154/custom/gauges/eng/apu_rpm")) --  . 0-100%
defineProperty("fuel_level", globalPropertyi("tu154/custom/switchers/fuel/fuel_level")) --  
defineProperty("fuel_flow_mode", globalPropertyi("tu154/custom/switchers/fuel/fuel_flow_mode")) --   .  - 
defineProperty("fuel_flow_on", globalPropertyi("tu154/custom/switchers/fuel/fuel_flow_on")) --  

local checklist_started = false
local stage = 0
local stage_status = 0 -- 0 question, 1+ - answers. 1 usually is false.

local speak_timer = 0

function checklist_4()

	--local passed = get(frame_time)
	
	--print(checklist_started)
	
	-- start the checklist
	if not checklist_started and get(checklist_selected) == 4 then 
		checklist_started = true 
		stage = 1
		
		-- declare checklist
		local num = find_empty()
		phrases_tbl[num] = {nav_tbl["before_lineup"][lang], 2}
		speak_timer = 2
		
	end
	
	-- another checklist started
	if get(checklist_selected) ~= 4 then 
		checklist_started = false
		stage = 0
		stage_status = 0 
	end
	
	-- move stages
	if checklist_started then
		if stage == 1 and get(fishka_4) == 1 then stage = 2 stage_status = 0 end -- move further if cap is closed
		if stage == 2 and get(fishka_5) == 1 then stage = 3 stage_status = 0 end -- move further if cap is closed
		if stage == 3 and get(fishka_6) == 1 then stage = 4 stage_status = 0 end -- move further if cap is closed
		if stage == 4 and get(fishka_7) == 1 then stage = 5 stage_status = 0 end -- move further if cap is closed
		if stage == 5 and get(fishka_8) == 1 then stage = 6 stage_status = 0 end -- move further if cap is closed
		if stage == 6 and get(fishka_9) == 1 then stage = 7 stage_status = 0 end -- move further if cap is closed
		if stage == 7 and get(fishka_10) == 1 then stage = 8 stage_status = 0 end -- move further if cap is closed
		if stage == 8 and get(fishka_11) == 1 then stage = 9 stage_status = 0 end -- move further if cap is closed
		if stage == 9 and get(fishka_12) == 1 then 
			stage = 100 stage_status = 0 
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["checklist_completed"][lang], 2}
		end -- end checklist
	end
	
	------------------------------
	-- question 1. Altimeters --
	---------------------------------
	if stage == 1 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["altimeters"][lang], 1}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and get(vbe_on_1) * get(vbe_on_2) * (1 - get(rv_flag_1)) * (1 - get(rv_flag_2)) == 0 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(vbe_on_1) * get(vbe_on_2) * (1 - get(rv_flag_1)) * (1 - get(rv_flag_2)) == 1 then
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["pressure"][lang], 1}
			cop_say_num(get(vbe_pressure), 4, lang)
			phrases_tbl[num+5] = {cop_tbl["rv_on"][lang], 2}
			
			speak_timer = 5
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 4
	if stage == 1 and stage_status == 10 and speak_timer < 0.1 then set(fishka_4, 1) end

	------------------------------
	-- question 2. Flaps and slats --
	---------------------------------
	if stage == 2 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["flaps"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (get(flap_left_ind) < 13 or get(flap_right_ind) < 13 or get(flap_left_ind) > 30 or get(flap_right_ind) > 30 or get(slats_extended) == 0) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(flap_left_ind) > 13 and get(flap_right_ind) > 13 and get(flap_left_ind) < 30 and get(flap_right_ind) < 30 and get(slats_extended) > 0.1 then
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["ext_tablo_lit"][lang], 2}

			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 5
	if stage == 2 and stage_status == 10 and speak_timer < 0.1 then set(fishka_5, 1) end	
	
	------------------------------
	-- question 3. Stab --
	---------------------------------
	if stage == 3 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["stabilizer"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and get(stab_ind) > 3.1 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(stab_ind) < 3.1 then
			local num = find_empty()
			if get(stab_ind) < 0.1 then phrases_tbl[num] = {cop_tbl["stab_0"][lang], 2}
			elseif get(stab_ind) > 2.5 then phrases_tbl[num] = {cop_tbl["stab_3"][lang], 2}
			else phrases_tbl[num] = {cop_tbl["stab_15"][lang], 2} 
			end

			speak_timer = 3
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 6
	if stage == 3 and stage_status == 10 and speak_timer < 0.1 then set(fishka_6, 1) end	
	
	------------------------------
	-- question 4. Control forces --
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
	
	-- move fishka 7
	if stage == 4 and stage_status == 10 and speak_timer < 0.1 then set(fishka_7, 1) end	
	
	------------------------------
	-- question 5. Spoilers --
	---------------------------------
	if stage == 5 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["speed_br"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and get(spoilers_mid_left) + get(spoilers_mid_right) + get(spoilers_inn_left) + get(spoilers_inn_right) > 0.1 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(spoilers_mid_left) + get(spoilers_mid_right) + get(spoilers_inn_left) + get(spoilers_inn_right) < 0.1 then
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["removed_lights_off"][lang], 3}

			speak_timer = 4
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 8
	if stage == 5 and stage_status == 10 and speak_timer < 0.1 then set(fishka_8, 1) end	
	
	------------------------------
	-- question 6. AHZ --
	---------------------------------
	if stage == 6 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["air_horizons"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
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
			phrases_tbl[num] = {cop_tbl["chk_lines_up"][lang], 2}
			phrases_tbl[num+1] = {cpt_tbl["check_lines_fit"][lang], 2}
			
			speak_timer = 5
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 9
	if stage == 6 and stage_status == 10 and speak_timer < 0.1 then set(fishka_9, 1) end	
	
	------------------------------
	-- question 7. Windows --
	---------------------------------
	if stage == 7 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["vents"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and get(cockpit_window_left) + get(cockpit_window_right) > 0 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(cockpit_window_left) + get(cockpit_window_right) == 0 then
			local num = find_empty()
			phrases_tbl[num] = {cop_tbl["closed"][lang], 2}
			phrases_tbl[num+1] = {cpt_tbl["closed"][lang], 2}
			
			speak_timer = 5
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 10
	if stage == 7 and stage_status == 10 and speak_timer < 0.1 then set(fishka_10, 1) end

	------------------------------
	-- question 8. Controls --
	---------------------------------
	if stage == 8 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["rudders_ailerons"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and (not v_var["ail_chk"] or not v_var["elev_chk"]) then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and v_var["ail_chk"] and v_var["elev_chk"] then
			local num = find_empty()
			phrases_tbl[num] = {cpt_tbl["check_free"][lang], 2}

			speak_timer = 2
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 11
	if stage == 8 and stage_status == 10 and speak_timer < 0.1 then set(fishka_11, 1) end

	------------------------------
	-- question 9. APU, Fuel system --
	---------------------------------
	if stage == 9 and speak_timer == 0 then
		
		-- ask question
		if stage_status == 0 then
			local num = find_empty()
			phrases_tbl[num] = {nav_tbl["VSU_fuel_sis"][lang], 2}
	
			stage_status = 1 -- question asked
			speak_timer = 2 -- set up time before answer
		end
		
		-- false answer
		if stage_status == 1 and get(fuel_level) * get(fuel_flow_mode) * get(fuel_flow_on) == 0 then
			-- say false answer once
			local num = find_empty()
			phrases_tbl[num] = {eng_tbl["fail_"..math.random(1,5)][lang], 1}
			speak_timer = 1
			stage_status = 2
		end
		
		-- true answer
		if (stage_status == 1 or stage_status == 2) and get(fuel_level) * get(fuel_flow_mode) * get(fuel_flow_on) == 1 then
			local num = find_empty()
			if get(apu_rpm) < 90 then phrases_tbl[num] = {eng_tbl["off"][lang], 1}
			else phrases_tbl[num] = {eng_tbl["on"][lang], 1} end
			
			phrases_tbl[num+1] = {eng_tbl["auto"][lang], 1}
			
			speak_timer = 2
			stage_status = 10 -- finish
		end
		
	end
	
	-- move fishka 12
	if stage == 9 and stage_status == 10 and speak_timer < 0.1 then set(fishka_12, 1) end

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