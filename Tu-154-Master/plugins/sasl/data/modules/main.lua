print("This is the Tu154M SASL 3 ")
size = { 2048, 2048 }
print("Lua version is", _VERSION)

if jit and jit.os ~= "Windows" then
	jit.off()
	jit.flush()
	print("LuaJIT disabled")
end

sasl.options.set3DRendering(true)
sasl.options.setAircraftPanelRendering(true)
sasl.options.setInteractivity(true)
sasl.options.setRenderingMode2D(SASL_RENDER_2D_MULTIPASS)
sasl.options.setUpdateDrawingReady (true)
-- Added for Development only
sasl.options.setLuaErrorsHandling ( SASL_STOP_PROCESSING )
addSearchResourcesPath(moduleDirectory .. "/Custom Module/textures")
addSearchPath(moduleDirectory .. "/Custom Module/KLN90/")
addSearchPath(moduleDirectory .. "/Custom Module/Custom Sounds")
addSearchPath(moduleDirectory .. "/Custom Module/gui")
addSearchPath(moduleDirectory .. "/Custom Module")
addSearchPath(moduleDirectory .. "/Custom Module/main_panel")
addSearchPath(moduleDirectory .. "/Custom Module/main_panel/taws")
-- include all functions 
include ("functions.lua" )

sasl.gl.setRenderTextPixelAligned(true )

-- 3D panel issue workaround
fixedPanelWidth = 2048
fixedPanelHeight = 2048

math.randomseed(os.time()) -- randomise random :)

xplane_version = globalProperty("sim/version/xplane_internal_version")

components = {
	dataref_creator_1 {}, -- main datarefs. controls and indicatios
	dataref_creator_2 {}, -- internal datarefs
	dataref_creator_3 {}, -- failures datarefs
	save_state {}, -- safe current state
	time_logic {},
	flap_aero {},
	-- gauges and systems
	main_panel { -- panel for simulated 2D gauges
		position = {0, 0, 2048, 2048},
	}, 
	overhead {},
	animation {},
	electric_system{},
	lights_system{},
	apu_system {},
	engines_system {},
	fuel_system {},
	hydro_system {},
	kskv {},
	start_system {},
	controls {},
	fire_system {},
	antiice{},
	msrp {},
	brake_system {},
	sounds {},
	panels_2d {},
}
