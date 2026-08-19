-- this is VHF radio
size = {420, 90}


defineProperty("num", 0)
-- Smart Copilot
defineProperty("ismaster", globalPropertyf("scp/api/ismaster")) -- Master. 0 = plugin not found, 1 = slave 2 = master
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1")) -- Have control. 0 = plugin not found, 1 = no control 2 = has control

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    { "frequency", "sim/cockpit2/radios/actuators/com1_frequency_hz_833", globalPropertyf },
    { "freq_sby", "sim/cockpit2/radios/actuators/com1_standby_frequency_hz_833", globalPropertyf },
    { "vhf_left", "tu154/custom/rotary/ovhd/vhf_1_left", globalPropertyi },
    { "vhf_right", "tu154/custom/rotary/ovhd/vhf_1_right", globalPropertyi },
    { "vhf_on", "tu154/custom/switchers/ovhd/vhf_1_on", globalPropertyi },
    { "bus27_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "spu_source", "tu154/custom/switchers/spu_1_source", globalPropertyi },
    { "com_power", "sim/cockpit2/radios/actuators/com1_power", globalPropertyi },
    { "vhf_cc", "tu154/custom/radio/vhf1_cc", globalPropertyf },
})

local rot_small_sound = sasl.al.loadSample('Custom Sounds/com.wav')
sasl.al.setSampleGain(rot_small_sound, 500)
local text_font = sasl.gl.loadBitmapFont('digital7_it.fnt')
local rot_summ_last = 0

local function rotary()
	local nav_left_sw = get(vhf_left)
	local nav_right_sw = get(vhf_right)
	local summ = nav_left_sw + nav_right_sw
	if summ ~= rot_summ_last then sasl.al.playSample(rot_small_sound, false) end
	rot_summ_last = summ
end



-- variables for separate manipulations
local freq_100 = 0  -- digits before period
local freq_10 = 0  -- digits after period
local freq_10_show = 0
local freq_show = ""
local power = false
local knob_last_L = get(vhf_left)
local knob_last_R = get(vhf_right)

function update()

	rotary()
	local MASTER = get(ismaster) ~= 1	
	-- knobs cycle
	local left_knob = get(vhf_left)
	local right_knob = get(vhf_right)
	left_knob = around(left_knob, -10, 26, 36)
	right_knob = around(right_knob, -10, 26, 36)
	set(vhf_left, left_knob)
	set(vhf_right, right_knob)
	local freq = get(frequency)
	-- set standby frequency as the main here
	if (get(num) == 0 and get(spu_source) == 1) or (get(num) == 1 and get(spu_source) == 0) then freq = get(freq_sby) end
	power = get(vhf_on) == 1 and get(bus27_volt) > 13 -- temp
	local MHz = math.floor(freq / 1000)
	local kHz = freq % 1000
	local out = kHz % 1000
	
	MHz = around(MHz, 118, 136, 18)
	kHz = around(kHz, 0, 995, 1000)
	kHz = limit(kHz, 0, 995)
	freq = MHz * 1000 + kHz

if MASTER then
	-- change frequency
	if power then
		local knob_diff_L = left_knob - knob_last_L
		local knob_diff_R = right_knob - knob_last_R
		if math.abs(knob_diff_L) < 5 then
			MHz = MHz + knob_diff_L
		end
		if math.abs(knob_diff_R) < 5 then
			kHz = kHz + 5 * knob_diff_R
		end	
	end
	MHz = around(MHz, 118, 136, 18)
	kHz = around(kHz, 0, 995, 1000)
	if (get(num) == 0 and get(spu_source) == 1) or (get(num) == 1 and get(spu_source) == 0) then set(freq_sby, MHz * 1000 + kHz) 
	else set(frequency, MHz * 1000 + kHz) end
end
	freq_show = string.format("%.3f", freq/1000)
	set(com_power, bool2int(power))
	set(vhf_cc, bool2int(power) * 1.2)
	knob_last_L = left_knob
	knob_last_R = right_knob
end

function onModuleDone()
	set(com_power, 1)
end

local font_scale = 1.5
local text_x = 35
local text_y = 20

function draw()
    if not power then
        return
    end
    sasl.gl.saveGraphicsContext()
    sasl.gl.setTranslateTransform(text_x, text_y)
    sasl.gl.setScaleTransform(font_scale, font_scale)

    sasl.gl.drawBitmapText(
        text_font,
        0,
        0,
        freq_show,
        TEXT_ALIGN_LEFT,
        {0.2, 1, 0.2, 1}
    )
    sasl.gl.restoreGraphicsContext()
end
