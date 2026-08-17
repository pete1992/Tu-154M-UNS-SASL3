-- texture.lua
-- Generic texture drawing component.

-- Texture supplied by the parent component.
defineProperty("image")

function draw()
    local texture = get(image)

    if not texture then
        return
    end

    sasl.gl.drawTexture(
        texture,
        0,
        0,
        size[1],
        size[2]
    )
end
