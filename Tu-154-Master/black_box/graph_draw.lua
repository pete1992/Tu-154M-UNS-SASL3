
function getParamIndex(paramName)
  local found = false
  
  for k, v in pairs(mainTable) do
    if v.name == paramName then 
      return k 
    end 
    if found then break end
  end
  
  return nil
  
end

function getStartEndID(tab, startTime, endTime)
  
  local startID = 1
  local endID = 1
  local foundStart = false
  
  for k, v in ipairs(mainTable[1].data) do
    if v >= startTime and not foundStart then
      foundStart = true
      startID = k
    end
    
    if v >= endTime then
      endID = k
      break
    end
  end
  
  return startID, endID
  
end

function getRange(tab, startID, endID)
  local max = tab.data[startID]
  local min = tab.data[startID]
  
  for i = startID, endID do
    if tab.data[i] < min then min = tab.data[i]
    elseif tab.data[i] > max then max = tab.data[i]
    end
    
  end
  
  if max - min < 0.2 then
    min = min - 0.1
    max = max + 0.1
  end
  
  return min, max

end

function pointVertPos(value, valMin, valMax, posLow, posHigh) -- value, minimum value, maximum value, low coordinate, high coordinate
  
  local pixelPerVal = (posHigh - posLow) / (valMax - valMin)
  local zeroValPos = -valMin * pixelPerVal
  local valPos = value * pixelPerVal + zeroValPos + posLow
  
  return valPos
  --return (value - valMin) * (posHigh - posLow) / (valMax - valMin) + posLow

end

function pointHorPos(value, valMin, valMax)
  
  local pixelPerVal = workPlace.w / (valMax - valMin)
  local zeroValPos = -valMin * pixelPerVal
  local valPos = value * pixelPerVal + zeroValPos + workPlace.x
  
  return valPos
  
end

-- selected table, minimum time, maximum time, minimum value, maximum value, low coordinate, high coordinate, step of time, step of values, show grid or not
function draw_graph(tabID, tabFirstNum, tabLastNum, timeMin, timeMax, rangeMin, rangeMax, vertLow, vertHigh, timeStep, rangeStep, showGrid)
  
  -- move borders to make room for graph name
  vertHigh = vertHigh + 20
  
  -- draw grid
  if showGrid then
    
    -- draw time lines
    for i = math.floor(timeMin/timeStep)*timeStep, math.floor(timeMax/timeStep)*timeStep, timeStep do
        if i > timeMin and i < timeMax then
          local x = pointHorPos(i, timeMin, timeMax)
          love.graphics.setColor(50,50,50,255)
          love.graphics.line(x, vertLow, x, vertHigh)
        end
    end

    -- draw horizontal lines
    for i = math.floor(rangeMin/rangeStep)*rangeStep, math.floor(rangeMax/rangeStep)*rangeStep, rangeStep do
        if i > rangeMin and i < rangeMax then
          if i < 0.001 and i > -0.001 then i = 0 end
          
          local y = pointVertPos(i, rangeMin, rangeMax, vertLow, vertHigh)
          love.graphics.setColor(50,50,50,255)
          love.graphics.line(workPlace.x, y, workPlace.w+workPlace.x, y)
          love.graphics.setColor(255,255,255,255)
          love.graphics.print(i, workPlace.x - 50, y-5)
        end
    end
    
    -- draw borders
    love.graphics.setColor(255,255,255,255)
    love.graphics.rectangle( "line", workPlace.x, vertHigh, workPlace.w, vertLow - vertHigh)
    
    -- draw graph group
    love.graphics.print(mainTable[tabID].group, workPlace.x, vertHigh - 15)
    
  end
  
  -- draw zero line
  if rangeMin < 0 and rangeMax > 0 then
    love.graphics.setColor(128,128,128,255)
    love.graphics.line(workPlace.x, pointVertPos(0, rangeMin, rangeMax, vertLow, vertHigh), workPlace.w + workPlace.x, pointVertPos(0, rangeMin, rangeMax, vertLow, vertHigh))
  end
  
  -- draw graph itself
  
  for i = tabFirstNum+1, tabLastNum do      
    
    local time1 = mainTable[1].data[i-1]
    local time2 = mainTable[1].data[i]
    local data1 = mainTable[tabID].data[i-1]
    local data2 = mainTable[tabID].data[i]
    
    local x1 = pointHorPos(time1, timeMin, timeMax)
    local y1 = pointVertPos(data1, rangeMin, rangeMax, vertLow, vertHigh)
    local x2 = pointHorPos(time2, timeMin, timeMax)
    local y2 = pointVertPos(data2, rangeMin, rangeMax, vertLow, vertHigh)
    
    -- color
    love.graphics.setColor(colorTBL[namesTable[tabID].color].r, colorTBL[namesTable[tabID].color].g, colorTBL[namesTable[tabID].color].b, 255)
    if ((data1 > mainTable[tabID].limits.max and data2 > mainTable[tabID].limits.max) or 
      (data1 < mainTable[tabID].limits.min and data2 < mainTable[tabID].limits.min)) and
      (mainTable[tabID].limits.max ~= 0 and mainTable[tabID].limits.min ~= 0)
    then
      love.graphics.setColor(255,0,0,255)
    end
    -- draw line
    love.graphics.line(x1, y1, x2, y2)
  end
  
end
