
--local pitch = 0
local attPosX, attPosY = 215, 190
local R = 0
local IAS = 0
local baroAlt = 0
local M = 0
local vviPos = 0
local VVI = 0
local vviUnit = "m/s"
local course = 0
local engN1 = {0,0,0,0,0,0}
local engREV = {false, false, false, false, false, false}
local engNum = 0
local engLim = {100,100,100,100,100,100}
local CS = 0
local GS = 0
local CSFlag = 0
local GSFlag = 0
local R_Alt = 0
local R_altUnit = "m"

local flapLPos = 0
local flapRPos = 0
local slatsPos = 0

local ailPosL = 0
local ailPosR = 0
local elevPosL = 0
local elevPosR = 0
local rudderR = 52
local rudderX = 0
local rudderY = rudderR
local stab = 0

local gear = false

local spoilerOutL = 0
local spoilerMidL = 0
local spoilerInnL = 0

local spoilerOutR = 0
local spoilerMidR = 0
local spoilerInnR = 0

local marker = 0

function line (x, x1, y1, x2, y2) -- returns Y on the line with two points by given X 
  
	if x2 - x1 ~= 0 then 
		return (x - x1)*(y2 - y1)/(x2 - x1) + y1
	else return y1 
	end

end

function gaugeUpdate(dt, tab)
  
  -- pitch
  attQuad:setViewport(0, attHeight/2 - attViewportH/2 - tab.pitch * 3.26, attWidth, attViewportH)
  
  -- other
  R = math.rad(tab.roll)
  IAS = tab.ias
  baroAlt = tab.baroAlt
  M = tab.mach
  VVI = tab.vvi
  
  local vviCoef = 1
  if not tab.isMPS then vviCoef = 0.005080; vviUnit = "ft/min" end
  
  -- vvi pos
  if VVI*vviCoef > 30 then vviPos = 111
  elseif VVI*vviCoef > 10 and VVI*vviCoef <= 30 then
    vviPos = line(VVI*vviCoef, 10, 81, 30, 110)
  elseif VVI*vviCoef > 5 and VVI*vviCoef <= 10 then
    vviPos = line(VVI*vviCoef, 5, 41, 10, 81)  
  elseif VVI*vviCoef > -5 and VVI*vviCoef < 5 then
    vviPos = line(VVI*vviCoef, -5, -41, 5, 42)
  elseif VVI*vviCoef < -5 and VVI*vviCoef >= -10 then
    vviPos = line(VVI*vviCoef, -5, -41, -10, -81) 
  elseif VVI*vviCoef < -10 and VVI*vviCoef >= -30 then
    vviPos = line(VVI*vviCoef, -10, -81, -30, -110)
  elseif VVI*vviCoef < -30 then vviPos = -111
  
  end
  
  course = tab.crs
  
  engNum = tab.engNum
  
  if engNum > 0 then
    for i = 1, engNum do
      engN1[i] = math.abs(tab.engN1[i])
      engLim[i] = tab.engLim[i]
      engREV[i] = tab.engN1[i] < 0
    end
    
  end
  
  CS = tab.CS
  GS = tab.GS 
  CSFlag = tab.CSFlag
  GSFlag = tab.GSFlag
  
  R_Alt = tab.R_Alt
  R_altUnit = tab.R_altUnit
  
  flapLPos = tab.flapL * 55 / tab.flapsLim
  flapRPos = tab.flapR * 55 / tab.flapsLim
  slatsPos = tab.slats * 42 / tab.slatsLim
  
  -- flight controls
  ailPosL = tab.ailL * 20 * 2 / (tab.ailLim[2] - tab.ailLim[1])
  ailPosR = tab.ailR * 20 * 2 / (tab.ailLim[2] - tab.ailLim[1])
  
  elevPosL = -tab.elevL * 20 * 2 / (tab.elevLim[2] - tab.elevLim[1])
  elevPosR = -tab.elevR * 20 * 2 / (tab.elevLim[2] - tab.elevLim[1])
  
  local rudAng = math.rad(-tab.rudder)
  rudderX = math.sin(rudAng) * rudderR
  rudderY = math.cos(rudAng) * rudderR
  
  stab = string.format("%.1f", tab.stab)
  
  gear = tab.gear == 1
  
  spoilerOutL = tab.spoilerOutL * 30
  spoilerMidL = tab.spoilerMidL * 34
  spoilerInnL = tab.spoilerInnL * 38

  spoilerOutR = tab.spoilerOutR * 30
  spoilerMidR = tab.spoilerMidR * 34
  spoilerInnR = tab.spoilerInnR * 38
  
  marker = tab.marker
  
end

local function drawRoll()
  
  local cx = 215
  local cy = 190
  local r = 128
  
  local topX = cx + math.sin(R+math.pi) * r 
  local topY = cy + math.cos(R+math.pi) * r
  
  local leftX = cx + math.sin(R+math.pi-math.pi*0.03) * r*0.9
  local leftY = cy + math.cos(R+math.pi-math.pi*0.03) * r*0.9
  
  local rightX = cx + math.sin(R+math.pi+math.pi*0.03) * r*0.9
  local rightY = cy + math.cos(R+math.pi+math.pi*0.03) * r*0.9
  
  love.graphics.setColor(255,237,49,255)
  --love.graphics.points( topX, topY )
  
  love.graphics.polygon( "line", topX, topY, leftX, leftY, rightX, rightY )
  
end

function gaugeDraw()
  -- att gauge
  love.graphics.draw(att_img, attQuad, attPosX, attPosY, -R, 1, 1, attWidth/2, attViewportH/2)
  
  love.graphics.setLineWidth( 3 )
  drawRoll() -- Roll triangle
  
  love.graphics.setLineWidth( 1 )
  -- IAS strip
  love.graphics.setColor(50,45,70,255)
  love.graphics.rectangle("fill", 20, 60, 52, 260)
   
  love.graphics.setColor(255,255,255,255)
  
  -- draw scale lines
  for i = math.floor((IAS - 30)/5)*5, math.floor((IAS + 30)/5)*5, 5 do
    local y = 190 - (i-IAS) * 5
    love.graphics.line(60, y, 70, y)
  end
  
  -- draw scale text
  for i = math.floor((IAS - 30)/10)*10, math.floor((IAS + 30)/10)*10, 10 do
    local y = 183 - (i-IAS) * 5
    love.graphics.printf( i, 25, y, 30, "right" )
    
    y = 191 - (i-IAS) * 5
    love.graphics.line(60, y, 70, y)
    love.graphics.line(60, y-2, 70, y-2)
  end  
  
  -- Baro alt strip
  love.graphics.setColor(50,45,70,255)
  love.graphics.rectangle("fill", 361, 60, 62, 260)
   
  love.graphics.setColor(255,255,255,255)
  
  -- draw scale lines
  for i = math.floor((baroAlt - 300)/50)*50, math.floor((baroAlt + 300)/50)*50, 50 do
    local y = 190 - (i-baroAlt) * 0.5
    love.graphics.line(361, y, 371, y)
  end
  
  -- draw scale text
  for i = math.floor((baroAlt - 300)/100)*100, math.floor((baroAlt + 300)/10)*100, 100 do
    local y = 183 - (i-baroAlt) * 0.5
    love.graphics.printf( i, 375, y, 50, "left" )
    
    y = 191 - (i-baroAlt) * 0.5
    love.graphics.line(361, y, 371, y)
    love.graphics.line(361, y-2, 371, y-2)
  end  
  
  -- Course
  love.graphics.setColor(50,45,70,255)
  love.graphics.rectangle("fill", 85, 349, 260, 38)
   
  love.graphics.setColor(255,255,255,255)
  
  -- draw scale lines
  for i = math.floor((course - 60)/5)*5, math.floor((course + 60)/5)*5, 5 do
    local x = 215 + (i-course) * 3
    love.graphics.line(x, 351, x, 355)
  end
  
  for i = math.floor((course - 60)/10)*10, math.floor((course + 60)/10)*10, 10 do
    local x = 215 + (i-course) * 3
    love.graphics.line(x, 351, x, 358)
    love.graphics.line(x-1, 351, x-1, 358)
    love.graphics.line(x+1, 351, x+1, 358)
  end
  
  -- draw course text
  for i = math.floor((course - 60)/20)*20, math.floor((course + 60)/20)*20, 20 do
    local x = 215 + (i-course) * 3
    
    local text = i
    while text <= 0 do text = text + 360 end
    
    love.graphics.printf(text, x-20, 359, 40, "center")
    
  end  
  
  love.graphics.line(215, 351, 215, 386)
  
  -- att mask 
  love.graphics.draw(att_mask, 0, 0)
  
  -- print actual altitude
  love.graphics.print(math.floor(baroAlt/10)*10, 380, 184)
  
  -- print mach number
  love.graphics.setColor(50, 150, 200)
  love.graphics.print(math.floor(M*100)*0.01, 25, 40, 0, 1.5)
  
  -- draw VVI needle
  love.graphics.setLineWidth( 3 )
  love.graphics.setColor(50, 255, 50)
  love.graphics.line(454, 191-vviPos, 480, 191-vviPos*0.5)
  
  -- draw VVI text
  local vviText = string.format("%.1f", math.floor(VVI*10)*0.1)
  love.graphics.printf(vviText, 435, 40, 40, "right", 0, 1.5) 
  love.graphics.printf(vviUnit, 450, 60, 40, "right") 
  
  -- ENG RPM gauges
  love.graphics.setLineWidth( 1 )
  if engNum > 0 then
    for i = 1, engNum do
      -- draw scales
      love.graphics.setColor(50,255,50,255)
      if engN1[i] > engLim[i] then love.graphics.setColor(255,0,0,255) end
      
      local height = 100 * engN1[i] / engLim[i]
      height = math.min(height, engLim[i]+engLim[i]*0.1)
      
      love.graphics.rectangle("fill", 15+(i-1)*40, 520 - height, 10, height+1) -- gauge
      
      love.graphics.printf(math.floor(engN1[i]), (i-1)*40, 390, 40, "center") -- text
      
      love.graphics.setColor(255,255,255,255)
      love.graphics.rectangle("line", 15+(i-1)*40, 410, 10, 111) -- border
      
      if not engREV[i] then
        love.graphics.print("#"..i, 11+(i-1)*40, 525) -- engine number
      else
        love.graphics.setColor(255,50,50,255)
        love.graphics.print("REV", 8+(i-1)*40, 525) -- Reverse
      end
      
    end
  end
  
  -- ILS
  love.graphics.setColor(255,237,49,255)
  love.graphics.setLineWidth( 3 )
  love.graphics.line(215+CS*40, 326, 215+CS*40, 348) -- Course
  love.graphics.line(330, 191+GS*40, 357, 191+GS*40) -- Glideslope
  
  -- ILS flags
  
  if CSFlag == 1 then
    love.graphics.setColor(255,50,50,255)
    love.graphics.rectangle("fill", 175, 325, 80, 23)
    love.graphics.setColor(0,0,0,255)
    love.graphics.print("CS", 198, 324, 0, 2) 
  end
  
  if GSFlag == 1 then
    love.graphics.setColor(255,50,50,255)
    love.graphics.rectangle("fill", 333, 151, 23, 80)
    love.graphics.setColor(0,0,0,255)
    love.graphics.printf("GS", 335, 162, 10, "center", 0, 2) 
  end
  
  love.graphics.setColor(255,237,49,255)
  love.graphics.print("RA "..string.format("%.0f", R_Alt)..R_altUnit, 360, 325, 0, 1) 
  
  -- flaps
  love.graphics.setLineWidth( 1 )
  
  love.graphics.setColor(255,50,50,255)
  love.graphics.rectangle("line", 438+flapLPos, 369+flapLPos/7, 10, 6)
  love.graphics.line(438, 369, 438+flapLPos, 369+flapLPos/7)
  
  love.graphics.setColor(50,255,50,255)
  love.graphics.rectangle("line", 438+flapRPos, 369+flapRPos/7, 10, 6)
  love.graphics.line(438, 369, 438+flapRPos, 369+flapRPos/7)
  
  love.graphics.rectangle("line", 411-slatsPos, 369+slatsPos/6.5, 10, 6)
  love.graphics.line(411+10, 369, 411-slatsPos+10, 369+slatsPos/6.5)
  
  love.graphics.setLineWidth( 3 )
  love.graphics.line(402, 455, 402+rudderX, 455+rudderY) -- rudder
  
  love.graphics.line(300, 435+ailPosL, 307, 435+ailPosL) -- aileron L
  love.graphics.polygon("fill", 300, 435+ailPosL, 300-10, 435+ailPosL+5, 300-10, 435+ailPosL-5)  
  
  love.graphics.line(499, 435+ailPosR, 506, 435+ailPosR) -- aileron R
  love.graphics.polygon("fill", 506, 435+ailPosR, 506+10, 435+ailPosR+5, 506+10, 435+ailPosR-5)
  
  love.graphics.line(350, 487+elevPosL, 360, 487+elevPosL) -- elevator L
  love.graphics.polygon("fill", 350, 487+elevPosL, 350-10, 487+elevPosL+5, 350-10, 487+elevPosL-5)
  
  love.graphics.line(445, 487+elevPosR, 455, 487+elevPosR) -- elevator R
  love.graphics.polygon("fill", 455, 487+elevPosR, 455+10, 487+elevPosR+5, 455+10, 487+elevPosR-5)
  
  love.graphics.print("STAB", 473, 463) -- stab
  love.graphics.printf(stab, 473, 480, 30, "right")
  
  love.graphics.setLineWidth( 2 )
  
  --love.graphics.rectangle("line", 381, 398, 42, 14)
  if not gear then 
    love.graphics.setColor(255,50,50,255)
    love.graphics.printf("GEAR UP", 381, 390, 42, "center") 
  else
    love.graphics.setColor(50,255,50,255)
    love.graphics.printf("GEAR DOWN", 381, 390, 42, "center")
  end
  
  -- spoilers
  love.graphics.setColor(50,255,50,255)
  love.graphics.rectangle("fill", 315, 450-spoilerOutL+1, 20, spoilerOutL+1 )
  love.graphics.rectangle("fill", 337, 450-spoilerMidL+1, 20, spoilerMidL+1 )
  love.graphics.rectangle("fill", 359, 450-spoilerInnL+1, 20, spoilerInnL+1 )
  
  love.graphics.rectangle("fill", 469, 450-spoilerOutR+1, 20, spoilerOutR+1 )
  love.graphics.rectangle("fill", 447, 450-spoilerMidR+1, 20, spoilerMidR+1 )
  love.graphics.rectangle("fill", 425, 450-spoilerInnR+1, 20, spoilerInnR+1 )
  
  -- markers
  if marker == 1 then -- inner
    love.graphics.setColor(255,255,255,255)
    love.graphics.circle("fill", 215, 25, 15)
    love.graphics.setColor(0,0,0,255)
    love.graphics.print("I", 213, 15, 0, 1.5)
  elseif marker == 2 then -- middle
    love.graphics.setColor(255,255,50,255)
    love.graphics.circle("fill", 215, 25, 15)
    love.graphics.setColor(0,0,0,255)
    love.graphics.print("M", 208, 15, 0, 1.5)
  elseif marker == 3 then -- outer
    love.graphics.setColor(100,150,255,255)
    love.graphics.circle("fill", 215, 25, 15)
    love.graphics.setColor(0,0,0,255)
    love.graphics.print("O", 208, 15, 0, 1.5)
  end
  
  -- zero cross
  --love.graphics.line(attPosX-attWidth/2, attPosY, attPosX+attWidth/2, attPosY) -- hor
  --love.graphics.line(attPosX, attPosY-attViewportH/2, attPosX, attPosY+attViewportH/2) -- vert
  love.graphics.setLineWidth( 1 )
  love.graphics.setColor(255,255,255,255)
end
