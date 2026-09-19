-- scr_welcome.lua
-- this is the clock screen of TAWS
size = {1000, 770}

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
    { "mode_set", "tu154/custom/taws/mode_set", globalPropertyi }, --   . 0 - , 1 -  , 2 -  , 3 - , 4 -
    { "brt_handle", "tu154/custom/rotary/srpbz/brightness", globalPropertyf }, --
    { "distance_set", "tu154/custom/taws/distance_set", globalPropertyi }, --    , . 0 = 10, 1 = 20, 2 = 40, 3 = 80, 4 = 160, 5 = 320, 6 = 640

    -- { "course_fly", "sim/flightmodel/position/hpath", globalPropertyf }, -- course, where aircraft actually flies

    -- { "latitude", "sim/flightmodel/position/latitude", globalPropertyf }, -- degrees	The latitude of the aircraft
    -- { "longitude", "sim/flightmodel/position/longitude", globalPropertyf }, -- degrees The longitude of the aircraft
    -- { "speed", "sim/flightmodel/position/groundspeed", globalPropertyf },

    -- { "sim_time", "sim/time/zulu_time_sec", globalPropertyf },  -- zulu time

    -- time
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time
})

-- images
defineProperty("wc_screen_img", sasl.gl.loadImage("taws_welcome.png", 0, 0, 1000, 770))
local text_font = sasl.gl.loadBitmapFont('taws_scr.fnt')

local screen_work = get(mode_set) == 4
local brightness = 0.8

--[[ start sequence

0:01 - .   - 1
0:23 -     015 - 2
0:28 -    010 - 2
0:34 -   - 3
0:39 -   - 4
0:48 -          - 5
1:01 -  .  20. - 6

--]]

local time_counter = 0 -- use frames to fill table row by row

local sequence_phase = 0

local counter_text = "0  0  0"

local last_mode = get(mode_set)

function update()
	
	local current_mode = get(mode_set)
	
	screen_work = current_mode == 4
	
	local passed = get(frame_time)
	
	time_counter = time_counter + passed

	if not screen_work then 
		brightness = 0 
		time_counter = 0	
	
	else
		brightness = get(brt_handle)
	
		if current_mode == 0 then time_counter = 0 end -- reset counter when power off
		
		-- test
		--time_counter = 50
		
		if time_counter < 1 then 
			sequence_phase = 0 -- power off
		elseif time_counter >= 1  and time_counter < 23 then
			sequence_phase = 1 -- .  
		elseif time_counter < 34 then
			sequence_phase = 2 --     015
		elseif time_counter < 39 then
			sequence_phase = 3 --  
		elseif time_counter < 48 then
			sequence_phase = 4 --  
		elseif time_counter < 61 then
			sequence_phase = 5 --         
		elseif time_counter >= 61 and time_counter < 62 then
			sequence_phase = 6 --  .  20.
			set(mode_set, 1)
			set(distance_set, 1)
		end
		
		local count = math.floor(math.max(0, 5 - (time_counter - 24)))
		
		counter_text = "0  1  "..count
		
		--print(sequence_phase)
	
	end
	
	last_mode = current_mode

end

components = {
	
	rectangle {
		position = {0, 0, size[1], size[2]},
		color = {0.1, 0.1, 0.1, 1},
		visible = function()
			return screen_work
		end,
	},
	
	--------------------------------
	-- phase 1 - yellow screen --
	--------------------------------
	rectangle {
		position = {0, 0, size[1], size[2]},
		color = {1, 1, 0.5, 1},
		visible = function()
			return screen_work and sequence_phase == 1
		end,
	},	
	
	--------------------------------
	-- phase 2 - blue screen and counter --
	--------------------------------
	rectangle {
		position = {0, 0, size[1], size[2]},
		color = {0.2, 0.5, 1, 1},
		visible = function()
			return screen_work and sequence_phase == 2
		end,
	},	
	
	-- counter background
	rectangle {
		position = {380, 400, 330, 200},
		color = {1, 1, 1, 1},
		visible = function()
			return screen_work and sequence_phase == 2
		end,
	},
	rectangle {
		position = {385, 405, 320, 190},
		color = {0.2, 0.5, 1, 1},
		visible = function()
			return screen_work and sequence_phase == 2
		end,
	},	
	
	rectangle {
		position = {390, 410, 100, 180},
		color = {1, 1, 1, 1},
		visible = function()
			return screen_work and sequence_phase == 2
		end,
	},	
	
	rectangle {
		position = {395, 415, 90, 170},
		color = {0.2, 0.5, 1, 1},
		visible = function()
			return screen_work and sequence_phase == 2
		end,
	},		
	rectangle {
		position = {495, 410, 100, 180},
		color = {1, 1, 1, 1},
		visible = function()
			return screen_work and sequence_phase == 2
		end,
	},	
	
	rectangle {
		position = {500, 415, 90, 170},
		color = {0.2, 0.5, 1, 1},
		visible = function()
			return screen_work and sequence_phase == 2
		end,
	},	

	rectangle {
		position = {600, 410, 100, 180},
		color = {1, 1, 1, 1},
		visible = function()
			return screen_work and sequence_phase == 2
		end,
	},	
	
	rectangle {
		position = {605, 415, 90, 170},
		color = {0.2, 0.5, 1, 1},
		visible = function()
			return screen_work and sequence_phase == 2
		end,
	},	

	-- counter text
	text_draw {
		position = {413, 480, 220, 150},
		text = function()
			return counter_text
		end,
		font = text_font,
		color = {1,1,1,1},
		visible = function()
			return screen_work and sequence_phase == 2
		end,
	},

	-------------------------------
	-- phase 4 - welcome screen --
	-------------------------------
	textureLit {
		position = {0, 0, size[1], size[2]},
		image = get(wc_screen_img),
		visible = function()
			return screen_work and sequence_phase == 4
		end,
	},

	-------------------------------
	-- phase 5 - NO RP --
	-------------------------------
	rectangle {
		position = {0, 0, size[1], size[2]},
		color = {0.7, 0.7, 0.6, 1},
		visible = function()
			return screen_work and sequence_phase == 5
		end,
	},	
	
	rectangle {
		position = {330, 335, 340, 80},
		color = {0.1, 0.1, 0.1, 1},
		visible = function()
			return screen_work and sequence_phase == 5
		end,
	},	
	
	-- counter text
	text_draw {
		position = {360, 350, 185, 160},
		text = function()
			return " "
		end,
		font = text_font,
		color = {1,0.8,0,1},
		visible = function()
			return screen_work and sequence_phase == 5
		end,
	},	
	
	-- brightness controll
	rectangle_ctr {
		R = 0,
		G = 0,
		B = 0,
		A = function()
			return 1 - brightness
		end, -- controll via alpha
		position_x = 0,
		position_y = 0,
		width = size[1],
		height = size[2],
		visible = function()
			return screen_work
		end,
	},

}