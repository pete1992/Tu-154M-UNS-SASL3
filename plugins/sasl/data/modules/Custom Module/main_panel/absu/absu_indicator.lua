-- this is the ABSU indicators

-- sources
defineProperty("absu_contr_pitch", globalPropertyf("tu154/custom/absu/contr_pitch")) --   56  
defineProperty("absu_contr_roll", globalPropertyf("tu154/custom/absu/contr_roll")) --   56  
defineProperty("absu_contr_yaw", globalPropertyf("tu154/custom/absu/contr_yaw")) --   56  
defineProperty("int_pitch_trim", globalPropertyf("tu154/custom/trimmers/int_pitch_trim")) --    
defineProperty("gear1_deflect", globalProperty("sim/flightmodel2/gear/tire_vertical_deflection_mtr[0]"))  -- vertical deflection of front gear
-- results
defineProperty("rudder_pos_ind", globalPropertyf("tu154/custom/gauges/misc/rudder_pos_ind")) --   
defineProperty("aileron_pos_ind", globalPropertyf("tu154/custom/gauges/misc/aileron_pos_ind")) --   
defineProperty("elevator_pos_ind", globalPropertyf("tu154/custom/gauges/misc/elevator_pos_ind")) --   

function update()
	set(rudder_pos_ind, get(absu_contr_yaw) / 0.4)
	set(aileron_pos_ind, get(absu_contr_roll) / 0.4)
	set(elevator_pos_ind, get(absu_contr_pitch) / 0.4)
	if get(gear1_deflect) > 0.01 and get(int_pitch_trim) < -0.5 then set(elevator_pos_ind, -get(absu_contr_pitch) / 0.4) end
end
