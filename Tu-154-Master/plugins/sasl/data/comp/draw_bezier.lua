-- draw_bezier.lua
-- Draws a quadratic Bezier curve.

size = {100, 100}

-- Start point
defineProperty("x_1", 0)
defineProperty("y_1", 0)

-- End point
defineProperty("x_2", 100)
defineProperty("y_2", 0)

-- Control point
defineProperty("x_p", 50)
defineProperty("y_p", 100)

-- Drawing parameters
defineProperty("quality", 100)
defineProperty("thickness", 1)

-- Color
defineProperty("color_r", 1)
defineProperty("color_g", 0)
defineProperty("color_b", 1)
defineProperty("color_a", 1)

function draw()
    local x1 = get(x_1)
    local y1 = get(y_1)
    local x2 = get(x_2)
    local y2 = get(y_2)
    local xp = get(x_p)
    local yp = get(y_p)

    local Q = math.floor(get(quality))
    local TH = get(thickness)

    local r = get(color_r)
    local g = get(color_g)
    local b = get(color_b)
    local a = get(color_a)

    -- Prevent invalid values
    if Q < 1 then Q = 1 end
    if TH < 0 then TH = 0 end

    -- Draw the Bezier curve
    for i = 0, Q do
        local t = i / Q

        -- Intermediate points on the two handle lines
        local xp1 = (xp - x1) * t + x1
        local yp1 = (yp - y1) * t + y1

        local xp2 = (x2 - xp) * t + xp
        local yp2 = (y2 - yp) * t + yp

        -- Final point on the Bezier curve
        local bx = (xp2 - xp1) * t + xp1
        local by = (yp2 - yp1) * t + yp1

        drawRectangle(bx - TH * 0.5, by - TH * 0.5, TH, TH, r, g, b, a)
    end
end
