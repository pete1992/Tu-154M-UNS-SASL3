-- digitstape.lua
-- Generic rolling digit tape component.

-- Digit texture supplied by the parent component.
defineProperty("image")

-- Optional overlay texture supplied by the parent component.
defineProperty("overlayImage")

-- Displayed value.
defineProperty("value", 0)

-- Number of displayed digits.
defineProperty("digits", 1)

-- Number of fractional digits.
defineProperty("fractional", 0)

-- Allow non-rounded values.
defineProperty("allowNonRound", false)

-- Enables or disables value display.
defineProperty("valueEnabler", true)

-- Show leading zeros.
defineProperty("showLeadingZeros", false)

-- Reserve the first digit position for a negative sign.
defineProperty("showSign", false)

-- Component position and dimensions.
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

    local imgWidth, imgHeight = getTextureSize(img)

    if not imgWidth or not imgHeight or imgWidth <= 0 or imgHeight <= 0 then
        return
    end

    local digitTileWidth = imgWidth
    local digitTileHeight = imgHeight / 14

    local v = math.abs(value) * (10 ^ frac)

    -- Round only when non-rounded values are disabled.
    if get(allowNonRound) then
        v = math.floor(v + 0.5)
    end

    local panelWidth = pos[3] or 100
    local panelHeight = pos[4] or 100

    local digitWidth = (digitTileWidth + panelHeight) * 0.35 - 4
    local digitHeight = (digitTileHeight + panelHeight) * 0.35

    local posX = panelWidth - digitTileWidth + 15


    -- Draw decimal separator.
    if frac > 0 then
        local sourceY = 13 * digitTileHeight
        sourceY = imgHeight - sourceY - digitTileHeight

        drawTexturePart(
            img,
            posX - digitWidth * frac,
            0,
            digitWidth,
            digitHeight,
            0,
            sourceY,
            digitTileWidth,
            digitTileHeight
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

            -- Roll the next digit when the previous digit approaches rollover.
            if prevDigit > 9.5 then
                digit = digit + 1
            end

            prevDigit = digit
            v = math.floor(v / 10)

            local sourceY = (11 - digit) * digitTileHeight

            -- Texture coordinates use the lower-left image origin.
            sourceY = imgHeight - sourceY - digitTileHeight

            drawTexturePart(
                img,
                posX,
                0,
                digitWidth,
                digitHeight,
                0,
                sourceY,
                digitTileWidth,
                digitTileHeight
            )

            posX = posX - digitWidth

            -- Skip the decimal separator position.
            if frac == i then
                posX = posX - digitWidth
            end

            if i > frac and not leading and v == 0 then
                break
            end
        end


        -- Draw negative sign.
        if sign and value < 0 then
            local sourceY = 14 * digitTileHeight
            sourceY = imgHeight - sourceY - digitTileHeight

            drawTexturePart(
                img,
                posX,
                0,
                digitWidth,
                digitHeight,
                0,
                sourceY,
                digitTileWidth,
                digitTileHeight
            )
        end
    end


    -- Draw optional overlay texture.
    if overlayImg then
        local w, h = getTextureSize(overlayImg)

        if w and h and w > 0 and h > 0 then
            drawTexture(
                overlayImg,
                0,
                0,
                w,
                h
            )
        end
    end
end
