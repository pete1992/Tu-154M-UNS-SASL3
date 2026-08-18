tu154 = false
if tu154 then
    dofile("json/json.lua")
    navAidsJSON                    = find_dataref("xtlua/navaids")
    simDR_time                    = find_dataref("sim/time/total_running_time_sec")
    simDR_lat					= find_dataref("sim/flightmodel/position/latitude")
    simDR_long					= find_dataref("sim/flightmodel/position/longitude")
    simDR_vor1_m_a             = find_dataref("tu154/custom/switchers/nav_1_man_auto")
    simDR_vor2_m_a             = find_dataref("tu154/custom/switchers/nav_2_man_auto")
    simDR_bus27left                    = find_dataref("tu154/custom/elec/bus27_volt_left")
    simDR_bus27right                    = find_dataref("tu154/custom/elec/bus27_volt_right")
    simDR_radio_nav_freq_hz             = find_dataref("sim/cockpit2/radios/actuators/nav_frequency_hz")



    function getDistance(lat1,lon1,lat2,lon2)
      alat=math.rad(lat1)
      alon=math.rad(lon1)
      blat=math.rad(lat2)
      blon=math.rad(lon2)
      av=math.sin(alat)*math.sin(blat) + math.cos(alat)*math.cos(blat)*math.cos(blon-alon)
      if av > 1 then av=1 end
      retVal=math.acos(av) * 3440
      return retVal
    end

    function deferred_dataref(name,nilType,callFunction)
      if callFunction~=nil then
        end
        return find_dataref(name)
    end


    vor1_auto	= deferred_dataref("tu154/custom/switchers/uns_vor1_a", "number")
    vor2_auto	= deferred_dataref("tu154/custom/switchers/uns_vor2_a", "number")
    vor1_freq					= deferred_dataref("tu154/custom/uns_vor1_freq", "number")
    vor2_freq					= deferred_dataref("tu154/custom/uns_vor2_freq", "number")

    dofile("vor/vor.lua")

    function after_physics()

        if simDR_bus27left > 0 then
            tu154_vor_auto()
        elseif simDR_bus27right > 0 then
            tu154_vor_auto()
        end
    end
end
