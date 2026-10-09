-- draw_map.lua
-- Draw TAWS terrain cells from a height-color table.

size = { 100, 80 }

defineProperty("image_table") -- Terrain color indices by column and row.
defineProperty("colors") -- table of colors
defineProperty("size_x") -- Terrain grid column count.
defineProperty("size_y") -- Terrain grid row count.

function draw()
    local drawTable = get(image_table)
    local colorTable = get(colors)
    local x_sz = get(size_x)
    local y_sz = get(size_y)
    local cor_x = 100 / x_sz
    local cor_y = 80 / y_sz

    for x = 1, x_sz, 1 do
        local draw_row = drawTable[x]
        local y = 1
        while y <= y_sz do
            local color_id = draw_row[y]
            local next_y = y + 1
            -- Merge adjacent cells of the same color without changing the map grid.
            while next_y <= y_sz and draw_row[next_y] == color_id do
                next_y = next_y + 1
            end
            local color = colorTable[color_id]
            local r = color[1]
            local g = color[2]
            local b = color[3]
            sasl.gl.drawRectangle((x - 1) * cor_x, (y - 1) * cor_y, cor_x, (next_y - y) * cor_y, r, g, b, 1)
            y = next_y
        end
    end
end
