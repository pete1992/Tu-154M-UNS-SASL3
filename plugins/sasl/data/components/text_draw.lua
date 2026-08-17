-- text_draw.lua
-- Generic bitmap text drawing component using basic_font.fnt.

defineProperty("text", "")
defineProperty("color", {0, 0, 0, 1})

local text_font = sasl.gl.loadBitmapFont("basic_font.fnt")

function draw()
    if not text_font then
        return
    end

    local c = get(color)

    sasl.gl.drawBitmapText(
        text_font,
        0,
        0,
        tostring(get(text) or ""),
        TEXT_ALIGN_LEFT,
        {c[1], c[2], c[3], c[4]}
    )
end
