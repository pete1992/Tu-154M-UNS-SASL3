-- rain_mask.lua
-- SASL

-- Smartcopilot
defineProperty("ismaster", globalPropertyf("scp/api/ismaster"))  -- Master. 0 = plugin not found, 1 = slave 2 = master
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1")) -- Have control. 0 = plugin not found, 1 = no control 2 = has control
-- END

local function defineProps(defs)
    -- Correct: build property handles by calling the constructor with path
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Wiper animation
    {"wiper_angle_left", "tu154/custom/anim/wiper_angle_left", globalPropertyf},
    {"wiper_angle_right", "tu154/custom/anim/wiper_angle_right", globalPropertyf},
    -- Environment
    {"actual_rain", "sim/weather/precipitation_on_aircraft_ratio", globalPropertyf}, -- precipitation on aircraft
    {"net_rain_ratio", "tu154/custom/anim/net_rain_ratio", globalPropertyf},
    -- Airspeed
    {"indicated_airspeed", "sim/flightmodel/position/indicated_airspeed", globalPropertyf},
    -- Timing
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf}, -- flight time
    -- Outside temperature
    {"thermo", "sim/cockpit2/temperature/outside_air_temp_degc", globalPropertyf}, -- outside temperature
})

-- Per-layer global glass mask DataRefs (handles are expected to exist project-wide)
local mask = {}
for i = 1, 2 do
    mask[i] = globalPropertyf("tu154/custom/anim/rain_glass_"..i)
end

-- Per-wiper segment masks (left/right, 5 segments per layer)
local wiper_mask_L = {}
local wiper_mask_R = {}
for i = 1, 2 do
    table.insert(wiper_mask_L, {})
    table.insert(wiper_mask_R, {})
    for y = 1, 5 do
        table.insert(wiper_mask_L[i], globalPropertyf("tu154/custom/anim/rain_glass_"..i.."_w_"..y.."_L"))
        table.insert(wiper_mask_R[i], globalPropertyf("tu154/custom/anim/rain_glass_"..i.."_w_"..y.."_R"))
    end
end

-- Runtime accumulators for layer masks
local mask_tbl = {}
for i = 1, 2 do
    mask_tbl[i] = 0
end

-- Runtime accumulators for per-segment masks (left/right)
local wiper_mask_tbl_L = {}
local wiper_mask_tbl_R = {}
for i = 1, 2 do
    table.insert(wiper_mask_tbl_L, {})
    table.insert(wiper_mask_tbl_R, {})
    for y = 1, 5 do
        table.insert(wiper_mask_tbl_L[i], 0)
        table.insert(wiper_mask_tbl_R[i], 0)
    end
end

-- Appearance speeds for layer 1 & 2
local appear_spd = { [1] = 0, [2] = 0 }

-- Last wiper angles to detect band crossings
local wiper_L_last = get(wiper_angle_left)
local wiper_R_last = get(wiper_angle_right)

-- Helpers (local only)
-- Clamp to [0,1]
local function clamp01(x)
    if x < 0 then return 0 end
    if x > 1 then return 1 end
    return x
end

-- Numeric guard: coerce non-numeric values (tables/strings/nil) to number; fallback 0
local function n(v)
    local t = type(v)
    if t == "number" then return v end
    if t == "string" then
        local vv = tonumber(v)
        if vv then return vv end
    end
    return 0
end

-- Compute band limits for segment y
local function band_limits(y)
    -- low = 2 + (y*12 - 12), high = 12*y
    return 2 + (y * 12 - 12), 12 * y
end

-- True if angle is strictly inside (low, high)
local function in_band(a, low, high)
    return (a < high) and (a > low)
end

-- Decide if a wipe event clears a segment:
-- - If angle changed and either current or last is inside band → clear
-- - If increasing and crossing from below low to above high → clear
-- - If decreasing and crossing from above high to below low → clear
local function wiper_hits_band(curr, last, low, high)
    if curr ~= last then
        if in_band(curr, low, high) or in_band(last, low, high) then
            return true
        end
        if curr > last then
            if (curr > high) and (last < low) then
                return true
            end
        elseif curr < last then
            if (last > high) and (curr < low) then
                return true
            end
        end
    end
    return false
end

function update()
    local passed = n(get(frame_time))

    -- Determine who drives the shared rain ratio:
    -- single player (0) or master (2) → true; slave (1) → false
    local MASTER = (get(ismaster) ~= 1)
    if MASTER then
        -- Master or single player drives the shared rain ratio
        set(net_rain_ratio, n(get(actual_rain)))
    end

    -- Cache math functions
    local abs, min = math.abs, math.min

    -- Inputs for appearance rate (guard to numbers)
    local precip_lvl = n(get(net_rain_ratio))
    local IAS = n(get(indicated_airspeed))
    local temperature = n(get(thermo))

    -- Appearance speeds (layer 1 & 2), preserving original behavior
    appear_spd[1] = (precip_lvl - min(0.05 + abs(IAS) * 0.0005, 0.5)) * 0.3
    if temperature < 0 then
        appear_spd[1] = -min(0.01 + abs(IAS) * 0.0005, 0.5)
    end

    appear_spd[2] = (precip_lvl - min(0.05 + abs(IAS) * 0.0005, 0.5)) * 0.1
    if temperature > 0 then
        appear_spd[2] = -min(0.01 + abs(IAS) * 0.0005, 0.5) * 0.5
    end

    -- Wiper angles (guard to numbers)
    local wiper_L = n(get(wiper_angle_left))
    local wiper_R = n(get(wiper_angle_right))

    -- Update layers and segment masks
    for i = 1, 2 do
        -- Global glass layer
        mask_tbl[i] = clamp01(mask_tbl[i] + passed * appear_spd[i])
        set(mask[i], mask_tbl[i])

        -- Per-wiper segment masks
        for y = 1, 5 do
            -- Left side
            wiper_mask_tbl_L[i][y] = clamp01(wiper_mask_tbl_L[i][y] + passed * appear_spd[i])
            local lowL, highL = band_limits(y)
            if wiper_hits_band(wiper_L, wiper_L_last, lowL, highL) then
                wiper_mask_tbl_L[i][y] = 0
            end
            set(wiper_mask_L[i][y], wiper_mask_tbl_L[i][y])

            -- Right side
            wiper_mask_tbl_R[i][y] = clamp01(wiper_mask_tbl_R[i][y] + passed * appear_spd[i])
            local lowR, highR = band_limits(y)
            if wiper_hits_band(wiper_R, wiper_R_last, lowR, highR) then
                wiper_mask_tbl_R[i][y] = 0
            end
            set(wiper_mask_R[i][y], wiper_mask_tbl_R[i][y])
        end
    end

    -- Store last angles for next frame
    wiper_L_last = wiper_L
    wiper_R_last = wiper_R
end

