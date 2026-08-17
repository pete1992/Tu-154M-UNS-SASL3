-- lever_hor.lua
-- Generic horizontal lever component.

size = {139, 29}

-- Value controlled by the lever.
defineProperty("value", 0)

-- Lever value range.
defineProperty("minimum", 0)
defineProperty("maximum", 1)

-- Optional callback executed after the lever is released.
defineProperty("addFunc")

-- Images supplied by the parent component.
defineProperty("back_img")
defineProperty("lever_img")

local Min = get(minimum)
local Max = get(maximum)
local Range = Max - Min
local Travel = size[1] - 30

local mouse_down = false


-- Converts a mouse X position into the configured lever value.
local function setLeverValue(x)
    if Range == 0 then
        return
    end

    if x < 0 then
        x = 0
    elseif x > Travel then
        x = Travel
    end

    local val = x / Travel * Range + Min
    set(value, val)
end


components = {

    -- Movable lever image.
    free_texture {
        image = get(lever_img),

        position_y = 0,

        position_x = function()
            if Range == 0 then
                return 0
            end

            local a = (get(value) - Min) * Travel / Range

            if a > Travel then
                a = Travel
            elseif a < 0 then
                a = 0
            end

            return a
        end,

        width = 30,
        height = 30,
    },

    -- Interactive lever area.
    interactive {
        position = {15, 0, Travel, 29},

        -- Start dragging and immediately move the lever.
        onMouseDown = function(comp, x, y, button)
            mouse_down = true
            setLeverValue(x)
            return true
        end,

        -- Continuously update the lever while dragging.
        onMouseMove = function(comp, x, y, button)
            if mouse_down then
                setLeverValue(x)
            end

            return true
        end,

        -- Apply the final position and execute the release callback.
        onMouseUp = function(comp, x, y, button)
            if mouse_down then
                setLeverValue(x)
                mouse_down = false
                addFunc()
            end

            return true
        end,
    },
}

-- Draws all child components of the lever.
function draw()
    drawAll(components)
end
