colorTBL = {}
colorID = 1

-- fill color table
table.insert(colorTBL, {["r"] = 0, ["g"] = 0,["b"] = 0})

for R = 1, 4 do
  for G = 1, 4 do
    for B = 1, 4 do
      table.insert(colorTBL, {["r"] = R*64-1, ["g"] = G*64-1,["b"] = B*64-1})
    end
  end
end

-- draw color table
function drawColors(x, y)
      -- draw color table
    for k, v in ipairs(colorTBL) do
      --print(v.r .." ".. v.g .." ".. v.b)
      if k ~= 1 then
      love.graphics.setColor(v.r, v.g, v.b, 255)
      love.graphics.rectangle( "fill", x + (k-2)*20 - math.floor((k-2)/16)*20*16, y + math.floor((k-2)/16)*20, 20, 20)
      love.graphics.setColor(0, 0, 0, 255)
      love.graphics.print(k, 11 + 2 + (k-2)*20 - math.floor((k-2)/16)*20*16, 31 + 4 + math.floor((k-2)/16)*20)
      end
    end
  
end