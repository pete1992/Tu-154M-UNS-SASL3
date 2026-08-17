-- tape_lit.lua
-- Generic illuminated scrollable texture tape component.

-- Texture supplied by the parent component.
defineProperty("image")

-- Visible texture area in normalized texture coordinates.
defineProperty("window", {1.0, 1.0})

-- Horizontal source offset in normalized texture coordinates.
defineProperty("scrollX", 0)

-- Vertical source offset in normalized texture coordinates.
defineProperty("scrollY", 0)

function draw()
    local texture = get(image)

    if not texture then
        return
    end

    local texWidth, texHeight = sasl.gl.getTextureSize(texture)

    if not texWidth or not texHeight or texWidth <= 0 or texHeight <= 0 then
        return
    end

    local windowSize = get(window)
    local sourceX = get(scrollX) * texWidth
    local sourceY = get(scrollY) * texHeight
    local sourceWidth = windowSize[1] * texWidth
    local sourceHeight = windowSize[2] * texHeight

    sasl.gl.drawTexturePart(
        texture,
        0,
        0,
        size[1],
        size[2],
        sourceX,
        sourceY,
        sourceWidth,
        sourceHeight,
        {1, 1, 1, 1}
    )
end
