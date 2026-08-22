size = {241, 446}

defineProperty("bg", sasl.gl.loadImage("UPhone.png", 0, 0, 241, 446))
defineProperty("APPS", sasl.gl.loadImage("UPhone.png", 260, 0, 205, 305))
defineProperty("digitsImage", sasl.gl.loadImage("UPhone.png", 493, 0, 14, 280))
defineProperty("uphone_subpanel",globalPropertyi("tu154/custom/panels/show_phone")) --   

local program = 0

components = {
	texture {
		position = {0, 0, 240, 444},
		image = get(bg),
		visible = true
	},
	
	--menu
	interactive {
		position = {71, 19, 99, 40 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  

		onMouseDown = function()
		program = 0
		return true
		end  

	},

	--APPS
	textureLit {
		position = {20, 68, 205, 305},
		image = get(APPS),
		visible = function()
		return program == 0
		end,
	},
	interactive {
		position = {30, 300, 25, 25 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  
		visible = function()
		return program == 0
		end,
		onMouseDown = function()
		program = 1
		return true
		end  
	},
	UHUD {
		position = { 20, 68, 205, 305 },
		visible = function()
		return program == 1
		end,
	},	

	interactive {
		position = {65, 300, 25, 25 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  
		visible = function()
		return program == 0
		end,
		onMouseDown = function()
		program = 2
		return true
		end  
	},	

	UConvert {
		position = { 20, 68, 205, 305 },
		visible = function()
		return program == 2
		end,
	}, 
	interactive {
		position = {100, 300, 25, 25 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  
		visible = function()
		return program == 0
		end,
		onMouseDown = function()
		program = 3
		return true
		end  
	},	

	UTurn {
		position = { 20, 68, 205, 305 },
		visible = function()
		return program == 3
		end,
	}, 
	
	interactive {
		position = {135, 300, 25, 25 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  
		visible = function()
		return program == 0
		end,
		onMouseDown = function()
		program = 4
		return true
		end  
	},	
	
	UMETAR {
		position = { 20, 68, 205, 305 },
		visible = function()
		return program == 4
		end,
	}, 
	
	-- interactive area for closing main menu
	interactive {
		position = { size[1]-20, size[2]-20, 20, 20 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  
		
		onMouseDown = function()
		set(uphone_subpanel, 0 )
		return true
		end
	},
}

function draw()
	drawAll(components)
end
