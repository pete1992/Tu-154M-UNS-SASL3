-- T154.kontur.lua
-- X-Plane 12 Kontur mode selection, GPS1 and radar compatibility update.
--[[
Changelog
- Migrated WX display enable control from the legacy sim/cockpit/switches DataRef
  to the pilot/copilot sim/cockpit2/EFIS weather controls used by X-Plane 12.
- Migrated WX overlay alpha to cockpit2 pilot/copilot controls.
- Added X-Plane 12.3 weather radar mode and gain controls.
- WX ON/OFF is now controlled separately for the left and right Kontur displays,
  following the X-Plane 12 approach already used by the CE variant.
- WX level remains a shared radar control and is applied to both X-Plane displays.
- NAV and WX can be combined on each screen; their keys toggle each layer independently.
- TCAS can be overlaid on NAV or NAV/WX without hiding the selected route.
- The WX2000 TILT knob controls the native radar angle on both displays.
- TEST, WX, WX/TURB and MAP select the corresponding native radar modes.
- WINDSHEAR AUTO enables native predictive detection while the radar is powered and ready.
- TCAS, TAWS and native EFIS controls remain independent between screens.
- NAV displays GPS1 without changing the independent HSI/ABSU source selection.
- WX re-selection and power cycles restore scanning after a display standby selection.
- Shared radar level selection preserves both physical RRU knob positions.
- Radar availability, power recovery and screen readiness have one state owner.
- Existing custom paths remain; additional display/source status paths feed the panel.
- DataRefs use declarative binding tables with unchanged global names and notifier handlers.
--]]

-- Writable cockpit DataRefs need notifier functions, even when no side effect is required.
function tu154_kontur_weather_mode_DRhandler() end
function tu154_kontur_weather_sys_DRhandler() end
function tu154_wx2000_tilt_DRhandler() end
function tu154_wx2000_windshear_DRhandler() end



-- Preserve the project's global writable-DataRef helper and handle.
function deferred_dataref(name, type, notifier)
    print("Deffered dataref: " .. name)
    dref = XLuaCreateDataRef(name, type, "yes", notifier)
    return wrap_dref_any(dref, type)
end


-- Format GPS coordinates for the existing Kontur text fields; retain their layout.
-- These formatter names remain global for the shared xTlua environment.
function decToDms_lat(dec_lat)
	local abs_dec_lat = math.abs(dec_lat)
	local degrees_lat = math.floor(abs_dec_lat)
	local mins_lat = math.floor((abs_dec_lat - degrees_lat) * 60)
	local secs_lat = (((abs_dec_lat - degrees_lat) * 60) - mins_lat) * 60
	local secs_round_lat = math.floor(secs_lat + 0.5)
	local ns = "S"
	if dec_lat > 0 then ns = "N" end
	return ns .. " "..degrees_lat ..",".. mins_lat ..".".. secs_round_lat
end

function decToDms_long(dec_long)
	local abs_dec_long = math.abs(dec_long)
	local degrees_long = math.floor(abs_dec_long)
	local mins_long = math.floor((abs_dec_long - degrees_long) * 60)
	local secs_long = (((abs_dec_long - degrees_long) * 60) - mins_long) * 60
	local secs_round_long = math.floor(secs_long + 0.5)
	local ew = "W"
    local dlz = ""
	if dec_long > 0 then ew = "E" end
    if degrees_long < 100 then dlz = "0" end
	return ew .. dlz .. degrees_long ..",".. mins_long ..".".. secs_round_long
end

-- Bind simulator and aircraft inputs without changing their shared global names.
local find_datarefs = {
    -- Flight state and update timing.
    { "simDR_startuprunning", "sim/operation/prefs/startup_running" },
    { "simDR_gs", "sim/flightmodel/position/groundspeed" },
    { "simDR_gps_dme", "sim/cockpit2/radios/indicators/gps_dme_distance_nm" },
    { "simDR_passed", "sim/operation/misc/frame_rate_period" },
    { "simDR_time", "sim/time/total_running_time_sec" },
    -- Native pilot/copilot radar display controls.
    { "simDR_weather_alpha", "sim/cockpit2/EFIS/EFIS_weather_alpha" },
    { "simDR_weather_alpha_fo", "sim/cockpit2/EFIS/EFIS_weather_alpha_copilot" },
    { "simDR_weather_gain", "sim/cockpit2/EFIS/EFIS_weather_gain" },
    { "simDR_weather_gain_fo", "sim/cockpit2/EFIS/EFIS_weather_gain_copilot" },
    { "simDR_weather_mode_xp", "sim/cockpit2/EFIS/EFIS_weather_mode" },
    { "simDR_weather_mode_xp_fo", "sim/cockpit2/EFIS/EFIS_weather_mode_copilot" },
    -- Shared antenna scan, stabilization and predictive windshear.
    { "simDR_weather_sector_brg", "sim/cockpit2/EFIS/EFIS_weather_sector_brg" },
    { "simDR_weather_sector_width", "sim/cockpit2/EFIS/EFIS_weather_sector_width" },
    { "simDR_weather_antenna_limit", "sim/cockpit2/EFIS/EFIS_weather_antenna_limit" },
    { "simDR_weather_sweeps_per_sec", "sim/cockpit2/EFIS/EFIS_weather_sweeps_per_sec" },
    { "simDR_weather_stab", "sim/cockpit2/EFIS/EFIS_weather_stab" },
    { "simDR_weather_stab_fo", "sim/cockpit2/EFIS/EFIS_weather_stab_copilot" },
    { "simDR_weather_gcs", "sim/cockpit2/EFIS/EFIS_weather_gcs" },
    { "simDR_weather_gcs_fo", "sim/cockpit2/EFIS/EFIS_weather_gcs_copilot" },
    { "simDR_weather_pws", "sim/cockpit2/EFIS/EFIS_weather_pws" },
    { "simDR_weather_auto_tilt", "sim/cockpit2/EFIS/EFIS_weather_auto_tilt" },
    { "simDR_weather_auto_tilt_fo", "sim/cockpit2/EFIS/EFIS_weather_auto_tilt_copilot" },
    { "simDR_weather_tilt", "sim/cockpit2/EFIS/EFIS_weather_tilt" },
    { "simDR_weather_tilt_fo", "sim/cockpit2/EFIS/EFIS_weather_tilt_copilot" },
    { "simDR_weather_multiscan", "sim/cockpit2/EFIS/EFIS_weather_multiscan" },
    { "simDR_weather_multiscan_fo", "sim/cockpit2/EFIS/EFIS_weather_multiscan_copilot" },
    { "simDR_weather_vertical", "sim/cockpit2/EFIS/EFIS_weather_vertical" },
    { "simDR_weather_vertical_fo", "sim/cockpit2/EFIS/EFIS_weather_vertical_copilot" },
    { "simDR_efis_1_terrain", "sim/cockpit2/EFIS/EFIS_terrain_on" },
    { "simDR_efis_2_terrain", "sim/cockpit2/EFIS/EFIS_terrain_on_copilot" },
    -- Aircraft power, TAWS/TCAS sources and switch-sound signals.
    { "simDR_bus27left", "tu154/custom/elec/bus27_volt_left" },
    { "simDR_bus27right", "tu154/custom/elec/bus27_volt_right" },
    { "simDR_taws_dist", "tu154/custom/taws/distance_set" },
    { "simDR_taws_mode", "tu154/custom/taws/mode_set" },
    { "simDR_tcas_mode", "tu154/custom/tcas/mode_set" },
    { "simDR_tcas_disp_mod", "tu154/custom/tcas/screen_mode" },
    { "simDR_but_sound", "tu154/custom/buttons/srpbz/but_down" },
    { "simDR_sw_sound", "tu154/custom/switchers/console/nvu_corr_on" },
    { "simDR_tcas_on", "sim/cockpit2/EFIS/EFIS_tcas_on" },
    { "simDR_taws_but_mode", "tu154/custom/buttons/srpbz/but_view" },
    { "simDR_vbe1", "tu154/custom/switchers/ovhd/vbe_1_on" },
    { "simDR_vbe2", "tu154/custom/switchers/ovhd/vbe_2_on" },
    -- Navigation timing, coordinates and instrument brightness.
    { "simDR_gps_min", "sim/cockpit2/radios/indicators/gps_dme_time_min" },
    { "simDR_lat", "sim/flightmodel/position/latitude" },
    { "simDR_long", "sim/flightmodel/position/longitude" },
    { "simDR_srpbz_brightness", "tu154/custom/rotary/srpbz/brightness" },
    { "simDR_kontur_1_brt", "sim/cockpit2/switches/instrument_brightness_ratio[14]" },
    { "simDR_kontur_2_brt", "sim/cockpit2/switches/instrument_brightness_ratio[15]" },
    -- Navigation receiver and native map layers.
    { "simDR_kln", "tu154/custom/switchers/ovhd/kln_on" },
    { "simDR_rls", "tu154/custom/switchers/console/rls_mode" },
    { "simDR_efis_1_mode", "sim/cockpit/switches/EFIS_map_submode" },
    { "simDR_efis_1_range", "sim/cockpit/switches/EFIS_map_range_selector" },
    { "simDR_efis_1_fix", "sim/cockpit2/EFIS/EFIS_fix_on" },
    { "simDR_efis_1_wxr", "sim/cockpit2/EFIS/EFIS_weather_on" },
    { "simDR_efis_2_wxr", "sim/cockpit2/EFIS/EFIS_weather_on_copilot" },
    { "simDR_efis_1_ndb", "sim/cockpit2/EFIS/EFIS_ndb_on" },
    { "simDR_efis_1_vor", "sim/cockpit2/EFIS/EFIS_vor_on" },
    { "simDR_efis_1_apt", "sim/cockpit2/EFIS/EFIS_airport_on" },
    { "simDR_efis_1_tcas", "sim/cockpit2/EFIS/EFIS_tcas_on" },
    { "simDR_fms_line", "sim/graphics/misc/kill_map_fms_line" },
    -- Radar supply, stabilization status and radio deviation inputs.
    { "simDR_36v", "tu154/custom/elec/bus36_volt_left" },
    { "simDR_rv2", "tu154/custom/elec/rv5_right_cc" },
    { "simDRutchours", "sim/cockpit2/clock_timer/zulu_time_hours" },
    { "simDRutcmins", "sim/cockpit2/clock_timer/zulu_time_minutes" },
    { "simDRnostab_l", "tu154/custom/gauges/ahz/ahz_flag_L" },
    { "simDRnostab_r", "tu154/custom/gauges/ahz/ahz_flag_R" },
    { "simDRtcasmode", "tu154/custom/tcas/screen_mode" },
    { "simDRcrs_plank1", "tu154/custom/radio/nav1_cs" },
    { "simDRgs_plank1", "tu154/custom/radio/nav1_gs" },
    { "simDRcrs_flag1", "tu154/custom/radio/nav1_cs_flag" },
    { "simDRgs_flag1", "tu154/custom/radio/nav1_gs_flag" },
    { "simDRcrs_plank2", "tu154/custom/radio/nav2_cs" },
    { "simDRgs_plank2", "tu154/custom/radio/nav2_gs" },
    { "simDRcrs_flag2", "tu154/custom/radio/nav2_cs_flag" },
    { "simDRgs_flag2", "tu154/custom/radio/nav2_gs_flag" },
    -- Heading, course and cross-track source values.
    { "simDR_gmk_crs", "tu154/custom/tks/course_gmk" },
    { "simDR_diss_slipe", "tu154/custom/nvu/diss_slip_angle" },
    { "simDR_dtk", "sim/cockpit/radios/gps_course_degtm" },
    { "simDR_rel_bear", "sim/cockpit2/radios/indicators/gps_relative_bearing_deg" },
    { "simDR_bear", "sim/cockpit2/radios/indicators/gps_bearing_deg_mag" },
    { "simDR_hdg", "sim/cockpit2/gauges/indicators/heading_electric_deg_mag_pilot" },
    -- Radio altitude and vertical-speed source values.
    { "simDR_radioalt", "sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot" },
    { "simDR_vvi", "tu154/custom/gauges/vvi_left" },
    { "simDR_vvi_rv", "sim/cockpit2/gauges/indicators/vvi_fpm_pilot" },
    -- GPS validity and copilot map controls.
    { "simDR_gps_power", "sim/cockpit2/radios/actuators/gps_power" },
    { "simDR_gps_fromto", "sim/cockpit/radios/gps_fromto" },
    { "simDR_efis_2_mode", "sim/cockpit2/EFIS/map_mode_copilot" },
    { "simDR_efis_2_range", "sim/cockpit2/EFIS/map_range_copilot" },
    { "simDR_efis_1_hsi", "sim/cockpit2/EFIS/map_mode_is_HSI" },
    { "simDR_efis_2_hsi", "sim/cockpit2/EFIS/map_mode_is_HSI_copilot" },
    { "simDR_efis_2_fix", "sim/cockpit2/EFIS/EFIS_fix_on_copilot" },
    { "simDR_efis_2_ndb", "sim/cockpit2/EFIS/EFIS_ndb_on_copilot" },
    { "simDR_efis_2_vor", "sim/cockpit2/EFIS/EFIS_vor_on_copilot" },
    { "simDR_efis_2_apt", "sim/cockpit2/EFIS/EFIS_airport_on_copilot" },
    { "simDR_efis_2_tcas", "sim/cockpit2/EFIS/EFIS_tcas_on_copilot" },
}

-- Register writable outputs after the inputs are bound. Notifier functions must
-- already exist when this table is constructed; omitted handlers stay omitted.
local deferred_datarefs = {
    -- Display brightness and computed navigation/flight indications.
    { "kntr_1_brt_sw", "tu154/custom/kontur/kntr_1_brt_sw", "number" },
    { "kntr_2_brt_sw", "tu154/custom/kontur/kntr_2_brt_sw", "number" },
    { "z_bok", "tu154/custom/kontur/zbok", "number" },
    { "z_bok_nm", "tu154/custom/kontur/zbok_nm", "number" },
    { "radioalt", "tu154/custom/kontur/radioalt", "number" },
    { "vvi", "tu154/custom/kontur/vvi", "number" },
    { "vvi_rv", "tu154/custom/kontur/vvi_rv", "number" },
    { "gs_kmh", "tu154/custom/kontur/gs_kmh", "number" },
    { "gs_kts", "tu154/custom/kontur/gs_kts", "number" },
    { "gps_dme_km", "tu154/custom/kontur/gps_dme_km", "number" },
    { "gps_hours", "tu154/custom/kontur/gps_dme_hours", "number" },
    { "gps_min", "tu154/custom/kontur/gps_dme_min", "number" },
    { "gps_min_eta", "tu154/custom/kontur/gps_dme_min_eta", "number" },
    { "gps_hours_eta", "tu154/custom/kontur/gps_dme_hours_eta", "number" },
    { "gps_time_mode_l", "tu154/custom/kontur/left_gps_time_mod", "number" },
    { "gps_time_mode_r", "tu154/custom/kontur/right_gps_time_mod", "number" },
    -- Left/right panel power, menus and published display states.
    { "kontur_on_l", "tu154/custom/kontur/left_on", "number" },
    { "kontur_nav_menu_l", "tu154/custom/kontur/left_nav_menu", "number" },
    { "info_page_l", "tu154/custom/kontur/left_info_page", "number" },
    { "info_page_r", "tu154/custom/kontur/right_info_page", "number" },
    { "kontur_pow_l_lit", "tu154/custom/kontur/light/left_power", "number" },
    { "kontur_pow_r_lit", "tu154/custom/kontur/light/right_power", "number" },
    { "kontur_on_r", "tu154/custom/kontur/right_on", "number" },
    -- Shared radar power and operating mode; handlers are defined above.
    { "weather_lit", "tu154/custom/kontur/weather_lit", "number" },
    { "weather_sys", "tu154/custom/kontur/weather_sys", "number", tu154_kontur_weather_sys_DRhandler },
    -- Physical detents: 0 TEST, 1 WX, 2 WX/TURB, 3 MAP.
    { "weather_mode", "tu154/custom/kontur/weather_mode", "number", tu154_kontur_weather_mode_DRhandler },
    -- Selected layers and self-test state for the left screen.
    { "kontur_nav_l", "tu154/custom/kontur/left_nav", "number" },
    { "kontur_wx_l", "tu154/custom/kontur/left_wx", "number" },
    { "kontur_tcas_l", "tu154/custom/kontur/left_tcas", "number" },
    { "kontur_wx_test_l", "tu154/custom/kontur/left_wx_test", "number" },
    { "kontur_taws_l", "tu154/custom/kontur/left_taws", "number" },
    { "kontur_pow_l", "tu154/custom/kontur/left_power", "number" },
    { "kontur_onoff_l", "tu154/custom/kontur/left_onoff", "number" },
    { "kontur_test_l", "tu154/custom/kontur/left_test", "number" },
    -- Selected layers and self-test state for the right screen.
    { "kontur_nav_menu_r", "tu154/custom/kontur/right_nav_menu", "number" },
    { "kontur_nav_r", "tu154/custom/kontur/right_nav", "number" },
    { "kontur_taws_r", "tu154/custom/kontur/right_taws", "number" },
    { "kontur_wx_r", "tu154/custom/kontur/right_wx", "number" },
    { "kontur_pow_r", "tu154/custom/kontur/right_power", "number" },
    { "kontur_onoff_r", "tu154/custom/kontur/right_onoff", "number" },
    { "kontur_test_r", "tu154/custom/kontur/right_test", "number" },
    -- Stabilization availability and displayed radio deviations.
    { "ubs_pow_l", "tu154/custom/ubs/left_power", "number" },
    { "ubs_pow_r", "tu154/custom/ubs/right_power", "number" },
    { "diff_gs", "tu154/custom/kontur/gs_diff", "number" },
    { "diff_crs", "tu154/custom/kontur/crs_diff", "number" },
    { "gs_fl", "tu154/custom/kontur/gs_fl", "number" },
    { "crs_fl", "tu154/custom/kontur/crs_fl", "number" },
    -- Shared physical radar controls.
    { "wx2000_gain", "tu154/custom/wx2000_gain", "number" },
    -- Tilt in degrees: -15 DN, 0 level, +15 UP.
    { "wx2000_tilt", "tu154/custom/wx2000_tilt", "number", tu154_wx2000_tilt_DRhandler },
    -- Predictive windshear switch: 0 OFF, 1 AUTO.
    { "wx2000_windshear", "tu154/custom/wx2000_windshear", "number", tu154_wx2000_windshear_DRhandler },
    -- Panel gain knobs and navigation-unit power indications.
    { "kontur_rru_l", "tu154/custom/kontur/rru_l", "number" },
    { "kontur_rru_r", "tu154/custom/kontur/rru_r", "number" },
    { "uns1_on", "tu154/custom/uns1_on", "number" },
    { "uns2_on", "tu154/custom/uns2_on", "number" },
    { "gmk_crs", "tu154/custom/kontur/course_gmk", "number" },
    { "fpu_crs", "tu154/custom/kontur/course_fpu", "number" },
    -- Left panel button lighting, units and INFO knob positions.
    { "kontur_button_lit_l", "tu154/custom/kontur/button_lights_l", "number" },
    { "kontur_dist_mode_l", "tu154/custom/kontur/dist_mode_l", "number" },
    { "kontur_info_knob1_l", "tu154/custom/kontur/info_knob1_l", "number" },
    { "kontur_info_knob2_l", "tu154/custom/kontur/info_knob2_l", "number" },
    -- Right panel button lighting, units and INFO knob positions.
    { "kontur_button_lit_r", "tu154/custom/kontur/button_lights_r", "number" },
    { "kontur_dist_mode_r", "tu154/custom/kontur/dist_mode_r", "number" },
    { "kontur_info_knob1_r", "tu154/custom/kontur/info_knob1_r", "number" },
    { "kontur_info_knob2_r", "tu154/custom/kontur/info_knob2_r", "number" },
    -- Cross-track result and string DataRefs for coordinate text.
    { "kontur_zbok_test", "tu154/custom/kontur/zbok_test", "number" },
    { "lat_string", "tu154/custom/kontur/latitude", "string" },
    { "long_string", "tu154/custom/kontur/longitude", "string" },
    -- Screen mode: 0 blank, 1 TAWS, 2 TCAS, 3 NAV, 4 WX, 5 NAV+WX.
    { "kontur_mode_l", "tu154/custom/kontur/left_mode", "number" },
    { "kontur_mode_r", "tu154/custom/kontur/right_mode", "number" },
    { "kontur_map_l", "tu154/custom/kontur/left_map_on", "number" },
    { "kontur_map_r", "tu154/custom/kontur/right_map_on", "number" },
    { "kontur_tcas_r", "tu154/custom/kontur/right_tcas", "number" },
    { "nav_source_on", "tu154/custom/kontur/nav_source_on", "number" },
    { "nav_source_valid", "tu154/custom/kontur/nav_source_valid", "number" },
    { "weather_ready", "tu154/custom/kontur/weather_ready", "number" },
}

-- xTlua shares a global environment. Only the definitions/helpers are local;
-- the actual DataRef variables remain available to all existing consumers.
local function bind_datarefs(definitions)
    for _, def in ipairs(definitions) do
        _G[def[1]] = find_dataref(def[2])
    end
end

local function create_datarefs(definitions)
    for _, def in ipairs(definitions) do
        if def[4] ~= nil then
            _G[def[1]] = deferred_dataref(def[2], def[3], def[4])
        else
            _G[def[1]] = deferred_dataref(def[2], def[3])
        end
    end
end

bind_datarefs(find_datarefs)
create_datarefs(deferred_datarefs)

-- Private runtime state: sampled inputs, self-test timers and per-screen selections.
-- Physical knob DataRefs remain independent from the shared radar settings below.
local radioalt_loc = 0
local info_knob1_l_loc = kontur_info_knob1_l
local info_knob2_l_loc = 0
local info_knob1_r_loc = kontur_info_knob1_r
local info_knob2_r_loc = 0
local kontur_test_timer_l = 0
local kontur_test_start_l = 1
local kontur_test_timer_r = 0
local kontur_test_start_r = 1
local kontur_eta = 0
local weather_test_timer = 0
local wx_display_l = 3
local wx_display_r = 3
local tcas_display_l = 1
local tcas_display_r = 1
local tcas_overlay_l = false
local tcas_overlay_r = false
local aircraft_loaded = 0
local btn_onoff_l = 0
local btn_onoff_r = 0
local btn_tcas = 0
local btn_sound = 0
local start_vvi_check = 1
local start_vvi = 0
local radioalt_check = 0
local change_gps_time = 0
local sw_sound = 0
local nostab_l = 0
local nostab_r = 0
local relative_brg = 0
local true_brg = 0
-- Start every gain control at the actual shared level so each can turn down immediately.
wx2000_gain = 0.8
wx2000_tilt = 0
wx2000_windshear = 0
kontur_rru_l = 0.8
kontur_rru_r = 0.8
-- Remember the shared level separately from the three physical knob positions.
local wx_level_requested = kontur_rru_l
local rru_l_previous = kontur_rru_l
local rru_r_previous = kontur_rru_r
local wx2000_gain_previous = wx2000_gain
-- The mechanical WX mode selector defaults to WX independently of electrical power.
-- weather_sys remains the actual power switch and therefore still starts off cold and dark.
weather_mode = 1
kntr_1_brt_sw = 0.7
kntr_2_brt_sw = 0.7
simDR_kontur_1_brt = 0.6
simDR_kontur_2_brt = 0.6


-- Reject invalid frame/GPS values without retaining stale displayed information.
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

-- Limit timer advancement after long frames; invalid or negative periods do not advance it.
local function frame_step()
    if not finite(simDR_passed) or simDR_passed < 0 then return 0 end
    return math.min(simDR_passed, 0.1)
end

-- NAV and WX are independently selectable layers on the same screen.
-- Returning from INFO preserves an already selected layer instead of switching it off.
local function mode_after_key(current, requested, info_open)
    if requested == 3 then
        if info_open and (current == 3 or current == 5) then return current end
        if current == 3 then return 0 end
        if current == 4 then return 5 end
        if current == 5 then return 4 end
    elseif requested == 4 then
        if info_open and (current == 4 or current == 5) then return current end
        if current == 3 then return 5 end
        if current == 4 then return 0 end
        if current == 5 then return 3 end
    elseif current == requested and not info_open then
        return 0
    end
    return requested
end

-- Left display: clear published layers separately from the selected operating mode.
local function clear_modes_l()
    kontur_nav_l = 0
    kontur_taws_l = 0
    kontur_tcas_l = 0
    kontur_wx_l = 0
    kontur_map_l = 0
end

-- Power loss or an ON/OFF command restarts this screen's self-test and clears its menus.
local function reset_display_l()
    wx_display_l = 3
    tcas_overlay_l = false
    kontur_on_l = 0
    kontur_mode_l = 0
    kontur_test_l = 0
    kontur_test_timer_l = 0
    kontur_test_start_l = 1
    kontur_nav_menu_l = 0
    info_page_l = 0
    clear_modes_l()
end

-- The first mode key after the self-test both acknowledges it and selects that mode.
local function accept_key_l()
    if kontur_pow_l <= 0 or simDR_bus27left <= 13 or kontur_onoff_l >= 1 then return false end
    if kontur_test_start_l > 0 then
        if kontur_test_timer_l < 17 then return false end
        kontur_test_start_l = 0
        kontur_test_timer_l = 0
        kontur_test_l = 0
        kontur_on_l = 1
    end
    return kontur_on_l > 0
end

local function select_mode_l(mode)
    if not accept_key_l() then return end
    local requested = mode
    local previous = kontur_mode_l
    if requested == 2 and (previous == 3 or previous == 5) then
        -- TCAS toggles traffic over the selected NAV/WX layers; INFO only restores them.
        tcas_overlay_l = info_page_l > 0 or not tcas_overlay_l
        mode = previous
    else
        mode = mode_after_key(previous, requested, info_page_l > 0)
        if mode ~= 3 and mode ~= 5 then tcas_overlay_l = false end
    end
    if requested == 4 and (mode == 4 or mode == 5) and previous ~= 4 and previous ~= 5 then
        -- Re-selecting WX restores scanning after the WX softkey selected standby.
        wx_display_l = 3
    end
    kontur_mode_l = mode
    kontur_nav_menu_l = 0
    info_page_l = 0
    clear_modes_l()
    if requested == 3 and (mode == 3 or mode == 5) then
        -- Request the GPS1 receiver for display data only.
        -- HSI and autopilot sources belong to the independent NVU/VOR1/VOR2 controls.
        simDR_kln = 1
    end
end

-- Left cockpit commands act on initial press (phase 0), except the held INFO key.
function kontur_onoff_button_l_CMDhandler(phase, duration)
    if phase ~= 0 then return end
    if kontur_pow_l > 0 and simDR_bus27left > 13 then
        kontur_onoff_l = kontur_onoff_l < 1 and 1 or 0
    end
    reset_display_l()
end

function kontur_rls_button_l_CMDhandler(phase, duration)
    if phase == 0 then select_mode_l(4) end
end

function kontur_nav_button_l_CMDhandler(phase, duration)
    if phase == 0 then select_mode_l(3) end
end

function kontur_tcas_button_l_CMDhandler(phase, duration)
    if phase == 0 then select_mode_l(2) end
end

function kontur_taws_button_l_CMDhandler(phase, duration)
    if phase == 0 then select_mode_l(1) end
end

function kontur_zoomin_button_l_CMDhandler(phase, duration)
    if phase ~= 0 or not accept_key_l() then return end
    if info_page_l > 0 then
        info_page_l = 1
    else
        -- Both panels use the same TAWS texture and matching range annotation.
        simDR_efis_1_range = math.max(1, math.min(6, simDR_efis_1_range + (-1)))
    end
end

function kontur_zoomout_button_l_CMDhandler(phase, duration)
    if phase ~= 0 or not accept_key_l() then return end
    if info_page_l > 0 then
        info_page_l = 2
    else
        -- Both panels use the same TAWS texture and matching range annotation.
        simDR_efis_1_range = math.max(1, math.min(6, simDR_efis_1_range + (1)))
    end
end

-- Softkeys depend on the active page: units/time, TCAS format, TAWS view or WX standby.
function kontur_btn1_button_l_CMDhandler(phase, duration)
    if phase ~= 0 or not accept_key_l() then return end
    if kontur_nav_menu_l == 2 then kontur_dist_mode_l = kontur_dist_mode_l < 1 and 1 or 0 end
    if kontur_nav_menu_l == 3 then gps_time_mode_l = gps_time_mode_l < 1 and 1 or 0 end
end

function kontur_btn2_button_l_CMDhandler(phase, duration)
    if phase ~= 0 or not accept_key_l() then return end
    if info_page_l > 0 and ubs_pow_l > 0 then
        info_page_l = 3
    elseif kontur_mode_l == 2 and info_page_l < 1 then
        tcas_display_l = tcas_display_l == 1 and 2 or 1
    end
end

function kontur_btn3_button_l_CMDhandler(phase, duration)
    if phase ~= 0 or not accept_key_l() then return end
    if info_page_l > 0 then
        info_page_l = 0
    elseif kontur_mode_l == 1 then
        -- Both Kontur panels share the existing TAWS scan/texture.
        if simDR_taws_mode == 1 then simDR_taws_mode = 2
        elseif simDR_taws_mode == 2 then simDR_taws_mode = 1 end
    elseif kontur_mode_l == 4 or kontur_mode_l == 5 then
        wx_display_l = wx_display_l == 3 and 2 or 3
    end
end

-- Holding INFO opens the settings menu after 3 seconds and system information after 5.
function kontur_info_button_l_CMDhandler(phase, duration)
    if not accept_key_l() then return end
    if phase == 0 and kontur_nav_menu_l > 0 then kontur_nav_menu_l = 0 end
    if phase == 1 and duration > 5 then
        info_page_l = 1
        kontur_nav_menu_l = 0
    elseif phase == 1 and duration > 3 then
        kontur_nav_menu_l = 1
    end
end

function kontur_ovhd_onoff_l_CMDhandler(phase, duration)
    if phase ~= 0 then return end
    kontur_pow_l = kontur_pow_l > 0 and 0 or 1
    kontur_onoff_l = 1
    reset_display_l()
    simDR_sw_sound = simDR_sw_sound > -1 and -1 or 0
end

-- Right display keeps its own power, menus and selections; its self-test timing differs.
local function clear_modes_r()
    kontur_nav_r = 0
    kontur_taws_r = 0
    kontur_tcas_r = 0
    kontur_wx_r = 0
    kontur_map_r = 0
end

local function reset_display_r()
    wx_display_r = 3
    tcas_overlay_r = false
    kontur_on_r = 0
    kontur_mode_r = 0
    kontur_test_r = 0
    kontur_test_timer_r = 0
    kontur_test_start_r = 1
    kontur_nav_menu_r = 0
    info_page_r = 0
    clear_modes_r()
end

-- The first mode key after the self-test both acknowledges it and selects that mode.
local function accept_key_r()
    if kontur_pow_r <= 0 or simDR_bus27right <= 13 or kontur_onoff_r >= 1 then return false end
    if kontur_test_start_r > 0 then
        if kontur_test_timer_r < 19 then return false end
        kontur_test_start_r = 0
        kontur_test_timer_r = 0
        kontur_test_r = 0
        kontur_on_r = 1
    end
    return kontur_on_r > 0
end

local function select_mode_r(mode)
    if not accept_key_r() then return end
    local requested = mode
    local previous = kontur_mode_r
    if requested == 2 and (previous == 3 or previous == 5) then
        -- TCAS toggles traffic over the selected NAV/WX layers; INFO only restores them.
        tcas_overlay_r = info_page_r > 0 or not tcas_overlay_r
        mode = previous
    else
        mode = mode_after_key(previous, requested, info_page_r > 0)
        if mode ~= 3 and mode ~= 5 then tcas_overlay_r = false end
    end
    if requested == 4 and (mode == 4 or mode == 5) and previous ~= 4 and previous ~= 5 then
        -- Re-selecting WX restores scanning after the WX softkey selected standby.
        wx_display_r = 3
    end
    kontur_mode_r = mode
    kontur_nav_menu_r = 0
    info_page_r = 0
    clear_modes_r()
    if requested == 3 and (mode == 3 or mode == 5) then
        -- Request the GPS1 receiver for display data only.
        -- HSI and autopilot sources belong to the independent NVU/VOR1/VOR2 controls.
        simDR_kln = 1
    end
end

-- Right cockpit commands mirror the left controls without sharing their display state.
function kontur_onoff_button_r_CMDhandler(phase, duration)
    if phase ~= 0 then return end
    if kontur_pow_r > 0 and simDR_bus27right > 13 then
        kontur_onoff_r = kontur_onoff_r < 1 and 1 or 0
    end
    reset_display_r()
end

function kontur_rls_button_r_CMDhandler(phase, duration)
    if phase == 0 then select_mode_r(4) end
end

function kontur_nav_button_r_CMDhandler(phase, duration)
    if phase == 0 then select_mode_r(3) end
end

function kontur_tcas_button_r_CMDhandler(phase, duration)
    if phase == 0 then select_mode_r(2) end
end

function kontur_taws_button_r_CMDhandler(phase, duration)
    if phase == 0 then select_mode_r(1) end
end

function kontur_zoomin_button_r_CMDhandler(phase, duration)
    if phase ~= 0 or not accept_key_r() then return end
    if info_page_r > 0 then
        info_page_r = 1
    else
        -- Both panels use the same TAWS texture and matching range annotation.
        simDR_efis_1_range = math.max(1, math.min(6, simDR_efis_1_range + (-1)))
    end
end

function kontur_zoomout_button_r_CMDhandler(phase, duration)
    if phase ~= 0 or not accept_key_r() then return end
    if info_page_r > 0 then
        info_page_r = 2
    else
        -- Both panels use the same TAWS texture and matching range annotation.
        simDR_efis_1_range = math.max(1, math.min(6, simDR_efis_1_range + (1)))
    end
end

function kontur_btn1_button_r_CMDhandler(phase, duration)
    if phase ~= 0 or not accept_key_r() then return end
    if kontur_nav_menu_r == 2 then kontur_dist_mode_r = kontur_dist_mode_r < 1 and 1 or 0 end
    if kontur_nav_menu_r == 3 then gps_time_mode_r = gps_time_mode_r < 1 and 1 or 0 end
end

function kontur_btn2_button_r_CMDhandler(phase, duration)
    if phase ~= 0 or not accept_key_r() then return end
    if info_page_r > 0 and ubs_pow_r > 0 then
        info_page_r = 3
    elseif kontur_mode_r == 2 and info_page_r < 1 then
        tcas_display_r = tcas_display_r == 1 and 2 or 1
    end
end

function kontur_btn3_button_r_CMDhandler(phase, duration)
    if phase ~= 0 or not accept_key_r() then return end
    if info_page_r > 0 then
        info_page_r = 0
    elseif kontur_mode_r == 1 then
        -- Both Kontur panels share the existing TAWS scan/texture.
        if simDR_taws_mode == 1 then simDR_taws_mode = 2
        elseif simDR_taws_mode == 2 then simDR_taws_mode = 1 end
    elseif kontur_mode_r == 4 or kontur_mode_r == 5 then
        wx_display_r = wx_display_r == 3 and 2 or 3
    end
end

function kontur_info_button_r_CMDhandler(phase, duration)
    if not accept_key_r() then return end
    if phase == 0 and kontur_nav_menu_r > 0 then kontur_nav_menu_r = 0 end
    if phase == 1 and duration > 5 then
        info_page_r = 1
        kontur_nav_menu_r = 0
    elseif phase == 1 and duration > 3 then
        kontur_nav_menu_r = 1
    end
end

function kontur_ovhd_onoff_r_CMDhandler(phase, duration)
    if phase ~= 0 then return end
    kontur_pow_r = kontur_pow_r > 0 and 0 or 1
    kontur_onoff_r = 1
    reset_display_r()
    simDR_sw_sound = simDR_sw_sound > -1 and -1 or 0
end

-- Keep cockpit command paths and global handles stable for OBJ manipulators and bindings.
KONTUR_ONOFF_btn_l	= create_command("kontur/onoff_btn_l", "Kontur L ONOFF Button", kontur_onoff_button_l_CMDhandler)
KONTUR_RLS_btn_l	= create_command("kontur/rls_btn_l", "Kontur L RLS Button", kontur_rls_button_l_CMDhandler)
KONTUR_NAV_btn_l	= create_command("kontur/nav_btn_l", "Kontur L NAV Button", kontur_nav_button_l_CMDhandler)
KONTUR_TCAS_btn_l	= create_command("kontur/tcas_btn_l", "Kontur L TCAS Button", kontur_tcas_button_l_CMDhandler)
KONTUR_TAWS_btn_l	= create_command("kontur/taws_btn_l", "Kontur L TAWS Button", kontur_taws_button_l_CMDhandler)
KONTUR_ZOOMIN_btn_l	= create_command("kontur/zoomin_btn_l", "Kontur L Zoom In Button", kontur_zoomin_button_l_CMDhandler)
KONTUR_ZOOMOUT_btn_l	= create_command("kontur/zoomout_btn_l", "Kontur L Zoom Out Button", kontur_zoomout_button_l_CMDhandler)
KONTUR_BTN1_btn_l	= create_command("kontur/btn1_btn_l", "Kontur L BTN1 Button", kontur_btn1_button_l_CMDhandler)
KONTUR_BTN2_btn_l	= create_command("kontur/btn2_btn_l", "Kontur L BTN2 Button", kontur_btn2_button_l_CMDhandler)
KONTUR_BTN3_btn_l	= create_command("kontur/btn3_btn_l", "Kontur L BTN3 Button", kontur_btn3_button_l_CMDhandler)
KONTUR_INFO_btn_l	= create_command("kontur/info_btn_l", "Kontur L INFO Button", kontur_info_button_l_CMDhandler)
KONTUR_ONOFF_btn_r	= create_command("kontur/onoff_btn_r", "Kontur R ONOFF Button", kontur_onoff_button_r_CMDhandler)
KONTUR_RLS_btn_r	= create_command("kontur/rls_btn_r", "Kontur R RLS Button", kontur_rls_button_r_CMDhandler)
KONTUR_NAV_btn_r	= create_command("kontur/nav_btn_r", "Kontur R NAV Button", kontur_nav_button_r_CMDhandler)
KONTUR_TCAS_btn_r	= create_command("kontur/tcas_btn_r", "Kontur R TCAS Button", kontur_tcas_button_r_CMDhandler)
KONTUR_TAWS_btn_r	= create_command("kontur/taws_btn_r", "Kontur R TAWS Button", kontur_taws_button_r_CMDhandler)
KONTUR_ZOOMIN_btn_r	= create_command("kontur/zoomin_btn_r", "Kontur R Zoom In Button", kontur_zoomin_button_r_CMDhandler)
KONTUR_ZOOMOUT_btn_r	= create_command("kontur/zoomout_btn_r", "Kontur R Zoom Out Button", kontur_zoomout_button_r_CMDhandler)
KONTUR_BTN1_btn_r	= create_command("kontur/btn1_btn_r", "Kontur R BTN1 Button", kontur_btn1_button_r_CMDhandler)
KONTUR_BTN2_btn_r	= create_command("kontur/btn2_btn_r", "Kontur R BTN2 Button", kontur_btn2_button_r_CMDhandler)
KONTUR_BTN3_btn_r	= create_command("kontur/btn3_btn_r", "Kontur R BTN3 Button", kontur_btn3_button_r_CMDhandler)
KONTUR_INFO_btn_r	= create_command("kontur/info_btn_r", "Kontur R INFO Button", kontur_info_button_r_CMDhandler)
KONTUR_L_ON_func	= create_command("kontur/ovhd_onoff_l", "Kontur L OVHD ONOFF", kontur_ovhd_onoff_l_CMDhandler)
KONTUR_R_ON_func	= create_command("kontur/ovhd_onoff_r", "Kontur R OVHD ONOFF", kontur_ovhd_onoff_r_CMDhandler)


-- The shared physical knob sets both native antenna requests in degrees.
local function apply_weather_tilt()
    local tilt = wx2000_tilt
    if not finite(tilt) then tilt = 0 end
    tilt = math.max(-15, math.min(15, tilt))
    if wx2000_tilt ~= tilt then wx2000_tilt = tilt end

    -- Both automatic modes ignore manual tilt; disable them before writing the angle.
    if simDR_weather_multiscan ~= 0 then simDR_weather_multiscan = 0 end
    if simDR_weather_multiscan_fo ~= 0 then simDR_weather_multiscan_fo = 0 end
    if simDR_weather_auto_tilt ~= 0 then simDR_weather_auto_tilt = 0 end
    if simDR_weather_auto_tilt_fo ~= 0 then simDR_weather_auto_tilt_fo = 0 end
    -- Avoid redundant writes while the knob is stationary; preserve the ongoing sweep.
    if simDR_weather_tilt ~= tilt then simDR_weather_tilt = tilt end
    if simDR_weather_tilt_fo ~= tilt then simDR_weather_tilt_fo = tilt end
end

-- Configure a single stabilized horizontal sector scan with manual tilt.
local function configure_weather_scan()
    simDR_weather_sector_brg = 0
	-- USER EDIT
    simDR_weather_antenna_limit = 90
    simDR_weather_sector_width = 90
    simDR_weather_sweeps_per_sec = 0.6 -- Full left-right-left cycles per second.
	-- END OF EDIT
    simDR_weather_vertical = 0
    simDR_weather_vertical_fo = 0
    simDR_weather_stab = 1
    simDR_weather_stab_fo = 1
    simDR_weather_gcs = 1
    simDR_weather_gcs_fo = 1
    -- PWS must not start emissions while the WX2000 system is switched off.
    simDR_weather_pws = 0
    apply_weather_tilt()
end

-- Initialize native map/radar controls and restart both display self-tests on aircraft load.
function aircraft_load()
    -- PWS AUTO can emit even with mode OFF; inhibit it before shutting down the radar.
    if simDR_weather_pws ~= 0 then simDR_weather_pws = 0 end
    if simDR_weather_mode_xp ~= 0 then simDR_weather_mode_xp = 0 end
    if simDR_weather_mode_xp_fo ~= 0 then simDR_weather_mode_xp_fo = 0 end
    configure_weather_scan()
    reset_display_l()
    reset_display_r()
    weather_test_timer = 0
    kontur_wx_test_l = 0
    weather_ready = 0
    simDR_efis_1_fix					= 0
    simDR_efis_1_wxr					= 0
    simDR_efis_2_wxr					= 0
    simDR_efis_1_ndb					= 0
    simDR_efis_1_tcas					= 0
        if simDR_efis_1_range < 5 then
            simDR_efis_1_vor					= 1
        else
            simDR_efis_1_vor					= 0
        end
    simDR_efis_1_apt					= 1
    kontur_nav_l = 0
    kontur_on_l = 0
    kontur_test_l = 0
    kontur_onoff_l = 0
    kontur_onoff_r = 0
    kontur_wx_l = 0
    kontur_taws_l = 0
    kontur_nav_r = 0
    kontur_on_r = 0
    kontur_test_r = 0
    kontur_taws_r = 0
    simDR_vbe1 = 0
    simDR_vbe2 = 0
    aircraft_loaded = 1
    kontur_button_lit_l = 0.3
    kontur_button_lit_r = 0.3
end




-- Update left screen power, staged startup test and the two settings-menu encoders.
-- A mode key can acknowledge the final test stage; otherwise startup completes at 23 s.
function kontur_left()
    if kontur_pow_l <= 0 or simDR_bus27left <= 13 or kontur_onoff_l >= 1 then
        reset_display_l()
        kontur_pow_l_lit = 0
        return
    end
    kontur_pow_l_lit = 1
    if kontur_test_start_l > 0 then
        kontur_test_timer_l = kontur_test_timer_l + frame_step()
        kontur_test_l = 0
        if kontur_test_timer_l >= 3 then kontur_test_l = 1 end
        if kontur_test_timer_l >= 6 then kontur_test_l = 2 end
        if kontur_test_timer_l >= 12 then kontur_test_l = 3 end
        if kontur_test_timer_l >= 14 then kontur_test_l = 4 end
        if kontur_test_timer_l >= 17 then kontur_test_l = 5 end
        if kontur_test_timer_l >= 23 then
            kontur_test_start_l = 0
            kontur_test_timer_l = 0
            kontur_test_l = 0
            kontur_on_l = 1
        end
    end
-- Each encoder change of roughly 10 units advances one menu step.
if kontur_nav_menu_l > 0 then
   if (kontur_info_knob2_l - info_knob2_l_loc) > 9.9 then
        if kontur_nav_l > 0 then
            if kontur_nav_menu_l < 3 then
                kontur_nav_menu_l = kontur_nav_menu_l + 1
            end
        else
            if kontur_nav_menu_l < 2 then
                kontur_nav_menu_l = kontur_nav_menu_l + 1
            end
        end
        info_knob2_l_loc = kontur_info_knob2_l
    end
    if (info_knob2_l_loc - kontur_info_knob2_l) > 9.9 then
       if kontur_nav_menu_l > 1 then
            kontur_nav_menu_l = kontur_nav_menu_l - 1
       end  
       info_knob2_l_loc = kontur_info_knob2_l
    end
end


-- Menu 1 adjusts button backlighting; outside it, track the knob without changing brightness.
if kontur_nav_menu_l == 1 then
    if (kontur_info_knob1_l - info_knob1_l_loc) > 9.9 then
        if kontur_button_lit_l < 1 then
            kontur_button_lit_l = kontur_button_lit_l + 0.1
        end
        info_knob1_l_loc = kontur_info_knob1_l
    end
    if (info_knob1_l_loc - kontur_info_knob1_l) > 9.9 then
        if kontur_button_lit_l > 0 then
            kontur_button_lit_l = kontur_button_lit_l - 0.1
        end
        info_knob1_l_loc = kontur_info_knob1_l
    end
else
    info_knob1_l_loc = kontur_info_knob1_l
end
    
if kontur_button_lit_l > 1 then
    kontur_button_lit_l = 1
elseif kontur_button_lit_l < 0 then
    kontur_button_lit_l = 0
end
    
if kontur_nav_menu_l > 2 and kontur_nav_l < 1 then
    kontur_nav_menu_l = 2
end
    
    
    

end

-- Update the right screen independently, preserving its original 21-second startup sequence.
function kontur_right()
    if kontur_pow_r <= 0 or simDR_bus27right <= 13 or kontur_onoff_r >= 1 then
        reset_display_r()
        kontur_pow_r_lit = 0
        return
    end
    kontur_pow_r_lit = 1
    if kontur_test_start_r > 0 then
        kontur_test_timer_r = kontur_test_timer_r + frame_step()
        kontur_test_r = 0
        if kontur_test_timer_r >= 3 then kontur_test_r = 1 end
        if kontur_test_timer_r >= 7 then kontur_test_r = 2 end
        if kontur_test_timer_r >= 13 then kontur_test_r = 3 end
        if kontur_test_timer_r >= 16 then kontur_test_r = 4 end
        if kontur_test_timer_r >= 19 then kontur_test_r = 5 end
        if kontur_test_timer_r >= 21 then
            kontur_test_start_r = 0
            kontur_test_timer_r = 0
            kontur_test_r = 0
            kontur_on_r = 1
        end
    end
if kontur_nav_menu_r > 0 then
   if (kontur_info_knob2_r - info_knob2_r_loc) > 9.9 then
        if kontur_nav_r > 0 then
            if kontur_nav_menu_r < 3 then
                kontur_nav_menu_r = kontur_nav_menu_r + 1
            end
        else
            if kontur_nav_menu_r < 2 then
                kontur_nav_menu_r = kontur_nav_menu_r + 1
            end
        end
        info_knob2_r_loc = kontur_info_knob2_r
    end
    if (info_knob2_r_loc - kontur_info_knob2_r) > 9.9 then
       if kontur_nav_menu_r > 1 then
            kontur_nav_menu_r = kontur_nav_menu_r - 1
       end  
       info_knob2_r_loc = kontur_info_knob2_r
    end
end


if kontur_nav_menu_r == 1 then
    if (kontur_info_knob1_r - info_knob1_r_loc) > 9.9 then
        if kontur_button_lit_r < 1 then
            kontur_button_lit_r = kontur_button_lit_r + 0.1
        end
        info_knob1_r_loc = kontur_info_knob1_r
    end
    if (info_knob1_r_loc - kontur_info_knob1_r) > 9.9 then
        if kontur_button_lit_r > 0 then
            kontur_button_lit_r = kontur_button_lit_r - 0.1
        end
        info_knob1_r_loc = kontur_info_knob1_r
    end
else
    info_knob1_r_loc = kontur_info_knob1_r
end
    
if kontur_button_lit_r > 1 then
    kontur_button_lit_r = 1
elseif kontur_button_lit_r < 0 then
    kontur_button_lit_r = 0
end
    
if kontur_nav_menu_r > 2 and kontur_nav_r < 1 then
    kontur_nav_menu_r = 2
end
    
    

end

-- A single radar state owns the warm-up, power lamp and XP12 radar release.
local function update_weather()
    local was_ready = weather_ready > 0
    local powered = finite(weather_sys) and weather_sys > 0 and finite(simDR_36v) and simDR_36v > 0
    -- Invalid external selector writes must not select an unintended emitting mode.
    local valid_mode = finite(weather_mode) and weather_mode >= 0 and weather_mode <= 3
        and weather_mode == math.floor(weather_mode)
    if not powered then
        -- Do not retain a hidden display-standby latch across a radar restart.
        wx_display_l = 3
        wx_display_r = 3
    end
    weather_lit = powered and 1 or 0
    if not powered then
        weather_test_timer = 0
        kontur_wx_test_l = 0
    elseif kontur_wx_test_l ~= -1 then
        weather_test_timer = weather_test_timer + frame_step()
        if weather_test_timer >= 20 then kontur_wx_test_l = -1
        elseif weather_test_timer >= 12 then kontur_wx_test_l = 2
        elseif weather_test_timer >= 5 then kontur_wx_test_l = 1
        else kontur_wx_test_l = 0 end
    end
    -- TEST is a usable native display mode, not the radar power-off position.
    weather_ready = powered and valid_mode and kontur_wx_test_l == -1 and 1 or 0
    local pws = weather_ready > 0 and wx2000_windshear == 1 and 1 or 0
    -- Mode OFF alone cannot stop native PWS; remove its request first on shutdown.
    if pws == 0 and simDR_weather_pws ~= 0 then simDR_weather_pws = 0 end
    if weather_ready > 0 and not was_ready then configure_weather_scan() end
    -- Physical 0/1/2/3 -> XP12 TEST/WX/WX+T/MAP (native 1/2/3/4).
    -- Avoid repeated mode writes that could restart a native scan every frame.
    local native_mode = weather_ready > 0 and weather_mode + 1 or 0
    if simDR_weather_mode_xp ~= native_mode then simDR_weather_mode_xp = native_mode end
    if simDR_weather_mode_xp_fo ~= native_mode then simDR_weather_mode_xp_fo = native_mode end
    -- Apply after mode changes and power recovery so the physical setting stays in control.
    apply_weather_tilt()
    if simDR_weather_stab ~= 1 then simDR_weather_stab = 1 end
    if simDR_weather_stab_fo ~= 1 then simDR_weather_stab_fo = 1 end
    -- MAP needs ground returns; restore the established suppression when leaving MAP.
    local ground_suppression = native_mode == 4 and 0 or 1
    if simDR_weather_gcs ~= ground_suppression then simDR_weather_gcs = ground_suppression end
    if simDR_weather_gcs_fo ~= ground_suppression then simDR_weather_gcs_fo = ground_suppression end
    -- One shared antenna/PWS controller. XP12 owns its automatic flight-phase envelope;
    -- hiding WX on either screen must not disable predictive windshear detection.
    if simDR_weather_pws ~= pws then simDR_weather_pws = pws end
end

-- Publish each screen's visible layers after power, radar readiness and source data are current.
-- INFO temporarily hides those layers without discarding the selected NAV/WX/TCAS state.
local function apply_display_modes()
    clear_modes_l()
    local active_l = kontur_on_l > 0 and info_page_l == 0
    if active_l then
        if kontur_mode_l == 1 then kontur_taws_l = simDR_taws_mode == 2 and 2 or 1
        elseif kontur_mode_l == 2 then kontur_tcas_l = tcas_display_l
        elseif kontur_mode_l == 3 or kontur_mode_l == 5 then kontur_nav_l = 1 end
        -- Keep NAV's expanded map geometry when adding traffic (TCAS format 2).
        if kontur_nav_l > 0 and tcas_overlay_l then kontur_tcas_l = 2 end
        if kontur_mode_l == 4 or kontur_mode_l == 5 then
            kontur_wx_l = weather_ready > 0 and wx_display_l or 1
        end
        if kontur_mode_l >= 2 and kontur_mode_l <= 5 then kontur_map_l = 1 end
    end
    simDR_efis_1_mode = 2
    simDR_efis_1_hsi = kontur_tcas_l == 1 and 1 or 0
    simDR_efis_1_tcas = kontur_tcas_l > 0 and simDR_tcas_mode > 2
        and simDR_tcas_disp_mod >= 0 and simDR_tcas_disp_mod < 100 and 1 or 0
    -- Clear active native terrain before the final WX write; the layers are exclusive.
    -- Do not issue a terrain-off write after enabling the weather overlay.
    if kontur_wx_l > 0 and simDR_efis_1_terrain > 0 then simDR_efis_1_terrain = 0 end
    -- The electronic TEST pattern does not require antenna stabilization.
    simDR_efis_1_wxr = kontur_wx_l == 3 and weather_ready > 0
        and (weather_mode == 0 or nostab_l < 1) and 1 or 0
    simDR_efis_1_fix = 0
    simDR_efis_1_ndb = 0
    simDR_efis_1_vor = kontur_nav_l > 0 and simDR_efis_1_range < 5 and 1 or 0
    simDR_efis_1_apt = kontur_nav_l > 0 and 1 or 0
    clear_modes_r()
    local active_r = kontur_on_r > 0 and info_page_r == 0
    if active_r then
        if kontur_mode_r == 1 then kontur_taws_r = simDR_taws_mode == 2 and 2 or 1
        elseif kontur_mode_r == 2 then kontur_tcas_r = tcas_display_r
        elseif kontur_mode_r == 3 or kontur_mode_r == 5 then kontur_nav_r = 1 end
        -- Keep NAV's expanded map geometry when adding traffic (TCAS format 2).
        if kontur_nav_r > 0 and tcas_overlay_r then kontur_tcas_r = 2 end
        if kontur_mode_r == 4 or kontur_mode_r == 5 then
            kontur_wx_r = weather_ready > 0 and wx_display_r or 1
        end
        if kontur_mode_r >= 2 and kontur_mode_r <= 5 then kontur_map_r = 1 end
    end
    simDR_efis_2_mode = 2
    simDR_efis_2_hsi = kontur_tcas_r == 1 and 1 or 0
    simDR_efis_2_tcas = kontur_tcas_r > 0 and simDR_tcas_mode > 2
        and simDR_tcas_disp_mod >= 0 and simDR_tcas_disp_mod < 100 and 1 or 0
    -- Clear active native terrain before the final WX write; the layers are exclusive.
    -- Do not issue a terrain-off write after enabling the weather overlay.
    if kontur_wx_r > 0 and simDR_efis_2_terrain > 0 then simDR_efis_2_terrain = 0 end
    simDR_efis_2_wxr = kontur_wx_r == 3 and weather_ready > 0
        and (weather_mode == 0 or nostab_r < 1) and 1 or 0
    simDR_efis_2_fix = 0
    simDR_efis_2_ndb = 0
    simDR_efis_2_vor = kontur_nav_r > 0 and simDR_efis_1_range < 5 and 1 or 0
    simDR_efis_2_apt = kontur_nav_r > 0 and 1 or 0
    simDR_efis_2_range = simDR_efis_1_range
    -- Only Kontur writes this global map-line visibility during normal updates.
    simDR_fms_line = (kontur_nav_l > 0 or kontur_nav_r > 0) and nav_source_on > 0 and 0 or 1
end

-- Prepare display-only values and shared brightness/gain; do not change HSI or ABSU sources.
-- Each screen stays lit during its test sequence and dark when switched off.
function kontur_data()
 
if kontur_on_l > 0 then
   simDR_kontur_1_brt = kntr_1_brt_sw
elseif kontur_test_l > 0 then
   simDR_kontur_1_brt = kntr_1_brt_sw
else
   simDR_kontur_1_brt = 0
end
if kontur_on_r > 0 then
   simDR_kontur_2_brt = kntr_2_brt_sw
elseif kontur_test_r > 0 then
   simDR_kontur_2_brt = kntr_2_brt_sw
else
   simDR_kontur_2_brt = 0
end
 
if simDR_efis_1_range < 5 then
    simDR_efis_1_vor					= 1
else
    simDR_efis_1_vor					= 0
end
    
-- Combine compass heading and Doppler drift for the displayed track indication.
if  simDR_gmk_crs < 0 then
     gmk_crs = 360 + simDR_gmk_crs       
else
     gmk_crs = simDR_gmk_crs    
end
        
fpu_crs = gmk_crs + simDR_diss_slipe

 
-- Prefer a valid NAV1 deviation, then NAV2; hide the indication when both flags are invalid.
if simDRcrs_flag1 < 1 then
        diff_crs = simDRcrs_plank1 * 5
        crs_fl = 1
elseif simDRcrs_flag2 < 1 then
        diff_crs = simDRcrs_plank2 * 5
        crs_fl = 1
else
        diff_crs = 0.0
        crs_fl = 0
end
    
if simDRgs_flag1 < 1 then
        diff_gs = simDRgs_plank1 * 5
        gs_fl = 1
elseif simDRgs_flag2 < 1 then
        diff_gs = simDRgs_plank2 * 5
        gs_fl = 1
else
        diff_gs = 0.0
        gs_fl = 0
end
    

-- update_weather() owns the radar power lamp along with readiness and native modes.

-- The UBS-dependent information page and stabilized WX view require their respective supply.
if ubs_pow_r < 1 and info_page_r > 2 then
    info_page_r = 2
end
    
if ubs_pow_l < 1 and info_page_l > 2 then
    info_page_l = 2
end
    
if simDRnostab_l > 0 then
        nostab_l = 1
elseif ubs_pow_l < 1 then
        nostab_l = 1
else
        nostab_l = 0
end
    
if simDRnostab_r > 0 then
        nostab_r = 1
elseif ubs_pow_r < 1 then
        nostab_r = 1
else
        nostab_r = 0
end

-- Trigger the shared switch sound once per physical radar power-switch transition.
if weather_sys > 0 and sw_sound < 1 then
    if simDR_sw_sound > -2 then
        simDR_sw_sound = -2
        sw_sound = 1
    else
        simDR_sw_sound = -1
        sw_sound = 1
    end
end
if weather_sys < 1 and sw_sound > 0 then
    if simDR_sw_sound > -2 then
        simDR_sw_sound = -2
        sw_sound = 0
    else
        simDR_sw_sound = -1
        sw_sound = 0
    end
end   
    
-- Convert the vertical-speed input and radio altitude to the metric display units.
-- Retain the 780 m display limit and the half-second radio-altitude rate sampling.
vvi = simDR_vvi * 0.00508
radioalt_loc = simDR_radioalt * 0.3048
    
if radioalt_loc < 780 then  
    radioalt = radioalt_loc
    if radioalt > 5 then
    if start_vvi_check > 0 then
        radioalt_check = radioalt
        start_vvi = simDR_time
        start_vvi_check = 0
    end
     
    if ((simDR_time - start_vvi) > 0.5) and start_vvi_check < 1 then    
        vvi_rv = (radioalt - radioalt_check) *2
        start_vvi_check = 1
    end  
    end
else
  radioalt = 780
  vvi_rv = 0
end
      
    
    -- A switched-off left panel must not darken the right panel's shared TAWS texture.
    local taws_left = kontur_on_l > 0 and kontur_mode_l == 1 and info_page_l == 0
    local taws_right = kontur_on_r > 0 and kontur_mode_r == 1 and info_page_r == 0
    if taws_left or taws_right then
        simDR_srpbz_brightness = math.max(taws_left and simDR_kontur_1_brt or 0,
            taws_right and simDR_kontur_2_brt or 0)
    end
    
    
    -- The last moved RRU or WX2000 control sets the shared level, including zero.
    -- Stationary knobs must not impose a floor or overwrite a later adjustment.
    -- Same-frame changes use a fixed priority: WX2000, right RRU, left RRU.
    if finite(kontur_rru_l) and kontur_rru_l ~= rru_l_previous then
        wx_level_requested = kontur_rru_l
        rru_l_previous = kontur_rru_l
    end
    if finite(kontur_rru_r) and kontur_rru_r ~= rru_r_previous then
        wx_level_requested = kontur_rru_r
        rru_r_previous = kontur_rru_r
    end
    if finite(wx2000_gain) and wx2000_gain ~= wx2000_gain_previous then
        wx_level_requested = wx2000_gain
        wx2000_gain_previous = wx2000_gain
    end
    local wx_level = wx_level_requested

    if wx_level < 0 then
        wx_level = 0
    elseif wx_level > 1 then
        wx_level = 1
    end

    -- Preserve the old TAWS/WX readability limit.
    if wx_level > 0.4 then
        if (kontur_taws_l > 0 and kontur_wx_r > 0)
            or (kontur_taws_r > 0 and kontur_wx_l > 0) then
            wx_level = 0.4
        end
    end

    simDR_weather_alpha = wx_level
    simDR_weather_alpha_fo = wx_level

    -- XP12.3 radar gain is 0..2; 1.0 is the calibrated/auto position.
    simDR_weather_gain = wx_level * 2
    simDR_weather_gain_fo = wx_level * 2

    -- update_weather() alone owns native radar power and operating mode.
    
    if simDR_efis_1_range > 0 then
    simDR_taws_dist =  simDR_efis_1_range - 1
    else
        simDR_taws_dist = 0
    end
    
    
    -- Separate receiver power from usable route data so invalid guidance can be cleared.
    nav_source_on = simDR_gps_power > 0 and 1 or 0
    nav_source_valid = nav_source_on > 0 and simDR_gps_fromto ~= 0
        and finite(simDR_gps_dme) and simDR_gps_dme >= 0
        and finite(simDR_dtk) and finite(simDR_bear) and 1 or 0

    lat_string=decToDms_lat(simDR_lat)
    long_string=decToDms_long(simDR_long) 
    gs_kmh = simDR_gs * 3.6
    gs_kts = simDR_gs * 1.94
    
    -- Cap distance to the field width and wrap UTC arrival time at midnight.
    gps_dme_km = nav_source_valid > 0 and math.min(999.9, simDR_gps_dme * 1.852) or 0
    if nav_source_valid > 0 and finite(simDR_gps_min) and simDR_gps_min >= 0 and simDR_gps_min <= 9999 then
        local minutes = math.floor(simDR_gps_min)
        gps_hours = math.floor(minutes / 60)
        gps_min = minutes % 60
        local eta = (simDRutchours * 60 + simDRutcmins + minutes) % 1440
        gps_hours_eta = math.floor(eta / 60)
        gps_min_eta = eta % 60
    else
        gps_hours = 0
        gps_min = 0
        gps_hours_eta = 0
        gps_min_eta = 0
    end

    -- Derive signed cross-track distance from GPS range and relative bearing.
    -- Clear both unit variants immediately when route data becomes invalid.
    if nav_source_valid == 0 or not finite(simDR_dtk) or not finite(simDR_bear) then
        kontur_zbok_test = 0
        z_bok_nm = 0
        z_bok = 0
        return
    end
    relative_brg = (simDR_dtk - simDR_bear + 360) % 360
    if relative_brg > 180 then
        relative_brg = relative_brg - 360
    end
    if relative_brg < 0 then
        if relative_brg > -180 then
            relative_brg = -relative_brg
            kontur_zbok_test = -simDR_gps_dme * math.sin(math.rad(relative_brg))
        else
            kontur_zbok_test = -999
        end
    else
        if relative_brg < 180 then
            kontur_zbok_test = simDR_gps_dme * math.sin(math.rad(relative_brg))
        else
            kontur_zbok_test = 999
        end
    end
    z_bok_nm = kontur_zbok_test
    z_bok = kontur_zbok_test * 1.852
end  

-- Order matters: update screen power/tests, then shared radar and data, then final EFIS layers.
function after_physics()
    kontur_left()
    kontur_right()
    update_weather()
    kontur_data()
    apply_display_modes()
end


