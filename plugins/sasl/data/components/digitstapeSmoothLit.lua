-- digitstapeSmoothLit.lua
-- Generic illuminated smooth rolling digit tape component.

defineProperty("image")
defineProperty("overlayImage")
defineProperty("value", 0)
defineProperty("digits", 1)
defineProperty("fractional", 0)
defineProperty("allowNonRound", false)
defineProperty("valueEnabler", true)
defineProperty("showLeadingZeros", false)
defineProperty("showSign", false)

function draw()
    local img = get(image)

    if not img then
        return
    end

    local imgWidth, imgHeight = sasl.gl.getTextureSize(img)

    if not imgWidth or not imgHeight or imgWidth <= 0 or imgHeight <= 0 then
        return
    end

    local value = get(value)
    local sign = get(showSign)
    local leading = get(showLeadingZeros)
    local digitsNum = get(digits)
    local frac = get(fractional)

    if digitsNum < 1 then
        return
    end

    if frac < 0 then
        frac = 0
    end

    local symbolsNum = digitsNum

    if frac > 0 then
        symbolsNum = symbolsNum + 1
    end

    local digitWidth = 100 / symbolsNum
    local digitTileWidth = imgWidth
    local digitTileHeight = imgHeight / 14
    local v = math.abs(value) * (10 ^ frac)

    -- Preserve the original inverted allowNonRound behavior.
    if get(allowNonRound) then
        v = math.floor(v + 0.5)
    end

    local pos = 100 - digitWidth
    local overlayImg = get(overlayImage)

    if frac > 0 then
        local sourceY = 13 * digitTileHeight

        sasl.gl.drawTexturePart(
            img,
            pos - digitWidth * frac,
            0,
            digitWidth,
            100,
            0,
            sourceY,
            digitTileWidth,
            digitTileHeight,
            {1, 1, 1, 1}
        )
    end

    if get(valueEnabler) then
        local prevDigit = 0
        local visibleDigits = digitsNum

        if sign then
            visibleDigits = visibleDigits - 1
        end

        for i = 1, visibleDigits do
            local digit = v % 10

            if i > 1 then
                digit = math.floor(v % 10) + math.max(prevDigit - 9, 0)
            end

            prevDigit = digit
            v = math.floor(v / 10)

            local sourceY = (11 - digit) * digitTileHeight

            sasl.gl.drawTexturePart(
                img,
                pos,
                0,
                digitWidth,
                100,
                0,
                sourceY,
                digitTileWidth,
                digitTileHeight,
                {1, 1, 1, 1}
            )

            pos = pos - digitWidth

            if frac == i then
                pos = pos - digitWidth
            end

            if i > frac and not leading and v == 0 then
                break
            end
        end

        if sign and value < 0 then
            local sourceY = 14 * digitTileHeight

            sasl.gl.drawTexturePart(
                img,
                pos,
                0,
                digitWidth,
                100,
                0,
                sourceY,
                digitTileWidth,
                digitTileHeight,
                {1, 1, 1, 1}
            )
        end
    end

    if overlayImg then
        sasl.gl.drawTexture(
            overlayImg,
            0,
            0,
            100,
            100,
            {1, 1, 1, 1}
        )
    end
end
