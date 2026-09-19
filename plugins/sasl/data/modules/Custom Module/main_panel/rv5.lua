-- rv5.lua
-- RV-5 radio altimeter logic.

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
    -- Timing and radio altitude
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    -- { "external_view", "sim/graphics/view/view_is_external", globalPropertyi }, -- Unused: no view-dependent logic.
    { "altitude", "sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot", globalPropertyf },

    -- Controls and failure state; the right-side instance overrides these defaults.
    { "dh_set", "tu154/custom/gauges/alt/radioalt_dh_left", globalPropertyf }, -- DH angle
    { "test_btn", "tu154/custom/gauges/alt/radioalt_button_left", globalPropertyf },
    { "rv_on", "tu154/custom/switchers/ovhd/rv5_1_on", globalPropertyi },
    { "rv_fail", "tu154/custom/failures/rv1_fail", globalPropertyi },

    -- Electrical power
    { "bus27_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus115_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },

    -- Indications and current consumption
    { "rv_angle", "tu154/custom/gauges/alt/radioalt_needle_left", globalPropertyf },
    { "rv_flag", "tu154/custom/gauges/alt/radioalt_flag_left", globalPropertyf },
    { "rv5_alt", "tu154/custom/misc/rv5_alt_left", globalPropertyf },
    { "rv5_dh_signal", "tu154/custom/misc/rv5_dh_signal_left", globalPropertyi },
    { "rv_lamp", "tu154/custom/lights/small/rv5_left_dh", globalPropertyf },
    { "rv_", "tu154/custom/elec/rv5_left_cc", globalPropertyf },
})

local alt2angle = {
{-100000, 0},
{0, 0},
{20, 30},
{50, 80},
{100, 160},
{700, 314},
{700, 314},
{800, 340},
{8000000, 340}
}

local alt_angle = 0
local alt_angle_act = 0
local start_timer = 0
local alt = 0

function update()
	
	local passed = get(frame_time)
	
	local power = get(bus27_volt) > 13 and get(bus115_volt) > 110 and get(rv_on) == 1 and get(rv_fail) == 0
	local test = power and get(test_btn) == 1
	
	if power then
		start_timer = start_timer + passed
		
		if start_timer < 20 then 
			alt_angle = 340
			alt = 800
			if test then 
				alt = 15 
				alt_angle = interpolate(alt2angle, alt)
			end
		elseif start_timer <= 30 then 
			alt_angle = 340 - (start_timer - 20) * 34
			alt = get(altitude) * 0.3048
			if alt_angle < interpolate(alt2angle, alt) then alt_angle = interpolate(alt2angle, alt) end
			if test then 
				alt = 15 
				alt_angle = interpolate(alt2angle, alt)
			end
		else 
			alt = get(altitude) * 0.3048
			if alt > 800 then alt = 800
			elseif alt < 0 then alt = 0 end
			
			if test then alt = 15 end
			
			alt_angle = interpolate(alt2angle, alt)
			
			if start_timer > 50 then start_timer = 50 end
		end
		
		set(rv_, 1)
	else
		start_timer = start_timer - passed
		if start_timer < 20 then start_timer = 0 end
		--if start_timer < 0 then start_timer = 0 end
		set(rv_, 0)
	end
	
	alt_angle_act = alt_angle_act + (alt_angle - alt_angle_act) * passed * 4
	
	-- flag logic
	local flag_show = bool2int(not power or (start_timer <= 30 and not test))
	
	set(rv_flag, flag_show)
	
	-- lamp logic
	local lamp_lit = bool2int(alt_angle < get(dh_set) - 1 and power)
	
	local lamp_coef = math.max((get(bus27_volt) - 10) / 18.5, 0)
	
	set(rv_lamp, lamp_lit * lamp_coef)
	set(rv5_dh_signal, lamp_lit)
	
	-- set results
	set(rv_angle, alt_angle_act)
	set(rv5_alt, alt)

end

