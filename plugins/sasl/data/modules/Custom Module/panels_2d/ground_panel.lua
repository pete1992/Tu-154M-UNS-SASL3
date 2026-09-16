-- this is ground service panel
size = {655, 880}
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    { "save_state", "tu154/custom/save_state", globalPropertyi }, --
    -- time
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time
    { "show_ground_panel", "tu154/custom/panels/show_ground_panel", globalPropertyi }, --
    { "reset_crew", "tu154/custom/sound/reset_crew", globalPropertyi }, --
    { "failures_enabled", "tu154/custom/failures/failures_enabled", globalPropertyi },
    { "have_pedals", "tu154/custom/have_pedals", globalPropertyi },
    --defineProperty("save_state_enabled",globalPropertyi("tu154/custom/save_state_enabled")) --
    -- Unused bindings retained for reference; no ground-panel control reads them.
    -- { "reset_state", "tu154/custom/reset_state", globalPropertyi },
    { "asu_work", "tu154/custom/asu/work", globalPropertyi },

    -- datarefs
    { "hide_rus_objects", "tu154/custom/lang/hide_rus_objects", globalPropertyi }, --
    { "hide_eng_objects", "tu154/custom/lang/hide_eng_objects", globalPropertyi }, --
    { "sounds_volume", "tu154/custom/sounds_voulme", globalPropertyi }, --
    { "slider_1", "sim/cockpit2/switches/custom_slider_on[0]", globalProperty }, -- window L
    { "slider_2", "sim/cockpit2/switches/custom_slider_on[1]", globalProperty }, -- window R
    { "slider_3", "sim/cockpit2/switches/custom_slider_on[2]", globalProperty }, -- cargo 1
    { "slider_4", "sim/cockpit2/switches/custom_slider_on[3]", globalProperty }, -- cargo 2
    { "slider_5", "sim/cockpit2/switches/custom_slider_on[4]", globalProperty }, -- pax door 1
    { "slider_6", "sim/cockpit2/switches/custom_slider_on[5]", globalProperty }, -- pax door 2
    { "slider_7", "sim/cockpit2/switches/custom_slider_on[6]", globalProperty }, -- kitchen door
    -- { "slider_8", "sim/cockpit2/switches/custom_slider_on[7]", globalProperty },
    { "slider_9", "sim/cockpit2/switches/custom_slider_on[8]", globalProperty }, -- yokes
    -- { "slider_10", "sim/cockpit2/switches/custom_slider_on[9]", globalProperty },
    -- { "slider_11", "sim/cockpit2/switches/custom_slider_on[10]", globalProperty },
    -- { "slider_12", "sim/cockpit2/switches/custom_slider_on[11]", globalProperty },
    { "gear_blocks", "tu154/custom/anim/gear_blocks", globalPropertyi }, --
    { "sensors_caps", "tu154/custom/anim/sensors_caps", globalPropertyi }, --
    { "engine_caps", "tu154/custom/anim/engine_caps", globalPropertyi }, --
    { "gpu_present", "tu154/custom/anim/gpu_present", globalPropertyi }, --
    { "ladder_1_call", "tu154/custom/anim/ladder_1_call", globalPropertyi }, -- . 100 - . +50..0 - , 0 -   , 0..-50 -
    { "ladder_2_call", "tu154/custom/anim/ladder_2_call", globalPropertyi }, --
    { "catering_call", "tu154/custom/anim/catering_call", globalPropertyi }, --
    { "fuel_tanker_call", "tu154/custom/anim/fuel_tanker_call", globalPropertyi }, --
    { "ladder_1", "tu154/custom/anim/ladder_1", globalPropertyf }, -- - . +50..0 - , 0 -   , 0..-50 - 	100
    { "ladder_2", "tu154/custom/anim/ladder_2", globalPropertyf }, --
    { "catering", "tu154/custom/anim/catering", globalPropertyf }, --
    { "fuel_tanker", "tu154/custom/anim/fuel_tanker", globalPropertyf }, --
    { "GS", "sim/flightmodel/position/groundspeed", globalPropertyf },  -- ground speed
    { "eng_rpm1", "sim/flightmodel/engine/ENGN_N2_[0]", globalProperty },
    { "eng_rpm2", "sim/flightmodel/engine/ENGN_N2_[1]", globalProperty },
    { "eng_rpm3", "sim/flightmodel/engine/ENGN_N2_[2]", globalProperty },
    { "zone_1_pr", "tu154/custom/payload/zone_1", globalPropertyi },
    { "zone_2_pr", "tu154/custom/payload/zone_2", globalPropertyi },
    { "zone_4_pr", "tu154/custom/payload/zone_4", globalPropertyi },
    { "zone_5_pr", "tu154/custom/payload/zone_5", globalPropertyi },
    { "zone_6_pr", "tu154/custom/payload/zone_6", globalPropertyi },
    { "cargo_1_pr", "tu154/custom/payload/cargo_1", globalPropertyi },
    { "cargo_2_pr", "tu154/custom/payload/cargo_2", globalPropertyi },
    { "kitchens_pr", "tu154/custom/payload/kitchens", globalPropertyi },
    { "sim_static_fail_L", "sim/operation/failures/rel_static", globalPropertyi },  -- static fail
    { "sim_static_fail_R", "sim/operation/failures/rel_static2", globalPropertyi },  -- static fail
    { "rel_pitot", "sim/operation/failures/rel_pitot", globalPropertyi }, -- Pitot 1 - Blockage
    { "rel_pitot2", "sim/operation/failures/rel_pitot2", globalPropertyi }, -- Pitot 2 - Blockage
    { "alpha_fail", "sim/operation/failures/rel_AOA", globalPropertyi },  -- angle of attack fail
    { "deflection_mtr_1", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[0]", globalProperty }, --
    { "deflection_mtr_2", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[1]", globalProperty }, --
    { "deflection_mtr_3", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", globalProperty }, --
    { "enable_crew_vo", "tu154/custom/sounds/enable_crew_vo", globalPropertyi }, --
    { "show_fail_panel", "tu154/custom/panels/show_fail_panel", globalPropertyi }, --
    -- { "show_gns", "tu154/custom/anim/show_gns", globalPropertyi }, -- No manual GPS selection.
    { "show_RXP", "tu154/custom/anim/RXP", globalPropertyi },
    { "starter_torq", "sim/aircraft/engine/acf_starter_torque_ratio", globalPropertyf }, --  . 0.18
    -- custom fails
    { "pitot_fail1", "tu154/custom/failures/pitot1", globalPropertyi }, -- Pitot 1 - Blockage
    { "pitot_fail2", "tu154/custom/failures/pitot2", globalPropertyi }, -- Pitot 2 - Blockage
    { "custom_static_fail_L", "tu154/custom/failures/static1", globalPropertyi },  -- static fail
    { "custom_static_fail_R", "tu154/custom/failures/static2", globalPropertyi },  -- static fail
    { "uap_fail", "tu154/custom/failures/AOA", globalPropertyi }, -- fail
})

-- Ground-panel status strings use a compact scalable font.  Verdana at the
-- generic 24 px default is wider than the fields on this panel.
local text_font = sasl.gl.loadFont('Verdana.ttf')
-- load images
defineProperty("bg_img", sasl.gl.loadImage("ground_tex.png")) -- ENG
defineProperty("bg_img_rus", sasl.gl.loadImage("ground_tex_RUS.png")) -- ENG
-- These atlas Y coordinates are already measured from the bottom edge, as
-- required by SASL 3.  Flipping them selects transparent pixels.
defineProperty("green_lamp", sasl.gl.loadImage("overhead_tex.png", 1825, 706, 19, 19))
defineProperty("lev_img", sasl.gl.loadImage("absu_ess.png", 432, 324, 30, 29))
-- sim/operation/toggle_yoke
local yokes_cmd = sasl.findCommand("sim/operation/toggle_yoke")

local function yokes_hnd(phase)
	if 0 == phase then
		set(slider_9, 1 - get(slider_9))
	end
	return 0
end
sasl.registerCommandHandler(yokes_cmd, 0, yokes_hnd)

local ladder_1_pos = get(ladder_1)
local ladder_2_pos = get(ladder_2)
local catering_pos = get(catering)
local fuel_tanker_pos = get(fuel_tanker)
local notLoaded = true
local failPanelShow = false
local reset_click = false

local function coldDarkReset()
	if isColdAndDarkStart() and get(eng_rpm1) < 10 and get(eng_rpm2) < 10 and get(eng_rpm3) < 10 then
		-- cover acf
		set(gear_blocks, 1)
		set(sensors_caps, 1)
		set(engine_caps, 1)
		-- make acf empty
		set(zone_1_pr, 0)
		set(zone_2_pr, 0)
		set(zone_4_pr, 0)
		set(zone_5_pr, 0)
		set(zone_6_pr, 0)
		set(cargo_1_pr, 0)
		set(cargo_2_pr, 0)
		set(kitchens_pr, 20)
	end
	notLoaded = false
	return true
end

local load_counter = 0

function update()
	local passed = get(frame_time)
	--local groundspeed = get(GS)
	load_counter = load_counter + passed
	if notLoaded and load_counter > 3 then
		coldDarkReset()
	end
	-- main sound volume
	sasl.al.setMasterGain(get(sounds_volume))
	ladder_1_pos = get(ladder_1)
	ladder_2_pos = get(ladder_2)
	catering_pos = get(catering)
	fuel_tanker_pos = get(fuel_tanker)	
	-- -100..0 - to acf
	-- 0..+100 - from acf
	-- ladder 1
	if get(ladder_1_call) == 1 then -- call to acf
		if ladder_1_pos == 500 then -- make it appear
			ladder_1_pos = -50
		elseif ladder_1_pos >= -50 and ladder_1_pos < 0 then -- move to the aircraft
			ladder_1_pos = ladder_1_pos + passed * 2.7
			if ladder_1_pos > 0 then ladder_1_pos = 0 end
		elseif ladder_1_pos > 0 then -- call it back from moved away position
			ladder_1_pos = ladder_1_pos - passed * 2.7
			if ladder_1_pos < 0 then ladder_1_pos = 0 end
		end
	else -- cal from acf
		if ladder_1_pos < 0 and ladder_1_pos > -50 then -- send back, if cancelled
			ladder_1_pos = ladder_1_pos - passed * 2.7
			if ladder_1_pos < -50 then ladder_1_pos = -50 end
		elseif ladder_1_pos >= 0 and ladder_1_pos < 50 then -- move from the aircraft
			ladder_1_pos = ladder_1_pos + passed * 2.7
			if ladder_1_pos > 50 then ladder_1_pos = 50 end
		end
	end
	-- ladder 2
	if get(ladder_2_call) == 1 then -- call to acf
		if ladder_2_pos == 500 then -- make it appear
			ladder_2_pos = -50
		elseif ladder_2_pos >= -50 and ladder_2_pos < 0 then -- move to the aircraft
			ladder_2_pos = ladder_2_pos + passed * 2.7
			if ladder_2_pos > 0 then ladder_2_pos = 0 end
		elseif ladder_2_pos > 0 then -- call it back from moved away position
			ladder_2_pos = ladder_2_pos - passed * 2.7
			if ladder_2_pos < 0 then ladder_2_pos = 0 end
		end
	else -- cal from acf
		if ladder_2_pos < 0 and ladder_2_pos > -50 then -- send back, if cancelled
			ladder_2_pos = ladder_2_pos - passed * 2.7
			if ladder_2_pos < -50 then ladder_2_pos = -50 end
		elseif ladder_2_pos >= 0 and ladder_2_pos < 50 then -- move from the aircraft
			ladder_2_pos = ladder_2_pos + passed * 2.7
			if ladder_2_pos > 50 then ladder_2_pos = 50 end
		end
	end
	-- catering
	if get(catering_call) == 1 then -- call to acf
		if catering_pos == 500 then -- make it appear
			catering_pos = -50
		elseif catering_pos >= -50 and catering_pos < 0 then -- move to the aircraft
			catering_pos = catering_pos + passed * 2.7
			if catering_pos > 0 then catering_pos = 0 end
		elseif catering_pos > 0 then -- call it back from moved away position
			catering_pos = catering_pos - passed * 2.7
			if catering_pos < 0 then catering_pos = 0 end
		end
	else -- cal from acf
		if catering_pos < 0 and catering_pos > -50 then -- send back, if cancelled
			catering_pos = catering_pos - passed * 2.7
			if catering_pos < -50 then catering_pos = -50 end
		elseif catering_pos >= 0 and catering_pos < 50 then -- move from the aircraft
			catering_pos = catering_pos + passed * 2.7
			if catering_pos > 50 then catering_pos = 50 end
		end
	end
	-- fuel tanker
	if get(fuel_tanker_call) == 1 then -- call to acf
		if fuel_tanker_pos == 500 then -- make it appear
			fuel_tanker_pos = -50
		elseif fuel_tanker_pos >= -50 and fuel_tanker_pos < 0 then -- move to the aircraft
			fuel_tanker_pos = fuel_tanker_pos + passed * 2.7
			if fuel_tanker_pos > 0 then fuel_tanker_pos = 0 end
		elseif fuel_tanker_pos > 0 then -- call it back from moved away position
			fuel_tanker_pos = fuel_tanker_pos - passed * 2.7
			if fuel_tanker_pos < 0 then fuel_tanker_pos = 0 end
		end
	else -- cal from acf
		if fuel_tanker_pos < 0 and fuel_tanker_pos > -50 then -- send back, if cancelled
			fuel_tanker_pos = fuel_tanker_pos - passed * 2.7
			if fuel_tanker_pos < -50 then fuel_tanker_pos = -50 end
		elseif fuel_tanker_pos >= 0 and fuel_tanker_pos < 50 then -- move from the aircraft
			fuel_tanker_pos = fuel_tanker_pos + passed * 2.7
			if fuel_tanker_pos > 50 then fuel_tanker_pos = 50 end
		end
	end
	-- make all stuff disappear when acf moves
	if math.abs(get(GS)) > 1 or get(gear_blocks) < 1 or get(deflection_mtr_1) < 0.001 or get(deflection_mtr_2) < 0.001 or get(deflection_mtr_3) < 0.001 then -- 
		ladder_1_pos = 500
		ladder_2_pos = 500
		catering_pos = 500
		fuel_tanker_pos = 500
		set(ladder_1_call, 0)
		set(ladder_2_call, 0)
		set(catering_call, 0)
		set(fuel_tanker_call, 0)
		--set(gear_blocks, 0)
		--print(get(GS), "  ", get(gear_blocks), "  ", get(deflection_mtr_1), "  ", get(deflection_mtr_2), "  ", get(deflection_mtr_3))
	end
	-- make block disappear
	if math.abs(get(GS)) > 2 or get(deflection_mtr_1) < 0.001 or get(deflection_mtr_2) < 0.001 or get(deflection_mtr_3) < 0.001 then -- 
		set(gear_blocks, 0)
	end	
	set(ladder_1, ladder_1_pos)
	set(ladder_2, ladder_2_pos)
	set(catering, catering_pos)
	set(fuel_tanker, fuel_tanker_pos)
	-- set failures for Pitot tubes if blocked
	if get(sensors_caps) == 1 then
		set(sim_static_fail_L, 6)
		set(sim_static_fail_R, 6)
		set(rel_pitot, 6)
		set(rel_pitot2, 6)
		set(alpha_fail, 6)
	else -- set custom failures into sim
		set(sim_static_fail_L, get(custom_static_fail_L) * 6)
		set(sim_static_fail_R, get(custom_static_fail_R) * 6)
		set(rel_pitot, get(pitot_fail1) * 6)
		set(rel_pitot2, get(pitot_fail2) * 6)
		set(alpha_fail, get(uap_fail) * 6)
	end
	-- hide repair panel if not on ground
	--if get(gear_blocks) == 0 then set(show_fail_panel, 0) end
	if math.abs(get(GS)) > 1 or get(deflection_mtr_1) < 0.001 or get(deflection_mtr_2) < 0.001 or get(deflection_mtr_3) < 0.001 then -- 
		failPanelShow = false
		set(show_fail_panel, 0)
	else
		failPanelShow = true
	end
	updateAll(components)
end
components = {
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
	------------------
	-- state lamps --
	------------------
	-- Red OFF lamps are part of the background texture.  A green sprite is
	-- overlaid only while the corresponding service or object is active.
	-- left window
	textureLit {
		position = {232, 787, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(slider_1) == 1
		end,
	},
	-- pax door 1
	textureLit {
		position = {232, 744, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(slider_5) == 1
		end,
	},	
	-- sensors caps
	textureLit {
		position = {232, 658, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(sensors_caps) == 1
		end,
	},	
	-- pax door 2
	textureLit {
		position = {232, 613, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(slider_6) == 1
		end,
	},	
	-- gear blocks
	textureLit {
		position = {232, 392, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(gear_blocks) == 1
		end,
	},	
	-- engine covers
	textureLit {
		position = {232, 333, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(engine_caps) == 1
		end,
	},	
	-- right window
	textureLit {
		position = {396, 788, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(slider_2) == 1
		end,
	},	
	-- GPU
	textureLit {
		position = {396, 720, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(gpu_present) == 1
		end,
	},
	-- cargo 1
	textureLit {
		position = {396, 665, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(slider_3) == 1
		end,
	},
	-- kitchen door
	textureLit {
		position = {396, 619, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(slider_7) == 1
		end,
	},
	--  cargo 2
	textureLit {
		position = {396, 392, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(slider_4) == 1
		end,
	},
	-- ladder 1
	textureLit {
		position = {232, 702, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(ladder_1_call) == 1
		end,
	},
	-- ladder 2
	textureLit {
		position = {232, 571, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(ladder_2_call) == 1
		end,
	},
	-- asu
	textureLit {
		position = { 232, 528, 22, 22 },
		image = get(green_lamp),
		visible = function()
			return get(asu_work) == 1
		end,
	},
	-- catering
	textureLit {
		position = {396, 576, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(catering_call) == 1
		end,
	},
	-- tanker
	textureLit {
		position = {396, 531, 22,22},
		image = get(green_lamp),
		visible = function()
			return get(fuel_tanker_call) == 1
		end,
	},
	---------------------
	-- interactives --
	---------------------
	-- change language
	interactive {
		position = {6, 824, 275, 45},
		onMouseDown = function() 
			set(hide_rus_objects, 1 - get(hide_rus_objects))
			set(hide_eng_objects, 1 - get(hide_rus_objects))
			set(save_state, 1)
			return true
		end,
	},		
	-- HIDE/SHOW YOKES
	interactive {
		position = {366, 824, 275, 45},
		onMouseDown = function() 
			set(slider_9, 1 - get(slider_9))
			return true
		end,
	},		
	--------------------------
	-- windows and doors --
	--------------------------
	-- left window
	interactive {
		position = {23, 782, 200, 35},
		onMouseDown = function() 
			set(slider_1, 1 - get(slider_1))
			return true
		end,
	},		
	-- pax door 1
	interactive {
		position = {23, 737, 200, 35},
		onMouseDown = function() 
			set(slider_5, 1 - get(slider_5))
			return true
		end,
	},	
	-- sensors caps
	interactive {
		position = {23, 650, 200, 35},
		onMouseDown = function() 
			if get(GS) <= 0.1 then set(sensors_caps, 1 - get(sensors_caps)) end
			return true
		end,
	},	
	-- pax door 2
	interactive {
		position = {23, 607, 200, 35},
		onMouseDown = function() 
			set(slider_6, 1 - get(slider_6))
			return true
		end,
	},		
	-- gear blocks
	interactive {
		position = {23, 385, 200, 35},
		onMouseDown = function() 
			if get(gear_blocks) ~= 1 and get(GS) < 0.1 then set(gear_blocks, 1) else set(gear_blocks, 0) end
			return true
		end,
	},
	-- engine covers
	interactive {
		position = {23, 325, 200, 35},
		onMouseDown = function() 
			set(engine_caps, 1 - get(engine_caps))
			if get(eng_rpm1) > 5 or get(eng_rpm2) > 5 or get(eng_rpm3) > 5 then set(engine_caps, 0) end
			return true
		end,
	},
	-- right window
	interactive {
		position = {424, 782, 200, 35},
		onMouseDown = function() 
			set(slider_2, 1 - get(slider_2))
			return true
		end,
	},
	-- GPU
	interactive {
		position = {424, 715, 200, 35},
		onMouseDown = function() 
			set(gpu_present, 1 - get(gpu_present))
			return true
		end,
	},
	-- cargo 1
	interactive {
		position = {424, 660, 200, 35},
		onMouseDown = function() 
			set(slider_3, 1 - get(slider_3))
			return true
		end,
	},
	-- kitchen door
	interactive {
		position = {424, 613, 200, 35},
		onMouseDown = function() 
			set(slider_7, 1 - get(slider_7))
			return true
		end,
	},
	-- cargo 2
	interactive {
		position = {424, 386, 200, 35},
		onMouseDown = function() 
			set(slider_4, 1 - get(slider_4))
			return true
		end,
	},
	-----------------------------
	-- ground stuff --
	-----------------------------
	-- ladder 1
	interactive {
		position = {23, 695, 200, 35},
		onMouseDown = function() 
			set(ladder_1_call, 1 - get(ladder_1_call))
			return true
		end,
	},		
	-- ladder 2
	interactive {
		position = {23, 565, 200, 35},
		onMouseDown = function() 
			set(ladder_2_call, 1 - get(ladder_2_call))
			return true
		end,
	},	
	-- ASU
	interactive {
		position = { 23, 523, 200, 35 },
		onMouseDown = function()
			set(asu_work, 1 - get(asu_work))
			return true
		end,
	},
	-- catering
	interactive {
		position = {424, 570, 200, 35},
		onMouseDown = function() 
			set(catering_call, 1 - get(catering_call))
			return true
		end,
	},	
	-- tanker
	interactive {
		position = {424, 526, 200, 35},
		onMouseDown = function() 
			set(fuel_tanker_call, 1 - get(fuel_tanker_call))
			return true
		end,
	},	
	---------------------------
	-- service button --
	---------------------------
	interactive {
		position = {424, 230, 200, 35},
		onMouseDown = function() 
			if failPanelShow then 
				set(show_fail_panel, 1 - get(show_fail_panel))
			else
				set(show_fail_panel, 0)
			end
			return true
		end,
	},
	-- reset crew button
	interactive {
		position = {23, 230, 200, 35},
		onMouseDown = function() 
			if reset_click then
				set(reset_crew, 0)
			end
			if not reset_click then 
				set(reset_crew, 1)
				reset_click = true
			end
			return true
		end,
		onMouseUp = function()
			reset_click = false
			set(reset_crew, 0)
			return true
		end,
	},
	-- sounds volume  
	lever_hor{
       position = { 456, 125, 139, 29},
       value = sounds_volume,
       lever_img = get(lev_img),
       minimum = 0,
       maximum = 1000,
	   addFunc = function() set(save_state, 1) return true end,
   },	
	interactive {
		position = {426, 125, 30, 29},
		onMouseDown = function() 
			local a = get(sounds_volume) - 100
			if a < 0 then a = 0 end
			set(sounds_volume, a)
			set(save_state, 1)
			return true
		end,
	},
	interactive {
		position = {595, 125, 30, 29},
		onMouseDown = function() 
			local a = get(sounds_volume) + 100
			if a > 1000 then a = 1000 end
			set(sounds_volume, a)
			set(save_state, 1)
			return true
		end,
	},	
	-- enable crew voices
	text_draw {
		position = {32, 200, 55, 60},
		text = function()
			if get(enable_crew_vo) == 1 then return "CREW VO ENABLED"
			else return	"CREW VO DISABLED" end
		end,
		font = text_font,
		font_size = 17,
		bitmap = false,
		color = {0,0,0,1},
		visible = true,
	},
	interactive {
		position = {23, 190, 200, 35},
		onMouseDown = function() 
			set(enable_crew_vo, 1 - get(enable_crew_vo))
			set(save_state, 1)
			return true
		end,
	},
	-- Enable failures
	text_draw {
		position = {32, 158, 55, 60},
		text = function()
			if get(failures_enabled) == 0 then return "FAILURES OFF"
			elseif get(failures_enabled) == 1 then return "FAILURES LOW"
			elseif get(failures_enabled) == 2 then return "FAILURES MEDIUM"
			elseif get(failures_enabled) == 3 then return "FAILURES HIGH"
			end
			--if get(failures_enabled) == 1 then return "FAILURES ENABLED"
			--else return	"FAILURES DISABLED" end
		end,
		font = text_font,
		font_size = 17,
		bitmap = false,
		color = {0,0,0,1},
		visible = true,
	},
	interactive {
		position = {23, 148, 200, 35},
		onMouseDown = function() 
			local a = get(failures_enabled) + 1
			if a > 3 then a = 0 end
			set(failures_enabled, a)
			set(save_state, 1)			
			return true
		end,
	},
	-- reset all axies
	text_draw {
		position = {32, 78, 55, 60},
		text = "NW uses YAW",
		font = text_font,
		font_size = 17,
		bitmap = false,
		color = {0,0,0,1},
		visible = function()
			return get(have_pedals) == 0
		end,
	},
	text_draw {
		position = {32, 78, 55, 60},
		text = "NW uses Tiller",
		font = text_font,
		font_size = 17,
		bitmap = false,
		color = {0,0,0,1},
		visible = function()
			return get(have_pedals) == 1
		end,
	},
--[[
	text_draw {
		position = {32, 50, 55, 60},
		text = "WARNING, HOLD FOR 5 SEC",
		font = text_font,
		color = {0,0,0,1},
		visible = true,
	},
	text_draw {
		position = {32, 30, 55, 60},
		text = "TO RESET ALL JOYSTICKS",
		font = text_font,
		color = {0,0,0,1},
		visible = true,
	},
--]]
	interactive {
		position = {23, 70, 200, 35},
		onMouseDown = function() 
			set(have_pedals, 1-get(have_pedals))
			set(save_state, 1)
			return true
		end,
		onMouseUp = function() 
			--set(have_pedals, 0)
			--set(save_state, 1)
			return true
		end,
	},	
	-- GPS installation is detected centrally, even while this window is closed.
	text_draw {
		position = {32, 120, 55, 60},
		text = function()
			if get(show_RXP) == 1 then return "RXP AUTO"
			else return "GNS430 AUTO" end
		end,
		font = text_font,
		font_size = 17,
		bitmap = false,
		color = {0,0,0,1},
		visible = true,
	},
	-- set starter torque
	text_draw {
		position = {507, 52, 55, 60},
		text = function()
			return math.floor(get(starter_torq) *100 + 0.5) / 100
		end,
		font = text_font,
		font_size = 17,
		bitmap = false,
		color = {0,0,0,1},
		visible = true,
	},
	interactive {
		position = {426, 47, 30, 29},
		onMouseDown = function() 
			local a = get(starter_torq) - 0.01
			if a < 0.1 then a = 0.1 end
			set(starter_torq, a)
			set(save_state, 1)
			return true
		end,
	},
	interactive {
		position = {595, 47, 30, 29},
		onMouseDown = function() 
			local a = get(starter_torq) + 0.01
			if a > 1 then a = 1 end
			set(starter_torq, a)
			set(save_state, 1)
			return true
		end,
	},	
	interactive {
		position = {476, 12, 100, 29},
		onMouseDown = function() 
			set(starter_torq, 0.2)
			set(save_state, 1)
			return true
		end,
	},	
	--------------------------------
	-- close button
	interactive {
		position = {size[1] - 15, size[2] - 15, 15, 15 },
		onMouseDown = function() 
			set(show_ground_panel, 0)
			return true
		end,
	}, 
}

function draw()
	drawAll(components)
end
