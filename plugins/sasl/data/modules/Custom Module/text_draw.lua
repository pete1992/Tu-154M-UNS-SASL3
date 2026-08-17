-- this is text drawing component

defineProperty("text")
defineProperty("color", { 0, 0, 0, 1 })
defineProperty("font", sasl.gl.loadBitmapFont("basic_font.fnt"))

function draw()
	local c = get(color)
	sasl.gl.drawBitmapText(get(font), 0, 0, get(text), TEXT_ALIGN_LEFT, c)
end
