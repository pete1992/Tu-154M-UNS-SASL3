-- needle.lua
-- Generic rotating needle component.

-- Needle rotation angle.
defineProperty("angle", 0)

-- Texture supplied by the parent component.
defineProperty("image")

function draw()
    local texture = get(image)

    if not texture then
        return
    end

    local w, h = sasl.gl.getTextureSize(texture)

    if not w or not h or w <= 0 or h <= 0 then
        return
    end

    local maxDim = math.max(w, h)
    local rw = (w / maxDim) * size[1]
    local rh = (h / maxDim) * size[2]

    sasl.gl.drawRotatedTexture(
        texture,
        get(angle),
        (size[1] - rw) * 0.5,
        (size[2] - rh) * 0.5,
        rw,
        rh
    )
end
