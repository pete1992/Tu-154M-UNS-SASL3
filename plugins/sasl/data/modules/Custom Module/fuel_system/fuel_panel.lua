-- fuel_panel.lua
-- Updates fuel controls, quantity indications, consumption counter and lamps.

---------------------------------------------------------------------------
-- Local references for frequently used functions.
---------------------------------------------------------------------------
local get, set = get, set
local max = math.max
local playSample = sasl.al.playSample

--	true  = Cache lamp and electric gauge outputs and write only on
--				value changes
--	false = write cached lamp and electric gauge outputs every frame
local USE_WRITE_CACHE = true

---------------------------------------------------------------------------
-- Store property handles in P.
---------------------------------------------------------------------------
local P = {}
local env = (getfenv and getfenv(1)) or _ENV or _G

local function defineProps(defs)
    for i = 1, #defs do
        local d = defs[i]
        local prop
        if d[4] ~= nil then
            prop = d[3](d[2], d[4])
        else
            prop = d[3](d[2])
        end
        defineProperty(d[1], prop)
        -- Prefer a property already supplied by the component environment.
        P[d[1]] = env[d[1]] or prop
    end
end

defineProps({
    -- Gauges
    { "fuel_meter_summ", "tu154/custom/gauges/fuel/fuel_meter_summ", globalPropertyf },
    { "fuel_meter_tank1", "tu154/custom/gauges/fuel/fuel_meter_tank1", globalPropertyf },
    { "fuel_meter_tank2_left", "tu154/custom/gauges/fuel/fuel_meter_tank2_left", globalPropertyf },
    { "fuel_meter_tank2_right", "tu154/custom/gauges/fuel/fuel_meter_tank2_right", globalPropertyf },
    { "fuel_meter_tank3_left", "tu154/custom/gauges/fuel/fuel_meter_tank3_left", globalPropertyf },
    { "fuel_meter_tank3_right", "tu154/custom/gauges/fuel/fuel_meter_tank3_right", globalPropertyf },
    { "fuel_meter_tank4", "tu154/custom/gauges/fuel/fuel_meter_tank4", globalPropertyf },
    { "fuel_meter_mech", "tu154/custom/gauges/fuel/fuel_meter_mech", globalPropertyf },
    { "fuel_front_ind", "tu154/custom/gauges/misc/fuel_front_ind", globalPropertyf },
    -- Gauge test buttons: zero and maximum.
    { "fuel_meter_summ_zero", "tu154/custom/buttons/fuel/fuel_meter_summ_zero", globalPropertyf },
    { "fuel_meter_summ_max", "tu154/custom/buttons/fuel/fuel_meter_summ_max", globalPropertyf },
    { "fuel_meter_tank2_zero", "tu154/custom/buttons/fuel/fuel_meter_tank2_zero", globalPropertyf },
    { "fuel_meter_tank2_max", "tu154/custom/buttons/fuel/fuel_meter_tank2_max", globalPropertyf },
    { "fuel_meter_tank3_zero", "tu154/custom/buttons/fuel/fuel_meter_tank3_zero", globalPropertyf },
    { "fuel_meter_tank3_max", "tu154/custom/buttons/fuel/fuel_meter_tank3_max", globalPropertyf },
    { "fuel_meter_tank4_zero", "tu154/custom/buttons/fuel/fuel_meter_tank4_zero", globalPropertyf },
    { "fuel_meter_tank4_max", "tu154/custom/buttons/fuel/fuel_meter_tank4_max", globalPropertyf },
    { "fuel_front_zero", "tu154/custom/buttons/misc/fuel_front_zero", globalPropertyf },
    { "fuel_front_max", "tu154/custom/buttons/misc/fuel_front_max", globalPropertyf },
    -- Controls
    { "pump_tank2_left", "tu154/custom/switchers/fuel/pump_tank2_left", globalPropertyi },
    { "pump_tank2_right", "tu154/custom/switchers/fuel/pump_tank2_right", globalPropertyi },
    { "pump_tank3_left", "tu154/custom/switchers/fuel/pump_tank3_left", globalPropertyi },
    { "pump_tank3_right", "tu154/custom/switchers/fuel/pump_tank3_right", globalPropertyi },
    { "pump_tank4", "tu154/custom/switchers/fuel/pump_tank4", globalPropertyi },
    { "pump_tank1_1", "tu154/custom/switchers/fuel/pump_tank1_1", globalPropertyi },
    { "pump_tank1_2", "tu154/custom/switchers/fuel/pump_tank1_2", globalPropertyi },
    { "pump_tank1_3", "tu154/custom/switchers/fuel/pump_tank1_3", globalPropertyi },
    { "pump_tank1_4", "tu154/custom/switchers/fuel/pump_tank1_4", globalPropertyi },
    { "fuel_trans", "tu154/custom/switchers/fuel/fuel_trans", globalPropertyi },
    { "fuel_trans_cap", "tu154/custom/switchers/fuel/fuel_trans_cap", globalPropertyi },
    { "fuel_porc", "tu154/custom/switchers/fuel/fuel_porc", globalPropertyi },
    { "fuel_porc_cap", "tu154/custom/switchers/fuel/fuel_porc_cap", globalPropertyi },
    { "fuel_level", "tu154/custom/switchers/fuel/fuel_level", globalPropertyi },
    { "fuel_flow_mode", "tu154/custom/switchers/fuel/fuel_flow_mode", globalPropertyi },
    { "fuel_flow_on", "tu154/custom/switchers/fuel/fuel_flow_on", globalPropertyi },
    { "fuel_flow_on_cap", "tu154/custom/switchers/fuel/fuel_flow_on_cap", globalPropertyi },
    { "fuel_meter_on", "tu154/custom/switchers/fuel/fuel_meter_on", globalPropertyi },
    { "fuel_meter_mech_on", "tu154/custom/switchers/fuel/fuel_meter_mech_on", globalPropertyi },
    { "fire_valve_1", "tu154/custom/switchers/fuel/fire_valve_1", globalPropertyi },
    { "fire_valve_2", "tu154/custom/switchers/fuel/fire_valve_2", globalPropertyi },
    { "fire_valve_3", "tu154/custom/switchers/fuel/fire_valve_3", globalPropertyi },
    { "fire_valve_1_cap", "tu154/custom/switchers/fuel/fire_valve_1_cap", globalPropertyi },
    { "fire_valve_2_cap", "tu154/custom/switchers/fuel/fire_valve_2_cap", globalPropertyi },
    { "fire_valve_3_cap", "tu154/custom/switchers/fuel/fire_valve_3_cap", globalPropertyi },
    { "reserv_pump_test", "tu154/custom/buttons/eng/reserv_pump_test", globalPropertyi },
    -- Lamps
    { "fuel_tank3_left_fail", "tu154/custom/lights/small/fuel_tank3_left_fail", globalPropertyf },
    { "fuel_tank2_left_fail", "tu154/custom/lights/small/fuel_tank2_left_fail", globalPropertyf },
    { "fuel_tank2_right_fail", "tu154/custom/lights/small/fuel_tank2_right_fail", globalPropertyf },
    { "fuel_tank3_right_fail", "tu154/custom/lights/small/fuel_tank3_right_fail", globalPropertyf },
    { "fuel_pump_left_5", "tu154/custom/lights/small/fuel_pump_left_5", globalPropertyf },
    { "fuel_pump_left_6", "tu154/custom/lights/small/fuel_pump_left_6", globalPropertyf },
    { "fuel_pump_left_7", "tu154/custom/lights/small/fuel_pump_left_7", globalPropertyf },
    { "fuel_pump_left_8", "tu154/custom/lights/small/fuel_pump_left_8", globalPropertyf },
    { "fuel_pump_left_9", "tu154/custom/lights/small/fuel_pump_left_9", globalPropertyf },
    { "fuel_pump_right_5", "tu154/custom/lights/small/fuel_pump_right_5", globalPropertyf },
    { "fuel_pump_right_6", "tu154/custom/lights/small/fuel_pump_right_6", globalPropertyf },
    { "fuel_pump_right_7", "tu154/custom/lights/small/fuel_pump_right_7", globalPropertyf },
    { "fuel_pump_right_8", "tu154/custom/lights/small/fuel_pump_right_8", globalPropertyf },
    { "fuel_pump_right_9", "tu154/custom/lights/small/fuel_pump_right_9", globalPropertyf },
    { "fuel_pump_10", "tu154/custom/lights/small/fuel_pump_10", globalPropertyf },
    { "fuel_pump_11", "tu154/custom/lights/small/fuel_pump_11", globalPropertyf },
    { "fuel_pump_1", "tu154/custom/lights/small/fuel_pump_1", globalPropertyf },
    { "fuel_pump_2", "tu154/custom/lights/small/fuel_pump_2", globalPropertyf },
    { "fuel_pump_3", "tu154/custom/lights/small/fuel_pump_3", globalPropertyf },
    { "fuel_pump_4", "tu154/custom/lights/small/fuel_pump_4", globalPropertyf },
    { "fuel_cut_off_1", "tu154/custom/lights/small/fuel_cut_off_1", globalPropertyf },
    { "fuel_cut_off_2", "tu154/custom/lights/small/fuel_cut_off_2", globalPropertyf },
    { "fuel_cut_off_3", "tu154/custom/lights/small/fuel_cut_off_3", globalPropertyf },
    { "fuel_flow_from_2", "tu154/custom/lights/small/fuel_flow_from_2", globalPropertyf },
    { "fuel_flow_from_3", "tu154/custom/lights/small/fuel_flow_from_3", globalPropertyf },
    { "fuel_flow_from_4", "tu154/custom/lights/small/fuel_flow_from_4", globalPropertyf },
    { "fuel_flow_auto_fail", "tu154/custom/lights/small/fuel_flow_auto_fail", globalPropertyf },
    { "fuel_reserv_trans_left", "tu154/custom/lights/small/fuel_reserv_trans_left", globalPropertyf },
    { "fuel_reserv_trans_right", "tu154/custom/lights/small/fuel_reserv_trans_right", globalPropertyf },
    { "fuel_porc_reserv", "tu154/custom/lights/small/fuel_porc_reserv", globalPropertyf },
    { "fuel_level_automat", "tu154/custom/lights/small/fuel_level_automat", globalPropertyf },
    -- Engine inputs use one-based SASL array indices.
    { "eng1_N1", "sim/flightmodel2/engines/N1_percent", globalPropertyfae, 1 },
    { "eng2_N1", "sim/flightmodel2/engines/N1_percent", globalPropertyfae, 2 },
    { "eng3_N1", "sim/flightmodel2/engines/N1_percent", globalPropertyfae, 3 },
    { "ENGN_FF_1", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec", globalPropertyfae, 1 },
    { "ENGN_FF_2", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec", globalPropertyfae, 2 },
    { "ENGN_FF_3", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec", globalPropertyfae, 3 },
    -- Fuel tanks (m_fuel[0..5])
    { "tank1_w", "sim/flightmodel/weight/m_fuel", globalPropertyfae, 1 },
    { "tank4_w", "sim/flightmodel/weight/m_fuel", globalPropertyfae, 2 },
    { "tank2R_w", "sim/flightmodel/weight/m_fuel", globalPropertyfae, 3 },
    { "tank2L_w", "sim/flightmodel/weight/m_fuel", globalPropertyfae, 4 },
    { "tank3R_w", "sim/flightmodel/weight/m_fuel", globalPropertyfae, 5 },
    { "tank3L_w", "sim/flightmodel/weight/m_fuel", globalPropertyfae, 6 },
    { "reserv_trans", "tu154/custom/fuel/reserv_trans", globalPropertyi },
    -- Power
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },
    -- Lamp sources
    { "test_lamps", "tu154/custom/buttons/lamp_test_hydro", globalPropertyi },
    { "pump_tank2_left_work", "tu154/custom/fuel/pump_tank2_left_work", globalPropertyi },
    { "pump_tank2_right_work", "tu154/custom/fuel/pump_tank2_right_work", globalPropertyi },
    { "pump_tank3_left_work", "tu154/custom/fuel/pump_tank3_left_work", globalPropertyi },
    { "pump_tank3_right_work", "tu154/custom/fuel/pump_tank3_right_work", globalPropertyi },
    { "pump_tank4_work", "tu154/custom/fuel/pump_tank4_work", globalPropertyi },
    { "pump_tank1_1_work", "tu154/custom/fuel/pump_tank1_1_work", globalPropertyi },
    { "pump_tank1_2_work", "tu154/custom/fuel/pump_tank1_2_work", globalPropertyi },
    { "pump_tank1_3_work", "tu154/custom/fuel/pump_tank1_3_work", globalPropertyi },
    { "pump_tank1_4_work", "tu154/custom/fuel/pump_tank1_4_work", globalPropertyi },
    -- Feed selection: 0 = automatic fault; 1/2 = tank 2; 2/3 = tank 3; 4 = tank 4.
    { "auto_tanks_turn", "tu154/custom/fuel/auto_tanks_turn", globalPropertyi },
    -- -1 = L, 0 = none, +1 = R
    { "auto_tank_level_2", "tu154/custom/fuel/auto_tank_level_2", globalPropertyi },
    { "auto_tank_level_3", "tu154/custom/fuel/auto_tank_level_3", globalPropertyi },
    { "fire_vlv_open_1", "tu154/custom/fuel/fire_vlv_open_1", globalPropertyf },
    { "fire_vlv_open_2", "tu154/custom/fuel/fire_vlv_open_2", globalPropertyf },
    { "fire_vlv_open_3", "tu154/custom/fuel/fire_vlv_open_3", globalPropertyf },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    -- SmartCopilot: 0 = plugin not found, 1 = slave, 2 = master
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    -- Failures
    { "fuel_level_fail", "tu154/custom/failures/fuel_level_fail", globalPropertyi },
    { "fuel_meter_2l_fail", "tu154/custom/failures/fuel_meter_2l_fail", globalPropertyi },
    { "fuel_meter_2r_fail", "tu154/custom/failures/fuel_meter_2r_fail", globalPropertyi },
    { "fuel_meter_3l_fail", "tu154/custom/failures/fuel_meter_3l_fail", globalPropertyi },
    { "fuel_meter_3r_fail", "tu154/custom/failures/fuel_meter_3r_fail", globalPropertyi },
    { "fuel_meter_1_fail", "tu154/custom/failures/fuel_meter_1_fail", globalPropertyi },
    { "fuel_meter_4_fail", "tu154/custom/failures/fuel_meter_4_fail", globalPropertyi },
    { "fuel_meter_summ_fail", "tu154/custom/failures/fuel_meter_summ", globalPropertyi },
    { "fuel_flowmeter_1_fail", "tu154/custom/failures/fuel_flowmeter_1_fail", globalPropertyi },
    { "fuel_flowmeter_2_fail", "tu154/custom/failures/fuel_flowmeter_2_fail", globalPropertyi },
    { "fuel_flowmeter_3_fail", "tu154/custom/failures/fuel_flowmeter_3_fail", globalPropertyi },
})

---------------------------------------------------------------------------
-- Property-handle groups.
---------------------------------------------------------------------------
local function handles(names)
    local t = {}
    for i = 1, #names do
        t[i] = P[names[i]]
    end
    return t
end

-- All 31 lamp outputs are zero without electrical power.
local ALL_LAMPS = handles({
    "fuel_tank3_left_fail",
    "fuel_tank2_left_fail",
    "fuel_tank2_right_fail",
    "fuel_tank3_right_fail",
    "fuel_pump_left_5",
    "fuel_pump_left_6",
    "fuel_pump_left_7",
    "fuel_pump_left_8",
    "fuel_pump_left_9",
    "fuel_pump_right_5",
    "fuel_pump_right_6",
    "fuel_pump_right_7",
    "fuel_pump_right_8",
    "fuel_pump_right_9",
    "fuel_pump_10",
    "fuel_pump_11",
    "fuel_pump_1",
    "fuel_pump_2",
    "fuel_pump_3",
    "fuel_pump_4",
    "fuel_cut_off_1",
    "fuel_cut_off_2",
    "fuel_cut_off_3",
    "fuel_flow_from_2",
    "fuel_flow_from_3",
    "fuel_flow_from_4",
    "fuel_flow_auto_fail",
    "fuel_reserv_trans_left",
    "fuel_reserv_trans_right",
    "fuel_porc_reserv",
    "fuel_level_automat",
})

-- Sound-control index 1 must be fuel_porc for the safety-cap logic.
-- fuel_level, fuel_meter_on and fuel_meter_mech_on are passed separately.
local SW = handles({
    "fuel_porc",
    "pump_tank2_left",
    "pump_tank2_right",
    "pump_tank3_left",
    "pump_tank3_right",
    "pump_tank4",
    "pump_tank1_1",
    "pump_tank1_2",
    "pump_tank1_3",
    "pump_tank1_4",
    "fuel_trans",
    "fuel_flow_mode",
    "fuel_flow_on",
    "fire_valve_1",
    "fire_valve_2",
    "fire_valve_3",
})

-- Safety-cap index 2 must be fuel_porc_cap.
local CAPS = handles({
    "fuel_trans_cap",
    "fuel_porc_cap",
    "fuel_flow_on_cap",
    "fire_valve_1_cap",
    "fire_valve_2_cap",
    "fire_valve_3_cap",
})

-- Switches reset to zero for a cold-and-dark start.
local RESET_SW = handles({
    "pump_tank2_left",
    "pump_tank2_right",
    "pump_tank3_left",
    "pump_tank3_right",
    "pump_tank4",
    "pump_tank1_1",
    "pump_tank1_2",
    "pump_tank1_3",
    "pump_tank1_4",
    "fuel_level",
    "fuel_flow_mode",
    "fuel_flow_on",
    "fuel_meter_on",
    "fuel_meter_mech_on",
    "fire_valve_1",
    "fire_valve_2",
    "fire_valve_3",
})

---------------------------------------------------------------------------
-- Sound samples and persistent state.
---------------------------------------------------------------------------
local switcher_sound = sasl.al.loadSample("Custom Sounds/metal_switch.wav")
local cap_sound = sasl.al.loadSample("Custom Sounds/cap.wav")
-- The rotary sound is loaded but is not played by this component.

local passed = get(P.frame_time)
local notLoaded = true
local sim_start_timer = 0

---------------------------------------------------------------------------
-- Clear the output cache when SmartCopilot authority changes.
---------------------------------------------------------------------------
local cache = {}
local was_master = nil

local put = set
if USE_WRITE_CACHE then
    put = function(h, v)
        if cache[h] ~= v then
            cache[h] = v
            set(h, v)
        end
    end
end

---------------------------------------------------------------------------
-- One-time startup reset.
---------------------------------------------------------------------------
local function reset_switchers()
    if isColdAndDarkStart() and get(P.eng1_N1) < 5 and get(P.eng2_N1) < 5 and get(P.eng3_N1) < 5 then
        for i = 1, #RESET_SW do
            set(RESET_SW[i], 0)
        end
    end
    notLoaded = false
end

---------------------------------------------------------------------------
-- Detect control sounds from the sum of switch changes.
---------------------------------------------------------------------------
local sw_last = {}
for i = 1, #SW do
    sw_last[i] = get(SW[i])
end
local level_last = get(P.fuel_level)
local meter_last = get(P.fuel_meter_on)
local mech_last = get(P.fuel_meter_mech_on)

-- Return fuel_porc for the safety-cap logic.
local function check_switchers(level_sw, meter_sw, mech_sw)
    local change = level_sw + meter_sw + mech_sw - level_last - meter_last - mech_last
    local porc_sw = 0
    for i = 1, #SW do
        local v = get(SW[i])
        change = change + v - sw_last[i]
        sw_last[i] = v
        if i == 1 then
            porc_sw = v
        end
    end
    level_last, meter_last, mech_last = level_sw, meter_sw, mech_sw

    if change ~= 0 then
        playSample(switcher_sound, false)
    end
    return porc_sw
end

local cap_last = {}
for i = 1, #CAPS do
    cap_last[i] = get(CAPS[i])
end

local function caps_check(porc_sw)
    local change = 0
    for i = 1, #CAPS do
        local v = get(CAPS[i])
        change = change + v - cap_last[i]
        cap_last[i] = v
    end
    if change ~= 0 then
        playSample(cap_sound, false)
    end

    -- A closed safety cap holds fuel_porc at zero.
    if cap_last[2] == 0 and porc_sw ~= 0 then
        set(P.fuel_porc, 0)
    end
end

---------------------------------------------------------------------------
-- Mechanical fuel counter; updated only by the master.
---------------------------------------------------------------------------
local mech_counter = 0

local function mech_fuel_meter(bus_l, bus_r, mech_sw)
    local cur = get(P.fuel_meter_mech)
    local calc = cur

    mech_counter = mech_counter + passed

    if calc > 0 and mech_counter > 10 and mech_sw == 1 and (bus_l > 13 or bus_r > 13) then
        calc = calc
            - (
                    get(P.ENGN_FF_1) * (1 - get(P.fuel_flowmeter_1_fail))
                    + get(P.ENGN_FF_2) * (1 - get(P.fuel_flowmeter_2_fail))
                    + get(P.ENGN_FF_3) * (1 - get(P.fuel_flowmeter_3_fail))
                )
                * mech_counter
        mech_counter = 0
    end

    -- Write only when the value read in this frame has changed.
    if calc ~= cur then
        set(P.fuel_meter_mech, calc)
    end
end

---------------------------------------------------------------------------
-- Electric fuel-quantity gauges.
---------------------------------------------------------------------------
local summ_act, summ_front_act = 0, 0
local tank1_act, tank4_act = 0, 0
local tank2L_act, tank2R_act = 0, 0
local tank3L_act, tank3R_act = 0, 0

-- Rate-limited gauge movement with proportional settling near the target.
local function smooth(act, need, band, r1, r2, k)
    if act < need - band then
        return act + passed * r1 * r2
    elseif act > need + band then
        return act - passed * r1 * r2
    end
    return act + (need - act) * passed * k
end

local function electric_meters(bus_l, bus_r, meter_sw)
    local power = meter_sw == 1
        and (bus_l > 13 or bus_r > 13)
        and (get(P.bus115_1_volt) > 110 or get(P.bus115_3_volt) > 110)

    local summ_need, front_need, t1, t2L, t2R, t3L, t3R, t4

    if power then
        if get(P.fuel_meter_tank2_zero) == 1 then
            t2L, t2R = 0, 0
        elseif get(P.fuel_meter_tank2_max) == 1 then
            t2L, t2R = 11400, 11400
        else
            t2L, t2R = get(P.tank2L_w), get(P.tank2R_w)
        end

        if get(P.fuel_meter_tank3_zero) == 1 then
            t3L, t3R = 0, 0
        elseif get(P.fuel_meter_tank3_max) == 1 then
            t3L, t3R = 6400, 6400
        else
            t3L, t3R = get(P.tank3L_w), get(P.tank3R_w)
        end

        if get(P.fuel_meter_tank4_zero) == 1 then
            t4 = 0
        elseif get(P.fuel_meter_tank4_max) == 1 then
            t4 = 8000
        else
            t4 = get(P.tank4_w)
        end

        -- Sum the individual tank indications from the previous frame.
        summ_need = tank2L_act + tank2R_act + tank3L_act + tank3R_act + tank4_act + tank1_act
        front_need = summ_need

        if get(P.fuel_front_zero) == 1 then
            front_need = 0
        elseif get(P.fuel_front_max) == 1 then
            front_need = 47000
        end

        if get(P.fuel_meter_summ_zero) == 1 then
            summ_need, t1 = 0, 0
        elseif get(P.fuel_meter_summ_max) == 1 then
            summ_need, t1 = 47000, 4700
        else
            t1 = get(P.tank1_w)
        end
    else
        -- Without electrical power, hold each gauge at its indicated value.
        summ_need = get(P.fuel_meter_summ)
        front_need = get(P.fuel_front_ind)
        t1 = get(P.fuel_meter_tank1)
        t2L = get(P.fuel_meter_tank2_left)
        t2R = get(P.fuel_meter_tank2_right)
        t3L = get(P.fuel_meter_tank3_left)
        t3R = get(P.fuel_meter_tank3_right)
        t4 = get(P.fuel_meter_tank4)
    end

    -- A failed fuel meter holds its needle position.
    if get(P.fuel_meter_summ_fail) == 0 then
        summ_act = smooth(summ_act, summ_need, 1000, 10000, 1.5, 10)
        summ_front_act = smooth(summ_front_act, front_need, 1000, 10000, 1.5, 10)
    end
    if get(P.fuel_meter_1_fail) == 0 then
        tank1_act = smooth(tank1_act, t1, 100, 1000, 1.5, 10)
    end
    if get(P.fuel_meter_2l_fail) == 0 then
        tank2L_act = smooth(tank2L_act, t2L, 100, 2000, 1.8, 15)
    end
    if get(P.fuel_meter_2r_fail) == 0 then
        tank2R_act = smooth(tank2R_act, t2R, 100, 2000, 1.8, 15)
    end
    if get(P.fuel_meter_3l_fail) == 0 then
        tank3L_act = smooth(tank3L_act, t3L, 100, 1000, 2, 15)
    end
    if get(P.fuel_meter_3r_fail) == 0 then
        tank3R_act = smooth(tank3R_act, t3R, 100, 1000, 2, 15)
    end
    if get(P.fuel_meter_4_fail) == 0 then
        tank4_act = smooth(tank4_act, t4, 100, 1000, 2.5, 10)
    end

    put(P.fuel_meter_summ, summ_act)
    put(P.fuel_meter_tank1, tank1_act)
    put(P.fuel_meter_tank2_left, tank2L_act)
    put(P.fuel_meter_tank2_right, tank2R_act)
    put(P.fuel_meter_tank3_left, tank3L_act)
    put(P.fuel_meter_tank3_right, tank3R_act)
    put(P.fuel_meter_tank4, tank4_act)
    put(P.fuel_front_ind, summ_front_act)
end

---------------------------------------------------------------------------
-- Lamp indications.
---------------------------------------------------------------------------
local L_lb, L_tb = 0, 0

-- Boolean lamp input: max(bool2int(on) * lamps_brt, test_btn).
local function lp(on)
    return max((on and 1 or 0) * L_lb, L_tb)
end

-- Numeric lamp input: max(x * lamps_brt, test_btn).
local function lv(x)
    return max(x * L_lb, L_tb)
end

local function lamps(bus_l, bus_r, level_sw)
    local lb = max((max(bus_l, bus_r) - 10) / 18.5, 0)

    -- Clear every lamp, including the lamp test, without electrical power.
    if lb == 0 then
        for i = 1, #ALL_LAMPS do
            put(ALL_LAMPS[i], 0)
        end
        return
    end

    L_lb = lb
    L_tb = get(P.test_lamps) * max((bus_r - 10) / 18.5, 0)

    local p2L = get(P.pump_tank2_left_work)
    local p2R = get(P.pump_tank2_right_work)
    local p3L = get(P.pump_tank3_left_work)
    local p3R = get(P.pump_tank3_right_work)
    local p4 = get(P.pump_tank4_work)
    local lvl2 = get(P.auto_tank_level_2)
    local lvl3 = get(P.auto_tank_level_3)

    put(P.fuel_tank3_left_fail, lp(lvl3 == -1))
    put(P.fuel_tank2_left_fail, lp(lvl2 == -1))
    put(P.fuel_tank3_right_fail, lp(lvl3 == 1))
    put(P.fuel_tank2_right_fail, lp(lvl2 == 1))

    put(P.fuel_pump_left_5, lp(p2L > 0))
    put(P.fuel_pump_left_6, lp(p2L > 1))
    put(P.fuel_pump_left_7, lp(p3L > 2))
    put(P.fuel_pump_left_8, lp(p3L > 0))
    put(P.fuel_pump_left_9, lp(p3L > 1))

    put(P.fuel_pump_right_5, lp(p2R > 1))
    put(P.fuel_pump_right_6, lp(p2R > 0))
    put(P.fuel_pump_right_7, lp(p3R > 0))
    put(P.fuel_pump_right_8, lp(p3R > 2))
    put(P.fuel_pump_right_9, lp(p3R > 1))

    put(P.fuel_pump_10, lp(p4 > 0))
    put(P.fuel_pump_11, lp(p4 > 1))

    put(P.fuel_pump_1, lv(get(P.pump_tank1_1_work)))
    put(P.fuel_pump_2, lv(get(P.pump_tank1_2_work)))
    put(P.fuel_pump_3, lv(get(P.pump_tank1_3_work)))
    put(P.fuel_pump_4, lv(get(P.pump_tank1_4_work)))

    put(P.fuel_cut_off_1, lp(get(P.fire_vlv_open_1) > 0.7))
    put(P.fuel_cut_off_2, lp(get(P.fire_vlv_open_2) > 0.7))
    put(P.fuel_cut_off_3, lp(get(P.fire_vlv_open_3) > 0.7))

    local turn = get(P.auto_tanks_turn)
    put(P.fuel_flow_from_2, lp(turn == 1 or turn == 2))
    put(P.fuel_flow_from_3, lp(turn == 2 or turn == 3))
    put(P.fuel_flow_from_4, lp(turn == 4))
    put(P.fuel_flow_auto_fail, lp(turn == 0))

    local rt = lv(get(P.reserv_trans))
    put(P.fuel_reserv_trans_left, rt)
    put(P.fuel_reserv_trans_right, rt)

    put(P.fuel_porc_reserv, lv(get(P.reserv_pump_test)))

    -- Read the level-control failure only when its switch is on.
    local automat = 0
    if level_sw ~= 0 then
        automat = level_sw * (1 - get(P.fuel_level_fail))
    end
    put(P.fuel_level_automat, lv(automat))
end

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------
function update()
    passed = get(P.frame_time)

    sim_start_timer = sim_start_timer + passed
    local started = sim_start_timer > 0.3
    if started and notLoaded then
        reset_switchers()
    end

    -- Gemeinsame Schalterwerte nach einem möglichen Reset lesen
    local level_sw = get(P.fuel_level)
    local meter_sw = get(P.fuel_meter_on)
    local mech_sw = get(P.fuel_meter_mech_on)

    if started then
        local porc_sw = check_switchers(level_sw, meter_sw, mech_sw)
        caps_check(porc_sw)
    end

    local MASTER = get(P.ismaster) ~= 1
    if MASTER ~= was_master then
        cache = {}
        was_master = MASTER
    end

    local bus_l = get(P.bus27_volt_left)
    local bus_r = get(P.bus27_volt_right)

    if MASTER then
        mech_fuel_meter(bus_l, bus_r, mech_sw)
    end
    electric_meters(bus_l, bus_r, meter_sw)
    lamps(bus_l, bus_r, level_sw)
end
