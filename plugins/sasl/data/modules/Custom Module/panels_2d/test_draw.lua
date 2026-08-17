-- test drawing to texture
size = {1024, 1024}

defineProperty("image")

function draw()
	
	sasl.gl.setRenderTarget(get(image))

	sasl.gl.drawTexture(get(image), 0, 0, size[1], size[2])

	sasl.gl.drawRectangle(0, 0, size[1], size[2], { 1, 1, 1, 1 })

	sasl.gl.restoreRenderTarget()

end
