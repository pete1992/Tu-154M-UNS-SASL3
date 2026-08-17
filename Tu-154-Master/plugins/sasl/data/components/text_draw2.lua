-- text_draw2.lua
-- Generic text drawing component supporting regular and bitmap fonts.

defineProperty("text", "")
defineProperty("color", {0, 0, 0, 1})
defineProperty("bitmap", false)
defineProperty("font")
defineProperty("font_size", 24)

local fallback_font = sasl.gl.loadFont("avia.ttf")

local function isEnabled(value)
    return value == true or value == 1
end

function draw()
    local c = get(color)
    local font_handle = get(font)
    local text_value = tostring(get(text) or "")

    if not font_handle then
        font_handle = fallback_font
    end

    if not font_handle then
        return
    end

    if isEnabled(get(bitmap)) then
        sasl.gl.drawBitmapText(
            font_handle,
            0,
            0,
            text_value,
            TEXT_ALIGN_LEFT,
            {c[1], c[2], c[3], c[4]}
        )
    else
        sasl.gl.drawText(
            font_handle,
            0,
            0,
            text_value,
            get(font_size),
            false,
            false,
            TEXT_ALIGN_LEFT,
            {c[1], c[2], c[3], c[4]}
        )
    end
end
