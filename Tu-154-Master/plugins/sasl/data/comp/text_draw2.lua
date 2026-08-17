-- text_draw2.lua
-- Generic text drawing component supporting regular and bitmap fonts.

defineProperty("text", "")
defineProperty("color", {0, 0, 0, 1})

-- Set to true when the supplied font is a bitmap .fnt font.
defineProperty("bitmap", false)

-- Font supplied by the parent component.
defineProperty("font")

-- Fallback font used when no font is supplied.
local fallback_font = loadFont("avia.ttf")


function draw()
    local c = get(color)
    local font_handle = get(font)
    local text_value = tostring(get(text) or "")

    if not font_handle then
        font_handle = fallback_font
    end

    if get(bitmap) then
        drawBitmapText(
            font_handle,
            0,
            0,
            text_value,
            TEXT_ALIGN_LEFT,
            {c[1], c[2], c[3], c[4]}
        )
    else
        drawText(
            font_handle,
            0,
            0,
            text_value,
            c[1],
            c[2],
            c[3],
            c[4]
        )
    end
end
