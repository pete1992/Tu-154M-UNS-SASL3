-- switch_lit.lua
-- Generic two-state illuminated switch component.

-- Image displayed when the switch is on.
defineProperty("btnOn")

-- Image displayed when the switch is off.
defineProperty("btnOff")

-- Read-only state supplied by the parent component.
defineProperty("state")

-- Cursor resource.
local cursorImg = loadImage("interactive.png")

local function isOn()
    local value = get(state)

    if type(value) == "number" then
        return value ~= 0
    end

    return value == true
end

components = {
    -- On-state texture.
    textureLit {
        image = btnOn,
        visible = function()
            return isOn()
        end,
    },

    -- Off-state texture.
    textureLit {
        image = btnOff,
        visible = function()
            return not isOn()
        end,
    },

    -- Cursor area. Mouse callbacks are intentionally handled by the parent
    -- switch_lit instance so functional state properties remain read-only.
    interactive {
        position = {0, 0, size[1], size[2]},
        cursor = {
            x = 8,
            y = 26,
            width = 16,
            height = 16,
            shape = cursorImg,
        },
    },
}

function draw()
    drawAll(components)
end
