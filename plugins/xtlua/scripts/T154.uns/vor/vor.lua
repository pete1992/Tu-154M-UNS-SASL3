local vor1=""
local vor2=""
local dme1=""
local dme2=""
nSize=0
lastUpdate=0
local navAids
function tu154_vor_auto()
    
    local diff = simDR_time - lastUpdate
    if diff < 10 then 
        return 
    end
    --print("do RNAV" .. nSize)
    
    lastUpdate=simDR_time
    local lat=simDR_lat
    local lon=simDR_long
    if lat<-180 or lon<-180 then return end
    local vor1_closest=200
    local vor2_closest=200
    local dme1_closest=200
    local dme2_closest=200 
    local vor1_closest_index=-1
    local vor2_closest_index=-1
    local dme1_closest_index=-1
    local dme2_closest_index=-1
    
    if string.len(navAidsJSON) ~= nSize then
      navAids=json.decode(navAidsJSON)
      nSize=string.len(navAidsJSON)
     
    end
    if navAids==nil then return end
      for n=table.getn(navAids),1,-1 do
          if navAids[n][2] == 4 and navAids[n][3]>=10800 and navAids[n][3]<=11795 then
          local distance = getDistance(lat,lon,navAids[n][5],navAids[n][6])

        --print("navaid "..n.."->".. distance.."->"..navAids[n][1].." ".. navAids[n][2].." ".. navAids[n][3].." ".. navAids[n][4].." ".. navAids[n][5].." ".. navAids[n][6].." ".. navAids[n][7].." ".. navAids[n][8])

              if distance<vor1_closest then
                  vor2_closest=vor1_closest
                  vor2_closest_index=vor1_closest_index
                  vor1_closest=distance
                  vor1_closest_index=n
              end
          end
    end
    
    
if vor1_closest_index>0 then
    n=vor1_closest_index
    if vor1_auto > 0 then
      vor1_freq=navAids[n][3]
    elseif vor2_auto > 0 then
      vor2_freq=navAids[n][3]
    end
       --print("VOR1 "..n.."->"..navAids[n][1].." ".. navAids[n][2].." ".. navAids[n][3].." ".. navAids[n][4].." ".. navAids[n][5].." ".. navAids[n][6].." ".. navAids[n][7].." ".. navAids[n][8])
    
end
if vor2_closest_index>0 then
   n=vor2_closest_index
    if vor1_auto > 0 and vor2_auto > 0 then
      vor2_freq=navAids[n][3]
    end
    --print("VOR2 "..n.."->"..navAids[n][1].." ".. navAids[n][2].." ".. navAids[n][3].." ".. navAids[n][4].." ".. navAids[n][5].." ".. navAids[n][6].." ".. navAids[n][7].." ".. navAids[n][8])
    
end
end 
