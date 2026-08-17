-- scrollable tape

-- tape image
defineProperty("image")

-- size of visible area
defineProperty("window", { 1.0, 1.0 } )

-- amount to scroll horizontal
defineProperty("scrollX", 0)

-- amount to scroll vertically
defineProperty("scrollY", 0)

local WHITE = { 1, 1, 1, 1 }

-- draw tape
function draw()
    local sz = get(window)
    local imageId = get(image)
    local textureWidth, textureHeight = sasl.gl.getTextureSize(imageId)
    sasl.gl.drawTexturePart(imageId, 0, 0, 100, 100,
        get(scrollX) * textureWidth, get(scrollY) * textureHeight,
        sz[1] * textureWidth, sz[2] * textureHeight, WHITE)
end

