--functions.lua 

local floor = math.floor
local interpHint = setmetatable({}, { __mode = "k" })

function fastInterpolate(tbl, x)
    local n = #tbl
    if n < 2 then return 0 end
    if x ~= x then return tbl[1][2] end
    if x >= tbl[n][1] then return tbl[n][2] end
    local i = interpHint[tbl] or 1
    if i > n - 1 then i = 1 end
    if x < tbl[i][1] or x >= tbl[i + 1][1] then
        if i + 2 <= n and x >= tbl[i + 1][1] and x < tbl[i + 2][1] then
            i = i + 1
        elseif x < tbl[1][1] then
            i = 1
        else
            local lo, hi = 1, n
            while hi - lo > 1 do
                local mid = floor((lo + hi) * 0.5)
                if tbl[mid][1] <= x then
                    lo = mid
                else
                    hi = mid
                end
            end
            i = lo
        end
        interpHint[tbl] = i
    end
    local x1, y1 = tbl[i][1], tbl[i][2]
    local x2, y2 = tbl[i + 1][1], tbl[i + 1][2]
    if x2 == x1 then return y1 end
    return y1 + (y2 - y1) * (x - x1) / (x2 - x1)
end



function clamp(x, lo, hi)
    if x ~= x then return lo end
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end



function safeClamp(value, min_val, max_val, default)
    if type(value) ~= "number" or value ~= value then
        return default or 0
    end
    return clamp(value, min_val, max_val)
end



function interpolate(tbl, value)
    local lastActual = 0
    local lastReference = 0
    for i = 1, #tbl do
        local v = tbl[i]
        if value == v[1] then
            return v[2]
        end
        if value < v[1] then
            local d = v[1] - lastActual
            if d == 0 then
                return lastReference
            end
            return lastReference
                + (value - lastActual) / d
                * (v[2] - lastReference)
        end
        lastActual = v[1]
        lastReference = v[2]
    end
    return value - lastActual + lastReference
end



function bool2int(var)
    return var and 1 or 0
end



function line(x, x1, y1, x2, y2)
    if x2 == x1 then
        return y1
    end
    return y1 + (y2 - y1) * (x - x1) / (x2 - x1)
end



function map(value, x1, x2, y1, y2)
    return line(value, x1, y1, x2, y2)
end



function isILS(freq)
    if type(freq) ~= "number" or freq ~= freq then
        return false
    end
    if freq < 10810 or freq > 11195 then
        return false
    end
    return math.floor(
        math.floor(freq + 0.5) / 10
    ) % 2 == 1
end



function sign(x)
    if x > 0 then return 1 end
    if x < 0 then return -1 end
    return 0
end



local function rotaryFill(digitTable, procNum, digitsNum, INT, wrapDigits)
    if procNum ~= procNum then
        procNum = 0
    end
    local neg = procNum < 0
    local mag = math.abs(procNum)
    local ip = math.floor(mag)
    -- Fractional part limited to 0.01 steps.
    local frac =
        INT
        and 0
        or math.floor((mag - ip) * 100) / 100
    for i = 1, digitsNum do
        local p = 10 ^ (i - 1)
        local d = math.floor(ip / p)
        if wrapDigits then
            d = d % 10
        end
        -- Drum i starts rolling when all lower digits are at 9.
        if frac > 0 and (ip % p) == p - 1 then
            d = d + frac
        end
        if neg and d ~= 0 then
            d = -d
        end
        digitTable[i] = d
    end
end



function rotaryDigits(procNum, digitsNum, signed, negSHift, INT)
    if signed == nil then signed = false end
    if negSHift == nil then negSHift = -1 end
    if INT == nil then INT = false end
    local digitTable = {}
    if signed then
        if procNum < 0 then
            digitTable[digitsNum + 1] = negSHift
        else
            digitTable[digitsNum + 1] = 0
        end
    end
    rotaryFill(
        digitTable,
        math.abs(procNum),
        digitsNum,
        INT,
        true
    )
    return digitTable
end



function rotaryDigits2(procNum, digitsNum, signed, negSHift, INT)
    if signed == nil then signed = false end
    if negSHift == nil then negSHift = -1 end
    if INT == nil then INT = false end
    local digitTable = {}
    if signed then
        if procNum < 0 then
            digitTable[digitsNum + 1] = negSHift
        else
            digitTable[digitsNum + 1] = 0
        end
        procNum = math.abs(procNum)
    end
    rotaryFill(
        digitTable,
        procNum,
        digitsNum,
        INT,
        false
    )
    return digitTable
end



function limit(value, vmin, vmax)
    if not vmin then vmin = 0 end
    if not vmax then vmax = 1 end
    if value ~= value then
        return vmin
    end
    if value < vmin then return vmin end
    if value > vmax then return vmax end
    return value
end



function mapLim(value, x1, x2, y1, y2)
    local limMin = y1
    local limMax = y2
    if limMin > limMax then
        limMin, limMax = limMax, limMin
    end
    return limit(
        map(value, x1, x2, y1, y2),
        limMin,
        limMax
    )
end



function tabMax(tab, num)
    if not tab then
        return nil, nil
    end
    local n = #tab
    if n == 0 then
        return nil, nil
    end
    if num == nil or num > n then
        num = n
    end
    local result = tab[1]
    local id = 1
    for i = 2, num do
        if result < tab[i] then
            result = tab[i]
            id = i
        end
    end
    return result, id
end




function tabMin(tab, num)
    if not tab then
        return nil, nil
    end
    local n = #tab
    if n == 0 then
        return nil, nil
    end
    if num == nil or num > n then
        num = n
    end
    local result = tab[1]
    local id = 1
    for i = 2, num do
        if result > tab[i] then
            result = tab[i]
            id = i
        end
    end
    return result, id
end




function tabMean(tab, num)
    if not tab then
        return nil, nil
    end
    local n = #tab
    if n == 0 then
        return nil, nil
    end
    if num == nil or num > n then
        num = n
    end
    local result = tab[1]
    for i = 2, num do
        result = result + tab[i]
    end
    return result / num
end




function tabSumm(tab)
    if not tab or #tab == 0 then
        return nil
    end
    local summ = 0
    for _, v in pairs(tab) do
        summ = summ + v
    end
    return summ
end




function tabShuffle(tab)
    if not tab or #tab == 0 then
        return false
    end
    for i = #tab, 2, -1 do
        local j = math.random(i)
        tab[i], tab[j] = tab[j], tab[i]
    end
    return true
end




function tabPrint(tab)
    if not tab or #tab == 0 then
        return false
    end
    for i = 1, #tab do
        print(tab[i])
    end
    return true
end




function tabPrintRow(tab)
    if not tab or #tab == 0 then
        return false
    end
    local parts = {}
    for i = 1, #tab do
        parts[i] = tostring(tab[i])
    end
    print(table.concat(parts, "  "))
    return true
end




function around(value, minVal, maxVal, round)
    if not round then
        round = maxVal - minVal
    end
    -- Prevent invalid ranges from causing endless wrapping.
    if value ~= value or not round or round <= 0 then
        return value
    end
    if value >= minVal and value <= maxVal then
        return value
    end
    local wrapped =
        minVal + (value - minVal) % round
    -- Preserve the inclusive upper bound behavior.
    -- Example: around(720, 0, 360) returns 360.
    if value > maxVal and wrapped == minVal then
        wrapped = minVal + round
    end
    return wrapped
end
