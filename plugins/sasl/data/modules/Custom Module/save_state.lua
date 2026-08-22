-- save_state.lua
-- Persistent aircraft state save/restore logic.

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"save_state", "tu154/custom/save_state", globalPropertyi},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"starter_torq", "sim/aircraft/engine/acf_starter_torque_ratio", globalPropertyf},
    {"hardware_cockpit", "tu154/custom/hardware_cockpit", globalPropertyi},
    {"fuel_q_1", "sim/flightmodel/weight/m_fuel[0]", globalProperty},
    {"fuel_q_4", "sim/flightmodel/weight/m_fuel[1]", globalProperty},
    {"fuel_q_2R", "sim/flightmodel/weight/m_fuel[2]", globalProperty},
    {"fuel_q_2L", "sim/flightmodel/weight/m_fuel[3]", globalProperty},
    {"fuel_q_3R", "sim/flightmodel/weight/m_fuel[4]", globalProperty},
    {"fuel_q_3L", "sim/flightmodel/weight/m_fuel[5]", globalProperty},
    {"hide_rus_objects", "tu154/custom/lang/hide_rus_objects", globalPropertyi},
    {"hide_eng_objects", "tu154/custom/lang/hide_eng_objects", globalPropertyi},
    {"sounds_voulme", "tu154/custom/sounds_voulme", globalPropertyi},
    {"enable_crew_vo", "tu154/custom/sounds/enable_crew_vo", globalPropertyi},
    {"failures_enabled", "tu154/custom/failures/failures_enabled", globalPropertyi},
    {"have_pedals", "tu154/custom/have_pedals", globalPropertyi},
    {"show_gns", "tu154/custom/anim/show_gns", globalPropertyi},
    {"show_RXP", "tu154/custom/anim/RXP", globalPropertyi},
    {"pnp_1_crs", "tu154/custom/gauges/compas/pkp_obs_set_L", globalPropertyf},
    {"pnp_2_crs", "tu154/custom/gauges/compas/pkp_obs_set_R", globalPropertyf},
    {"pnp_1_obs", "tu154/custom/gauges/compas/pkp_helper_course_L", globalPropertyf},
    {"pnp_2_obs", "tu154/custom/gauges/compas/pkp_helper_course_R", globalPropertyf},
    {"ark_1_channel", "tu154/custom/switchers/ovhd/ark_1_channel", globalPropertyi},
    {"ark_1_hundr_left", "tu154/custom/switchers/ovhd/ark_1_hundr_left", globalPropertyi},
    {"ark_1_tens_left", "tu154/custom/switchers/ovhd/ark_1_tens_left", globalPropertyi},
    {"ark_1_ones_left", "tu154/custom/switchers/ovhd/ark_1_ones_left", globalPropertyi},
    {"ark_1_hundr_right", "tu154/custom/switchers/ovhd/ark_1_hundr_right", globalPropertyi},
    {"ark_1_tens_right", "tu154/custom/switchers/ovhd/ark_1_tens_right", globalPropertyi},
    {"ark_1_ones_right", "tu154/custom/switchers/ovhd/ark_1_ones_right", globalPropertyi},
    {"ark_2_channel", "tu154/custom/switchers/ovhd/ark_2_channel", globalPropertyi},
    {"ark_2_hundr_left", "tu154/custom/switchers/ovhd/ark_2_hundr_left", globalPropertyi},
    {"ark_2_tens_left", "tu154/custom/switchers/ovhd/ark_2_tens_left", globalPropertyi},
    {"ark_2_ones_left", "tu154/custom/switchers/ovhd/ark_2_ones_left", globalPropertyi},
    {"ark_2_hundr_right", "tu154/custom/switchers/ovhd/ark_2_hundr_right", globalPropertyi},
    {"ark_2_tens_right", "tu154/custom/switchers/ovhd/ark_2_tens_right", globalPropertyi},
    {"ark_2_ones_right", "tu154/custom/switchers/ovhd/ark_2_ones_right", globalPropertyi},
    {"vd15_pressure_left", "tu154/custom/gauges/alt/vd15_pressure_left", globalPropertyf},
    {"vd15_pressure_right", "tu154/custom/gauges/alt/vd15_pressure_right", globalPropertyf},
    {"vd15_pressure_eng", "tu154/custom/gauges/alt/vd15_pressure_eng", globalPropertyf},
    {"uvid_pressure_knob", "tu154/custom/gauges/alt/uvid_pressure_knob", globalPropertyf},
    {"tks_lat_set", "tu154/custom/rotary/ovhd/tks_lat_set", globalPropertyf},
    {"ppd_3_heat_fail", "tu154/custom/antiice/ppd_3_heat_fail", globalPropertyi},
    {"rel_ice_inlet_heat1", "sim/operation/failures/rel_ice_inlet_heat", globalPropertyi},
    {"rel_ice_inlet_heat2", "sim/operation/failures/rel_ice_inlet_heat2", globalPropertyi},
    {"rel_ice_inlet_heat3", "sim/operation/failures/rel_ice_inlet_heat3", globalPropertyi},
    {"rel_ice_pitot_heat1", "sim/operation/failures/rel_ice_pitot_heat1", globalPropertyi},
    {"rel_ice_pitot_heat2", "sim/operation/failures/rel_ice_pitot_heat2", globalPropertyi},
    {"rel_ice_surf_heat", "sim/operation/failures/rel_ice_surf_heat", globalPropertyi},
    {"rel_ice_surf_heat2", "sim/operation/failures/rel_ice_surf_heat2", globalPropertyi},
    {"rio_fail", "tu154/custom/failures/rio_fail", globalPropertyi},
    {"window_heat_fail_1", "tu154/custom/failures/window_heat_fail_1", globalPropertyi},
    {"window_heat_fail_2", "tu154/custom/failures/window_heat_fail_2", globalPropertyi},
    {"window_heat_fail_3", "tu154/custom/failures/window_heat_fail_3", globalPropertyi},
    {"apu_start_fail", "tu154/custom/failures/apu_start_fail", globalPropertyi},
    {"apu_runtime", "tu154/custom/failures/apu_runtime", globalPropertyf},
    {"apu_fail", "tu154/custom/failures/apu_fail", globalPropertyi},
    {"apu_press_fail", "tu154/custom/failures/apu_press_fail", globalPropertyi},
    {"brake_runtime_left", "tu154/custom/failures/brake_runtime_left", globalPropertyf},
    {"brake_runtime_right", "tu154/custom/failures/brake_runtime_right", globalPropertyf},
    {"rel_lbrakes", "sim/operation/failures/rel_lbrakes", globalPropertyi},
    {"rel_rbrakes", "sim/operation/failures/rel_rbrakes", globalPropertyi},
    {"ail_fail_left", "tu154/custom/failures/ail_fail_left", globalPropertyi},
    {"ail_fail_right", "tu154/custom/failures/ail_fail_right", globalPropertyi},
    {"fail_spoil_inn_left", "tu154/custom/failures/fail_spoil_inn_left", globalPropertyi},
    {"fail_spoil_inn_right", "tu154/custom/failures/fail_spoil_inn_right", globalPropertyi},
    {"fail_spoil_mid_left", "tu154/custom/failures/fail_spoil_mid_left", globalPropertyi},
    {"fail_spoil_mid_right", "tu154/custom/failures/fail_spoil_mid_right", globalPropertyi},
    {"fail_spoil_out_left", "tu154/custom/failures/fail_spoil_out_left", globalPropertyi},
    {"fail_spoil_out_right", "tu154/custom/failures/fail_spoil_out_right", globalPropertyi},
    {"rudder_fail", "tu154/custom/failures/rudder_fail", globalPropertyi},
    {"elev_fail_left", "tu154/custom/failures/elev_fail_left", globalPropertyi},
    {"elev_fail_right", "tu154/custom/failures/elev_fail_right", globalPropertyi},
    {"rel_trim_rud", "sim/operation/failures/rel_trim_rud", globalPropertyi},
    {"rel_trim_ail", "sim/operation/failures/rel_trim_ail", globalPropertyi},
    {"rel_trim_elv", "sim/operation/failures/rel_trim_elv", globalPropertyi},
    {"trim_emerg_elv_fail", "tu154/custom/failures/trim_emerg_elv_fail", globalPropertyi},
    {"flap_fail_left", "tu154/custom/failures/flap_fail_left", globalPropertyi},
    {"flap_fail_right", "tu154/custom/failures/flap_fail_right", globalPropertyi},
    {"stab_eng_fail", "tu154/custom/failures/stab_eng_fail", globalPropertyi},
    {"stab_automatic_fail", "tu154/custom/failures/stab_automatic_fail", globalPropertyi},
    {"slats_fail", "tu154/custom/failures/slats_fail", globalPropertyi},
    {"retract1_fail", "sim/operation/failures/rel_lagear1", globalPropertyi},
    {"retract2_fail", "sim/operation/failures/rel_lagear2", globalPropertyi},
    {"retract3_fail", "sim/operation/failures/rel_lagear3", globalPropertyi},
    {"actuator_fail", "sim/operation/failures/rel_gear_act", globalPropertyi},
    {"rel_genera0", "sim/operation/failures/rel_genera0", globalPropertyi},
    {"rel_genera1", "sim/operation/failures/rel_genera1", globalPropertyi},
    {"rel_genera2", "sim/operation/failures/rel_genera2", globalPropertyi},
    {"apu_gen_fail", "tu154/custom/failures/apu_gen_fail", globalPropertyi},
    {"vu1_fail", "tu154/custom/failures/vu1_fail", globalPropertyi},
    {"vu2_fail", "tu154/custom/failures/vu2_fail", globalPropertyi},
    {"vu3_fail", "tu154/custom/failures/vu3_fail", globalPropertyi},
    {"tr1_fail", "tu154/custom/failures/tr1_fail", globalPropertyi},
    {"tr2_fail", "tu154/custom/failures/tr2_fail", globalPropertyi},
    {"pts250_1_fail", "tu154/custom/failures/pts250_1_fail", globalPropertyi},
    {"pts250_2_fail", "tu154/custom/failures/pts250_2_fail", globalPropertyi},
    {"inv115_fail", "tu154/custom/failures/inv115_fail", globalPropertyi},
    {"bat_1_fail", "tu154/custom/failures/bat_1_fail", globalPropertyi},
    {"bat_2_fail", "tu154/custom/failures/bat_2_fail", globalPropertyi},
    {"bat_3_fail", "tu154/custom/failures/bat_3_fail", globalPropertyi},
    {"bat_4_fail", "tu154/custom/failures/bat_4_fail", globalPropertyi},
    {"bat_1_kz", "tu154/custom/failures/bat_1_kz", globalPropertyi},
    {"bat_2_kz", "tu154/custom/failures/bat_2_kz", globalPropertyi},
    {"bat_3_kz", "tu154/custom/failures/bat_3_kz", globalPropertyi},
    {"bat_4_kz", "tu154/custom/failures/bat_4_kz", globalPropertyi},
    {"rel_engfai0", "sim/operation/failures/rel_engfai0", globalPropertyi},
    {"rel_engfai1", "sim/operation/failures/rel_engfai1", globalPropertyi},
    {"rel_engfai2", "sim/operation/failures/rel_engfai2", globalPropertyi},
    {"engine_runtime_1", "tu154/custom/failures/engine_runtime_1", globalPropertyf},
    {"engine_runtime_2", "tu154/custom/failures/engine_runtime_2", globalPropertyf},
    {"engine_runtime_3", "tu154/custom/failures/engine_runtime_3", globalPropertyf},
    {"eng_fuel_pmp_fail_1", "tu154/custom/failures/eng_fuel_pmp_fail_1", globalPropertyi},
    {"eng_fuel_pmp_fail_2", "tu154/custom/failures/eng_fuel_pmp_fail_2", globalPropertyi},
    {"eng_fuel_pmp_fail_3", "tu154/custom/failures/eng_fuel_pmp_fail_3", globalPropertyi},
    {"engn_oil_qty_1", "tu154/custom/failures/engn_oil_qty_1", globalPropertyf},
    {"engn_oil_qty_2", "tu154/custom/failures/engn_oil_qty_2", globalPropertyf},
    {"engn_oil_qty_3", "tu154/custom/failures/engn_oil_qty_3", globalPropertyf},
    {"engn_oil_leak_1", "tu154/custom/failures/engn_oil_leak_1", globalPropertyi},
    {"engn_oil_leak_2", "tu154/custom/failures/engn_oil_leak_2", globalPropertyi},
    {"engn_oil_leak_3", "tu154/custom/failures/engn_oil_leak_3", globalPropertyi},
    {"rel_oilpmp0", "sim/operation/failures/rel_oilpmp0", globalPropertyi},
    {"rel_oilpmp1", "sim/operation/failures/rel_oilpmp1", globalPropertyi},
    {"rel_oilpmp2", "sim/operation/failures/rel_oilpmp2", globalPropertyi},
    {"rel_eng_lo0", "sim/operation/failures/rel_eng_lo0", globalPropertyi},
    {"rel_eng_lo1", "sim/operation/failures/rel_eng_lo1", globalPropertyi},
    {"rel_eng_lo2", "sim/operation/failures/rel_eng_lo2", globalPropertyi},
    {"rel_startr0", "sim/operation/failures/rel_startr0", globalPropertyi},
    {"rel_startr1", "sim/operation/failures/rel_startr1", globalPropertyi},
    {"rel_startr2", "sim/operation/failures/rel_startr2", globalPropertyi},
    {"rel_ignitr0", "sim/operation/failures/rel_ignitr0", globalPropertyi},
    {"rel_ignitr1", "sim/operation/failures/rel_ignitr1", globalPropertyi},
    {"rel_ignitr2", "sim/operation/failures/rel_ignitr2", globalPropertyi},
    {"rel_revers0", "sim/operation/failures/rel_revers0", globalPropertyi},
    {"rel_revers2", "sim/operation/failures/rel_revers2", globalPropertyi},
    {"fuel_pump_2l_fail", "tu154/custom/failures/fuel_pump_2l_fail", globalPropertyi},
    {"fuel_pump_2r_fail", "tu154/custom/failures/fuel_pump_2r_fail", globalPropertyi},
    {"fuel_pump_3l_fail", "tu154/custom/failures/fuel_pump_3l_fail", globalPropertyi},
    {"fuel_pump_3r_fail", "tu154/custom/failures/fuel_pump_3r_fail", globalPropertyi},
    {"fuel_pump_1_fail", "tu154/custom/failures/fuel_pump_1_fail", globalPropertyi},
    {"fuel_pump_4_fail", "tu154/custom/failures/fuel_pump_4_fail", globalPropertyi},
    {"fuel_auto_fail", "tu154/custom/failures/fuel_auto_fail", globalPropertyi},
    {"fuel_level_fail", "tu154/custom/failures/fuel_level_fail", globalPropertyi},
    {"fuel_porc_fail", "tu154/custom/failures/fuel_porc_fail", globalPropertyi},
    {"fuel_meter_2l_fail", "tu154/custom/failures/fuel_meter_2l_fail", globalPropertyi},
    {"fuel_meter_2r_fail", "tu154/custom/failures/fuel_meter_2r_fail", globalPropertyi},
    {"fuel_meter_3l_fail", "tu154/custom/failures/fuel_meter_3l_fail", globalPropertyi},
    {"fuel_meter_3r_fail", "tu154/custom/failures/fuel_meter_3r_fail", globalPropertyi},
    {"fuel_meter_1_fail", "tu154/custom/failures/fuel_meter_1_fail", globalPropertyi},
    {"fuel_meter_4_fail", "tu154/custom/failures/fuel_meter_4_fail", globalPropertyi},
    {"fuel_meter_summ", "tu154/custom/failures/fuel_meter_summ", globalPropertyi},
    {"fuel_flowmeter_1_fail", "tu154/custom/failures/fuel_flowmeter_1_fail", globalPropertyi},
    {"fuel_flowmeter_2_fail", "tu154/custom/failures/fuel_flowmeter_2_fail", globalPropertyi},
    {"fuel_flowmeter_3_fail", "tu154/custom/failures/fuel_flowmeter_3_fail", globalPropertyi},
    {"hydro_leak_1", "tu154/custom/failures/hydro_leak_1", globalPropertyi},
    {"hydro_leak_2", "tu154/custom/failures/hydro_leak_2", globalPropertyi},
    {"hydro_leak_3", "tu154/custom/failures/hydro_leak_3", globalPropertyi},
    {"hydro_leak_4", "tu154/custom/failures/hydro_leak_4", globalPropertyi},
    {"hydro_pump_fail_11", "tu154/custom/failures/hydro_pump_fail_11", globalPropertyi},
    {"hydro_pump_fail_12", "tu154/custom/failures/hydro_pump_fail_12", globalPropertyi},
    {"hydro_pump_fail_2", "tu154/custom/failures/hydro_pump_fail_2", globalPropertyi},
    {"hydro_pump_fail_3", "tu154/custom/failures/hydro_pump_fail_3", globalPropertyi},
    {"hydro_elec_fail_2", "tu154/custom/failures/hydro_elec_fail_2", globalPropertyi},
    {"hydro_elec_fail_3", "tu154/custom/failures/hydro_elec_fail_3", globalPropertyi},
    {"gs_qty_1", "tu154/custom/hydro/gs_qty_1", globalPropertyf},
    {"gs_qty_2", "tu154/custom/hydro/gs_qty_2", globalPropertyf},
    {"gs_qty_3", "tu154/custom/hydro/gs_qty_3", globalPropertyf},
    {"tth_left_fail", "tu154/custom/failures/tth_left_fail", globalPropertyi},
    {"tth_right_fail", "tu154/custom/failures/tth_right_fail", globalPropertyi},
    {"airbleed_1", "tu154/custom/failures/airbleed_1", globalPropertyi},
    {"airbleed_2", "tu154/custom/failures/airbleed_2", globalPropertyi},
    {"airbleed_3", "tu154/custom/failures/airbleed_3", globalPropertyi},
    {"psvp_fail_left", "tu154/custom/failures/psvp_fail_left", globalPropertyi},
    {"psvp_fail_right", "tu154/custom/failures/psvp_fail_right", globalPropertyi},
    {"sard_valve_fail", "tu154/custom/failures/sard_valve_fail", globalPropertyi},
    {"lan_lamp_fail_FL", "tu154/custom/failures/lan_lamp_fail_FL", globalPropertyi},
    {"lan_lamp_fail_FR", "tu154/custom/failures/lan_lamp_fail_FR", globalPropertyi},
    {"lan_lamp_fail_WL", "tu154/custom/failures/lan_lamp_fail_WL", globalPropertyi},
    {"lan_lamp_fail_WR", "tu154/custom/failures/lan_lamp_fail_WR", globalPropertyi},
    {"rel_lites_nav", "sim/operation/failures/rel_lites_nav", globalPropertyi},
    {"rel_lites_beac", "sim/operation/failures/rel_lites_beac", globalPropertyi},
    {"main_alarm_fail", "tu154/custom/failures/main_alarm_fail", globalPropertyi},
    {"speaker_alarm_fail", "tu154/custom/failures/speaker_alarm_fail", globalPropertyi},
    {"absu_ra56_roll_fail", "tu154/custom/failures/absu_ra56_roll_fail", globalPropertyi},
    {"absu_ra56_pitch_fail", "tu154/custom/failures/absu_ra56_pitch_fail", globalPropertyi},
    {"absu_ra56_yaw_fail", "tu154/custom/failures/absu_ra56_yaw_fail", globalPropertyi},
    {"absu_at1_fail", "tu154/custom/failures/absu_at1_fail", globalPropertyi},
    {"absu_at2_fail", "tu154/custom/failures/absu_at2_fail", globalPropertyi},
    {"absu_damp_roll_fail", "tu154/custom/failures/absu_damp_roll_fail", globalPropertyi},
    {"absu_damp_pitch_fail", "tu154/custom/failures/absu_damp_pitch_fail", globalPropertyi},
    {"absu_damp_yaw_fail", "tu154/custom/failures/absu_damp_yaw_fail", globalPropertyi},
    {"absu_contr_roll_fail", "tu154/custom/failures/absu_contr_roll_fail", globalPropertyi},
    {"absu_contr_pitch_fail", "tu154/custom/failures/absu_contr_pitch_fail", globalPropertyi},
    {"absu_calc_toga_fail", "tu154/custom/failures/absu_calc_toga_fail", globalPropertyi},
    {"absu_calc_roll_fail", "tu154/custom/failures/absu_calc_roll_fail", globalPropertyi},
    {"absu_calc_pitch_fail", "tu154/custom/failures/absu_calc_pitch_fail", globalPropertyi},
    {"diss_fail", "tu154/custom/failures/diss_fail", globalPropertyi},
    {"nvu_fail", "tu154/custom/failures/nvu_fail", globalPropertyi},
    {"radar_fail", "tu154/custom/failures/radar_fail", globalPropertyi},
    {"ark1_fail", "sim/operation/failures/rel_adf1", globalPropertyi},
    {"ark2_fail", "sim/operation/failures/rel_adf2", globalPropertyi},
    {"nav1fail", "tu154/custom/failures/nav1_fail", globalPropertyi},
    {"nav2fail", "tu154/custom/failures/nav2_fail", globalPropertyi},
    {"dme1_fail", "tu154/custom/failures/dme1_fail", globalPropertyi},
    {"dme2_fail", "tu154/custom/failures/dme2_fail", globalPropertyi},
    {"mrp_fail", "tu154/custom/failures/mrp_fail", globalPropertyi},
    {"rsbn_fail", "tu154/custom/failures/rsbn_fail", globalPropertyi},
    {"taws_fail", "tu154/custom/failures/taws_fail", globalPropertyi},
    {"tks_ga1_fail", "sim/operation/failures/rel_ss_dgy", globalPropertyi},
    {"tks_ga2_fail", "sim/operation/failures/rel_cop_dgy", globalPropertyi},
    {"tks_km1_fail", "tu154/custom/failures/tks_km1_fail", globalPropertyi},
    {"tks_km2_fail", "tu154/custom/failures/tks_km2_fail", globalPropertyi},
    {"tks_bgmk1_fail", "tu154/custom/failures/tks_bgmk1_fail", globalPropertyi},
    {"tks_bgmk2_fail", "tu154/custom/failures/tks_bgmk2_fail", globalPropertyi},
    {"alt_1_fail", "sim/operation/failures/rel_ss_alt", globalPropertyi},
    {"alt_2_fail", "sim/operation/failures/rel_cop_alt", globalPropertyi},
    {"eup_fail", "sim/operation/failures/rel_ss_tsi", globalPropertyi},
    {"acs1_fail", "tu154/custom/failures/acs1_fail", globalPropertyi},
    {"acs2_fail", "tu154/custom/failures/acs2_fail", globalPropertyi},
    {"acs3_fail", "tu154/custom/failures/acs3_fail", globalPropertyi},
    {"agr_fail", "tu154/custom/failures/agr_fail", globalPropertyi},
    {"bkk_fail", "tu154/custom/failures/bkk_fail", globalPropertyi},
    {"rel_pitot", "tu154/custom/failures/pitot1", globalPropertyi},
    {"rel_pitot2", "tu154/custom/failures/pitot2", globalPropertyi},
    {"static_fail_L", "tu154/custom/failures/static1", globalPropertyi},
    {"static_fail_R", "tu154/custom/failures/static2", globalPropertyi},
    {"svs_fail", "sim/operation/failures/rel_adc_comp", globalPropertyi},
    {"mgv_fail", "tu154/custom/failures/mgv_fail", globalPropertyi},
    {"pkp1fail", "sim/operation/failures/rel_ss_ahz", globalPropertyi},
    {"pkp2fail", "sim/operation/failures/rel_cop_ahz", globalPropertyi},
    {"rv1_fail", "tu154/custom/failures/rv1_fail", globalPropertyi},
    {"rv2_fail", "tu154/custom/failures/rv2_fail", globalPropertyi},
    {"uap_fail", "tu154/custom/failures/AOA", globalPropertyi},
    {"uap_warn_fail", "sim/operation/failures/rel_stall_warn", globalPropertyi},
    {"uvid_fail", "tu154/custom/failures/uvid15_fail", globalPropertyi},
    {"vvi1_fail", "sim/operation/failures/rel_ss_vvi", globalPropertyi},
    {"vvi2_fail", "sim/operation/failures/rel_cop_vvi", globalPropertyi},
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

local stateFileName = moduleDirectory .. "/Custom Module/saved_state.ini"

-- Entry format: { key, property, saveMultiplier, loadMultiplier, floorOnSave }
-- Multipliers are only used where the legacy file format requires them.
local stateEntries = {
    {"rusLang", hide_eng_objects},
    {"volume", sounds_voulme},
    {"starterTRQ", starter_torq, 100, 0.01, true},
    {"crewvo", enable_crew_vo},
    {"hardwareCockpit", hardware_cockpit},
    {"tankone", fuel_q_1},
    {"tankfour", fuel_q_4},
    {"tanktwoL", fuel_q_2L},
    {"tanktwoR", fuel_q_2R},
    {"tankthreeL", fuel_q_3L},
    {"tankthreeR", fuel_q_3R},
    {"enableFailures", failures_enabled},
    {"useNWaxis", have_pedals},
    {"gnsInstaled", show_gns},
    {"RXPInstaled", show_RXP},
    {"pnpCrs1", pnp_1_crs},
    {"pnpCrs2", pnp_2_crs},
    {"pnp1OBS", pnp_1_obs},
    {"pnp2OBS", pnp_2_obs},
    {"ark1ch", ark_1_channel},
    {"ark1hunL", ark_1_hundr_left},
    {"ark1tenL", ark_1_tens_left},
    {"ark1oneL", ark_1_ones_left},
    {"ark1hunR", ark_1_hundr_right},
    {"ark1tenR", ark_1_tens_right},
    {"ark1oneR", ark_1_ones_right},
    {"ark2ch", ark_2_channel},
    {"ark2hunL", ark_2_hundr_left},
    {"ark2tenL", ark_2_tens_left},
    {"ark2oneL", ark_2_ones_left},
    {"ark2hunR", ark_2_hundr_right},
    {"ark2tenR", ark_2_tens_right},
    {"ark2oneR", ark_2_ones_right},
    {"vdPressL", vd15_pressure_left},
    {"vdPressR", vd15_pressure_right},
    {"vdPressE", vd15_pressure_eng},
    {"uvidPress", uvid_pressure_knob},
    {"tksLatSet", tks_lat_set, 1000, 0.001, false},
    {"ppd3HeatFail", ppd_3_heat_fail},
    {"engHeat1", rel_ice_inlet_heat1},
    {"engHeat2", rel_ice_inlet_heat2},
    {"engHeat3", rel_ice_inlet_heat3},
    {"pitotHeatFail1", rel_ice_pitot_heat1},
    {"pitotHeatFail2", rel_ice_pitot_heat2},
    {"wingHeatFail", rel_ice_surf_heat},
    {"slatHeatFail", rel_ice_surf_heat2},
    {"iceDetFail", rio_fail},
    {"windowHeatFail1", window_heat_fail_1},
    {"windowHeatFail2", window_heat_fail_2},
    {"windowHeatFail3", window_heat_fail_3},
    {"apuStartFail", apu_start_fail},
    {"apuRuntime", apu_runtime},
    {"apuFail", apu_fail},
    {"apuAirFail", apu_press_fail},
    {"brakeRunLeft", brake_runtime_left, 1000, 0.001, false},
    {"brakeRunRight", brake_runtime_right, 1000, 0.001, false},
    {"brakeFailLeft", rel_lbrakes},
    {"brakeFailRight", rel_rbrakes},
    {"ailFailLeft", ail_fail_left},
    {"ailFailRight", ail_fail_right},
    {"spoilInnLeft", fail_spoil_inn_left},
    {"spoilInnRight", fail_spoil_inn_right},
    {"spoilMidLeft", fail_spoil_mid_left},
    {"spoilMidRight", fail_spoil_mid_right},
    {"spoilOutLeft", fail_spoil_out_left},
    {"spoilOutRight", fail_spoil_out_right},
    {"rudderFail", rudder_fail},
    {"elevFailLeft", elev_fail_left},
    {"elevFailRight", elev_fail_right},
    {"rudtrimFail", rel_trim_rud},
    {"ailTrimFail", rel_trim_ail},
    {"elevTrimFail", rel_trim_elv},
    {"elevEmergTraimFail", trim_emerg_elv_fail},
    {"flapFailLeft", flap_fail_left},
    {"flapFailRight", flap_fail_right},
    {"stabEngFail", stab_eng_fail},
    {"stabAutoFail", stab_automatic_fail},
    {"slatFail", slats_fail},
    {"gearRetrFail1", retract1_fail},
    {"gearRetrFail2", retract2_fail},
    {"gearRetrFail3", retract3_fail},
    {"gearActFail", actuator_fail},
    {"gen1Fail", rel_genera0},
    {"gen2Fail", rel_genera1},
    {"gen3Fail", rel_genera2},
    {"genApuFail", apu_gen_fail},
    {"vu1Fail", vu1_fail},
    {"vu2Fail", vu2_fail},
    {"vu3Fail", vu3_fail},
    {"tr1Fail", tr1_fail},
    {"tr2Fail", tr2_fail},
    {"pts1Fail", pts250_1_fail},
    {"pts2Fail", pts250_2_fail},
    {"inv115Fail", inv115_fail},
    {"bat1Fail", bat_1_fail},
    {"bat2Fail", bat_2_fail},
    {"bat3Fail", bat_3_fail},
    {"bat4Fail", bat_4_fail},
    {"bat1KZ", bat_1_kz},
    {"bat2KZ", bat_2_kz},
    {"bat3KZ", bat_3_kz},
    {"bat4KZ", bat_4_kz},
    {"engFail1", rel_engfai0},
    {"engFail2", rel_engfai1},
    {"engFail3", rel_engfai2},
    {"engRunTime1", engine_runtime_1},
    {"engRunTime2", engine_runtime_2},
    {"engRunTime3", engine_runtime_3},
    {"engFuelPumpFail1", eng_fuel_pmp_fail_1},
    {"engFuelPumpFail2", eng_fuel_pmp_fail_2},
    {"engFuelPumpFail3", eng_fuel_pmp_fail_3},
    {"engOilQty1", engn_oil_qty_1},
    {"engOilQty2", engn_oil_qty_2},
    {"engOilQty3", engn_oil_qty_3},
    {"engOilLeak1", engn_oil_leak_1},
    {"engOilLeak2", engn_oil_leak_2},
    {"engOilLeak3", engn_oil_leak_3},
    {"engOilPumpFail1", rel_oilpmp0},
    {"engOilPumpFail2", rel_oilpmp1},
    {"engOilPumpFail3", rel_oilpmp2},
    {"engFuelFilterFail1", rel_eng_lo0},
    {"engFuelFilterFail2", rel_eng_lo1},
    {"engFuelFilterFail3", rel_eng_lo2},
    {"engStarterFail1", rel_startr0},
    {"engStarterFail2", rel_startr1},
    {"engStarterFail3", rel_startr2},
    {"engIgnitFail1", rel_ignitr0},
    {"engIgnitFail2", rel_ignitr1},
    {"engIgnitFail3", rel_ignitr2},
    {"engReversFail1", rel_revers0},
    {"engReversFail3", rel_revers2},
    {"fuelPumpFail2L", fuel_pump_2l_fail},
    {"fuelPumpFail2R", fuel_pump_2r_fail},
    {"fuelPumpFail3L", fuel_pump_3l_fail},
    {"fuelPumpFail3R", fuel_pump_3r_fail},
    {"fuelPumpFail1", fuel_pump_1_fail},
    {"fuelPumpFail4", fuel_pump_4_fail},
    {"fuelAutoFail", fuel_auto_fail},
    {"fuelLvlFail", fuel_level_fail},
    {"fuelPorcFail", fuel_porc_fail},
    {"fuelMeterFail2L", fuel_meter_2l_fail},
    {"fuelMeterFail2R", fuel_meter_2r_fail},
    {"fuelMeterFail3L", fuel_meter_3l_fail},
    {"fuelMeterFail3R", fuel_meter_3r_fail},
    {"fuelMeterFail1", fuel_meter_1_fail},
    {"fuelMeterFail4", fuel_meter_4_fail},
    {"fuelMeterFailSumm", fuel_meter_summ},
    {"FF1fail", fuel_flowmeter_1_fail},
    {"FF2fail", fuel_flowmeter_2_fail},
    {"FF3fail", fuel_flowmeter_3_fail},
    {"hydroLeak1", hydro_leak_1},
    {"hydroLeak2", hydro_leak_2},
    {"hydroLeak3", hydro_leak_3},
    {"hydroLeak4", hydro_leak_4},
    {"hydroPmpFail11", hydro_pump_fail_11},
    {"hydroPmpFail12", hydro_pump_fail_12},
    {"hydroPmpFail2", hydro_pump_fail_2},
    {"hydroPmpFail3", hydro_pump_fail_3},
    {"HydroElecFail2", hydro_elec_fail_2},
    {"HydroElecFail3", hydro_elec_fail_3},
    {"hydroQty1", gs_qty_1, 100000, 1e-05, false},
    {"hydroQty2", gs_qty_2, 100000, 1e-05, false},
    {"hydroQty3", gs_qty_3, 100000, 1e-05, false},
    {"tthLeftFail", tth_left_fail},
    {"tthRightFail", tth_right_fail},
    {"airbleedFail1", airbleed_1},
    {"airbleedFail2", airbleed_2},
    {"airbleedFail3", airbleed_3},
    {"psvpFailL", psvp_fail_left},
    {"psvpFailR", psvp_fail_right},
    {"sardValveFail", sard_valve_fail},
    {"lanLampFLFail", lan_lamp_fail_FL},
    {"lanLampFRFail", lan_lamp_fail_FR},
    {"lanLampWLFail", lan_lamp_fail_WL},
    {"lanLampWRFail", lan_lamp_fail_WR},
    {"navLampFail", rel_lites_nav},
    {"beacLampFail", rel_lites_beac},
    {"mainAlarmFail", main_alarm_fail},
    {"spekAlarmFail", speaker_alarm_fail},
    {"absuRArollFail", absu_ra56_roll_fail},
    {"absuRApitchFail", absu_ra56_pitch_fail},
    {"absuRAyawFail", absu_ra56_yaw_fail},
    {"absuAT1Fail", absu_at1_fail},
    {"absuAT2Fail", absu_at2_fail},
    {"absuDampRollFail", absu_damp_roll_fail},
    {"absuDampPitchFail", absu_damp_pitch_fail},
    {"absuDampYawFail", absu_damp_yaw_fail},
    {"absuContrRollFail", absu_contr_roll_fail},
    {"absuContrPitchFail", absu_contr_pitch_fail},
    {"absuCalcTogaFail", absu_calc_toga_fail},
    {"absuCalcRollFail", absu_calc_roll_fail},
    {"absuCalcPitchFail", absu_calc_pitch_fail},
    {"dissFail", diss_fail},
    {"nvuFail", nvu_fail},
    {"radarFail", radar_fail},
    {"ark1fail", ark1_fail},
    {"ark2fail", ark2_fail},
    {"nav1fail", nav1fail},
    {"nav2fail", nav2fail},
    {"dme1Fail", dme1_fail},
    {"dme2Fail", dme2_fail},
    {"mrpFail", mrp_fail},
    {"tksGaFail1", tks_ga1_fail},
    {"tksGaFail2", tks_ga2_fail},
    {"tksKMFail1", tks_km1_fail},
    {"tksKMFail2", tks_km2_fail},
    {"tksBgmkFail1", tks_bgmk1_fail},
    {"tksBgmkFail2", tks_bgmk2_fail},
    {"rsbnFail", rsbn_fail},
    {"tawsFail", taws_fail},
    {"alt1fail", alt_1_fail},
    {"alt2fail", alt_2_fail},
    {"eupFail", eup_fail},
    {"acs1fail", acs1_fail},
    {"acs2fail", acs2_fail},
    {"acs3fail", acs3_fail},
    {"agrFail", agr_fail},
    {"bkkFail", bkk_fail},
    {"pitot1Fail", rel_pitot},
    {"pitot2Fail", rel_pitot2},
    {"static1Fail", static_fail_L},
    {"static2Fail", static_fail_R},
    {"svsFail", svs_fail},
    {"mgvFail", mgv_fail},
    {"pkp1fail", pkp1fail},
    {"pkp2fail", pkp2fail},
    {"rv1fail", rv1_fail},
    {"rv2fail", rv2_fail},
    {"uapFail", uap_fail},
    {"uapWarnFail", uap_warn_fail},
    {"uvid15fail", uvid_fail},
    {"vvi1fail", vvi1_fail},
    {"vvi2fail", vvi2_fail},
}

local function encodeValue(entry)
    local value = get(entry[2])

    if entry[3] then
        value = value * entry[3]
    end

    if entry[5] then
        value = math.floor(value)
    end

    return value
end

local function decodeValue(entry, value)
    if entry[4] then
        value = value * entry[4]
    end

    set(entry[2], value)
end

local function writeFile()
    local savefile = io.open(stateFileName, "w")

    if not savefile then
        print("State save failed: cannot open " .. stateFileName)
        return false
    end

    for _, entry in ipairs(stateEntries) do
        savefile:write(entry[1], "=", tostring(encodeValue(entry)), "\n")
    end

    savefile:close()
    print("State saved: OK")
    return true
end

local function readFile()
    local savefile = io.open(stateFileName, "r")

    if not savefile then
        print("State file not found; keeping current aircraft state")
        return false
    end

    local values = {}

    for line in savefile:lines() do
        local key, rawValue = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")

        if key and rawValue then
            local value = tonumber(rawValue)

            if value ~= nil then
                values[key] = value
            end
        end
    end

    savefile:close()

    for _, entry in ipairs(stateEntries) do
        local value = values[entry[1]]

        if value ~= nil then
            decodeValue(entry, value)
        end
    end

    -- Russian and English object visibility are complementary.
    if values["rusLang"] ~= nil then
        set(hide_rus_objects, 1 - values["rusLang"])
    end

    print("State restored: OK")
    return true
end

local startCounter = 0
local saveCounter = 0
local startupHandled = false

function update()
    local passed = get(frame_time)
    local MASTER = get(ismaster) ~= 1

    startCounter = startCounter + passed
    saveCounter = saveCounter + passed

    -- Restore once after aircraft initialization has settled.
    if not startupHandled and startCounter > 2 then
        if MASTER then
            readFile()
        end

        startupHandled = true
    end

    if not MASTER then
        return
    end

    local manualSave = get(save_state) == 1

    if manualSave or saveCounter >= 90 then
        writeFile()

        if manualSave then
            set(save_state, 0)
            saveCounter = 0
        else
            saveCounter = saveCounter % 90
        end
    end
end
