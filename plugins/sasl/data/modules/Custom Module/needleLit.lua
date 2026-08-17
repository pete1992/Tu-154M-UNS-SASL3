
-- default angle
defineProperty("angle", 0)

-- no image
defineProperty("image")

local WHITE = { 1, 1, 1, 1 }

function draw()
    local imageId = get(image)
    local w, h = sasl.gl.getTextureSize(imageId)
    
    local max = w
    if h > max then
        max = h
    end

    local rw = (w / max) * 100
    local rh = (h / max) * 100
    sasl.gl.drawRotatedTexture(imageId, get(angle),
        (100 - rw) / 2, (100 - rh) / 2, rw, rh, WHITE)
end

