-- rain_mask.lua
-- Rain and wiper mask logic.

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"ismaster", "scp/api/ismaster", globalPropertyf},
    {"wiper_angle_left", "tu154/custom/anim/wiper_angle_left", globalPropertyf},
    {"wiper_angle_right", "tu154/custom/anim/wiper_angle_right", globalPropertyf},
    {"actual_rain", "sim/weather/precipitation_on_aircraft_ratio", globalPropertyf},
    {"net_rain_ratio", "tu154/custom/anim/net_rain_ratio", globalPropertyf},
    {"indicated_airspeed", "sim/flightmodel/position/indicated_airspeed", globalPropertyf},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"thermo", "sim/cockpit2/temperature/outside_air_temp_degc", globalPropertyf},
})

-- Global rain-layer mask properties.
local mask = {}

for i = 1, 2 do
    mask[i] =
        globalPropertyf(
            "tu154/custom/anim/rain_glass_" .. i
        )
end

-- Per-wiper segment mask properties.
local wiper_mask_L = {}
local wiper_mask_R = {}

for i = 1, 2 do
    wiper_mask_L[i] = {}
    wiper_mask_R[i] = {}

    for y = 1, 5 do
        wiper_mask_L[i][y] =
            globalPropertyf(
                "tu154/custom/anim/rain_glass_"
                    .. i
                    .. "_w_"
                    .. y
                    .. "_L"
            )

        wiper_mask_R[i][y] =
            globalPropertyf(
                "tu154/custom/anim/rain_glass_"
                    .. i
                    .. "_w_"
                    .. y
                    .. "_R"
            )
    end
end

-- Preserve the current rain-mask state across script reloads.
local mask_tbl = {}
local wiper_mask_tbl_L = {}
local wiper_mask_tbl_R = {}

for i = 1, 2 do
    mask_tbl[i] = get(mask[i])

    wiper_mask_tbl_L[i] = {}
    wiper_mask_tbl_R[i] = {}

    for y = 1, 5 do
        wiper_mask_tbl_L[i][y] =
            get(wiper_mask_L[i][y])

        wiper_mask_tbl_R[i][y] =
            get(wiper_mask_R[i][y])
    end
end

-- Wiper segment limits are static and can be prepared once.
local bands = {}

for y = 1, 5 do
    bands[y] = {
        low = 2 + (y - 1) * 12,
        high = y * 12,
    }
end

-- Last wiper angles for segment-crossing detection.
local wiper_L_last = get(wiper_angle_left)
local wiper_R_last = get(wiper_angle_right)


local function clamp01(value)
    if value < 0 then
        return 0
    elseif value > 1 then
        return 1
    end

    return value
end


-- Return true when the angular path between the previous and current
-- wiper position intersects the specified segment.
local function wiperHitsBand(current, previous, low, high)
    if current == previous then
        return false
    end

    local move_min = math.min(current, previous)
    local move_max = math.max(current, previous)

    return move_max >= low and move_min <= high
end


function update()
    local passed = get(frame_time)

    -- Single player and SmartCopilot master provide the shared rain ratio.
    local MASTER = get(ismaster) ~= 1

    if MASTER then
        set(net_rain_ratio, get(actual_rain))
    end

    local precip_lvl = get(net_rain_ratio)
    local IAS = get(indicated_airspeed)
    local temperature = get(thermo)
    local abs_IAS = math.abs(IAS)

    -- Layer 1 appearance rate.
    local appear_spd_1 =
        (
            precip_lvl
            - math.min(
                0.05 + abs_IAS * 0.0005,
                0.5
            )
        )
        * 0.3

    if temperature < 0 then
        appear_spd_1 =
            -math.min(
                0.01 + abs_IAS * 0.0005,
                0.5
            )
    end

    -- Layer 2 appearance rate.
    local appear_spd_2 =
        (
            precip_lvl
            - math.min(
                0.05 + abs_IAS * 0.0005,
                0.5
            )
        )
        * 0.1

    if temperature > 0 then
        appear_spd_2 =
            -math.min(
                0.01 + abs_IAS * 0.0005,
                0.5
            )
            * 0.5
    end

    local wiper_L = get(wiper_angle_left)
    local wiper_R = get(wiper_angle_right)

    for i = 1, 2 do
        local appear_speed

        if i == 1 then
            appear_speed = appear_spd_1
        else
            appear_speed = appear_spd_2
        end

        -- Global glass layer.
        mask_tbl[i] =
            clamp01(
                mask_tbl[i]
                + passed * appear_speed
            )

        set(mask[i], mask_tbl[i])

        -- Per-wiper segment masks.
        for y = 1, 5 do
            local band = bands[y]

            wiper_mask_tbl_L[i][y] =
                clamp01(
                    wiper_mask_tbl_L[i][y]
                    + passed * appear_speed
                )

            if wiperHitsBand(
                wiper_L,
                wiper_L_last,
                band.low,
                band.high
            ) then
                wiper_mask_tbl_L[i][y] = 0
            end

            set(
                wiper_mask_L[i][y],
                wiper_mask_tbl_L[i][y]
            )

            wiper_mask_tbl_R[i][y] =
                clamp01(
                    wiper_mask_tbl_R[i][y]
                    + passed * appear_speed
                )

            if wiperHitsBand(
                wiper_R,
                wiper_R_last,
                band.low,
                band.high
            ) then
                wiper_mask_tbl_R[i][y] = 0
            end

            set(
                wiper_mask_R[i][y],
                wiper_mask_tbl_R[i][y]
            )
        end
    end

    wiper_L_last = wiper_L
    wiper_R_last = wiper_R
end
