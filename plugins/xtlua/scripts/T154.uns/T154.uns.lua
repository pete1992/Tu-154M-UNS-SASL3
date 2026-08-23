dofile("json/json.lua")

navAidsJSON = find_dataref("xtlua/navaids")
simDR_time = find_dataref("sim/time/total_running_time_sec")
simDR_lat = find_dataref("sim/flightmodel/position/latitude")
simDR_long = find_dataref("sim/flightmodel/position/longitude")
simDR_bus27left = find_dataref("tu154/custom/elec/bus27_volt_left")
simDR_bus27right = find_dataref("tu154/custom/elec/bus27_volt_right")

function getDistance(lat1, lon1, lat2, lon2)
    local latitude1 = math.rad(lat1)
    local longitude1 = math.rad(lon1)
    local latitude2 = math.rad(lat2)
    local longitude2 = math.rad(lon2)
    local arcCosine = math.sin(latitude1) * math.sin(latitude2)
        + math.cos(latitude1) * math.cos(latitude2) * math.cos(longitude2 - longitude1)

    -- Floating-point rounding can otherwise put acos marginally outside its domain.
    if arcCosine > 1 then
        arcCosine = 1
    elseif arcCosine < -1 then
        arcCosine = -1
    end

    return math.acos(arcCosine) * 3440
end

function deferred_dataref(name)
    return find_dataref(name)
end

vor1_auto = deferred_dataref("tu154/custom/switchers/uns_vor1_a", "number")
vor2_auto = deferred_dataref("tu154/custom/switchers/uns_vor2_a", "number")
vor1_freq = deferred_dataref("tu154/custom/uns_vor1_freq", "number")
vor2_freq = deferred_dataref("tu154/custom/uns_vor2_freq", "number")

dofile("vor/vor.lua")

function after_physics()
    local unsPowered = simDR_bus27left > 0 or simDR_bus27right > 0
    tu154_vor_auto(unsPowered)
end
