-- this script draws table of runtimes

size = {100, 100}

local text_font = sasl.gl.loadBitmapFont('basic_font.fnt')
local COLOR_BLACK = { 0, 0, 0, 1 }
local COLOR_RED = { 1, 0, 0, 1 }

defineProperty("drawTable") -- table of heights
defineProperty("value") -- table of heights

function draw()
	
	local runtime = get(drawTable)
	local val = get(value)
	
	local runPos = 0
	
	for k,v in ipairs(runtime) do
		
		sasl.gl.drawBitmapText(text_font, 0, -runPos * 30,
			v[1].." : "..v[2].." "..val, TEXT_ALIGN_LEFT, COLOR_BLACK)
		runPos = runPos + 1
	end
	
	--[[
	for i = 1, #runtime do
		
		sasl.gl.drawBitmapText(text_font, 0, i * 10,
			runtime[i], TEXT_ALIGN_LEFT, COLOR_RED)
	
	end
	--]]
	
end

