-- digitstapeSmoothLit.lua
-- Generic illuminated smooth rolling digit tape component.

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

-- Allow smooth non-rounded values.
defineProperty("allowNonRound", false)

-- Enables or disables value display.
defineProperty("valueEnabler", true)

-- Show leading zeros.
defineProperty("showLeadingZeros", false)

-- Reserve the first digit position for a negative sign.
defineProperty("showSign", false)


function draw()
    local img = get(image)

    if not img then
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
    local digitHeight = 1 / 14

    local v = math.abs(value) * (10 ^ frac)

    -- Round only when smooth non-round values are disabled.
    if get(allowNonRound) then
        v = math.floor(v + 0.5)
    end

    local pos = 100 - digitWidth
    local overlayImg = get(overlayImage)

    -- Draw decimal point.
    if frac > 0 then
        local y = 13 * digitHeight

        drawTexturePart(
            img,
            pos - digitWidth * frac,
            0,
            digitWidth,
            100,
            0,
            y,
            1,
            digitHeight,
            1,
            1,
            1
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

            -- Higher digits start rolling when the previous digit passes 9.
            if i > 1 then
                digit = math.floor(v % 10) + math.max(prevDigit - 9, 0)
            end

            prevDigit = digit
            v = math.floor(v / 10)

            local y = (11 - digit) * digitHeight

            drawTexturePart(
                img,
                pos,
                0,
                digitWidth,
                100,
                0,
                y,
                1,
                digitHeight,
                1,
                1,
                1
            )

            pos = pos - digitWidth

            -- Skip the decimal-point position.
            if frac == i then
                pos = pos - digitWidth
            end

            if i > frac and not leading and v == 0 then
                break
            end
        end

        -- Draw negative sign.
        if sign and value < 0 then
            local y = 14 * digitHeight

            drawTexturePart(
                img,
                pos,
                0,
                digitWidth,
                100,
                0,
                y,
                1,
                digitHeight,
                1,
                1,
                1
            )
        end
    end

    -- Draw optional glass or lighting overlay.
    if overlayImg then
        drawTexture(
            overlayImg,
            0,
            0,
            100,
            100,
            1,
            1,
            1
        )
    end
end
