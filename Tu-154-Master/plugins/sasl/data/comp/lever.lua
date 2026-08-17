-- lever.lua
-- Generic vertical lever component.

size = {30, 120}

-- Property or property table controlled by the lever.
defineProperty("value", {0})

-- Lever value range.
defineProperty("minimum", 0)
defineProperty("maximum", 1)

-- Number of properties controlled simultaneously.
defineProperty("lever_count", 1)

-- Images supplied by the parent component.
defineProperty("back_img")
defineProperty("lever_img")

-- Mouse cursor resource.
local cursor_img = loadImage("interactive.png")

local Min = get(minimum)
local Max = get(maximum)
local Range = Max - Min
local Count = get(lever_count)
local v = get(value)

local mouse_down = false


-- Converts a mouse Y position into the configured lever value.
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

    -- Movable lever image.
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

    -- Interactive lever area.
    interactive {
        position = {5, 0, 20, 100},

        cursor = {
            x = 0,
            y = 0,
            width = 16,
            height = 16,
            shape = cursor_img,
        },

        -- Start dragging and immediately move the lever to the clicked position.
        onMouseDown = function(comp, x, y, button)
            mouse_down = true
            setLeverValue(y)
            return true
        end,

        -- Continuously update the lever while dragging.
        onMouseMove = function(comp, x, y, button)
            if mouse_down then
                setLeverValue(y)
            end

            return true
        end,

        -- Stop dragging when the mouse button is released.
        onMouseUp = function(comp, x, y, button)
            mouse_down = false
            return true
        end,
    },
}


-- Draws all child components of the lever.
function draw()
    drawAll(components)
end
