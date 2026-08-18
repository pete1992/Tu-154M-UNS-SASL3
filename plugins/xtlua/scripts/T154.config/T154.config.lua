--replace create_command
function deferred_command(name,desc,realFunc)
	return replace_command(name,realFunc)
end
--replace deferred_dataref
function deferred_dataref(name,nilType,callFunction)
  if callFunction~=nil then
    --print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
    end
    return find_dataref(name)
end

dofile("json/json.lua")

simDR_livery_path			= find_dataref("sim/aircraft/view/acf_livery_path")


--*************************************************************************************--
--** 				        CREATE READ-WRITE CUSTOM DATAREFS                        **--
--*************************************************************************************--
-- Holds all SimConfig options
T154_simconfig_data						= deferred_dataref("tu154/custom/t154cfg/simconfig", "string")
T154_newsimconfig_data					= deferred_dataref("tu154/custom/t154cfg/newsimconfig", "number")
T154_hide_mil					= deferred_dataref("tu154/custom/t154cfg/hide_mil", "number")
T154_hide_civ					= deferred_dataref("tu154/custom/t154cfg/hide_civ", "number")
T154_hide_def					= deferred_dataref("tu154/custom/t154cfg/hide_def", "number")
T154_hide_autoladder					= deferred_dataref("tu154/custom/t154cfg/hide_autoladder", "number")
T154_hide_antenna					= deferred_dataref("tu154/custom/t154cfg/hide_antenna", "number")
T154_sync_baro					= deferred_dataref("tu154/custom/t154cfg/sync_baro", "number")
T154_sync_lights					= deferred_dataref("tu154/custom/t154cfg/sync_lights", "number")
T154_hide_winglets					= deferred_dataref("tu154/custom/t154cfg/hide_winglets", "number")
T154_show_winglets					= deferred_dataref("tu154/custom/t154cfg/show_winglets", "number")

simDR_kitchen_pld = find_dataref("tu154/custom/payload/kitchens")
simDR_cargo1_pld = find_dataref("tu154/custom/payload/cargo_1")
simDR_var_pld = find_dataref("tu154/custom/payload/various")
simDR_vd15_l = find_dataref("tu154/custom/gauges/alt/vd15_pressure_left")
simDR_vd15_r = find_dataref("tu154/custom/gauges/alt/vd15_pressure_right")
simDR_vd15_e = find_dataref("tu154/custom/gauges/alt/vd15_pressure_eng")
simDR_uvid = find_dataref("tu154/custom/gauges/alt/uvid_pressure_knob")
simDR_vbe_l = find_dataref("tu154/custom/gauges/alt/vbe_press_left")
simDR_vbe_r = find_dataref("tu154/custom/gauges/alt/vbe_press_right")
simDR_left_panel_lit = find_dataref("tu154/custom/lights/left_panel_int_set")
simDR_left_panel_c_lit = find_dataref("tu154/custom/lights/mid_left_panel_int_set")
simDR_right_panel_lit = find_dataref("tu154/custom/lights/right_panel_int_set")
simDR_right_panel_c_lit = find_dataref("tu154/custom/lights/mid_right_panel_int_set")
simDR_left_pnppkp_lit = find_dataref("tu154/custom/switchers/airbleed/ground_cond_on_cap")
simDR_right_pnppkp_lit = find_dataref("tu154/custom/switchers/airbleed/skv_faster_work_cap")

--*************************************************************************************--
--** 				        MAIN PROGRAM LOGIC                                       **--
--*************************************************************************************--
simConfigData = {}


function simconfig_values()
	return {
			SIM = {
                ground = 0,
                has_autoladder = "NO",
                has_antenna = "NO",
                sync_baro = "NO",
                sync_lights = "NO",
                winglets = "NO"
			}
	}
end


function winglets_func()
    if T154_hide_winglets > 0 then
       T154_show_winglets = 0
    else
       T154_show_winglets = 1
    end
end

function lights_sync()
    if T154_sync_baro == 1 then
        simDR_left_panel_c_lit = simDR_left_panel_lit
        simDR_right_panel_lit = simDR_left_panel_lit
        simDR_right_panel_c_lit = simDR_left_panel_lit
    elseif T154_sync_baro == 2 then
        simDR_left_panel_c_lit = simDR_right_panel_lit
        simDR_right_panel_c_lit = simDR_right_panel_lit
        simDR_left_panel_lit = simDR_right_panel_lit
    end
end

function baro_sync()
    if T154_sync_baro == 1 then
      simDR_vd15_r = simDR_vd15_l
      simDR_vd15_e = simDR_vd15_l
      simDR_vbe_r = simDR_vbe_l
    elseif T154_sync_baro == 2 then
      simDR_vd15_l = simDR_vd15_r
      simDR_vd15_e = simDR_vd15_r
      simDR_vbe_l = simDR_vbe_r
      simDR_uvid = simDR_vbe_r
    end
end


function antenna()
    -- Intentionally left empty.
end

function autoladder()
	if T154_hide_autoladder < 1 then
        if simDR_var_pld < 400 then
            simDR_var_pld = 400
        end
	end
end

function simconfig_save_CMDhandler(phase, duration)
    if phase == 0 then
        local file_location_w = simDR_livery_path.."T154_config.dat"
        local file_w = io.open(file_location_w, "w")
        if file_w ~= nil then
            io.output(file_w)
            io.write(T154_simconfig_data)
            io.close(file_w)
        end
    end
end


function doneNewSimConfig()
	T154_newsimconfig_data=0
end

function pushSimConfig(values)
	T154_simconfig_data=json.encode(values)
	T154_newsimconfig_data=1
	run_after_time(doneNewSimConfig, 1)
end


function simconfig_change_gtech_CMDhandler(phase, duration)
    if phase == 0 then
        local ground_tech = simConfigData["data"].SIM.ground
        if ground_tech == 0 then
			ground_tech = 1
            T154_hide_mil = 1
            T154_hide_civ = 0
            T154_hide_def = 1
		elseif ground_tech == 1 then
			ground_tech = 2
            T154_hide_mil = 0
            T154_hide_civ = 1
            T154_hide_def = 1
        else
            ground_tech = 0
            T154_hide_mil = 1
            T154_hide_civ = 1
            T154_hide_def = 0
		end
		simConfigData["data"].SIM.ground = ground_tech
		pushSimConfig(simConfigData["data"]["values"])
    end
end

function simconfig_change_antenna_CMDhandler(phase, duration)
    if phase == 0 then
        local antenna_cur = simConfigData["data"].SIM.has_antenna
        if antenna_cur == "NO" then
			antenna_cur = "YES"
            T154_hide_antenna = 0
        else
            antenna_cur = "NO"
            T154_hide_antenna = 1
		end
		simConfigData["data"].SIM.has_antenna = antenna_cur
		pushSimConfig(simConfigData["data"]["values"])
    end
end

function simconfig_change_autoladder_CMDhandler(phase, duration)
    if phase == 0 then
        local autoladder_cur = simConfigData["data"].SIM.has_autoladder
        if autoladder_cur == "NO" then
			autoladder_cur = "YES"
            T154_hide_autoladder = 0
        else
            autoladder_cur = "NO"
            T154_hide_autoladder = 1
		end
		simConfigData["data"].SIM.has_autoladder = autoladder_cur
		pushSimConfig(simConfigData["data"]["values"])
    end
end

function simconfig_change_sync_baro_CMDhandler(phase, duration)
    if phase == 0 then
        local sync_baro_cur = simConfigData["data"].SIM.sync_baro
        if sync_baro_cur == "CPT" then
			sync_baro_cur = "FO"
            T154_sync_baro = 2
        elseif sync_baro_cur == "FO" then
            sync_baro_cur = "NO"
            T154_sync_baro = 0
        else
            sync_baro_cur = "CPT"
            T154_sync_baro = 1
		end
		simConfigData["data"].SIM.sync_baro = sync_baro_cur
		pushSimConfig(simConfigData["data"]["values"])
    end
end

function simconfig_change_sync_lights_CMDhandler(phase, duration)
    if phase == 0 then
        local sync_lights_cur = simConfigData["data"].SIM.sync_lights
        if sync_lights_cur == "CPT" then
			sync_lights_cur = "FO"
            T154_sync_lights = 2
        elseif sync_lights_cur == "FO" then
            sync_lights_cur = "NO"
            T154_sync_lights = 0
        else
            sync_lights_cur = "CPT"
            T154_sync_lights = 1
		end
		simConfigData["data"].SIM.sync_lights = sync_lights_cur
		pushSimConfig(simConfigData["data"]["values"])
    end
end

function simconfig_change_winglets_CMDhandler(phase, duration)
    if phase == 0 then
        local winglets_cur = simConfigData["data"].SIM.winglets
        if winglets_cur == "NO" then
			winglets_cur = "YES"
            T154_hide_winglets = 0
            T154_show_winglets = 1
        else
            winglets_cur = "NO"
            T154_hide_winglets = 1
            T154_show_winglets = 0
		end
		simConfigData["data"].SIM.winglets = winglets_cur
		pushSimConfig(simConfigData["data"]["values"])
    end
end

changewinglets_CMD = deferred_command("t154cfg/changewinglets", "Change winglets CFG", simconfig_change_winglets_CMDhandler)
changesynclights_CMD = deferred_command("t154cfg/changesynclights", "Change sync lights CFG", simconfig_change_sync_lights_CMDhandler)
changesyncbaro_CMD = deferred_command("t154cfg/changesyncbaro", "Change sync baro CFG", simconfig_change_sync_baro_CMDhandler)
changetech_CMD = deferred_command("t154cfg/changetech", "Change tech CFG", simconfig_change_gtech_CMDhandler)
changeautoladder_CMD = deferred_command("t154cfg/changeautoladder", "Autoladder ON/OFF CFG", simconfig_change_autoladder_CMDhandler)
changeantenna_CMD = deferred_command("t154cfg/changeantenna", "Antenna ON/OFF CFG", simconfig_change_antenna_CMDhandler)
savecfg_CMD = deferred_command("t154cfg/savecfg", "SAVE CFG", simconfig_save_CMDhandler)




function set_loaded_configs()
	
	if simConfigData["data"].SIM.ground == 0 then
        T154_hide_mil = 1
        T154_hide_civ = 1
        T154_hide_def = 0
    elseif simConfigData["data"].SIM.ground == 1 then
        T154_hide_mil = 1
        T154_hide_civ = 0
        T154_hide_def = 1
    elseif simConfigData["data"].SIM.ground == 2 then
        T154_hide_mil = 0
        T154_hide_civ = 1
        T154_hide_def = 1
        simDR_kitchen_pld = 0
	end
    
	if simConfigData["data"].SIM.has_autoladder == "YES" then
        T154_hide_autoladder = 0
    elseif simConfigData["data"].SIM.has_autoladder == "NO" then
        T154_hide_autoladder = 1
	end
    
	if simConfigData["data"].SIM.has_antenna == "YES" then
        T154_hide_antenna = 0
    elseif simConfigData["data"].SIM.has_antenna == "NO" then
        T154_hide_antenna = 1
	end
    
	if simConfigData["data"].SIM.sync_baro == "CPT" then
        T154_sync_baro = 1
	elseif simConfigData["data"].SIM.sync_baro == "FO" then
        T154_sync_baro = 2
    else
        T154_sync_baro = 0
	end
    
	if simConfigData["data"].SIM.sync_lights == "CPT" then
        T154_sync_lights = 1
	elseif simConfigData["data"].SIM.sync_lights == "FO" then
        T154_sync_lights = 2
    else
        T154_sync_lights = 0
	end
	if simConfigData["data"].SIM.winglets == "YES" then
        T154_hide_winglets = 0
        T154_show_winglets = 1
    elseif simConfigData["data"].SIM.winglets == "NO" then
        T154_hide_winglets = 1
        T154_show_winglets = 0
	end
	T154_newsimconfig_data = 0
end



function aircraft_simConfig()
	local file_location = simDR_livery_path.."T154_config.dat"
	--print("File = "..file_location)
	local file = io.open(file_location, "r")

	if file ~= nil then
		io.input(file)
		local tmpDataS = io.read()
		io.close(file)
		--print("read "..tmpDataS)
		local tmpData=json.decode(tmpDataS)
		--print("encoding "..tmpDataS)
		T154_simconfig_data = json.encode(tmpData)
		--print("done encoding "..T154_simconfig_data)
		T154_newsimconfig_data=1
		run_after_time(set_loaded_configs, 3)  --Apply loaded configs.  Wait a few seconds to ensure they load correctly.
	else
		T154_simconfig_data = json.encode(simconfig_values())
		run_after_time(set_loaded_configs, 3)  --Apply loaded configs.  Wait a few seconds to ensure they load correctly.
	end

end

simConfigData["data"]=simconfig_values()


function flight_start()
	local refreshLivery=simDR_livery_path
	T154_simconfig_data=json.encode(simConfigData["data"]["values"]) --make the simConfig data available to other modules
	T154_newsimconfig_data=1
	run_after_time(aircraft_simConfig, 1)  --Load specific simConfig data for current livery
    local livery_path =simDR_livery_path
end



function livery_change()
	--print("livery load")
	local refreshLivery=simDR_livery_path
    livery_path = simDR_livery_path
	T154_newsimconfig_data=1
	run_after_time(aircraft_simConfig, 2)  --Load specific simConfig data for current livery
end

local setSimConfig=false


function hasSimConfig()
	if T154_newsimconfig_data==1 then
		if string.len(T154_simconfig_data) > 1 then
			simConfigData["data"] = json.decode(T154_simconfig_data)
			setSimConfig=true
		else
			return false
		end
	end
	return setSimConfig
end




function after_physics()
	--Keep the structure fresh
	if hasSimConfig()==false then return end

    if livery_path ~= simDR_livery_path then
        livery_change()
    end
    
    lights_sync()
    baro_sync()
    antenna()
    winglets_func()
    autoladder()
end

