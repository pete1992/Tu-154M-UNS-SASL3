mainTable = {}

function addParam(name)
  local a = {}
  
  a.name = name
  a.units = ""
  a.limits = {["min"] = 0, ["max"] = 0}
  a.group = ""
  a.data = {}
  
  return a
  
end

function readFile(fileName)
  
  -- open file
  local file = io.open(fileName, "r")
  
  if file then
    while true do
      -- read each line
      local line = file:read("*line")
      
      if line == nil then break end -- stop reading file
      
      local a = 1
			local b = string.find(line, "\t", a) -- find TAB symbol
      
      -- if line is not empty, read it
      if b ~= nil then
        local lineID = tonumber(string.sub(line, a, b-1))
        
        if lineID == 0 then -- found record name
          
          a = b
          b = string.len(line)
          
          local date = tonumber( string.sub(line, a, a+2) )
          local month = tonumber( string.sub(line, a+4, a+5) )
          local year = tonumber( string.sub(line, a+7, a+8) )
          local flight = string.sub(line, a+10, a+12)
          
          if month == 01 then month = "January"
          elseif month == 02 then month = "February"
          elseif month == 03 then month = "March"
          elseif month == 04 then month = "April"
          elseif month == 05 then month = "May"
          elseif month == 06 then month = "June"
          elseif month == 07 then month = "July"
          elseif month == 08 then month = "August"
          elseif month == 09 then month = "September"
          elseif month == 10 then month = "October"
          elseif month == 11 then month = "November"
          elseif month == 12 then month = "December"
          end
          
          love.window.setTitle("Black Box Decoder - ".. month.." "..date..", 20"..year.."  Flight: "..flight)
        
        elseif lineID == 1 then -- found parameters names
          
          while true do
            a = b+1 -- new position
            if a > string.len(line) then break end
            
            b = string.find(line, "\t", a) -- find TAB symbol
            
            if b == nil then break end
         
            local paramName = string.sub(line, a, b-1)
            -- create tables inside main table
            
            table.insert(mainTable, addParam(paramName))
            
          end
        
        elseif lineID == 2 then -- line with units
          
          local i = 1
          
          while true do

            a = b+1 -- new position
            if a > string.len(line) then break end
            
            b = string.find(line, "\t", a) -- find TAB symbol
            
            if b == nil or i > #mainTable then break end
            -- fill units field in tables
            local unit = string.sub(line, a, b-1)
            
            mainTable[i].units = unit
            
            i = i + 1
          
          end
          
        elseif lineID == 3 then -- line with limits
          
          local i = 1
          
          while true do

            a = b+1 -- new position
            if a > string.len(line) then break end
            
            b = string.find(line, "\t", a) -- find TAB symbol
            if b == nil or i > #mainTable then break end
            -- fill range fields in tables
            local a1 = a
            local b1 = string.find(line, "/", a1)
            local rangeMin = tonumber( string.sub(line, a1, b1-1) )
            
            a1 = b1 + 1
            b1 = b
            local rangeMax = tonumber( string.sub(line, a1, b1-1) )
            
            mainTable[i].limits.min = rangeMin
            mainTable[i].limits.max = rangeMax
       
            i = i + 1
          
          end  
        
        elseif lineID == 4 then -- line with groups
          
          local i = 1
          
          while true do

            a = b+1 -- new position
            if a > string.len(line) then break end
            
            b = string.find(line, "\t", a) -- find TAB symbol
            if b == nil or i > #mainTable then break end
            -- fill units field in tables
            local group = string.sub(line, a, b-1)
            
            mainTable[i].group = group
            
            i = i + 1
          
          end
        
        elseif lineID == 9 then -- line with data
          
          local i = 1
          
          while true do

            a = b+1 -- new position
            if a > string.len(line) then break end
            
            b = string.find(line, "\t", a) -- find TAB symbol
            if b == nil or i > #mainTable then break end
            -- fill data in tables
            local data = string.sub(line, a, b-1)
            
            if i ~= 2 then data = tonumber(data) end
            
            table.insert(mainTable[i].data, data)
      
            i = i + 1
          
          end

        end
 
      end
      
    end
  
  end
 
  file:close()
  
      -- reformat time data
      for k, v in ipairs(mainTable[2].data) do
        local timeSTR = v
        
        local a = 1
        local b = string.find(timeSTR, ":", a)
        
        local HH = string.sub(timeSTR, a, b-1)
        if string.len(HH) == 1 then HH = "0"..HH end
        
        a = b + 1
        b = string.find(timeSTR, ":", a)
        
        local MM = string.sub(timeSTR, a, b-1)
        if string.len(MM) == 1 then MM = "0"..MM end
        
        a = b + 1
        b = string.len(timeSTR)
        
        local SS = string.sub(timeSTR, a, b)
        if string.len(SS) == 1 then SS = "0"..SS end
        
        mainTable[2].data[k] = HH..":"..MM..":"..SS
        
      end
      
      -- set new window title
      love.window.setTitle(love.window.getTitle().." start - "..mainTable[2].data[1]..", end - "..mainTable[2].data[#mainTable[2].data])
      
      -- set new range of table IDs for start and end of the record
      ID1, ID2 = 1, #mainTable[1].data 
      
      -- set initial slider position
      sliderStart = ID1
      sliderEnd = ID2
  
end
