-- draw texture

-- no default texture
defineProperty("image")
defineProperty("alpha", 1)

function draw()
	local a = get(alpha)
    sasl.gl.drawTexture(get(image), 0, 0, 100, 100, { a, a, a, 1 })
end

