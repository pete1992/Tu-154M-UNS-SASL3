-- vbe_altimeter.lua
-- Electronic VBE altimeter logic and display.

size = {424, 424}

defineProperty("gauge_num", 0)

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"msl_alt", "sim/flightmodel/position/elevation", globalPropertyf},
    {"msl_press", "sim/weather/barometer_sealevel_inhg", globalPropertyf},
    {"static_fail", "sim/operation/failures/rel_static", globalPropertyi},
    {"external_view", "sim/graphics/view/view_is_external", globalPropertyi},
    {"alt_mtr", "tu154/custom/gauges/alt/vbe_alt_left", globalPropertyf},
    {"pressure", "tu154/custom/gauges/alt/vbe_press_left", globalPropertyf},
    {"brt_knob", "tu154/custom/gauges/alt/vbe_brt_left", globalPropertyf},
    {"press_knob", "tu154/custom/gauges/alt/vbe_press_knob_left", globalPropertyi},
    {"fl_knob", "tu154/custom/gauges/alt/vbe_fl_knob_left", globalPropertyi},
    {"vbe_mode", "tu154/custom/gauges/alt/vbe_mode_left", globalPropertyi},
    {"vbe_flightlevel", "tu154/custom/gauges/alt/vbe_flightlevel_left", globalPropertyf},
    {"mode_button", "tu154/custom/gauges/alt/vbe_mode_but_left", globalPropertyi},
    {"bus27_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"vbe_on", "tu154/custom/switchers/ovhd/vbe_1_on", globalPropertyi},
    {"vbe_std", "tu154/custom/gauges/alt/vbe_std_left", globalPropertyi},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"sensors_caps", "tu154/custom/anim/sensors_caps", globalPropertyi},
    {"warning_volume_ratio", "sim/operation/sound/warning_volume_ratio", globalPropertyf},
    {"fail", "sim/operation/failures/rel_ss_alt", globalPropertyi},
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

-- Local texture resources.
local scale_img = sasl.gl.loadImage("vbe_scale.png", 0, 4, 424, 424)
local green_img = sasl.gl.loadImage("vbe_scale.png", 445, 0, 60, 60)
local yellow_img = sasl.gl.loadImage("vbe_scale.png", 445, 65, 60, 60)
local hpa_rus_img = sasl.gl.loadImage("vbe_scale.png", 441, 135, 68, 35)
local hpa_eng_img = sasl.gl.loadImage("vbe_scale.png", 441, 176, 68, 35)
local borderg_img = sasl.gl.loadImage("vbe_scale.png", 5, 458, 153, 50)
local ft_img = sasl.gl.loadImage("vbe_scale.png", 448, 220, 46, 35)
local mtr_img = sasl.gl.loadImage("vbe_scale.png", 448, 257, 46, 35)
local ALT_img = sasl.gl.loadImage("vbe_scale.png", 437, 301, 68, 33)
local E_img = sasl.gl.loadImage("vbe_scale.png", 442, 345, 27, 46)
local minus_img = sasl.gl.loadImage("vbe_scale.png", 442, 350, 27, 35)
local needle_img = sasl.gl.loadImage("vbe_scale.png", 178, 482, 320, 6)
local digitsImage = sasl.gl.loadImage("black_digit_strip.png", 12, 0, 40, 784)
local bold_digitsImage = sasl.gl.loadImage("bold_digit_strip.png", 12, 0, 40, 784)

-- Sounds.
local switcher_sound = sasl.al.loadSample("Custom Sounds/metal_switch.wav")
local vbe_alarm_snd = sasl.al.loadSample("Custom Sounds/vbe_alarm.wav")

local power = false
local mode = get(vbe_mode)
local brightness = 0
local mod_but_last = get(mode_button)

local press = get(pressure)
local press_knob_last = get(press_knob)
local fl_knob_last = get(fl_knob)

local flight_level_show = 0
local flight_level = get(vbe_flightlevel)

local show_border = true
local vbe_MSL = 0
local altitude_ft = 0
local altitude_mtr = 0
local altitude_100 = 250
local altitude_1000 = 15

local show_E = false
local minus_10 = true
local minus_1 = false
local negative = false
local needle_angle = 0

-- Required by xTLua compatibility logic.
local test = false

local self_test_timer = 0
local border_mode = 0 -- 0 = hidden, 1 = blinking, 2 = steady
local border_blink_timer = 0
local mode_last = border_mode
local switcher_last = get(vbe_on)


local function normalizeKnob(value)
    while value > 11 do
        value = value - 10
    end

    while value < -1 do
        value = value + 10
    end

    return value
end


local function clamp(value, minimum, maximum)
    if value > maximum then
        return maximum
    elseif value < minimum then
        return minimum
    end

    return value
end


local function getAltitudeDrums(display_alt, current_mode)
    local thousands

    if display_alt > 0 then
        thousands = math.floor(display_alt * 0.001)
    else
        thousands = math.ceil(display_alt * 0.001)
    end

    local remainder = display_alt - thousands * 1000
    local hundreds

    if current_mode == 0 then
        if display_alt > 0 then
            hundreds = math.floor(remainder * 0.2) * 5
        else
            hundreds = math.ceil(remainder * 0.2) * 5
        end
    else
        if display_alt > 0 then
            hundreds = math.floor(remainder / 15) * 15
        else
            hundreds = math.ceil(remainder / 15) * 15
        end
    end

    return thousands, hundreds
end


local function getBorderMode(display_alt, selected_alt, current_mode)
    if selected_alt <= 0 then
        return 0
    end

    local step
    local blink_limit
    local steady_limit

    if current_mode == 0 then
        step = 5
        blink_limit = 60
        steady_limit = 150
    else
        step = 15
        blink_limit = 200
        steady_limit = 500
    end

    local quantized_alt =
        math.floor(display_alt / step) * step

    local difference =
        math.abs(quantized_alt - selected_alt)

    if difference >= steady_limit then
        return 2
    elseif difference >= blink_limit then
        return 1
    end

    return 0
end


function update()
    local MASTER = get(ismaster) ~= 1
    local passed = get(frame_time)
    local num = get(gauge_num)
    local external = get(external_view) == 1

    local vbe_on_now = get(vbe_on)

    -- Power switch sound.
    if vbe_on_now ~= switcher_last then
        sasl.al.playSample(switcher_sound, false)
    end

    switcher_last = vbe_on_now

    -- Electrical power.
    power =
        get(bus27_volt) > 13
        and vbe_on_now == 1
        and get(fail) < 6

    if power then
        brightness = get(brt_knob) ^ 0.8
        self_test_timer = self_test_timer + passed
    else
        brightness = 0
        self_test_timer = 0

        if MASTER then
            set(pressure, 1013)
            set(vbe_mode, 0)
        end

        if sasl.al.isSamplePlaying(vbe_alarm_snd) then
            sasl.al.stopSample(vbe_alarm_snd)
        end
    end

    -- Meter/feet mode selector.
    local mod_but = get(mode_button)
    mode = get(vbe_mode)

    if MASTER
        and mod_but ~= mod_but_last
        and mod_but == 1 then

        mode = 1 - mode
        set(vbe_mode, mode)
    end

    -- Keep the edge detector synchronized even while running as slave.
    mod_but_last = mod_but

    -- Pressure selector.
    local press_knob_now =
        normalizeKnob(get(press_knob))

    press = get(pressure)

    if MASTER then
        set(press_knob, press_knob_now)

        local press_knob_diff =
            press_knob_now - press_knob_last

        if power and math.abs(press_knob_diff) < 5 then
            press = press + press_knob_diff
        end

        press = clamp(press, 700, 1080)

        if get(vbe_std) == 1 then
            press = 1013
        end

        set(pressure, press)
    end

    -- Keep the selector history current on both SmartCopilot sides.
    press_knob_last = press_knob_now

    -- Flight-level selector.
    local fl_knob_now =
        normalizeKnob(get(fl_knob))

    flight_level = get(vbe_flightlevel)

    if MASTER then
        set(fl_knob, fl_knob_now)

        local fl_knob_diff =
            fl_knob_now - fl_knob_last

        if power and math.abs(fl_knob_diff) < 5 then
            flight_level =
                flight_level + fl_knob_diff * 100
        end

        flight_level =
            clamp(flight_level, 0, 12000)

        set(vbe_flightlevel, flight_level)
    end

    -- Keep the selector history current on both SmartCopilot sides.
    fl_knob_last = fl_knob_now

    -- Selected altitude display.
    if mode == 0 then
        flight_level_show = flight_level
    else
        flight_level_show =
            math.floor(
                flight_level
                * 3.280839895013
                * 0.001
                + 0.49
            )
            * 1000
    end

    -- Barometric altitude source.
    local static_fail_active =
        get(static_fail) == 6
        or get(sensors_caps) == 1

    local msl_ft =
        get(msl_alt) * 3.28083

    if not static_fail_active then
        vbe_MSL = msl_ft
    end

    local press_inHg =
        press * 0.0295300586467

    if power then
        altitude_ft =
            vbe_MSL
            + (press_inHg - get(msl_press)) * 1000
    end

    altitude_mtr =
        altitude_ft * 0.3048

    set(alt_mtr, altitude_mtr)

    -- Use one display altitude for both meter and feet modes.
    local display_alt

    if mode == 0 then
        display_alt = altitude_mtr
    else
        display_alt = altitude_ft
    end

    altitude_1000, altitude_100 =
        getAltitudeDrums(display_alt, mode)

    if altitude_100 <= -100 then
        altitude_100 = math.abs(altitude_100)
        negative = true
    else
        negative = false
    end

    -- E and minus flags.
    show_E =
        altitude_1000 < 1
        and altitude_1000 > -1

    minus_1 =
        negative
        and altitude_1000 > -1

    minus_10 =
        altitude_1000 <= -1

    -- Needle position.
    needle_angle =
        altitude_100 * 360 / 1000 + 90

    -- Selected-altitude border.
    border_mode =
        getBorderMode(
            display_alt,
            flight_level_show,
            mode
        )

    if border_mode == 2 then
        show_border = true
        border_blink_timer = 0

    elseif border_mode == 1 then
        border_blink_timer =
            border_blink_timer + passed

        if border_blink_timer > 0.5 then
            border_blink_timer = 0
            show_border = not show_border
        end

    else
        show_border = false
        border_blink_timer = 0
    end

    -- Altitude deviation warning transition.
    local entered_blink =
        mode_last ~= border_mode
        and border_mode == 1

    local entered_steady_from_hidden =
        mode_last == 0
        and border_mode == 2

    local alarm_transition =
        entered_blink
        or entered_steady_from_hidden

    if alarm_transition
        and self_test_timer > 8
        and num == 0
        and not external then

        sasl.al.playSample(vbe_alarm_snd, false)
    end

    mode_last = border_mode

    sasl.al.setSampleGain(
        vbe_alarm_snd,
        1000 * get(warning_volume_ratio)
    )

    -- Self-test after power-on.
    if power and self_test_timer < 9 then
        if self_test_timer < 4 then
            mode = 0
            show_E = false
            minus_1 = false
            minus_10 = false
            altitude_100 = 888
            altitude_1000 = 88
            flight_level_show = 88800
            show_border = false
            needle_angle = self_test_timer * 45 + 90
            border_mode = 2

        elseif self_test_timer < 8 then
            if not sasl.al.isSamplePlaying(vbe_alarm_snd)
                and self_test_timer < 5
                and num == 0
                and not external then

                sasl.al.playSample(vbe_alarm_snd, false)

            elseif external or self_test_timer >= 6 then
                sasl.al.stopSample(vbe_alarm_snd)
            end

            mode = 1
            show_E = false
            minus_1 = false
            minus_10 = false
            altitude_100 = 888
            altitude_1000 = 88
            flight_level_show = 88800
            show_border = true
            needle_angle = self_test_timer * 45 + 90
            border_mode = 2

        else
            mode = 0
            show_border = false
        end
    end
end


components = {

    -- Green background.
    textureLit {
        position = {0, 0, size[1], size[2]},
        image = green_img,
        visible = function()
            return power and mode == 0
        end,
    },

    -- Yellow background.
    textureLit {
        position = {0, 0, size[1], size[2]},
        image = yellow_img,
        visible = function()
            return power and mode == 1
        end,
    },

    -- Altitude needle.
    needle {
        position = {47.5, 47, 320, 320},
        image = needle_img,
        angle = function()
            return needle_angle
        end,
        visible = function()
            return power
                and not negative
                and altitude_100 >= 0
        end,
    },

    -- ALT flag.
    texture {
        position = {185, 213, 60, 25},
        image = ALT_img,
        visible = function()
            return power and mode == 1
        end,
    },

    -- FT flag.
    texture {
        position = {270, 168, 30, 25},
        image = ft_img,
        visible = function()
            return power and mode == 1
        end,
    },

    -- Meter flag.
    texture {
        position = {270, 168, 30, 25},
        image = mtr_img,
        visible = function()
            return power and mode == 0
        end,
    },

    -- E flag.
    texture {
        position = {137, 171, 22, 41},
        image = E_img,
        visible = function()
            return power and show_E
        end,
    },

    -- Altitude thousands.
    digitstape {
        position = {135, 168, 60, 50},
        image = bold_digitsImage,
        digits = 2,
        showLeadingZeros = false,
        allowNonRound = false,
        fractional = 0,
        showSign = false,
        value = function()
            return altitude_1000
        end,
        visible = function()
            return power
                and (
                    altitude_1000 >= 1
                    or altitude_1000 <= -1
                )
        end,
    },

    -- Tens-of-thousands minus flag.
    texture {
        position = {137, 175, 22, 33},
        image = minus_img,
        visible = function()
            return power and minus_10
        end,
    },

    -- Units minus flag.
    texture {
        position = {167, 175, 22, 33},
        image = minus_img,
        visible = function()
            return power and minus_1
        end,
    },

    -- Altitude hundreds.
    digitstape {
        position = {175, 168, 100, 40},
        image = bold_digitsImage,
        digits = 4,
        showLeadingZeros = function()
            return math.abs(altitude_1000) >= 1
        end,
        allowNonRound = false,
        fractional = 0,
        showSign = true,
        value = function()
            return altitude_100
        end,
        visible = function()
            return power
        end,
    },

    -- Green selected-altitude background.
    textureLit {
        position = {132, 245, 153, 51},
        image = green_img,
        visible = function()
            return power and mode == 0
        end,
    },

    -- Yellow selected-altitude background.
    textureLit {
        position = {132, 245, 153, 51},
        image = yellow_img,
        visible = function()
            return power and mode == 1
        end,
    },

    -- Selected altitude digits.
    digitstape {
        position = {145, 250, 130, 40},
        image = digitsImage,
        digits = 5,
        showLeadingZeros = false,
        allowNonRound = false,
        fractional = 0,
        showSign = false,
        value = function()
            return flight_level_show
        end,
        visible = function()
            return power
                and (
                    border_mode > 0
                    or flight_level_show == 0
                )
        end,
    },

    -- Zero selected-altitude digit.
    digitstape {
        position = {223, 250, 26, 40},
        image = digitsImage,
        digits = 1,
        showLeadingZeros = false,
        allowNonRound = false,
        fractional = 0,
        showSign = false,
        value = 0,
        visible = function()
            return power and flight_level_show == 0
        end,
    },

    -- Selected-altitude border.
    texture {
        position = {132, 245, 153, 51},
        image = borderg_img,
        visible = function()
            return power and show_border
        end,
    },

    -- Green pressure background.
    textureLit {
        position = {164, 92, 96, 48},
        image = green_img,
        visible = function()
            return power and mode == 0
        end,
    },

    -- Yellow pressure background.
    textureLit {
        position = {164, 92, 96, 48},
        image = yellow_img,
        visible = function()
            return power and mode == 1
        end,
    },

    -- Pressure digits.
    digitstape {
        position = {160, 100, 90, 35},
        image = digitsImage,
        digits = 4,
        showLeadingZeros = false,
        allowNonRound = false,
        fractional = 0,
        showSign = false,
        value = function()
            if self_test_timer <= 4 then
                return 1888
            end

            return press
        end,
        visible = function()
            return power
        end,
    },

    -- Russian hPa label.
    texture {
        position = {186, 140, 50, 25},
        image = hpa_rus_img,
        visible = function()
            return power and mode == 0
        end,
    },

    -- English hPa label.
    texture {
        position = {185, 140, 50, 25},
        image = hpa_eng_img,
        visible = function()
            return power and mode == 1
        end,
    },

    -- Brightness overlay.
    rectangle_ctr {
        R = 0,
        G = 0,
        B = 0,
        A = function()
            return 1 - brightness
        end,
        position_x = 0,
        position_y = 0,
        width = size[1],
        height = size[2],
        visible = function()
            return power
        end,
    },

    -- Foreground.
    texture {
        position = {0, 0, size[1], size[2]},
        image = scale_img,
    },
}
