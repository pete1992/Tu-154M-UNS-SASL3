-- this is hydraulic logic

-- controls
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    { "accum_fill", "tu154/custom/buttons/hydro/accum_fill", globalPropertyi }, --

    { "connect2to1", "tu154/custom/switchers/hydro/connect2to1", globalPropertyi }, --  2   1
    { "pump_2", "tu154/custom/switchers/hydro/pump_2", globalPropertyi }, --   2
    { "pump_3", "tu154/custom/switchers/hydro/pump_3", globalPropertyi }, --  3

    -- sources
    { "rpm_high_1", "tu154/custom/gauges/engine/rpm_high_1", globalPropertyf }, --     №1
    { "rpm_high_2", "tu154/custom/gauges/engine/rpm_high_2", globalPropertyf }, --     №2
    { "rpm_high_3", "tu154/custom/gauges/engine/rpm_high_3", globalPropertyf }, --     №3

    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },

    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf }, --   27
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf }, --   27

    -- results
    { "gs_press_1", "tu154/custom/hydro/gs_press_1", globalPropertyf }, --   1
    { "gs_press_2", "tu154/custom/hydro/gs_press_2", globalPropertyf }, --   2
    { "gs_press_3", "tu154/custom/hydro/gs_press_3", globalPropertyf }, --   3
    { "gs_press_4", "tu154/custom/hydro/gs_press_4", globalPropertyf }, --   4

    { "bak_qty_1", "tu154/custom/hydro/gs_bak_qty_1", globalPropertyf }, --
    { "bak_qty_2", "tu154/custom/hydro/gs_bak_qty_2", globalPropertyf }, --
    { "bak_qty_3", "tu154/custom/hydro/gs_bak_qty_3", globalPropertyf }, --

    { "system_qty_1", "tu154/custom/hydro/gs_qty_1", globalPropertyf }, --
    { "system_qty_2", "tu154/custom/hydro/gs_qty_2", globalPropertyf }, --
    { "system_qty_3", "tu154/custom/hydro/gs_qty_3", globalPropertyf }, --

    { "gs_qty_12_show", "tu154/custom/hydro/gs_qty_12_show", globalPropertyf }, --
    { "gs_qty_3_show", "tu154/custom/hydro/gs_qty_3_show", globalPropertyf }, --

    -- failures
    { "hs_leak_1", "tu154/custom/failures/hydro_leak_1", globalPropertyi }, -- leak
    { "hs_leak_2", "tu154/custom/failures/hydro_leak_2", globalPropertyi }, -- leak
    { "hs_leak_3", "tu154/custom/failures/hydro_leak_3", globalPropertyi }, -- leak
    { "hs_leak_4", "tu154/custom/failures/hydro_leak_4", globalPropertyi }, -- leak

    { "hydro_pump_fail_11", "tu154/custom/failures/hydro_pump_fail_11", globalPropertyi }, -- fail
    { "hydro_pump_fail_12", "tu154/custom/failures/hydro_pump_fail_12", globalPropertyi }, -- fail
    { "hydro_pump_fail_2", "tu154/custom/failures/hydro_pump_fail_2", globalPropertyi }, -- fail
    { "hydro_pump_fail_3", "tu154/custom/failures/hydro_pump_fail_3", globalPropertyi }, -- fail

    { "hydro_elec_fail_2", "tu154/custom/failures/hydro_elec_fail_2", globalPropertyi }, -- fail
    { "hydro_elec_fail_3", "tu154/custom/failures/hydro_elec_fail_3", globalPropertyi }, -- fail

    -- time
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time

    -- engines
    { "eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalProperty }, -- engine 1 rpm
    { "eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalProperty }, -- engine 2 rpm
    { "eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalProperty }, -- engine 3 rpm

    -- users --

    -- flaps
    { "flap_inn_L", "sim/flightmodel/controls/wing1l_fla1def", globalPropertyf }, -- inner flaps left
    { "flap_inn_R", "sim/flightmodel/controls/wing1r_fla1def", globalPropertyf }, -- inner flaps right

    -- brakes
    { "l_brake_add", "tu154/custom/brakes/int_brakes_L", globalPropertyf }, --
    { "r_brake_add", "tu154/custom/brakes/int_brakes_R", globalPropertyf }, --

    { "parkbrake", "sim/flightmodel/controls/parkbrake", globalPropertyf }, -- Parking Brake

    { "brake_emerg", "tu154/custom/controlls/brake_emerg", globalPropertyf }, --
    { "brake_emerg_L", "tu154/custom/controlls/brake_emerg_L", globalPropertyf }, --
    { "brake_emerg_R", "tu154/custom/controlls/brake_emerg_R", globalPropertyf }, --

    -- absu
    { "absu_contr_pitch", "tu154/custom/absu/contr_pitch", globalPropertyf }, --   56
    { "absu_contr_roll", "tu154/custom/absu/contr_roll", globalPropertyf }, --   56
    { "absu_contr_yaw", "tu154/custom/absu/contr_yaw", globalPropertyf }, --   56

    { "hydro_ra56_rud_1", "tu154/custom/switchers/eng/hydro_ra56_rud_1", globalPropertyi }, --  56
    { "hydro_ra56_rud_2", "tu154/custom/switchers/eng/hydro_ra56_rud_2", globalPropertyi }, --  56
    { "hydro_ra56_rud_3", "tu154/custom/switchers/eng/hydro_ra56_rud_3", globalPropertyi }, --  56

    { "hydro_ra56_ail_1", "tu154/custom/switchers/eng/hydro_ra56_ail_1", globalPropertyi }, --  56
    { "hydro_ra56_ail_2", "tu154/custom/switchers/eng/hydro_ra56_ail_2", globalPropertyi }, --  56
    { "hydro_ra56_ail_3", "tu154/custom/switchers/eng/hydro_ra56_ail_3", globalPropertyi }, --  56

    { "hydro_ra56_elev_1", "tu154/custom/switchers/eng/hydro_ra56_elev_1", globalPropertyi }, --  56
    { "hydro_ra56_elev_2", "tu154/custom/switchers/eng/hydro_ra56_elev_2", globalPropertyi }, --  56
    { "hydro_ra56_elev_3", "tu154/custom/switchers/eng/hydro_ra56_elev_3", globalPropertyi }, --  56

    -- ailerons
    { "ail_L", "sim/flightmodel/controls/wing3l_ail1def", globalPropertyf }, -- aileron left Degrees, positive is trailing-edge down. +- 20
    { "ail_R", "sim/flightmodel/controls/wing3r_ail1def", globalPropertyf }, -- aileron right Degrees, positive is trailing-edge down. +- 20

    -- spoilers
    { "spd_brk_inn_L", "sim/flightmodel/controls/wing1l_spo1def", globalPropertyf }, -- inner speedbrake left Degrees
    { "spd_brk_inn_R", "sim/flightmodel/controls/wing1r_spo1def", globalPropertyf }, -- inner speedbrake right Degrees

    { "spd_brk_mid_L", "sim/flightmodel/controls/wing2l_spo2def", globalPropertyf }, -- middle speedbrake left Degrees
    { "spd_brk_mid_R", "sim/flightmodel/controls/wing2r_spo2def", globalPropertyf }, -- middle speedbrake right Degrees

    -- tail
    { "elevator_L", "sim/flightmodel/controls/hstab1_elv1def", globalPropertyf }, -- Degrees, positive is trailing-edge down.
    { "elevator_R", "sim/flightmodel/controls/hstab2_elv1def", globalPropertyf }, -- Degrees, positive is trailing-edge down.
    { "rudder", "sim/flightmodel/controls/vstab2_rud1def", globalPropertyf }, -- degrees, positive is trailing-edge left

    -- gear
    { "gear1_deploy", "sim/aircraft/parts/acf_gear_deploy[0]", globalProperty },  -- deploy of front gear
    { "gear2_deploy", "sim/aircraft/parts/acf_gear_deploy[1]", globalProperty },  -- deploy of right gear
    { "gear3_deploy", "sim/aircraft/parts/acf_gear_deploy[2]", globalProperty },  -- deploy of left gear

    { "gears_retr_lock", "tu154/custom/switchers/gears_retr_lock", globalPropertyi }, --
    { "gears_ext_3GS", "tu154/custom/switchers/gears_ext_3GS", globalPropertyi }, --    3
    { "emerg_gear_ext", "tu154/custom/controll/emerg_gear_ext", globalPropertyi }, --
    { "gear_lever", "tu154/custom/controll/gear_lever", globalPropertyi }, --   . -1 - , 0 - , +1 -

    -- busters
    { "buster_on_1", "tu154/custom/switchers/console/buster_on_1", globalPropertyi }, --
    { "buster_on_2", "tu154/custom/switchers/console/buster_on_2", globalPropertyi }, --
    { "buster_on_3", "tu154/custom/switchers/console/buster_on_3", globalPropertyi }, --

    -- currents
    { "gs_pump_2_cc", "tu154/custom/hydro/gs_pump_2_cc", globalPropertyf }, --
    { "gs_pump_3_cc", "tu154/custom/hydro/gs_pump_3_cc", globalPropertyf }, --

    -- Smart Copilot
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- Master. 0 = plugin not found, 1 = slave 2 = master
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- Have control. 0 = plugin not found, 1 = no control 2 = has control
})


-- set initial values
set(system_qty_1, 58)
set(system_qty_2, 58)
set(system_qty_3, 45)

set(gs_press_1, 210)
set(gs_press_2, 210)
set(gs_press_3, 210)
set(gs_press_4, 210)

--[[
  ,  ,  ,  
  48 +-1
  24 +-1

   :  17    . 8   .

--]]

local notLoaded = true
local sim_start_timer = 0

local function reset_switchers()
	if isColdAndDarkStart() and get(eng1_N1) < 5 and get(eng2_N1) < 5 and get(eng3_N1) < 5 then

	set(gs_press_1, 0)
		set(gs_press_2, 0)
		set(gs_press_3, 0)
		set(gs_press_4, 0)
		
	end
	notLoaded = false
end

local engine_pumps_t = { 
{  -10000, 0.9},
{  0, 0.9},    
{  2.5, 0.8 },    
{  3.8, 0.7 }, 
{  4.15, 0.2 },   
{  4.21, 0 },
{  1000, 0 }}  

local electric_pumps_t = { 
{  -10000, 0.3},
{  0, 0.3},    
{  2.5, 0.28 },    
{  3.8, 0.27 },    
{  4.15, 0.1 },
{  4.21, 0 },
{  1000, 0 }} 

local brakes_L_last = get(l_brake_add)
local brakes_R_last = get(r_brake_add)
--local brakes_last = get(parkbrake)

local brakes_EM_L_last = get(brake_emerg_L)
local brakes_EM_R_last = get(brake_emerg_R)
local brakes_EM_last = get(brake_emerg)

local flap_L_last = get(flap_inn_L)
local flap_R_last = get(flap_inn_R)

local ail_L_last = get(ail_L)
local ail_R_last = get(ail_R)

local spd_brk_L_last = get(spd_brk_mid_L) + get(spd_brk_inn_L)
local spd_brk_R_last = get(spd_brk_mid_R) + get(spd_brk_inn_R)

local elev_last = get(elevator_L) + get(elevator_R)

local rudder_last = get(rudder)

local buster_1_ON = 0
local buster_2_ON = 0
local buster_3_ON = 0

local absu_pitch_last = get(absu_contr_pitch)
local absu_roll_last = get(absu_contr_roll)
local absu_yaw_last = get(absu_contr_yaw)

local gear_pos_1_last = get(gear1_deploy)
local gear_pos_2_last = get(gear2_deploy)
local gear_pos_3_last = get(gear3_deploy)

function update()

	passed = get(frame_time)

local MASTER = get(ismaster) ~= 1	
	
if MASTER then	
	
	-- reset some variables for cold start
	sim_start_timer = sim_start_timer + passed
	if sim_start_timer > 0.3 then 
		if notLoaded then reset_switchers() end
	end
	
	-- calculate oil amount
	local sys_qty_1 = get(system_qty_1)
	local sys_qty_2 = get(system_qty_2)
	local sys_qty_3 = get(system_qty_3)
	
	-- calculate amount of oil in accums
	local acc_1 = get(gs_press_1) * 0.02
	local acc_2 = get(gs_press_2) * 0.02
	local acc_3 = get(gs_press_3) * 0.02
	local acc_4 = get(gs_press_4) * 0.02
	
	-- calculate amount in barrels. barrel = whole system - pipes - accums
	local hs1_qty = sys_qty_1 - 34 - acc_1 - acc_4/2 -- quantity of oil
	local hs2_qty = sys_qty_2 - 34 - acc_2 - acc_4/2 -- quantity of oil
	local hs3_qty = sys_qty_3 - 21 - acc_3 -- quantity of oil
	
	-- limit zero amount in barrels
	if hs1_qty < 0 then hs1_qty = 0 end
	if hs2_qty < 0 then hs2_qty = 0 end
	if hs3_qty < 0 then hs3_qty = 0 end
	
	-- cross-feed in bak 1 and bak 2
	if (hs1_qty > 12 or hs2_qty > 12) and math.abs(hs1_qty - hs2_qty) > 0.001 then
		local flow = (hs2_qty - hs1_qty) * passed * 5
		
		hs1_qty = hs1_qty + flow
		hs2_qty = hs2_qty - flow
	end
	
	-- check power
	local power27L = get(bus27_volt_left) > 13
	local power27R = get(bus27_volt_right) > 13
	
	local power115_1 = get(bus115_1_volt) > 110
	local power115_3 = get(bus115_3_volt) > 110

	-- gain pressure from engine pumps
	local RPM_1 = get(rpm_high_1)
	local RPM_2 = get(rpm_high_2)
	local RPM_3 = get(rpm_high_3)
	local eng_pump_1_1 = math.min (1, RPM_1 * 0.02) * (1 - get(hydro_pump_fail_11))
	local eng_pump_1_2 = math.min (1, RPM_2 * 0.02) * (1 - get(hydro_pump_fail_12))
	local eng_pump_2 = math.min (1, RPM_2 * 0.02) * (1 - get(hydro_pump_fail_2))
	local eng_pump_3 = math.min (1, RPM_3 * 0.02) * (1 - get(hydro_pump_fail_3))	

	-- pump oil from storage to accums
	if hs1_qty > 0 then 
		local flow = (eng_pump_1_1 + eng_pump_1_2) * interpolate(engine_pumps_t, acc_1) * passed
		acc_1 = acc_1 + flow 
		hs1_qty = hs1_qty - flow
	end	

	if hs2_qty > 0 then 
		local flow = eng_pump_2 * interpolate(engine_pumps_t, acc_2) * passed
		acc_2 = acc_2 + flow 
		hs2_qty = hs2_qty - flow
	end

	if hs3_qty > 0 then 
		local flow = eng_pump_3 * interpolate(engine_pumps_t, acc_3) * passed
		acc_3 = acc_3 + flow
		hs3_qty = hs3_qty - flow
	end	

	-- gain pressure from electrical pumps
	local elec_pump_2 = bool2int(power115_1 and power27L and get(pump_2) == 1 and get(hydro_elec_fail_2) == 0)
	local elec_pump_3 = bool2int(power115_3 and power27R and get(pump_3) == 1 and get(hydro_elec_fail_3) == 0)
	
	if hs2_qty > 0 then 
		local flow = elec_pump_2 * interpolate(electric_pumps_t, acc_2) * passed 
		acc_2 = acc_2 + flow
		hs2_qty = hs2_qty - flow
	end
	if hs3_qty > 0 then 
		local flow = elec_pump_3 * interpolate(electric_pumps_t, acc_3) * passed 
		acc_3 = acc_3 + flow
		hs3_qty = hs3_qty - flow
	end
	
	local pump2_current = elec_pump_2 * (32 + interpolate(electric_pumps_t, acc_2 * 50) * 0.15)
	local pump3_current = elec_pump_3 * (32 + interpolate(electric_pumps_t, acc_3 * 50) * 0.15)
	
	-- charge the accumulator for emergency brakes
	if get(accum_fill) == 1 and acc_4 < acc_1 and power27L then
		local flow = (acc_1 - acc_4)
		if flow > 2 then flow = 2 end
		
		acc_1 = acc_1 - flow * passed
		acc_4 = acc_4 + flow * passed
	end

	-- connect HS 1 and HS2
	if get(connect2to1) == 1 and power27L and acc_2 > acc_1 then
		local flow = acc_2 - acc_1
		if flow > 2 then flow = 2 end
		
		acc_1 = acc_1 + flow * passed
		acc_2 = acc_2 - flow * passed
	end

	-- internal leak
	-- HS1 leaks down to 120 (2.4) for one hour
	-- HS2 leaks down to 130 (2.6) for one hour
	-- HS3 leaks down to 190 (3.8) for one hour
	-- HS4 leaks down to 190 (3.8) for one hour
	
	if acc_1 > 0.1 then
		local flow = passed * acc_1 * 0.00008
		acc_1 = acc_1 - flow
		hs1_qty = hs1_qty + flow
	end

	if acc_2 > 0.1 then
		local flow = passed * acc_2 * 0.000074
		acc_2 = acc_2 - flow
		hs2_qty = hs2_qty + flow
	end	
	
	if acc_3 > 0.1 then
		local flow = passed * acc_3 * 0.000014
		acc_3 = acc_3 - flow
		hs3_qty = hs3_qty + flow
	end	
	
	if acc_4 > 0.1 then
		local flow = passed * acc_4 * 0.000014
		acc_4 = acc_4 - flow
		hs1_qty = hs1_qty + flow
	end		

	-- check leak failure
	local high_leak_1 = get(hs_leak_1)
	local high_leak_2 = get(hs_leak_2)
	local high_leak_3 = get(hs_leak_3)
	local high_leak_4 = get(hs_leak_4)
	
	acc_1 = acc_1 - high_leak_1 * acc_1 * passed * 0.05
	acc_2 = acc_2 - high_leak_2 * acc_2 * passed * 0.05
	acc_3 = acc_3 - high_leak_3 * acc_3 * passed * 0.05
	acc_4 = acc_4 - high_leak_4 * acc_4 * passed * 0.05
	
	--             
	--   :)
	
	-- brakes --
	-- takes 0.04 l for full brake for each gear
	local brakes_L = get(l_brake_add)
	local brakes_R = get(r_brake_add)
	--local brakes = get(parkbrake)
	
	local main_brakes_feed = (math.max(brakes_L - brakes_L_last, 0) + math.max(brakes_R - brakes_R_last, 0)) * 0.04
	
	brakes_L_last = brakes_L
	brakes_R_last = brakes_R
	--brakes_last = brakes
	
	if acc_1 > 0 and main_brakes_feed > 0 then 
		acc_1 = acc_1 - main_brakes_feed -- take oil from HS1
		hs1_qty = hs1_qty + main_brakes_feed -- return it to barrel
	end
	
	-- emergency brakes
	local brakes_EM_L = get(brake_emerg_L)
	local brakes_EM_R = get(brake_emerg_R)
	local brakes_EM = get(brake_emerg)
	
	--local EM_brakes_feed = (brakes_EM_L - brakes_EM_L_last + brakes_EM_R - brakes_EM_R_last + brakes_EM - brakes_EM_last) * 0.04 * passed
	local EM_brakes_feed = (brakes_EM - brakes_EM_last) * 0.04
	
	brakes_EM_L_last = brakes_EM_L
	brakes_EM_R_last = brakes_EM_R
	brakes_EM_last = brakes_EM
	
	if acc_4 > 0 and EM_brakes_feed > 0 then 
		acc_4 = acc_4 - EM_brakes_feed -- take oil from HS4
		hs1_qty = hs1_qty + EM_brakes_feed -- return it to barrel
	end	
	
	------
	-- flaps
	local flap_L_now = get(flap_inn_L)
	local flap_R_now = get(flap_inn_R)	
	
	local flaps_feed = math.abs(flap_L_now - flap_L_last + flap_R_now - flap_R_last) * 0.01

	flap_L_last = flap_L_now
	flap_R_last = flap_R_now
	
	-- flight controls
	-- set busters work status
	if power27L then
		buster_1_ON = get(buster_on_1)
		buster_2_ON = get(buster_on_2)
	end
	
	if power27R then
		buster_3_ON = get(buster_on_3)
	end

	local ail_L_now = get(ail_L)
	local ail_R_now = get(ail_R)

	local spd_brk_L_now = get(spd_brk_mid_L) + get(spd_brk_inn_L)
	local spd_brk_R_now = get(spd_brk_mid_R) + get(spd_brk_inn_R)

	local elev_now = get(elevator_L) + get(elevator_R)

	local rudder_now = get(rudder)	
	
	local ailerons_feed = (math.abs(ail_L_now - ail_L_last) + math.abs(ail_R_now - ail_R_last)) * 0.05 * 0.05
	
	local elev_feed = math.abs(elev_now - elev_last) * 0.05 * 0.05
	
	local rudder_feed = math.abs(rudder_now - rudder_last) * 0.05 * 0.05
	
	local sbd_brk_feed = math.abs(spd_brk_L_now - spd_brk_L_last + spd_brk_R_now - spd_brk_R_last) * 0.05 * 0.05
	
	ail_L_last = ail_L_now
	ail_R_last = ail_R_now
	
	elev_last = elev_now
	rudder_last = rudder_now
	
	spd_brk_L_last = spd_brk_L_now
	spd_brk_R_last = spd_brk_R_now

	if acc_1 > 0 then
		local flow = (ailerons_feed + elev_feed + rudder_feed) * buster_1_ON + sbd_brk_feed + flaps_feed
		acc_1 = acc_1 - flow -- take oil from HS1
		hs1_qty = hs1_qty + flow -- return it to barrel		
	end
	
	if acc_2 > 0 then
		local flow = (ailerons_feed + elev_feed + rudder_feed) * buster_2_ON + flaps_feed
		acc_2 = acc_2 - flow -- take oil from HS2
		hs2_qty = hs2_qty + flow -- return it to barrel
	end		
	if acc_3 > 0 then
		local flow = (ailerons_feed + elev_feed + rudder_feed) * buster_3_ON
		acc_3 = acc_3 - flow -- take oil from HS3
		hs3_qty = hs3_qty + flow -- return it to barrel
	end		
	
	-- ABSU
	local absu_pitch_feed = math.abs(get(absu_contr_pitch) - absu_pitch_last) * 0.01
	local absu_roll_feed = math.abs(get(absu_contr_roll) - absu_roll_last) * 0.01
	local absu_yaw_feed = math.abs(get(absu_contr_yaw) - absu_yaw_last) * 0.01
	
	absu_pitch_last = get(absu_contr_pitch)
	absu_roll_last = get(absu_contr_roll)
	absu_yaw_last = get(absu_contr_yaw)
	
	if acc_1 > 0 then
		local flow = absu_pitch_feed * get(hydro_ra56_elev_1) + absu_roll_feed * get(hydro_ra56_ail_1) + absu_yaw_feed * get(hydro_ra56_rud_1)
		acc_1 = acc_1 - flow -- take oil from HS1
		hs1_qty = hs1_qty + flow -- return it to barrel		
	end
	
	if acc_2 > 0 then
		local flow = absu_pitch_feed * get(hydro_ra56_elev_2) + absu_roll_feed * get(hydro_ra56_ail_2) + absu_yaw_feed * get(hydro_ra56_rud_2)
		acc_2 = acc_2 - flow -- take oil from HS2
		hs2_qty = hs2_qty + flow -- return it to barrel
	end		
	if acc_3 > 0 then
		local flow = absu_pitch_feed * get(hydro_ra56_elev_3) + absu_roll_feed * get(hydro_ra56_ail_3) + absu_yaw_feed * get(hydro_ra56_rud_3)
		acc_3 = acc_3 - flow -- take oil from HS3
		hs3_qty = hs3_qty + flow -- return it to barrel
	end		
	
	-- gears
	local gear_feed_1 = math.abs(get(gear1_deploy) - gear_pos_1_last) * 8 / 2.5
	local gear_feed_2 = math.abs(get(gear2_deploy) - gear_pos_2_last) * 17 / 2.5
	local gear_feed_3 = math.abs(get(gear3_deploy) - gear_pos_3_last) * 17 / 2.5
	
	gear_pos_1_last = get(gear1_deploy)
	gear_pos_2_last = get(gear2_deploy)
	gear_pos_3_last = get(gear3_deploy)
	
	-- normal operation
	if acc_1 > 0 and get(gears_ext_3GS) == 0 and get(emerg_gear_ext) == 0 then
		acc_1 = acc_1 - gear_feed_1 - gear_feed_2 - gear_feed_3 -- take oil from HS1
		hs1_qty = hs1_qty + gear_feed_1 + gear_feed_2 + gear_feed_3 -- return it to barrel	
	end
	
	-- emerg operation
	if acc_2 > 0 and get(emerg_gear_ext) == 1 then
		acc_2 = acc_2 - gear_feed_1 - gear_feed_2 - gear_feed_3 -- take oil from HS2
		hs2_qty = hs2_qty + gear_feed_1 + gear_feed_2 + gear_feed_3 -- return it to barrel	
	end
	
	-- 3'd HS operation
	if acc_3 > 0 and get(gears_ext_3GS) == 1 and get(emerg_gear_ext) == 0 then
		acc_3 = acc_3 - gear_feed_1 - gear_feed_2 - gear_feed_3 -- take oil from HS3
		hs3_qty = hs3_qty + gear_feed_1 + gear_feed_2 + gear_feed_3 -- return it to barrel	
	end
	
	-- set results
	set(gs_press_1, acc_1 * 50)
	set(gs_press_2, acc_2 * 50)
	set(gs_press_3, acc_3 * 50)
	set(gs_press_4, acc_4 * 50)
	
	set(bak_qty_1, hs1_qty)
	set(bak_qty_2, hs2_qty)
	set(bak_qty_3, hs3_qty)	
	
	-- whole system = barrel + pipes + accums
	set(system_qty_1, hs1_qty + 34 + acc_1 + acc_4/2)
	set(system_qty_2, hs2_qty + 34 + acc_2 + acc_4/2)
	set(system_qty_3, hs3_qty + 21 + acc_3)
	
	set(gs_qty_12_show, hs1_qty * 2)
	set(gs_qty_3_show, hs3_qty)	
	
	set(gs_pump_2_cc, pump2_current)
	set(gs_pump_3_cc, pump3_current)	
	
	--print(get(system_qty_1) + get(system_qty_2))
	
end
end

