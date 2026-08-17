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
defineProperty("control_thro_other", globalPropertyf("tu154/custom/SC/control_thro_other")) 

local coef = (get(window_height) / 1024) * 0.8

if coef > 1 then coef = 1 end  
defineProperty("closeImage", loadImage("close.png"))  
palette = contextWindow {
	position = { 50, 50, 251 * coef, 305 * coef };
	noDecore = true;
	noBackground = true;
	noClose = true;
	resizeProportional = true;
	savePosition = true;
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
	noDecore = true;
	noBackground = true;
	noClose = true;
	resizeProportional = true;
	savePosition = true;
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
	noDecore = true;
	noBackground = true;
	noClose = true;
	resizeProportional = true;
	savePosition = true;
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
	noDecore = true;
	noBackground = true;
	noClose = true;
	resizeProportional = true;
	savePosition = true;
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
	noDecore = true;
	noBackground = false;
	noClose = true;
	resizeProportional = true;
	savePosition = true;
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
	noDecore = true;
	noBackground = true;
	noClose = true;
	resizeProportional = true;
	savePosition = true;
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
	noDecore = true;
	noBackground = true;
	noClose = true;
	resizeProportional = true;
	savePosition = true;
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
    noDecore = true;
    noBackground = true;
    noClose = true;
	movable = true;
	resizeble = true;
	resizeProportional = true;
	savePosition = true;
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
	noDecore = true;
	noBackground = true;
	noClose = true;
	resizeProportional = true;
	savePosition = true;
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
	noDecore = true;
	noBackground = true;
	noClose = true;
	resizeProportional = true;
	savePosition = false;
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
defineProperty("menu_wt", loadImage("menus.png", 0, 0, 31, 30))
defineProperty("menu_gr", loadImage("menus.png", 30, 0, 31, 30))
defineProperty("menu_ex_wt", loadImage("menus.png", 0, 30, 31, 90))
defineProperty("nav_ext_gr", loadImage("menus.png", 30, 30, 31, 30))
defineProperty("serv_ext_gr", loadImage("menus.png", 30, 60, 31, 30))
defineProperty("misc_ext_gr", loadImage("menus.png", 30, 90, 31, 30))
defineProperty("nav_menu_wt", loadImage("menus.png", 60, 29, 121, 31))
defineProperty("serv_menu_wt", loadImage("menus.png", 60, 59, 61, 31))
defineProperty("misc_menu_wt", loadImage("menus.png", 60, 89, 121, 31))
defineProperty("thro_red", loadImage("menus.png", 90, 0, 31, 30))
defineProperty("thro_grn", loadImage("menus.png", 120, 0, 31, 30))

local main_menu_ext = false
local nav_ext = false
local serv_ext = false
local misc_ext = false

-- UI layout constants (screen-space anchored)
local MENU_MARGIN = 10

local MAIN_W, MAIN_H = 31, 30
local EXT_W,  EXT_H  = 31, 90

local NAV_W,  NAV_H  = 121, 31
local SERV_W, SERV_H = 61, 31
local MISC_W, MISC_H = 121, 31

local function clamp(v, vmin, vmax)
	if v < vmin then return vmin end
	if v > vmax then return vmax end
	return v
end

local function updateMenuLayout()
	local wh = get(window_height)

	-- Guard: during early init, objects may not exist yet
	if not main_menu or not ext_menu or not nav_menu or not serv_menu or not misc_menu then
		return
	end

	-- Left edge, vertically centered
	local main_y = (wh * 0.5) - (MAIN_H * 0.5)
	main_y = clamp(main_y, 0, wh - MAIN_H)

	-- We have two possible directions for the stack:
	-- 1) Downward (like original: ext below main)
	-- 2) Upward (flip), if there's not enough space below

	local needed_below = EXT_H -- ext menu height (includes the 3 toggles)
	local lowest_needed = NAV_H + SERV_H + MISC_H -- worst case if all submenus shown (layout space)

	-- Total "potential" vertical span below main, if everything is open
	local total_below = math.max(needed_below, lowest_needed)

	local space_below = main_y
	local space_above = wh - (main_y + MAIN_H)

	local open_down = true
	if space_below < total_below and space_above > space_below then
		open_down = false
	end

	local ext_y, nav_y, serv_y, misc_y

	if open_down then
		-- Open downward (decreasing Y)
		ext_y  = main_y - EXT_H
		nav_y  = main_y - NAV_H
		serv_y = main_y - (NAV_H + SERV_H)
		misc_y = main_y - (NAV_H + SERV_H + MISC_H)
	else
		-- Open upward (increasing Y)
		ext_y  = main_y + MAIN_H
		nav_y  = main_y + MAIN_H
		serv_y = main_y + MAIN_H + NAV_H
		misc_y = main_y + MAIN_H + NAV_H + SERV_H
	end

	-- Clamp all to screen
	ext_y  = clamp(ext_y,  0, wh - EXT_H)
	nav_y  = clamp(nav_y,  0, wh - NAV_H)
	serv_y = clamp(serv_y, 0, wh - SERV_H)
	misc_y = clamp(misc_y, 0, wh - MISC_H)

	-- Apply positions
	main_menu.position = { 0,  main_y, MAIN_W, MAIN_H }
	ext_menu.position  = { 0,  ext_y,  EXT_W,  EXT_H  }

	nav_menu.position  = { 30, nav_y,  NAV_W,  NAV_H  }
	serv_menu.position = { 30, serv_y, SERV_W, SERV_H }
	misc_menu.position = { 30, misc_y, MISC_W, MISC_H }

	-- Optional: throttle button near main, avoid leaving screen
	if thro_button then
		local thro_y = main_y + MAIN_H + 10
		if thro_y + 30 > wh then
			thro_y = main_y - 30 - 10
		end
		thro_y = clamp(thro_y, 0, wh - 30)
		thro_button.position = { 0, thro_y, 31, 30 }
	end
end

nav_menu = contextWindow {
	position = { 30, 570, 121, 31 };
	noDecore = true;
	noBackground = false;
	noClose = true;
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
					commandOnce(findCommand("sim/GPS/g430n1_popup"))
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
	noDecore = true;
	noBackground = false;
	noClose = true;
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
	noDecore = true;
	noBackground = false;
	noClose = true;
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
	noDecore = true;
	noBackground = false;
	noClose = true;
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
	noDecore = true;
	noBackground = false;
	noClose = true;
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
	noDecore = true;
	noBackground = false;
	noClose = true;
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
	main_menu.visible = true
	ext_menu.visible = main_menu_ext
	nav_menu.visible = main_menu_ext and nav_ext
	serv_menu.visible = main_menu_ext and serv_ext
	misc_menu.visible = main_menu_ext and misc_ext
	payload_panel.visible = get(show_load_panel) == 1
	absu_2d_panel.visible = get(show_absu_panel) == 1
	ovhd_2d_panel.visible = get(show_ohvd_panel) == 1
	nvu_2D_panel.visible = get(show_nvu_panel) == 1
	checklist_panel.visible = get(show_checklist_panel) == 1
	ground_srv_panel.visible = get(show_ground_panel) == 1
	uphone.visible = get(show_phone) == 1
	camera_panel.visible = get(show_cam) == 1
	palette.visible = get(show_palette) == 1
	fails_panel.visible = get(show_fail_panel) == 1
	thro_button.visible = get(ismaster) > 0
end

function draw()
	drawAll(components)  -- you need this in order for X-Plane to draw the interactive areas when mouse click zones are set to on in graphics settings
    
end

function onAvionicsDone()
	savePopupsPositions()
end

onAvionicsDone = function()
	savePopupsPositions()
end

function draw()
	drawAll(components)
end
