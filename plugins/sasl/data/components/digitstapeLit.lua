-- no image by default
defineProperty("image")

-- image to display over digits (for 3d effect)
defineProperty("overlayImage")

-- default value
defineProperty("value", 0)

-- maximum digits
defineProperty("digits", 1)

-- maximum digits
defineProperty("fractional", 0)

-- allow non-round values
defineProperty("allowNonRound", false)

-- enable of disable value display
defineProperty("valueEnabler", true)

-- show leading zeros
defineProperty("showLeadingZeros", false)

-- show sign instead of first digit
defineProperty("showSign", false)

local WHITE = { 1, 1, 1, 1 }

function draw()
    local sign = get(showSign)
    local leading = get(showLeadingZeros)
    local digitsNum = get(digits)
    local frac = get(fractional)
    local symbolsNum = digitsNum
    if 0 < frac then
        symbolsNum = symbolsNum + 1
    end
    local digitWidth = 100 / symbolsNum

    local v = math.abs(get(value)) * (10 ^ frac)
    if get(allowNonRound) then
        v = math.floor(v + 0.5)
    end
    local pos = 100 - digitWidth
    local digitHeight = 0.0714285714286
    local img = get(image)
    local overlayImg = get(overlayImage)
    local textureWidth, textureHeight = sasl.gl.getTextureSize(img)

    if 0 < frac then
        local y = (12 + 1) * digitHeight
        sasl.gl.drawTexturePart(img, pos - digitWidth * frac, 0, digitWidth, 100,
            0, y * textureHeight, textureWidth, digitHeight * textureHeight, WHITE)
    end

    if get(valueEnabler) then
        local prevDigit = 0
        if sign then
            digitsNum = digitsNum - 1
        end
        for i = 1, digitsNum do
            local digit = v % 10
            if 9.5 < prevDigit then
                digit = digit + 1
            end
            prevDigit = digit
            v = math.floor(v / 10)
            local y = (10 - digit + 1) * digitHeight
            sasl.gl.drawTexturePart(img, pos, 0, digitWidth, 100,
                0, y * textureHeight, textureWidth, digitHeight * textureHeight, WHITE)
            pos = pos - digitWidth
            if frac == i then
                pos = pos - digitWidth
            end
            if (i > frac) and (not leading) and (0 == v) then
                break
            end
        end
        if sign and (0 > get(value)) then
            local y = (13 + 1) * digitHeight
            sasl.gl.drawTexturePart(img, pos, 0, digitWidth, 100,
                0, y * textureHeight, textureWidth, digitHeight * textureHeight, WHITE)
        end
    end
        
    if overlayImg then
        sasl.gl.drawTexture(overlayImg, 0, 0, 100, 100, WHITE)
    end
end

