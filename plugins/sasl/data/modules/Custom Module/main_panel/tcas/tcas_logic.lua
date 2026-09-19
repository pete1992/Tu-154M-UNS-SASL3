-- tcas_logic.lua
-- this is TCAS calculation and signal generations
size = {2048, 2048}
-- controls
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
    { "tcas_on", "tu154/custom/switchers/ovhd/tcas_on", globalPropertyi },  --  TCAS

    { "tcas_range_set", "tu154/custom/tcas/range_set", globalPropertyi },  --   . 0 = 3, 1 = 5, 2 = 10, 3 = 15 nm
    { "mode_set", "tu154/custom/tcas/mode_set", globalPropertyi },  --  TCAS. -1 = test, 0 - stby, 1 = alt off, 2 = alt on, 3 = TA, 4 = TARA	4

    { "level_mode", "tu154/custom/tcas/level_mode", globalPropertyi },  -- 1 = above, 0 = normal, -1 = below
    { "fl_mode", "tu154/custom/tcas/fl_mode", globalPropertyi },  -- 0 = absolute, 1 = relative
    -- { "flt_id", "tu154/custom/tcas/flt_id", globalPropertyi },  -- 0 = cover, 1 = show / change code

    { "tcas_mode_rot", "tu154/custom/switchers/tcas/tcas_mode", globalPropertyi },  --  TCAS. -1 = test, 0 - stby, 1 = alt off, 2 = alt on, 3 = TA, 4 = TARA	3

    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time

    { "tcas_ident_btn", "tu154/custom/buttons/tcas/tcas_ident_btn", globalPropertyi },  --  IDENT
    { "tcas_fcn_btn", "tu154/custom/buttons/tcas/tcas_fcn_btn", globalPropertyi },  --  FCN
    { "tcas_left_btn", "tu154/custom/buttons/tcas/tcas_left_btn", globalPropertyi },  --  <
    { "tcas_right_btn", "tu154/custom/buttons/tcas/tcas_right_btn", globalPropertyi },  --  >
    { "tcas_ent_btn", "tu154/custom/buttons/tcas/tcas_ent_btn", globalPropertyi },  --  ENT
    -- { "tcas_atc_btn", "tu154/custom/buttons/tcas/tcas_atc_btn", globalPropertyi },  --  ATC
    -- { "tcas_alt_btn", "tu154/custom/buttons/tcas/tcas_alt_btn", globalPropertyi },  --  ALT
    { "tcas_rng_dn_btn", "tu154/custom/buttons/tcas/tcas_rng_dn_btn", globalPropertyi },  --  RNG DN
    { "tcas_rng_up_btn", "tu154/custom/buttons/tcas/tcas_rng_up_btn", globalPropertyi },  --  RNG UP

    { "tcas_rot_big", "tu154/custom/switchers/tcas/tcas_rot_big", globalPropertyi },  --

    { "alt_svs", "tu154/custom/svs/altitude", globalPropertyf }, -- Altitude by 1013 hpa

    -- { "rv_angle", "tu154/custom/gauges/alt/radioalt_needle_left", globalPropertyf },  -- RV needle
    { "rv_flag", "tu154/custom/gauges/alt/radioalt_flag_left", globalPropertyf },  -- RV flag
    { "rv5_alt", "tu154/custom/misc/rv5_alt_left", globalPropertyf },  --
    { "screen_mode", "tu154/custom/tcas/screen_mode", globalPropertyi },  --   . 0 =  , -1 = , 1 = test

    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    -- { "bus115_2_volt", "tu154/custom/elec/bus115_2_volt", globalPropertyf },
    { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },

    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf }, --   27
    -- { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf }, --   27

    -- { "xpdr_code", "sim/cockpit/radios/transponder_code", globalPropertyf },
    { "xpdr_mode", "sim/cockpit/radios/transponder_mode", globalPropertyf },
    -- { "xpdr_led", "sim/cockpit/radios/transponder_light", globalPropertyf },
    -- { "xpdr_fail", "sim/operation/failures/rel_xpndr", globalPropertyi },

    { "ovhd_mode", "tu154/custom/switchers/ovhd/transponder_mode", globalPropertyi },

    { "var_on_1", "tu154/custom/switchers/ovhd/var_left", globalPropertyi },  -- . var
    { "var_on_2", "tu154/custom/switchers/ovhd/var_right", globalPropertyi },  -- . var

    -- other aircrafts
    { "acf_1_x", "sim/multiplayer/position/plane1_x", globalPropertyf },  -- x
    { "acf_1_y", "sim/multiplayer/position/plane1_y", globalPropertyf },  -- x
    { "acf_1_z", "sim/multiplayer/position/plane1_z", globalPropertyf },  -- x

    { "acf_2_x", "sim/multiplayer/position/plane2_x", globalPropertyf },  -- x
    { "acf_2_y", "sim/multiplayer/position/plane2_y", globalPropertyf },  -- x
    { "acf_2_z", "sim/multiplayer/position/plane2_z", globalPropertyf },  -- x

    { "acf_3_x", "sim/multiplayer/position/plane3_x", globalPropertyf },  -- x
    { "acf_3_y", "sim/multiplayer/position/plane3_y", globalPropertyf },  -- x
    { "acf_3_z", "sim/multiplayer/position/plane3_z", globalPropertyf },  -- x

    { "acf_4_x", "sim/multiplayer/position/plane4_x", globalPropertyf },  -- x
    { "acf_4_y", "sim/multiplayer/position/plane4_y", globalPropertyf },  -- x
    { "acf_4_z", "sim/multiplayer/position/plane4_z", globalPropertyf },  -- x

    { "acf_5_x", "sim/multiplayer/position/plane5_x", globalPropertyf },  -- x
    { "acf_5_y", "sim/multiplayer/position/plane5_y", globalPropertyf },  -- x
    { "acf_5_z", "sim/multiplayer/position/plane5_z", globalPropertyf },  -- x

    { "acf_6_x", "sim/multiplayer/position/plane6_x", globalPropertyf },  -- x
    { "acf_6_y", "sim/multiplayer/position/plane6_y", globalPropertyf },  -- x
    { "acf_6_z", "sim/multiplayer/position/plane6_z", globalPropertyf },  -- x

    { "acf_7_x", "sim/multiplayer/position/plane7_x", globalPropertyf },  -- x
    { "acf_7_y", "sim/multiplayer/position/plane7_y", globalPropertyf },  -- x
    { "acf_7_z", "sim/multiplayer/position/plane7_z", globalPropertyf },  -- x

    { "acf_8_x", "sim/multiplayer/position/plane8_x", globalPropertyf },  -- x
    { "acf_8_y", "sim/multiplayer/position/plane8_y", globalPropertyf },  -- x
    { "acf_8_z", "sim/multiplayer/position/plane8_z", globalPropertyf },  -- x

    { "acf_9_x", "sim/multiplayer/position/plane9_x", globalPropertyf },  -- x
    { "acf_9_y", "sim/multiplayer/position/plane9_y", globalPropertyf },  -- x
    { "acf_9_z", "sim/multiplayer/position/plane9_z", globalPropertyf },  -- x

    { "acf_10_x", "sim/multiplayer/position/plane10_x", globalPropertyf },  -- x
    { "acf_10_y", "sim/multiplayer/position/plane10_y", globalPropertyf },  -- x
    { "acf_10_z", "sim/multiplayer/position/plane10_z", globalPropertyf },  -- x

    { "acf_11_x", "sim/multiplayer/position/plane11_x", globalPropertyf },  -- x
    { "acf_11_y", "sim/multiplayer/position/plane11_y", globalPropertyf },  -- x
    { "acf_11_z", "sim/multiplayer/position/plane11_z", globalPropertyf },  -- x

    { "acf_12_x", "sim/multiplayer/position/plane12_x", globalPropertyf },  -- x
    { "acf_12_y", "sim/multiplayer/position/plane12_y", globalPropertyf },  -- x
    { "acf_12_z", "sim/multiplayer/position/plane12_z", globalPropertyf },  -- x

    { "acf_13_x", "sim/multiplayer/position/plane13_x", globalPropertyf },  -- x
    { "acf_13_y", "sim/multiplayer/position/plane13_y", globalPropertyf },  -- x
    { "acf_13_z", "sim/multiplayer/position/plane13_z", globalPropertyf },  -- x

    { "acf_14_x", "sim/multiplayer/position/plane14_x", globalPropertyf },  -- x
    { "acf_14_y", "sim/multiplayer/position/plane14_y", globalPropertyf },  -- x
    { "acf_14_z", "sim/multiplayer/position/plane14_z", globalPropertyf },  -- x

    { "acf_15_x", "sim/multiplayer/position/plane15_x", globalPropertyf },  -- x
    { "acf_15_y", "sim/multiplayer/position/plane15_y", globalPropertyf },  -- x
    { "acf_15_z", "sim/multiplayer/position/plane15_z", globalPropertyf },  -- x

    { "acf_16_x", "sim/multiplayer/position/plane16_x", globalPropertyf },  -- x
    { "acf_16_y", "sim/multiplayer/position/plane16_y", globalPropertyf },  -- x
    { "acf_16_z", "sim/multiplayer/position/plane16_z", globalPropertyf },  -- x

    { "acf_17_x", "sim/multiplayer/position/plane17_x", globalPropertyf },  -- x
    { "acf_17_y", "sim/multiplayer/position/plane17_y", globalPropertyf },  -- x
    { "acf_17_z", "sim/multiplayer/position/plane17_z", globalPropertyf },  -- x

    { "acf_18_x", "sim/multiplayer/position/plane18_x", globalPropertyf },  -- x
    { "acf_18_y", "sim/multiplayer/position/plane18_y", globalPropertyf },  -- x
    { "acf_18_z", "sim/multiplayer/position/plane18_z", globalPropertyf },  -- x

    { "acf_19_x", "sim/multiplayer/position/plane19_x", globalPropertyf },  -- x
    { "acf_19_y", "sim/multiplayer/position/plane19_y", globalPropertyf },  -- x
    { "acf_19_z", "sim/multiplayer/position/plane19_z", globalPropertyf },  -- x

    -- defineProperty("acf_20_x", globalPropertyf("sim/multiplayer/position/plane20_x"))  -- x
    -- defineProperty("acf_20_y", globalPropertyf("sim/multiplayer/position/plane20_y"))  -- x
    -- defineProperty("acf_20_z", globalPropertyf("sim/multiplayer/position/plane20_z"))  -- x

    -- local aircraft coordinates
    { "pos_x", "sim/flightmodel/position/local_x", globalPropertyf }, -- longtitude. positive from W to E
    { "pos_y", "sim/flightmodel/position/local_y", globalPropertyf }, -- altitude. positive UP
    { "pos_z", "sim/flightmodel/position/local_z", globalPropertyf }, -- latitude. positive from N to S

    { "course", "sim/flightmodel/position/psi", globalPropertyf }, -- angle between -Z axis and airplane's nose
    -- { "course_fly", "sim/flightmodel/position/hpath", globalPropertyf }, -- course, where aircraft actually flies

    { "ra_scale_set", "tu154/custom/tcas/ra_scale_set", globalPropertyi },  -- RA mode scale set. 0 = none.
    { "vvi", "sim/flightmodel/position/vh_ind", globalPropertyf },  -- vertical velocity of our acf
    { "traffic_det", "tu154/custom/tcas/traffic_det", globalPropertyi },  --

    -- Smart Copilot
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- Master. 0 = plugin not found, 1 = slave 2 = master
    -- { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- Have control. 0 = plugin not found, 1 = no control 2 = has control
})

local MASTER = get(ismaster) ~= 1

local acf_local_tbl = {} -- source table in decarts coordinates

for i = 1, 20, 1 do
	table.insert(acf_local_tbl, {[1] = 0, [2] = 0, [3] = 0})
end

local acf_local_last_tbl = {} -- source table in decarts coordinates

for i = 1, 20, 1 do
	table.insert(acf_local_last_tbl, {[1] = 0, [2] = 0, [3] = 0})
end

-----
local acf_circ_tbl = {} -- source table in circular coordinates

for i = 1, 20, 1 do
	table.insert(acf_circ_tbl, {[1] = 0, [2] = 0, [3] = 0})
end

-----
local tcas_show_tbl = {} -- table for show on screen

for i = 1, 20, 1 do
	table.insert(tcas_show_tbl, {[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = "0", [7] = false}) -- 1 - forward, 2 - right, 3 - alt, 4 - 0 = hide, 1+ = mark of treat, 5 = arrow, +1 - climb, -1 - descend, 6 = text to draw, 7 - threat
end

-----
local tcas_prev_tbl = {} -- previous state for calculations

for i = 1, 20, 1 do
	table.insert(tcas_prev_tbl, {[1] = 0, [2] = 0, [3] = 0}) -- 1 - forward, 2 - right, 3 - alt
end

local refresh_counter = 0

local intruders_tbl = {} -- a table for collecting intruders
intruders_tbl = {
{["Tau"] = 0, ["alt"] = 0, ["cl_alt"] = 0, ["rate"] = 0}, -- 1 = Tau, 2 = current distance, 3 = close distance, 4 = current alt, 5 = close alt, 6 = current rate

}

function limits()
	-- this function return limits
	-- Tau TA, Tau RA, Dist TA, Dist RA, Alt Ta, Alt RA
	local alt = get(alt_svs) * 3.28083 -- alt in feet
	if alt <= 1000 then
		return 20, 0, 0.30, 0, 259.08, 0
	elseif alt <= 2350 then
		return 25, 15, 0.33, 0.20, 259.08, 91.44
	elseif alt <= 5000 then
		return 30, 20, 0.48, 0.35, 259.08, 91.44
	elseif alt <= 10000 then
		return 40, 25, 0.75, 0.55, 259.08, 106.68
	elseif alt <= 20000 then
		return 45, 30, 1.00, 0.80, 259.08, 121.92
	elseif alt <= 42000 then
		return 48, 35, 1.30, 1.10, 259.08, 182.88 		
	else
		return 48, 35, 1.30, 1.10, 365.76, 213.36
	end
	
end

local tcas_mode = get(mode_set)
local passed = get(frame_time)
local power = false

local function refresh_data()
			
			-- fill local coordinates table
			acf_local_tbl[1][1] = get(acf_1_x)
			acf_local_tbl[1][2] = get(acf_1_y)
			acf_local_tbl[1][3] = get(acf_1_z)
			
			acf_local_tbl[2][1] = get(acf_2_x)
			acf_local_tbl[2][2] = get(acf_2_y)
			acf_local_tbl[2][3] = get(acf_2_z)

			acf_local_tbl[3][1] = get(acf_3_x)
			acf_local_tbl[3][2] = get(acf_3_y)
			acf_local_tbl[3][3] = get(acf_3_z)
			
			acf_local_tbl[4][1] = get(acf_4_x)
			acf_local_tbl[4][2] = get(acf_4_y)
			acf_local_tbl[4][3] = get(acf_4_z)
			
			acf_local_tbl[5][1] = get(acf_5_x)
			acf_local_tbl[5][2] = get(acf_5_y)
			acf_local_tbl[5][3] = get(acf_5_z)
			
			acf_local_tbl[6][1] = get(acf_6_x)
			acf_local_tbl[6][2] = get(acf_6_y)
			acf_local_tbl[6][3] = get(acf_6_z)
			
			acf_local_tbl[7][1] = get(acf_7_x)
			acf_local_tbl[7][2] = get(acf_7_y)
			acf_local_tbl[7][3] = get(acf_7_z)
			
			acf_local_tbl[8][1] = get(acf_8_x)
			acf_local_tbl[8][2] = get(acf_8_y)
			acf_local_tbl[8][3] = get(acf_8_z)
			
			acf_local_tbl[9][1] = get(acf_9_x)
			acf_local_tbl[9][2] = get(acf_9_y)
			acf_local_tbl[9][3] = get(acf_9_z)
			
			acf_local_tbl[10][1] = get(acf_10_x)
			acf_local_tbl[10][2] = get(acf_10_y)
			acf_local_tbl[10][3] = get(acf_10_z)
			
			acf_local_tbl[11][1] = get(acf_11_x)
			acf_local_tbl[11][2] = get(acf_11_y)
			acf_local_tbl[11][3] = get(acf_11_z)
			
			acf_local_tbl[12][1] = get(acf_12_x)
			acf_local_tbl[12][2] = get(acf_12_y)
			acf_local_tbl[12][3] = get(acf_12_z)
			
			acf_local_tbl[13][1] = get(acf_13_x)
			acf_local_tbl[13][2] = get(acf_13_y)
			acf_local_tbl[13][3] = get(acf_13_z)
			
			acf_local_tbl[14][1] = get(acf_14_x)
			acf_local_tbl[14][2] = get(acf_14_y)
			acf_local_tbl[14][3] = get(acf_14_z)
			
			acf_local_tbl[15][1] = get(acf_15_x)
			acf_local_tbl[15][2] = get(acf_15_y)
			acf_local_tbl[15][3] = get(acf_15_z)
			
			acf_local_tbl[16][1] = get(acf_16_x)
			acf_local_tbl[16][2] = get(acf_16_y)
			acf_local_tbl[16][3] = get(acf_16_z)
			
			acf_local_tbl[17][1] = get(acf_17_x)
			acf_local_tbl[17][2] = get(acf_17_y)
			acf_local_tbl[17][3] = get(acf_17_z)
			
			acf_local_tbl[18][1] = get(acf_18_x)
			acf_local_tbl[18][2] = get(acf_18_y)
			acf_local_tbl[18][3] = get(acf_18_z)
			
			acf_local_tbl[19][1] = get(acf_19_x)
			acf_local_tbl[19][2] = get(acf_19_y)
			acf_local_tbl[19][3] = get(acf_19_z)
			
			-- acf_local_tbl[20][1] = get(acf_20_x)
			-- acf_local_tbl[20][2] = get(acf_20_y)
			-- acf_local_tbl[20][3] = get(acf_20_z)
			
			-- recalculate relative table	
			local local_x = get(pos_x) -- longtitude. positive from W to E
			local local_z = get(pos_z) -- latitude. positive from N to S
			local local_y = get(pos_y) -- altitude. positive UP
			
			local lat, lon, local_alt = sasl.localToWorld(local_x, local_y, local_z)
			
			local cur = get(course)
			
			for i = 1, 20, 1 do
				-- bearing				
				acf_circ_tbl[i][1] = math.deg(math.atan2(acf_local_tbl[i][1] - local_x, -acf_local_tbl[i][3] + local_z)) - cur
				while acf_circ_tbl[i][1] > 180 do acf_circ_tbl[i][1] = acf_circ_tbl[i][1] - 360 end
				while acf_circ_tbl[i][1] < -180 do acf_circ_tbl[i][1] = acf_circ_tbl[i][1] + 360 end
				--dist
				acf_circ_tbl[i][2] = math.sqrt( (acf_local_tbl[i][1] - local_x)^2 + (acf_local_tbl[i][3] - local_z)^2 )
				-- altitude
				local lat, lon, alt = sasl.localToWorld(acf_local_tbl[i][1], acf_local_tbl[i][2], acf_local_tbl[i][3])
				
				acf_circ_tbl[i][3] = alt - local_alt

			end
			
end

local function coor_calc() -- recalculate coordinates
	local level = get(level_mode)
	for i = 1, 20, 1 do
		local bearing = acf_circ_tbl[i][1]
		local dist = acf_circ_tbl[i][2]
		local alt = acf_circ_tbl[i][3]
		
		local y = dist * math.cos(math.rad(bearing))
		local x = dist * math.sin(math.rad(bearing))
		local z = alt
		local show = bool2int(acf_local_tbl[i][1] ~= 0 and acf_local_tbl[i][2] ~= 0 and acf_local_tbl[i][3] ~= 0)
		
		if (alt > 0 and level < 0) or (alt < 0 and level > 0) then show = 0 end
		
		--print("coor calc", x, y, z, show)
		
		tcas_show_tbl[i][1] = x
		tcas_show_tbl[i][2] = y
		tcas_show_tbl[i][3] = z
		tcas_show_tbl[i][4] = show
		tcas_show_tbl[i][5] = 0
		tcas_show_tbl[i][6] = ""
		if show == 0 then tcas_show_tbl[i][7] = false end
		
	end

end

local function mark_calc()
	
	local Tau_TA, Tau_RA, Dist_TA, Dist_RA, Alt_Ta, Alt_RA = limits() -- set limits for TA and RA modes
	local our_vvi = get(vvi)
	
	local traffic = 0
	
	-- flush the indruders table and fill it from scratch
	intruders_tbl = {}
	
	for i = 1, 20, 1 do
		
		local mark = tcas_show_tbl[i][4]
		local rate = tcas_show_tbl[i][5]
		
		if tcas_mode == -1 and power then
			if i == 1 then
				tcas_show_tbl[i][1] = -1852*2
				tcas_show_tbl[i][2] = 1852*4
				tcas_show_tbl[i][3] = 0
				tcas_show_tbl[i][4] = 1
				tcas_show_tbl[i][5] = 0
				tcas_show_tbl[i][6] = "+10"
			elseif i == 2 then
				tcas_show_tbl[i][1] = 1852*2
				tcas_show_tbl[i][2] = 1852*4
				tcas_show_tbl[i][3] = -1000
				tcas_show_tbl[i][4] = 2
				tcas_show_tbl[i][5] = -1
				tcas_show_tbl[i][6] = "-10"
			elseif i == 3 then
				tcas_show_tbl[i][1] = 1852*2
				tcas_show_tbl[i][2] = 0
				tcas_show_tbl[i][3] = 200
				tcas_show_tbl[i][4] = 4
				tcas_show_tbl[i][5] = 0
				tcas_show_tbl[i][6] = "+02"
			elseif i == 4 then
				tcas_show_tbl[i][1] = -1852*2
				tcas_show_tbl[i][2] = 0
				tcas_show_tbl[i][3] = -200
				tcas_show_tbl[i][4] = 3
				tcas_show_tbl[i][5] = 1
				tcas_show_tbl[i][6] = "-02"
			else
				tcas_show_tbl[i][4] = 0
				mark = 0
			end
		elseif tcas_mode == 0 or tcas_mode == 1 or tcas_mode == 2 or not power then -- clear marks
			tcas_show_tbl[i][4] = 0
			tcas_show_tbl[i][7] = false
			mark = 0
		elseif mark ~= 0 and power then
			local bearing = acf_circ_tbl[i][1]
			local dist = acf_circ_tbl[i][2] / 1852 -- distance in miles
			local alt = acf_circ_tbl[i][3] -- alt in meters
			local alt_prev = tcas_prev_tbl[i][3]
			
			local x = tcas_show_tbl[i][1] -- coordinates in meters
			local y = tcas_show_tbl[i][2] -- coordinates in meters
			
			-- marks will be. 1 - non-intruder, 2 - proximity traffic, 3 - intruder (TA), 4 - Threat (RA)
			local search_dist = math.sqrt(x^2 + (y - 3*1852)^2) / 1852
			
			if search_dist > 16 or math.abs(alt) > 2651.76 then 
				mark = 0 -- too far away. ignoring
				tcas_show_tbl[i][7] = false
			elseif (search_dist > 7 or math.abs(alt) > 365.76) or (get(rv5_alt) < 518.16 and alt < -get(rv5_alt) + 115.824) then
				if acf_local_tbl[i][1]-acf_local_last_tbl[i][1] ~= 0 or acf_local_tbl[i][3]-acf_local_last_tbl[i][3] ~= 0 then
					mark = 1 -- in range, but not a threat. or "on ground"
					tcas_show_tbl[i][7] = false
				else
					mark = 0
					tcas_show_tbl[i][7] = false
				end
			else -- calculate the marks within the circle 
				mark = 2
				local dist_last = dist --math.sqrt(x^2 + y^2) -- last distance of target
				local delta_x = x - tcas_prev_tbl[i][1]
				local delta_y = y - tcas_prev_tbl[i][2]
				local delta_z = alt - alt_prev
				local z_last = alt
				
				--print(delta_x, delta_y, delta_z)
				
				if acf_local_tbl[i][1]-acf_local_last_tbl[i][1] ~= 0 or acf_local_tbl[i][3]-acf_local_last_tbl[i][3] ~= 0 then -- bugs walkaround
					local iter_time = 0.5
					for t = 0, Tau_RA + 1, iter_time do
						local iter_x = x + delta_x * t
						local iter_y = y + delta_y * t
						local iter_z = alt + delta_z * t
						
						local iter_dist = math.sqrt(iter_x^2 + iter_y^2) / 1852 -- distance in miles
						-- check distance and alt change
						if iter_dist > dist_last and t == 1 then -- distance growing at the very begining of calculations
							tcas_show_tbl[i][7] = false
							if dist < Dist_TA then -- clear of conflict, but still close
								mark = 3
							else mark = 2 -- no threat
							end
							break
							
						elseif t > 1 and t <= Tau_RA and iter_dist <= Dist_RA and math.abs(iter_z) <= Alt_RA and tcas_mode == 4 then  -- too close. alarm!
							mark = 4
							tcas_show_tbl[i][7] = true
							traffic = 1
							if iter_dist > dist_last and t > 1 then -- target is at its closest position and within the RA area
								-- save this target into table
								table.insert(intruders_tbl, {["Tau"] = t, ["dist"] = dist, ["cl_dist"] = iter_dist, ["alt"] = alt, ["cl_alt"] = iter_z, ["rate"] = alt - alt_prev + our_vvi})
								break
							end
							--break
						elseif t > 1 and t <= Tau_TA and iter_dist <= Dist_TA and math.abs(iter_z) <= Alt_Ta then -- target will fly close. caution!
							mark = 3
							tcas_show_tbl[i][7] = true
							traffic = 1
							if iter_dist > dist_last and t > 1 then -- target is at its closest position and within the TA area
								-- stop mark calculation
								break
							end
							
							--break
						elseif t > 1 and iter_dist > dist_last and math.abs(iter_z) > math.abs(z_last) and iter_dist > Dist_TA and math.abs(iter_z) > Alt_Ta then -- target fly away the secured area
							mark = 2
							break
						elseif t == Tau_RA and iter_dist > Dist_TA and math.abs(iter_z) > Alt_Ta then -- target has no threat
							mark = 2
						end
						dist_last = iter_dist
						z_last = iter_z
					end
				else mark = 0
				end
			
			end
			
			--if mark > 0 then print(mark, dist, alt) end
			
			tcas_show_tbl[i][4] = mark
			
			-- arrow calculation
			
			if alt - alt_prev + our_vvi < -2.54 then rate = -1 -- target descending
			elseif alt - alt_prev + our_vvi > 2.54 then rate = 1 -- target climbing
			end
			
			tcas_show_tbl[i][5] = rate
			
			local alt_show = math.floor(alt * 3.280839895013 / 100)
			local sign_mark = "+"
			if alt_show < 0 then sign_mark = "-" end
			
			if math.abs(alt_show) < 24 then
				alt_show = string.format("%s%s", "", math.abs(alt_show) )
				if string.len(alt_show) == 1 then alt_show = string.format("%s%s", "0", alt_show ) end
				
				alt_show = sign_mark..alt_show
			else
				alt_show = ""
				tcas_show_tbl[i][5] = 0
			end
			
			tcas_show_tbl[i][6] = alt_show
			
		end
		
		tcas_prev_tbl[i][1] = tcas_show_tbl[i][1]
		tcas_prev_tbl[i][2] = tcas_show_tbl[i][2]
		tcas_prev_tbl[i][3] = tcas_show_tbl[i][3]
		
		acf_local_last_tbl[i][1] = acf_local_tbl[i][1]
		acf_local_last_tbl[i][2] = acf_local_tbl[i][2]
		acf_local_last_tbl[i][3] = acf_local_tbl[i][3]
		
		--print(i, "  ", tcas_show_tbl[i][4])
		
	end

	set(traffic_det, traffic)
	
end

local range = get(tcas_range_set)
local range_timer = 5

local dn_btn_last = get(tcas_rng_dn_btn)
local up_btn_last = get(tcas_rng_up_btn)

local function set_range()
	
	range = get(tcas_range_set)

if MASTER then
	
	local dn_btn = get(tcas_rng_dn_btn)
	local up_btn = get(tcas_rng_up_btn)
	
	range_timer = range_timer + passed
	
	if dn_btn ~= dn_btn_last then
		if dn_btn == 1 and range > 0 then range = range - 1 end
		range_timer = 0
	end

	if up_btn ~= up_btn_last then
		if up_btn == 1 and range < 3 then range = range + 1 end
		range_timer = 0
	end	
	
	dn_btn_last = dn_btn
	up_btn_last = up_btn
	
	--results
	set(tcas_range_set, range) 
	 
end

end

local test_counter = 100

local function tcas_mode_set()

	local mode = get(tcas_mode_rot)
	
	tcas_mode = get(mode_set)
	
	test_counter = test_counter + passed
	
	if mode == -1 then
		test_counter = 0
	end
	
if MASTER then
	
	if not power then 
		mode = 0
		tcas_mode = 0
	elseif test_counter < 1 then
		tcas_mode = -1
		set(tcas_range_set, 2)
	elseif mode == 3 or mode == 4 and (get(rv5_alt) < 152.4 or get(rv_flag) == 1) then
		tcas_mode = 3
	elseif mode == 4 and (get(rv5_alt) >= 152.4 and get(rv_flag) == 0) then
		tcas_mode = 4
	else 
		tcas_mode = mode
	end
	
	-- set default xpdr mode
	-- (off=0,stdby=1,on=2,test=3)
	
	local tcas_int_mode = 0
	local so72_int_mode = 0
	
	if not power then tcas_int_mode = 0 -- off
	elseif mode == 0 then tcas_int_mode = 1 -- stby
	elseif mode >= 1 then tcas_int_mode = 2 -- work
	elseif mode == -1 then tcas_int_mode = 3 -- test
	end
	
	local so72_mode = get(ovhd_mode)
	
	if so72_mode == 0 or get(bus27_volt_left) < 13 then so72_int_mode = 0 -- off
	elseif so72_mode == 1 then so72_int_mode = 1 -- stby
	elseif so72_mode >= 2 then so72_int_mode = 2 -- work
	end 
	
	-- results
	set(mode_set, tcas_mode) --  TCAS. -1 = test, 0 - stby, 1 = alt off, 2 = alt on, 3 = TA, 4 = TARA	4
	set(xpdr_mode, math.max(tcas_int_mode, so72_int_mode))
end	

end

--local range_last = range

local ident_timer = 10
local sq_set_timer = 10

local fnc_but_last = get(tcas_fcn_btn)
local left_btn_last = get(tcas_left_btn)
local right_btn_last = get(tcas_right_btn)
local enter_btn_last = get(tcas_ent_btn)

-- local text = 0

local reset timer = 0

local tcas_rot_big_last = get(tcas_rot_big)

local function text_mode()
	
	local text = get(screen_mode)

	fnc_but_sw = get(tcas_fcn_btn)
	left_btn_sw = get(tcas_left_btn)
	right_btn_sw = get(tcas_right_btn)
	enter_btn_sw = get(tcas_ent_btn)	
	
	ident_timer = ident_timer + passed
	
	--if range_last ~= range then range_timer = 0 end
	if get(tcas_ident_btn) == 1 then ident_timer = 0 end

if MASTER then
	
	if not power then 
		text = 100
	elseif get(var_on_1) == 0 and get(var_on_2) == 0 then
		text = -1
	elseif tcas_mode == -1 then -- test
		text = 5
	elseif range_timer < 3 and text < 10 then -- range changed
		text = 6
	elseif ident_timer < 5 and right_btn_last < 10 then
		text = -10
	elseif fnc_but_sw ~= fnc_but_last and fnc_but_sw == 1 and text ~= 1 and text ~= 2 and text ~= 3 and text ~= 4 and text < 10 then
		text = 1 -- level mode
	elseif fnc_but_sw ~= fnc_but_last and fnc_but_sw == 1 and text == 1 then
		text = 2 -- flight level mode
	elseif fnc_but_sw ~= fnc_but_last and fnc_but_sw == 1 and text == 2 then
		text = 3 -- flight ID
	elseif fnc_but_sw ~= fnc_but_last and fnc_but_sw == 1 and text == 3 then
		text = 4 -- PLN BIT
	elseif (fnc_but_sw ~= fnc_but_last and fnc_but_sw == 1 and text == 4) or (range_timer > 3 and ident_timer > 5 and text ~= 1 and text ~= 2 and text ~= 3 and text ~= 4 and (text < 10 or text == 100 and power)) then
		text = 0 -- ATC CODE
	end
	
	if text == 0 and enter_btn_sw == 1 and enter_btn_sw ~= enter_btn_last then --or text == 11 or text == 12 or text == 13 or text == 14 then
		text = 11
		--set(screen_mode, text)
	elseif text >= 11 and text <= 14 and enter_btn_sw == 1 and enter_btn_sw ~= enter_btn_last then
		text = 0
		--set(screen_mode, text)
	end
	
	-- change cursor position
	if text >= 11 and text <= 14 then
		if right_btn_sw ~= right_btn_last and right_btn_sw == 1 then text = text + 1
		elseif left_btn_sw ~= left_btn_last and left_btn_sw == 1 then text = text - 1
		end
		
		local tcas_rot_big_now = get(tcas_rot_big)
		
		text = text + tcas_rot_big_now - tcas_rot_big_last
		
		-- limit cursor
		if text > 14 then text = 14
		elseif text < 11 then text = 11 end
		
		if fnc_but_sw ~= fnc_but_last and fnc_but_sw == 1 then text = 0 end
		
		tcas_rot_big_last = tcas_rot_big_now
		
	end	
	
end	

	if text == 1 then
		local lvl = get(level_mode)
		if right_btn_sw ~= right_btn_last and right_btn_sw == 1 and lvl < 1 then lvl = lvl + 1
		elseif left_btn_sw ~= left_btn_last and left_btn_sw == 1 and lvl > -1 then lvl = lvl - 1
		end		
		if MASTER then set(level_mode, lvl) end
	end
	
	if text == 2 then
		local fl = get(fl_mode)
		if right_btn_sw ~= right_btn_last and right_btn_sw == 1 and fl < 1 then fl = fl + 1
		elseif left_btn_sw ~= left_btn_last and left_btn_sw == 1 and fl > 0 then fl = fl - 1
		end		
		if MASTER then set(fl_mode, fl) end
		
	end
	
	if fnc_but_sw == 1 then
		range_timer = 10
		ident_timer = 10
	end
	
	fnc_but_last = fnc_but_sw
	left_btn_last = left_btn_sw
	right_btn_last = right_btn_sw
	enter_btn_last = enter_btn_sw
	
	--range_last = range
	-- result
	if MASTER then set(screen_mode, text) end
end

local initial_RA = 10 -- - 2 = descend 2500fpm, -1 = descend 1500fpm, 0 = level flight, +1 = climb 1500fpm, +2 = climb 2500fpm, 10 = none

local ra_counter = 0
local col_alt = 0
local col_alt_last = 0

local function tcas_ra_calc()
	--print ("    ")
	local Tau_TA, Tau_RA, Dist_TA, Dist_RA, Alt_Ta, Alt_RA = limits() -- set limits for TA and RA modes
	local our_vvi = get(vvi)
	local our_alt = get(alt_svs)
	local radioalt = get(rv5_alt)
	--local our_course = get(true_psi)
	--local westbound = our_course > 180 and our_course <= 360
	
	-- sort table by Tau
	if intruders_tbl[1] and intruders_tbl[2] and intruders_tbl[1]["Tau"] ~= nil and intruders_tbl[2]["Tau"] ~= nil then
		table.sort(intruders_tbl, function(a,b) return a["Tau"] < b["Tau"] end)
	end
	
	ra_counter = ra_counter + 1
	
	if tcas_mode == 4 then
		-- take two targets and check where they will pass
		local target_1_alt_now = nil --intruders_tbl[1]["alt"]
		local target_2_alt_now = nil --intruders_tbl[2]["alt"]
		--local target_3_alt_now = nil
		
		local target_1_alt_col = nil --intruders_tbl[1]["cl_alt"]
		local target_2_alt_col = nil --intruders_tbl[2]["cl_alt"]
		--local target_3_alt_col = nil
		
		if intruders_tbl[1] then 
			target_1_alt_now = intruders_tbl[1]["alt"]
			target_1_alt_col = intruders_tbl[1]["cl_alt"]
		end
		
		if intruders_tbl[2] then
			target_2_alt_now = intruders_tbl[2]["alt"]
			target_2_alt_col = intruders_tbl[2]["cl_alt"]
		end
		--[[
		if intruders_tbl[3] then
			target_3_alt_now = intruders_tbl[3]["alt"]
			target_3_alt_col = intruders_tbl[3]["cl_alt"]
		end
		--]]
		
		local targets = 0
		
		--[[if target_1_alt_now and target_2_alt_now then -- two targets
			targets = 2
			
			ra_counter = 0		--]]
		if target_1_alt_now and ra_counter > 3 then -- only one target
			targets = 1
			
			local timeToCol = intruders_tbl[1]["Tau"]
			local altCol = intruders_tbl[1]["cl_alt"]
			col_alt = altCol + our_alt
			--           .     
			--    5  12 /.
			--    -   5
			--     - 12  0 .
			
			local up = 0
			local down = 0
			
			if our_vvi > 10 then
				
				up = (12 - our_vvi) * timeToCol
				down = (5 - our_vvi) * timeToCol
				
				if up - altCol > altCol - down then 
					initial_RA = 2
					set(ra_scale_set, 2)
				else 
					initial_RA = 1
					set(ra_scale_set, 6)
				end
				--print(">10  ", initial_RA, up, down, our_vvi, altCol)
			elseif our_vvi > 4 then 
				up = (12 - our_vvi) * timeToCol
				down = -our_vvi * timeToCol
				
				if up - altCol > altCol - down then 
					initial_RA = 2
					set(ra_scale_set, 2)
				else 
					initial_RA = 0
					set(ra_scale_set, 7)
				end
				--print(">3  ", initial_RA, up, down, our_vvi, altCol)
			elseif our_vvi < -10 then 
				up = (-5 - our_vvi) * timeToCol
				down = (-12 - our_vvi) * timeToCol
				
				if up - altCol > altCol - down or radioalt < 300 then 
					initial_RA = -1
					set(ra_scale_set, 8)
				else 
					initial_RA = -2 
					set(ra_scale_set, 4)
				end
				--print("<10  ", initial_RA, up, down, our_vvi, altCol)
			elseif our_vvi < -3 then 
				up = our_vvi * timeToCol
				down = (-12 - our_vvi) * timeToCol
				
				if up - altCol > altCol - down or radioalt < 300 then 
					initial_RA = -1
					set(ra_scale_set, 9)
				else 
					initial_RA = -2 
					set(ra_scale_set, 4)
				end
				--print("<3  ", initial_RA, up, down, our_vvi, altCol)
			else
				up = (5 - our_vvi) * timeToCol
				down = (-5 - our_vvi) * timeToCol
				
				if up - altCol > altCol - down or radioalt < 300  then 
					initial_RA = 1
					set(ra_scale_set, 1)
				else 
					initial_RA = -1 
					set(ra_scale_set, 3)
				end
				
				--print("0  ", initial_RA, up, down, our_vvi, altCol)
			end
			
			ra_counter = 0
		else -- no targets
			
			local no_threat = true
			
			for i = 1, 20, 1 do
				if tcas_show_tbl[i][7] then no_threat = false end
			end
			
			--print(math.abs(our_alt - col_alt) > Alt_RA, no_threat)
			
			if (math.abs(our_alt - col_alt) > Alt_Ta or no_threat) and ra_counter > 5 then 
				initial_RA = 10 
				set(ra_scale_set, 0)
				
				col_alt = 0
			end
			
		end
	
		col_alt_last = col_alt
		
		--set(ra_scale_set, 0)
	else
		set(ra_scale_set, 0)
		col_alt = 0
		col_alt_last = 0
	end
	
end

function update()

	MASTER = get(ismaster) ~= 1
	
	passed = get(frame_time)
	refresh_counter = refresh_counter + passed
	
	power = (get(bus115_1_volt) > 110 or get(bus115_3_volt) > 110) and get(tcas_on) == 1
	
	tcas_mode_set()
	
	-- refresh table once per second
	if refresh_counter >= 1 then
		
		refresh_data()
		coor_calc()
		mark_calc()
		tcas_ra_calc()

		refresh_counter = 0
	end
	
	set_range()
	text_mode()
	
end

components = {
	
	-- Match the traffic overlay to the reduced, needle-aligned displays.
	tcas_draw {
		position = {17.5, -2, 469, 516},
		table_draw = tcas_show_tbl
	},
	
	tcas_draw {
		position = {524.5, -2, 469, 516},
		table_draw = tcas_show_tbl
	},	

}

