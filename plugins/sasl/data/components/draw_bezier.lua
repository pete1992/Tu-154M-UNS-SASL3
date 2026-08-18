-- this is the example of how to build a Bezier Curve

size = {100, 100}

-- pint 1
defineProperty("x_1", 0)
defineProperty("y_1", 0)
-- point 2
defineProperty("x_2", 100)
defineProperty("y_2", 0)
-- handle
defineProperty("x_p", 50)
defineProperty("y_p", 100)
-- aux params (quality is kept for compatibility with existing component declarations)
defineProperty("quality", 100)
defineProperty("thickness", 1)
-- colour
defineProperty("color_r", 1)
defineProperty("color_g", 0)
defineProperty("color_b", 1)
defineProperty("color_a", 1)

function draw()
	local color = { get(color_r), get(color_g), get(color_b), get(color_a) }
	sasl.gl.drawWideBezierLineQAdaptive(
		get(x_1), get(y_1),
		get(x_p), get(y_p),
		get(x_2), get(y_2),
		get(thickness), color
	)
end
