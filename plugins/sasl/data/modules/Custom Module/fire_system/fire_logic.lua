-- fire_logic.lua
-- this is fire system's logic

-- sim variables
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
    { "sim_engine_on_fire1", "sim/operation/failures/rel_engfir0", globalPropertyi },  -- left engine on fire
    { "sim_engine_on_fire2", "sim/operation/failures/rel_engfir1", globalPropertyi },  -- mid engine on fire
    { "sim_engine_on_fire3", "sim/operation/failures/rel_engfir2", globalPropertyi },  -- right engine on fire

    { "sim_engine_ext1", "sim/cockpit2/engine/actuators/fire_extinguisher_on[0]", globalProperty },  -- left engine fire extinguiher
    { "sim_engine_ext2", "sim/cockpit2/engine/actuators/fire_extinguisher_on[1]", globalProperty },  -- mid engine fire extinguiher
    { "sim_engine_ext3", "sim/cockpit2/engine/actuators/fire_extinguisher_on[2]", globalProperty },  -- right engine fire extinguiher

    -- controls
    -- { "lamp_test", "tu154/custom/buttons/lamp_test_fire_panel", globalPropertyi }, --      	0
    { "smoke_test", "tu154/custom/buttons/eng/smoke_test", globalPropertyi }, --
    -- { "ext_test", "tu154/custom/buttons/eng/ext_test", globalPropertyi }, --

    { "fire_ext_1", "tu154/custom/buttons/eng/fire_ext_1", globalPropertyi }, --
    { "fire_ext_2", "tu154/custom/buttons/eng/fire_ext_2", globalPropertyi }, --
    { "fire_ext_3", "tu154/custom/buttons/eng/fire_ext_3", globalPropertyi }, --
    { "cold_eng_1", "tu154/custom/buttons/eng/cold_eng_1", globalPropertyi }, --
    { "cold_eng_2", "tu154/custom/buttons/eng/cold_eng_2", globalPropertyi }, --
    { "cold_eng_3", "tu154/custom/buttons/eng/cold_eng_3", globalPropertyi }, --
    { "cold_apu", "tu154/custom/buttons/eng/cold_apu", globalPropertyi }, --
    { "neutral_gas", "tu154/custom/buttons/eng/neutral_gas", globalPropertyi }, --

    -- { "fire_sensor_sel", "tu154/custom/switchers/eng/fire_sensor_sel", globalPropertyi }, --
    -- { "fire_place_sel", "tu154/custom/switchers/eng/fire_place_sel", globalPropertyi }, --

    { "fire_main_switch", "tu154/custom/switchers/eng/fire_main_switch", globalPropertyi }, --
    { "fire_buzzer", "tu154/custom/switchers/eng/fire_buzzer", globalPropertyi }, --

    -- power
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },

    { "fire_sys_cc", "tu154/custom/fire/fire_sys_cc", globalPropertyf }, --

    -- results
    { "ext_used_1", "tu154/custom/fire/ext_used_1", globalPropertyi }, --
    { "ext_used_2", "tu154/custom/fire/ext_used_2", globalPropertyi }, --
    { "ext_used_3", "tu154/custom/fire/ext_used_3", globalPropertyi }, --

    { "ng_used", "tu154/custom/fire/ng_used", globalPropertyi }, --

    { "valve_open_1", "tu154/custom/fire/valve_open_1", globalPropertyi }, --    1
    { "valve_open_2", "tu154/custom/fire/valve_open_2", globalPropertyi }, --    2
    { "valve_open_3", "tu154/custom/fire/valve_open_3", globalPropertyi }, --    3
    { "valve_open_4", "tu154/custom/fire/valve_open_4", globalPropertyi }, --

    { "engine_fire_state_1", "tu154/custom/fire/engine_fire_state_1", globalPropertyi }, --  . 0 - , 1 - , 2 -
    { "engine_fire_state_2", "tu154/custom/fire/engine_fire_state_2", globalPropertyi }, --  . 0 - , 1 - , 2 -
    { "engine_fire_state_3", "tu154/custom/fire/engine_fire_state_3", globalPropertyi }, --  . 0 - , 1 - , 2 -
    { "engine_fire_state_4", "tu154/custom/fire/engine_fire_state_4", globalPropertyi }, --  . 0 - , 1 - , 2 -

    { "fire_detected", "tu154/custom/fire/fire_detected", globalPropertyi }, --

    { "fire_siren", "tu154/custom/fire/fire_siren", globalPropertyi }, --

    { "fire_vlv_open_1", "tu154/custom/fuel/fire_vlv_open_1", globalPropertyf }, --
    { "fire_vlv_open_2", "tu154/custom/fuel/fire_vlv_open_2", globalPropertyf }, --
    { "fire_vlv_open_3", "tu154/custom/fuel/fire_vlv_open_3", globalPropertyf }, --

    -- { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time

    -- Smart Copilot
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- Master. 0 = plugin not found, 1 = slave 2 = master
    -- { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- Have control. 0 = plugin not found, 1 = no control 2 = has control
})

local valve_1 = get(valve_open_1)
local valve_2 = get(valve_open_2)
local valve_3 = get(valve_open_3)
local valve_4 = get(valve_open_4)

local valves_open = 0 -- open valves counter

set(sim_engine_ext1, 0)
set(sim_engine_ext2, 0)
set(sim_engine_ext3, 0)

function update()

local MASTER = get(ismaster) ~= 1	
	
if MASTER then	

	local power27L = get(bus27_volt_left) > 13
	local power27R = get(bus27_volt_right) > 13
	
	if power27L and get(fire_main_switch) == 1 then
		
		-- set destination manually
		if get(cold_eng_1) == 1 then valve_1 = 1 end
		if get(cold_eng_2) == 1 then valve_2 = 1 end
		if get(cold_eng_3) == 1 then valve_3 = 1 end
		if get(cold_apu) == 1 then valve_4 = 1 end
		
		-- set destination automatically
		local fire_1 = get(sim_engine_on_fire1) == 6
		local fire_2 = get(sim_engine_on_fire2) == 6
		local fire_3 = get(sim_engine_on_fire3) == 6
		
		if fire_1 then valve_1 = 1 end
		if fire_2 then valve_2 = 1 end
		if fire_3 then valve_3 = 1 end
		
		-- use neutral gas
		if get(neutral_gas) == 1 then set(ng_used, 1) end
		
		-- extinguishers work
		valves_open = valve_1 + valve_2 + valve_3 + valve_4
		
		local ext_1_ready = get(ext_used_1) == 0
		local ext_2_ready = get(ext_used_2) == 0
		local ext_3_ready = get(ext_used_3) == 0
		
		local fire_1_but = get(fire_ext_1) == 1
		local fire_2_but = get(fire_ext_2) == 1
		local fire_3_but = get(fire_ext_3) == 1
		
		-- engine 1
		if valve_1 == 1 then
			if ext_1_ready and (get(fire_vlv_open_1) < 0.5 or fire_1_but)then -- automatically use ext 1 or by button
				set(ext_used_1, 1) -- use extinguisher
				set(sim_engine_ext1, 1)
				if math.random() < 0.98 / valves_open then 
					set(sim_engine_on_fire1, 0) -- remove fire fail
				end
			end
			
			if ext_2_ready and fire_2_but then -- use ext 2
				set(ext_used_2, 1) -- use extinguisher
				set(sim_engine_ext1, 1)
				if math.random() < 0.98 / valves_open then 
					set(sim_engine_on_fire1, 0) -- remove fire fail
				end
			end

			if ext_3_ready and fire_3_but then -- use ext 3
				set(ext_used_3, 1) -- use extinguisher
				set(sim_engine_ext1, 1)
				if math.random() < 0.98 / valves_open then 
					set(sim_engine_on_fire1, 0) -- remove fire fail
				end
			end
			
		end

		-- engine 2
		if valve_2 == 1 then
			if ext_1_ready and (get(fire_vlv_open_2) < 0.5 or fire_1_but)then -- automatically use ext 1 or by button
				set(ext_used_1, 1) -- use extinguisher
				set(sim_engine_ext2, 1)
				if math.random() < 0.98 / valves_open then 
					set(sim_engine_on_fire2, 0) -- remove fire fail
				end
			end
			
			if ext_2_ready and fire_2_but then -- use ext 2
				set(ext_used_2, 1) -- use extinguisher
				set(sim_engine_ext2, 1)
				if math.random() < 0.98 / valves_open then 
					set(sim_engine_on_fire2, 0) -- remove fire fail
				end
			end

			if ext_3_ready and fire_3_but then -- use ext 3
				set(ext_used_3, 1) -- use extinguisher
				set(sim_engine_ext2, 1)
				if math.random() < 0.98 / valves_open then 
					set(sim_engine_on_fire2, 0) -- remove fire fail
				end
			end
			
		end		

		-- engine 3
		if valve_3 == 1 then
			if ext_1_ready and (get(fire_vlv_open_3) < 0.5 or fire_1_but)then -- automatically use ext 1 or by button
				set(ext_used_1, 1) -- use extinguisher
				set(sim_engine_ext3, 1)
				if math.random() < 0.98 / valves_open then 
					set(sim_engine_on_fire3, 0) -- remove fire fail
				end
			end
			
			if ext_2_ready and fire_2_but then -- use ext 2
				set(ext_used_2, 1) -- use extinguisher
				set(sim_engine_ext3, 1)
				if math.random() < 0.98 / valves_open then 
					set(sim_engine_on_fire3, 0) -- remove fire fail
				end
			end

			if ext_3_ready and fire_3_but then -- use ext 3
				set(ext_used_3, 1) -- use extinguisher
				set(sim_engine_ext3, 1)
				if math.random() < 0.98 / valves_open then 
					set(sim_engine_on_fire3, 0) -- remove fire fail
				end
			end
			
		end	
		
		-- same way for APU
		
		-- fire siren
		if fire_1 or fire_2 or fire_3 or get(smoke_test) == 1 then
			set(fire_detected, 1)
			set(fire_siren, get(fire_buzzer))
		
		else
			set(fire_detected, 0)
			set(fire_siren, 0)
		end
		
		if fire_1 then set(engine_fire_state_1, 2)
		else set(engine_fire_state_1, 0) end
		
		if fire_2 then set(engine_fire_state_2, 2)
		else set(engine_fire_state_2, 0) end
		
		if fire_3 then set(engine_fire_state_3, 2)
		else set(engine_fire_state_3, 0) end
		
		--[[if fire_4 then set(engine_fire_state_4, 2)
		else set(engine_fire_state_4, 0) end--]]
		
		set(fire_sys_cc, 0.8)
	else
		-- reset valves state
		valve_1 = 0
		valve_2 = 0
		valve_3 = 0
		valve_4 = 0
		
		valves_open = 0
		
		set(fire_detected, 0)
		set(fire_siren, 0)	
		
		set(engine_fire_state_1, 0)
		set(engine_fire_state_2, 0)
		set(engine_fire_state_3, 0)
		set(engine_fire_state_4, 0)
		
		set(fire_sys_cc, 0)
	end
	
	--set results
	set(valve_open_1, valve_1)
	set(valve_open_2, valve_2)
	set(valve_open_3, valve_3)
	set(valve_open_4, valve_4)

end

end