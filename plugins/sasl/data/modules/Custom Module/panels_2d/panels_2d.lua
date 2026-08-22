-- panels_2d.lua
--[[
Changelog
- Corrected SASL 3 ContextWindow handling: window visibility now uses ContextWindow:setIsVisible().
- Corrected SASL 3 ContextWindow positioning: menu positions now use ContextWindow:setPosition().
- Replaced legacy subpanel parameters resizeProportional/savePosition with SASL 3 proportional/saveState.
- Removed legacy noClose parameters; noDecore already suppresses the standard window decoration.
- Corrected UPhone window movement/resizing options to SASL 3 noMove/noResize parameters.
- Restored the original menu geometry: NAV/SERV/MISC submenus align with their corresponding rows in the extended menu.
- Menu positions are recalculated only when the simulator window height changes.
- Guarded the initial panel scale against a zero/unavailable X-Plane window height so ContextWindows never receive zero-sized render areas.
- Converted the menus.png crop coordinates from image-top Y values to SASL 3's bottom-origin Y values so the menu labels render instead of empty black cells.
- Removed the invalid file-level drawAll(components) call; this file has no top-level components table and ContextWindows render their own child components.
- Preserved all existing panel toggles, SmartCopilot throttle-control button logic, menu actions, and Dataref paths.
]]

size = {2048, 2048}

defineProperty("window_height",globalPropertyi("sim/graphics/view/window_height"))
defineProperty("window_width",globalPropertyi("sim/graphics/view/window_width"))
defineProperty("external",globalPropertyi("sim/graphics/view/view_is_external"))
defineProperty("show_gns",globalPropertyi("tu154/custom/anim/show_gns"))
defineProperty("show_RXP",globalPropertyi("tu154/custom/anim/RXP"))
defineProperty("show_load_panel",globalPropertyi("tu154/custom/panels/show_load_panel")) 
defineProperty("show_absu_panel",globalPropertyi("tu154/custom/panels/show_absu_panel")) 
defineProperty("show_ohvd_panel",globalPropertyi("tu154/custom/panels/show_ohvd_panel")) 
defineProperty("show_nvu_panel",globalPropertyi("tu154/custom/panels/show_nvu_panel")) 
defineProperty("show_checklist_panel",globalPropertyi("tu154/custom/panels/show_checklist_panel")) 
defineProperty("show_ground_panel",globalPropertyi("tu154/custom/panels/show_ground_panel")) 
defineProperty("show_phone",globalPropertyi("tu154/custom/panels/show_phone")) 
defineProperty("show_cam",globalPropertyi("tu154/custom/panels/show_cam")) 
defineProperty("show_palette",globalPropertyi("tu154/custom/panels/show_palette")) 
defineProperty("show_fail_panel",globalPropertyi("tu154/custom/panels/show_fail_panel")) 
defineProperty("KLN90visible", globalPropertyi("tu154/custom/xap/KLN90/visible"))
defineProperty("ismaster", globalPropertyf("scp/api/ismaster")) 
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1")) 
defineProperty("control_thro_other", globalPropertyi("tu154/custom/SC/control_thro_other")) 

local initial_window_height = get(window_height)

-- X-Plane can briefly report 0 while SASL is constructing the module. Passing
-- zero-sized child components to a ContextWindow can crash SASL before Lua has
-- a chance to report an error, so use the original 1024 px reference as a safe
-- startup value and keep every initial render area at a usable size.
if initial_window_height == nil or initial_window_height <= 0 then
	initial_window_height = 1024
end

local coef = (initial_window_height / 1024) * 0.8

if coef < 0.5 then coef = 0.5 end
if coef > 1 then coef = 1 end
defineProperty("closeImage", sasl.gl.loadImage("close.png"))
palette = contextWindow {
	position = { 50, 50, 251 * coef, 305 * coef };
	visible = false;
	noDecore = true;
	noBackground = true;
	proportional = true;
	saveState = true;
	name = "palette";	
	components = {
		palette_2d {
			position = { 0, 0, 251 * coef, 305 * coef },
		};
		textureLit {
			position = { 251 * coef - 15, 305 * coef - 15, 15, 15 },
			image = get(closeImage),
		};
	};
}

payload_panel = contextWindow {
	position = { 50, 50, 1024 * coef, 683 * coef };
	visible = false;
	noDecore = true;
	noBackground = true;
	proportional = true;
	saveState = true;
	name = "payload_panel";	
	components = {
		load_panel {
			position = { 0, 0, 1024 * coef, 683 * coef },
		};
		textureLit {
			position = { 1024 * coef - 15, 683 * coef - 15, 15, 15 },
			image = get(closeImage),
		};
	};
}

absu_2d_panel = contextWindow {
	position = { 50, 50, 917 * coef, 597 * coef };
	visible = false;
	noDecore = true;
	noBackground = true;
	proportional = true;
	saveState = true;
	name = "absu_2d_panel";	
	components = {
		absu_panel_2d {
			position = { 0, 0, 917 * coef, 597 * coef },
		};
		textureLit {
			position = { 917 * coef - 15, 597 * coef - 15, 15, 15 },
			image = get(closeImage),
		};
	};
}

ovhd_2d_panel = contextWindow {
	position = { 50, 0, 1458 * coef, 1013 * coef };
	visible = false;
	noDecore = true;
	noBackground = true;
	proportional = true;
	saveState = true;
	name = "ovhd_2d_panel";	
	components = {
		overhead_2d {
			position = { 0, 0, 1458 * coef, 1013 * coef },
		};
		textureLit {
			position = { 1458 * coef - 15, 1013 * coef - 15, 15, 15 },
			image = get(closeImage),
		};
	};
}
nvu_2D_panel = contextWindow {
	position = { 50, 0, 636 * coef, 786 * coef };
	visible = false;
	noDecore = true;
	noBackground = false;
	proportional = true;
	saveState = true;
	name = "nvu_2D_panel";	
	components = {
		nvu_panel_2d {
			position = { 0, 0, 636 * coef, 786 * coef },
		};
		textureLit {
			position = { 636 * coef - 15, 786 * coef - 15, 15, 15 },
			image = get(closeImage),
		};
	};
}
checklist_panel = contextWindow {
	position = { 50, 50, 240 * coef, 850 * coef };
	visible = false;
	noDecore = true;
	noBackground = true;
	proportional = true;
	saveState = true;
	name = "checklist_panel_2d";	
	components = {
		checklist_panel_2d {
			position = { 0, 0, 240 * coef, 850 * coef },
		};
		textureLit {
			position = { 240 * coef - 15, 850 * coef - 15, 15, 15 },
			image = get(closeImage),
		};
	};
}
ground_srv_panel = contextWindow {
	position = { 50, 50, 655 * coef, 880 * coef };
	visible = false;
	noDecore = true;
	noBackground = true;
	proportional = true;
	saveState = true;
	name = "ground_srv_panel";	
	components = {
		ground_panel {
			position = { 0, 0, 655 * coef, 880 * coef },
		};
		textureLit {
			position = { 655 * coef - 15, 880 * coef - 15, 15, 15 },
			image = get(closeImage),
		};
	};
}
uphone = contextWindow {
    position = { 40, 20, 241 * coef , 446 * coef };
	visible = false;
    noDecore = true;
    noBackground = true;
	noMove = false;
	noResize = false;
	proportional = true;
	saveState = true;
	name = "uphone";
    components = {
		UPhone {
         position = { 0, 0, 241 * coef, 446 * coef  },
         };
		textureLit {
 		 position = {(241 - 16) * coef , (446 - 16) * coef , 16 * coef , 16 * coef },
		 image = get(closeImage),
		 };
	};
}
camera_panel = contextWindow {
	position = { 50, 50, 512 * coef, 512 * coef };
	visible = false;
	noDecore = true;
	noBackground = true;
	proportional = true;
	saveState = true;
	name = "camera_panel";	
	components = {
		camera {
			position = { 0, 0, 512 * coef, 512 * coef },
		};
		textureLit {
			position = { 512 * coef - 15, 512 * coef - 15, 15, 15 },
			image = get(closeImage),
		};
	};
}
fails_panel = contextWindow {
	position = { 50, 100, 512 * coef, 700 * coef };
	visible = false;
	noDecore = true;
	noBackground = true;
	proportional = true;
	saveState = false;
	name = "fails_panel";	
	components = {
		failures_2d {
			position = { 0, 0, 512 * coef, 700 * coef },
		};
		textureLit {
			position = { 512 * coef - 15, 700 * coef - 15, 15, 15 },
			image = get(closeImage),
		};
	};
}
local MENU_TEXTURE_HEIGHT = 256

-- The sprite positions below were authored from the top edge of menus.png,
-- while SASL 3 loadImage() measures Y from the bottom edge of the texture.
local function menuTextureY(top, height)
	return MENU_TEXTURE_HEIGHT - top - height
end

defineProperty("menu_wt", sasl.gl.loadImage("menus.png", 0, menuTextureY(0, 30), 31, 30))
defineProperty("menu_gr", sasl.gl.loadImage("menus.png", 30, menuTextureY(0, 30), 31, 30))
defineProperty("menu_ex_wt", sasl.gl.loadImage("menus.png", 0, menuTextureY(30, 90), 31, 90))
defineProperty("nav_ext_gr", sasl.gl.loadImage("menus.png", 30, menuTextureY(30, 30), 31, 30))
defineProperty("serv_ext_gr", sasl.gl.loadImage("menus.png", 30, menuTextureY(60, 30), 31, 30))
defineProperty("misc_ext_gr", sasl.gl.loadImage("menus.png", 30, menuTextureY(90, 30), 31, 30))
defineProperty("nav_menu_wt", sasl.gl.loadImage("menus.png", 60, menuTextureY(29, 31), 121, 31))
defineProperty("serv_menu_wt", sasl.gl.loadImage("menus.png", 60, menuTextureY(59, 31), 61, 31))
defineProperty("misc_menu_wt", sasl.gl.loadImage("menus.png", 60, menuTextureY(89, 31), 121, 31))
defineProperty("thro_red", sasl.gl.loadImage("menus.png", 90, menuTextureY(0, 30), 31, 30))
defineProperty("thro_grn", sasl.gl.loadImage("menus.png", 120, menuTextureY(0, 30), 31, 30))

local main_menu_ext = false
local nav_ext = false
local serv_ext = false
local misc_ext = false

-- UI layout constants.
local MAIN_W, MAIN_H = 31, 30
local EXT_W, EXT_H = 31, 90
local NAV_W, NAV_H = 121, 31
local SERV_W, SERV_H = 61, 31
local MISC_W, MISC_H = 121, 31

local last_window_height = -1

local function clamp(value, minimum, maximum)
	if value < minimum then return minimum end
	if value > maximum then return maximum end
	return value
end

local function updateMenuLayout()
	local wh = get(window_height)

	-- ContextWindows are already created before update() starts.
	-- Reposition them only when the simulator window size actually changes.
	if wh == last_window_height or wh <= 0 then
		return
	end
	last_window_height = wh

	-- Keep the main menu vertically centered at the left screen edge.
	local main_y = clamp(wh * 0.5 - MAIN_H * 0.5, 0, math.max(0, wh - MAIN_H))

	-- Preserve the original menu geometry:
	-- extended menu directly below the main button, with each submenu aligned
	-- to the matching NAV / SERV / MISC row.
	local ext_y = clamp(main_y - EXT_H, 0, math.max(0, wh - EXT_H))
	local nav_y = clamp(ext_y + 60, 0, math.max(0, wh - NAV_H))
	local serv_y = clamp(ext_y + 30, 0, math.max(0, wh - SERV_H))
	local misc_y = clamp(ext_y, 0, math.max(0, wh - MISC_H))

	main_menu:setPosition(0, main_y, MAIN_W, MAIN_H)
	ext_menu:setPosition(0, ext_y, EXT_W, EXT_H)
	nav_menu:setPosition(30, nav_y, NAV_W, NAV_H)
	serv_menu:setPosition(30, serv_y, SERV_W, SERV_H)
	misc_menu:setPosition(30, misc_y, MISC_W, MISC_H)

	-- Keep the SmartCopilot throttle-control button above the main menu.
	local thro_y = clamp(main_y + MAIN_H + 10, 0, math.max(0, wh - 30))
	thro_button:setPosition(0, thro_y, 31, 30)
end

local function setWindowVisible(window, visible)
	if window:isVisible() ~= visible then
		window:setIsVisible(visible)
	end
end

nav_menu = contextWindow {
	position = { 30, 570, 121, 31 };
	visible = false;
	noDecore = true;
	noBackground = false;
	noResize = true;
	noMove = true;
	components = {
		textureLit {
			position = { 0, 0, 121, 31 };
			image = get(nav_menu_wt);
		},
		interactive { 
			position = {90, 0, 31, 31 },
			onMouseDown = function() 
				if get(show_gns) == 1 then  
					sasl.commandOnce(sasl.findCommand("sim/GPS/g430n1_popup"))
					set(KLN90visible, 0)
				elseif get(show_gns) == 0 then 
					set(KLN90visible, 1 - get(KLN90visible))
				else set(KLN90visible, 0) 
				end
				return true
			end,
		},
		interactive { 
			position = {60, 0, 31, 31 },
			onMouseDown = function() 
				set(show_ohvd_panel, 1 - get(show_ohvd_panel))
				return true
			end,
		},
		interactive { 
			position = {30, 0, 31, 31 },
			onMouseDown = function() 
				set(show_absu_panel, 1 - get(show_absu_panel))
				return true
			end,
		},		
		interactive { 
			position = {0, 0, 31, 31 },
			onMouseDown = function() 
				set(show_nvu_panel, 1 - get(show_nvu_panel))
				return true
			end,
		},		
	};
}
serv_menu = contextWindow {
	position = { 30, 540, 61, 31 };
	visible = false;
	noDecore = true;
	noBackground = false;
	noResize = true;
	noMove = true;
	components = {
		textureLit {
			position = { 0, 0, 61, 31 };
			image = get(serv_menu_wt);
		},
		interactive {
			position = {0, 0, 31, 31 },
			onMouseDown = function() 
				set(show_load_panel, 1 - get(show_load_panel))
				return true
			end,
		},
		interactive {
			position = {30, 0, 31, 31 },
			onMouseDown = function() 
				set(show_ground_panel, 1 - get(show_ground_panel))
				return true
			end,
		},		
	};
}
misc_menu = contextWindow {
	position = { 30, 510, 121, 31 };
	visible = false;
	noDecore = true;
	noBackground = false;
	noResize = true;
	noMove = true;
	components = {
		textureLit {
			position = { 0, 0, 121, 31 };
			image = get(misc_menu_wt);
		},
		interactive {
			position = {60, 0, 31, 31 },
			onMouseDown = function() 
				set(show_checklist_panel, 1 - get(show_checklist_panel))
				return true
			end,
		},
		interactive {
			position = {30, 0, 31, 31 },
			onMouseDown = function() 
				set(show_phone, 1 - get(show_phone))
				return true
			end,
		},
		interactive {
			position = {0, 0, 31, 31 },
			onMouseDown = function() 
				set(show_cam, 1 - get(show_cam))
				return true
			end,
		},
		interactive {
			position = {90, 0, 31, 31 },
			onMouseDown = function() 
				set(show_palette, 1 - get(show_palette))
				return true
			end,
		},
	};
}
ext_menu = contextWindow {
	position = { 0, 510, 31, 90 };
	visible = false;
	noDecore = true;
	noBackground = false;
	noResize = true;
	noMove = true;
	components = {
		textureLit {
			position = { 0, 0, 31, 90 };
			image = get(menu_ex_wt);
		},
		textureLit {
			position = { 0, 60, 31, 30 };
			image = get(nav_ext_gr);
			visible = function()
				return nav_ext
			end;
		},		
		textureLit {
			position = { 0, 30, 31, 30 };
			image = get(serv_ext_gr);
			visible = function()
				return serv_ext
			end;
		},		
		textureLit {
			position = { 0, 0, 31, 30 };
			image = get(misc_ext_gr);
			visible = function()
				return misc_ext
			end;
		},	
		interactive {
			position = {0, 60, 31, 30 },
			onMouseDown = function() 
				nav_ext = not nav_ext
				return true
			end,
		},
		interactive {
			position = {0, 30, 31, 30 },
			onMouseDown = function() 
				serv_ext = not serv_ext
				return true
			end,
		},
		interactive {
			position = {0, 0, 31, 30 },
			onMouseDown = function() 
				misc_ext = not misc_ext
				return true
			end,
		},
	};
}
main_menu = contextWindow {
	position = { 0, 600, 31, 30 };
	visible = true;
	noDecore = true;
	noBackground = false;
	noResize = true;
	noMove = true;
	components = {
		textureLit {
			position = { 0, 0, 31, 30 };
			image = get(menu_wt);
		},
		textureLit {
			position = { 0, 0, 31, 30 };
			image = get(menu_gr);
			visible = function()
				return main_menu_ext
			end;
		},	
		interactive {
			position = {0, 0, 31, 30 },
			onMouseDown = function() 
				main_menu_ext = not main_menu_ext
				return true
			end,
		},
	};
}
thro_button = contextWindow {
	position = { 0, 640, 31, 30 };
	visible = false;
	noDecore = true;
	noBackground = false;
	noResize = true;
	noMove = true;
	components = {
		textureLit {
			position = { 0, 0, 31, 30 };
			image = get(thro_red);
			visible = function()
				return (get(hascontrol_1) == 2 and get(control_thro_other) == 1) or (get(hascontrol_1) == 1 and get(control_thro_other) == 0)
			end;
		},
		textureLit {
			position = { 0, 0, 31, 30 };
			image = get(thro_grn);
			visible = function()
				return (get(hascontrol_1) == 2 and get(control_thro_other) == 0) or (get(hascontrol_1) == 1 and get(control_thro_other) == 1)
			end;
		},	
		interactive {
			position = {0, 0, 31, 30 },
			onMouseDown = function() 
				set(control_thro_other, 1 - get(control_thro_other))
				return true
			end,
		},
	};
}

function update()
	updateMenuLayout()

	setWindowVisible(main_menu, true)
	setWindowVisible(ext_menu, main_menu_ext)
	setWindowVisible(nav_menu, main_menu_ext and nav_ext)
	setWindowVisible(serv_menu, main_menu_ext and serv_ext)
	setWindowVisible(misc_menu, main_menu_ext and misc_ext)

	setWindowVisible(payload_panel, get(show_load_panel) == 1)
	setWindowVisible(absu_2d_panel, get(show_absu_panel) == 1)
	setWindowVisible(ovhd_2d_panel, get(show_ohvd_panel) == 1)
	setWindowVisible(nvu_2D_panel, get(show_nvu_panel) == 1)
	setWindowVisible(checklist_panel, get(show_checklist_panel) == 1)
	setWindowVisible(ground_srv_panel, get(show_ground_panel) == 1)
	setWindowVisible(uphone, get(show_phone) == 1)
	setWindowVisible(camera_panel, get(show_cam) == 1)
	setWindowVisible(palette, get(show_palette) == 1)
	setWindowVisible(fails_panel, get(show_fail_panel) == 1)
	setWindowVisible(thro_button, get(ismaster) > 0)
end
