-- One-shot flight configuration for X-Plane's "Start with engines running" option.
-- Only cockpit controls belong here. Native engines, autopilot engagement,
-- failures, payload/fuel quantities and hydraulic state remain system-owned.
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    { "startup_running", "sim/operation/prefs/startup_running", globalPropertyi },
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    -- Main electrical supplies and normal bus configuration
    { "gen_1_on", "tu154/custom/switchers/eng/gen_1_on", globalPropertyi },
    { "gen_2_on", "tu154/custom/switchers/eng/gen_2_on", globalPropertyi },
    { "gen_3_on", "tu154/custom/switchers/eng/gen_3_on", globalPropertyi },
    { "bus27_vu1", "tu154/custom/switchers/eng/bus27_vu1", globalPropertyi },
    { "bus27_vu2", "tu154/custom/switchers/eng/bus27_vu2", globalPropertyi },
    { "bat1_on", "tu154/custom/switchers/eng/bat1_on", globalPropertyi },
    { "bat2_on", "tu154/custom/switchers/eng/bat2_on", globalPropertyi },
    { "bat3_on", "tu154/custom/switchers/eng/bat3_on", globalPropertyi },
    { "bat4_on", "tu154/custom/switchers/eng/bat4_on", globalPropertyi },
    { "gpu_on", "tu154/custom/switchers/eng/gpu_on", globalPropertyi },
    { "apu_gen_on", "tu154/custom/switchers/eng/apu_gen_on", globalPropertyi },
    { "emerg_inv115", "tu154/custom/switchers/eng/emerg_inv115", globalPropertyi },
    { "emerg_inv115_cap", "tu154/custom/switchers/eng/emerg_inv115_cap", globalPropertyi },
    { "bus36_tr_left_to_right", "tu154/custom/switchers/eng/bus36_tr_left_to_right", globalPropertyi },
    { "bus36_tr_right_to_left", "tu154/custom/switchers/eng/bus36_tr_right_to_left", globalPropertyi },
    { "pts250_on", "tu154/custom/switchers/eng/pts250_on", globalPropertyi },
    { "pts250_mode", "tu154/custom/switchers/eng/pts250_mode", globalPropertyi },
    { "pts250_on_cap", "tu154/custom/switchers/eng/pts250_on_cap", globalPropertyi },
    { "pts250_mode_cap", "tu154/custom/switchers/eng/pts250_mode_cap", globalPropertyi },
    { "bus27_connect", "tu154/custom/switchers/eng/bus27_connect", globalPropertyi },
    { "bus27_connect_cap", "tu154/custom/switchers/eng/bus27_connect_cap", globalPropertyi },
    { "emerg_gen_on_1", "tu154/custom/switchers/eng/emerg_gen_on_1", globalPropertyi },
    { "emerg_gen_on_2", "tu154/custom/switchers/eng/emerg_gen_on_2", globalPropertyi },
    { "emerg_gen_on_3", "tu154/custom/switchers/eng/emerg_gen_on_3", globalPropertyi },
    { "emerg_gen_on_1_cap", "tu154/custom/switchers/eng/emerg_gen_on_1_cap", globalPropertyi },
    { "emerg_gen_on_2_cap", "tu154/custom/switchers/eng/emerg_gen_on_2_cap", globalPropertyi },
    { "emerg_gen_on_3_cap", "tu154/custom/switchers/eng/emerg_gen_on_3_cap", globalPropertyi },

    -- Fuel pumps, automatic feed and fire shutoff valves
    { "pump_tank2_left", "tu154/custom/switchers/fuel/pump_tank2_left", globalPropertyi },
    { "pump_tank2_right", "tu154/custom/switchers/fuel/pump_tank2_right", globalPropertyi },
    { "pump_tank3_left", "tu154/custom/switchers/fuel/pump_tank3_left", globalPropertyi },
    { "pump_tank3_right", "tu154/custom/switchers/fuel/pump_tank3_right", globalPropertyi },
    { "pump_tank4", "tu154/custom/switchers/fuel/pump_tank4", globalPropertyi },
    { "pump_tank1_1", "tu154/custom/switchers/fuel/pump_tank1_1", globalPropertyi },
    { "pump_tank1_2", "tu154/custom/switchers/fuel/pump_tank1_2", globalPropertyi },
    { "pump_tank1_3", "tu154/custom/switchers/fuel/pump_tank1_3", globalPropertyi },
    { "pump_tank1_4", "tu154/custom/switchers/fuel/pump_tank1_4", globalPropertyi },
    { "fuel_level", "tu154/custom/switchers/fuel/fuel_level", globalPropertyi },
    { "fuel_flow_mode", "tu154/custom/switchers/fuel/fuel_flow_mode", globalPropertyi },
    { "fuel_flow_on", "tu154/custom/switchers/fuel/fuel_flow_on", globalPropertyi },
    { "fuel_meter_on", "tu154/custom/switchers/fuel/fuel_meter_on", globalPropertyi },
    { "fuel_meter_mech_on", "tu154/custom/switchers/fuel/fuel_meter_mech_on", globalPropertyi },
    { "fire_valve_1", "tu154/custom/switchers/fuel/fire_valve_1", globalPropertyi },
    { "fire_valve_2", "tu154/custom/switchers/fuel/fire_valve_2", globalPropertyi },
    { "fire_valve_3", "tu154/custom/switchers/fuel/fire_valve_3", globalPropertyi },
    { "fuel_trans", "tu154/custom/switchers/fuel/fuel_trans", globalPropertyi },
    { "fuel_trans_cap", "tu154/custom/switchers/fuel/fuel_trans_cap", globalPropertyi },
    { "fuel_porc", "tu154/custom/switchers/fuel/fuel_porc", globalPropertyi },
    { "fuel_porc_cap", "tu154/custom/switchers/fuel/fuel_porc_cap", globalPropertyi },
    { "fuel_flow_on_cap", "tu154/custom/switchers/fuel/fuel_flow_on_cap", globalPropertyi },
    { "fire_valve_1_cap", "tu154/custom/switchers/fuel/fire_valve_1_cap", globalPropertyi },
    { "fire_valve_2_cap", "tu154/custom/switchers/fuel/fire_valve_2_cap", globalPropertyi },
    { "fire_valve_3_cap", "tu154/custom/switchers/fuel/fire_valve_3_cap", globalPropertyi },

    -- Start-system fuel admission; native engine start remains X-Plane owned
    { "fuel_in_1", "tu154/custom/start/fuel_in_1", globalPropertyi },
    { "fuel_in_2", "tu154/custom/start/fuel_in_2", globalPropertyi },
    { "fuel_in_3", "tu154/custom/start/fuel_in_3", globalPropertyi },

    -- Clear stale start-panel commands before a new flight's engine update.
    { "starter_cap", "tu154/custom/switchers/eng/starter_cap", globalPropertyi },
    { "starter_switch", "tu154/custom/switchers/eng/starter_switch", globalPropertyi },
    { "starter_eng_select", "tu154/custom/switchers/eng/starter_eng_select", globalPropertyi },
    { "starter_mode", "tu154/custom/switchers/eng/starter_mode", globalPropertyi },
    { "starter_start", "tu154/custom/buttons/eng/starter_start", globalPropertyi },
    { "starter_stop", "tu154/custom/buttons/eng/starter_stop", globalPropertyi },
    { "flight_start_1", "tu154/custom/buttons/eng/flight_start_1", globalPropertyi },
    { "flight_start_2", "tu154/custom/buttons/eng/flight_start_2", globalPropertyi },
    { "flight_start_3", "tu154/custom/buttons/eng/flight_start_3", globalPropertyi },

    -- Engine instrumentation and fire detection
    { "gauges_on_1", "tu154/custom/switchers/eng/gauges_on_1", globalPropertyi },
    { "gauges_on_2", "tu154/custom/switchers/eng/gauges_on_2", globalPropertyi },
    { "gauges_on_3", "tu154/custom/switchers/eng/gauges_on_3", globalPropertyi },
    { "fire_main_switch", "tu154/custom/switchers/eng/fire_main_switch", globalPropertyi },
    { "gauges_on_1_cap", "tu154/custom/switchers/eng/gauges_on_1_cap", globalPropertyi },
    { "gauges_on_2_cap", "tu154/custom/switchers/eng/gauges_on_2_cap", globalPropertyi },
    { "gauges_on_3_cap", "tu154/custom/switchers/eng/gauges_on_3_cap", globalPropertyi },
    { "fire_buzzer", "tu154/custom/switchers/eng/fire_buzzer", globalPropertyi },
    { "fire_buzzer_cap", "tu154/custom/switchers/eng/fire_buzzer_cap", globalPropertyi },

    -- Flight-control boosters and ABSU preparation, without engaging the autopilot
    { "buster_on_1", "tu154/custom/switchers/console/buster_on_1", globalPropertyi },
    { "buster_on_2", "tu154/custom/switchers/console/buster_on_2", globalPropertyi },
    { "buster_on_3", "tu154/custom/switchers/console/buster_on_3", globalPropertyi },
    { "absu_needles_on", "tu154/custom/switchers/console/absu_needles_on", globalPropertyi },
    { "absu_nav_on", "tu154/custom/switchers/console/absu_nav_on", globalPropertyi },
    { "absu_speed_prepare", "tu154/custom/switchers/console/absu_speed_prepare", globalPropertyi },
    { "absu_roll_ch_on", "tu154/custom/switchers/console/absu_roll_ch_on", globalPropertyi },
    { "absu_pitch_ch_on", "tu154/custom/switchers/console/absu_pitch_ch_on", globalPropertyi },
    { "nvu_power_on", "tu154/custom/switchers/console/nvu_power_on", globalPropertyi },
    { "busters_cap", "tu154/custom/switchers/console/busters_cap", globalPropertyi },
    { "absu_speed_prepare_cap", "tu154/custom/switchers/console/absu_speed_prepare_cap", globalPropertyi },

    -- Autothrottle engine disconnect buttons
    { "absu_throt_off_1", "tu154/custom/buttons/console/absu_throt_off_1", globalPropertyi },
    { "absu_throt_off_2", "tu154/custom/buttons/console/absu_throt_off_2", globalPropertyi },
    { "absu_throt_off_3", "tu154/custom/buttons/console/absu_throt_off_3", globalPropertyi },

    -- Nosewheel control guards
    { "nosewheel_turn_enable", "tu154/custom/switchers/nosewheel_turn_enable", globalPropertyi },
    { "nosewheel_turn_sel", "tu154/custom/switchers/nosewheel_turn_sel", globalPropertyi },
    { "nosewheel_turn_cap", "tu154/custom/switchers/nosewheel_turn_cap", globalPropertyi },

    -- Bleed air and automatic cabin-temperature regulation
    { "cockpit_mode_set", "tu154/custom/switchers/airbleed/cockpit_mode_set", globalPropertyi },
    { "cabin1_mode_set", "tu154/custom/switchers/airbleed/cabin1_mode_set", globalPropertyi },
    { "cabin2_mode_set", "tu154/custom/switchers/airbleed/cabin2_mode_set", globalPropertyi },
    { "left_sys_mode_set", "tu154/custom/switchers/airbleed/left_sys_mode_set", globalPropertyi },
    { "right_sys_mode_set", "tu154/custom/switchers/airbleed/right_sys_mode_set", globalPropertyi },
    { "psvp_left_on", "tu154/custom/switchers/airbleed/psvp_left_on", globalPropertyi },
    { "psvp_right_on", "tu154/custom/switchers/airbleed/psvp_right_on", globalPropertyi },
    { "eng_valve_1", "tu154/custom/switchers/airbleed/eng_valve_1", globalPropertyi },
    { "eng_valve_2", "tu154/custom/switchers/airbleed/eng_valve_2", globalPropertyi },
    { "eng_valve_3", "tu154/custom/switchers/airbleed/eng_valve_3", globalPropertyi },
    { "psvp_left_on_cap", "tu154/custom/switchers/airbleed/psvp_left_on_cap", globalPropertyi },
    { "psvp_right_on_cap", "tu154/custom/switchers/airbleed/psvp_right_on_cap", globalPropertyi },

    -- Navigation and flight instruments
    { "diss_on", "tu154/custom/switchers/ovhd/diss_on", globalPropertyi },
    { "diss_mode", "tu154/custom/switchers/ovhd/diss_mode", globalPropertyi },
    { "nvu_calc_set", "tu154/custom/switchers/ovhd/nvu_calc_set", globalPropertyi },
    { "ark_1_mode", "tu154/custom/switchers/ovhd/ark_1_mode", globalPropertyi },
    { "ark_2_mode", "tu154/custom/switchers/ovhd/ark_2_mode", globalPropertyi },
    { "var_left", "tu154/custom/switchers/ovhd/var_left", globalPropertyi },
    { "var_right", "tu154/custom/switchers/ovhd/var_right", globalPropertyi },
    { "auasp_on", "tu154/custom/switchers/ovhd/auasp_on", globalPropertyi },
    { "eup_on", "tu154/custom/switchers/ovhd/eup_on", globalPropertyi },
    { "agr_on", "tu154/custom/switchers/ovhd/agr_on", globalPropertyi },
    { "tks_on_1", "tu154/custom/switchers/ovhd/tks_on_1", globalPropertyi },
    { "tks_on_2", "tu154/custom/switchers/ovhd/tks_on_2", globalPropertyi },
    { "svs_on", "tu154/custom/switchers/ovhd/svs_on", globalPropertyi },
    { "svs_heat", "tu154/custom/switchers/ovhd/svs_heat", globalPropertyi },
    { "kln_on", "tu154/custom/switchers/ovhd/kln_on", globalPropertyi },
    { "tcas_on", "tu154/custom/switchers/ovhd/tcas_on", globalPropertyi },
    { "vbe_1_on", "tu154/custom/switchers/ovhd/vbe_1_on", globalPropertyi },
    { "vbe_2_on", "tu154/custom/switchers/ovhd/vbe_2_on", globalPropertyi },
    { "curs_np_on_1", "tu154/custom/switchers/ovhd/curs_np_on_1", globalPropertyi },
    { "curs_np_on_2", "tu154/custom/switchers/ovhd/curs_np_on_2", globalPropertyi },
    { "tra_67_on", "tu154/custom/switchers/ovhd/tra_67_on", globalPropertyi },
    { "rsbn_on", "tu154/custom/switchers/ovhd/rsbn_on", globalPropertyi },
    { "rv5_1_on", "tu154/custom/switchers/ovhd/rv5_1_on", globalPropertyi },
    { "rv5_2_on", "tu154/custom/switchers/ovhd/rv5_2_on", globalPropertyi },
    { "vhf_1_on", "tu154/custom/switchers/ovhd/vhf_1_on", globalPropertyi },
    { "vhf_2_on", "tu154/custom/switchers/ovhd/vhf_2_on", globalPropertyi },
    { "uvid_on", "tu154/custom/switchers/ovhd/uvid_on", globalPropertyi },
    { "mars_on", "tu154/custom/switchers/ovhd/mars_on", globalPropertyi },

    -- Guarded overhead power switches
    { "bkk_contr_cap", "tu154/custom/switchers/ovhd/bkk_contr_cap", globalPropertyi },
    { "bkk_on_cap", "tu154/custom/switchers/ovhd/bkk_on_cap", globalPropertyi },
    { "sau_stu_cap", "tu154/custom/switchers/ovhd/sau_stu_cap", globalPropertyi },
    { "pkp_left_cap", "tu154/custom/switchers/ovhd/pkp_left_cap", globalPropertyi },
    { "pkp_right_cap", "tu154/custom/switchers/ovhd/pkp_right_cap", globalPropertyi },
    { "mgv_contr_cap", "tu154/custom/switchers/ovhd/mgv_contr_cap", globalPropertyi },
    { "bkk_contr", "tu154/custom/switchers/ovhd/bkk_contr", globalPropertyi },
    { "bkk_on", "tu154/custom/switchers/ovhd/bkk_on", globalPropertyi },
    { "sau_stu_on", "tu154/custom/switchers/ovhd/sau_stu_on", globalPropertyi },
    { "pkp_left_on", "tu154/custom/switchers/ovhd/pkp_left_on", globalPropertyi },
    { "pkp_right_on", "tu154/custom/switchers/ovhd/pkp_right_on", globalPropertyi },
    { "mgv_contr", "tu154/custom/switchers/ovhd/mgv_contr", globalPropertyi },

    -- Window/probe heat and ice detection; wing/engine anti-ice remain off
    { "window_heat_1", "tu154/custom/switchers/ovhd/window_heat_1", globalPropertyi },
    { "window_heat_2", "tu154/custom/switchers/ovhd/window_heat_2", globalPropertyi },
    { "window_heat_3", "tu154/custom/switchers/ovhd/window_heat_3", globalPropertyi },
    { "pitot_heat_1", "tu154/custom/switchers/ovhd/pitot_heat_1", globalPropertyi },
    { "pitot_heat_2", "tu154/custom/switchers/ovhd/pitot_heat_2", globalPropertyi },
    { "pitot_heat_3", "tu154/custom/switchers/ovhd/pitot_heat_3", globalPropertyi },

    -- Icing detector and demand-only anti-ice switches
    { "soi21_on", "tu154/custom/switchers/eng/soi21_on", globalPropertyi },
    { "antiice_slats", "tu154/custom/switchers/eng/antiice_slats", globalPropertyi },
    { "antiice_eng_1", "tu154/custom/switchers/eng/antiice_eng_1", globalPropertyi },
    { "antiice_eng_2", "tu154/custom/switchers/eng/antiice_eng_2", globalPropertyi },
    { "antiice_eng_3", "tu154/custom/switchers/eng/antiice_eng_3", globalPropertyi },
    { "antiice_wing", "tu154/custom/switchers/eng/antiice_wing", globalPropertyi },

    -- Flight recorder
    { "msrp_mlp_1", "tu154/custom/switchers/eng/msrp_mlp_1", globalPropertyi },
    { "msrp_mlp_2", "tu154/custom/switchers/eng/msrp_mlp_2", globalPropertyi },
    { "msrp_main_switch", "tu154/custom/switchers/eng/msrp_main_switch", globalPropertyi },

    -- Exterior lights without deploying landing lights
    { "nav_lights_set", "tu154/custom/lights/nav_lights_set", globalPropertyi },
    { "strobe_set", "tu154/custom/lights/strobe_set", globalPropertyi },
    { "tail_light_set", "tu154/custom/lights/tail_light_set", globalPropertyi },
    { "wing_light_left_set", "tu154/custom/lights/wing_light_left_set", globalPropertyi },
    { "wing_light_right_set", "tu154/custom/lights/wing_light_right_set", globalPropertyi },
    { "landing_ext_set_L", "tu154/custom/lights/landing_ext_set_L", globalPropertyi },
    { "landing_ext_set_R", "tu154/custom/lights/landing_ext_set_R", globalPropertyi },
    { "landing_mode_set_L", "tu154/custom/lights/landing_mode_set_L", globalPropertyi },
    { "landing_mode_set_R", "tu154/custom/lights/landing_mode_set_R", globalPropertyi },

    -- Passenger signs
    { "sign_belts", "tu154/custom/switchers/ovhd/sign_belts", globalPropertyi },
    { "sign_nosmoke", "tu154/custom/switchers/ovhd/sign_nosmoke", globalPropertyi },
    { "sign_exit", "tu154/custom/switchers/ovhd/sign_exit", globalPropertyi },

    -- Legacy TCAS mode
    { "tcas_mode", "tu154/custom/switchers/tcas/tcas_mode", globalPropertyi },

    -- Ground equipment; preserve payload, fuel and hydraulic quantities
    { "gear_blocks", "tu154/custom/anim/gear_blocks", globalPropertyi },
    { "sensors_caps", "tu154/custom/anim/sensors_caps", globalPropertyi },
    { "engine_caps", "tu154/custom/anim/engine_caps", globalPropertyi },

    -- xTlua avionics: reproduce T154.zmisc aircraft_load() hot-start settings
    { "uns1_on", "tu154/custom/uns1_on", globalPropertyf },
    { "uns2_on", "tu154/custom/uns2_on", globalPropertyf },
    { "weather_sys", "tu154/custom/kontur/weather_sys", globalPropertyf },
    { "kontur_pow_l", "tu154/custom/kontur/left_power", globalPropertyf },
    { "kontur_pow_r", "tu154/custom/kontur/right_power", globalPropertyf },
    { "ubs_pow_l", "tu154/custom/ubs/left_power", globalPropertyf },
    { "ubs_pow_r", "tu154/custom/ubs/right_power", globalPropertyf },
    { "tcas2000_mode", "tu154/custom/tcas2000/mode", globalPropertyf },
    { "weather_mode", "tu154/custom/kontur/weather_mode", globalPropertyf },
    { "srpbz", "tu154/custom/kontur/srpbz", globalPropertyf },
    { "szt_1", "tu154/custom/switchers/eng/szt_1", globalPropertyf },
    { "szt_2", "tu154/custom/switchers/eng/szt_2", globalPropertyf },
    { "szt_3", "tu154/custom/switchers/eng/szt_3", globalPropertyf },
})

-- Row format: { property, cold value, engines-running value }.
-- Hot values reproduce the existing creator defaults and xTlua aircraft-load
-- settings. A nil cold value deliberately leaves the existing cold position alone.
local flight_presets = {
    -- Main electrical supplies and normal bus configuration
    { gen_1_on, 0, 1 },
    { gen_2_on, 0, 1 },
    { gen_3_on, 0, 1 },
    { bus27_vu1, 0, 1 },
    { bus27_vu2, 0, 1 },
    { bat1_on, 0, 1 },
    { bat2_on, 0, 1 },
    { bat3_on, 0, 1 },
    { bat4_on, 0, 1 },
    { gpu_on, 0, 0 },
    { apu_gen_on, 0, 0 },
    { emerg_inv115, 0, 0 },
    { emerg_inv115_cap, 0, 0 },
    { bus36_tr_left_to_right, 0, 0 },
    { bus36_tr_right_to_left, 0, 0 },
    { pts250_on, 0, 0 },
    { pts250_mode, 0, 0 },
    { pts250_on_cap, 0, 0 },
    { pts250_mode_cap, 0, 0 },
    { bus27_connect, 0, 0 },
    { bus27_connect_cap, 0, 0 },
    { emerg_gen_on_1, 0, 0 },
    { emerg_gen_on_2, 0, 0 },
    { emerg_gen_on_3, 0, 0 },
    { emerg_gen_on_1_cap, 0, 0 },
    { emerg_gen_on_2_cap, 0, 0 },
    { emerg_gen_on_3_cap, 0, 0 },

    -- Fuel pumps, automatic feed and fire shutoff valves
    { pump_tank2_left, 0, 1 },
    { pump_tank2_right, 0, 1 },
    { pump_tank3_left, 0, 1 },
    { pump_tank3_right, 0, 1 },
    { pump_tank4, 0, 1 },
    { pump_tank1_1, 0, 1 },
    { pump_tank1_2, 0, 1 },
    { pump_tank1_3, 0, 1 },
    { pump_tank1_4, 0, 1 },
    { fuel_level, 0, 1 },
    { fuel_flow_mode, 0, 1 },
    { fuel_flow_on, 0, 1 },
    { fuel_meter_on, 0, 1 },
    { fuel_meter_mech_on, 0, 1 },
    { fire_valve_1, 0, 1 },
    { fire_valve_2, 0, 1 },
    { fire_valve_3, 0, 1 },
    { fuel_trans, 0, 0 },
    { fuel_trans_cap, 0, 0 },
    { fuel_porc, 0, 0 },
    { fuel_porc_cap, 0, 0 },
    { fuel_flow_on_cap, 0, 0 },
    { fire_valve_1_cap, 0, 0 },
    { fire_valve_2_cap, 0, 0 },
    { fire_valve_3_cap, 0, 0 },

    -- Start-system fuel admission; native engine start remains X-Plane owned
    { fuel_in_1, 0, 1 },
    { fuel_in_2, 0, 1 },
    { fuel_in_3, 0, 1 },

    -- A held previous-flight button must not launch or stop a new APD sequence.
    { starter_cap, 0, 0 },
    { starter_switch, 0, 0 },
    { starter_eng_select, 0, 0 },
    { starter_mode, 0, 0 },
    { starter_start, 0, 0 },
    { starter_stop, 0, 0 },
    { flight_start_1, 0, 0 },
    { flight_start_2, 0, 0 },
    { flight_start_3, 0, 0 },

    -- Engine instrumentation and fire detection
    { gauges_on_1, 0, 1 },
    { gauges_on_2, 0, 1 },
    { gauges_on_3, 0, 1 },
    { fire_main_switch, 0, 1 },
    { gauges_on_1_cap, 1, 0 },
    { gauges_on_2_cap, 1, 0 },
    { gauges_on_3_cap, 1, 0 },
    { fire_buzzer, nil, 1 },
    { fire_buzzer_cap, nil, 0 },

    -- Flight-control boosters and ABSU preparation, without engaging the autopilot
    { buster_on_1, 0, 1 },
    { buster_on_2, 0, 1 },
    { buster_on_3, 0, 1 },
    { absu_needles_on, 0, 1 },
    { absu_nav_on, 0, 1 },
    { absu_speed_prepare, 0, 1 },
    { absu_roll_ch_on, 0, 1 },
    { absu_pitch_ch_on, 0, 1 },
    { nvu_power_on, 0, 1 },
    { busters_cap, 1, 0 },
    { absu_speed_prepare_cap, nil, 0 },

    -- Autothrottle engine disconnect buttons
    { absu_throt_off_1, 1, 0 },
    { absu_throt_off_2, 1, 0 },
    { absu_throt_off_3, 1, 0 },

    -- Nosewheel control guards
    { nosewheel_turn_enable, nil, 1 },
    { nosewheel_turn_sel, 1, 0 },
    { nosewheel_turn_cap, 1, 0 },

    -- Bleed air and automatic cabin-temperature regulation
    { cockpit_mode_set, 0, 1 },
    { cabin1_mode_set, 0, 1 },
    { cabin2_mode_set, 0, 1 },
    { left_sys_mode_set, 0, 1 },
    { right_sys_mode_set, 0, 1 },
    { psvp_left_on, 0, 1 },
    { psvp_right_on, 0, 1 },
    { eng_valve_1, 0, 1 },
    { eng_valve_2, 0, 1 },
    { eng_valve_3, 0, 1 },
    { psvp_left_on_cap, nil, 0 },
    { psvp_right_on_cap, nil, 0 },

    -- Navigation and flight instruments
    { diss_on, 0, 1 },
    { diss_mode, 0, 1 },
    { nvu_calc_set, 0, 1 },
    { ark_1_mode, 0, 1 },
    { ark_2_mode, 0, 1 },
    { var_left, nil, 1 },
    { var_right, nil, 1 },
    { auasp_on, nil, 1 },
    { eup_on, nil, 1 },
    { agr_on, nil, 1 },
    { tks_on_1, nil, 1 },
    { tks_on_2, nil, 1 },
    { svs_on, nil, 1 },
    { svs_heat, nil, 1 },
    { kln_on, nil, 1 },
    { tcas_on, nil, 1 },
    { vbe_1_on, nil, 1 },
    { vbe_2_on, nil, 1 },
    { curs_np_on_1, nil, 1 },
    { curs_np_on_2, nil, 1 },
    { tra_67_on, nil, 1 },
    { rsbn_on, nil, 1 },
    { rv5_1_on, nil, 1 },
    { rv5_2_on, nil, 1 },
    { vhf_1_on, nil, 1 },
    { vhf_2_on, nil, 1 },
    { uvid_on, nil, 1 },
    { mars_on, nil, 1 },

    -- Guarded overhead power switches
    { bkk_contr_cap, 1, 0 },
    { bkk_on_cap, 1, 0 },
    { sau_stu_cap, 1, 0 },
    { pkp_left_cap, 1, 0 },
    { pkp_right_cap, 1, 0 },
    { mgv_contr_cap, 1, 0 },
    { bkk_contr, nil, 0 },
    { bkk_on, nil, 1 },
    { sau_stu_on, nil, 1 },
    { pkp_left_on, nil, 1 },
    { pkp_right_on, nil, 1 },
    { mgv_contr, nil, 1 },

    -- Window/probe heat and ice detection; wing/engine anti-ice remain off
    { window_heat_1, 0, -1 },
    { window_heat_2, 0, -1 },
    { window_heat_3, 0, -1 },
    { pitot_heat_1, 0, 1 },
    { pitot_heat_2, 0, 1 },
    { pitot_heat_3, 0, 1 },

    -- Icing detector and demand-only anti-ice switches
    { soi21_on, 0, 1 },
    { antiice_slats, 0, 0 },
    { antiice_eng_1, 0, 0 },
    { antiice_eng_2, 0, 0 },
    { antiice_eng_3, 0, 0 },
    { antiice_wing, 0, 0 },

    -- Flight recorder
    { msrp_mlp_1, 0, 1 },
    { msrp_mlp_2, 0, 1 },
    { msrp_main_switch, 0, 1 },

    -- Exterior lights without deploying landing lights
    { nav_lights_set, 0, 1 },
    { strobe_set, 0, 1 },
    { tail_light_set, 0, 1 },
    { wing_light_left_set, 0, 0 },
    { wing_light_right_set, 0, 0 },
    { landing_ext_set_L, 0, 0 },
    { landing_ext_set_R, 0, 0 },
    { landing_mode_set_L, 0, 0 },
    { landing_mode_set_R, 0, 0 },

    -- Passenger signs
    { sign_belts, 0, 1 },
    { sign_nosmoke, 0, 1 },
    { sign_exit, 0, 0 },

    -- Legacy TCAS mode
    { tcas_mode, 0, 4 },

    -- Ground equipment; preserve payload, fuel and hydraulic quantities
    { gear_blocks, 1, 0 },
    { sensors_caps, 1, 0 },
    { engine_caps, 1, 0 },

    -- xTlua avionics: reproduce T154.zmisc aircraft_load() hot-start settings
    { uns1_on, nil, 1 },
    { uns2_on, nil, 1 },
    { weather_sys, nil, 1 },
    { kontur_pow_l, nil, 1 },
    { kontur_pow_r, nil, 1 },
    { ubs_pow_l, nil, 1 },
    { ubs_pow_r, nil, 1 },
    { tcas2000_mode, nil, 4 },
    { weather_mode, nil, 1 },
    { srpbz, nil, 1 },
    { szt_1, nil, 1 },
    { szt_2, nil, 1 },
    { szt_3, nil, 1 },
}

local initialization_pending = true
local pending_hot_start = nil

-- SASL documents this as the USER aircraft's new-airport/new-flight callback.
-- flightIndex is not documented as an AI aircraft index, so do not filter it.
function onAirportLoaded(flightIndex)
    pending_hot_start = get(startup_running) ~= 0
    initialization_pending = true
end

function update()
    if not initialization_pending then
        return
    end

    -- Consume the request even on a SmartCopilot slave. Acquiring control later
    -- must never reapply a preset over the pilots' current switch positions.
    initialization_pending = false
    local hot_start = pending_hot_start
    pending_hot_start = nil
    if get(ismaster) == 1 then
        return
    end

    if hot_start == nil then
        hot_start = get(startup_running) ~= 0
    end

    for _, preset in ipairs(flight_presets) do
        local value = preset[2]
        if hot_start then
            value = preset[3]
        end
        if value ~= nil then
            set(preset[1], value)
        end
    end

    -- Do not poll the preference again or hold switches in a forced state.
    print("[Aircraft initialization] " ..
        (hot_start and "Engines-running controls applied" or "Cold-and-dark controls applied"))
end
