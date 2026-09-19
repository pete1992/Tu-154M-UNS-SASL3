-- checklist_panel_2d.lua
-- this is checklist panel
size = {240, 850}

local function defineProps(defs)
    for _, def in ipairs(defs) do
        local prop
        if def[4] ~= nil then
            prop = def[3](def[2], def[4])
        else
            prop = def[3](def[2])
        end
        defineProperty(def[1], prop)
    end
end

defineProps({
    { "hide_eng_objects", "tu154/custom/lang/hide_eng_objects", globalPropertyi }, --    . 1 = RUS

    -- controls
    { "show_checklist_panel", "tu154/custom/panels/show_checklist_panel", globalPropertyi }, --

    { "side", "tu154/custom/checklist/side", globalPropertyi }, --   . 0 -  , 1 -

    { "fishka_1", "tu154/custom/checklist/fishka_1", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_2", "tu154/custom/checklist/fishka_2", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_3", "tu154/custom/checklist/fishka_3", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_4", "tu154/custom/checklist/fishka_4", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_5", "tu154/custom/checklist/fishka_5", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_6", "tu154/custom/checklist/fishka_6", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_7", "tu154/custom/checklist/fishka_7", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_8", "tu154/custom/checklist/fishka_8", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_9", "tu154/custom/checklist/fishka_9", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_10", "tu154/custom/checklist/fishka_10", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_11", "tu154/custom/checklist/fishka_11", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_12", "tu154/custom/checklist/fishka_12", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_13", "tu154/custom/checklist/fishka_13", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_14", "tu154/custom/checklist/fishka_14", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_15", "tu154/custom/checklist/fishka_15", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_16", "tu154/custom/checklist/fishka_16", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_17", "tu154/custom/checklist/fishka_17", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_18", "tu154/custom/checklist/fishka_18", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_19", "tu154/custom/checklist/fishka_19", globalPropertyi }, --  . 0 - , 1 -
    { "fishka_20", "tu154/custom/checklist/fishka_20", globalPropertyi }, --  . 0 - , 1 -

    { "checklist_selected", "tu154/custom/checklist/checklist_selected", globalPropertyi }, --
})

-- images

-- The checklist atlas was authored with Y coordinates measured from the PNG's
-- top edge; SASL 3 loadImage() measures them from the bottom edge.
local CHECKLIST_ATLAS_HEIGHT = 1024

local function checklistAtlasY(top, height)
	return CHECKLIST_ATLAS_HEIGHT - top - height
end

defineProperty("bg_img_0", sasl.gl.loadImage("checklist_tex.png", 0, checklistAtlasY(0, 850), 240, 850))
defineProperty("bg_img_1", sasl.gl.loadImage("checklist_tex.png", 249, checklistAtlasY(0, 850), 240, 850))

defineProperty("bg_img_0_RUS", sasl.gl.loadImage("checklist_tex_RUS.png", 0, checklistAtlasY(0, 850), 240, 850))
defineProperty("bg_img_1_RUS", sasl.gl.loadImage("checklist_tex_RUS.png", 249, checklistAtlasY(0, 850), 240, 850))

defineProperty("fishka_left", sasl.gl.loadImage("checklist_tex.png", 0, checklistAtlasY(859, 25), 166, 25))
defineProperty("fishka_right", sasl.gl.loadImage("checklist_tex.png", 0, checklistAtlasY(887, 25), 166, 25))

components = {

	-- background
	textureLit {
		position = {0, 0, size[1], size[2]},
		image = get(bg_img_0),
		visible = function()
			return get(side) == 0 and get(hide_eng_objects) == 0
		end,
	},	
	textureLit {
		position = {0, 0, size[1], size[2]},
		image = get(bg_img_1),
		visible = function()
			return get(side) == 1 and get(hide_eng_objects) == 0
		end,
	},	

	textureLit {
		position = {0, 0, size[1], size[2]},
		image = get(bg_img_0_RUS),
		visible = function()
			return get(side) == 0 and get(hide_eng_objects) == 1
		end,
	},	
	textureLit {
		position = {0, 0, size[1], size[2]},
		image = get(bg_img_1_RUS),
		visible = function()
			return get(side) == 1 and get(hide_eng_objects) == 1
		end,
	},
	
	---------------------
	-- interactives --
	---------------------
	
	-- change side --
	interactive {
		position = {58, 788, 122, 15},
      
		onMouseDown = function() 
			set(side, 1 - get(side))
			return true
		end,
	},	
	
	-- before start --
	interactive {
		position = {4, 424, 28, 350},
      
		onMouseDown = function() 
			set(fishka_1, 1)
			set(fishka_2, 1)
			set(fishka_3, 1)
			set(fishka_4, 1)
			set(fishka_5, 1)
			set(fishka_6, 1)
			set(fishka_7, 1)
			set(fishka_8, 1)
			set(fishka_9, 1)
			set(fishka_10, 1)
			if get(checklist_selected) ~=1 then set(checklist_selected, 1) end
			return true
		end,
		onMouseUp = function() 
			--set(checklist_selected, 0)
			return true
		end,
		
		visible = function()
			return get(side) == 0
		end,
	},	
	
	-- before taxi --
	interactive {
		position = {4, 57, 28, 350},
      
		onMouseDown = function() 
			set(fishka_11, 1)
			set(fishka_12, 1)
			set(fishka_13, 1)
			set(fishka_14, 1)
			set(fishka_15, 1)
			set(fishka_16, 1)
			set(fishka_17, 1)
			set(fishka_18, 1)
			set(fishka_19, 1)
			set(fishka_20, 1)
			if get(checklist_selected) ~=2 then set(checklist_selected, 2) end
			return true
		end,
		onMouseUp = function() 
			--set(checklist_selected, 0)
			return true
		end,
		visible = function()
			return get(side) == 0
		end,
	},	
	
	-- on taxi --
	interactive {
		position = {207, 688, 28, 91},
      
		onMouseDown = function() 
			set(fishka_1, 0)
			set(fishka_2, 0)
			set(fishka_3, 0)
			if get(checklist_selected) ~=3 then set(checklist_selected, 3) end
			return true
		end,
		onMouseUp = function() 
			--set(checklist_selected, 0)
			return true
		end,
		visible = function()
			return get(side) == 0
		end,
	},	
	
	-- before line up --
	interactive {
		position = {207, 350, 28, 327},
      
		onMouseDown = function() 
			set(fishka_4, 0)
			set(fishka_5, 0)
			set(fishka_6, 0)
			set(fishka_7, 0)
			set(fishka_8, 0)
			set(fishka_9, 0)
			set(fishka_10, 0)
			set(fishka_11, 0)
			set(fishka_12, 0)
			if get(checklist_selected) ~=4 then set(checklist_selected, 4) end
			return true
		end,
		onMouseUp = function() 
			--set(checklist_selected, 0)
			return true
		end,
		visible = function()
			return get(side) == 0
		end,
	},		
	
	-- before take-off --
	interactive {
		position = {207, 48, 28, 289},
      
		onMouseDown = function() 
			set(fishka_13, 0)
			set(fishka_14, 0)
			set(fishka_15, 0)
			set(fishka_16, 0)
			set(fishka_17, 0)
			set(fishka_18, 0)
			set(fishka_19, 0)
			set(fishka_20, 0)
			if get(checklist_selected) ~=5 then set(checklist_selected, 5) end
			return true
		end,
		onMouseUp = function() 
			--set(checklist_selected, 0)
			return true
		end,
		visible = function()
			return get(side) == 0
		end,
	},	
	
	-----------------------------
	
	-- before descend --
	interactive {
		position = {4, 270, 28, 257},
      
		onMouseDown = function() 
			set(fishka_8, 1)
			set(fishka_9, 1)
			set(fishka_10, 1)
			set(fishka_11, 1)
			set(fishka_12, 1)
			set(fishka_13, 1)
			set(fishka_14, 1)
			if get(checklist_selected) ~=6 then set(checklist_selected, 6) end
			return true
		end,
		onMouseUp = function() 
			--set(checklist_selected, 0)
			return true
		end,
		visible = function()
			return get(side) == 1
		end,
	},		
	
	-- after transition level --
	interactive {
		position = {4, 47, 28, 213},
      
		onMouseDown = function() 
			set(fishka_15, 1)
			set(fishka_16, 1)
			set(fishka_17, 1)
			set(fishka_18, 1)
			set(fishka_19, 1)
			set(fishka_20, 1)
			if get(checklist_selected) ~=7 then set(checklist_selected, 7) end
			return true
		end,
		onMouseUp = function() 
			--set(checklist_selected, 0)
			return true
		end,
		visible = function()
			return get(side) == 1
		end,
	},		
		
	-- before base turn --
	interactive {
		position = {207, 462, 28, 315},
      
		onMouseDown = function() 
			set(fishka_1, 0)
			set(fishka_2, 0)
			set(fishka_3, 0)
			set(fishka_4, 0)
			set(fishka_5, 0)
			set(fishka_6, 0)
			set(fishka_7, 0)
			set(fishka_8, 0)
			set(fishka_9, 0)
			if get(checklist_selected) ~=8 then set(checklist_selected, 8) end
			return true
		end,
		onMouseUp = function() 
			--set(checklist_selected, 0)
			return true
		end,
		visible = function()
			return get(side) == 1
		end,
	},		
		
	-- on final --
	interactive {
		position = {207, 50, 28, 396},
      
		onMouseDown = function() 
			set(fishka_10, 0)
			set(fishka_11, 0)
			set(fishka_12, 0)
			set(fishka_13, 0)
			set(fishka_14, 0)
			set(fishka_15, 0)
			set(fishka_16, 0)
			set(fishka_17, 0)
			set(fishka_18, 0)
			set(fishka_19, 0)
			set(fishka_20, 0)
			if get(checklist_selected) ~=9 then set(checklist_selected, 9) end
			return true
		end,
		onMouseUp = function() 
			--set(checklist_selected, 0)
			return true
		end,
		visible = function()
			return get(side) == 1
		end,
	},	
	
	-------------------------
	-- fishki --
	-------------------------
	
	-- fishka 1 --
	switch_lit {
		position = {35, 758, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_1) == 1
		end,
		onMouseDown = function()
			set(fishka_1, 1 - get(fishka_1))
			return true
		end,
	},	
		
	-- fishka 2 --
	switch_lit {
		position = {35, 720, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_2) == 1
		end,
		onMouseDown = function()
			set(fishka_2, 1 - get(fishka_2))
			return true
		end,
	},	
		
	-- fishka 3 --
	switch_lit {
		position = {35, 684, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_3) == 1
		end,
		onMouseDown = function()
			set(fishka_3, 1 - get(fishka_3))
			return true
		end,
	},	
		
	-- fishka 4 --
	switch_lit {
		position = {35, 646, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_4) == 1
		end,
		onMouseDown = function()
			set(fishka_4, 1 - get(fishka_4))
			return true
		end,
	},	
	
	-- fishka 5 --
	switch_lit {
		position = {35, 608, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_5) == 1
		end,
		onMouseDown = function()
			set(fishka_5, 1 - get(fishka_5))
			return true
		end,
	},		
	
	-- fishka 6 --
	switch_lit {
		position = {35, 570, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_6) == 1
		end,
		onMouseDown = function()
			set(fishka_6, 1 - get(fishka_6))
			return true
		end,
	},		
	
	-- fishka 7 --
	switch_lit {
		position = {35, 533, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_7) == 1
		end,
		onMouseDown = function()
			set(fishka_7, 1 - get(fishka_7))
			return true
		end,
	},	

	-- fishka 8 --
	switch_lit {
		position = {35, 495, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_8) == 1
		end,
		onMouseDown = function()
			set(fishka_8, 1 - get(fishka_8))
			return true
		end,
	},

	-- fishka 9 --
	switch_lit {
		position = {35, 457, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_9) == 1
		end,
		onMouseDown = function()
			set(fishka_9, 1 - get(fishka_9))
			return true
		end,
	},
	
	-- fishka 10 --
	switch_lit {
		position = {35, 418, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_10) == 1
		end,
		onMouseDown = function()
			set(fishka_10, 1 - get(fishka_10))
			return true
		end,
	},	
	
	-- fishka 11 --
	switch_lit {
		position = {35, 379, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_11) == 1
		end,
		onMouseDown = function()
			set(fishka_11, 1 - get(fishka_11))
			return true
		end,
	},	

	-- fishka 12 --
	switch_lit {
		position = {35, 342, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_12) == 1
		end,
		onMouseDown = function()
			set(fishka_12, 1 - get(fishka_12))
			return true
		end,
	},

	-- fishka 13 --
	switch_lit {
		position = {35, 305, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_13) == 1
		end,
		onMouseDown = function()
			set(fishka_13, 1 - get(fishka_13))
			return true
		end,
	},

	-- fishka 14 --
	switch_lit {
		position = {35, 267, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_14) == 1
		end,
		onMouseDown = function()
			set(fishka_14, 1 - get(fishka_14))
			return true
		end,
	},

	-- fishka 15 --
	switch_lit {
		position = {35, 229, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_15) == 1
		end,
		onMouseDown = function()
			set(fishka_15, 1 - get(fishka_15))
			return true
		end,
	},

	-- fishka 16 --
	switch_lit {
		position = {35, 193, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_16) == 1
		end,
		onMouseDown = function()
			set(fishka_16, 1 - get(fishka_16))
			return true
		end,
	},

	-- fishka 17 --
	switch_lit {
		position = {35, 154, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_17) == 1
		end,
		onMouseDown = function()
			set(fishka_17, 1 - get(fishka_17))
			return true
		end,
	},

	-- fishka 18 --
	switch_lit {
		position = {35, 117, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_18) == 1
		end,
		onMouseDown = function()
			set(fishka_18, 1 - get(fishka_18))
			return true
		end,
	},

	-- fishka 19 --
	switch_lit {
		position = {35, 80, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_19) == 1
		end,
		onMouseDown = function()
			set(fishka_19, 1 - get(fishka_19))
			return true
		end,
	},

	-- fishka 20 --
	switch_lit {
		position = {35, 44, 166, 25},
		btnOn = get(fishka_right),
		btnOff = get(fishka_left),
		state = function()
			return get(fishka_20) == 1
		end,
		onMouseDown = function()
			set(fishka_20, 1 - get(fishka_20))
			return true
		end,
	},

	--------------------------------

	-- close button
	interactive {
		position = {size[1] - 30, size[2] - 30, 30, 30 },
      
		onMouseDown = function() 
			set(show_checklist_panel, 0)
			
			return true
		end,
	}, 	

}

function draw()
	drawAll(components)
end
