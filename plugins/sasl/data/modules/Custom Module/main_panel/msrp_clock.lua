-- msrp_clock.lua
-- MSRP clock panel.

size = {195, 84}

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"sim_time", "sim/time/zulu_time_sec", globalPropertyf},
    {"msrp_power", "tu154/custom/msrp/msrp_power", globalPropertyi},
})

local digitsImage =
    sasl.gl.loadImage("green_digit_strip.png", 12, 0, 40, 784)

local show_time = 0
local power = get(msrp_power) == 1

function update()
    local utc = math.floor(get(sim_time) / 60)
    local hours = math.floor(utc / 60)
    local minutes = utc - hours * 60

    show_time = hours * 100 + minutes
    power = get(msrp_power) == 1
end

components = {
    digitstapeLit {
        position = {13, 5, 170, 70},
        image = digitsImage,
        digits = 4,
        showLeadingZeros = true,
        allowNonRound = false,
        fractional = 0,
        showSign = false,

        value = function()
            return show_time
        end,

        visible = function()
            return power
        end,
    },
}
