-- palette_2d.lua
-- Tu-154 takeoff, approach and weight/CG reference palette.

size = {251, 305}

defineProperty("show_palette", globalPropertyi("tu154/custom/panels/show_palette")) -- Palette visibility

defineProperty("payload", globalPropertyf("sim/flightmodel/weight/m_fixed")) -- Payload weight, kg
defineProperty("CG_load", globalPropertyf("sim/flightmodel/misc/cgz_ref_to_default")) -- CG offset from default reference, m
defineProperty("fuel_q_1", globalProperty("sim/flightmodel/weight/m_fuel[0]")) -- Fuel quantity, tank 1
defineProperty("fuel_q_4", globalProperty("sim/flightmodel/weight/m_fuel[1]")) -- Fuel quantity, tank 4
defineProperty("fuel_q_2R", globalProperty("sim/flightmodel/weight/m_fuel[2]")) -- Fuel quantity, tank 2 right
defineProperty("fuel_q_2L", globalProperty("sim/flightmodel/weight/m_fuel[3]")) -- Fuel quantity, tank 2 left
defineProperty("fuel_q_3R", globalProperty("sim/flightmodel/weight/m_fuel[4]")) -- Fuel quantity, tank 3 right
defineProperty("fuel_q_3L", globalProperty("sim/flightmodel/weight/m_fuel[5]")) -- Fuel quantity, tank 3 left

defineProperty("gear1_deflect", globalProperty("sim/flightmodel2/gear/tire_vertical_deflection_mtr[0]"))

-- Panel image resources.
local bg_img1 = loadImage("palette.png", 0, 0, 251, 305)
local bg_img2 = loadImage("palette.png", 250, 0, 251, 305)

defineProperty("cg_pos_actual", globalProperty("tu154/custom/misc/cg_pos_actual"))
defineProperty("weight_actual", globalProperty("tu154/custom/misc/weight_actual"))

-- save results
defineProperty("v1_15", globalPropertyi("tu154/custom/speeds/v1_15"))
defineProperty("vr_15", globalPropertyi("tu154/custom/speeds/vr_15"))
defineProperty("v2_15", globalPropertyi("tu154/custom/speeds/v2_15"))
defineProperty("v1_28", globalPropertyi("tu154/custom/speeds/v1_28"))
defineProperty("vr_28", globalPropertyi("tu154/custom/speeds/vr_28"))
defineProperty("v2_28", globalPropertyi("tu154/custom/speeds/v2_28"))
-- Converts aircraft weight and loading index to center of gravity in percent MAC.
local function calc_CG(weight, index)
	
	local MID_CG = 40 -- %MAC at the diagram centerline
	local MID_CG_POS = 60 -- Loading index at the diagram centerline
	local MIN_WEIGHT = 54000 -- Minimum diagram weight, kg
	local MAX_WEIGHT = 74000 -- Maximum diagram weight, kg
	local MAX_WEIGHT_POS = 1 -- Relative maximum-weight position on the diagram
	local MIN_CG = 22 -- Minimum CG shown on the diagram
	local MIN_CG_LOW_POS = MID_CG_POS - 34.3 -- Minimum-CG loading index at low weight
	local MIN_CG_HIGH_POS = MID_CG_POS - 24.8 -- Minimum-CG loading index at high weight
	
	-- Calculate relative weight position on the diagram.
	local z = (weight - MIN_WEIGHT) * MAX_WEIGHT_POS / (MAX_WEIGHT - MIN_WEIGHT)  
	
	-- Calculate CG loading index relative to the centerline.
	local b = ((MID_CG_POS - index) * MIN_CG_LOW_POS * MAX_WEIGHT_POS) / (z * MIN_CG_HIGH_POS - z * MIN_CG_LOW_POS + MIN_CG_LOW_POS * MAX_WEIGHT_POS)
	
	-- Convert loading index to CG in percent MAC.
	local result_CG = MID_CG - b * (MID_CG - MIN_CG) / MIN_CG_LOW_POS

	return result_CG

end

-- Converts aircraft weight and center of gravity in percent MAC to loading index.
local function calc_idx(weight, CG)
	
	local MID_CG = 40 -- %MAC at the diagram centerline
	local MID_CG_POS = 60 -- Loading index at the diagram centerline
	local MIN_WEIGHT = 54000 -- Minimum diagram weight, kg
	local MAX_WEIGHT = 74000 -- Maximum diagram weight, kg
	local MAX_WEIGHT_POS = 1 -- Relative maximum-weight position on the diagram
	local MIN_CG = 22 -- Minimum CG shown on the diagram
	local MIN_CG_LOW_POS = MID_CG_POS - 34.3 -- Minimum-CG loading index at low weight
	local MIN_CG_HIGH_POS = MID_CG_POS - 24.8 -- Minimum-CG loading index at high weight
	
	-- Calculate relative weight position on the diagram.
	local z = (weight - MIN_WEIGHT) * MAX_WEIGHT_POS / (MAX_WEIGHT - MIN_WEIGHT)  
	
	-- Calculate relative CG position.
	-- local CG = MID_CG - b * (MID_CG - MIN_CG) / MIN_CG_LOW_POS
	
	local b = (MID_CG - CG) * MIN_CG_LOW_POS / (MID_CG - MIN_CG)
	
	-- Calculate loading index.
	local index = MID_CG_POS - b * (z * MIN_CG_HIGH_POS - z * MIN_CG_LOW_POS + MIN_CG_LOW_POS * MAX_WEIGHT_POS) / (MIN_CG_LOW_POS * MAX_WEIGHT_POS)

	return index

end

-- tables
local V1_28_tbl = {
	{70, 205},
	{75, 210},
	{80, 220},
	{85, 230},
	{90, 235},
	{95, 240},
	{100, 250}
}

local Vr_28_tbl = {
	{70, 215},
	{75, 220},
	{80, 230},
	{85, 240},
	{90, 245},
	{95, 250},
	{100, 260}
}

local V2_28_tbl = {
	{70, 235},
	{75, 245},
	{80, 250},
	{85, 260},
	{90, 270},
	{95, 275},
	{100, 280}
}
--[[
local Vfl_15_tbl = {
	{70, 255},
	{75, 265},
	{80, 275},
	{85, 280},
	{90, 290},
	{95, 300},
	{100, 305}
}
--]]
-- Flaps-up limit reference table. Currently not used by the display logic.
local Vfl_0_tbl = {
	{70, 360},
	{95, 360},
	{100, 365}
}

local V1_15_tbl = {
	{70, 220},
	{75, 230},
	{80, 235},
	{85, 245},
	{90, 250},
	{95, 260},
	{100, 270}
}

local Vr_15_tbl = {
	{70, 230},
	{75, 240},
	{80, 245},
	{85, 255},
	{90, 260},
	{95, 270},
	{100, 280}
}

local V2_15_tbl = {
	{70, 270},
	{75, 280},
	{80, 285},
	{85, 295},
	{90, 305},
	{95, 315},
	{100, 320}
}

local Vapp_f0_tbl = {
	{60, 318},
	{65, 332},
	{70, 344},
	{75, 356},
	{80, 368},
	{85, 380},
	{90, 401}
}

local Vapp_f15_tbl = {
	{60, 251},
	{65, 261},
	{70, 270},
	{75, 280},
	{80, 288},
	{85, 297},
	{90, 305}
}

local Vapp_f28_tbl = {
	{60, 236},
	{65, 247},
	{70, 255},
	{75, 265},
	{80, 273},
	{85, 282},
	{90, 288}
}

local Vapp_f36_tbl = {
	{60, 232},
	{65, 242},
	{70, 250},
	{75, 260},
	{80, 268},
	{85, 276},
	{90, 283}
}

local Vapp_f45_tbl = {
	{60, 230},
	{65, 240},
	{70, 247},
	{75, 257},
	{80, 265},
	{85, 272},
	{90, 280}
}

local show_side = 0

local show_weight = 0
local CG_show = 0

local show_V1_28 = "---"
local show_Vr_28 = "---"
local show_V2_28 = "---"
local show_Vfl_15_28 = 330
local show_Vfl_0 = 360

local show_V1_15 = "---"
local show_Vr_15 = "---"
local show_V2_15 = "---"

local show_Vapp_0 = "---"
local show_Vapp_15 = "---"
local show_Vapp_28 = "---"
local show_Vapp_36 = "---"
local show_Vapp_45 = "---"

local CG_shifted = false
local CG_return = false

if get(gear1_deflect) > 0 then
	CG_shifted = false
	CG_return = true
else 
	CG_shifted = true
	CG_return = false
end

-- Updates aircraft weight, CG and reference speeds displayed on the palette.
function update()
	
	-- Calculate current zero-fuel weight and zero-fuel CG.
	local current_ZFW = get(payload) + 54865
	local current_ZFW_CG = ((get(CG_load) + 0.2) * 100 / 5.28) + 25
	
	local gear_press = get(gear1_deflect) > 0
	
	if gear_press then current_ZFW_CG = ((get(CG_load)) * 100 / 5.28) + 25 end
	
	-- Apply the existing ground/flight CG reference shift.
	if not gear_press and not CG_shifted then
		set(CG_load, get(CG_load) - 0.2)
		CG_shifted = true
		CG_return = false
	elseif gear_press and not CG_return then
		set(CG_load, get(CG_load) + 0.2)
		CG_shifted = false
		CG_return = true
	end
	
	-- Read fuel quantities and calculate current loaded weight and CG.
	local tank1 = get(fuel_q_1)
	local tank4 = get(fuel_q_4)
	local tank2L = get(fuel_q_2L)
	local tank2R = get(fuel_q_2R)
	local tank3L = get(fuel_q_3L)
	local tank3R = get(fuel_q_3R)
	
	local index = {
		["tank_1_idx"] = -0.0011993,
		["tank_2_idx"] = -0.0000509,
		["tank_3_idx"] = 0.0014161,
		["tank_4_idx"] = -0.00194
	}	
	
	local current_weight = current_ZFW + tank1 + tank4 + tank2L + tank2R + tank3L + tank3R
	
	-- Calculate zero-fuel loading index.
	
	local ZFW_idx = calc_idx(current_ZFW, current_ZFW_CG)
	
	local current_idx = ZFW_idx + index["tank_1_idx"] * tank1 + index["tank_2_idx"] * (tank2L + tank2R) + index["tank_3_idx"] * (tank3L + tank3R) + index["tank_4_idx"] * tank4

	local current_CG = calc_CG(current_weight, current_idx)
	
	-- Calculate values shown on the palette.
	show_weight = math.floor(current_weight / 100) / 10
	CG_show = math.floor(current_CG * 10) / 10
	
	if show_weight >= 70 and show_weight <= 100 then
		show_V1_28 = math.floor(interpolate(V1_28_tbl, show_weight))
		show_Vr_28 = math.floor(interpolate(Vr_28_tbl, show_weight))
		show_V2_28 = math.floor(interpolate(V2_28_tbl, show_weight))
		--show_Vfl_15_28 = math.floor(interpolate(Vfl_15_tbl, show_weight))
		--show_Vfl_0 = math.floor(interpolate(Vfl_0_tbl, show_weight))
		
		show_V1_15 = math.floor(interpolate(V1_15_tbl, show_weight))
		show_Vr_15 = math.floor(interpolate(Vr_15_tbl, show_weight))
		show_V2_15 = math.floor(interpolate(V2_15_tbl, show_weight))
		
	elseif show_weight < 70 then
		show_V1_28 = 205
		show_Vr_28 = 215
		show_V2_28 = 235
		--show_Vfl_15_28 = 255
		--show_Vfl_0 = 305
		
		show_V1_15 = 220
		show_Vr_15 = 230
		show_V2_15 = 270

	end	
	
	if show_weight >= 60 and show_weight <= 100 then
		show_Vapp_0 = math.floor(interpolate(Vapp_f0_tbl, show_weight))
		show_Vapp_15 = math.floor(interpolate(Vapp_f15_tbl, show_weight))
		show_Vapp_28 = math.floor(interpolate(Vapp_f28_tbl, show_weight))
		show_Vapp_36 = math.floor(interpolate(Vapp_f36_tbl, show_weight))
		show_Vapp_45 = math.floor(interpolate(Vapp_f45_tbl, show_weight))
	
	elseif show_weight < 60 then
		show_Vapp_0 = 318
		show_Vapp_15 = 251
		show_Vapp_28 = 236
		show_Vapp_36 = 232
		show_Vapp_45 = 230

	end
	
	set(cg_pos_actual, current_CG)
	set(weight_actual, current_weight)
	
	set(v1_15, show_V1_15)
	set(vr_15, show_Vr_15)
	set(v2_15, show_V2_15)
	set(v1_28, show_V1_28)
	set(vr_28, show_Vr_28)
	set(v2_28, show_V2_28)
	
end

components = {
	
	-- Background textures.
	textureLit {
		position = {0, 0, size[1], size[2]},
		image = bg_img1,
		visible = function()
			return show_side == 0
		end,
	},

	textureLit {
		position = {0, 0, size[1], size[2]},
		image = bg_img2,
		visible = function()
			return show_side == 1
		end,
	},

	-- Panel controls.
	interactive {
		position = {size[1]-15, size[2]-15, 15, 15 },
      
		onMouseDown = function()
			set(show_palette, 0)
			return true
		end,
	},

	-- Switch between takeoff and approach reference pages.
	interactive {
		position = {51, 281, 153, 21 },
      
		onMouseDown = function()
			show_side = 1 - show_side
			return true
		end,
	},

	-- Displayed values.
	
	-- Current aircraft weight.
	text_draw {
		position = {155, 264, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_weight
		end,
	},
	
	-- Current center of gravity.
	text_draw {
		position = {155, 244, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return CG_show
		end,
	},

	-- V1 15
	text_draw {
		position = {155, 184, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_V1_15
		end,
		visible = function()
			return show_side == 0
		end,
	},

	-- Vr 15
	text_draw {
		position = {155, 164, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_Vr_15
		end,
		visible = function()
			return show_side == 0
		end,
	},
	
	-- V2 15
	text_draw {
		position = {155, 144, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_V2_15
		end,
		visible = function()
			return show_side == 0
		end,
	},	
	
	-- Vfl 0 15
	text_draw {
		position = {155, 124, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_Vfl_0
		end,
		visible = function()
			return show_side == 0
		end,
	},	
	-- V1 28
	text_draw {
		position = {155, 84, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_V1_28
		end,
		visible = function()
			return show_side == 0
		end,
	},	
	
	-- Vr 28
	text_draw {
		position = {155, 64, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_Vr_28
		end,
		visible = function()
			return show_side == 0
		end,
	},	
	
	-- V2 28
	text_draw {
		position = {155, 44, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_V2_28
		end,
		visible = function()
			return show_side == 0
		end,
	},	
	
	-- Vfl 15
	text_draw {
		position = {155, 24, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_Vfl_15_28
		end,
		visible = function()
			return show_side == 0
		end,
	},	
	
	-- Vfl 0
	text_draw {
		position = {155, 4, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_Vfl_0
		end,
		visible = function()
			return show_side == 0
		end,
	},
	
	-- Vapp flaps 0
	text_draw {
		position = {155, 184, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_Vapp_0
		end,
		visible = function()
			return show_side == 1
		end,
	},	
	
	-- Vapp flaps 15
	text_draw {
		position = {155, 164, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_Vapp_15
		end,
		visible = function()
			return show_side == 1
		end,
	},	
	
	-- Vapp flaps 28
	text_draw {
		position = {155, 144, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_Vapp_28
		end,
		visible = function()
			return show_side == 1
		end,
	},	
	
	-- Vapp flaps 36
	text_draw {
		position = {155, 124, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_Vapp_36
		end,
		visible = function()
			return show_side == 1
		end,
	},	
	
	-- Vapp flaps 45
	text_draw {
		position = {155, 104, 50, 50},
		color = {0, 0, 0, 1},
		text = function()
			return show_Vapp_45
		end,
		visible = function()
			return show_side == 1
		end,
	},	
}

-- Draws all child components of the palette.
function draw()
	drawAll(components)
end
