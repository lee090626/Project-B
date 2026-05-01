local WorldPatterns = {
    RINGS = "rings",
    DIAMONDS = "diamonds",
    FAULTS = "faults",
    ARCS = "arcs",
}

WorldPatterns.valid = {
    [WorldPatterns.RINGS] = true,
    [WorldPatterns.DIAMONDS] = true,
    [WorldPatterns.FAULTS] = true,
    [WorldPatterns.ARCS] = true,
}

function WorldPatterns.isValid(value)
    return WorldPatterns.valid[value] == true
end

return WorldPatterns
