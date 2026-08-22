--[[
Changelog
- Grouped all Dataref property bindings through a local defineProps() helper while preserving every existing property name, Dataref path, constructor, and binding order.
- Replaced Russian comments with English comments.
- Fixed route-change detection so main/alternate fuel is recalculated when either distance or flight level changes, even if opposite changes cancel numerically.
- Moved the static CG index coefficients out of update() to avoid rebuilding the same table every frame.
- Reused a single fuel interpolation table instead of allocating a new table on every fuel calculation.
- Moved constant CG diagram parameters out of calc_CG() so they are not recreated for every call.
- Removed a redundant CG Dataref write during fast loading while preserving the final ground/air CG behavior.
- Updated the 0% load preset so Cargo 1 and Cargo 2 are unloaded together with the passenger zones.
- Consolidated mutable panel state into one STATE table to keep Lua 5.1/SASL callback upvalue counts safely below the compiler limit.
- Preserved payload limits, passenger/cargo weights, fuel tables, fuel distribution thresholds, CG coefficients, tank limits, UI geometry, and public interfaces unless explicitly listed above.
- Restored native SASL 3 mouse semantics: legacy onMouseClick actions now use onMouseDown instead of frame-driven onMouseHold.
- Added updateAll(components) to the custom update() callback so child components keep receiving updates under SASL 3.
- Removed an unused bitmap-font load that was not used by this panel.
]]

-- Payload panel.
size = {1024, 683}

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

-- General panel state and timing.
defineProps({
    { "save_state", "tu154/custom/save_state", globalPropertyi },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    { "hide_eng_objects", "tu154/custom/lang/hide_eng_objects", globalPropertyi },
    { "show_load_panel", "tu154/custom/panels/show_load_panel", globalPropertyi },
})

-- Panel images are SASL properties, not Datarefs.
defineProperty("bg_img", sasl.gl.loadImage("load_panel.png"))
defineProperty("bg_img_rus", sasl.gl.loadImage("load_panel_RUS.png"))

-- Payload inputs, aircraft state, and load results.
defineProps({
    { "crew_num_pr", "tu154/custom/payload/crew_num", globalPropertyi },
    { "zone_1_pr", "tu154/custom/payload/zone_1", globalPropertyi },
    { "zone_2_pr", "tu154/custom/payload/zone_2", globalPropertyi },
    { "cabin_num_pr", "tu154/custom/payload/cabin_num", globalPropertyi },
    { "zone_4_pr", "tu154/custom/payload/zone_4", globalPropertyi },
    { "zone_5_pr", "tu154/custom/payload/zone_5", globalPropertyi },
    { "zone_6_pr", "tu154/custom/payload/zone_6", globalPropertyi },
    { "cargo_1_pr", "tu154/custom/payload/cargo_1", globalPropertyi },
    { "cargo_2_pr", "tu154/custom/payload/cargo_2", globalPropertyi },
    { "kitchens_pr", "tu154/custom/payload/kitchens", globalPropertyi },
    { "various_pr", "tu154/custom/payload/various", globalPropertyi },
    { "main_dist_pr", "tu154/custom/payload/main_dist", globalPropertyi },
    { "alt_dist_pr", "tu154/custom/payload/alt_dist", globalPropertyi },
    { "main_fl_pr", "tu154/custom/payload/main_fl", globalPropertyi },
    { "alt_fl_pr", "tu154/custom/payload/alt_fl", globalPropertyi },
    { "nav_fuel_pr", "tu154/custom/payload/nav_fuel", globalPropertyi },
    { "taxi_fuel_pr", "tu154/custom/payload/taxi_fuel", globalPropertyi },
    { "tank_1_pr", "tu154/custom/payload/tank_1", globalPropertyi },
    { "tank_4_pr", "tu154/custom/payload/tank_4", globalPropertyi },
    { "tank_2L_pr", "tu154/custom/payload/tank_2L", globalPropertyi },
    { "tank_2R_pr", "tu154/custom/payload/tank_2R", globalPropertyi },
    { "tank_3L_pr", "tu154/custom/payload/tank_3L", globalPropertyi },
    { "tank_3R_pr", "tu154/custom/payload/tank_3R", globalPropertyi },
    { "eng_rpm1", "sim/flightmodel/engine/ENGN_N2_[0]", globalProperty },
    { "eng_rpm2", "sim/flightmodel/engine/ENGN_N2_[1]", globalProperty },
    { "eng_rpm3", "sim/flightmodel/engine/ENGN_N2_[2]", globalProperty },
    { "gear1_deflect", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[0]", globalProperty },
    { "payload", "sim/flightmodel/weight/m_fixed", globalPropertyf },
    { "CG_load", "sim/flightmodel/misc/cgz_ref_to_default", globalPropertyf },
    { "fuel_q_1", "sim/flightmodel/weight/m_fuel[0]", globalProperty },
    { "fuel_q_4", "sim/flightmodel/weight/m_fuel[1]", globalProperty },
    { "fuel_q_2R", "sim/flightmodel/weight/m_fuel[2]", globalProperty },
    { "fuel_q_2L", "sim/flightmodel/weight/m_fuel[3]", globalProperty },
    { "fuel_q_3R", "sim/flightmodel/weight/m_fuel[4]", globalProperty },
    { "fuel_q_3L", "sim/flightmodel/weight/m_fuel[5]", globalProperty },
    { "paylod_set", "tu154/custom/payload/paylod_set", globalPropertyf },
    { "cg_set", "tu154/custom/payload/cg_set", globalPropertyf },
    { "load_fuel_btn", "tu154/custom/payload/load_fuel_btn", globalPropertyi },
    { "load_fast_btn", "tu154/custom/payload/load_fast_btn", globalPropertyi },
    { "load_slow_btn", "tu154/custom/payload/load_slow_btn", globalPropertyi },
})

include("fuel_tables.lua")

--include("fuel_tables.sec")
---local EMPTY_WEIGHT = 54865
-- Internal mutable panel state.
-- Keeping mutable values in one table prevents Lua 5.1 functions from capturing
-- dozens of individual file-level locals as separate upvalues.
local STATE = {
    crew_num = 3,
    zone_1 = 18,
    zone_2 = 44,
    cabin_num = 7,
    zone_4 = 48,
    zone_5 = 42,
    zone_6 = 14,
    cargo_1 = 0,
    cargo_2 = 0,
    kitchens = 500,
    various = 500,
    main_dist = 5000,
    alt_dist = 5000,
    main_fl = 340,
    alt_fl = 380,
    nav_fuel = 4500,
    taxi_fuel = 500,

    main_fuel = 20000,
    alt_fuel = 15000,
    tank_1 = 3300,
    tank_4 = 6595,
    tank_2L = 9500,
    tank_2R = 9500,
    tank_3L = 5405,
    tank_3R = 5405,

    zfw_cg = 35.9587,
    to_cg = 19.9587,
    land_cg = 25.9587,
    stab_set = "MID/MID/MID",

    cargo_1_fill = 1,
    cargo_2_fill = 1,
    zfw_overweight = false,
    to_overweight = false,
    land_overweight = false,
    fuel_over_limits = 0,
    tank_1_fill = 1,
    tank_4_fill = 1,
    tank_2L_fill = 1,
    tank_2R_fill = 1,
    tank_3L_fill = 1,
    tank_3R_fill = 1,
    optimal_mach = 0.8,
    click_timer = 0,

    main_dist_last = nil,
    main_fl_last = nil,
    alt_dist_last = nil,
    alt_fl_last = nil,
}

STATE.total_pax_load = STATE.zone_1 + STATE.zone_2 + STATE.zone_4 + STATE.zone_5 + STATE.zone_6
STATE.cargo_load = STATE.cargo_1 + STATE.cargo_2
STATE.traffic_load = STATE.total_pax_load + STATE.cargo_load
STATE.dry_op_weight = 54865 + STATE.crew_num * 80 + STATE.cabin_num * 80 + STATE.kitchens + STATE.various
STATE.zero_fuel_weight = STATE.dry_op_weight + STATE.traffic_load
STATE.total_fuel = STATE.main_fuel + STATE.alt_fuel + STATE.nav_fuel + STATE.taxi_fuel
STATE.total_fuel_actual = STATE.tank_1 + STATE.tank_4 + STATE.tank_2L + STATE.tank_2R + STATE.tank_3L + STATE.tank_3R
STATE.takeoff_weight = STATE.zero_fuel_weight + STATE.total_fuel
STATE.trip_fuel = STATE.main_fuel + STATE.nav_fuel
STATE.landing_weight = STATE.takeoff_weight - STATE.trip_fuel
STATE.main_fuel_show = STATE.main_fuel
STATE.alt_fuel_show = STATE.alt_fuel
STATE.total_fuel_show = STATE.total_fuel

-- Static loading-diagram coefficients. These values were previously rebuilt every frame.
local LOAD_INDEX = {
    initial_index = 72.03,
    cockpit_crew_idx = -0.84,
    cabin_crew_idx = -0.413,
    zone_1_idx = -0.63,
    zone_2_idx = -0.49,
    zone_4_idx = -0.17,
    zone_5_idx = 0.04,
    zone_6_idx = 0.18,
    kitchen_idx = -0.0059,
    tools_tdx = -0.0053,
    cargo_1_idx = -0.0050667,
    cargo_2_idx = 0.0014933,
    tank_1_idx = -0.0011993,
    tank_2_idx = -0.0000509,
    tank_3_idx = 0.0014161,
    tank_4_idx = -0.00194,
}

-- Reused interpolation table; only the Y values depend on route distance.
local FUEL_INTERP_TABLE = {
    {200, 0}, {230, 0}, {250, 0}, {270, 0}, {290, 0},
    {310, 0}, {330, 0}, {350, 0}, {370, 0}, {390, 0},
}

-- Loading diagram constants used by calc_CG().
local MID_CG = 40
local MID_CG_POS = 60
local MIN_WEIGHT = 54000
local MAX_WEIGHT = 74000
local MAX_WEIGHT_POS = 1
local MIN_CG = 22
local MIN_CG_LOW_POS = MID_CG_POS - 34.3
local MIN_CG_HIGH_POS = MID_CG_POS - 24.8

local function calc_opt_fl(dist)
	local selected_fl = interpolate(optimal_fl_tbl, dist)
	local rounded_fl = math.floor(selected_fl / 10) * 10
	return rounded_fl
end

local function calc_fuel(dist, flightlevel)
    FUEL_INTERP_TABLE[1][2] = interpolate(fl_200_tbl, dist)
    FUEL_INTERP_TABLE[2][2] = interpolate(fl_230_tbl, dist)
    FUEL_INTERP_TABLE[3][2] = interpolate(fl_250_tbl, dist)
    FUEL_INTERP_TABLE[4][2] = interpolate(fl_270_tbl, dist)
    FUEL_INTERP_TABLE[5][2] = interpolate(fl_290_tbl, dist)
    FUEL_INTERP_TABLE[6][2] = interpolate(fl_310_tbl, dist)
    FUEL_INTERP_TABLE[7][2] = interpolate(fl_330_tbl, dist)
    FUEL_INTERP_TABLE[8][2] = interpolate(fl_350_tbl, dist)
    FUEL_INTERP_TABLE[9][2] = interpolate(fl_370_tbl, dist)
    FUEL_INTERP_TABLE[10][2] = interpolate(fl_390_tbl, dist)
    return interpolate(FUEL_INTERP_TABLE, flightlevel)
end

-- initial weights setup
	--set(payload, 0)
	set(CG_load, 0.077616)
	--set(CG_load, (26 - 25) * 5.28 / 100 - 0.3)
	if get(gear1_deflect) > 0 then set(CG_load, (26 - 25) * 5.28 / 100) end
	set(fuel_q_1, 3300)
	set(fuel_q_4, 0)
	set(fuel_q_2L, 1500)
	set(fuel_q_2R, 1500)
	set(fuel_q_3L, 3225)
	set(fuel_q_3R, 3225)
	
local function calc_CG(weight, index)
    -- Convert loading-diagram index to percent MAC.
    local z = (weight - MIN_WEIGHT) * MAX_WEIGHT_POS / (MAX_WEIGHT - MIN_WEIGHT)
    local denominator = z * MIN_CG_HIGH_POS - z * MIN_CG_LOW_POS + MIN_CG_LOW_POS * MAX_WEIGHT_POS
    local b = ((MID_CG_POS - index) * MIN_CG_LOW_POS * MAX_WEIGHT_POS) / denominator
    return MID_CG - b * (MID_CG - MIN_CG) / MIN_CG_LOW_POS
end
--[[
local CG_added = false
local CG_removed = false
--]]

function update()
	-- get entered and calculated values
	STATE.crew_num = get(crew_num_pr)
	STATE.zone_1 = get(zone_1_pr)
	STATE.zone_2 = get(zone_2_pr)
	STATE.cabin_num = get(cabin_num_pr)
	STATE.zone_4 = get(zone_4_pr)
	STATE.zone_5 = get(zone_5_pr)
	STATE.zone_6 = get(zone_6_pr)
	STATE.cargo_1 = get(cargo_1_pr)
	STATE.cargo_2 = get(cargo_2_pr)
	STATE.kitchens = get(kitchens_pr)
	STATE.various = get(various_pr)
	STATE.main_dist = get(main_dist_pr)
	STATE.alt_dist = get(alt_dist_pr)
	STATE.main_fl = get(main_fl_pr) -- minimum - 140
	STATE.alt_fl = get(alt_fl_pr) -- minimum - 140
	STATE.nav_fuel = get(nav_fuel_pr)
	STATE.taxi_fuel = get(taxi_fuel_pr)
	STATE.tank_1 = get(tank_1_pr)
	STATE.tank_2L = get(tank_2L_pr)
	STATE.tank_2R = get(tank_2R_pr)
	STATE.tank_3L = get(tank_3L_pr)
	STATE.tank_3R = get(tank_3R_pr)
	STATE.tank_4 = get(tank_4_pr)
	
	-- calculate final load
	local pax_num = STATE.zone_1 + STATE.zone_2 + STATE.zone_4 + STATE.zone_5 + STATE.zone_6
	local pax_weight = pax_num * 75 -- weight of passengers
	STATE.cargo_load = STATE.cargo_1 + STATE.cargo_2
	STATE.traffic_load = pax_weight + STATE.cargo_load
	STATE.dry_op_weight = 54865 + STATE.crew_num * 80 + STATE.cabin_num * 75 + STATE.kitchens + STATE.various
	STATE.zero_fuel_weight = STATE.dry_op_weight + STATE.traffic_load
	
	-- Recalculate planned fuel only when the corresponding route inputs change.
	local main_route_changed = STATE.main_dist ~= STATE.main_dist_last or STATE.main_fl ~= STATE.main_fl_last
	local alt_route_changed = STATE.alt_dist ~= STATE.alt_dist_last or STATE.alt_fl ~= STATE.alt_fl_last

	if main_route_changed then
		STATE.main_fuel = calc_fuel(STATE.main_dist, STATE.main_fl)
	end
	if alt_route_changed then
		STATE.alt_fuel = calc_fuel(STATE.alt_dist, STATE.alt_fl)
	end

	STATE.main_fuel = math.ceil(STATE.main_fuel)
	STATE.alt_fuel = math.ceil(STATE.alt_fuel)

	if main_route_changed or alt_route_changed then
		STATE.nav_fuel = math.ceil((STATE.main_fuel + STATE.alt_fuel) * 0.05)
		set(nav_fuel_pr, STATE.nav_fuel)
	end

	STATE.main_dist_last = STATE.main_dist
	STATE.main_fl_last = STATE.main_fl
	STATE.alt_dist_last = STATE.alt_dist
	STATE.alt_fl_last = STATE.alt_fl
	STATE.total_fuel = STATE.main_fuel + STATE.alt_fuel + STATE.nav_fuel + STATE.taxi_fuel
	STATE.total_fuel_actual = STATE.tank_1 + STATE.tank_4 + STATE.tank_2L + STATE.tank_2R + STATE.tank_3L + STATE.tank_3R
	--takeoff_fuel = STATE.total_fuel_actual - STATE.taxi_fuel
	STATE.takeoff_weight = STATE.zero_fuel_weight + STATE.total_fuel_actual-- + takeoff_fuel
	STATE.trip_fuel = STATE.main_fuel + STATE.nav_fuel
	STATE.landing_weight = STATE.takeoff_weight - STATE.trip_fuel
	
	-- CG calculations
	local ZFW_idx = LOAD_INDEX.initial_index + LOAD_INDEX.cockpit_crew_idx * STATE.crew_num + LOAD_INDEX.cabin_crew_idx * STATE.cabin_num + LOAD_INDEX.zone_1_idx * STATE.zone_1 + LOAD_INDEX.zone_2_idx * STATE.zone_2
	ZFW_idx = ZFW_idx + LOAD_INDEX.zone_4_idx * STATE.zone_4 + LOAD_INDEX.zone_5_idx * STATE.zone_5 + LOAD_INDEX.zone_6_idx * STATE.zone_6
	ZFW_idx = ZFW_idx + LOAD_INDEX.cargo_1_idx * STATE.cargo_1 + LOAD_INDEX.cargo_2_idx * STATE.cargo_2 + LOAD_INDEX.kitchen_idx * STATE.kitchens + LOAD_INDEX.tools_tdx * STATE.various
	local TOW_idx = ZFW_idx + LOAD_INDEX.tank_1_idx * STATE.tank_1 + LOAD_INDEX.tank_2_idx * (STATE.tank_2L + STATE.tank_2R) + LOAD_INDEX.tank_3_idx * (STATE.tank_3L + STATE.tank_3R) + LOAD_INDEX.tank_4_idx * STATE.tank_4
	
	-- calculate landing fuel amount
	local tank2_land = STATE.tank_2L + STATE.tank_2R
	local tank3_land = STATE.tank_3L + STATE.tank_3R
	local tank4_land = STATE.tank_4
	local tank1_land = STATE.tank_1
	--take fuel from tanks
	tank2_land = tank2_land - STATE.trip_fuel
	if tank2_land < 100 then 
		tank2_land = 100
		tank3_land = tank3_land - (STATE.trip_fuel - (STATE.tank_2L + STATE.tank_2R))
		if tank3_land < 100 then 
			tank3_land = 100
			tank4_land = tank4_land - (STATE.trip_fuel - (STATE.tank_2L + STATE.tank_2R + STATE.tank_3L + STATE.tank_3R))
			if tank4_land < 50 then
				tank4_land = 50
				tank1_land = tank1_land - (STATE.trip_fuel - (STATE.tank_2L + STATE.tank_2R + STATE.tank_3L + STATE.tank_3R + tank4_land))
				if tank1_land < 50 then tank1_land = 50 end
			end
		end
	end
	local LFW_idx = ZFW_idx + LOAD_INDEX.tank_1_idx * tank1_land + LOAD_INDEX.tank_2_idx * tank2_land + LOAD_INDEX.tank_3_idx * tank3_land + LOAD_INDEX.tank_4_idx * tank4_land
	STATE.zfw_cg = calc_CG(STATE.zero_fuel_weight, ZFW_idx)
	STATE.to_cg = calc_CG(STATE.takeoff_weight, TOW_idx)
	STATE.land_cg = calc_CG(STATE.landing_weight, LFW_idx)
	STATE.cargo_1_fill = STATE.cargo_1 / 12900
	STATE.cargo_2_fill = STATE.cargo_2 / 10400
	STATE.tank_1_fill = STATE.tank_1 / 3300
	STATE.tank_4_fill = STATE.tank_4 / 6595
	STATE.tank_2L_fill = STATE.tank_2L / 9500
	STATE.tank_2R_fill = STATE.tank_2R / 9500
	STATE.tank_3L_fill = STATE.tank_3L / 5405
	STATE.tank_3R_fill = STATE.tank_3R / 5405
	local opt_M_main = interpolate(optimal_mach_tbl, STATE.main_fl)
	local opt_M_altn = interpolate(optimal_mach_tbl, STATE.alt_fl)
	opt_M_main = math.floor(opt_M_main * 100 + 0.5) / 100
	opt_M_altn = math.floor(opt_M_altn * 100 + 0.5) / 100
	STATE.optimal_mach = opt_M_main.." / "..opt_M_altn
	-- stab set calcs
	local to_stab = "FWD"
	if STATE.to_cg > 32 then to_stab = "AFT"
	elseif STATE.to_cg >= 24 and STATE.to_cg <=32 then to_stab = "CTR" end
	local ld_stab = "FWD"
	if STATE.land_cg > 32 then ld_stab = "AFT"
	elseif STATE.land_cg >= 24 and STATE.land_cg <=32 then ld_stab = "CTR" end
	local zfw_stab = "FWD"
	if STATE.zfw_cg > 32 then zfw_stab = "AFT"
	elseif STATE.zfw_cg >= 24 and STATE.zfw_cg <=32 then zfw_stab = "CTR" end
	STATE.stab_set = zfw_stab.."/"..to_stab.."/"..ld_stab
	STATE.zfw_overweight = STATE.zero_fuel_weight > 74000
	STATE.to_overweight = STATE.takeoff_weight > 100000
	STATE.land_overweight = STATE.landing_weight > 80000
	--if STATE.to_overweight then STATE.takeoff_weight = STATE.takeoff_weight.." OVER!" end
	--if STATE.land_overweight then STATE.landing_weight = STATE.landing_weight.." OVER!" end
	--if STATE.zfw_overweight then STATE.zero_fuel_weight = STATE.zero_fuel_weight.." OVER!" end
	-- prepare values to show as text
	if STATE.zone_1 < 10 then STATE.zone_1 = " "..STATE.zone_1 end
	if STATE.zone_2 < 10 then STATE.zone_2 = " "..STATE.zone_2 end
	if STATE.zone_4 < 10 then STATE.zone_4 = " "..STATE.zone_4 end
	if STATE.zone_5 < 10 then STATE.zone_5 = " "..STATE.zone_5 end
	if STATE.zone_6 < 10 then STATE.zone_6 = " "..STATE.zone_6 end
	if STATE.cargo_1 < 1000 then STATE.cargo_1 = "  "..STATE.cargo_1
	elseif STATE.cargo_1 < 10000 then STATE.cargo_1 = " "..STATE.cargo_1 end
	STATE.cargo_1 = STATE.cargo_1.." kg"
	if STATE.cargo_2 < 1000 then STATE.cargo_2 = "  "..STATE.cargo_2
	elseif STATE.cargo_2 < 10000 then STATE.cargo_2 = " "..STATE.cargo_2 end
	STATE.cargo_2 = STATE.cargo_2.." kg"
	if STATE.kitchens < 100 then STATE.kitchens = " "..STATE.kitchens end
	if STATE.various < 100 then STATE.various = " "..STATE.various end
	STATE.total_pax_load = pax_num.." / "..pax_weight
	if STATE.main_dist < 1000 then STATE.main_dist = " "..STATE.main_dist end
	if STATE.alt_dist < 1000 then STATE.alt_dist = " "..STATE.alt_dist end
	STATE.main_fuel_show = STATE.main_fuel
	if STATE.main_fuel < 1000 then STATE.main_fuel_show = "  "..STATE.main_fuel_show
	elseif STATE.main_fuel < 10000 then STATE.main_fuel_show = " "..STATE.main_fuel_show end
	STATE.alt_fuel_show = STATE.alt_fuel
	if STATE.alt_fuel < 1000 then STATE.alt_fuel_show = "  "..STATE.alt_fuel_show
	elseif STATE.alt_fuel < 10000 then STATE.alt_fuel_show = " "..STATE.alt_fuel_show end
	if STATE.nav_fuel < 1000 then STATE.nav_fuel = " "..STATE.nav_fuel end
	if STATE.taxi_fuel < 1000 then STATE.taxi_fuel = " "..STATE.taxi_fuel end
	STATE.total_fuel_show = STATE.total_fuel
	if STATE.total_fuel < 1000 then STATE.total_fuel_show = "  "..STATE.total_fuel_show
	elseif STATE.total_fuel < 10000 then STATE.total_fuel_show = " "..STATE.total_fuel_show end
	if STATE.total_fuel > 39750 or STATE.total_fuel < 12750 then STATE.total_fuel_show = STATE.total_fuel_show.." !" end
	if STATE.total_fuel < 12750 then STATE.fuel_over_limits = -1 
	elseif STATE.total_fuel > 39750 then STATE.fuel_over_limits = 1 
	else STATE.fuel_over_limits = 0 end
	STATE.zfw_cg = math.floor(STATE.zfw_cg * 100 + 0.5)/ 100
	STATE.to_cg = math.floor(STATE.to_cg * 100 + 0.5)/ 100
	STATE.land_cg = math.floor(STATE.land_cg * 100 + 0.5)/ 100
	if STATE.tank_1 < 1000 then STATE.tank_1 = " "..STATE.tank_1 end
	if STATE.tank_4 < 1000 then STATE.tank_4 = " "..STATE.tank_4 end
	if STATE.tank_2L < 1000 then STATE.tank_2L = " "..STATE.tank_2L end
	if STATE.tank_2R < 1000 then STATE.tank_2R = " "..STATE.tank_2R end
	if STATE.tank_3L < 1000 then STATE.tank_3L = " "..STATE.tank_3L end
	if STATE.tank_3R < 1000 then STATE.tank_3R = " "..STATE.tank_3R end
	--print(STATE.takeoff_weight, "  ", STATE.to_cg, "  ", STATE.land_cg)
	-- load results
	if get(load_fuel_btn) == 1 then
		if STATE.total_fuel < 12750 then
			set(tank_1_pr, 3300)
			set(tank_4_pr, 0)
			set(tank_2L_pr, 1500)
			set(tank_2R_pr, 1500)
			set(tank_3L_pr, 3225)
			set(tank_3R_pr, 3225)
		elseif STATE.total_fuel > 39750 then
			set(tank_1_pr, 3300)
			set(tank_4_pr, 6595)
			set(tank_2L_pr, 9500)
			set(tank_2R_pr, 9500)
			set(tank_3L_pr, 5405)
			set(tank_3R_pr, 5405)
		else
			set(tank_1_pr, 3300)
			if STATE.total_fuel < 21550 then
				local tank32 = STATE.total_fuel - 6750 
				set(tank_2L_pr, math.ceil((tank32 / 4)/25)*25)
				set(tank_2R_pr, math.ceil((tank32 / 4)/25)*25)
				set(tank_3L_pr, math.ceil((tank32 / 4)/25)*25 + 1725)
				set(tank_3R_pr, math.ceil((tank32 / 4)/25)*25 + 1725)
				set(tank_4_pr, 0)
			elseif STATE.total_fuel < 33150 then
				local tank2 = STATE.total_fuel - 14150
				set(tank_2L_pr, math.ceil((tank2 / 2)/25)*25)
				set(tank_2R_pr, math.ceil((tank2 / 2)/25)*25)
				set(tank_3L_pr, 5405)
				set(tank_3R_pr, 5405)
				set(tank_4_pr, 0)
			else	
				set(tank_2L_pr, 9500)
				set(tank_2R_pr, 9500)
				set(tank_3L_pr, 5405)
				set(tank_3R_pr, 5405)
				set(tank_4_pr, math.ceil((STATE.total_fuel - 33150)/25)*25)
			end
		end	
	end

	-- fast load
	if get(load_fast_btn) == 1 then
		set(payload, STATE.zero_fuel_weight - 54865)
		if get(gear1_deflect) > 0 then 
			set(CG_load, (STATE.zfw_cg - 25) * 5.28 / 100) 
		else
			set(CG_load, (STATE.zfw_cg - 25) * 5.28 / 100 - 0.2)
		end
		set(fuel_q_1, get(tank_1_pr))
		set(fuel_q_4, get(tank_4_pr))
		set(fuel_q_2L, get(tank_2L_pr))
		set(fuel_q_2R, get(tank_2R_pr))
		set(fuel_q_3L, get(tank_3L_pr))
		set(fuel_q_3R, get(tank_3R_pr))
		--set(show_load_panel, 0)	
	end
	-- slow load
	if get(load_slow_btn) == 1 then
		set(paylod_set, STATE.zero_fuel_weight - 54865)
		--set(cg_set, (STATE.zfw_cg - 25) * 5.28 / 100 - 0.3)
		if get(gear1_deflect) > 0 then 
			set(cg_set, (STATE.zfw_cg - 25) * 5.28 / 100) 
		else
			set(cg_set, (STATE.zfw_cg - 25) * 5.28 / 100 - 0.2)
		end
		--set(show_load_panel, 0)	
	end

	updateAll(components)
end

--init_load()
components = {
	-- white background
	rectangle {
		position = {0, 0, size[1], size[2]},
		color = {0.7, 1, 0.7, 1},
	},
	-- cargo background
	rectangle {
		position = {185, 527, 600, 60},
		color = {0.8, 0.8, 0.8, 1},
	},	
	-- STATE.cargo_1 fill
	rectangle_ctr_fuel {
		R = 0.5,
		G = 0.5,
		B = 1.0,
		A = 1,
		position_x = 200,
		position_y = 532,
		width = 200,
		height = function()
			return 32 * STATE.cargo_1_fill
		end,
	},	
	-- STATE.cargo_2 fill
	rectangle_ctr_fuel {
		R = 0.5,
		G = 0.5,
		B = 1.0,
		A = 1,
		position_x = 569,
		position_y = 532,
		width = 200,
		height = function()
			return 32 * STATE.cargo_2_fill
		end,
	},		
	-- STATE.tank_1_fill
	rectangle_ctr_fuel {
		R = 0.5,
		G = 0.5,
		B = 1.0,
		A = 1,
		position_x = 245,
		position_y = 93,
		width = 91,
		height = function()
			return 59 * STATE.tank_1_fill
		end,
	},		
	-- STATE.tank_4_fill
	rectangle_ctr_fuel {
		R = 0.5,
		G = 0.5,
		B = 1.0,
		A = 1,
		position_x = 245,
		position_y = 161,
		width = 91,
		height = function()
			return 59 * STATE.tank_4_fill
		end,
	},		
	-- STATE.tank_2L_fill
	rectangle_ctr_fuel {
		R = 0.5,
		G = 0.5,
		B = 1.0,
		A = 1,
		position_x = 138,
		position_y = 93,
		width = 102,
		height = function()
			return 123 * STATE.tank_2L_fill
		end,
	},		
	-- STATE.tank_2R_fill
	rectangle_ctr_fuel {
		R = 0.5,
		G = 0.5,
		B = 1.0,
		A = 1,
		position_x = 342,
		position_y = 93,
		width = 102,
		height = function()
			return 123 * STATE.tank_2R_fill
		end,
	},		
	-- STATE.tank_3L_fill
	rectangle_ctr_fuel {
		R = 0.5,
		G = 0.5,
		B = 1.0,
		A = 1,
		position_x = 31,
		position_y = 93,
		width = 102,
		height = function()
			return 89 * STATE.tank_3L_fill
		end,
	},	
	-- STATE.tank_3R_fill
	rectangle_ctr_fuel {
		R = 0.5,
		G = 0.5,
		B = 1.0,
		A = 1,
		position_x = 450,
		position_y = 93,
		width = 102,
		height = function()
			return 89 * STATE.tank_3R_fill
		end,
	},		
	-- zero fuel indicator
	rectangle {
		position = {820, 278, 170, 30},
		color = {0.9, 0.3, 0.3, 1},
		visible = function()
			return STATE.zfw_overweight
		end,
	},	
	-- takeoff indicator
	rectangle {
		position = {820, 210, 170, 30},
		color = {0.9, 0.3, 0.3, 1},
		visible = function()
			return STATE.to_overweight
		end,
	},		
	-- landing indicator
	rectangle {
		position = {820, 143, 170, 30},
		color = {0.9, 0.3, 0.3, 1},
		visible = function()
			return STATE.land_overweight
		end,
	},	
	-- fuel maximum indicator
	rectangle {
		position = {469, 245, 110, 32},
		color = {0.9, 0.3, 0.3, 1},
		visible = function()
			return STATE.fuel_over_limits == 1
		end,
	},
	-- fuel minimum indicator
	rectangle {
		position = {469, 245, 110, 32},
		color = {1, 0.7, 0.1, 1},
		visible = function()
			return STATE.fuel_over_limits == -1
		end,
	},
	-- zero fuel CG indicator
	rectangle {
		position = {820, 110, 170, 30},
		color = {0.9, 0.7, 0.3, 1},
		visible = function()
			return STATE.zfw_cg > 32 and STATE.takeoff_weight < 80000
		end,
	},	
	-- take off CG indicator
	rectangle {
		position = {820, 77, 170, 30},
		color = {0.9, 0.7, 0.3, 1},
		visible = function()
			return STATE.to_cg > 32 and STATE.takeoff_weight < 80000
		end,
	},	
	-- landing CG indicator
	rectangle {
		position = {820, 43, 170, 30},
		color = {0.9, 0.7, 0.3, 1},
		visible = function()
			return STATE.land_cg > 32 and STATE.takeoff_weight < 80000
		end,
	},
	-- zero fuel CG indicator
	rectangle {
		position = {820, 110, 170, 30},
		color = {0.9, 0.3, 0.3, 1},
		visible = function()
			return STATE.zfw_cg > 40 or (STATE.zfw_cg > 32 and STATE.takeoff_weight >= 80000) or STATE.zfw_cg < 18
		end,
	},	
	-- take off CG indicator
	rectangle {
		position = {820, 77, 170, 30},
		color = {0.9, 0.3, 0.3, 1},
		visible = function()
			return STATE.to_cg > 40 or (STATE.to_cg > 32 and STATE.takeoff_weight >= 80000) or STATE.to_cg < 18
		end,
	},	
	-- landing CG indicator
	rectangle {
		position = {820, 43, 170, 30},
		color = {0.9, 0.3, 0.3, 1},
		visible = function()
			return STATE.land_cg > 40 or (STATE.land_cg > 32 and STATE.takeoff_weight >= 80000) or STATE.land_cg < 18
		end,
	},		
	-------------------------------
	-- background
	textureLit {
		position = {0, 0, size[1], size[2]},
		image = get(bg_img),
		visible = function()
			return get(hide_eng_objects) == 0
		end,
	},
	textureLit {
		position = {0, 0, size[1], size[2]},
		image = get(bg_img_rus),
		visible = function()
			return get(hide_eng_objects) == 1
		end,
	},
	------------------------
	-- values --
	------------------------
	-- crew number
	text_draw {
		position = {150, 580, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.crew_num
		end,
	},
	-- zone 1 number
	text_draw {
		position = {216, 580, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.zone_1
		end,
	},	
	-- zone 2 number
	text_draw {
		position = {310, 580, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.zone_2
		end,
	},		
	-- cabin crew number
	text_draw {
		position = {416, 580, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.cabin_num
		end,
	},		
	-- zone 4 number
	text_draw {
		position = {513, 580, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.zone_4
		end,
	},		
	-- zone 5 number
	text_draw {
		position = {638, 580, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.zone_5
		end,
	},		
	-- zone 6 number
	text_draw {
		position = {728, 580, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.zone_6
		end,
	},	
	-- cargo 1 load
	text_draw {
		position = {255, 540, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.cargo_1
		end,
	},
	-- cargo 2 load
	text_draw {
		position = {605, 540, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.cargo_2
		end,
	},	
	-- STATE.kitchens load
	text_draw {
		position = {662, 494, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.kitchens
		end,
	},
	-- STATE.kitchens load
	text_draw {
		position = {930, 494, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.various
		end,
	},
	---------------------------
	-- fuel values --
	-----------------------
	-- main distance
	text_draw {
		position = {213, 405, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.main_dist
		end,
	},	
	-- alternate distance
	text_draw {
		position = {500, 405, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.alt_dist
		end,
	},		
	-- main flight level
	text_draw {
		position = {220, 372, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.main_fl
		end,
	},	
	-- alternate flight level
	text_draw {
		position = {505, 372, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.alt_fl
		end,
	},		
	-- main fuel
	text_draw {
		position = {207, 338, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.main_fuel_show
		end,
	},	
	-- alternate fuel
	text_draw {
		position = {492, 338, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.alt_fuel_show
		end,
	},	
	-- nav fuel
	text_draw {
		position = {213, 288, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.nav_fuel
		end,
	},	
	-- alternate distance
	text_draw {
		position = {500, 288, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.taxi_fuel
		end,
	},	
	-- total fuel
	text_draw {
		position = {495, 255, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.total_fuel_show
		end,
	},	
	-- fuel tank 1
	text_draw {
		position = {265, 100, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.tank_1
		end,
	},	
	-- fuel tank 4
	text_draw {
		position = {265, 168, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.tank_4
		end,
	},
	-- fuel tank 2L
	text_draw {
		position = {164, 100, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.tank_2L
		end,
	},	
	-- fuel tank 2R
	text_draw {
		position = {368, 100, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.tank_2R
		end,
	},	
	-- fuel tank 3L
	text_draw {
		position = {56, 100, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.tank_3L
		end,
	},	
	-- fuel tank 3R
	text_draw {
		position = {475, 100, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.tank_3R
		end,
	},
	-- optimal mach
	text_draw {
		position = {160, 255, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.optimal_mach
		end,
	},
	--------------------------
	-- result values --
	-------------------------
	-- tottal pax load number
	text_draw {
		position = {840, 419, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.total_pax_load
		end,
	},		
	-- total cargo load
	text_draw {
		position = {840, 385, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.cargo_load
		end,
	},	
	-- total traffic load
	text_draw {
		position = {840, 351, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.traffic_load
		end,
	},	
	-- dry operating weight
	text_draw {
		position = {840, 318, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.dry_op_weight
		end,
	},
	-- dry operating weight
	text_draw {
		position = {840, 284, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			if STATE.zfw_overweight then return STATE.zero_fuel_weight.." OVER!"
			else return STATE.zero_fuel_weight
			end
		end,
	},
	-- takeoff fuel
	text_draw {
		position = {840, 251, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.total_fuel_actual
		end,
	},
	-- takeoff weight
	text_draw {
		position = {840, 219, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			if STATE.to_overweight then return STATE.takeoff_weight.." OVER!"
			else return STATE.takeoff_weight
			end
		end,
	},
	-- trip fuel
	text_draw {
		position = {840, 184, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.trip_fuel
		end,
	},
	-- landing weight
	text_draw {
		position = {840, 151, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			if STATE.land_overweight then return STATE.landing_weight.." OVER!"
			else return STATE.landing_weight
			end
		end,
	},
	-- ZFW CG
	text_draw {
		position = {840, 118, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			if STATE.zfw_cg < 18 then return STATE.zfw_cg.."  FWD!"
			elseif STATE.zfw_cg > 32 then return STATE.zfw_cg.."  AFT!" 
			else return STATE.zfw_cg
			end
		end,
	},
	-- TO CG
	text_draw {
		position = {840, 85, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			if STATE.to_cg < 18 then return STATE.to_cg.."  FWD!"
			elseif STATE.to_cg > 32 then return STATE.to_cg.."  AFT!" 
			else return STATE.to_cg
			end
		end,
	},
	-- Landing CG
	text_draw {
		position = {840, 51, 60, 60},
		color = {0, 0, 0, 1},
		text = function()
			if STATE.land_cg < 18 then return STATE.land_cg.."  FWD!"
			elseif STATE.land_cg > 32 then return STATE.land_cg.."  AFT!" 
			else return STATE.land_cg
			end
		end,
	},
	-- stab settings
	text_draw {
		position = {840, 18, 57, 60},
		color = {0, 0, 0, 1},
		text = function()
			return STATE.stab_set
		end,
	},	
	------------------
	-- interactives --
	------------------
	-- cockpit crew	
	interactive {
		position = {121, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(crew_num_pr) - 1
			if a < 3 then a = 3 end
			set(crew_num_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {163, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(crew_num_pr) + 1
			if a > 5 then a = 5 end
			set(crew_num_pr, a)
			return true
		end,
	}, 	
	-- ZONE 1
	interactive {
		position = {194, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(zone_1_pr) - 1
			if a < 0 then a = 0 end
			set(zone_1_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {237, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(zone_1_pr) + 1
			if a > 18 then a = 18 end
			set(zone_1_pr, a)
			return true
		end,
	}, 	
	-- ZONE 2
	interactive {
		position = {278, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(zone_2_pr) - 1
			if a < 0 then a = 0 end
			set(zone_2_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {338, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(zone_2_pr) + 1
			if a > 44 then a = 44 end
			set(zone_2_pr, a)
			return true
		end,
	}, 	
	-- Cabin crew
	interactive {
		position = {378, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(cabin_num_pr) - 1
			if a < 0 then a = 0 end
			set(cabin_num_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {431, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(cabin_num_pr) + 1
			if a > 7 then a = 7 end
			set(cabin_num_pr, a)
			return true
		end,
	}, 	
	-- Zone 4
	interactive {
		position = {481, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(zone_4_pr) - 1
			if a < 0 then a = 0 end
			set(zone_4_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {540, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(zone_4_pr) + 1
			if a > 48 then a = 48 end
			set(zone_4_pr, a)
			return true
		end,
	}, 
	-- Zone 5
	interactive {
		position = {606, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(zone_5_pr) - 1
			if a < 0 then a = 0 end
			set(zone_5_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {665, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(zone_5_pr) + 1
			if a > 42 then a = 42 end
			set(zone_5_pr, a)
			return true
		end,
	}, 
	-- Zone 6
	interactive {
		position = {703, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(zone_6_pr) - 1
			if a < 0 then a = 0 end
			set(zone_6_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {748, 572, 30, 30 },
		onMouseDown = function() 
			local a = get(zone_6_pr) + 1
			if a > 14 then a = 14 end
			set(zone_6_pr, a)
			return true
		end,
	}, 
	-- Cargo 1
	interactive {
		position = {211, 533, 30, 30 },
		onMouseDown = function() 
			local a = get(cargo_1_pr) - 100
			if a < 0 then a = 0 end
			set(cargo_1_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {362, 533, 30, 30 },
		onMouseDown = function() 
			local a = get(cargo_1_pr) + 100
			if a > 12900 then a = 12900 end
			set(cargo_1_pr, a)
			return true
		end,
	}, 
	-- Cargo 2
	interactive {
		position = {572, 533, 30, 30 },
		onMouseDown = function() 
			local a = get(cargo_2_pr) - 100
			if a < 0 then a = 0 end
			set(cargo_2_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {706, 533, 30, 30 },
		onMouseDown = function() 
			local a = get(cargo_2_pr) + 100
			if a > 10400 then a = 10400 end
			set(cargo_2_pr, a)
			return true
		end,
	},	
	-- Kitchens
	interactive {
		position = {631, 488, 30, 30 },
		onMouseDown = function() 
			local a = get(kitchens_pr) - 10
			if a < 0 then a = 0 end
			set(kitchens_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {705, 488, 30, 30 },
		onMouseDown = function() 
			local a = get(kitchens_pr) + 10
			if a > 500 then a = 500 end
			set(kitchens_pr, a)
			return true
		end,
	},	
	-- Equipment
	interactive {
		position = {896, 488, 30, 30 },
		onMouseDown = function() 
			local a = get(various_pr) - 10
			if a < 50 then a = 50 end
			set(various_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {971, 488, 30, 30 },
		onMouseDown = function() 
			local a = get(various_pr) + 10
			if a > 500 then a = 500 end
			set(various_pr, a)
			return true
		end,
	},	
	-- 0% load
	interactive {
		position = {185, 486, 45, 35 },
		onMouseDown = function() 
			set(zone_1_pr, 0)
			set(zone_2_pr, 0)
			set(zone_4_pr, 0)
			set(zone_5_pr, 0)
			set(zone_6_pr, 0)
			set(cabin_num_pr, 0)
			set(cargo_1_pr, 0)
			set(cargo_2_pr, 0)
			return true
		end,
	}, 
	-- 25% load
	interactive {
		position = {233, 486, 53, 35 },
		onMouseDown = function() 
			set(zone_1_pr, math.random(3, 6))
			set(zone_2_pr, math.random(8, 14))
			set(zone_4_pr, math.random(9, 15))
			set(zone_5_pr, math.random(7, 13))
			set(zone_6_pr, math.random(2, 6))
			set(cabin_num_pr, 3)
			return true
		end,
	}, 	
	-- 50% load
	interactive {
		position = {290, 486, 53, 35 },
		onMouseDown = function() 
			set(zone_1_pr, math.random(7, 11))
			set(zone_2_pr, math.random(19, 25))
			set(zone_4_pr, math.random(21, 27))
			set(zone_5_pr, math.random(18, 24))
			set(zone_6_pr, math.random(5, 9))
			set(cabin_num_pr, 4)
			return true
		end,
	}, 
	-- 75% load
	interactive {
		position = {346, 486, 53, 35 },
		onMouseDown = function() 
			set(zone_1_pr, math.random(12, 16))
			set(zone_2_pr, math.random(30, 36))
			set(zone_4_pr, math.random(33, 39))
			set(zone_5_pr, math.random(29, 35))
			set(zone_6_pr, math.random(8, 12))
			set(cabin_num_pr, 5)
			return true
		end,
	}, 	
	-- 100% load
	interactive {
		position = {402, 486, 61, 35 },
		onMouseDown = function() 
			set(zone_1_pr, 18)
			set(zone_2_pr, 44)
			set(zone_4_pr, 48)
			set(zone_5_pr, 42)
			set(zone_6_pr, 14)
			set(cabin_num_pr, 6)
			return true
		end,
	}, 	
	-- Main distance
	interactive {
		position = {186, 398, 30, 30 },
		onMouseDown = function() 
			local a = get(main_dist_pr) - 100
			if a < 0 then a = 0 end
			set(main_dist_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {263, 398, 30, 30 },
		onMouseDown = function() 
			local a = get(main_dist_pr) + 100
			if a > 5000 then a = 5000 end
			set(main_dist_pr, a)
			return true
		end,
	},		
	-- Alternate distance
	interactive {
		position = {471, 398, 30, 30 },
		onMouseDown = function() 
			local a = get(alt_dist_pr) - 100
			if a < 0 then a = 0 end
			set(alt_dist_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {549, 398, 30, 30 },
		onMouseDown = function() 
			local a = get(alt_dist_pr) + 100
			if a > 5000 then a = 5000 end
			set(alt_dist_pr, a)
			return true
		end,
	},		
	-- Main FL
	interactive {
		position = {186, 366, 30, 30 },
		onMouseDown = function() 
			local a = get(main_fl_pr) - 10
			if a < 200 then a = 200 end
			set(main_fl_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {263, 366, 30, 30 },
		onMouseDown = function() 
			local a = get(main_fl_pr) + 10
			if a > 390 then a = 390 end
			set(main_fl_pr, a)
			return true
		end,
	},		
	-- Alternate FL
	interactive {
		position = {471, 366, 30, 30 },
		onMouseDown = function() 
			local a = get(alt_fl_pr) - 10
			if a < 200 then a = 200 end
			set(alt_fl_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {549, 366, 30, 30 },
		onMouseDown = function() 
			local a = get(alt_fl_pr) + 10
			if a > 390 then a = 390 end
			set(alt_fl_pr, a)
			return true
		end,
	},	
	-- Optimal main FL
	interactive {
		position = {133, 362, 50, 35 },
		onMouseDown = function() 
			local fl = calc_opt_fl(get(main_dist_pr))
			set(main_fl_pr, fl)
			return true
		end,
	},
	-- Optimal alt FL
	interactive {
		position = {419, 362, 50, 35 },
		onMouseDown = function() 
			local fl = calc_opt_fl(get(alt_dist_pr))
			set(alt_fl_pr, fl)
			return true
		end,
	},
	-- Navigation fuel
	interactive {
		position = {186, 282, 30, 30 },
		onMouseDown = function() 
			local a = get(nav_fuel_pr) - 100
			if a < 0 then a = 0 end
			set(nav_fuel_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {263, 282, 30, 30 },
		onMouseDown = function() 
			local a = get(nav_fuel_pr) + 100
			if a > 5000 then a = 5000 end
			set(nav_fuel_pr, a)
			return true
		end,
	},		
	-- Taxi fuel
	interactive {
		position = {471, 282, 30, 30 },
		onMouseDown = function() 
			local a = get(taxi_fuel_pr) - 100
			if a < 0 then a = 0 end
			set(taxi_fuel_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {549, 282, 30, 30 },
		onMouseDown = function() 
			local a = get(taxi_fuel_pr) + 100
			if a > 1000 then a = 1000 end
			set(taxi_fuel_pr, a)
			return true
		end,
	},
	-- minimum fuel load
	interactive {
		position = {20, 202, 56, 37 },
		onMouseDown = function() 
			set(tank_1_pr, 3300)
			set(tank_4_pr, 0)
			set(tank_2L_pr, 1500)
			set(tank_2R_pr, 1500)
			set(tank_3L_pr, 3225)
			set(tank_3R_pr, 3225)
			return true
		end,
	},
	-- maximum fuel load
	interactive {
		position = {84, 202, 56, 37 },
		onMouseDown = function() 
			set(tank_1_pr, 3300)
			set(tank_4_pr, 6595)
			set(tank_2L_pr, 9500)
			set(tank_2R_pr, 9500)
			set(tank_3L_pr, 5405)
			set(tank_3R_pr, 5405)
			return true
		end,
	},
	-- Tank 4
	interactive {
		position = {242, 161, 30, 30 },
		onMouseDown = function() 
			local a = get(tank_4_pr) - 25
			if a < 0 then a = 0 end
			set(tank_4_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {310, 161, 30, 30 },
		onMouseDown = function() 
			local a = get(tank_4_pr) + 25
			if a > 6595 then a = 6595 end
			set(tank_4_pr, a)
			return true
		end,
	},	
	-- Tank 1
	interactive {
		position = {242, 93, 30, 30 },
		onMouseDown = function() 
			local a = get(tank_1_pr) - 25
			if a < 0 then a = 0 end
			set(tank_1_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {310, 93, 30, 30 },
		onMouseDown = function() 
			local a = get(tank_1_pr) + 25
			if a > 3300 then a = 3300 end
			set(tank_1_pr, a)
			return true
		end,
	},
	-- Tank 3L
	interactive {
		position = {29, 93, 30, 30 },
		onMouseDown = function() 
			local a = get(tank_3L_pr) - 25
			if a < 0 then a = 0 end
			set(tank_3L_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {102, 93, 30, 30 },
		onMouseDown = function() 
			local a = get(tank_3L_pr) + 25
			if a > 5405 then a = 5405 end
			set(tank_3L_pr, a)
			return true
		end,
	},
	-- Tank 2L
	interactive {
		position = {137, 93, 30, 30 },
		onMouseDown = function() 
			local a = get(tank_2L_pr) - 25
			if a < 0 then a = 0 end
			set(tank_2L_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {211, 93, 30, 30 },
		onMouseDown = function() 
			local a = get(tank_2L_pr) + 25
			if a > 9500 then a = 9500 end
			set(tank_2L_pr, a)
			return true
		end,
	},	
	-- Tank 2R
	interactive {
		position = {341, 93, 30, 30 },
		onMouseDown = function() 
			local a = get(tank_2R_pr) - 25
			if a < 0 then a = 0 end
			set(tank_2R_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {416, 93, 30, 30 },
		onMouseDown = function() 
			local a = get(tank_2R_pr) + 25
			if a > 9500 then a = 9500 end
			set(tank_2R_pr, a)
			return true
		end,
	},		
	-- Tank 3R
	interactive {
		position = {448, 93, 30, 30 },
		onMouseDown = function() 
			local a = get(tank_3R_pr) - 25
			if a < 0 then a = 0 end
			set(tank_3R_pr, a)
			return true
		end,
	}, 
	interactive {
		position = {523, 93, 30, 30 },
		onMouseDown = function() 
			local a = get(tank_3R_pr) + 25
			if a > 5405 then a = 5405 end
			set(tank_3R_pr, a)
			return true
		end,
	},		
	-- load fuel button
	interactive {
		position = {467, 202, 106, 37 },
		onMouseDown = function() 
			set(load_fuel_btn, 1)
			return true
		end,
		onMouseUp = function() 
			set(load_fuel_btn, 0)
			return true
		end,
	},		
	-- fast load
		interactive {
		position = {20, 17, 160, 45 },
		onMouseDown = function() 
			set(load_fast_btn, 1)
			set(save_state, 1)
			return true
		end,
		onMouseUp = function() 
			set(load_fast_btn, 0)
			set(show_load_panel, 0)
			return true
		end,
	},
	--[[
	-- slow load
		interactive {
		position = {200, 17, 210, 45 },
		onMouseDown = function() 
			set(load_slow_btn, 1)
			return true
		end,
		onMouseUp = function() 
			set(load_slow_btn, 0)
			return true
		end,
	},
--]]
	-- close button
	interactive {
		position = {429, 17, 130, 45 },
		onMouseDown = function() 
			set(show_load_panel, 0)
			return true
		end,
	},	
	interactive {
		position = {size[1]-15, size[2]-15, 15, 15 },
		onMouseDown = function() 
			set(show_load_panel, 0)
			return true
		end,
	},		
}
function draw()
	drawAll(components)
end
