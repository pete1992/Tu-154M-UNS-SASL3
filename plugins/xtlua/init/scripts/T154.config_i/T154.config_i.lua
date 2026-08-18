function deferred_command(name,desc,nilFunc)
	c = XLuaCreateCommand(name,desc)
	--print("Deferred command: "..name)
	--XLuaReplaceCommand(c,null_command)
	return nil --make_command_obj(c)
end
function deferred_dataref(name,type,notifier)
	--print("Deffereed dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end

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


changewinglets_CMD = deferred_command("t154cfg/changewinglets", "Change winglets CFG", simconfig_change_winglets_CMDhandler)
changesynclights_CMD = deferred_command("t154cfg/changesynclights", "Change sync lights CFG", simconfig_change_sync_lights_CMDhandler)
changesyncbaro_CMD = deferred_command("t154cfg/changesyncbaro", "Change sync baro CFG", simconfig_change_sync_baro_CMDhandler)
changetech_CMD = deferred_command("t154cfg/changetech", "Change tech CFG", simconfig_change_gtech_CMDhandler)
changeautoladder_CMD = deferred_command("t154cfg/changeautoladder", "Autoladder ON/OFF CFG", simconfig_change_autoladder_CMDhandler)
changeantenna_CMD = deferred_command("t154cfg/changeantenna", "Antenna ON/OFF CFG", simconfig_change_antenna_CMDhandler)
savecfg_CMD = deferred_command("t154cfg/savecfg", "SAVE CFG", simconfig_save_CMDhandler)



T154_hide_mil					= 1
T154_hide_civ					= 0
T154_hide_def					= 1
T154_hide_autoladder			= 1
T154_hide_antenna				= 1 
T154_sync_baro				= 0 
T154_hide_winglets					= 0 
