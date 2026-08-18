-- lever_hor.lua

size = {139, 29}

-- Controlled value.
defineProperty("value", 0)

-- Lever range.
defineProperty("minimum", 0)
defineProperty("maximum", 1)

-- Optional function called when the lever is released.
defineProperty("addFunc")

-- Images.
defineProperty("back_img")
defineProperty("lever_img")

local Min = get(minimum)
local Max = get(maximum)
local Range = Max - Min
local Travel = size[1] - 30

local dragging = false


local function setLeverValue(x)
    if Range == 0 or Travel <= 0 then
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

        onMouseDown = function(comp, x, y, button)
            if button ~= MB_LEFT then
                return false
            end

            dragging = true
            setLeverValue(x)

            return true
        end,

        onMouseMove = function(comp, x, y, button)
            if dragging then
                setLeverValue(x)
            end

            return true
        end,

        onMouseUp = function(comp, x, y, button)
            if button ~= MB_LEFT then
                return false
            end

            if dragging then
                setLeverValue(x)
                dragging = false

                if addFunc then
                    addFunc()
                end
            end

            return true
        end,
    },
}


function draw()
    drawAll(components)
end
