-- define images
att_img = love.graphics.newImage("images/att.png")
att_mask = love.graphics.newImage("images/gauge_mask.png")
--icon = love.graphics.newImage("images/icon.png")

attWidth, attHeight = att_img:getDimensions()
attViewportH = 300
--print(attWidth, attHeight)
attQuad = love.graphics.newQuad( 0, attHeight/2 - attViewportH/2, attWidth, attViewportH, attWidth, attHeight )

-- define working place coordinates
workPlace = {x = 10, y = 30, w = love.graphics.getWidth() - 220, h = love.graphics.getHeight() - 100}

ID1, ID2 = 0, 0

-- flag for mouse pressed on the simulator screen
simScreenMousePress = false

sliderX = workPlace.x
sliderWidth = workPlace.w
sliderStart = ID1
sliderEnd = ID2
sliderGrabbed = false

require("readfile")
require("runways")
require("colors")
require("graph_draw")
require("graph_screen")

require("sim_gauge")
require("sim_screen")

local screenMode = 0 -- 0 = intro, 1 = graphs, 2 = simulator

function love.load()
  
  love.graphics.setBackgroundColor(100,100,100,255)
  readAPT()
  
end

-- work with dropped file
function love.filedropped(dropfile)
  
  fileName = dropfile:getFilename()
  
  -- check file name
  local strLen = string.len(fileName)
  local fileExt = string.sub(fileName, strLen-3, strLen)
  
  if fileExt == "bbox" then
  
    -- change title
    --love.window.setTitle("Black Box Decoder - "..fileName)
    showIntro = false
    screenMode = 1
    
    -- reset main table
    mainTable = {}
    -- read file
    readFile(fileName)
    fillNamesTable()

  end

end

function love.wheelmoved(x,y)
  
  if screenMode == 1 and love.mouse.getX() > workPlace.x + workPlace.w+10 then
    moveList(-y)
    updateGraphs()
  elseif screenMode == 1 then
    -- zoom and scroll charts
    if y > 0 and not love.keyboard.isDown("lalt") then zoomIn() end
    if y < 0 and not love.keyboard.isDown("lalt") then zoomOut() end
    if x < 0 then slideLeft() end
    if x > 0 then slideRight() end
    if love.keyboard.isDown("lalt") and y > 0 then slideLeft() end
    if love.keyboard.isDown("lalt") and y < 0 then slideRight() end
    
  end  
  
end

function love.mousepressed(x,y,button)
  
  -- mode button
  if x > love.graphics.getWidth()/2 - 150 and x < love.graphics.getWidth()/2 and y > love.graphics.getHeight() - 40 and y < love.graphics.getHeight() - 10 then
    if screenMode ~= 0 and button == 1 then
      if screenMode == 1 then screenMode = 2
      else screenMode = 1
      end
    end
  end
  
  -- work with buttons on graph screen
  if screenMode == 1 then 
    colorPick(x, y, button)
    setParamShow(x,y,button)
    UpDownClick(x,y,button)
    sliderButtons(x, y, button)
    updateGraphs()
  elseif screenMode == 2 then
    simMouseClick(x, y, button)
  
  end
  
  --if button == 2 then showColorsTable = true end

end

--[[
function love.mousereleased( x, y, button, istouch, presses )
  simScreenMousePress = false
  sliderGrabbed = false
end
--]]

function love.keypressed(key)
  if screenMode == 1 then  
    if key == "up" then zoomIn() end
    if key == "down" then zoomOut() end
    if key == "left" then slideLeft() end
    if key == "right" then slideRight() end
  elseif screenMode == 2 then
    simKeyPressed(key)
  end
  
end

function love.update(dt)
  
  if screenMode == 1 then
    -- resize working place
    --workPlace = {x = 10, y = 30, w = love.graphics.getWidth() - 220, h = love.graphics.getHeight() - 100}
    workPlace.x = 80
    workPlace.y = 30
    workPlace.w = love.graphics.getWidth() - 220 - workPlace.x
    workPlace.h = love.graphics.getHeight() - 150 - workPlace.y 
    
    --calculate slider position
    if ID1 ~= ID2 then
      sliderX = pointHorPos(sliderStart, 1, #mainTable[1].data)
      sliderWidth = pointHorPos(sliderEnd, 1, #mainTable[1].data) - sliderX
    end
  
  end
  
  if screenMode == 2 then simUpdate(dt) end
  
end

function love.draw()
  
  --love.graphics.setColor(255,255,255,255)
  --love.graphics.print("window: "..love.graphics.getWidth().." / "..love.graphics.getHeight())
  --love.graphics.print("mouse: "..love.mouse.getX().." / "..love.mouse.getY(), 0, 20)
  
  -- draw intro text
  if screenMode == 0 then 
    love.graphics.setColor(0,0,0,255)
    love.graphics.print( "Drop .bbox file here", love.graphics.getWidth()/2 - 100, love.graphics.getHeight()/2 - 10, 0, 2, 2, 0, 0, 0, 0 )
  elseif screenMode == 1 then
    drawGraphs()
    drawListButtons()
  elseif screenMode == 2 then
    simDraw()
  end
  
  if showColorsTable and screenMode == 1 then drawColors(colorTablePosX, colorTablePosY) end
  
  -- draw mode button
  if screenMode ~= 0 then
    love.graphics.setColor(255,255,255,255)
    love.graphics.rectangle( "line", love.graphics.getWidth()/2 - 150, love.graphics.getHeight() - 40, 150, 30)
    if screenMode == 1 then
      love.graphics.print("SIMULATOR", love.graphics.getWidth()/2 - 110, love.graphics.getHeight() - 32)
    else
      love.graphics.print("GRAPHICS", love.graphics.getWidth()/2 - 105, love.graphics.getHeight() - 32)
    end
    
  end
  
end
