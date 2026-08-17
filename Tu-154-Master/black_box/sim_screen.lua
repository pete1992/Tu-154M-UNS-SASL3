playSPD = 0
playPos = 1
playDir = 1

local pitchID = nil
local rollID  = nil
local iasID = nil
local altID = nil
local machID = nil
local vviID = nil
local crsID = nil
local engIDs = {0,0,0,0,0,0}
local CS_ID = nil
local GS_ID = nil
local CS_FlagID = nil
local GS_FlagID = nil
local RaltID = nil

local flapL_ID = nil
local flapR_ID = nil
local slatID = nil

local ailLID = nil
local ailRID = nil
local elevLID = nil
local elevRID = nil
local ruddID = nil
local stabID = nil
local gearID = nil

local spoilerOutLID = nil
local spoilerMidLID = nil
local spoilerInnLID = nil

local spoilerOutRID = nil
local spoilerMidRID = nil
local spoilerInnRID = nil

local markerID = nil

local dataTable = {}

dataTable.lat = 0
dataTable.long = 0
dataTable.trueCRS = 0

dataTable.pitch = 0
dataTable.roll = 0
dataTable.ias = 0
dataTable.baroAlt = 0
dataTable.mach = 0
dataTable.vvi = 0
dataTable.isMPS = true -- true if vvi is MPS and false if vvi is FPM
dataTable.crs = 0
dataTable.engN1 = {0,0,0,0,0,0}
dataTable.engLim = {100,100,100,100,100,100}
dataTable.engNum = 0
dataTable.CS = 0
dataTable.GS = 0
dataTable.CSFlag = 1
dataTable.GSFlag = 1
dataTable.R_Alt = 0
dataTable.R_altUnit = "m"
dataTable.flapL = 0
dataTable.flapR = 0
dataTable.flapsLim = 45
dataTable.slats = 0
dataTable.slatsLim = 20

dataTable.ailL = 0
dataTable.ailR = 0
dataTable.elevL = 0
dataTable.elevR = 0
dataTable.rudder = 0
dataTable.stab = 0

dataTable.ailLim = {20,20}
dataTable.elevLim = {20,20}

dataTable.gear = 0

dataTable.spoilerOutL = 0
dataTable.spoilerMidL = 0
dataTable.spoilerInnL = 0

dataTable.spoilerOutR = 0
dataTable.spoilerMidR = 0
dataTable.spoilerInnR = 0

dataTable.marker = 0

local altMin, altMax = 0, 0

-- returns value at given time
function getData(ID, timeID, isCRS)
  local P = 0
  if ID then
    if math.floor(timeID) == timeID then
      if mainTable[ID].data[timeID] then P = mainTable[ID].data[timeID] end
    else
      if mainTable[ID].data[math.floor(timeID)] and mainTable[ID].data[math.ceil(timeID)] then
        local a = mainTable[ID].data[math.floor(timeID)]
        local b = mainTable[ID].data[math.ceil(timeID)]
        
        if isCRS then 
          if a - b > 180 then a = a - 360
          elseif a - b < -180 then a = a + 360 end
          
        end
        
        P = line (timeID, math.floor(timeID), a, math.ceil(timeID), b)
      end
    end
    
    --
  end
  return P
  
end

function revealTimePos(time_x, valMin, valMax)
  local pixelPerVal = (love.graphics.getWidth() - 40) / (valMax - valMin)
  local zeroValPos = -valMin * pixelPerVal + 20
  local ID = math.floor((time_x - zeroValPos) / pixelPerVal)
  
  if ID < valMin then ID = valMin
    elseif ID > valMax then ID = valMax end
  
  return ID
end

local frameCounter = 0

local engTabFilled = false

function simMouseClick(x, y, button)
  
  if x > 50 and x < 80 and y > 750 and y < 780 then -- play button 50, 600
    playSPD = 1
  
  elseif x > 90 and x < 120 and y > 750 and y < 780 then -- pause button 90, 600
    playSPD = 0
    
  elseif x > 210 and x < 240 and y > 750 and y < 780 then -- increase speed button 210, 600
    if playSPD < 64 then playSPD = playSPD * 2 end
    if playSPD == 0 then playSPD = 1 end
    
  elseif x > 250 and x < 280 and y > 750 and y < 780 then -- decrease speed button 250, 600
    if playSPD > 0 then playSPD = playSPD / 2 end
    if playSPD < 1 then playSPD = 0 end
    
  elseif x > 10 and x < 40 and y > 750 and y < 780 then-- rewind button 10, 600
    playPos = 1
    playSPD = 0
  
  elseif x > 130 and x < 160 and y > 750 and y < 780 and love.keyboard.isDown("lshift") then -- ten steps back 130, 600
     playSPD = 0
    playPos = playPos - 10
    if playPos < 1 then playPos = 1 end
    keyTimer = 0
  
  elseif x > 170 and x < 200 and y > 750 and y < 780 and love.keyboard.isDown("lshift") then -- ten steps forward 170, 600
    playSPD = 0
    playPos = playPos + 10
    if playPos > #mainTable[1].data then playPos = #mainTable[1].data end
    keyTimer = 0
  
  elseif x > 130 and x < 160 and y > 750 and y < 780 then -- one step back 130, 600
    playSPD = 0
    if playPos > 1 then playPos = playPos - 1 end
  
  elseif x > 170 and x < 200 and y > 750 and y < 780 then -- one step forward 170, 600
    playSPD = 0
    if playPos < #mainTable[1].data then playPos = playPos + 1 end

  elseif x > 0 and x < love.graphics.getWidth() and y > 570 and y < 720 then -- move play position
    playPos = revealTimePos(x, 1, #mainTable[1].data)
  end
  
end

local keyTimer = 0

function simKeyPressed(key)

  if key == "space" then -- play/pause button
    if playSPD ~= 0 then playSPD = 0 else playSPD = 1 end
    
  elseif key == "up" then -- increase speed button
    if playSPD < 64 then playSPD = playSPD * 2 end
    if playSPD == 0 then playSPD = 1 end
  elseif key == "down" then -- decrease speed button
    if playSPD > 0 then playSPD = playSPD / 2 end
    if playSPD < 1 then playSPD = 0 end
    
  elseif key == "backspace" then-- rewind button
    playPos = 1
    playSPD = 0
  elseif key == "left" and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then -- ten steps behind
    playSPD = 0
    playPos = playPos - 20
    if playPos < 1 then playPos = 1 end
    keyTimer = 0
  elseif key == "right" and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then -- ten steps forward
    playSPD = 0
    playPos = playPos + 20
    if playPos > #mainTable[1].data then playPos = #mainTable[1].data end
    keyTimer = 0
  elseif key == "left" then -- one step behind
    playSPD = 0
    if playPos > 1 then playPos = playPos - 1 end
    keyTimer = 0
  elseif key == "right" then -- one step forward
    playSPD = 0
    if playPos < #mainTable[1].data then playPos = playPos + 1 end
    keyTimer = 0
  end
  
end

function timeHorPos(value, valMin, valMax)
  
  local pixelPerVal = (love.graphics.getWidth() - 40) / (valMax - valMin)
  local zeroValPos = -valMin * pixelPerVal + 20
  local valPos = value * pixelPerVal + zeroValPos
  
  return valPos
  
end

function simUpdate(dt)
  
  keyTimer = keyTimer + dt -- slow down key press response
  
  -- mouse down
  local mx = love.mouse.getX()
  local my = love.mouse.getY()  
  local md = love.mouse.isDown(1)
  --if love.mouse.isGrabbed() then print("grab") end
  
  if (love.keyboard.isDown( "right" ) or (md and mx > 170 and mx < 200 and my > 600 and my < 630)) and keyTimer > 0.3 then
    playSPD = 0
    if playPos < #mainTable[1].data then playPos = playPos + 1 end
    keyTimer = 0
  elseif (love.keyboard.isDown( "left" ) or (md and mx > 130 and mx < 160 and my > 600 and my < 630)) and keyTimer > 0.3 then
    playSPD = 0
    if playPos > 1 then playPos = playPos - 1 end
    keyTimer = 0
  end
  
  if playPos <= #mainTable[1].data and playPos >= 1 then
    
    -- get data IDs
    if not pitchID then pitchID = getParamIndex("Pitch") end
    if not rollID then rollID = getParamIndex("Roll") end
    if not iasID then iasID = getParamIndex("Airspeed") end
    if not altID then altID = getParamIndex("Baro alt") end
    if not machID then machID = getParamIndex("Mach No") end
    if not vviID then vviID = getParamIndex("Vertical spd") end
    if not crsID then crsID = getParamIndex("Mag CRS") end
    
    if not engTabFilled then
      for i = 1, 6 do
        local ID = getParamIndex("ENG "..i.." RPM") -- ENG 1 RPM
        if ID then 
          engIDs[i] = ID
          dataTable.engNum = dataTable.engNum + 1
        end
        
       end
       engTabFilled = true
    end
    
    -- ILS
    if not CS_ID then CS_ID = getParamIndex("ILS CRS") end
    if not GS_ID then GS_ID = getParamIndex("ILS GS") end
    if not CS_FlagID then CS_FlagID = getParamIndex("CRS Flag") end
    if not GS_FlagID then GS_FlagID = getParamIndex("GS Flag") end
    
    if not RaltID then RaltID = getParamIndex("Radio alt") end
    
    if not flapL_ID then flapL_ID = getParamIndex("Flaps L") end
    if not flapR_ID then flapR_ID = getParamIndex("Flaps R") end
    if not slatID then slatID = getParamIndex("Slats") end
    
    if not ailLID then ailLID = getParamIndex("Aileron L") end
    if not ailRID then ailRID = getParamIndex("Aileron R") end
    if not elevLID then elevLID = getParamIndex("Elevator L") end
    if not elevRID then elevRID = getParamIndex("Elevator R") end
    if not ruddID then ruddID = getParamIndex("Rudder") end
    if not stabID then stabID = getParamIndex("Stab pos") end
    
    if not gearID then gearID = getParamIndex("Gear Down") end
    
    if not spoilerOutLID then spoilerOutLID = getParamIndex("Spoiler OUT L") end
    if not spoilerMidLID then spoilerMidLID = getParamIndex("Spoiler MID L") end
    if not spoilerInnLID then spoilerInnLID = getParamIndex("Spoiler INN L") end
    
    if not spoilerOutRID then spoilerOutRID = getParamIndex("Spoiler OUT R") end
    if not spoilerMidRID then spoilerMidRID = getParamIndex("Spoiler MID R") end
    if not spoilerInnRID then spoilerInnRID = getParamIndex("Spoiler INN R") end
    
    if not markerID then markerID = getParamIndex("Marker") end
    
    -- get data itself
    dataTable.lat = getData(3, playPos)
    dataTable.long = getData(4, playPos)
    dataTable.trueCRS = getData(5, playPos, true)
    
    dataTable.pitch = getData(pitchID, playPos)
    dataTable.roll = getData(rollID, playPos)
    dataTable.ias = getData(iasID, playPos)
    dataTable.baroAlt = getData(altID, playPos)
    dataTable.mach = getData(machID, playPos)
    dataTable.vvi = getData(vviID, playPos)
    dataTable.isMPS = mainTable[vviID].units == "m/s"

    dataTable.crs = getData(crsID, playPos, true)
    
    if engTabFilled and dataTable.engNum > 0 then
      for i = 1, dataTable.engNum do
        dataTable.engN1[i] = getData(engIDs[i], playPos)
        dataTable.engLim[i] = mainTable[engIDs[i]].limits.max
      end
    end
    
    dataTable.CS = getData(CS_ID, playPos)
    dataTable.GS = getData(GS_ID, playPos)
    dataTable.CSFlag = getData(CS_FlagID, playPos)
    dataTable.GSFlag = getData(GS_FlagID, playPos)
    
    if not dataTable.CS then dataTable.CSFlag = 1 end
    if not dataTable.GS then dataTable.GSFlag = 1 end
    
    dataTable.R_Alt = getData(RaltID, playPos)
    dataTable.R_altUnit = mainTable[RaltID].units
    
    dataTable.flapL = getData(flapL_ID, playPos)
    dataTable.flapR = getData(flapR_ID, playPos)
    dataTable.slats = getData(slatID, playPos)
    
    dataTable.flapsLim = mainTable[flapL_ID].limits.max
    dataTable.slatsLim = mainTable[slatID].limits.max
    
    dataTable.ailL = getData(ailLID, playPos)
    dataTable.ailR = getData(ailRID, playPos)
    dataTable.elevL = getData(elevLID, playPos)
    dataTable.elevR = getData(elevRID, playPos)
    dataTable.rudder = getData(ruddID, playPos)
    dataTable.stab = getData(stabID, playPos)
    
    dataTable.ailLim = {mainTable[ailLID].limits.min, mainTable[ailLID].limits.max}
    dataTable.elevLim = {mainTable[elevLID].limits.min, mainTable[elevLID].limits.max}

    dataTable.gear = getData(gearID, playPos)
    
    dataTable.spoilerOutL = getData(spoilerOutLID, playPos)
    dataTable.spoilerMidL = getData(spoilerMidLID, playPos)
    dataTable.spoilerInnL = getData(spoilerInnLID, playPos)

    dataTable.spoilerOutR = getData(spoilerOutRID, playPos)
    dataTable.spoilerMidR = getData(spoilerMidRID, playPos)
    dataTable.spoilerInnR = getData(spoilerInnRID, playPos)
    
    dataTable.marker = getData(markerID, playPos)
    
    playPos = playPos + playSPD * dt -- play simulation

  end
  
  -- stop playing at the edge
  if playPos > #mainTable[1].data or playPos < 1 then
    if playPos > #mainTable[1].data then playPos = #mainTable[1].data
    elseif playPos < 1 then playPos = 1
    end
    
    playSPD = 0
    
    --playDir = -playDir
    frameCounter = 0
  end
  
  gaugeUpdate(dt, dataTable)
  
  altMin, altMax = getRange(mainTable[6], 1, #mainTable[6].data)
  
end

function simDraw()
  gaugeDraw() -- big gauge
  
  -- draw buttons --
  -- rewind button
  love.graphics.rectangle("line", 10, 750, 30, 30)
  love.graphics.print("|<", 17, 757)
  -- play button
  love.graphics.rectangle("line", 50, 750, 30, 30)
  love.graphics.print(">", 60, 757)
  -- pause speed
  love.graphics.rectangle("line", 90, 750, 30, 30)
  love.graphics.print("||", 100, 757)
  -- one step behind speed
  love.graphics.rectangle("line", 130, 750, 30, 30)
  love.graphics.print("<|", 138, 757)
  -- one step ahead speed
  love.graphics.rectangle("line", 170, 750, 30, 30)
  love.graphics.print("|>", 178, 757)
  -- decrease speed
  love.graphics.rectangle("line", 210, 750, 30, 30)
  love.graphics.print("+", 220, 757)
  -- increase speed
  love.graphics.rectangle("line", 250, 750, 30, 30)
  love.graphics.print("_", 262, 752)
  
  -- draw timeline
  love.graphics.line(20, 700, love.graphics.getWidth() - 20, 700)
  love.graphics.line(20, 680, 20, 720)
  love.graphics.line(love.graphics.getWidth() - 20, 680, love.graphics.getWidth() - 20, 720)
  -- draw time stamps line
  love.graphics.setColor(100,100,100)
  for i = 1, #mainTable[1].data do
    local x = timeHorPos(i, 1, #mainTable[1].data)
    love.graphics.line(x, 695, x, 705)
  end
  
  -- draw timeSlider
  local playX = timeHorPos(playPos, 1, #mainTable[1].data)
  love.graphics.setColor(50,255,50,50)
  love.graphics.rectangle("fill", playX - 10, 690, 20, 20)
  love.graphics.setColor(50,255,50,255)
  love.graphics.rectangle("line", playX - 10, 690, 20, 20)
  love.graphics.line(playX, 570, playX, 710)
  
  love.graphics.printf(math.floor(mainTable[6].data[math.floor(playPos)]), playX-25, 550, 50, "center")
  
  -- draw time stamp
  love.graphics.setColor(255,255,255,255)
  love.graphics.print("Flight time: "..mainTable[2].data[math.floor(playPos)].."   Play speed: "..playSPD, 10, 730)
  
  -- draw temp ID stamp
  if love.mouse.getY() > 570 and love.mouse.getY() < 720 then
    local IDx = revealTimePos(love.mouse.getX(), 1, #mainTable[1].data)
    love.graphics.print("Click to jump to: "..mainTable[2].data[math.floor(IDx)], 10, 785)
  end
  
  -- draw altitude borders
  love.graphics.rectangle("line", 20, 570, love.graphics.getWidth() - 40, 100)
  
  -- draw altitude graph
  for i = 2, #mainTable[6].data do      
    
    --local time1 = mainTable[1].data[i-1]
    --local time2 = mainTable[1].data[i]
    local data1 = mainTable[6].data[i-1]
    local data2 = mainTable[6].data[i]
    
    local x1 = timeHorPos(i-1, 1, #mainTable[6].data)--pointHorPos(time1, timeMin, timeMax)
    local y1 = pointVertPos(data1, 0, altMax, 670, 570)
    local x2 = timeHorPos(i, 1, #mainTable[6].data)
    local y2 = pointVertPos(data2, 0, altMax, 670, 570)
    
    -- color
    love.graphics.setColor(255,0,0,255)

    -- draw line
    love.graphics.line(x1, y1, x2, y2)
  end
  
  love.graphics.setColor(255,255,255,255)
  love.graphics.print("Altitude MSL", 22, 572)
  
end
