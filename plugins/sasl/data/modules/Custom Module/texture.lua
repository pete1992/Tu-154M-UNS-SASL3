-- texture.lua
-- Draws a texture across the component area.

-- Texture supplied by the parent component.
defineProperty("image")

function draw()
    local texture = get(image)

    if not texture then
        return
    end

    sasl.gl.drawTexture(texture, 0, 0, size[1], size[2])
end
