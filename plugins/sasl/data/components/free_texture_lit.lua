-- free_texture_lit.lua
-- Generic illuminated texture drawing component.

defineProperty("image")
defineProperty("position_x", 0)
defineProperty("position_y", 0)
defineProperty("width", 100)
defineProperty("height", 100)

function draw()
    local texture = get(image)

    if not texture then
        return
    end

    sasl.gl.drawTexture(
        texture,
        get(position_x),
        get(position_y),
        get(width),
        get(height),
        {1, 1, 1, 1}
    )
end
