aptTable = {}

function addAPT(ICAO, name)
  
  local a = {}
  
  a.ICAO = ICAO
  a.name = name
  a.runways = {}
  
  return a  
  
end

function addRWY(rwy1, lat1, lon1, rwy2, lat2, lon2)
  
  local a = {}
  
  a.rwy1 = rwy1
  a.lat1 = lat1
  a.lon1 = lon1
  a.rwy2 = rwy2
  a.lat2 = lat2
  a.lon2 = lon2
  
  return a

end

function readAPT()
  local file = io.open("runways.txt", "r")
  
  if file then
  
    while true do
      -- read each line
      local line = file:read("*line")
      
      if line == nil then break end -- stop reading file
      
      local a = 1
			local b = string.find(line, "\t", a) -- find TAB symbol
      
      -- if line is not empty, read it
      if b ~= nil then
        local lineID = string.sub(line, a, b-1)
        
        --local runways = 0 
        
        if lineID == "1" then -- found airport
          
          a = b+1
          b = string.find(line, "\t")
          
          local ICAO = string.sub(line, a, b-1)
          local name = string.sub(line, b+1, string.len(line))
          
          table.insert(aptTable, addAPT(ICAO, name)) -- create new airport entity
          --runways = 0 -- reset number of found runways for new airport
        
        elseif lineID == "2" then
           
          a = b+1
          b = string.find(line, "\t")
          
          local rwy1 = string.sub(line, a, b-1)
          
          a = b+1
          b = string.find(line, "\t")
          
          local lat1 = tonumber(string.sub(line, a, b-1))
          
          a = b+1
          b = string.find(line, "\t")
          
          local lon1 = tonumber(string.sub(line, a, b-1))
          
          a = b+1
          b = string.find(line, "\t")
          
          local rwy2 = string.sub(line, a, b-1)
          
          a = b+1
          b = string.find(line, "\t")
          
          local lat2 = tonumber(string.sub(line, a, b-1))
          
          a = b+1
          b = string.len(line)
          
          local lon2 = tonumber(string.sub(line, a, b-1))
          
          table.insert(aptTable[#aptTable].runways, addRWY(rwy1, lat1, lon1, rwy2, lat2, lon2))

        end
      
      end
      
    end

  end

  file:close()
  return true
end

