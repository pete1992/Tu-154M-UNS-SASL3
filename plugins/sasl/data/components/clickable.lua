-- interactive.lua
-- Auxiliary mouse input helper component.
-- Use only when standard component mouse callbacks are insufficient.

defineProperty("enabled", true)
defineProperty("mouseDown")
defineProperty("mouseUp")
defineProperty("mouseHold")
defineProperty("doubleClick")
defineProperty("mouseDrag")
defineProperty("mouseWheel")

local function isEnabled()
    local value = get(enabled)
    return value == true or value == 1
end

function update()
    if not isEnabled() then
        return
    end

    -- Ignore mouse input outside the SASL interface.
    if sasl.getCSCursorOnInterface() ~= 1 then
        return
    end

    local x = sasl.getCSMouseXPos()
    local y = sasl.getCSMouseYPos()

    if sasl.getCSClickDown(MB_LEFT) == 1 and mouseDown then
        mouseDown(x, y)
    end

    if sasl.getCSClickHold(MB_LEFT) == 1 and mouseHold then
        mouseHold(x, y)
    end

    if sasl.getCSClickUp(MB_LEFT) == 1 and mouseUp then
        mouseUp(x, y)
    end

    if sasl.getCSDoubleClick(MB_LEFT) == 1 and doubleClick then
        doubleClick(x, y)
    end

    local dragValue = sasl.getCSDragValue()

    if dragValue and dragValue > 0 and mouseDrag then
        mouseDrag(
            x,
            y,
            sasl.getCSDragDirection(),
            dragValue
        )
    end

    local wheel = sasl.getCSWheelClicks()

    if wheel ~= 0 and mouseWheel then
        mouseWheel(x, y, wheel)
    end
end
