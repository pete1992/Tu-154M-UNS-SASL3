size = {457, 146.5}

---------------------------------------------------------------------------------
-- Smart Copilot section --
---------------------------------------------------------------------------------
-- Aircraft power bus 
defineProperty("kln_power", globalPropertyi("tu154/custom/kln_power"));

defineProperty("SC_master", globalPropertyi("scp/api/ismaster")) -- status of SmartCopilot

-- Graph serialized string to show flightplan path
defineProperty("sc_graphNAV5Comp", globalPropertys("tu154/custom/xap/KLN90/graphNAV5Comp"))
defineProperty("sc_graphAPT3Comp", globalPropertys("tu154/custom/xap/KLN90/graphAPT3Comp"))
-- Text strings for SmartCopilot sync
defineProperty("sc_gline_1", globalPropertys("tu154/custom/xap/KLN90/gline_1"))
defineProperty("sc_gline_2", globalPropertys("tu154/custom/xap/KLN90/gline_2"))
defineProperty("sc_gline_3", globalPropertys("tu154/custom/xap/KLN90/gline_3"))
defineProperty("sc_gline_4", globalPropertys("tu154/custom/xap/KLN90/gline_4"))
defineProperty("sc_gline_5", globalPropertys("tu154/custom/xap/KLN90/gline_5"))
defineProperty("sc_gline_6", globalPropertys("tu154/custom/xap/KLN90/gline_6"))
defineProperty("sc_gline_7", globalPropertys("tu154/custom/xap/KLN90/gline_7"))
defineProperty("sc_gline_8", globalPropertys("tu154/custom/xap/KLN90/gline_8"))
defineProperty("sc_bline_1", globalPropertys("tu154/custom/xap/KLN90/bline_1"))
defineProperty("sc_bline_2", globalPropertys("tu154/custom/xap/KLN90/bline_2"))
defineProperty("sc_bline_3", globalPropertys("tu154/custom/xap/KLN90/bline_3"))
defineProperty("sc_bline_4", globalPropertys("tu154/custom/xap/KLN90/bline_4"))
defineProperty("sc_bline_5", globalPropertys("tu154/custom/xap/KLN90/bline_5"))
defineProperty("sc_bline_6", globalPropertys("tu154/custom/xap/KLN90/bline_6"))
defineProperty("sc_bline_7", globalPropertys("tu154/custom/xap/KLN90/bline_7"))
defineProperty("sc_bline_8", globalPropertys("tu154/custom/xap/KLN90/bline_8"))
defineProperty("sc_scaleline", globalPropertys("tu154/custom/xap/KLN90/scale_line"))
defineProperty("sc_cage", globalPropertyi("tu154/custom/xap/KLN90/cage"))
-- animation
defineProperty("L_Angle_3D", globalPropertyi("tu154/custom/rotary/KLN90/3D_L_Angle"))
defineProperty("R_Angle_3D", globalPropertyi("tu154/custom/rotary/KLN90/3D_R_Angle"))
defineProperty("power_knob", globalPropertyi("tu154/custom/rotary/KLN90/power_knob"))
defineProperty("power_knob_angle", globalPropertyi("tu154/custom/rotary/KLN90/power_knob_angle"))
defineProperty("scan_knob", globalPropertyi("tu154/custom/rotary/KLN90/scan_knob"))

----------------

defineProperty("bg", sasl.gl.loadImage("KLN90.png", 0, 0, 914, 293))
defineProperty("glass", sasl.gl.loadImage("KLN90.png", 10, 298, 426, 199))
defineProperty("powerknob", sasl.gl.loadImage("KLN90.png", 455, 321, 52, 52))
defineProperty("powerext", sasl.gl.loadImage("KLN90.png", 445, 400, 65, 50))
defineProperty("rknobstex", sasl.gl.loadImage("KLN90.png", 528, 312, 71, 71))
--defineProperty("arrowtex", sasl.gl.loadImage("KLNmap.png", 125, 98, 275, 150))
defineProperty("mapplane", sasl.gl.loadImage("KLNmap.png", 2, 2, 5, 4))
defineProperty("mapstar", sasl.gl.loadImage("KLNmap.png", 16, 2, 5, 5))
defineProperty("mapdiamond", sasl.gl.loadImage("KLNmap.png", 9, 2, 5, 5))
defineProperty("mappixel", sasl.gl.loadImage("KLNmap.png", 4, 10, 1, 1))
defineProperty("mapplus", sasl.gl.loadImage("KLNmap.png", 43, 3, 3, 3))

--defineProperty("mappixel", sasl.gl.loadImage("KLNmap.png", 4, 11, 2, 2))

defineProperty("mapquad", sasl.gl.loadImage("KLNmap.png", 9, 9, 3, 3))
defineProperty("mapAPT", sasl.gl.loadImage("KLNmap.png", 23, 2, 5, 5))
defineProperty("mapNDB", sasl.gl.loadImage("KLNmap.png", 30, 3, 4, 4))
defineProperty("mapVOR", sasl.gl.loadImage("KLNmap.png", 36, 2, 5, 5))

defineProperty("Atex", sasl.gl.loadImage("KLNmap.png", 1, 36, 5, 7))
defineProperty("Btex", sasl.gl.loadImage("KLNmap.png", 7, 36, 5, 7))
defineProperty("Ctex", sasl.gl.loadImage("KLNmap.png", 13, 36, 5, 7))
defineProperty("Dtex", sasl.gl.loadImage("KLNmap.png", 19, 36, 5, 7))
defineProperty("Etex", sasl.gl.loadImage("KLNmap.png", 25, 36, 5, 7))
defineProperty("Ftex", sasl.gl.loadImage("KLNmap.png", 31, 36, 5, 7))
defineProperty("Gtex", sasl.gl.loadImage("KLNmap.png", 37, 36, 5, 7))
defineProperty("Htex", sasl.gl.loadImage("KLNmap.png", 43, 36, 5, 7))
defineProperty("Itex", sasl.gl.loadImage("KLNmap.png", 49, 36, 5, 7))
defineProperty("Jtex", sasl.gl.loadImage("KLNmap.png", 55, 36, 5, 7))
defineProperty("Ktex", sasl.gl.loadImage("KLNmap.png", 61, 36, 5, 7))
defineProperty("Ltex", sasl.gl.loadImage("KLNmap.png", 67, 36, 5, 7))
defineProperty("Mtex", sasl.gl.loadImage("KLNmap.png", 73, 36, 5, 7))
defineProperty("Ntex", sasl.gl.loadImage("KLNmap.png", 79, 36, 5, 7))
defineProperty("Otex", sasl.gl.loadImage("KLNmap.png", 85, 36, 5, 7))
defineProperty("Ptex", sasl.gl.loadImage("KLNmap.png", 91, 36, 5, 7))
defineProperty("Qtex", sasl.gl.loadImage("KLNmap.png", 97, 36, 5, 7))
defineProperty("Rtex", sasl.gl.loadImage("KLNmap.png", 103, 36, 5, 7))
defineProperty("Stex", sasl.gl.loadImage("KLNmap.png", 109, 36, 5, 7))
defineProperty("Ttex", sasl.gl.loadImage("KLNmap.png", 115, 36, 5, 7))
defineProperty("Utex", sasl.gl.loadImage("KLNmap.png", 121, 36, 5, 7))
defineProperty("Vtex", sasl.gl.loadImage("KLNmap.png", 127, 36, 5, 7))
defineProperty("Wtex", sasl.gl.loadImage("KLNmap.png", 133, 36, 5, 7))
defineProperty("Xtex", sasl.gl.loadImage("KLNmap.png", 139, 36, 5, 7))
defineProperty("Ytex", sasl.gl.loadImage("KLNmap.png", 145, 36, 5, 7))
defineProperty("Ztex", sasl.gl.loadImage("KLNmap.png", 151, 36, 5, 7))
defineProperty("ötex", sasl.gl.loadImage("KLNmap.png", 157, 36, 5, 7))
defineProperty("ö0tex", sasl.gl.loadImage("KLNmap.png", 1, 44, 5, 7))
defineProperty("ö1tex", sasl.gl.loadImage("KLNmap.png", 7, 44, 5, 7))
defineProperty("ö2tex", sasl.gl.loadImage("KLNmap.png", 13, 44, 5, 7))
defineProperty("ö3tex", sasl.gl.loadImage("KLNmap.png", 19, 44, 5, 7))
defineProperty("ö4tex", sasl.gl.loadImage("KLNmap.png", 25, 44, 5, 7))
defineProperty("ö5tex", sasl.gl.loadImage("KLNmap.png", 31, 44, 5, 7))
defineProperty("ö6tex", sasl.gl.loadImage("KLNmap.png", 37, 44, 5, 7))
defineProperty("ö7tex", sasl.gl.loadImage("KLNmap.png", 43, 44, 5, 7))
defineProperty("ö8tex", sasl.gl.loadImage("KLNmap.png", 49, 44, 5, 7))
defineProperty("ö9tex", sasl.gl.loadImage("KLNmap.png", 55, 44, 5, 7))

defineProperty("lknobstex", sasl.gl.loadImage("KLN90.png", 528, 392, 71, 71))

defineProperty("cage", sasl.gl.loadImage("KLN90.png", 9, 501, 415, 2))

defineProperty("FPlan_tbl")
defineProperty("values_tbl")
defineProperty("controls_tbl")
defineProperty("gline_tbl")
defineProperty("bline_tbl")

defineProperty("Nav5Comp_tbl")
defineProperty("APT3Comp_tbl")

defineProperty("brightness")
defineProperty("power_val")

local font = sasl.gl.loadBitmapFont('KLN90.fnt')
local fontb = sasl.gl.loadBitmapFont('KLN90_2.fnt')
local fontl = sasl.gl.loadBitmapFont('KLN90_3.fnt')

local brt = 1
local power = 1

-- commands
local KLNpowerc_command = sasl.findCommand("xap/KLN90/Toggle_Power_Switch")
local KLNincbrtc_command = sasl.findCommand("xap/KLN90/Increase_Brightness")
local KLNdecbrtc_command = sasl.findCommand("xap/KLN90/Decrease_Brightness")
local KLNLCRSRc_command = sasl.findCommand("xap/KLN90/Toggle_Left_Cursor")
local KLNRCRSRc_command = sasl.findCommand("xap/KLN90/Toggle_Right_Cursor")
local KLNSCANc_command = sasl.findCommand("xap/KLN90/Toggle_Scan_Mode")
local KLNlknoblccc_command = sasl.findCommand("xap/KLN90/Turn_Left_Large_Knob_Counterclockwise")
local KLNlknobsccc_command = sasl.findCommand("xap/KLN90/Turn_Left_Small_Knob_Counterclockwise")
local KLNlknobscc_command = sasl.findCommand("xap/KLN90/Turn_Left_Small_Knob_Clockwise")
local KLNlknoblcc_command = sasl.findCommand("xap/KLN90/Turn_Left_Large_Knob_Clockwise")
local KLNMSGc_command = sasl.findCommand("xap/KLN90/Toggle_Message_Page")
local KLNALTc_command = sasl.findCommand("xap/KLN90/Toggle_Altitude_Page")
local KLNDTOc_command = sasl.findCommand("xap/KLN90/Toggle_Direct_To_Page")
local KLNCLRc_command = sasl.findCommand("xap/KLN90/Press_CLR")
local KLNENTc_command = sasl.findCommand("xap/KLN90/Press_ENT")
local KLNrknoblccc_command = sasl.findCommand("xap/KLN90/Turn_Right_Large_Knob_Counterclockwise")
local KLNrknobsccc_command = sasl.findCommand("xap/KLN90/Turn_Right_Small_Knob_Counterclockwise")
local KLNrknobscc_command = sasl.findCommand("xap/KLN90/Turn_Right_Small_Knob_Clockwise")
local KLNrknoblcc_command = sasl.findCommand("xap/KLN90/Turn_Right_Large_Knob_Clockwise")

components = {

	textureLit { -- background
		position = {0, 0, 457, 146.5},
		image = get(bg),
	},

	texture {
		position = {386.5, 96.5, 32.5, 25},
		image = get(powerext),
		visible = function()
			return power == 0
		end,
	},
									
	needleLit {
		position = {389.5, 105, 26, 26},
		image = get(powerknob),
		angle = function()
			return brt * 335
		end,
	},
								
	needleLit {
		position = {39.5, 16, 35.5, 35.5},
		image = get(lknobstex),
		angle = function()
			return get(L_Angle_3D) * 10
		end,
	},
							
	needleLit {
		position = {385, 16, 35.5, 35.5},
		image = get(rknobstex),
		angle = function()
			return get(R_Angle_3D) * 10
		end,
	},

	needleLit {
		position = {386, 15, 35.5, 35.5},
		image = get(rknobstex),
		angle = function()
			return get(R_Angle_3D) * 10
		end,
		visible = function()
			return get(scan_knob) == 1
		end,
	},

					textureLit2 {
					position = {125, 55, 208, 1},
					image = get(cage),
					brt2 = function() 
						return brt
					end,
					visible = function()
						if get(SC_master) == 1 then
							return get(sc_cage) == 1
						else
							return get(sc_cage) == 1 --cagevisible == 1
						end	
					end,
				},
	
	textureLit2 {
		position = {125, 55, 208, 1},
		image = get(cage),
		brt2 = function() 
			return brt
		end,
		visible = function()
			return get(sc_cage) == 1
		end,
	},

	---------------------------------------
	-- interactives --
	------------------------------
--[[	
	rectangle {
		position = {55, 10, 22.5, 47.5 },
		color = {1, 0, 0, 1},
	},
--]]
	interactive {
		position = {43.5, 75.5, 25.5, 15 },
				
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  
			
		onMouseHold = function()
			sasl.commandOnce(KLNLCRSRc_command)
			return true
		end  
	},	
		
	interactive {
		position = {388, 75.5, 25.5, 15 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  
		
		onMouseHold = function()
			sasl.commandOnce(KLNRCRSRc_command)
			return true
		end  
	},	

	interactive {
	position = {392, 108, 20, 20 },

	cursor = { 
		x = 16, 
		y = 32,  
		width = 16, 
		height = 16, 
		shape = sasl.gl.loadImage("interactive.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNpowerc_command)
			
			return true
		end  
	},	
	
	interactive {
		position = {368, 107.5, 20, 20 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("rotateleft.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNdecbrtc_command)
			return true
		end  
	},	
	
	interactive {
		position = {418, 107.5, 20, 20 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("rotateright.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNincbrtc_command)
			return true
		end  
	},		
	
	interactive {
		position = {116, 9, 26.5, 15.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNMSGc_command)
			return true
		end  
	},		
	
	interactive {
		position = {165.5, 9, 26.5, 15.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNALTc_command)
			return true
		end  
	},		
	
	interactive {
		position = {215, 9, 26.5, 15.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNDTOc_command)
			return true
		end  
	},		
	
	interactive {
		position = {264.5, 9, 26.5, 15.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNCLRc_command)
			return true
		end  
	},		
	
	interactive {
		position = {314, 9, 26.5, 15.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNENTc_command)
			return true
		end  
	},	
	
	interactive {
		position = {33, 10, 22.5, 47.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("rotateleft2.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNlknobsccc_command)
			return true
		end  
	},	
	
	interactive {
		position = {58, 10, 22.5, 47.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("rotateright2.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNlknobscc_command)
			return true
		end  
	},	
	
	interactive {
		position = {5, 10, 25, 47.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("rotateleft.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNlknoblccc_command)
			return true
		end  
	},	
	
	interactive {
		position = {85, 10, 22.5, 47.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("rotateright.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNlknoblcc_command)
			return true
		end  
	},	

	interactive {
		position = {388, 60, 25.5, 12.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("interactive2.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNSCANc_command)
			
			return true
		end  
	},	
	
	interactive {
		position = {378, 10, 22.5, 47.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("rotateleft2.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNrknobsccc_command)
			return true
		end  
	},	
	
	interactive {
		position = {403, 10, 22.5, 47.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("rotateright2.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNrknobscc_command)
			return true
		end  
	},	
	
	interactive {
		position = {350, 10, 25, 47.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("rotateleft.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNrknoblccc_command)
			return true
		end  
	},	
	
	interactive {
		position = {430, 10, 25, 47.5 },
		
		cursor = { 
			x = 16, 
			y = 32,  
			width = 16, 
			height = 16, 
			shape = sasl.gl.loadImage("rotateright.png")
		},  

		onMouseHold = function()
			sasl.commandOnce(KLNrknoblcc_command)
			return true
		end  
	},	
	
	interactive { -- close button
		position = {size[1] - 10, size[2] - 10, 10, 10},
		
		cursor = { 
		x = 16, 
		y = 32,  
		width = 16, 
		height = 16, 
		shape = sasl.gl.loadImage("interactive.png")
	},  

		onMouseHold = function()
			set(KLN90visible, 0)
			return true
		end
	},		

}

components2 = {
	rectangle2 {
		position = {122, 33, 213, 100},
		color = {0,0.85,0.05},
		brt2 = function() 
			if power == 0 then
				return 0
			else
				return brt / 10
			end
		end,
	},

	texture {

		position = {122, 33, 213, 100},
		image = get(glass),
	},
}

Nav5Comp = {}
APT3Comp = {}

function draw()
	
	local FPlan = get(FPlan_tbl)
	local values = get(values_tbl)
	local controls = get(controls_tbl)
	local gline = get(gline_tbl)
	local bline = get(bline_tbl)
	
	Nav5Comp = get(Nav5Comp_tbl)
	APT3Comp = get(APT3Comp_tbl)
	
	power = get(power_val)	
	brt = get(brightness)
	
	drawAll(components)

	if get(SC_master) == 1 then
	
		drawAll(Nav5Comp)
		drawAll(APT3Comp)
		
		sasl.gl.drawBitmapText(font, 125, 98, get(sc_gline_1), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(font, 125, 87, get(sc_gline_2), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(font, 125, 76, get(sc_gline_3), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(font, 125, 65, get(sc_gline_4), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(font, 125, 54, get(sc_gline_5), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(font, 125, 43, get(sc_gline_6), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(font, 125, 29, get(sc_gline_7), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
	
		sasl.gl.drawBitmapText(fontb, 125, 98, get(sc_bline_1), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(fontb, 125, 87, get(sc_bline_2), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(fontb, 125, 76, get(sc_bline_3), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(fontb, 125, 65, get(sc_bline_4), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(fontb, 125, 54, get(sc_bline_5), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(fontb, 125, 43, get(sc_bline_6), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(fontb, 125, 29, get(sc_bline_7), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		
		sasl.gl.drawBitmapText(fontl, 129.5, 87, get(sc_scaleline), TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
	else
		
		sasl.gl.drawBitmapText(font, 125, 98, gline[1], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(font, 125, 87, gline[2], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(font, 125, 76, gline[3], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(font, 125, 65, gline[4], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(font, 125, 54, gline[5], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(font, 125, 43, gline[6], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(font, 125, 29, gline[7], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
	
		sasl.gl.drawBitmapText(fontb, 125, 98, bline[1], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(fontb, 125, 87, bline[2], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(fontb, 125, 76, bline[3], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(fontb, 125, 65, bline[4], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(fontb, 125, 54, bline[5], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(fontb, 125, 43, bline[6], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		sasl.gl.drawBitmapText(fontb, 125, 29, bline[7], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
		
		sasl.gl.drawBitmapText(fontl, 129.5, 87, values["scaleline"], TEXT_ALIGN_LEFT, {brt, brt, brt, 1})
	end
	--]]
	drawAll(Nav5Comp)
	drawAll(APT3Comp)
	
	drawAll(components2)
	
end

function draw()
	drawAll(components)
end
