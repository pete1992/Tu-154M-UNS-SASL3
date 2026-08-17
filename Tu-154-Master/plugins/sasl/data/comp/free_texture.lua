-- free_texture.lua
-- Generic texture drawing component.

-- Texture supplied by the parent component.
defineProperty("image")

-- Texture position and size.
defineProperty("position_x", 0)
defineProperty("position_y", 0)
defineProperty("width", 100)
defineProperty("height", 100)


function draw()
    local texture = get(image)

    if not texture then
        return
    end

    drawTexture(
        texture,
        get(position_x),
        get(position_y),
        get(width),
        get(height)
    )
end

