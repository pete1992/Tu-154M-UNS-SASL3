-- this is DME indicators
size = {215, 70}

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
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    -- Each instance keeps its own NAV receiver and unit selector.
    { "vor_dme", "tu154/custom/radio/vor_dme_1", globalPropertyf },
    { "sd75_on", "tu154/custom/switchers/ovhd/sd75_1_on", globalPropertyi },
    { "nav_mile_km", "tu154/custom/switchers/nav_1_mile_km", globalPropertyi },
    -- KATET selects the displayed distance, not the radio or guidance source.
    { "katet_dme_rsbn", "tu154/custom/katet/dme_rsbn", globalPropertyi },
    { "rsbn_distance", "tu154/custom/rsbn/distance", globalPropertyf },
    { "rsbn_distance_valid", "tu154/custom/rsbn/distance_valid", globalPropertyi },
    { "rsbn_cc", "tu154/custom/radio/rsbn_cc", globalPropertyf },
    -- Unit lamps and display power.
    { "dme_mile_lit", "tu154/custom/lights/small/dme_mile_left", globalPropertyf },
    { "dme_km_lit", "tu154/custom/lights/small/dme_km_left", globalPropertyf },
    { "bus27_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus115_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "fail", "sim/operation/failures/rel_dme", globalPropertyi },
    { "dme_fail", "tu154/custom/failures/dme1_fail", globalPropertyi },
})

local text_font = sasl.gl.loadBitmapFont('digital7_it.fnt')

local dist_text = "888.8"

local power = false

local dist_now = 0
local dist_show = 0

function update()
	
	local use_rsbn = get(katet_dme_rsbn) == 1
	power = get(sd75_on) == 1 and get(bus27_volt) > 13 and get(bus115_volt) > 110
		and (use_rsbn or get(dme_fail) == 0)
	
	local passed = get(frame_time)
	
	dist_now = 0
	if power then
		if use_rsbn then
			-- RSBN's mechanical indication holds its last reading after signal loss.
			-- Only copy it while the receiver reports a currently valid range.
			if get(rsbn_cc) > 0 and get(rsbn_distance_valid) == 1 then
				dist_now = get(rsbn_distance)
				if get(nav_mile_km) == 0 then dist_now = dist_now / 1.852 end
			end
		else
			-- CourseMP has already applied the selected NM/KM units to DME.
			dist_now = get(vor_dme)
		end
	end
	
	-- Do not let invalid or oversized receiver values corrupt the display.
	if dist_now ~= dist_now or dist_now == math.huge or dist_now == -math.huge then
		dist_now = 0
	end
	dist_now = math.max(0, math.min(999.9, dist_now))
	
	dist_show = math.floor((dist_now + 0.03) * 10) / 10
	
	if dist_show == 0 then dist_text = "---.-"
	elseif dist_show < 10 then 
		dist_text = "  "..dist_show
	elseif dist_show < 100 then
		dist_text = " "..dist_show
	else dist_text = dist_show
	end
	
	if dist_show - math.floor(dist_show) == 0 and dist_text ~= "---.-" then dist_text = dist_text..".0" end

	-- lamps
	local mode = get(nav_mile_km)
	
	if power then
		set(dme_mile_lit, bool2int(mode == 0))
		set(dme_km_lit, bool2int(mode == 1))
	else
		set(dme_mile_lit, 0)
		set(dme_km_lit, 0)
	end
	
end

components = {
	--[[
	rectangle {
		position = {0, 0, 215, 70},
		color = {0,0,1,1},
	},
	--]]

	text_draw {
		position = {16, 12, 130, 130},
		color = {1, 0.3, 0.2, 1},
		font = text_font,
		visible = function()
			return power
		end,
		text = function()
			return dist_text
		end,
	
	},

}