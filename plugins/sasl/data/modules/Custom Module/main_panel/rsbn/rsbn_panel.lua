-- rsbn_panel.lua
-- this is RSBN panel

-- controls
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
    { "rsbn_control_strobe", "tu154/custom/buttons/ovhd/rsbn_control_strobe", globalPropertyi }, --
    { "rsbn_control_azimuth", "tu154/custom/buttons/ovhd/rsbn_control_azimuth", globalPropertyi }, --
    { "rsbn_control_distance", "tu154/custom/buttons/ovhd/rsbn_control_distance", globalPropertyi }, --

    { "rsbn_ch_ten", "tu154/custom/buttons/ovhd/rsbn_ch_ten", globalPropertyi }, --
    { "rsbn_ch_one", "tu154/custom/buttons/ovhd/rsbn_ch_one", globalPropertyi }, --

    -- { "rsbn_on", "tu154/custom/switchers/ovhd/rsbn_on", globalPropertyi }, --
    -- { "rsbn_recon", "tu154/custom/switchers/ovhd/rsbn_recon", globalPropertyi }, --

    { "test_lamps", "tu154/custom/buttons/lamp_test_front", globalPropertyi }, --
    { "day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf }, --   - . 0 - , 1 - .    .

    -- gauges
    { "rsbn_azimuth_ind", "tu154/custom/gauges/misc/rsbn_azimuth_ind", globalPropertyf }, --
    { "rsbn_distance_km", "tu154/custom/gauges/misc/rsbn_distance_km", globalPropertyf }, --
    { "rsbn_km_one", "tu154/custom/gauges/misc/rsbn_km_one", globalPropertyf }, --
    { "rsbn_km_ten", "tu154/custom/gauges/misc/rsbn_km_ten", globalPropertyf }, --
    { "rsbn_km_hun", "tu154/custom/gauges/misc/rsbn_km_hun", globalPropertyf }, --

    -- lamps
    { "dist_autonom", "tu154/custom/lights/dist_autonom", globalPropertyf }, --
    { "azimuth_autonom", "tu154/custom/lights/azimuth_autonom", globalPropertyf }, --

    -- sources
    { "distance", "tu154/custom/rsbn/distance", globalPropertyf }, --
    { "azimuth", "tu154/custom/rsbn/azimuth", globalPropertyf }, --

    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time

    -- other sources
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf }, --   27
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf }, --   27
})

set(dist_autonom, 1)

set(azimuth_autonom, 1)

local button_sound = sasl.al.loadSample('Custom Sounds/plastic_btn.wav')
local rotary_sound = sasl.al.loadSample('Custom Sounds/plastic_switch.wav')

local passed = 0

local but_summ_last = 0

local function buttons()
	local rsbn_control_strobe_sw = get(rsbn_control_strobe)
	local rsbn_control_azimuth_sw = get(rsbn_control_azimuth)
	local rsbn_control_distance_sw = get(rsbn_control_distance)

	local but_summ = rsbn_control_strobe_sw + rsbn_control_azimuth_sw + rsbn_control_distance_sw
	
	if but_summ ~= but_summ_last then sasl.al.playSample(button_sound, false) end
	
	but_summ_last = but_summ

end

local rot_summ_last = 0

local function rotary()

	local rsbn_ch_ten_sw = get(rsbn_ch_ten)
	local rsbn_ch_one_sw = get(rsbn_ch_one)
	
	local summ = rsbn_ch_ten_sw + rsbn_ch_one_sw
	
	if summ ~= rot_summ_last then sasl.al.playSample(rotary_sound, false) end
	
	rot_summ_last = summ

end

local azimuth_act = 0
local dist_act = 0

local function gauges()

	local azim = get(azimuth) -- deg
	
	local az_delta = azim - azimuth_act
	if az_delta > 180 then az_delta = az_delta - 360
	elseif az_delta < -180 then az_delta = az_delta + 360 end
	
	if az_delta > 1 then azimuth_act = azimuth_act + passed * 30
	elseif az_delta < -1 then azimuth_act = azimuth_act - passed * 30
	else azimuth_act = azimuth_act + az_delta * passed * 30
	end
	
--	azimuth_act = azimuth_act + az_delta * passed * 5
	
	set(rsbn_azimuth_ind, azimuth_act)
	
	local dist = get(distance) * 10 -- km
	
	local dist_delta = dist - dist_act
	
	if dist_delta > 10 then dist_act = dist_act + passed * 60
	elseif dist_delta < -10 then dist_act = dist_act - passed * 60
	else dist_act = dist_act + dist_delta * passed * 6
	end
	
	local dist_01 = dist_act % 10
	
	local dist_one = math.floor((dist_act % 100) * 0.1) + math.max(math.max((dist_01  - 8) / 2, 0), 0)
	
	local dist_10 = math.floor((dist_act % 1000) * 0.01) + math.max(math.max((dist_one  - 9), 0), 0)
	
	local dist_100 = math.floor((dist_act % 10000) * 0.001) + math.max(math.max((dist_10 - 9), 0), 0)
	
	set(rsbn_distance_km, dist_01 * 0.1)
	set(rsbn_km_one, dist_one)
	set(rsbn_km_ten, dist_10)
	set(rsbn_km_hun, dist_100)

end

local function lamps()
	
	local test_btn = get(test_lamps) * math.max((get(bus27_volt_right) - 10) / 18.5, 0)
	local day_night = 1 - get(day_night_set) * 0.25
	local lamps_brt = math.max((math.max(get(bus27_volt_left), get(bus27_volt_right)) - 10) / 18.5, 0) * day_night

	local dist_autonom_brt = math.max(bool2int(get(distance) == 0) * lamps_brt, test_btn)
	set(dist_autonom, dist_autonom_brt)
	
	local azimuth_autonom_brt = math.max(bool2int(get(azimuth) == 0) * lamps_brt, test_btn)
	set(azimuth_autonom, azimuth_autonom_brt)
	
end

function update()
	passed = get(frame_time)
	
	buttons()
	rotary()
	gauges()
	lamps()

end