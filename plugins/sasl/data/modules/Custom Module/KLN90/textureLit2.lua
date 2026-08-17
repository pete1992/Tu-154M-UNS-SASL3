-- draws texture independed of cockpit lighting system

-- no default texture
defineProperty("image")
defineProperty("brt2")

function draw()
    local brightness = get(brt2)
    sasl.gl.drawTexture(get(image), 0, 0, 100, 100,
        { brightness, brightness, brightness, 1 })
end

