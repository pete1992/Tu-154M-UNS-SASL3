-- taws sound logic

defineProperty("taws_english", globalPropertyi("tu154/custom/taws/taws_english")) --  . 0 - , 1 - 	0

defineProperty("taws_eng_phrase", globalPropertyi("tu154/custom/sounds/taws_eng_phrase")) --     
defineProperty("taws_rus_phrase", globalPropertyi("tu154/custom/sounds/taws_rus_phrase")) --     

defineProperty("external_view", globalPropertyi("sim/graphics/view/view_is_external")) -- enviroment

-- sounds

local eng_alt_50 = sasl.al.loadSample('Custom Sounds/taws/eng/alt_50.wav')
local eng_alt_200 = sasl.al.loadSample('Custom Sounds/taws/eng/alt_200.wav')
local eng_alt_500 = sasl.al.loadSample('Custom Sounds/taws/eng/alt_500.wav')
local eng_alt_1000 = sasl.al.loadSample('Custom Sounds/taws/eng/alt_1000.wav')
local eng_check_alt = sasl.al.loadSample('Custom Sounds/taws/eng/check_alt.wav')
local eng_dont_sink = sasl.al.loadSample('Custom Sounds/taws/eng/dont_sink.wav')
local eng_glideslope = sasl.al.loadSample('Custom Sounds/taws/eng/glideslope.wav')
local eng_pull_up = sasl.al.loadSample('Custom Sounds/taws/eng/pull_up.wav')
local eng_sink_rate = sasl.al.loadSample('Custom Sounds/taws/eng/sink_rate.wav')
local eng_terrain = sasl.al.loadSample('Custom Sounds/taws/eng/terrain.wav')
local eng_terrain_ahead = sasl.al.loadSample('Custom Sounds/taws/eng/terrain_ahead.wav')
local eng_too_low_flaps = sasl.al.loadSample('Custom Sounds/taws/eng/too_low_flaps.wav')
local eng_too_low_gear = sasl.al.loadSample('Custom Sounds/taws/eng/too_low_gear.wav')
local eng_too_low_terrain = sasl.al.loadSample('Custom Sounds/taws/eng/too_low_terrain.wav')

local rus_alt_5 = sasl.al.loadSample('Custom Sounds/taws/rus/alt_5.wav')
local rus_alt_10 = sasl.al.loadSample('Custom Sounds/taws/rus/alt_10.wav')
local rus_alt_15 = sasl.al.loadSample('Custom Sounds/taws/rus/alt_15.wav')
local rus_alt_20 = sasl.al.loadSample('Custom Sounds/taws/rus/alt_20.wav')
local rus_alt_25 = sasl.al.loadSample('Custom Sounds/taws/rus/alt_25.wav')
local rus_alt_30 = sasl.al.loadSample('Custom Sounds/taws/rus/alt_30.wav')
local rus_alt_40 = sasl.al.loadSample('Custom Sounds/taws/rus/alt_40.wav')
local rus_alt_50 = sasl.al.loadSample('Custom Sounds/taws/rus/alt_50.wav')
local rus_alt_60 = sasl.al.loadSample('Custom Sounds/taws/rus/alt_60.wav')
local rus_alt_150 = sasl.al.loadSample('Custom Sounds/taws/rus/alt_150.wav')
local rus_check_alt = sasl.al.loadSample('Custom Sounds/taws/rus/check_alt.wav')
local rus_dont_sink = sasl.al.loadSample('Custom Sounds/taws/rus/dont_sink.wav')
local rus_glideslope = sasl.al.loadSample('Custom Sounds/taws/rus/glideslope.wav')
local rus_pull_up = sasl.al.loadSample('Custom Sounds/taws/rus/pull_up.wav')
local rus_sink_rate = sasl.al.loadSample('Custom Sounds/taws/rus/sink_rate.wav')
local rus_terrain = sasl.al.loadSample('Custom Sounds/taws/rus/terrain.wav')
local rus_terrain_ahead = sasl.al.loadSample('Custom Sounds/taws/rus/terrain_ahead.wav')
local rus_too_low_flaps = sasl.al.loadSample('Custom Sounds/taws/rus/too_low_flaps.wav')
local rus_too_low_gear = sasl.al.loadSample('Custom Sounds/taws/rus/too_low_gear.wav')
local rus_too_low_terrain = sasl.al.loadSample('Custom Sounds/taws/rus/too_low_terrain.wav')

function update()
	
	if get(taws_english) == 1 and get(external_view) == 0 then -- english mode
	
		local num = get(taws_eng_phrase)
		
		if num == 0 then
			
		-- play selected sample
		elseif num == 1 then sasl.al.playSample(eng_alt_50, false)
		elseif num == 2 then sasl.al.playSample(eng_alt_200, false)
		elseif num == 3 then sasl.al.playSample(eng_alt_500, false)
		elseif num == 4 then sasl.al.playSample(eng_alt_1000, false)
		elseif num == 11 then sasl.al.playSample(eng_check_alt, false)
		elseif num == 12 then sasl.al.playSample(eng_dont_sink, false)
		elseif num == 13 then sasl.al.playSample(eng_glideslope, false)
		elseif num == 14 then sasl.al.playSample(eng_pull_up, false)
		elseif num == 15 then sasl.al.playSample(eng_sink_rate, false)
		elseif num == 16 then sasl.al.playSample(eng_terrain, false)
		elseif num == 17 then sasl.al.playSample(eng_terrain_ahead, false)
		elseif num == 18 then sasl.al.playSample(eng_too_low_flaps, false)
		elseif num == 19 then sasl.al.playSample(eng_too_low_gear, false)
		elseif num == 20 then sasl.al.playSample(eng_too_low_terrain, false)
		
		end
		
		set(taws_eng_phrase, 0) -- reset number of sample
		
	elseif get(external_view) == 0 then -- russian mode
	
		local num = get(taws_rus_phrase)
	
		if num == 0 then 
			
		elseif num == 1 then sasl.al.playSample(rus_alt_5, false)
		elseif num == 2 then sasl.al.playSample(rus_alt_10, false)
		elseif num == 3 then sasl.al.playSample(rus_alt_15, false)
		elseif num == 4 then sasl.al.playSample(rus_alt_20, false)
		elseif num == 5 then sasl.al.playSample(rus_alt_25, false)
		elseif num == 6 then sasl.al.playSample(rus_alt_30, false)
		elseif num == 7 then sasl.al.playSample(rus_alt_40, false)
		elseif num == 8 then sasl.al.playSample(rus_alt_50, false)
		elseif num == 9 then sasl.al.playSample(rus_alt_60, false)
		elseif num == 10 then sasl.al.playSample(rus_alt_150, false)
		elseif num == 11 then sasl.al.playSample(rus_check_alt, false)
		elseif num == 12 then sasl.al.playSample(rus_dont_sink, false)
		elseif num == 13 then sasl.al.playSample(rus_glideslope, false)
		elseif num == 14 then sasl.al.playSample(rus_pull_up, false)
		elseif num == 15 then sasl.al.playSample(rus_sink_rate, false)
		elseif num == 16 then sasl.al.playSample(rus_terrain, false)
		elseif num == 17 then sasl.al.playSample(rus_terrain_ahead, false)
		elseif num == 18 then sasl.al.playSample(rus_too_low_flaps, false)
		elseif num == 19 then sasl.al.playSample(rus_too_low_gear, false)
		elseif num == 20 then sasl.al.playSample(rus_too_low_terrain, false)
	
		end
	
		set(taws_rus_phrase, 0)  -- reset number of sample
	
	end
	
end

