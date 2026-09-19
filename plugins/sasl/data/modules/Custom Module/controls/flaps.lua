-- flaps.lua
-- this is flaps, slats and hor-stab logic

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
    { "external_view", "sim/graphics/view/view_is_external", globalPropertyi }, -- enviroment
    -- sim positions
    { "flap_inn_L", "sim/flightmodel/controls/wing1l_fla1def", globalPropertyf }, -- inner flaps left
    { "flap_inn_R", "sim/flightmodel/controls/wing1r_fla1def", globalPropertyf }, -- inner flaps right

    { "flap_mid_L", "sim/flightmodel/controls/wing2l_fla2def", globalPropertyf }, -- middle flaps left
    { "flap_mid_R", "sim/flightmodel/controls/wing2r_fla2def", globalPropertyf }, -- middle flaps right
    --defineProperty("slats", globalPropertyf("sim/flightmodel/controls/slatrat")) -- slats position. this one works
    { "slats", "sim/flightmodel2/controls/slat1_deploy_ratio", globalPropertyf }, -- slats position. this one works too
    { "stab_ratio", "sim/cockpit2/controls/elevator_trim", globalPropertyf }, -- sim pitch trimmer
    -- controls
    { "sim_flap_ratio", "sim/cockpit2/controls/flap_ratio", globalPropertyf }, -- sim flaps ratio control. use for axis and commands

    { "flaps_lever", "tu154/custom/controll/flaps_lever", globalPropertyf }, -- sim flaps ratio control. use for axis and commands
    { "flaps_sel", "tu154/custom/switchers/flaps_sel", globalPropertyi }, --    . -1 - , 0 - , +1 -

    { "slat_man", "tu154/custom/switchers/slat_man", globalPropertyi }, --   . -1 - , 0 , +1 -
    { "slat_man_cap", "tu154/custom/switchers/slat_man_cap", globalPropertyi }, --

    { "stab_man_cap", "tu154/custom/controll/stab_man_cap", globalPropertyi }, --
    { "stab_manual", "tu154/custom/controll/stab_manual", globalPropertyi }, --  . 0 - , +1 -
    { "stab_setting", "tu154/custom/controll/stab_setting", globalPropertyi }, --    . 0 - , 1 - , 2 - 	1

    -- other sources

    -- hydraulics
    { "gs_press_1", "tu154/custom/hydro/gs_press_1", globalPropertyf }, --   1
    { "gs_press_2", "tu154/custom/hydro/gs_press_2", globalPropertyf }, --   2
    -- { "gs_press_3", "tu154/custom/hydro/gs_press_3", globalPropertyf }, --   3

    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- time of frame

    -- power
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf }, --   27
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf }, --   27

    { "bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf }, --   36
    { "bus36_volt_right", "tu154/custom/elec/bus36_volt_right", globalPropertyf }, --   36

    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },

    { "ctr_115_1_cc", "tu154/custom/control/ctr_115_1_cc", globalPropertyf }, --
    { "ctr_115_3_cc", "tu154/custom/control/ctr_115_3_cc", globalPropertyf }, --

    -- Smart Copilot
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- Master. 0 = plugin not found, 1 = slave 2 = master
    -- { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- Have control. 0 = plugin not found, 1 = no control 2 = has control

    -- failures
    { "flap_fail_left", "tu154/custom/failures/flap_fail_left", globalPropertyi }, --
    { "flap_fail_right", "tu154/custom/failures/flap_fail_right", globalPropertyi }, --

    { "stab_eng_fail", "tu154/custom/failures/stab_eng_fail", globalPropertyi }, --
    { "stab_automatic_fail", "tu154/custom/failures/stab_automatic_fail", globalPropertyi }, --
    { "slats_fail", "tu154/custom/failures/slats_fail", globalPropertyi }, --
})

flaps_cmd_up = sasl.findCommand("sim/flight_controls/flaps_up")
flaps_cmd_down = sasl.findCommand("sim/flight_controls/flaps_down")

local flaps_sound = sasl.al.loadSample('Custom Sounds/flaps_hnd.wav') --

function flaps_up_handler(phase)
	if 0 == phase then
		if get(external_view) == 0 then sasl.al.playSample(flaps_sound, false) end
	end
	return 0
end

function flaps_down_handler(phase)
	if 0 == phase then
		if get(external_view) == 0 then sasl.al.playSample(flaps_sound, false) end
	end
	return 0
end

sasl.registerCommandHandler(flaps_cmd_up, 0, flaps_up_handler)
sasl.registerCommandHandler(flaps_cmd_down, 0, flaps_down_handler)

flap_lever_tbl = {
	{	-50000, 0  },
	{	0, 0		   },
	{	0.20, 15	},
	{	0.25, 15	}, -- stop pos
	{	0.30, 15	},
	{	0.45, 28	},
	{	0.50, 28	}, -- stop pos
	{	0.55, 28	},
	{	0.70, 36	},
	{	0.75, 36	}, -- stop pos
	{	0.80, 36	},
	{	0.95, 45	},
	{	1.00, 45	 }, -- stop pos
	{	10000, 45  }
}

local mid_flap_tbl = {
	{0, 0},
	{15, 13},
	{28, 25},
	{36, 32},
	{45, 40}
}

local flaps_pos_L_cmd = get(flap_inn_L)
local flaps_pos_R_cmd = get(flap_inn_R)
local flaps_dirr_L = 0
local flaps_dirr_R = 0

local flap_SPD = 1.8 -- deg per second
local flap_pos_L_last = flaps_pos_L_cmd
local flap_pos_R_last = flaps_pos_R_cmd

local slats_pos_cmd = get(slats)
local slats_dirr = 0
local spats_spd = 0.2 * 0.5

local stab_pos_now = get(stab_ratio) * 5.5 -- 0 - 5.5 degrees
local stab_pos_cmd = stab_pos_now
local stab_dirr = 0
local flaps_lever_last = get(flaps_lever)

local lever_moved_dir = -1 -- -1 = moved up, +1 = moved down
local stab_must_move = false

function update()
	
	local MASTER = get(ismaster) ~= 1
	
if MASTER then
	
	-- initial
	local passed = get(frame_time)
	local flaps_mode = get(flaps_sel)
	
	-- failures
	local flap_mech_L_fail = get(flap_fail_left)
	local flap_mech_R_fail = get(flap_fail_right)
	
	-- power
	local power27_L = bool2int(get(bus27_volt_left) > 13)
	local power27_R = bool2int(get(bus27_volt_right) > 13)
	
	local power36_L = bool2int(get(bus36_volt_left) > 30)
	local power36_R = bool2int(get(bus36_volt_right) > 30)
	
	local power115_1 = bool2int(get(bus115_1_volt) > 110)
	local power115_3 = bool2int(get(bus115_3_volt) > 110)
	
	local CC_115_1 = 0
	local CC_115_3 = 0
	
	--------------------------------------
	-- flaps --

	-- flap lever position and animation
	local flap_lever_pos = interpolate(flap_lever_tbl, get(sim_flap_ratio))
	
	set(flaps_lever, flap_lever_pos)
	
	-- calculate flaps commanded position
	flaps_pos_L_cmd = flap_lever_pos -- for automatic movement. can add control failures here
	flaps_pos_R_cmd = flap_lever_pos -- for automatic movement. can add control failures here
	
	-- for manual movement

	-- flaps movements
	local HS1 = math.min(get(gs_press_1) * 0.15, 1)
	local HS2 = math.min(get(gs_press_2) * 0.15, 1)
	
	local flap_pos_now_L = get(flap_inn_L)
	local flap_pos_now_R = get(flap_inn_R)
	
	if flaps_mode == 0 then -- automatic movements
		
		if flap_pos_now_L < flaps_pos_L_cmd - 0.1 then flaps_dirr_L = 1
		elseif flap_pos_now_L > flaps_pos_L_cmd then flaps_dirr_L = -1
		else flaps_dirr_L = 0
		end

		if flap_pos_now_R < flaps_pos_R_cmd - 0.1 then flaps_dirr_R = 1
		elseif flap_pos_now_R > flaps_pos_R_cmd then flaps_dirr_R = -1
		else flaps_dirr_R = 0
		end
		
		-- can add automatic failures here, controlling dirrection
		
	elseif flaps_mode == 1 then -- manual movements
		
		if flap_lever_pos > 40 then	
			flaps_dirr_L = 1
			flaps_dirr_R = 1
		elseif flap_lever_pos < 5 then 
			flaps_dirr_L = -1
			flaps_dirr_R = -1
		else 
			flaps_dirr_L = 0 
			flaps_dirr_R = 0
		end

	end
	
	-- add power dependencies
	flaps_dirr_L = flaps_dirr_L * power36_L * power36_R
	flaps_dirr_R = flaps_dirr_R * power36_L * power36_R
	
	-- move the flaps
	flap_pos_now_L = flap_pos_now_L + flaps_dirr_L * passed * math.max(HS1, HS2) * flap_SPD * (1 - flap_mech_L_fail) 
	flap_pos_now_R = flap_pos_now_R + flaps_dirr_R * passed * math.max(HS1, HS2) * flap_SPD * (1 - flap_mech_R_fail) 
	
	-- set limits
	if flap_pos_now_L > 45 then flap_pos_now_L = 45
	elseif flap_pos_now_L < 0 then flap_pos_now_L = 0 end
		
	if flap_pos_now_R > 45 then flap_pos_now_R = 45
	elseif flap_pos_now_R < 0 then flap_pos_now_R = 0 end	
	
	-- brake unsynced flaps
	if math.abs(flap_pos_now_L - flap_pos_now_R) < 3 then 
		flap_pos_L_last = flap_pos_now_L
		flap_pos_R_last = flap_pos_now_R
	end
	
	-- flap sounds
	
	if flaps_lever_last ~= flap_lever_pos and (flap_lever_pos == 0 or flap_lever_pos == 15 or flap_lever_pos == 28 or flap_lever_pos == 36 or flap_lever_pos == 45) then
		sasl.al.playSample(flaps_sound, false)
	end
	
	flaps_lever_last = flap_lever_pos
	
	-- set results	
	set(flap_inn_L, flap_pos_L_last)
	set(flap_inn_R, flap_pos_R_last)
	
	set(flap_mid_L, interpolate(mid_flap_tbl, flap_pos_L_last))
	set(flap_mid_R, interpolate(mid_flap_tbl, flap_pos_R_last))	
	
	-----------------------------------------------------
	-- slats -- 
	local slats_pos = get(slats)
	local stats_eng = 2 - get(slats_fail) -- can add failures here
	
	-- calculate new position of slats
	if get(slat_man_cap) == 0 then -- automatic mode
		if flap_lever_pos >= 5 then slats_pos_cmd = 1
		elseif flap_lever_pos < 5 and flap_pos_L_last <= 14 and flap_pos_R_last <= 14 then slats_pos_cmd = 0
		end	
		
		if slats_pos_cmd > slats_pos + 0.01 then slats_dirr = 1
		elseif slats_pos_cmd < slats_pos then slats_dirr = -1
		else slats_dirr = 0 end
		--slats_dirr
		
	else -- manual mode
		slats_dirr = get(slat_man)
		slats_pos_cmd = slats_pos
	end
	
	-- power
	slats_dirr = slats_dirr * power36_L * power36_R
	
	-- set movement
	slats_pos = slats_pos + slats_dirr * passed * spats_spd * (bool2int(stats_eng > 1) * power115_1 * power27_L + bool2int(stats_eng > 0) * power115_3 * power27_R)
	
	if slats_dirr ~= 0 then
		if stats_eng > 1 then CC_115_1 = 6.5 end
		if stats_eng > 0 then CC_115_3 = 6.5 end
	end
	
	if slats_pos > 1 then slats_pos = 1
	elseif slats_pos < 0 then slats_pos = 0 end
	
	set(slats, slats_pos)
	
	----------------------------------------------------
	-- stab --

	local stab_mechs = 2 - get(stab_eng_fail) -- two engines working normally. can add failures here
	
	-- calculate new stab position and dirrection of movement
	if get(stab_man_cap) == 0 and get(stab_automatic_fail) == 0 then -- automatic controls and no automatic fails
		local stab_set = get(stab_setting)
		-- check lever movement
		if flap_lever_pos > flap_pos_L_last + 0.1 and flap_lever_pos > flap_pos_R_last + 0.1 then -- flaps lever moving down
			lever_moved_dir = 1
			stab_must_move = true
		elseif flap_lever_pos < flap_pos_L_last - 0.1 and flap_lever_pos < flap_pos_R_last - 0.1 then -- flaps moving up
			lever_moved_dir = -1
			stab_must_move = true
		else 
			lever_moved_dir = 0
			stab_must_move = false
		end		

		-- calculate stab new position
		if lever_moved_dir == 1 and stab_must_move then 
			if flap_lever_pos >= 15 and flap_lever_pos <= 28 then 
				if stab_set == 2 then stab_pos_cmd = 3
				elseif stab_set == 1 then stab_pos_cmd = 1.5
				else stab_pos_cmd = 0 end
			elseif flap_lever_pos >= 36 and flap_pos_L_last >= 31 and flap_pos_R_last >= 31 then
				if stab_set == 2 then stab_pos_cmd = 5.5
				elseif stab_set == 1 then stab_pos_cmd = 3
				else stab_pos_cmd = 0 end			
			end
		elseif lever_moved_dir == -1 and stab_must_move then 
			if --[[flap_lever_pos >= 15 and--]] flap_lever_pos <= 28 and flap_pos_L_last <= 34 and flap_pos_R_last <= 34 then 
				--print("work 2")
				if stab_set == 2 then stab_pos_cmd = 3
				elseif stab_set == 1 then stab_pos_cmd = 1.5
				else stab_pos_cmd = 0 end			
			end			
		end
		
		if flap_lever_pos < 5 and flap_pos_L_last < 25 and flap_pos_R_last < 25 then stab_pos_cmd = 0 end -- flight position
		
		--stab_must_move = math.abs(stab_pos_cmd - stab_pos_now) > 0.01 and math.abs(flap_pos_L_last - flaps_pos_L_cmd) > 0.1 and math.abs(flap_pos_R_last - flaps_pos_R_cmd) > 0.1
		
		if stab_pos_cmd > stab_pos_now + 0.01 then stab_dirr = 1
		elseif stab_pos_cmd < stab_pos_now then stab_dirr = -1
		else stab_dirr = 0 end
		
	elseif get(stab_man_cap) == 1 then -- manual stab control
		stab_dirr = get(stab_manual)
		stab_pos_cmd = stab_pos_now
	end
	
	-- stab movements
	stab_pos_now = stab_pos_now + stab_dirr * passed * (bool2int(stab_mechs > 0) * power115_1 + bool2int(stab_mechs > 1) * power115_3) * 0.11
	
	if stab_dirr ~= 0 then
		if stab_mechs > 1 then CC_115_1 = CC_115_1 + 6.5 end
		if stab_mechs > 0 then CC_115_3 = CC_115_3 + 6.5 end
	
	end
	
	-- set limits
	if stab_pos_now > 5.5 then stab_pos_now = 5.5
	elseif stab_pos_now < 0 then stab_pos_now = 0 end
	
	--stab_dirr = 0
	--stab_pos_cmd = 0
	set(stab_ratio, stab_pos_now / 5.5)
	
	set(ctr_115_1_cc, CC_115_1)
	set(ctr_115_3_cc, CC_115_3)
	
	end
end
