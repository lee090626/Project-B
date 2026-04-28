local ProgressionBalance = {
    maps = {
        {
            id = 1,
            nameKey = "map.1.name",
            reward = 1.0,
            hpScale = 1.0,
            spawn = { common = 0.78, rare = 0.2, elite = 0.02 },
            unlockRequires = 0,
        },
        {
            id = 2,
            nameKey = "map.2.name",
            reward = 1.28,
            hpScale = 1.28,
            spawn = { common = 0.68, rare = 0.26, elite = 0.06 },
            unlockRequires = 18,
        },
        {
            id = 3,
            nameKey = "map.3.name",
            reward = 1.62,
            hpScale = 1.62,
            spawn = { common = 0.56, rare = 0.32, elite = 0.12 },
            unlockRequires = 46,
        },
        {
            id = 4,
            nameKey = "map.4.name",
            reward = 2.0,
            hpScale = 2.05,
            spawn = { common = 0.46, rare = 0.36, elite = 0.18 },
            unlockRequires = 82,
        },
    },
    nestLevelCostBands = {
        { fromLevel = 1, toLevel = 20, multiplier = 1 },
        { fromLevel = 21, toLevel = 40, multiplier = 3 },
        { fromLevel = 41, toLevel = 60, multiplier = 6 },
        { fromLevel = 61, toLevel = math.huge, multiplier = 10 },
    },
    metaCostDepthMultipliers = {
        { maxDepth = 2, multiplier = 1.0 },
        { maxDepth = 4, multiplier = 1.25 },
        { maxDepth = 6, multiplier = 1.55 },
        { maxDepth = math.huge, multiplier = 1.9 },
    },
    metaPassiveCostDepthMultipliers = {
        { maxDepth = 0, multiplier = 1.35 },
        { maxDepth = 2, multiplier = 1.55 },
        { maxDepth = 4, multiplier = 1.85 },
        { maxDepth = math.huge, multiplier = 2.15 },
    },
}

return ProgressionBalance
