-- T154.zmisc2.lua

-- xTLua system coordinator for ground servicing and miscellaneous aircraft systems.
-- This is an xTLua init script, not a SASL component: datarefs are exposed as
-- namespace variables and after_physics() is called by the xTLua runtime.
--
-- Main responsibilities:
--   * staged payload loading, refueling, service vehicles, doors, and CG movement;
--   * VVI/slat smoothing, door icing, and brake-temperature behavior;
--   * engine RPM correction and associated annunciator logic.

-- Create writable custom datarefs in the current xTLua namespace.
function deferred_dataref(name,type,notifier)
	print("Deffered dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end

-- Existing aircraft, simulator, and failure-system inputs.
-- Bind existing X-Plane and Tu-154 datarefs in a deterministic order.
local datarefs = {

    -- Engine indications, failures, and door animations
    {"simDR_failures","tu154/custom/failures/failures_enabled"},
    {"simDR_rpm_low_1","tu154/custom/gauges/engine/rpm_low_1"},
    {"simDR_rpm_low_2","tu154/custom/gauges/engine/rpm_low_2"},
    {"simDR_rpm_low_3","tu154/custom/gauges/engine/rpm_low_3"},
    {"simDR_rpm_high_1","tu154/custom/gauges/engine/rpm_high_1_new"},
    {"simDR_rpm_high_2","tu154/custom/gauges/engine/rpm_high_2_new"},
    {"simDR_rpm_high_3","tu154/custom/gauges/engine/rpm_high_3_new"},
    {"simDR_perep_1","tu154/custom/lights/engines/eng1_bypass_valve"},
    {"simDR_perep_2","tu154/custom/lights/engines/eng2_bypass_valve"},
    {"simDR_perep_3","tu154/custom/lights/engines/eng3_bypass_valve"},
    {"simDR_door1_anim","tu154/custom/anim/pax_door_1"},
    {"simDR_door2_anim","tu154/custom/anim/pax_door_2"},
    {"simDR_door3_anim","tu154/custom/anim/pax_door_3"},
    {"simDR_door_cargo1_anim","tu154/custom/anim/cargo_1"},
    {"simDR_door_cargo2_anim","tu154/custom/anim/cargo_2"},
    -- Environment, ground contact, brakes, and electrical power
    {"simDR_door_fan_temp","tu154/custom/bleed/door_heat_tube_t"},
    {"simDR_oat","sim/cockpit2/temperature/outside_air_temp_deg"},
    {"simDR_altitude","sim/flightmodel/position/y_agl"},
    {"simDR_brake_l","sim/cockpit2/controls/left_brake_ratio"},
    {"simDR_brake_r","sim/cockpit2/controls/right_brake_ratio"},
    {"simDR_gs","sim/flightmodel/position/groundspeed"},
    {"simDR_on_ground","sim/flightmodel/failures/onground_all"},
    {"simDR_gear1","sim/flightmodel/movingparts/gear1def"},
    {"simDR_gear2","sim/flightmodel/movingparts/gear2def"},
    {"simDR_gear3","sim/flightmodel/movingparts/gear3def"},
    {"simDR_gear_fan","tu154/custom/switchers/eng/gear_fan"},
    {"simDR_36vl","tu154/custom/elec/bus36_volt_left"},
    {"simDR_36vr","tu154/custom/elec/bus36_volt_right"},
    {"simDR_bus27left","tu154/custom/elec/bus27_volt_left"},
    {"simDR_bus27right","tu154/custom/elec/bus27_volt_right"},
    {"simDR_passed","sim/operation/misc/frame_rate_period"},
    {"simDR_gear_blocks","tu154/custom/anim/gear_blocks"},
    {"simDR_slat_ratio","sim/flightmodel/controls/slatrat"},
    {"simDR_day_night_lit","tu154/custom/lights/day_night_set"},
    {"simDR_vvi_left","tu154/custom/gauges/vvi_left"},
    {"simDR_vvi_right","tu154/custom/gauges/vvi_right"},
    {"simDR_var_left","tu154/custom/switchers/ovhd/var_left"},
    {"simDR_var_right","tu154/custom/switchers/ovhd/var_right"},
    {"simDR_start_apu","tu154/custom/lights/apu/start_apu"},
    {"simDR_lamp_test_apu","tu154/custom/buttons/lamp_test_apu"},
    -- Load-panel state and fuel/engine annunciators
    {"simDR_load_panel","tu154/custom/panels/show_load_panel"},
    {"simDR_light_fuel_pump_1","tu154/custom/lights/small/fuel_pump_1"},
    {"simDR_light_fuel_pump_2","tu154/custom/lights/small/fuel_pump_2"},
    {"simDR_light_fuel_pump_3","tu154/custom/lights/small/fuel_pump_3"},
    {"simDR_light_fuel_pump_4","tu154/custom/lights/small/fuel_pump_4"},
    {"simDR_light_fuel_pump_10","tu154/custom/lights/small/fuel_pump_10"},
    {"simDR_light_fuel_pump_11","tu154/custom/lights/small/fuel_pump_11"},
    {"simDR_light_fuel_pump_left_5","tu154/custom/lights/small/fuel_pump_left_5"},
    {"simDR_light_fuel_pump_left_6","tu154/custom/lights/small/fuel_pump_left_6"},
    {"simDR_light_fuel_pump_left_7","tu154/custom/lights/small/fuel_pump_left_7"},
    {"simDR_light_fuel_pump_left_8","tu154/custom/lights/small/fuel_pump_left_8"},
    {"simDR_light_fuel_pump_left_9","tu154/custom/lights/small/fuel_pump_left_9"},
    {"simDR_light_fuel_pump_right_5","tu154/custom/lights/small/fuel_pump_right_5"},
    {"simDR_light_fuel_pump_right_6","tu154/custom/lights/small/fuel_pump_right_6"},
    {"simDR_light_fuel_pump_right_7","tu154/custom/lights/small/fuel_pump_right_7"},
    {"simDR_light_fuel_pump_right_8","tu154/custom/lights/small/fuel_pump_right_8"},
    {"simDR_light_fuel_pump_right_9","tu154/custom/lights/small/fuel_pump_right_9"},
    {"simDR_light_fuel_pump_left_2_fail","tu154/custom/lights/small/fuel_tank2_left_fail"},
    {"simDR_light_fuel_pump_right_2_fail","tu154/custom/lights/small/fuel_tank2_right_fail"},
    {"simDR_light_fuel_pump_left_3_fail","tu154/custom/lights/small/fuel_tank3_left_fail"},
    {"simDR_light_fuel_pump_right_3_fail","tu154/custom/lights/small/fuel_tank3_right_fail"},
    {"simDR_light_test_hydro","tu154/custom/buttons/lamp_test_hydro"},
    {"simDR_light_test_eng","tu154/custom/buttons/lamp_test_engines"},
    {"simDR_oilmeter_1_lit","tu154/custom/lights/small/oil_meter_1"},
    {"simDR_oilmeter_2_lit","tu154/custom/lights/small/oil_meter_2"},
    {"simDR_oilmeter_3_lit","tu154/custom/lights/small/oil_meter_3"},
    {"simDR_bypass_vlv_1_lit","tu154/custom/lights/engines/eng1_bypass_valve"},
    {"simDR_bypass_vlv_2_lit","tu154/custom/lights/engines/eng2_bypass_valve"},
    {"simDR_bypass_vlv_3_lit","tu154/custom/lights/engines/eng3_bypass_valve"},
    {"simDR_vna33_1_lit","tu154/custom/lights/engines/eng1_vna33"},
    {"simDR_vna33_2_lit","tu154/custom/lights/engines/eng2_vna33"},
    {"simDR_vna33_3_lit","tu154/custom/lights/engines/eng3_vna33"},
    {"simDR_vna0_1_lit","tu154/custom/lights/engines/eng1_vna0"},
    {"simDR_vna0_2_lit","tu154/custom/lights/engines/eng2_vna0"},
    {"simDR_vna0_3_lit","tu154/custom/lights/engines/eng3_vna0"},
    {"simDR_brake_heat_left","tu154/custom/failures/brake_heat_left"},
    {"simDR_brake_heat_right","tu154/custom/failures/brake_heat_right"},
    -- Fuel, payload, and target values supplied by the load panel
    {"simDR_fuel_tanks","sim/flightmodel/weight/m_fuel"},
    {"simDR_fuel_tank1","sim/flightmodel/weight/m_fuel1"},
    {"simDR_fuel_tank2","sim/flightmodel/weight/m_fuel2"},
    {"simDR_fuel_tank3","sim/flightmodel/weight/m_fuel3"},
    {"simDR_payload_set","tu154/custom/payload/load_slow_btn_new"},
    {"simDR_fast_load_btn","tu154/custom/payload/load_fast_btn"},
    {"simDR_payload","sim/flightmodel/weight/m_fixed"},
    {"simDR_payload_cargo1","tu154/custom/payload/cargo_1"},
    {"simDR_payload_cargo2","tu154/custom/payload/cargo_2"},
    {"simDR_payload_cargo3","tu154/custom/payload/kitchens"},
    {"simDR_payload_cargo4","tu154/custom/payload/various"},
    {"simDR_payload_pax1","tu154/custom/payload/zone_1"},
    {"simDR_payload_pax2","tu154/custom/payload/zone_2"},
    {"simDR_payload_pax3","tu154/custom/payload/zone_4"},
    {"simDR_payload_pax4","tu154/custom/payload/zone_5"},
    {"simDR_payload_pax5","tu154/custom/payload/zone_6"},
    {"simDR_payload_crew","tu154/custom/payload/crew_num"},
    {"simDR_payload_cabin","tu154/custom/payload/cabin_num"},
    {"simDR_srd_buzzer","tu154/custom/switchers/eng/srd_buzzer"},
    {"simDR_srd_buzzer_cap","tu154/custom/switchers/eng/srd_buzzer_cap"},
    {"simDR_cg","sim/flightmodel/misc/cgz_ref_to_default"},
    {"simDR_tank1","tu154/custom/payload/tank_1"},
    {"simDR_tank2_l","tu154/custom/payload/tank_2L"},
    {"simDR_tank2_r","tu154/custom/payload/tank_2R"},
    {"simDR_tank3_l","tu154/custom/payload/tank_3L"},
    {"simDR_tank3_r","tu154/custom/payload/tank_3R"},
    {"simDR_tank4","tu154/custom/payload/tank_4"},
    -- Ground-service calls and X-Plane custom slider door commands
    {"simDR_fuel_tanker","tu154/custom/anim/fuel_tanker_call"},
    {"simDR_fuel_tanker_anim","tu154/custom/anim/fuel_tanker"},
    {"simDR_catering","tu154/custom/anim/catering_call"},
    {"simDR_ladder1","tu154/custom/anim/ladder_1_call"},
    {"simDR_ladder2","tu154/custom/anim/ladder_2_call"},
    {"simDR_door1","sim/cockpit2/switches/custom_slider_on[4]"},
    {"simDR_door2","sim/cockpit2/switches/custom_slider_on[5]"},
    {"simDR_door_cargo1","sim/cockpit2/switches/custom_slider_on[2]"},
    {"simDR_door_cargo2","sim/cockpit2/switches/custom_slider_on[3]"},
    {"simDR_door_kitchen","sim/cockpit2/switches/custom_slider_on[6]"},
    {"simDR_catering_anim","tu154/custom/anim/catering_tanker"},
    -- Pitot icing and airspeed indications
    {"mDR_percip_on_craft","sim/weather/precipitation_on_aircraft_ratio"},
    {"simDR_speed_svs","tu154/custom/svs/true_airspeed"},
    {"simDR_ppd1_fail","tu154/custom/failures/pitot1"},
    {"simDR_ppd2_fail","tu154/custom/failures/pitot2"},
    {"simDR_ppd3_fail","tu154/custom/antiice/ppd_3_heat_fail"},
    {"simDR_kus_left","tu154/custom/gauges/speed/kus_ias_left"},
    {"simDR_tas_left","tu154/custom/gauges/speed/kus_tas_left"},
    {"simDR_ias_left","tu154/custom/gauges/speed/ias_left"},
    {"simDR_ias_y_left","tu154/custom/gauges/speed/ias_yellow_left"},
    {"simDR_kus_right","tu154/custom/gauges/speed/kus_ias_right"},
    {"simDR_tas_right","tu154/custom/gauges/speed/kus_tas_right"},
    {"simDR_ias_right","tu154/custom/gauges/speed/ias_right"},
    {"simDR_ias_y_right","tu154/custom/gauges/speed/ias_yellow_right"},
    -- Smooth-loading CG references
    {"simDR_cg_pos_act","tu154/custom/misc/cg_pos_actual"},
    {"simDR_cg_pos_met","sim/flightmodel/misc/cgz_ref_to_default"},
    {"simDR_cg_pos_to","tu154/custom/t154_efb/cax_to"},
    -- Pitot-heater and precipitation inputs
    {"simDR_ppd1","tu154/custom/switchers/ovhd/pitot_heat_1"},
    {"simDR_ppd2","tu154/custom/switchers/ovhd/pitot_heat_2"},
    {"simDR_ppd3","tu154/custom/switchers/ovhd/pitot_heat_3"},
    {"simDR_percip_on_craft","sim/weather/precipitation_on_aircraft_ratio"},
}

local env = getfenv(1)

for _,dataref in ipairs(datarefs) do
    env[dataref[1]] = find_dataref(dataref[2])
end

-- Create writable custom datarefs owned by this xTLua script.
local deferred_datarefs = {
    {"rpm1_low","tu154/custom/gauges/engine/rpm_low_1_new"},
    {"rpm2_low","tu154/custom/gauges/engine/rpm_low_2_new"},
    {"rpm3_low","tu154/custom/gauges/engine/rpm_low_3_new"},
    {"fuel_load_total","tu154/custom/fuel_load_total"},
    {"fueling_cpmlt","tu154/custom/fueling_cpmlt"},
    {"cargo_req","tu154/custom/cargo_req"},
    {"pax_req","tu154/custom/pax_req"},
    {"yoke_height","tu154/custom/yoke_height"},
    {"vvi_left","tu154/custom/gauges/vvi_left_new"},
    {"vvi_right","tu154/custom/gauges/vvi_right_new"},
    {"start_loading","tu154/custom/start_smooth_loading"},
}

for _,dataref in ipairs(deferred_datarefs) do
    env[dataref[1]] = deferred_dataref(dataref[2],"number")
end


-- Legacy correction state retained with the original bindings. These values are
-- currently not consumed elsewhere in this script.
local ias_y_left_corr = 0
local kus_left_corr = 0
local tas_left_corr = 0
local ias_left_corr = 0
local ias_y_right_corr = 0
local kus_right_corr = 0
local tas_right_corr = 0
local ias_right_corr = 0
local ppd_icing1 = 0
local ppd_icing2 = 0
local ppd_icing3 = 0
local ppd1_fail_was = 0
local ppd2_fail_was = 0
local ppd3_fail_was = 0

-- Instrument animation and load-sequence state.
local load_panel_loaded = 0
local vvi_left_test = 0
local vvi_left_ms = 0
local vvi_left_delta = 0
local vvi_right_test = 0
local vvi_right_ms = 0
local vvi_right_delta = 0
local slat_ratio_loc = 0
local slat_ratio_delta = 0

-- Payload completion flags and accumulated loaded mass, in kilograms.
local cargo_cmplt = 0
local pax_cmplt = 0
local cargo_doors_closed_by_loader = false
local pax_load = 0
local cargo_load = 0
local payload_loc_req = 0
local cg_loc_req = 0
local cg_loc = 0
local payload_loc = 0
local loading_cmplt = 0

-- Refueling state. Each tank completion flag is either zero or one.
local fueling_cpmlt_23 = 0
local refueler_set = 0
local refueler_set = 0
local refuel_refueler = 0
local refuel_refueler_set = 0
local fuel_was_set = 0
local start_refueling = 0
local tank1 = 0
local tank2_l = 0
local tank2_r = 0
local tank3_l = 0
local tank3_r = 0
local tank4 = 0
local tank1_req = 0
local tank2_l_req = 0
local tank2_r_req = 0
local tank3_l_req = 0
local tank3_r_req = 0
local tank4_req = 0
local tank1_cmplt = 0
local tank2_r_cmplt = 0
local tank2_l_cmplt = 0
local tank3_r_cmplt = 0
local tank3_l_cmplt = 0
local tank4_cmplt = 0

-- Miscellaneous system-model state.
local brake_temp = 0
local bus27 = 0
local bus36 = 0
local pump_test = 0
local gears = 0
local doors_icing = 0
local rpm1_low_loc = 0
local rpm2_low_loc = 0
local rpm3_low_loc = 0
local rpm1_correct = 0
local rpm2_correct = 0
local rpm3_correct = 0
local rpm1_correct_loc = 0
local rpm2_correct_loc = 0
local rpm3_correct_loc = 0
local brake_temp_loc_l = 0
local brake_temp_loc_r = 0

-- Outside-air-temperature-adjusted engine annunciator thresholds.
local vna33_off = 0
local vna0_off = 0


-- VVI (VAR-30MK) indication constants.
local VVI_FPM_TO_MS = 0.00508
local VVI_PARK      = 30
local VVI_TEST_TIME = 10
local VVI_TEST_HOLD = 8
local VVI_TEST_RATE = 0.5




-- Run the complete ground-service state machine. All work is inhibited in flight.
-- The slow-load button captures a new set of targets; subsequent physics frames
-- advance payload, fuel, and CG until their individual completion conditions are met.
function refueling()
       if simDR_on_ground > 0 then
           -- Capture requested fuel quantities while the slow-load button is active.
           if simDR_payload_set > 0 then
                fuel_was_set = 1
                tank1_req = simDR_tank1  
                tank2_r_req = simDR_tank2_r
                tank2_l_req = simDR_tank2_l
                tank3_r_req = simDR_tank3_r
                tank3_l_req = simDR_tank3_l
                tank4_req = simDR_tank4
            else
                -- Keep a snapshot of the current simulator tank quantities whenever
                -- the request button is released.
                tank1 = simDR_fuel_tanks[0]  
                tank2_r = simDR_fuel_tanks[2]
                tank2_l = simDR_fuel_tanks[3]
                tank3_r = simDR_fuel_tanks[4]
                tank3_l = simDR_fuel_tanks[5]
                tank4 = simDR_fuel_tanks[1]
            end 
            -- Track the current payload whenever no new target is being captured.
            if simDR_payload_set < 1 and fuel_was_set < 1 then
                payload_loc = simDR_payload
            end
            -- Initialize one complete loading/refueling cycle from the captured targets.
            if fuel_was_set > 0 then
                -- Cargo targets are already masses. Passenger-zone counts use the
                -- aircraft's fixed planning mass of 75 kg per passenger.
                if (simDR_payload_cargo1 + simDR_payload_cargo2 +simDR_payload_cargo3) - cargo_load > 0 then
                    cargo_req = (simDR_payload_cargo1 + simDR_payload_cargo2 +simDR_payload_cargo3) - cargo_load
                else
                    cargo_load = simDR_payload_cargo1 + simDR_payload_cargo2 +simDR_payload_cargo3
                    cargo_req = 0
                end
                if ((simDR_payload_pax1*75)+(simDR_payload_pax2*75)+(simDR_payload_pax3*75)+(simDR_payload_pax4*75)+(simDR_payload_pax5*75)) - pax_load > 0 then
                    pax_req = ((simDR_payload_pax1*75)+(simDR_payload_pax2*75)+(simDR_payload_pax3*75)+(simDR_payload_pax4*75)+(simDR_payload_pax5*75)) - pax_load
                else
                    pax_load = (simDR_payload_pax1*75)+(simDR_payload_pax2*75)+(simDR_payload_pax3*75)+(simDR_payload_pax4*75)+(simDR_payload_pax5*75)
                    pax_req = 0
                end
                -- Establish the already-loaded baseline before staged mass is added.
                -- Flight crew uses 80 kg per person; cabin crew uses 75 kg.
                simDR_payload = (simDR_payload_crew*80)+(simDR_payload_cabin*75)+simDR_payload_cargo4 +pax_load + cargo_load

                -- Excess fuel is removed immediately; fuel below target is added later
                -- by the timed refueling section.
                if simDR_fuel_tanks[0] > tank1_req then
                    simDR_fuel_tanks[0] = tank1_req
                end
                if simDR_fuel_tanks[2] > tank2_r_req then
                    simDR_fuel_tanks[2] = tank2_r_req
                end
                if simDR_fuel_tanks[3] > tank2_l_req then
                    simDR_fuel_tanks[3] = tank2_l_req
                end
                if simDR_fuel_tanks[4] > tank3_r_req then
                    simDR_fuel_tanks[4] = tank3_r_req
                end
                if simDR_fuel_tanks[5] > tank3_l_req then
                    simDR_fuel_tanks[5] = tank3_l_req
                end
                if simDR_fuel_tanks[1] > tank4_req then
                    simDR_fuel_tanks[1] = tank4_req
                end

                -- Open only the service doors needed by the requested payload.
                if cargo_req > 0 then
                    if simDR_payload_cargo1 > 0 then
                        simDR_door_cargo1 = 1
                    end
                    if simDR_payload_cargo2 > 0 then
                        simDR_door_cargo2 = 1
                    end
                end

                if pax_req > 0 then
                  if (simDR_door1+simDR_door2) == 0 then
                      simDR_door1 = 1
                  end
                end

                -- Arm all substates for the new cycle.
                fuel_load_total = 0
                fuel_was_set = 0
                start_refueling = 1
                start_loading = 1
                cargo_doors_closed_by_loader = false
                tank1_cmplt = 0
                tank2_r_cmplt = 0
                tank2_l_cmplt = 0
                tank3_r_cmplt = 0
                tank3_l_cmplt = 0
                tank4_cmplt = 0
                refueler_set = 0
            end
                
            -- Count completed wing tanks. Clamping the count to three keeps the
            -- transfer-rate divisor (4 - fueling_cpmlt_23) above zero.
            if tank2_r_cmplt + tank2_l_cmplt + tank3_r_cmplt + tank3_l_cmplt < 4 then
                fueling_cpmlt_23 = tank2_r_cmplt + tank2_l_cmplt + tank3_r_cmplt + tank3_l_cmplt
            else
                fueling_cpmlt_23 = 3
            end
            
            fueling_cpmlt = tank1_cmplt + tank2_r_cmplt + tank2_l_cmplt + tank3_r_cmplt + tank3_l_cmplt + tank4_cmplt
            loading_cmplt = cargo_cmplt+pax_cmplt
            
        
            -- Nudge X-Plane's longitudinal CG reference toward the EFB target while
            -- the smooth-loading sequence remains active.
            if start_loading > 0 then
                if simDR_cg_pos_act > simDR_cg_pos_to then
                   simDR_cg_pos_met = simDR_cg_pos_met - 0.0001
                elseif simDR_cg_pos_act < (simDR_cg_pos_to-0.005) then
                   simDR_cg_pos_met = simDR_cg_pos_met + 0.0001
                end
            end
            
            -- Payload loading is complete only after cargo, passengers, and CG agree.
            if loading_cmplt == 2 and math.abs(simDR_cg_pos_act - simDR_cg_pos_to) < 0.01 then
                start_loading = 0
                cargo_req = 0 
                pax_req = 0
            end
            
            -- Fast load owns the final values, so cancel any in-progress smooth load.
            if simDR_fast_load_btn > 0 then
                start_loading = 0
                cargo_req = 0 
                pax_req = 0
            end
               
            
            -- Finish refueling when all six physical tanks have reached target.
            if fueling_cpmlt == 6 and start_refueling > 0 then
                start_refueling = 0
                if simDR_fuel_tanker > 0 then
                    simDR_fuel_tanker = 0
                end
                tank1_cmplt = 0
                tank2_r_cmplt = 0
                tank2_l_cmplt = 0
                tank3_r_cmplt = 0
                tank3_l_cmplt = 0
                tank4_cmplt = 0
            end
                
            -- Treat a manually removed tanker as cancellation of the active fuel job.
            if refueler_set > 0 and simDR_fuel_tanker < 1 and start_refueling > 0 then
                start_refueling = 0
                tank1_cmplt = 0
                tank2_r_cmplt = 0
                tank2_l_cmplt = 0
                tank3_r_cmplt = 0
                tank3_l_cmplt = 0
                tank4_cmplt = 0
            end
                
            -- Add payload in 0.5 kg increments per physics callback. Gear blocks are
            -- installed automatically for the duration of ground servicing.
            if start_loading > 0 then
                if simDR_gear_blocks < 1 then
                    simDR_gear_blocks = 1
                end
                
                if cargo_req > 0 then
                    simDR_payload = simDR_payload + 0.5
                    cargo_req = cargo_req - 0.5
                    cargo_load = cargo_load + 0.5
                else
                    -- Close the cargo doors once when loading finishes. Repeating this
                    -- every frame would override later manual input from the ground panel.
                    if not cargo_doors_closed_by_loader then
                        if simDR_door_cargo1 > 0 then
                           simDR_door_cargo1 = 0
                        end
                        if simDR_door_cargo2 > 0 then
                           simDR_door_cargo2 = 0
                        end
                        cargo_doors_closed_by_loader = true
                    end
                    cargo_cmplt = 1
                end
                
                -- Passenger loading waits until refueling has stopped. Catering and
                -- passenger service objects are then removed when loading completes.
                if start_refueling < 1 then
                    if pax_cmplt < 1 and simDR_payload_cargo3 > 5 then
                       simDR_catering = 1
                       simDR_door_kitchen = 1
                    end
                    if pax_req > 0 then
                        simDR_payload = simDR_payload + 0.5
                        pax_req = pax_req - 0.5
                        pax_load = pax_load + 0.5
                    else
                        if simDR_catering > 0 then
                           simDR_catering = 0
                        end
                        if simDR_door_kitchen > 0 then
                           simDR_door_kitchen = 0
                        end
                        if simDR_ladder1 > 0 then
                           simDR_ladder1 = 0
                        end
                        if simDR_ladder2 > 0 then
                           simDR_ladder2 = 0
                        end
                        if simDR_door1 > 0 then
                           simDR_door1 = 0
                        end
                        if simDR_door2 > 0 then
                           simDR_door2 = 0
                        end
                        pax_cmplt = 1
                    end 
                end
            else
                cargo_cmplt = 0
                pax_cmplt = 0
                cargo_doors_closed_by_loader = false
            end
              
                
            -- Timed refueling uses a one-kilogram completion tolerance per tank.
            if start_refueling > 0 then
                
                
                if simDR_fuel_tanks[0] > (tank1_req -1) and tank1_cmplt < 1 then
                    tank1_cmplt = 1
                end
                if simDR_fuel_tanks[1] > (tank4_req -1) and tank2_r_cmplt > 0 and tank2_l_cmplt > 0 and tank3_r_cmplt > 0 and tank3_l_cmplt > 0 then
                    tank4_cmplt = 1
                end
                if simDR_fuel_tanks[2] > (tank2_r_req -1) and tank2_r_cmplt < 1 then
                    tank2_r_cmplt = 1
                end
                if simDR_fuel_tanks[3] > (tank2_l_req -1) and tank2_l_cmplt < 1 then
                    tank2_l_cmplt = 1
                end
                if simDR_fuel_tanks[4] > (tank3_r_req -1) and tank3_r_cmplt < 1 then
                    tank3_r_cmplt = 1
                end
                if simDR_fuel_tanks[5] > (tank3_l_req -1) and tank3_l_cmplt < 1 then
                    tank3_l_cmplt = 1
                end
                    
                    
                -- Keep the aircraft chocked and transfer fuel only while the tanker
                -- animation reports the service position. The modeled aggregate flow
                -- is approximately 13.333 kg/s.
                if simDR_gear_blocks < 1 then
                    simDR_gear_blocks = 1
                end
                if simDR_fuel_tanker_anim == 0 and fuel_load_total < 17600 then
                    -- Tank 1 is filled before the wing-tank distribution begins.
                    if simDR_fuel_tanks[0] < tank1_req then
                        simDR_fuel_tanks[0] = simDR_fuel_tanks[0] +13.333 *SIM_PERIOD
                        fuel_load_total = fuel_load_total +13.333 *SIM_PERIOD
                    else
                        -- Initially balance tank 3 left/right up to 1,725 kg. Once that
                        -- phase is complete, divide the flow among unfinished tanks 2/3.
                        if simDR_fuel_tanks[5] < 1725 and simDR_fuel_tanks[4] < 1725 and simDR_fuel_tanks[5] < tank3_l_req and simDR_fuel_tanks[4] < tank3_r_req then
                            if simDR_fuel_tanks[5] < tank3_l_req then
                                if simDR_fuel_tanks[4] < 1725 then
                                    simDR_fuel_tanks[5] = simDR_fuel_tanks[5] +6.6665 *SIM_PERIOD
                                    fuel_load_total = fuel_load_total +6.6665 *SIM_PERIOD
                                else
                                    simDR_fuel_tanks[5] = simDR_fuel_tanks[5] +13.333 *SIM_PERIOD
                                    fuel_load_total = fuel_load_total +13.333 *SIM_PERIOD
                                end
                            end
                            if simDR_fuel_tanks[4] < tank3_r_req then
                                if simDR_fuel_tanks[5] < 1725 then
                                    simDR_fuel_tanks[4] = simDR_fuel_tanks[4] +6.6665 *SIM_PERIOD
                                    fuel_load_total = fuel_load_total +6.6665 *SIM_PERIOD
                                else
                                    simDR_fuel_tanks[4] = simDR_fuel_tanks[4] +13.333 *SIM_PERIOD
                                    fuel_load_total = fuel_load_total +13.333 *SIM_PERIOD
                                end
                            end
                        else
                            if simDR_fuel_tanks[5] < tank3_l_req then
                                simDR_fuel_tanks[5] = simDR_fuel_tanks[5] +(13.33325/ (4-fueling_cpmlt_23)) *SIM_PERIOD
                                fuel_load_total = fuel_load_total +(13.33325/ (4-fueling_cpmlt_23)) *SIM_PERIOD
                            end
                            if simDR_fuel_tanks[4] < tank3_r_req then
                                simDR_fuel_tanks[4] = simDR_fuel_tanks[4] +(13.33325/ (4-fueling_cpmlt_23)) *SIM_PERIOD
                                fuel_load_total = fuel_load_total +(13.33325/ (4-fueling_cpmlt_23)) *SIM_PERIOD
                            end
                            if simDR_fuel_tanks[2] < tank2_r_req then
                                if  simDR_fuel_tank3 < simDR_fuel_tanks[2] then
                                    simDR_fuel_tank3 = simDR_fuel_tanks[2]
                                end
                                simDR_fuel_tanks[2] = simDR_fuel_tanks[2] +(13.33325/ (4-fueling_cpmlt_23)) *SIM_PERIOD
                                fuel_load_total = fuel_load_total +(13.33325/ (4-fueling_cpmlt_23)) *SIM_PERIOD
                            end   
                            if simDR_fuel_tanks[3] < tank2_l_req then
                                if  simDR_fuel_tank3 < simDR_fuel_tanks[3] then
                                    simDR_fuel_tank3 = simDR_fuel_tanks[3]
                                end
                                simDR_fuel_tanks[3] = simDR_fuel_tanks[3] +(13.33325/ (4-fueling_cpmlt_23)) *SIM_PERIOD
                                fuel_load_total = fuel_load_total +(13.33325 / (4-fueling_cpmlt_23)) *SIM_PERIOD
                            end
                        end
                        -- Tank 4 is filled last, after all tank 2/3 sections complete.
                        if tank2_r_cmplt > 0 and tank2_l_cmplt > 0 and tank3_r_cmplt > 0 and tank3_l_cmplt > 0 then
                            if simDR_fuel_tanks[1] < tank4_req then
                                if  simDR_fuel_tank2 < simDR_fuel_tanks[1] then
                                    simDR_fuel_tank2 = simDR_fuel_tanks[1]
                                end
                                simDR_fuel_tanks[1] = simDR_fuel_tanks[1] +13.33325 *SIM_PERIOD
                                fuel_load_total = fuel_load_total +13.33325 *SIM_PERIOD
                            end
                        end  
                    end  
                else
                    -- One tanker load is limited to 17,600 kg. Send it away, wait for
                    -- its cycle timer, and request another tanker when more fuel remains.
                    if fuel_load_total > 17600 then
                        refueler_set = 0
                        simDR_fuel_tanker = 0
                        if refuel_refueler_set < 1 then
                            refuel_refueler = 50
                            refuel_refueler_set = 1
                        end
                        if refuel_refueler_set > 0 and refuel_refueler < 5 then
                            fuel_load_total = 0      
                        end
                    else
                        refuel_refueler_set = 0
                        refuel_refueler = 0
                        if refueler_set < 1 then
                            simDR_fuel_tanker = 1
                            refueler_set = 1
                        end
                    end
                    if refuel_refueler > 0 then
                        refuel_refueler = refuel_refueler- 1*simDR_passed
                    end
                end
                    
            end
       end
end


-- Update the independent instrument, icing, brake, and engine-indication models.
function m_misc()
-- Keep the SRD buzzer enabled whenever its protective cap is closed.
if simDR_srd_buzzer_cap < 1 then
   simDR_srd_buzzer = 1
end
    
-- VVI indication ----------------------------------------------
-- The needles follow the source dataref directly, one update per frame,
-- without artificial lag. Both instruments share the right 27 V bus, so
-- the power check is evaluated once.
vvi_left_ms = simDR_vvi_left * VVI_FPM_TO_MS
vvi_right_ms = simDR_vvi_right * VVI_FPM_TO_MS

if simDR_bus27right > 0 then
    if vvi_left_test < VVI_TEST_HOLD then
        vvi_left = vvi_left_ms
    end
    if vvi_left_test > 0 then
        vvi_left_test = vvi_left_test - VVI_TEST_RATE * SIM_PERIOD
    end

    if vvi_right_test < VVI_TEST_HOLD then
        vvi_right = vvi_right_ms
    end
    if vvi_right_test > 0 then
        vvi_right_test = vvi_right_test - VVI_TEST_RATE * SIM_PERIOD
    end
else
    vvi_left = VVI_PARK
    vvi_left_test = VVI_TEST_TIME
    vvi_right = VVI_PARK
    vvi_right_test = VVI_TEST_TIME
end

-- Enforce the 0.3 lower bound of the custom yoke-height output.
if yoke_height < 0.3 then
    yoke_height = 0.3
end

-- Rate-limit intermediate slat motion while preserving the simulator endpoints.
if simDR_slat_ratio > 0 and simDR_slat_ratio < 0.95 then   
        slat_ratio_delta = simDR_slat_ratio - slat_ratio_loc
else
        slat_ratio_delta = 0
end
  
if slat_ratio_delta > 0 then
   simDR_slat_ratio = simDR_slat_ratio - math.abs(slat_ratio_delta) 
   slat_ratio_loc = slat_ratio_loc + 0.075 * SIM_PERIOD
elseif slat_ratio_delta < 0 then
   simDR_slat_ratio = simDR_slat_ratio + math.abs(slat_ratio_delta) 
   slat_ratio_loc = slat_ratio_loc - 0.075 * SIM_PERIOD
end
  
-- On the ground, use the APU start annunciator to reflect the powered gear-fan state.
if bus27 > 0 then
  if simDR_gear_fan > 0 and simDR_on_ground > 0 then
       simDR_start_apu = 1
  elseif simDR_lamp_test_apu < 1 then
       simDR_start_apu = 0
  end
end
  
    -- Stagger fuel-system annunciators during the hydraulic lamp-test sequence.
    if simDR_light_test_hydro > 0 and bus27 > 0 then
        if pump_test > 0.8 then
            simDR_light_fuel_pump_1 = 0
        end
        if pump_test > 8.0 then
            simDR_light_fuel_pump_2 = 0
        end
        if pump_test > 1.6 then
            simDR_light_fuel_pump_3 = 0
        end
        if pump_test > 1.4 then
            simDR_light_fuel_pump_4 = 0
        end
        if pump_test > 1.2 then
            simDR_light_fuel_pump_10 = 0
        end
        if pump_test > 1.0 then
            simDR_light_fuel_pump_11 = 0
        end
        if pump_test > 2.9 then
            simDR_light_fuel_pump_left_5 = 0
        end
        if pump_test > 2.7 then
            simDR_light_fuel_pump_left_6 = 0
        end
        if pump_test > 2.5 then
            simDR_light_fuel_pump_left_7 = 0
        end
        if pump_test > 2.3 then
            simDR_light_fuel_pump_left_8 = 0
        end
        if pump_test > 2.1 then
            simDR_light_fuel_pump_left_9 = 0
        end
        if pump_test > 1.9 then
            simDR_light_fuel_pump_right_5 = 0
        end
        if pump_test > 1.7 then
            simDR_light_fuel_pump_right_6 = 0
        end
        if pump_test > 1.5 then
            simDR_light_fuel_pump_right_7 = 0
        end
        if pump_test > 1.3 then
            simDR_light_fuel_pump_right_8 = 0
        end
        if pump_test > 1.1 then
            simDR_light_fuel_pump_right_8 = 0
        end
        if pump_test > 0.9 then
            simDR_light_fuel_pump_right_9 = 0
        end
        if pump_test > 0.7 then
            simDR_light_fuel_pump_left_2_fail = 0
        end
        if pump_test > 0.5 then
            simDR_light_fuel_pump_right_2_fail = 0
        end
        if pump_test > 0.3 then
            simDR_light_fuel_pump_left_3_fail = 0
        end
        if pump_test > 0.1 then
             simDR_light_fuel_pump_right_3_fail = 0
        end
        if pump_test > 0 then
            pump_test = pump_test -0.45
        else
            pump_test = 0
        end     
    else
        pump_test = 3
    end
    
    

    -- Refresh the cached availability of the 27 V and 36 V buses once per frame.
    if simDR_bus27left > 5 then
        bus27 = 1
    elseif simDR_bus27right > 5 then
        bus27 = 1
    else
        bus27 = 0
    end 
        
    if simDR_36vl > 5 then
        bus36 = 1
    elseif simDR_36vr > 5 then
        bus36 = 1
    else
        bus36 = 0
    end   
       
 
    -- Failure-dependent environmental models are disabled as a group when the
    -- aircraft's failure simulation switch is off.
    if simDR_failures > 0 then 
        -- Accumulate door icing in cold high-altitude conditions without sufficient
        -- heated-air temperature. Residual severe ice keeps passenger doors closed
        -- while the modeled ice decays.
        if simDR_oat < 0 and simDR_door_fan_temp < 40 and simDR_altitude > 2450 then
            if doors_icing < 100 then
                doors_icing = doors_icing + 0.1
            else
                doors_icing = 100
            end
        else
            if doors_icing > 10 then
                    simDR_door1_anim = 0
                    simDR_door2_anim = 0
                    simDR_door3_anim = 0
            end
            if simDR_oat < 0 then
                if doors_icing > 0 then
                    doors_icing = doors_icing - (0.004 *simDR_door_fan_temp * SIM_PERIOD)
                else
                    doors_icing = 0
                end
            else
                if doors_icing > 0 then
                    doors_icing = doors_icing - (((0.016 *simDR_oat) + (0.004 *simDR_door_fan_temp)) * SIM_PERIOD)
                else
                    doors_icing = 0
                end
            end
        end
        -- Publish the current brake temperatures, then integrate the next model step.
        simDR_brake_heat_left = brake_temp_loc_l
        simDR_brake_heat_right = brake_temp_loc_r   
        -- Add heat according to brake application and ground speed.
        if simDR_brake_l > 0 and simDR_gs > 1 and simDR_on_ground > 0 then
            if brake_temp < 1200 then
                brake_temp_loc_l = brake_temp_loc_l + (simDR_brake_l * 0.015 * simDR_gs)
            end
        end
        if simDR_brake_r > 0 and simDR_gs > 1 and simDR_on_ground > 0 then
            if brake_temp < 1200 then
                brake_temp_loc_r = brake_temp_loc_r + (simDR_brake_r * 0.015 * simDR_gs)
            end
        end


        -- Apply passive cooling. Rates differ with gear position, aircraft motion,
        -- and whether the outside-air temperature is above or below zero.
        if simDR_oat < brake_temp_loc_l then
            if gears > 0 then
                if simDR_gs > 1 then
                        brake_temp_loc_l = brake_temp_loc_l - 0.0005 * simDR_gs 
                else
                    if simDR_oat > 0 then
                        brake_temp_loc_l = brake_temp_loc_l - 0.0000001*(50-math.abs(simDR_oat))
                    else
                        brake_temp_loc_l = brake_temp_loc_l - 0.000004*math.abs(simDR_oat)
                    end
                end
            else
                if simDR_oat > 0 then
                    brake_temp_loc_l = brake_temp_loc_l - 0.000005
                else
                    brake_temp_loc_l = brake_temp_loc_l - 0.00015*math.abs(simDR_oat)
                end
            end
        end

        if simDR_oat < brake_temp_loc_r then
            if gears > 0 then
                if simDR_gs > 1 then
                    brake_temp_loc_r = brake_temp_loc_r - 0.0005 * simDR_gs 
                else
                    if simDR_oat > 0 then
                        brake_temp_loc_r = brake_temp_loc_r - 0.0000001*(50-math.abs(simDR_oat))
                    else
                        brake_temp_loc_r = brake_temp_loc_r - 0.000004*math.abs(simDR_oat)
                    end
                end
            else
                if simDR_oat > 0 then
                    brake_temp_loc_r = brake_temp_loc_r - 0.000005
                else
                    brake_temp_loc_r = brake_temp_loc_r - 0.00015*math.abs(simDR_oat)
                end
            end
        end
        -- Powered brake fans provide additional cooling while on the ground.
        if bus36 > 0 and simDR_gear_fan > 0 and simDR_on_ground > 0 then
            if brake_temp_loc_l > simDR_oat then
                brake_temp_loc_l = brake_temp_loc_l - 0.03
            end
        end
        if bus36 > 0 and simDR_gear_fan > 0 and simDR_on_ground > 0 then
            if brake_temp_loc_r > simDR_oat then
                brake_temp_loc_r = brake_temp_loc_r - 0.03
            end
        end
        -- Reduce available braking progressively above the modeled threshold of 450.
        if brake_temp_loc_l > 450 then  
            if simDR_brake_l > 1 - (1 - ((1450 - brake_temp_loc_l)*0.001)) then 
                simDR_brake_l = 1 - (1 - ((1450 - brake_temp_loc_l)*0.001))
            end
        end
        if brake_temp_loc_r > 450 then  
            if simDR_brake_r > 1 - (1 - ((1450 - brake_temp_loc_r)*0.001)) then 
                simDR_brake_r = 1 - (1 - ((1450 - brake_temp_loc_r)*0.001))
            end
        end
        -- Cache whether any landing-gear leg is extended for the next cooling step.
        if simDR_gear1 < 0.01 and simDR_gear2 < 0.01 and simDR_gear3 < 0.01 then
            gears = 0
        else
            gears = 1
        end
    else
        -- Disabling failures clears accumulated thermal and icing state.
        brake_temp_loc_r = 0
        brake_temp_loc_l = 0
        doors_icing = 0
    end

    -- Build corrected low-pressure RPM indications. The correction term extends
    -- the displayed range once the original low-pressure value rises above 3.85.
    if simDR_rpm_low_1 > 3.85 then 
            rpm1_low_loc = simDR_rpm_low_1 + rpm1_correct
    else
            rpm1_low_loc = simDR_rpm_low_1
    end

    if simDR_rpm_low_2 > 3.85 then 
            rpm2_low_loc = simDR_rpm_low_2 + rpm2_correct
    else
            rpm2_low_loc = simDR_rpm_low_2
    end

    if simDR_rpm_low_3 > 3.85 then 
            rpm3_low_loc = simDR_rpm_low_3 + rpm3_correct
    else
            rpm3_low_loc = simDR_rpm_low_3
    end 

        
    -- Suppress normal annunciator updates during the engine lamp test.
    if simDR_light_test_eng < 1 then
        
        -- Illuminate bypass-valve annunciators in their respective RPM windows;
        -- night mode uses the reduced 0.75 intensity.
        if simDR_rpm_high_1 > 50 and simDR_rpm_high_1 < 76.5 and simDR_oilmeter_1_lit > 0 then
          if simDR_day_night_lit < 1 then
            simDR_bypass_vlv_1_lit = 1
          else
            simDR_bypass_vlv_1_lit = 0.75
          end
        end
        if simDR_rpm_high_2 > 50 and simDR_rpm_high_2 < 77.5 and simDR_oilmeter_2_lit > 0 then
          if simDR_day_night_lit < 1 then
            simDR_bypass_vlv_2_lit = 1
          else
            simDR_bypass_vlv_2_lit = 0.75
          end
        end
        if simDR_rpm_high_3 > 50 and simDR_rpm_high_3 < 77 and simDR_oilmeter_3_lit > 0 then
          if simDR_day_night_lit < 1 then
            simDR_bypass_vlv_3_lit = 1
          else
            simDR_bypass_vlv_3_lit = 0.75
          end
        end
        
        -- Temperature-compensated RPM thresholds for the VNA 33 and VNA 0 lights.
        vna33_off = 74.5+(simDR_oat/7.5)
        vna0_off = 91+(simDR_oat/6.31)
        
        if simDR_rpm_high_1 < vna33_off and simDR_oilmeter_1_lit > 0 then
          if simDR_day_night_lit < 1 then
            simDR_vna33_1_lit = 1
          else
            simDR_vna33_1_lit = 0.75
          end
        else
            simDR_vna33_1_lit = 0
        end
        if simDR_rpm_high_2 < vna33_off and simDR_oilmeter_2_lit > 0 then
          if simDR_day_night_lit < 1 then
            simDR_vna33_2_lit = 1
          else
            simDR_vna33_2_lit = 0.75
          end
        else
            simDR_vna33_2_lit = 0
        end
            
        
        if simDR_rpm_high_3 < vna33_off and simDR_oilmeter_3_lit > 0 then
          if simDR_day_night_lit < 1 then
            simDR_vna33_3_lit = 1
          else
            simDR_vna33_3_lit = 0.75
          end
        else
            simDR_vna33_3_lit = 0
        end
        
        if simDR_rpm_high_1 < vna0_off and simDR_oilmeter_1_lit > 0 then
          if simDR_day_night_lit < 1 then
            simDR_vna0_1_lit = 1
          else
            simDR_vna0_1_lit = 0.75
          end
        else
            simDR_vna0_1_lit = 0
        end
        if simDR_rpm_high_2 < vna0_off and simDR_oilmeter_2_lit > 0 then
          if simDR_day_night_lit < 1 then
            simDR_vna0_2_lit = 1
          else
            simDR_vna0_2_lit = 0.75
          end
        else
            simDR_vna0_2_lit = 0
        end
            
        
        if simDR_rpm_high_3 < vna0_off and simDR_oilmeter_3_lit > 0 then
          if simDR_day_night_lit < 1 then
            simDR_vna0_3_lit = 1
          else
            simDR_vna0_3_lit = 0.75
          end
        else
            simDR_vna0_3_lit = 0
        end
        -- Ramp a separate correction for each engine at high RPM instead of
        -- introducing an instantaneous jump in the low-pressure indication.
        if simDR_rpm_high_1 > 75 then
            if rpm1_correct < 3.85 and simDR_rpm_low_1 < 75 then
                if rpm1_correct < 3.83 then
                rpm1_correct = rpm1_correct + 0.12
                else
                rpm1_correct = 3.85
                end
            elseif rpm1_correct > 0 then
                rpm1_correct = rpm1_correct - 0.02
            else
                rpm1_correct = 0
            end
        else
            if rpm1_correct > 0 then
                rpm1_correct = rpm1_correct - 0.05
            else
                rpm1_correct = 0
            end
        end

        if simDR_rpm_high_2 > 78 then
            if rpm2_correct < 3.85 and simDR_rpm_low_2 < 75 then
                if rpm2_correct < 3.83 then
                 rpm2_correct = rpm2_correct + 0.12
                else
                    rpm2_correct = 3.852 
                end
            elseif rpm2_correct > 0 then
                rpm2_correct = rpm2_correct - 0.02
            else
                rpm2_correct = 0
            end
        else
            if rpm2_correct > 0 then
                rpm2_correct = rpm2_correct - 0.05
            else
                rpm2_correct = 0
            end
        end

        if simDR_rpm_high_3 > 77 then
            if rpm3_correct < 3.85 and simDR_rpm_low_3 < 75 then
                if rpm3_correct < 3.83 then
                    rpm3_correct = rpm3_correct + 0.12
                else
                    rpm3_correct = 3.851 
                end
            elseif rpm3_correct > 0 then
                rpm3_correct = rpm3_correct - 0.02
            else
                rpm3_correct = 0
            end
        else
            if rpm3_correct > 0 then
                rpm3_correct = rpm3_correct - 0.05
            else
                rpm3_correct = 0
            end
        end
        rpm1_correct_loc = rpm1_correct
        rpm2_correct_loc = rpm2_correct
        rpm3_correct_loc = rpm3_correct
    else
        -- Hold correction values stable while the lamp-test circuit owns the lights.
        rpm1_correct = rpm1_correct_loc
        rpm2_correct = rpm2_correct_loc
        rpm3_correct = rpm3_correct_loc
    end
    
    -- Publish non-negative corrected RPM values through this script's custom datarefs.
    if rpm1_low_loc > 0 then
        rpm1_low = rpm1_low_loc
    else
        rpm1_low = 0
    end

    if rpm2_low_loc > 0 then
        rpm2_low = rpm2_low_loc
    else
        rpm2_low = 0
    end

    if rpm3_low_loc > 0 then
        rpm3_low = rpm3_low_loc
    else
        rpm3_low = 0
    end 
end

-- xTLua physics callback. Run both update groups once per physics frame in their
-- established order.
function after_physics()
    m_misc()
    refueling()
end
