-- draw_bezier.lua
-- Draws a quadratic Bezier curve using the native SASL 3 graphics API.

size = {100, 100}

defineProperty("x_1", 0)
defineProperty("y_1", 0)

defineProperty("x_2", 100)
defineProperty("y_2", 0)

defineProperty("x_p", 50)
defineProperty("y_p", 100)

defineProperty("quality", 100)
defineProperty("thickness", 1)

defineProperty("color_r", 1)
defineProperty("color_g", 0)
defineProperty("color_b", 1)
defineProperty("color_a", 1)

function draw()
    local parts = math.floor(get(quality))
    local thickness = get(thickness)

    if parts < 1 then
        parts = 1
    end

    if thickness < 0 then
        thickness = 0
    end

    sasl.gl.drawWideBezierLineQ(
        get(x_1),
        get(y_1),
        get(x_p),
        get(y_p),
        get(x_2),
        get(y_2),
        parts,
        thickness,
        {
            get(color_r),
            get(color_g),
            get(color_b),
            get(color_a)
        }
    )
end
