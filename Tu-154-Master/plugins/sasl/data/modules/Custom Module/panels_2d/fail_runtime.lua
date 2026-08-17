-- runtime_table.lua
-- Draws a table containing runtime values.

size = {100, 100}

-- Bitmap font used for runtime table text.
local text_font = loadBitmapFont("basic_font.fnt")

-- Runtime data table.
defineProperty("drawTable")

-- Unit or additional value displayed after each runtime entry.
defineProperty("value")


-- Draws all runtime entries as vertically arranged text rows.
function draw()
    local runtime = get(drawTable)
    local val = get(value)

    if type(runtime) ~= "table" then
        return
    end

    local runPos = 0

    for _, v in ipairs(runtime) do
        drawBitmapText(
            text_font,
            0,
            -runPos * 30,
            tostring(v[1]) .. " : " .. tostring(v[2]) .. " " .. tostring(val or ""),
            TEXT_ALIGN_LEFT,
            {0, 0, 0, 1}
        )

        runPos = runPos + 1
    end
end

