local Utils = {}

function Utils.clamp(v, minV, maxV)
    if v < minV then
        return minV
    end
    if v > maxV then
        return maxV
    end
    return v
end

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.distance(ax, ay, bx, by)
    local dx = bx - ax
    local dy = by - ay
    return math.sqrt(dx * dx + dy * dy)
end

return Utils
