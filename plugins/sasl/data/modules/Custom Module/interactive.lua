-- interactive.lua
-- Provides a mouse interaction zone with optional debug outlines.

-- Interactive zone

function draw()
    if globalShowInteractiveAreas then
        sasl.gl.drawFrame(0, 0, size[1], size[2])
    end
end
