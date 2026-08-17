-- general two-state toggable button

-- image used when button in "ON" state
defineProperty("btnOn")

-- image used when button in "OFF" state
defineProperty("btnOff")

-- function called to get button state
defineProperty("state")

components = {

    -- "on" state texture
    textureLit {
        image = btnOn,
        visible = function() return get(state); end,
    };
    
    -- "off" state texture
    textureLit {
        image = btnOff,
        visible = function() return not get(state); end,
    };

    -- interactive area
    interactive {
        cursor = {
            x = 8,
            y = 26,
            width = 16,
            height = 16,
            shape = sasl.gl.loadImage("interactive.png"),
        },
    };
}

function draw()
	drawAll(components)
end
