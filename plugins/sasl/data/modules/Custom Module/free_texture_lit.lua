
-- no default texture
defineProperty("image")
defineProperty("position_x", 0)
defineProperty("position_y", 0)
defineProperty("width", 100)
defineProperty("height", 100)
local WHITE = { 1, 1, 1, 1 }

function draw()
    sasl.gl.drawTexture(get(image), get(position_x), get(position_y), get(width), get(height), WHITE)
end

