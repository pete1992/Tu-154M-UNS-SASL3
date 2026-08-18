-- text_draw.lua
-- Generic bitmap text drawing component.

defineProperty("text", "")
defineProperty("color", {0, 0, 0, 1})
defineProperty("font", nil)

local fallbackFont = sasl.gl.loadBitmapFont("basic_font.fnt")

function draw()
    local drawFont = get(font)

    if not drawFont then
        drawFont = fallbackFont
    end

    if not drawFont then
        return
    end

    local c = get(color)

    sasl.gl.drawBitmapText(
        drawFont,
        0,
        0,
        tostring(get(text) or ""),
        TEXT_ALIGN_LEFT,
        {c[1], c[2], c[3], c[4]}
    )
end
