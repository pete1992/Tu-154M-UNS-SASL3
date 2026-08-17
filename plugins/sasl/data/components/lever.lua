-- lever.lua
-- Generic vertical lever component.

size = {30, 120}

defineProperty("value", {0})
defineProperty("minimum", 0)
defineProperty("maximum", 1)
defineProperty("lever_count", 1)

defineProperty("back_img")
defineProperty("lever_img")

local cursor_img = sasl.gl.loadImage("interactive.png")

local Min = get(minimum)
local Max = get(maximum)
local Range = Max - Min
local Count = get(lever_count)
local v = get(value)

local mouse_down = false

local function setLeverValue(y)
    if Range == 0 then
        return
    end

    if y < 0 then
        y = 0
    elseif y > 100 then
        y = 100
    end

    local val = y / 100 * Range + Min

    for i = 1, Count do
        set(v[i], val)
    end
end

components = {
    free_texture {
        image = get(lever_img),
        position_x = 0,
        position_y = function()
            if Range == 0 then
                return -10
            end

            local a = (get(v[1]) - Min) * 90 / Range

            if a > 90 then
                a = 90
            elseif a < 0 then
                a = 0
            end

            return a - 10
        end,
        width = 30,
        height = 30,
    },

    interactive {
        position = {5, 0, 20, 100},

        cursor = {
            x = 0,
            y = 0,
            width = 16,
            height = 16,
            shape = cursor_img,
        },

        onMouseDown = function(comp, x, y, button)
            mouse_down = true
            setLeverValue(y)
            return true
        end,

        onMouseMove = function(comp, x, y, button)
            if mouse_down then
                setLeverValue(y)
            end
            return true
        end,

        onMouseUp = function(comp, x, y, button)
            if mouse_down then
                setLeverValue(y)
            end

            mouse_down = false
            return true
        end,
    },
}

function draw()
    drawAll(components)
end
