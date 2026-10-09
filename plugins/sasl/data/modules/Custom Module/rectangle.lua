-- rectangle.lua
-- Draws a filled rectangle using the supplied color.

defineProperty("color", { 0.15, 0.15, 0.15, 1.0 })

function draw()
    sasl.gl.drawRectangle(0, 0, size[1], size[2], get(color))
end
