-- this is flight controls override script for SmartCopilot

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
    -- Simulator controls.
    -- { "yoke_pitch_ratio", "sim/joystick/yoke_pitch_ratio", globalPropertyf },
    -- { "yoke_roll_ratio", "sim/joystick/yoke_roll_ratio", globalPropertyf },
    -- { "yoke_heading_ratio", "sim/joystick/yoke_heading_ratio", globalPropertyf },
    { "yoke_pitch_ratio", "sim/cockpit2/controls/yoke_pitch_ratio", globalPropertyf }, -- Joystick pitch position.
    { "yoke_roll_ratio", "sim/cockpit2/controls/yoke_roll_ratio", globalPropertyf }, -- Joystick roll position.
    { "yoke_heading_ratio", "sim/cockpit2/controls/yoke_heading_ratio", globalPropertyf }, -- Joystick yaw position.

    { "ENGN_thro_0", "sim/flightmodel/engine/ENGN_thro[0]", globalProperty },
    { "ENGN_thro_1", "sim/flightmodel/engine/ENGN_thro[1]", globalProperty },
    { "ENGN_thro_2", "sim/flightmodel/engine/ENGN_thro[2]", globalProperty },

    -- Propeller-mode synchronization below is disabled; no active consumers.
    -- { "ENGN_propmode_0", "sim/flightmodel/engine/ENGN_propmode[0]", globalProperty },
    -- { "ENGN_propmode_2", "sim/flightmodel/engine/ENGN_propmode[2]", globalProperty },

    { "tire_steer_command_deg", "sim/flightmodel2/gear/tire_steer_command_deg[0]", globalProperty },

    -- Brake synchronization below is disabled; no active consumers.
    -- { "l_brake_add", "sim/flightmodel/controls/l_brake_add", globalPropertyf },
    -- { "r_brake_add", "sim/flightmodel/controls/r_brake_add", globalPropertyf },
    -- { "int_brakes_L", "tu154/custom/brakes/int_brakes_L", globalPropertyf },
    -- { "int_brakes_R", "tu154/custom/brakes/int_brakes_R", globalPropertyf },
    -- { "parkbrake", "sim/flightmodel/controls/parkbrake", globalPropertyf },

    -- SmartCopilot control bridge.
    { "CS_pitch_ratio", "tu154/custom/SC/yoke_pitch_ratio", globalPropertyf },
    { "SC_roll_ratio", "tu154/custom/SC/yoke_roll_ratio", globalPropertyf },
    { "SC_heading_ratio", "tu154/custom/SC/yoke_heading_ratio", globalPropertyf },

    { "SC_ENGN_thro_0", "tu154/custom/SC/engine/ENGN_thro_0", globalPropertyf },
    { "SC_ENGN_thro_1", "tu154/custom/SC/engine/ENGN_thro_1", globalPropertyf },
    { "SC_ENGN_thro_2", "tu154/custom/SC/engine/ENGN_thro_2", globalPropertyf },

    -- Propeller-mode synchronization below is disabled; no active consumers.
    -- { "SC_ENGN_propmode_0", "tu154/custom/SC/engine/ENGN_propmode_0", globalPropertyf },
    -- { "SC_ENGN_propmode_2", "tu154/custom/SC/engine/ENGN_propmode_2", globalPropertyf },

    { "SC_tire_steer", "tu154/custom/SC/gear/tire_steer_command_deg", globalPropertyf },

    -- Brake synchronization below is disabled; no active consumers.
    -- { "SC_l_brake_add", "tu154/custom/SC/controls/l_brake_add", globalPropertyf },
    -- { "SC_r_brake_add", "tu154/custom/SC/controls/r_brake_add", globalPropertyf },
    -- { "SC_int_brakes_L", "tu154/custom/SC/brakes/int_brakes_L", globalPropertyf },
    -- { "SC_int_brakes_R", "tu154/custom/SC/brakes/int_brakes_R", globalPropertyf },
    -- { "SC_parkbrake", "tu154/custom/SC/controls/parkbrake", globalPropertyf },

    -- SmartCopilot connection and ownership.
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- 0 = absent, 1 = slave, 2 = master.
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- 0 = absent, 1 = no control, 2 = has control.
    { "control_thro_other", "tu154/custom/SC/control_thro_other", globalPropertyf },

    -- Wheel-steering override.
    { "override_wheel_steer", "sim/operation/override/override_wheel_steer", globalPropertyf },
})

local conr_last = true
set(override_wheel_steer, 0)

function update()

	local has_contr = get(hascontrol_1) ~= 1
	local other_tro = get(control_thro_other) == 1

	if conr_last ~= has_contr then set(control_thro_other, 0) end
	
	-- change nosewheel steer once at changing controls
	
	if conr_last ~= has_contr and has_contr then
		set(override_wheel_steer, 0)
	elseif not has_contr then
		set(override_wheel_steer, 1)
	end
	
	-- let this client control the acf, if SC plugin gives this ability or no plugin connection at all
	if has_contr then
		
		set(CS_pitch_ratio, get(yoke_pitch_ratio))
		set(SC_roll_ratio, get(yoke_roll_ratio))
		set(SC_heading_ratio, get(yoke_heading_ratio))
		
		set(SC_tire_steer, get(tire_steer_command_deg))
		
		--set(SC_l_brake_add, get(l_brake_add))
		--set(SC_r_brake_add, get(r_brake_add))
		
		--set(SC_int_brakes_L, get(int_brakes_L))
		--set(SC_int_brakes_R, get(int_brakes_R))
	
		--set(SC_parkbrake, get(parkbrake))
	else
		
		set(tire_steer_command_deg, get(SC_tire_steer))
		
		--set(l_brake_add, get(SC_l_brake_add))
		--set(r_brake_add, get(SC_r_brake_add))
		
		--set(int_brakes_L, get(SC_int_brakes_L))
		--set(int_brakes_R, get(SC_int_brakes_R))
	
		--set(parkbrake, get(SC_parkbrake))
	end
	
	conr_last = has_contr
	
	-- let this control the throttles when SC controls on other client and "other" option enabled or no CS connection at all
	if (not has_contr and other_tro) or (has_contr and not other_tro) or get(ismaster) == 0 then
		set(SC_ENGN_thro_0, get(ENGN_thro_0))
		set(SC_ENGN_thro_1, get(ENGN_thro_1))
		set(SC_ENGN_thro_2, get(ENGN_thro_2))
		
		--set(SC_ENGN_propmode_0, get(ENGN_propmode_0))
		--set(SC_ENGN_propmode_2, get(ENGN_propmode_2))
		
	end

end

function onModuleDone()
	set(override_wheel_steer, 0)
end
