-- RSBN logic: selects the nearest beacon on the tuned channel and
-- provides slant range and azimuth to the gauges

-------------------------------------------------
-- properties
-------------------------------------------------

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Controls
    { "rsbn_control_strobe",   "tu154/custom/buttons/ovhd/rsbn_control_strobe", globalPropertyi },
    { "rsbn_control_azimuth",  "tu154/custom/buttons/ovhd/rsbn_control_azimuth", globalPropertyi },
    { "rsbn_control_distance", "tu154/custom/buttons/ovhd/rsbn_control_distance", globalPropertyi },

    { "rsbn_ch_ten", "tu154/custom/buttons/ovhd/rsbn_ch_ten", globalPropertyi },
    { "rsbn_ch_one", "tu154/custom/buttons/ovhd/rsbn_ch_one", globalPropertyi },

    { "rsbn_on",    "tu154/custom/switchers/ovhd/rsbn_on", globalPropertyi },
    { "rsbn_recon", "tu154/custom/switchers/ovhd/rsbn_recon", globalPropertyi },

    -- Aircraft position
    { "latitude",  "sim/flightmodel/position/latitude", globalPropertyd },
    { "longitude", "sim/flightmodel/position/longitude", globalPropertyd },
    { "elevation", "sim/flightmodel/position/elevation", globalPropertyd },

    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },

    -- Power
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus115_1_volt",   "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "rsbn_cc",         "tu154/custom/radio/rsbn_cc", globalPropertyf },

    -- Failures
    { "rsbn_fail", "tu154/custom/failures/rsbn_fail", globalPropertyi },

    -- Results
    { "distance", "tu154/custom/rsbn/distance", globalPropertyf },
    { "azimuth",  "tu154/custom/rsbn/azimuth", globalPropertyf },
})

include("nav_funcs.lua")

-------------------------------------------------
-- state
-------------------------------------------------

local nav_table = {}          -- all beacons from rsbn.dat
local work_table = {}         -- beacons matching the selected channel
local channel_set = 0
local chan_last = -1          -- -1 forces a first rebuild, also for channel 0
local table_read_timer = 0

-------------------------------------------------
-- navigation database
-------------------------------------------------

-- Splits "a|b|c|..." into a plain array. Returns nil if the line has
-- fewer fields than expected, so malformed lines are skipped instead
-- of crashing on string.sub(line, a, nil - 1).
local function splitFields(line, expected)
    local fields = {}
    local pos = 1

    for _ = 1, expected - 1 do
        local sep = string.find(line, "|", pos, true)
        if sep == nil then
            return nil
        end
        fields[#fields + 1] = string.sub(line, pos, sep - 1)
        pos = sep + 1
    end

    fields[#fields + 1] = string.sub(line, pos)
    return fields
end

-- Builds the full path to rsbn.dat, tolerating a trailing separator
local function navDataPath()
    local base = sasl.getAircraftPath()
    if base == nil then
        return nil
    end

    if string.sub(base, -1) == "/" or string.sub(base, -1) == "\\" then
        return base .. "rsbn.dat"
    end
    return base .. "/rsbn.dat"
end

-- Kept global: other modules may trigger a reload of the database
function read_nav_dat()
    local fileName = navDataPath()
    if fileName == nil then
        print("RSBN: cannot resolve aircraft path, rsbn.dat not loaded")
        return false
    end

    local file = io.open(fileName, "r")
    if file == nil then
        print("RSBN: can't read " .. fileName)
        return false
    end

    local parsed = {}
    local skipped = 0

    for line in file:lines() do
        -- channel|name|code|freq|lat|lon|elev
        local f = splitFields(line, 7)

        if f == nil then
            -- no separator at all: comment or blank line, silently ignored
        else
            local channel = tonumber(f[1])
            local lat     = tonumber(f[5])
            local lon     = tonumber(f[6])
            local elev    = tonumber(f[7])

            if channel and lat and lon and elev then
                parsed[#parsed + 1] = {
                    chan = channel,
                    name = f[2],
                    icao = f[3],
                    lat  = lat,
                    lon  = lon,
                    elev = elev,
                }
            else
                skipped = skipped + 1
            end
        end
    end

    file:close()

    nav_table = parsed
    work_table = {}
    chan_last = -1  -- force a rebuild against the new database

    if skipped > 0 then
        print("RSBN: rsbn.dat read, " .. #nav_table ..
              " beacons, " .. skipped .. " malformed lines skipped")
    else
        print("RSBN: rsbn.dat read OK, " .. #nav_table .. " beacons")
    end

    return true
end

read_nav_dat() -- read the nav database once at load time

-------------------------------------------------
-- channel selection
-------------------------------------------------

local function chan_select()
    channel_set = get(rsbn_ch_ten) * 10 + get(rsbn_ch_one)

    if channel_set == chan_last then
        return
    end

    -- Database not available yet: keep chan_last untouched so the
    -- selection is retried after a successful reload
    if #nav_table == 0 then
        return
    end

    local matches = {}
    for i = 1, #nav_table do
        local m = nav_table[i]
        if m.chan == channel_set then
            matches[#matches + 1] = m
        end
    end

    work_table = matches
    table_read_timer = 0
    chan_last = channel_set
end

-------------------------------------------------
-- nearest beacon
-------------------------------------------------

local function get_nearest()
    local plane_lat = get(latitude)
    local plane_lon = get(longitude)

    local dist = 21600 -- nm, half the earth circumference
    local res_lat, res_lon, res_elev = 0, 0, 0
    local res_name = ""

    for i = 1, #work_table do
        local m = work_table[i]
        local b_dist = calc_range(m.lat, m.lon, plane_lat, plane_lon)

        if b_dist < dist then
            dist = b_dist
            res_lat = m.lat
            res_lon = m.lon
            res_elev = m.elev
            res_name = m.name
        end
    end

    return dist, res_lat, res_lon, res_elev, res_name
end

-------------------------------------------------
-- runtime state
-------------------------------------------------

local beacon_dist = 0 -- nm
local beacon_lat = 0
local beacon_lon = 0
local beacon_elevation = 0
local beacon_name = "none"
local beacon_azimuth = 0

local dist_show = 0
local azimuth_show = 0

local NM_TO_M = 1852

-------------------------------------------------
-- update
-------------------------------------------------

function update()
    local passed = get(frame_time)
    local plane_lat = get(latitude)
    local plane_lon = get(longitude)
    local plane_elev = get(elevation)

    local power = get(rsbn_on) == 1
        and get(bus27_volt_left) > 13
        and get(bus115_1_volt) > 110
        and get(rsbn_fail) == 0

    set(rsbn_cc, bool2int(power))

    if power then
        chan_select()
    end

    -- Refresh the nearest beacon about once per second
    if table_read_timer == 0 and #work_table > 0 and power then
        beacon_dist, beacon_lat, beacon_lon, beacon_elevation, beacon_name =
            get_nearest()
    elseif #work_table == 0 or not power then
        beacon_dist, beacon_lat, beacon_lon, beacon_elevation, beacon_name =
            0, 0, 0, 0, "none"
    end

    local res_distance = 0

    if beacon_name ~= "none" then
        -- Great circle range and true bearing to the beacon
        beacon_dist = calc_range(beacon_lat, beacon_lon, plane_lat, plane_lon)
        beacon_azimuth = calc_true_course(beacon_lat, beacon_lon,
                                          plane_lat, plane_lon, beacon_dist)

        -- Slant range, corrected for the altitude difference
        local ground = beacon_dist * NM_TO_M
        local vertical = plane_elev - beacon_elevation
        res_distance = math.sqrt(ground * ground + vertical * vertical)

        -- Radio horizon: drop the indication if the beacon is out of reach
        local dist_limit = 4120 * (math.sqrt(math.max(plane_elev, 0))
                         + math.sqrt(math.max(beacon_elevation, 0))) + 20000

        if ground < math.abs(vertical) or res_distance > dist_limit then
            res_distance = 0
            beacon_azimuth = 0
        end
    end

    -- Self test values
    if power and get(rsbn_control_azimuth) == 1 then
        beacon_azimuth = 1 -- degree
    end

    if power and get(rsbn_control_distance) == 1 then
        res_distance = 2000 -- m
    end

    table_read_timer = table_read_timer + passed
    if table_read_timer > 1 then
        table_read_timer = 0
    end

    -- Hold the last valid reading, as the real indicator does
    if res_distance ~= 0 then
        dist_show = res_distance
    end
    if beacon_azimuth ~= 0 then
        azimuth_show = beacon_azimuth
    end

    set(distance, dist_show * 0.001) -- km
    set(azimuth, azimuth_show)
end
