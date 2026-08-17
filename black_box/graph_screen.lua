
namesTable = {}

local showParamsMin = 7
local showParamsMax = 37
local selectedParam = 0

showColorsTable = false
colorTablePosX = 11
colorTablePosY = 31

paramsDrawTable = {}

function addName(name, units, color, index, group)
  local a = {}
  
  a.name = name
  a.units = units
  
  if units == "mode" then a.units = "" end
  
  a.color = color
  a.show = false
  a.pos = 79 + (index - showParamsMin) * 20
  a.group = group
  return a
  
end

function updateGraphs()
  
  for k, v in ipairs(namesTable) do
    v.pos = 79 + (k - showParamsMin) * 20
  end
  
end

function fillNamesTable()
  for k, v in pairs(mainTable) do
    table.insert(namesTable, addName(v.name, v.units, k+2, k, v.group))
  end
  
end

function getParamsToDraw()
  
  paramsDrawTable = {} -- flush the draw table
  
  for k, v in ipairs(namesTable) do -- search the main table for selected parameters
    if v.show then
      -- scan table for groups
      local groupExist = false
      
      for i, m in ipairs(paramsDrawTable) do
        if m.group == v.group then
          groupExist = true
          table.insert(paramsDrawTable[i].ids, k)
          break
        end 
      
      end
      
      -- if no group found - create it.
      if not groupExist then
        paramsDrawTable[#paramsDrawTable + 1] = {group = v.group, ids = {k}}
      end
    
    end
    
  end
  
  return true
  
end

function drawListButtons()
  love.graphics.setColor(255,255,255,255)
  
  -- UP
  if showParamsMin > 7 then
    love.graphics.rectangle( "line", love.graphics.getWidth() - 150, 35, 100, 30 )
    love.graphics.line(love.graphics.getWidth() - 150, 65, love.graphics.getWidth() - 100, 35)
    love.graphics.line(love.graphics.getWidth() - 50, 65, love.graphics.getWidth() - 100, 35)
  end
  -- DOWN
  if showParamsMax < #namesTable then
    love.graphics.rectangle( "line", love.graphics.getWidth() - 150, 710, 100, 30 )
    love.graphics.line(love.graphics.getWidth() - 150, 710, love.graphics.getWidth() - 100, 740)
    love.graphics.line(love.graphics.getWidth() - 50, 710, love.graphics.getWidth() - 100, 740)
  end
  
end

function UpDownClick(x,y,button)
    -- UP
  if showParamsMin > 7 then
    if x > love.graphics.getWidth() - 150 and x < love.graphics.getWidth() - 150+100 
      and y > 35 and y < 35+30 then
        showParamsMin = showParamsMin - 1
        showParamsMax = showParamsMax - 1
    end
  end
  
  -- DOWN
  if showParamsMax < #namesTable then
    if x > love.graphics.getWidth() - 150 and x < love.graphics.getWidth() - 150+100 
      and y > 710 and y < 710+30 then
        showParamsMin = showParamsMin + 1
        showParamsMax = showParamsMax + 1
    end
  end  
  
  updateGraphs()
  
end

function zoomIn()
      
  if ID2 - ID1 > 40 then
    
    local range = ID2 - ID1
    local center = range / 2 + ID1
      
    ID1 = center - range * 0.3
    ID2 = center + range * 0.3
      
    if ID2 - ID1 < 40 then
      ID1 = center - 20
      ID2 = center + 20
    end

    ID1 = math.floor(ID1)
    ID2 = math.ceil(ID2)
      
    if ID1 < 1 then ID1 = 1 end
    if ID2 > #mainTable[1].data then ID2 = #mainTable[1].data end
      
    sliderStart = ID1
    sliderEnd = ID2
      
  end
end

function zoomOut()
  if ID2 - ID1 < #mainTable[1].data then
    
    local range = ID2 - ID1
    local center = range / 2 + ID1
      
    ID1 = center - range * 0.7
    ID2 = center + range * 0.7
      
    -- limit IDs
    if ID1 < 1 then ID1 = 1 end
    if ID2 > #mainTable[1].data then ID2 = #mainTable[1].data end
      
    ID1 = math.floor(ID1)
    ID2 = math.ceil(ID2)
      
    sliderStart = ID1
    sliderEnd = ID2
  
  end  
end

function slideLeft()
  
  local range = ID2 - ID1
  local center = range / 2 + ID1
  local newCenter = center - range / 4
  
  ID1 = newCenter - range * 0.5
  ID2 = newCenter + range * 0.5
  
  ID1 = math.floor(ID1)
  ID2 = math.ceil(ID2)
  
  -- limit IDs
  if ID1 < 1 then 
    ID1 = 1 
    ID2 = ID1 + range
  end
  
  if ID2 > #mainTable[1].data then 
    ID2 = #mainTable[1].data 
    ID1 = ID2 - range
  end
   
  sliderStart = ID1
  sliderEnd = ID2
  
end

function slideRight()
  
  local range = ID2 - ID1
  local center = range / 2 + ID1
  local newCenter = center + range / 4
  
  ID1 = newCenter - range * 0.5
  ID2 = newCenter + range * 0.5
  
  ID1 = math.floor(ID1)
  ID2 = math.ceil(ID2)
  
  -- limit IDs
  if ID1 < 1 then 
    ID1 = 1 
    ID2 = ID1 + range
  end
  
  if ID2 > #mainTable[1].data then 
    ID2 = #mainTable[1].data 
    ID1 = ID2 - range
  end

  sliderStart = ID1
  sliderEnd = ID2 
end

function sliderButtons(x, y, button)
  
  -- zoom IN
  if x >= workPlace.x-60 and x <= workPlace.x-40 and y >= workPlace.h+workPlace.y+70 and y <= workPlace.h+workPlace.y+90 then  
    zoomIn()
  end
  
  -- zoom OUT
  if x >= workPlace.x-30 and x <= workPlace.x-10 and y >= workPlace.h+workPlace.y+70 and y <= workPlace.h+workPlace.y+90 then
    zoomOut()
  end
  
  -- slide Left
  if x >= workPlace.x-60 and x <= workPlace.x-40 and y >= workPlace.h+workPlace.y+40 and y <= workPlace.h+workPlace.y+60 then  
    slideLeft()
  end
  
  -- slide Right
  if x >= workPlace.x-30 and x <= workPlace.x-10 and y >= workPlace.h+workPlace.y+40 and y <= workPlace.h+workPlace.y+60 then
    slideRight()
  end
  
end

function moveList(dir)

  -- move list
  showParamsMin = showParamsMin + dir
  showParamsMax = showParamsMax + dir
  
  -- limit list
  if showParamsMin < 7 then
    showParamsMin = 7
    showParamsMax = math.min(37, #namesTable)
  elseif showParamsMax > #namesTable then
    showParamsMin = math.max(#namesTable - 30, 6)
    showParamsMax = #namesTable
  end
  
end

function colorPick(x, y, button)

  if button == 2 then 
    showColorsTable = false
    selectedParam = 0
  end
  
  -- remove color table, if click outside
  if showColorsTable and (x < colorTablePosX or x > colorTablePosX + 20*16 or y < colorTablePosY or y > colorTablePosY + 20*4 ) then
    selectedParam = 0
    showColorsTable = false
  end
  
  if button == 1 then 
    
    if not showColorsTable then
      for k, v in pairs(namesTable) do
        if k >= showParamsMin and k <= showParamsMax then
          if x > love.graphics.getWidth() - 190 and x < love.graphics.getWidth() - 190 + 30 and y > v.pos and y < v.pos + 18 then
            showColorsTable = true
            selectedParam = k
          end
        end
      end
    end

    -- set color ID
    if showColorsTable then
      for X = 1, 16 do
        for Y = 1, 4 do
          if x > colorTablePosX + (X-1)*20 and x < 11 + (X-1)*20 + 20 and y > colorTablePosY + (Y-1)*20 and y < 31 + (Y-1)*20 + 20 then
            colorID = (Y-1) * 16 + X + 1
            namesTable[selectedParam].color = colorID
            showColorsTable = false
            break
          end 
        end
      end
      
    end
    
  end
  
end

function setParamShow(x,y,button)

  for k, v in pairs(namesTable) do
    if k >= showParamsMin and k <= showParamsMax then
      if x > love.graphics.getWidth() - 155 and x < love.graphics.getWidth() - 155 + 100 and y > v.pos and y < v.pos + 18 then
        v.show = not v.show 
        getParamsToDraw()
      end
    end
  end

end

function getStep(Min, Max, height)
  
  local range = math.abs(Max - Min)
  
  local step = 10 ^ math.floor(math.log10(range))
  
  -- check amount of steps to fit into the view
  local count = math.floor(range / step)
  
  if height / count > 150 then step = step / 10 end
  if step < 0.1 then step = 0.1 end

  return step

end

function getTimeStep(Min, Max)
  
  local range = Max - Min
  
  local step = 5
  
  while range / step > 13 do
    step = step * 2
  end
  
  return step

end

function drawGraphs()
  -- set new colors
    love.graphics.setBackgroundColor(colorTBL[1].r, colorTBL[1].g, colorTBL[1].b, 255)
        
    -- draw screen table
    love.graphics.setColor(255,255,255,255)
    love.graphics.line(workPlace.x + workPlace.w+10, 0, workPlace.x + workPlace.w+10, love.graphics.getHeight()) -- parameters vertical line
    --love.graphics.line(workPlace.x + workPlace.w+10, workPlace.y, love.graphics.getWidth(), workPlace.y) -- parameters horizontal line
    
    -- draw graphs borders
    love.graphics.setColor(255,255,255,255)
    love.graphics.rectangle( "line", workPlace.x-60, workPlace.y, workPlace.w+60, workPlace.h + 10)
    love.graphics.print("FLIGHT DATA", love.graphics.getWidth()/2 - 120, 10)
    love.graphics.print("PARAMETERS", love.graphics.getWidth() - 140, 10)
    
    if ID1 ~= ID2 then
    
      -- draw parameters names
      for i = showParamsMin, math.min(showParamsMax, #namesTable) do
        if namesTable[i].show then
          love.graphics.setColor(colorTBL[65].r, colorTBL[65].g, colorTBL[65].b, 255)
        else
          love.graphics.setColor(colorTBL[23].r, colorTBL[23].g, colorTBL[23].b, 255)
        end
        
        love.graphics.print(namesTable[i].name.." - "..namesTable[i].units , love.graphics.getWidth() - 150, 80 + (i - showParamsMin) * 20)
      end
      
      -- draw parameters colors
      for i = showParamsMin, showParamsMax do
        love.graphics.setColor(colorTBL[namesTable[i].color].r, colorTBL[namesTable[i].color].g, colorTBL[namesTable[i].color].b, 255)
        love.graphics.rectangle( "fill", love.graphics.getWidth() - 190, namesTable[i].pos, 30, 18)
      end  
      
      -- calculate time range
      local timeStep = getTimeStep(mainTable[1].data[ID1], mainTable[1].data[ID2])
      local timeMin = mainTable[1].data[ID1]
      local timeMax = mainTable[1].data[ID2]
      
      -- draw graphs
      local graphCount = #paramsDrawTable
      if graphCount ~= 0 then
        for i, t in pairs(paramsDrawTable) do

          -- calculate range
          local num = t.ids[1]
          local rangeMin, rangeMax = getRange(mainTable[t.ids[1]], ID1, ID2)
          
          for k, v in pairs(t.ids) do
            local min, max = getRange(mainTable[v], ID1, ID2)
            if min < rangeMin then rangeMin = min end
            if max > rangeMax then rangeMax = max end
          end

          -- calculate position
          local upPos = workPlace.y + (i - 1) * workPlace.h / graphCount
          local downPos = upPos + workPlace.h / graphCount
          -- calculate range step for a grid
          local rangeStep = getStep(rangeMin, rangeMax, downPos - upPos)
          -- draw graph
          for k, v in pairs(t.ids) do

            draw_graph(v, ID1, ID2, timeMin, timeMax, rangeMin, rangeMax, downPos, upPos, timeStep, rangeStep, k==1)
      
          end
        end
      else
        love.graphics.setColor(255,255,255,255)
        love.graphics.print("NO DATA SELECTED", 100, 100)
      
      end
      
      -- draw time stamps
      love.graphics.setColor(255,255,255,255)
      for i = math.floor(timeMin/timeStep)*timeStep, math.floor(timeMax/timeStep)*timeStep, timeStep do
          if i > timeMin and i < timeMax then
            local x = pointHorPos(i, timeMin, timeMax)
            
            local timeID1, timeID2 = getStartEndID(mainTable[1].data, i - 0.5, i + 0.5)
            
            local num = mainTable[2].data[timeID1]
            
            if x < workPlace.x+workPlace.w - 20 then            
              love.graphics.print(num, x-30, workPlace.h+workPlace.y+15)
            end
          end
      end
      
      -- draw slider
      love.graphics.setColor(50,255,50,255)
      love.graphics.rectangle("fill", sliderX, workPlace.h + workPlace.y + 40, sliderWidth, 20)
      love.graphics.print(mainTable[2].data[ID1].."   -   "..mainTable[2].data[ID2], workPlace.x + workPlace.w/2 - 65, workPlace.h + workPlace.y + 70)
      
      -- draw time scale
      love.graphics.setColor(255,255,255,255)
      love.graphics.line(workPlace.x, workPlace.h+workPlace.y+50, workPlace.x+workPlace.w, workPlace.h+workPlace.y+50)
      love.graphics.line(workPlace.x, workPlace.h+workPlace.y+40, workPlace.x, workPlace.h+workPlace.y+60)
      love.graphics.line(workPlace.x+workPlace.w, workPlace.h+workPlace.y+40, workPlace.x+workPlace.w, workPlace.h+workPlace.y+60)
      
      -- draw slider buttons
      love.graphics.rectangle( "line", workPlace.x-60, workPlace.h+workPlace.y+70, 20, 20)
      love.graphics.print("+", workPlace.x-55, workPlace.h+workPlace.y+72)
      love.graphics.rectangle( "line", workPlace.x-30, workPlace.h+workPlace.y+70, 20, 20)
      love.graphics.print("-", workPlace.x-23, workPlace.h+workPlace.y+72)
      
      love.graphics.rectangle( "line", workPlace.x-60, workPlace.h+workPlace.y+40, 20, 20)
      love.graphics.print("<", workPlace.x-55, workPlace.h+workPlace.y+42)
      love.graphics.rectangle( "line", workPlace.x-30, workPlace.h+workPlace.y+40, 20, 20)
      love.graphics.print(">", workPlace.x-23, workPlace.h+workPlace.y+42)
      
  else
    love.graphics.setColor(255,255,255,255)
    love.graphics.print("Corrupted or empty file", 100, 100)
  
  end
  
end

