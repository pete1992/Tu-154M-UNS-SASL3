-- this script draws table of failures

size = {100, 100}

local text_font = sasl.gl.loadBitmapFont('basic_font.fnt')
local COLOR_BLACK = { 0, 0, 0, 1 }

defineProperty("drawTable") -- table of failures
defineProperty("maxDraw") -- table of failures

function draw()
	
	local tbl = get(drawTable)

	local pos = 0
	
	local count = get(maxDraw)
	
	for k, v in ipairs(tbl) do
		
		if pos < count / 2 then
			sasl.gl.drawBitmapText(text_font, 0, -pos * 30,
				v, TEXT_ALIGN_LEFT, COLOR_BLACK)
		elseif pos < get(maxDraw) then
			sasl.gl.drawBitmapText(text_font, 500, -(pos - count / 2) * 30,
				v, TEXT_ALIGN_LEFT, COLOR_BLACK)
		end
		
		pos = pos + 1
	
	end
	
end
