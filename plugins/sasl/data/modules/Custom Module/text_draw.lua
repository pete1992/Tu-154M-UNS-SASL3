-- Generic text drawing component for scalable and legacy bitmap fonts.
--
-- The 2D panels were authored for a 24 px outline font.  Using the fixed-size
-- 40 px basic_font bitmap here makes every payload value and ground-service
-- status overflow its field under SASL 3.

defineProperty("text", "")
defineProperty("color", {0, 0, 0, 1})
defineProperty("monospace", false)
defineProperty("font_size", 24)
defineProperty("font", nil)
defineProperty("italic", false)
-- nil keeps compatibility with the older callers: an explicitly supplied
-- font was historically a bitmap font, while the fallback is scalable.
defineProperty("bitmap", nil)

local fallbackFont = sasl.gl.loadFont("AVIA.ttf")

local function isEnabled(value)
    return value == true or value == 1
end

function draw()
    local suppliedFont = get(font)
    local drawFont = suppliedFont or fallbackFont

    if not drawFont then
        return
    end

    local c = get(color)
    local bitmapMode = get(bitmap)
    local drawAsBitmap

    if bitmapMode == nil then
        drawAsBitmap = suppliedFont ~= nil
    else
        drawAsBitmap = isEnabled(bitmapMode)
    end

    if drawAsBitmap then
        sasl.gl.drawBitmapText(
            drawFont,
            0,
            0,
            tostring(get(text) or ""),
            TEXT_ALIGN_LEFT,
            {c[1], c[2], c[3], c[4]}
        )
        return
    end

    if isEnabled(get(monospace)) then
        sasl.gl.setFontRenderMode(drawFont, TEXT_RENDER_FORCED_MONO)
    end

    sasl.gl.drawText(
        drawFont,
        0,
        0,
        tostring(get(text) or ""),
        get(font_size),
        false,
        isEnabled(get(italic)),
        TEXT_ALIGN_LEFT,
        {c[1], c[2], c[3], c[4]}
    )
end
