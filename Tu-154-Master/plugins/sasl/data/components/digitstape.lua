-- digitstape.lua
-- Generic rolling digit tape component.

defineProperty("image")
defineProperty("overlayImage")
defineProperty("value", 0)
defineProperty("digits", 1)
defineProperty("fractional", 0)
defineProperty("allowNonRound", false)
defineProperty("valueEnabler", true)
defineProperty("showLeadingZeros", false)
defineProperty("showSign", false)
defineProperty("position", {0, 0, 100, 100})

function draw()
    local img = get(image)

    if not img then
        return
    end

    local overlayImg = get(overlayImage)
    local value = get(value)
    local sign = get(showSign)
    local leading = get(showLeadingZeros)
    local digitsNum = get(digits)
    local frac = get(fractional)
    local pos = get(position)

    if digitsNum < 1 then
        return
    end

    if frac < 0 then
        frac = 0
    end

    local imgWidth, imgHeight = sasl.gl.getTextureSize(img)

    if not imgWidth or not imgHeight or imgWidth <= 0 or imgHeight <= 0 then
        return
    end

    local digitTileWidth = imgWidth
    local digitTileHeight = imgHeight / 14
    local v = math.abs(value) * (10 ^ frac)

    -- Preserve the original inverted allowNonRound behavior.
    if get(allowNonRound) then
        v = math.floor(v + 0.5)
    end

    local panelWidth = pos[3] or 100
    local panelHeight = pos[4] or 100

    local digitWidth = (digitTileWidth + panelHeight) * 0.35 - 4
    local digitHeight = (digitTileHeight + panelHeight) * 0.35
    local posX = panelWidth - digitTileWidth + 15

    if frac > 0 then
        local sourceY = 13 * digitTileHeight
        sourceY = imgHeight - sourceY - digitTileHeight

        sasl.gl.drawTexturePart(
            img,
            posX - digitWidth * frac,
            0,
            digitWidth,
            digitHeight,
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

            if prevDigit > 9.5 then
                digit = digit + 1
            end

            prevDigit = digit
            v = math.floor(v / 10)

            local sourceY = (11 - digit) * digitTileHeight
            sourceY = imgHeight - sourceY - digitTileHeight

            sasl.gl.drawTexturePart(
                img,
                posX,
                0,
                digitWidth,
                digitHeight,
                0,
                sourceY,
                digitTileWidth,
                digitTileHeight,
                {1, 1, 1, 1}
            )

            posX = posX - digitWidth

            if frac == i then
                posX = posX - digitWidth
            end

            if i > frac and not leading and v == 0 then
                break
            end
        end

        if sign and value < 0 then
            local sourceY = 14 * digitTileHeight
            sourceY = imgHeight - sourceY - digitTileHeight

            sasl.gl.drawTexturePart(
                img,
                posX,
                0,
                digitWidth,
                digitHeight,
                0,
                sourceY,
                digitTileWidth,
                digitTileHeight,
                {1, 1, 1, 1}
            )
        end
    end

    if overlayImg then
        local w, h = sasl.gl.getTextureSize(overlayImg)

        if w and h and w > 0 and h > 0 then
            sasl.gl.drawTexture(
                overlayImg,
                0,
                0,
                w,
                h
            )
        end
    end
end
