-- T154.ubs.lua
function deferred_dataref(name,type,notifier)
	print("Deffered dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end

-- Read the independent XP12 display switches and the Kontur-owned source status.
simDR_efis_1_wxr = find_dataref("sim/cockpit2/EFIS/EFIS_weather_on")
simDR_efis_2_wxr = find_dataref("sim/cockpit2/EFIS/EFIS_weather_on_copilot")
kontur_wx_l = find_dataref("tu154/custom/kontur/left_wx")
kontur_wx_r = find_dataref("tu154/custom/kontur/right_wx")
weather_ready = find_dataref("tu154/custom/kontur/weather_ready")
nav_source_on = find_dataref("tu154/custom/kontur/nav_source_on")
simDRtcasmode = find_dataref("tu154/custom/tcas/screen_mode")
simDR_taws_mode = find_dataref("tu154/custom/taws/mode_set")
simDR_sw_sound = find_dataref("tu154/custom/switchers/console/nvu_corr_on")
ubs_pow_l = find_dataref("tu154/custom/ubs/left_power")
ubs_pow_r = find_dataref("tu154/custom/ubs/right_power")
nodata = deferred_dataref("tu154/custom/kontur/nodata", "number")
nodata_r = deferred_dataref("tu154/custom/kontur/nodata_r", "number")

-- Existing bitmaps cover 29 states. The other three use the existing panel font.
nodata_label_no = deferred_dataref("tu154/custom/kontur/nodata_label_no", "string")
nodata_label_mw = deferred_dataref("tu154/custom/kontur/nodata_label_mw", "string")
nodata_label_rdr = deferred_dataref("tu154/custom/kontur/nodata_label_rdr", "string")
nodata_label_taws = deferred_dataref("tu154/custom/kontur/nodata_label_taws", "string")
nodata_label_gps1 = deferred_dataref("tu154/custom/kontur/nodata_label_gps1", "string")
nodata_label_no = "NO"
nodata_label_mw = "MW"
nodata_label_rdr = "RDR"
nodata_label_taws = "TAWS"
nodata_label_gps1 = "GPS1"

local no_swc_l = 0
local no_swc_r = 0
local no_rls = 0
local no_tcas = 0
local no_taws = 0
local no_nav = 0

function ubs_ovhd_onoff_l_CMDhandler(phase, duration)
     if phase == 0 then
        if ubs_pow_l > 0 then
                ubs_pow_l = 0
        else
                ubs_pow_l = 1
        end  
        if simDR_sw_sound > -1 then
            simDR_sw_sound = -1
        else
            simDR_sw_sound = 0
        end
    end    	
end

function ubs_ovhd_onoff_r_CMDhandler(phase, duration)
     if phase == 0 then
        if ubs_pow_r > 0 then
                ubs_pow_r = 0
        else
                ubs_pow_r = 1
        end  
        if simDR_sw_sound > -1 then
            simDR_sw_sound = -1
        else
            simDR_sw_sound = 0
        end
    end    	
end	

UBS_L_ON_func	= create_command("ubs/ovhd_onoff_l", "UBS L OVHD ONOFF", ubs_ovhd_onoff_l_CMDhandler)
UBS_R_ON_func	= create_command("ubs/ovhd_onoff_r", "UBS R OVHD ONOFF", ubs_ovhd_onoff_r_CMDhandler)

function kontur_nodata_items()
    -- A powered GPS1 without a selected leg is available; waypoint fields have
    -- their separate nav_source_valid gate and show dashes until a leg exists.
    no_nav = nav_source_on > 0 and 0 or 1
    no_swc_l = (kontur_wx_l > 0 and simDR_efis_1_wxr < 1) and 1 or 0
    no_swc_r = (kontur_wx_r > 0 and simDR_efis_2_wxr < 1) and 1 or 0
    no_rls = weather_ready > 0 and 0 or 1
    no_tcas = simDRtcasmode == 100 and 1 or 0
    no_taws = (simDR_taws_mode == 0 or simDR_taws_mode == 4) and 1 or 0
end

-- Missing-source mask: MW=1, radar=2, TCAS=4, TAWS=8, GPS1=16.
-- Retain every existing artwork code and define the three previously stale states.
local nodata_codes = {
    [0] = 0, [1] = 11, [2] = 12, [3] = 7,
    [4] = 13, [5] = 5, [6] = 9, [7] = 3,
    [8] = 14, [9] = 6, [10] = 8, [11] = 30,
    [12] = 10, [13] = 2, [14] = 4, [15] = 1,
    [16] = 29, [17] = 25, [18] = 26, [19] = 21,
    [20] = 27, [21] = 19, [22] = 23, [23] = 17,
    [24] = 28, [25] = 20, [26] = 22, [27] = 31,
    [28] = 24, [29] = 16, [30] = 18, [31] = 15,
}

function kontur_nodata_l()
    nodata = nodata_codes[no_swc_l + 2 * no_rls + 4 * no_tcas + 8 * no_taws + 16 * no_nav]
end

function kontur_nodata_r()
    nodata_r = nodata_codes[no_swc_r + 2 * no_rls + 4 * no_tcas + 8 * no_taws + 16 * no_nav]
end

run_at_interval(kontur_nodata_l, 1.5)
run_at_interval(kontur_nodata_r, 1.5)

function after_physics()
    kontur_nodata_items()    
end
