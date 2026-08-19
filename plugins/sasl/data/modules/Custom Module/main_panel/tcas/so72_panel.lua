-- so72_panel.lua
-- SO-72 transponder panel and logic.

size = {440, 167}

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"xpdr_code", "sim/cockpit/radios/transponder_code", globalPropertyi},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"transponder_mode", "tu154/custom/switchers/ovhd/transponder_mode", globalPropertyi},
    {"transponder_control", "tu154/custom/buttons/ovhd/transponder_control", globalPropertyi},
    {"transponder_sign", "tu154/custom/buttons/ovhd/transponder_sign", globalPropertyi},
    {"transponder_but_1", "tu154/custom/buttons/ovhd/transponder_but_1", globalPropertyi},
    {"transponder_but_2", "tu154/custom/buttons/ovhd/transponder_but_2", globalPropertyi},
    {"transponder_but_3", "tu154/custom/buttons/ovhd/transponder_but_3", globalPropertyi},
    {"transponder_but_4", "tu154/custom/buttons/ovhd/transponder_but_4", globalPropertyi},
    {"transponder_emerg", "tu154/custom/buttons/ovhd/transponder_emerg", globalPropertyi},
    {"transponder_red", "tu154/custom/lights/small/transponder_red", globalPropertyf},
    {"transponder_green", "tu154/custom/lights/small/transponder_green", globalPropertyf},
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

local ident_cmd = sasl.findCommand("sim/transponder/transponder_ident")
local text_font = sasl.gl.loadBitmapFont("digital7_space.fnt")
local rot_sound = sasl.al.loadSample("Custom Sounds/rot_click_big.wav")
local button_sound = sasl.al.loadSample("Custom Sounds/plastic_btn.wav")

local FONT_SCALE = 2.5
local TEXT_X = 35
local TEXT_Y = 20

local power = false
local code_show = "0000"
local self_test = false
local self_test_cnt = 0

local mode_last = get(transponder_mode)

local button_last = {
    control = get(transponder_control),
    sign = get(transponder_sign),
    but_1 = get(transponder_but_1),
    but_2 = get(transponder_but_2),
    but_3 = get(transponder_but_3),
    but_4 = get(transponder_but_4),
    emerg = get(transponder_emerg),
}

set(transponder_red, 0)
set(transponder_green, 0)

local function getDigits(squawk)
    squawk = math.floor(squawk)

    local d1 = math.floor(squawk / 1000)
    squawk = squawk - d1 * 1000

    local d2 = math.floor(squawk / 100)
    squawk = squawk - d2 * 100

    local d3 = math.floor(squawk / 10)
    local d4 = squawk - d3 * 10

    return d1, d2, d3, d4
end

local function isPressed(current, previous)
    return current == 1 and previous ~= 1
end

local function buttonsChanged(
    control,
    sign,
    but_1,
    but_2,
    but_3,
    but_4,
    emerg
)
    return
        control ~= button_last.control or
        sign ~= button_last.sign or
        but_1 ~= button_last.but_1 or
        but_2 ~= button_last.but_2 or
        but_3 ~= button_last.but_3 or
        but_4 ~= button_last.but_4 or
        emerg ~= button_last.emerg
end

local function updateButtonStates(
    control,
    sign,
    but_1,
    but_2,
    but_3,
    but_4,
    emerg
)
    button_last.control = control
    button_last.sign = sign
    button_last.but_1 = but_1
    button_last.but_2 = but_2
    button_last.but_3 = but_3
    button_last.but_4 = but_4
    button_last.emerg = emerg
end

local function updateLamps(passed)
    if self_test then
        self_test_cnt = self_test_cnt + passed

        if self_test_cnt < 30 then
            set(transponder_red, 1)
            set(transponder_green, 0)

        elseif self_test_cnt < 55 then
            set(transponder_red, 0)
            set(transponder_green, 1)

        else
            self_test = false
            self_test_cnt = 0

            set(transponder_red, 0)
            set(transponder_green, 0)
        end

    else
        self_test_cnt = 0

        set(transponder_red, 0)
        set(transponder_green, 0)
    end
end

function update()
    local passed = get(frame_time)
    local MASTER = get(ismaster) ~= 1

    local mode = get(transponder_mode)

    local control = get(transponder_control)
    local sign = get(transponder_sign)
    local but_1 = get(transponder_but_1)
    local but_2 = get(transponder_but_2)
    local but_3 = get(transponder_but_3)
    local but_4 = get(transponder_but_4)
    local emerg = get(transponder_emerg)

    power = mode > 0 and get(bus27_volt_left) > 13

    -- Rotary switch sound
    if mode ~= mode_last then
        sasl.al.playSample(rot_sound, false)
    end

    mode_last = mode

    -- Button sound
    if buttonsChanged(
        control,
        sign,
        but_1,
        but_2,
        but_3,
        but_4,
        emerg
    ) then
        sasl.al.playSample(button_sound, false)
    end

    local control_pressed = isPressed(control, button_last.control)
    local sign_pressed = isPressed(sign, button_last.sign)
    local but_1_pressed = isPressed(but_1, button_last.but_1)
    local but_2_pressed = isPressed(but_2, button_last.but_2)
    local but_3_pressed = isPressed(but_3, button_last.but_3)
    local but_4_pressed = isPressed(but_4, button_last.but_4)
    local emerg_pressed = isPressed(emerg, button_last.emerg)

    local code = get(xpdr_code)
    local d1, d2, d3, d4 = getDigits(code)

    if power and MASTER then
        local code_changed = false

        -- Change transponder digits
        if but_1_pressed then
            d1 = d1 + 1

            if d1 > 7 then
                d1 = 0
            end

            code_changed = true
        end

        if but_2_pressed then
            d2 = d2 + 1

            if d2 > 7 then
                d2 = 0
            end

            code_changed = true
        end

        if but_3_pressed then
            d3 = d3 + 1

            if d3 > 7 then
                d3 = 0
            end

            code_changed = true
        end

        if but_4_pressed then
            d4 = d4 + 1

            if d4 > 7 then
                d4 = 0
            end

            code_changed = true
        end

        if code_changed then
            code = d1 * 1000 + d2 * 100 + d3 * 10 + d4
            set(xpdr_code, code)
        end

        -- Set emergency code
        if mode > 1 and emerg_pressed then
            code = 7700
            set(xpdr_code, code)
        end

        -- Send IDENT signal
        if mode > 1 and sign_pressed and ident_cmd then
            sasl.commandOnce(ident_cmd)
        end
    end

    -- Start transponder self-test
    if power and control_pressed then
        self_test = true
        self_test_cnt = 0
    end

    updateLamps(passed)

    code_show = string.format("%04d", math.floor(code))

    updateButtonStates(
        control,
        sign,
        but_1,
        but_2,
        but_3,
        but_4,
        emerg
    )
end

function draw()
    if not power or not text_font then
        return
    end

    sasl.gl.saveGraphicsContext()

    sasl.gl.setTranslateTransform(TEXT_X, TEXT_Y)
    sasl.gl.setScaleTransform(FONT_SCALE, FONT_SCALE)

    sasl.gl.drawBitmapText(
        text_font,
        0,
        0,
        code_show,
        TEXT_ALIGN_LEFT,
        {1, 0.3, 0.2, 1}
    )
    sasl.gl.restoreGraphicsContext()
end
