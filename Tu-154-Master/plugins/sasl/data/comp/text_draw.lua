-- text_draw.lua
-- Generic bitmap text drawing component.

defineProperty("text", "")
defineProperty("color", {0, 0, 0, 1})

-- Bitmap font used by this component.
local text_font = loadBitmapFont("basic_font.fnt")


function draw()
    local c = get(color)

    drawBitmapText(
        text_font,
        0,
        0,
        tostring(get(text) or ""),
        TEXT_ALIGN_LEFT,
        c
    )
end
