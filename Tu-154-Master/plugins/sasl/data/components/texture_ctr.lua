-- texture_ctr.lua
-- Generic texture component with adjustable opacity.

-- Texture supplied by the parent component.
defineProperty("image")

-- Texture opacity.
defineProperty("alpha", 1)

function draw()
    local texture = get(image)

    if not texture then
        return
    end

    local a = get(alpha)

    if a < 0 then
        a = 0
    elseif a > 1 then
        a = 1
    end

    sasl.gl.drawTexture(
        texture,
        0,
        0,
        size[1],
        size[2],
        {1, 1, 1, a}
    )
end
