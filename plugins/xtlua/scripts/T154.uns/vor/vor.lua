-- vor.lua
local UPDATE_INTERVAL = 10
local MAX_VOR_DISTANCE_NM = 200
local VOR_TYPE = 4
local MIN_VOR_FREQUENCY = 10800
local MAX_VOR_FREQUENCY = 11795

local navAids
local lastNavAidsJSON
local lastUpdate = -UPDATE_INTERVAL
local previousVor1Auto = false
local previousVor2Auto = false

local function loadNavAids()
    local encodedNavAids = navAidsJSON
    if type(encodedNavAids) ~= "string" or encodedNavAids == "" then
        return false
    end

    if navAids ~= nil and encodedNavAids == lastNavAidsJSON then
        return true
    end

    local decodedSuccessfully, decodedNavAids = pcall(json.decode, encodedNavAids)
    if not decodedSuccessfully or type(decodedNavAids) ~= "table" then
        return false
    end

    navAids = decodedNavAids
    lastNavAidsJSON = encodedNavAids
    return true
end

local function readVor(navAid)
    if type(navAid) ~= "table" then
        return nil
    end

    local navAidType = tonumber(navAid[2])
    local frequency = tonumber(navAid[3])
    local latitude = tonumber(navAid[5])
    local longitude = tonumber(navAid[6])

    if navAidType ~= VOR_TYPE
        or frequency == nil
        or frequency < MIN_VOR_FREQUENCY
        or frequency > MAX_VOR_FREQUENCY
        or latitude == nil
        or latitude < -90
        or latitude > 90
        or longitude == nil
        or longitude < -180
        or longitude > 180 then
        return nil
    end

    return frequency, latitude, longitude
end

function tu154_vor_auto(unsPowered)
    local vor1IsAutomatic = unsPowered and vor1_auto > 0
    local vor2IsAutomatic = unsPowered and vor2_auto > 0
    local automaticModeChanged = vor1IsAutomatic ~= previousVor1Auto
        or vor2IsAutomatic ~= previousVor2Auto

    previousVor1Auto = vor1IsAutomatic
    previousVor2Auto = vor2IsAutomatic

    if not vor1IsAutomatic and not vor2IsAutomatic then
        return
    end

    local now = tonumber(simDR_time)
    if now == nil then
        return
    end

    if not automaticModeChanged
        and now >= lastUpdate
        and now - lastUpdate < UPDATE_INTERVAL then
        return
    end

    lastUpdate = now

    local aircraftLatitude = tonumber(simDR_lat)
    local aircraftLongitude = tonumber(simDR_long)
    if aircraftLatitude == nil
        or aircraftLatitude < -90
        or aircraftLatitude > 90
        or aircraftLongitude == nil
        or aircraftLongitude < -180
        or aircraftLongitude > 180
        or not loadNavAids() then
        return
    end

    local closestFrequency
    local secondClosestFrequency
    local closestDistance = MAX_VOR_DISTANCE_NM
    local secondClosestDistance = MAX_VOR_DISTANCE_NM

    for index = #navAids, 1, -1 do
        local frequency, latitude, longitude = readVor(navAids[index])
        if frequency ~= nil then
            local distance = getDistance(
                aircraftLatitude,
                aircraftLongitude,
                latitude,
                longitude
            )

            if distance < closestDistance then
                secondClosestDistance = closestDistance
                secondClosestFrequency = closestFrequency
                closestDistance = distance
                closestFrequency = frequency
            elseif distance < secondClosestDistance then
                secondClosestDistance = distance
                secondClosestFrequency = frequency
            end
        end
    end

    if closestFrequency == nil then
        return
    end

    -- Each UI selector owns exactly one receiver. A receiver in MANUAL is never
    -- written here, even if the other receiver remains in automatic mode.
    if vor1IsAutomatic then
        vor1_freq = closestFrequency
    end

    if vor2IsAutomatic then
        local selectedFrequency = vor1IsAutomatic and secondClosestFrequency or closestFrequency
        if selectedFrequency ~= nil then
            vor2_freq = selectedFrequency
        end
    end
end
