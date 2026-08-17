defineProperty("click", nil)
defineProperty("label", "")
defineProperty("font", sasl.gl.loadFont("AVIA.ttf"))
defineProperty("font_size", 12)

defineProperty("color", { 0, 0.4, 0.6, 1 })
defineProperty("frame_color", { 0, 0.3, 0.5, 1 })
defineProperty("hover_color", { 0.6, 0.1, 0.1, 1 })

state = {
    hover = false
}

function onMouseDown(component, x, y, button, parentX, parentY)
    if button == MB_LEFT then
        print(" Handled ! ")
    end
    return true
end

function update()

end

function onMouseMove(comp, x, y, button, parentX, parentY)
    state.hover = true
    return true
end

function onMouseLeave()
    state.hover = false
end

function draw()
    if state.hover then
        sasl.gl.drawRectangle(0, 0, get(position)[3], get(position)[4], get(hover_color))
    else
        sasl.gl.drawRectangle(0, 0, get(position)[3], get(position)[4], get(color))
    end
    sasl.gl.drawFrame(0, 0, get(position)[3], get(position)[4], get(frame_color))
    sasl.gl.drawText(
        get(font),
        get(position)[3] / 2,
        (get(position)[4] - get(font_size)) / 2,
        get(label),
        get(font_size),
        false,
        false,
        TEXT_ALIGN_CENTER,
        { 1, 1, 1, 1 }
    )
end
