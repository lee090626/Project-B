local Meta = {}

local DEFINITIONS = {}
local LAYOUT = {}
local INTEGER_REBALANCE_KEYS = {
    speed = true,
    magnet = true,
    contactBite = true,
    spawnCap = true,
    lightningDamage = true,
    lightningChain = true,
    fireballDamage = true,
    fireballCount = true,
    fireballRadius = true,
    fireballSplit = true,
    frostDamage = true,
    frostRadius = true,
}
local ECONOMY_REBALANCE_KEYS = {
    essenceMult = true,
    rareValue = true,
    eliteValue = true,
    spawnRate = true,
    rareBonus = true,
    eliteBonus = true,
}
local COOLDOWN_REBALANCE_KEYS = {
    lightningIntervalCut = true,
    fireballIntervalCut = true,
    frostIntervalCut = true,
}
local STATUS_REBALANCE_KEYS = {
    frostSlow = true,
    frostDuration = true,
}

local function round(value, digits)
    local scale = 10 ^ digits
    return math.floor(value * scale + 0.5) / scale
end

local function rebalanceBonus(def)
    if not def.bonusKey then
        return
    end

    local value = def.bonusPerLevel
    if INTEGER_REBALANCE_KEYS[def.bonusKey] then
        def.bonusPerLevel = math.floor(value * 0.75)
    elseif def.bonusKey == "reach" then
        def.bonusPerLevel = round(value * 0.8, 1)
    elseif ECONOMY_REBALANCE_KEYS[def.bonusKey] then
        def.bonusPerLevel = round(value * 0.7, 2)
    elseif COOLDOWN_REBALANCE_KEYS[def.bonusKey] or STATUS_REBALANCE_KEYS[def.bonusKey] then
        def.bonusPerLevel = round(value * 0.75, 2)
    end
end

local function addNode(args)
    local index = #DEFINITIONS + 1
    DEFINITIONS[index] = {
        key = args.key,
        nameKey = "meta." .. args.key .. ".name",
        descKey = "meta." .. args.key .. ".desc",
        category = args.category,
        icon = args.icon,
        deps = args.deps or {},
        maxLevel = args.maxLevel,
        baseCost = args.baseCost,
        scale = args.scale,
        bonusKey = args.bonusKey,
        bonusPerLevel = args.bonusPerLevel,
    }
    LAYOUT[index] = { x = args.x, y = args.y }
    return index
end

local refs = {}

refs.origin = addNode {
    key = "origin_heart",
    category = "core",
    icon = "ORG",
    deps = {},
    maxLevel = 1,
    baseCost = 3,
    scale = 1.0,
    x = 0.0,
    y = 0.0,
}

local function addMainBranch(prefix, category, nodes)
    local out = {}
    for i, node in ipairs(nodes) do
        local deps = {}
        for _, depRef in ipairs(node.deps) do
            if depRef == "origin" then
                deps[#deps + 1] = refs.origin
            else
                deps[#deps + 1] = out[depRef]
            end
        end
        out[i] = addNode {
            key = prefix .. "_" .. node.key,
            category = category,
            icon = node.icon,
            deps = deps,
            maxLevel = node.maxLevel,
            baseCost = node.baseCost,
            scale = node.scale,
            bonusKey = node.bonusKey,
            bonusPerLevel = node.bonusPerLevel,
            x = node.x,
            y = node.y,
        }
    end
    return out
end

refs.up = addMainBranch("up", "mobility", {
    { key = "swift", icon = "SPD", deps = { "origin" }, maxLevel = 8, baseCost = 5, scale = 1.24, bonusKey = "speed", bonusPerLevel = 8, x = 0.0, y = -0.18 },
    { key = "maw", icon = "MAW", deps = { 1 }, maxLevel = 8, baseCost = 7, scale = 1.25, bonusKey = "reach", bonusPerLevel = 1.2, x = 0.0, y = -0.36 },
    { key = "bite", icon = "BTE", deps = { 2 }, maxLevel = 8, baseCost = 9, scale = 1.26, bonusKey = "contactBite", bonusPerLevel = 4, x = 0.0, y = -0.54 },
    { key = "rush", icon = "RSH", deps = { 3 }, maxLevel = 7, baseCost = 12, scale = 1.27, bonusKey = "speed", bonusPerLevel = 12, x = 0.0, y = -0.72 },
    { key = "crown", icon = "CRN", deps = { 4 }, maxLevel = 6, baseCost = 17, scale = 1.28, bonusKey = "contactBite", bonusPerLevel = 7, x = 0.0, y = -0.9 },
    { key = "drift", icon = "DWF", deps = { 1 }, maxLevel = 7, baseCost = 7, scale = 1.25, bonusKey = "speed", bonusPerLevel = 6, x = -0.18, y = -0.18 },
    { key = "jaws", icon = "JAW", deps = { 2 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "reach", bonusPerLevel = 1.0, x = 0.18, y = -0.36 },
    { key = "ram", icon = "RAM", deps = { 3 }, maxLevel = 6, baseCost = 11, scale = 1.27, bonusKey = "contactBite", bonusPerLevel = 5, x = -0.18, y = -0.54 },
    { key = "feather", icon = "LSH", deps = { 4 }, maxLevel = 6, baseCost = 15, scale = 1.28, bonusKey = "speed", bonusPerLevel = 15, x = 0.18, y = -0.72 },
    { key = "majesty", icon = "PRD", deps = { 5, 9 }, maxLevel = 5, baseCost = 22, scale = 1.3, bonusKey = "reach", bonusPerLevel = 2.1, x = 0.18, y = -0.9 },
})

refs.right = addMainBranch("right", "economy", {
    { key = "greed", icon = "ECO", deps = { "origin" }, maxLevel = 8, baseCost = 5, scale = 1.24, bonusKey = "essenceMult", bonusPerLevel = 0.06, x = 0.18, y = 0.0 },
    { key = "lure", icon = "RAR", deps = { 1 }, maxLevel = 8, baseCost = 7, scale = 1.25, bonusKey = "rareBonus", bonusPerLevel = 0.008, x = 0.36, y = 0.0 },
    { key = "feast", icon = "ELT", deps = { 2 }, maxLevel = 8, baseCost = 10, scale = 1.26, bonusKey = "eliteBonus", bonusPerLevel = 0.0045, x = 0.54, y = 0.0 },
    { key = "hoard", icon = "GLD", deps = { 3 }, maxLevel = 7, baseCost = 13, scale = 1.27, bonusKey = "essenceMult", bonusPerLevel = 0.08, x = 0.72, y = 0.0 },
    { key = "royal", icon = "ROY", deps = { 4 }, maxLevel = 6, baseCost = 18, scale = 1.29, bonusKey = "eliteValue", bonusPerLevel = 0.18, x = 0.9, y = 0.0 },
    { key = "gold", icon = "GLD", deps = { 2 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "rareValue", bonusPerLevel = 0.10, x = 0.36, y = -0.18 },
    { key = "brood", icon = "MAG", deps = { 2 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "magnet", bonusPerLevel = 9, x = 0.36, y = 0.18 },
    { key = "nest", icon = "POP", deps = { 3 }, maxLevel = 6, baseCost = 12, scale = 1.27, bonusKey = "spawnCap", bonusPerLevel = 5, x = 0.54, y = -0.18 },
    { key = "bloom", icon = "SPN", deps = { 3 }, maxLevel = 6, baseCost = 12, scale = 1.27, bonusKey = "spawnRate", bonusPerLevel = 0.07, x = 0.54, y = 0.18 },
    { key = "vault", icon = "VLT", deps = { 5, 8 }, maxLevel = 5, baseCost = 24, scale = 1.3, bonusKey = "essenceMult", bonusPerLevel = 0.12, x = 0.9, y = -0.18 },
})

refs.down = addMainBranch("down", "combat", {
    { key = "fang", icon = "DMG", deps = { "origin" }, maxLevel = 8, baseCost = 5, scale = 1.24, bonusKey = "contactBite", bonusPerLevel = 5, x = 0.0, y = 0.18 },
    { key = "stride", icon = "SPD", deps = { 1 }, maxLevel = 8, baseCost = 7, scale = 1.25, bonusKey = "speed", bonusPerLevel = 7, x = 0.0, y = 0.36 },
    { key = "arc", icon = "LNK", deps = { 2 }, maxLevel = 5, baseCost = 10, scale = 1.27, bonusKey = "lightningChain", bonusPerLevel = 1, x = 0.0, y = 0.54 },
    { key = "burst", icon = "FIR", deps = { 3 }, maxLevel = 4, baseCost = 14, scale = 1.28, bonusKey = "fireballSplit", bonusPerLevel = 1, x = 0.0, y = 0.72 },
    { key = "blizzard", icon = "ICE", deps = { 4 }, maxLevel = 5, baseCost = 18, scale = 1.29, bonusKey = "frostDuration", bonusPerLevel = 0.25, x = 0.0, y = 0.9 },
    { key = "ram", icon = "JAW", deps = { 1 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "contactBite", bonusPerLevel = 6, x = -0.18, y = 0.18 },
    { key = "field", icon = "PUL", deps = { 2 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "magnet", bonusPerLevel = 10, x = 0.18, y = 0.36 },
    { key = "fork", icon = "THN", deps = { 3 }, maxLevel = 6, baseCost = 12, scale = 1.27, bonusKey = "lightningDamage", bonusPerLevel = 6, x = -0.18, y = 0.54 },
    { key = "ember", icon = "EMB", deps = { 4 }, maxLevel = 6, baseCost = 13, scale = 1.28, bonusKey = "fireballDamage", bonusPerLevel = 5, x = 0.18, y = 0.72 },
    { key = "cold", icon = "CLD", deps = { 5, 9 }, maxLevel = 5, baseCost = 22, scale = 1.31, bonusKey = "frostDamage", bonusPerLevel = 4, x = 0.18, y = 0.9 },
})

refs.left = addMainBranch("left", "utility", {
    { key = "drag", icon = "MAG", deps = { "origin" }, maxLevel = 8, baseCost = 5, scale = 1.24, bonusKey = "magnet", bonusPerLevel = 8, x = -0.18, y = 0.0 },
    { key = "trail", icon = "SNF", deps = { 1 }, maxLevel = 8, baseCost = 7, scale = 1.25, bonusKey = "spawnRate", bonusPerLevel = 0.06, x = -0.36, y = 0.0 },
    { key = "brood", icon = "CAL", deps = { 2 }, maxLevel = 8, baseCost = 10, scale = 1.26, bonusKey = "spawnCap", bonusPerLevel = 6, x = -0.54, y = 0.0 },
    { key = "sweep", icon = "SWP", deps = { 3 }, maxLevel = 7, baseCost = 13, scale = 1.27, bonusKey = "speed", bonusPerLevel = 10, x = -0.72, y = 0.0 },
    { key = "vacuum", icon = "VAC", deps = { 4 }, maxLevel = 6, baseCost = 18, scale = 1.29, bonusKey = "magnet", bonusPerLevel = 16, x = -0.9, y = 0.0 },
    { key = "wide", icon = "RNG", deps = { 2 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "reach", bonusPerLevel = 1.1, x = -0.36, y = -0.18 },
    { key = "dash", icon = "DSH", deps = { 2 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "speed", bonusPerLevel = 8, x = -0.36, y = 0.18 },
    { key = "grid", icon = "GRD", deps = { 3 }, maxLevel = 6, baseCost = 12, scale = 1.27, bonusKey = "essenceMult", bonusPerLevel = 0.05, x = -0.54, y = -0.18 },
    { key = "pack", icon = "PAC", deps = { 3 }, maxLevel = 6, baseCost = 12, scale = 1.27, bonusKey = "spawnRate", bonusPerLevel = 0.08, x = -0.54, y = 0.18 },
    { key = "storm", icon = "SRH", deps = { 5, 8 }, maxLevel = 5, baseCost = 24, scale = 1.3, bonusKey = "spawnCap", bonusPerLevel = 10, x = -0.9, y = -0.18 },
})

local function addPassiveCluster(prefix, category, icon, rootDeps, points, defs)
    local indices = {}
    for i, def in ipairs(defs) do
        local deps = {}
        if i == 1 then
            for _, depIndex in ipairs(rootDeps) do
                deps[#deps + 1] = depIndex
            end
        else
            for _, depRef in ipairs(def.deps) do
                deps[#deps + 1] = indices[depRef]
            end
        end
        indices[i] = addNode {
            key = prefix .. "_" .. def.key,
            category = category,
            icon = def.icon or icon,
            deps = deps,
            maxLevel = def.maxLevel,
            baseCost = def.baseCost,
            scale = def.scale,
            bonusKey = def.bonusKey,
            bonusPerLevel = def.bonusPerLevel,
            x = points[i].x,
            y = points[i].y,
        }
    end
    return indices
end

local lightningPoints = {
    { x = 0.54, y = 0.54 }, { x = 0.72, y = 0.54 }, { x = 0.9, y = 0.54 }, { x = 1.08, y = 0.54 },
    { x = 0.72, y = 0.72 }, { x = 0.9, y = 0.72 }, { x = 0.9, y = 0.36 }, { x = 1.08, y = 0.36 },
    { x = 0.54, y = 0.72 }, { x = 0.54, y = 0.9 }, { x = 0.72, y = 0.9 }, { x = 0.9, y = 0.9 },
    { x = 1.08, y = 0.72 }, { x = 1.26, y = 0.72 }, { x = 1.26, y = 0.54 }, { x = 1.26, y = 0.36 },
}

local firePoints = {
    { x = -0.36, y = 0.72 }, { x = -0.54, y = 0.72 }, { x = -0.72, y = 0.72 }, { x = -0.9, y = 0.72 },
    { x = -0.54, y = 0.9 }, { x = -0.72, y = 0.9 }, { x = -0.72, y = 0.54 }, { x = -0.9, y = 0.54 },
    { x = -0.36, y = 0.9 }, { x = -0.36, y = 1.08 }, { x = -0.54, y = 1.08 }, { x = -0.72, y = 1.08 },
    { x = -0.9, y = 0.9 }, { x = -1.08, y = 0.9 }, { x = -1.08, y = 0.72 }, { x = -1.08, y = 0.54 },
}

local frostPoints = {
    { x = -0.54, y = -0.36 }, { x = -0.72, y = -0.36 }, { x = -0.9, y = -0.36 }, { x = -1.08, y = -0.36 },
    { x = -0.72, y = -0.54 }, { x = -0.9, y = -0.54 }, { x = -0.9, y = -0.18 }, { x = -1.08, y = -0.18 },
    { x = -0.54, y = -0.54 }, { x = -0.54, y = -0.72 }, { x = -0.72, y = -0.72 }, { x = -0.9, y = -0.72 },
    { x = -1.08, y = -0.54 }, { x = -1.26, y = -0.54 }, { x = -1.26, y = -0.36 }, { x = -1.26, y = -0.18 },
}

refs.lightning = addPassiveCluster("lightning", "lightning", "LIT", { refs.down[3], refs.right[3] }, lightningPoints, {
    { key = "root", maxLevel = 1, baseCost = 18, scale = 1.0, bonusKey = "lightningEnabled", bonusPerLevel = 1 },
    { key = "dmg1", deps = { 1 }, maxLevel = 6, baseCost = 10, scale = 1.27, bonusKey = "lightningDamage", bonusPerLevel = 8 },
    { key = "rate1", deps = { 2 }, maxLevel = 6, baseCost = 12, scale = 1.28, bonusKey = "lightningIntervalCut", bonusPerLevel = 0.08 },
    { key = "dmg2", deps = { 3 }, maxLevel = 5, baseCost = 16, scale = 1.29, bonusKey = "lightningDamage", bonusPerLevel = 12 },
    { key = "chain1", deps = { 2 }, maxLevel = 3, baseCost = 13, scale = 1.28, bonusKey = "lightningChain", bonusPerLevel = 1 },
    { key = "chain2", deps = { 5 }, maxLevel = 3, baseCost = 18, scale = 1.29, bonusKey = "lightningChain", bonusPerLevel = 1 },
    { key = "rate2", deps = { 3 }, maxLevel = 5, baseCost = 15, scale = 1.29, bonusKey = "lightningIntervalCut", bonusPerLevel = 0.1 },
    { key = "dmg3", deps = { 4 }, maxLevel = 4, baseCost = 20, scale = 1.3, bonusKey = "lightningDamage", bonusPerLevel = 16 },
    { key = "arc1", deps = { 1 }, maxLevel = 5, baseCost = 11, scale = 1.27, bonusKey = "lightningDamage", bonusPerLevel = 6 },
    { key = "arc2", deps = { 9 }, maxLevel = 5, baseCost = 13, scale = 1.28, bonusKey = "lightningIntervalCut", bonusPerLevel = 0.06 },
    { key = "arc3", deps = { 10 }, maxLevel = 5, baseCost = 15, scale = 1.29, bonusKey = "lightningDamage", bonusPerLevel = 9 },
    { key = "arc4", deps = { 11 }, maxLevel = 2, baseCost = 22, scale = 1.3, bonusKey = "lightningChain", bonusPerLevel = 1 },
    { key = "surge1", deps = { 4 }, maxLevel = 4, baseCost = 22, scale = 1.3, bonusKey = "lightningDamage", bonusPerLevel = 18 },
    { key = "surge2", deps = { 13 }, maxLevel = 4, baseCost = 24, scale = 1.31, bonusKey = "lightningIntervalCut", bonusPerLevel = 0.12 },
    { key = "surge3", deps = { 14 }, maxLevel = 3, baseCost = 28, scale = 1.32, bonusKey = "lightningDamage", bonusPerLevel = 24 },
    { key = "apex", deps = { 15, 8 }, maxLevel = 2, baseCost = 34, scale = 1.34, bonusKey = "lightningChain", bonusPerLevel = 2 },
})

refs.fireball = addPassiveCluster("fireball", "fireball", "FIR", { refs.down[4], refs.up[3] }, firePoints, {
    { key = "root", maxLevel = 1, baseCost = 18, scale = 1.0, bonusKey = "fireballEnabled", bonusPerLevel = 1 },
    { key = "dmg1", deps = { 1 }, maxLevel = 6, baseCost = 10, scale = 1.27, bonusKey = "fireballDamage", bonusPerLevel = 7 },
    { key = "rate1", deps = { 2 }, maxLevel = 6, baseCost = 12, scale = 1.28, bonusKey = "fireballIntervalCut", bonusPerLevel = 0.08 },
    { key = "dmg2", deps = { 3 }, maxLevel = 5, baseCost = 16, scale = 1.29, bonusKey = "fireballDamage", bonusPerLevel = 10 },
    { key = "count1", deps = { 2 }, maxLevel = 2, baseCost = 14, scale = 1.28, bonusKey = "fireballCount", bonusPerLevel = 1 },
    { key = "count2", deps = { 5 }, maxLevel = 2, baseCost = 20, scale = 1.29, bonusKey = "fireballCount", bonusPerLevel = 1 },
    { key = "rate2", deps = { 3 }, maxLevel = 5, baseCost = 15, scale = 1.29, bonusKey = "fireballIntervalCut", bonusPerLevel = 0.1 },
    { key = "dmg3", deps = { 4 }, maxLevel = 4, baseCost = 20, scale = 1.3, bonusKey = "fireballDamage", bonusPerLevel = 14 },
    { key = "rad1", deps = { 1 }, maxLevel = 5, baseCost = 11, scale = 1.27, bonusKey = "fireballRadius", bonusPerLevel = 10 },
    { key = "rad2", deps = { 9 }, maxLevel = 5, baseCost = 13, scale = 1.28, bonusKey = "fireballRadius", bonusPerLevel = 12 },
    { key = "rad3", deps = { 10 }, maxLevel = 5, baseCost = 15, scale = 1.29, bonusKey = "fireballDamage", bonusPerLevel = 8 },
    { key = "rad4", deps = { 11 }, maxLevel = 2, baseCost = 22, scale = 1.3, bonusKey = "fireballCount", bonusPerLevel = 1 },
    { key = "split1", deps = { 4 }, maxLevel = 3, baseCost = 22, scale = 1.3, bonusKey = "fireballSplit", bonusPerLevel = 1 },
    { key = "split2", deps = { 13 }, maxLevel = 4, baseCost = 24, scale = 1.31, bonusKey = "fireballIntervalCut", bonusPerLevel = 0.12 },
    { key = "split3", deps = { 14 }, maxLevel = 3, baseCost = 28, scale = 1.32, bonusKey = "fireballDamage", bonusPerLevel = 18 },
    { key = "apex", deps = { 15, 8 }, maxLevel = 3, baseCost = 34, scale = 1.34, bonusKey = "fireballRadius", bonusPerLevel = 18 },
})

refs.frost = addPassiveCluster("frost", "frost", "ICE", { refs.left[3], refs.up[2] }, frostPoints, {
    { key = "root", maxLevel = 1, baseCost = 18, scale = 1.0, bonusKey = "frostEnabled", bonusPerLevel = 1 },
    { key = "dmg1", deps = { 1 }, maxLevel = 6, baseCost = 10, scale = 1.27, bonusKey = "frostDamage", bonusPerLevel = 5 },
    { key = "rate1", deps = { 2 }, maxLevel = 6, baseCost = 12, scale = 1.28, bonusKey = "frostIntervalCut", bonusPerLevel = 0.08 },
    { key = "dmg2", deps = { 3 }, maxLevel = 5, baseCost = 16, scale = 1.29, bonusKey = "frostDamage", bonusPerLevel = 7 },
    { key = "slow1", deps = { 2 }, maxLevel = 4, baseCost = 13, scale = 1.28, bonusKey = "frostSlow", bonusPerLevel = 0.05 },
    { key = "slow2", deps = { 5 }, maxLevel = 4, baseCost = 18, scale = 1.29, bonusKey = "frostSlow", bonusPerLevel = 0.06 },
    { key = "rate2", deps = { 3 }, maxLevel = 5, baseCost = 15, scale = 1.29, bonusKey = "frostIntervalCut", bonusPerLevel = 0.1 },
    { key = "dmg3", deps = { 4 }, maxLevel = 4, baseCost = 20, scale = 1.3, bonusKey = "frostDamage", bonusPerLevel = 10 },
    { key = "rad1", deps = { 1 }, maxLevel = 5, baseCost = 11, scale = 1.27, bonusKey = "frostRadius", bonusPerLevel = 10 },
    { key = "rad2", deps = { 9 }, maxLevel = 5, baseCost = 13, scale = 1.28, bonusKey = "frostRadius", bonusPerLevel = 12 },
    { key = "rad3", deps = { 10 }, maxLevel = 5, baseCost = 15, scale = 1.29, bonusKey = "frostDamage", bonusPerLevel = 6 },
    { key = "rad4", deps = { 11 }, maxLevel = 4, baseCost = 22, scale = 1.3, bonusKey = "frostDuration", bonusPerLevel = 0.2 },
    { key = "veil1", deps = { 4 }, maxLevel = 4, baseCost = 22, scale = 1.3, bonusKey = "frostRadius", bonusPerLevel = 16 },
    { key = "veil2", deps = { 13 }, maxLevel = 4, baseCost = 24, scale = 1.31, bonusKey = "frostIntervalCut", bonusPerLevel = 0.12 },
    { key = "veil3", deps = { 14 }, maxLevel = 3, baseCost = 28, scale = 1.32, bonusKey = "frostDamage", bonusPerLevel = 14 },
    { key = "apex", deps = { 15, 8 }, maxLevel = 3, baseCost = 34, scale = 1.34, bonusKey = "frostDuration", bonusPerLevel = 0.35 },
})

for _, def in ipairs(DEFINITIONS) do
    rebalanceBonus(def)
end

assert(#DEFINITIONS == 89, "meta tree must contain 89 nodes")

local function makeDefaultLevels()
    local levels = {}
    for _, def in ipairs(DEFINITIONS) do
        levels[def.key] = 0
    end
    return levels
end

local function getCost(def, level)
    return math.floor(def.baseCost * (def.scale ^ level))
end

local function depsSatisfied(metaState, def)
    if not def.deps or #def.deps == 0 then
        return true
    end
    for _, depIndex in ipairs(def.deps) do
        local depDef = DEFINITIONS[depIndex]
        if not depDef or (metaState.levels[depDef.key] or 0) <= 0 then
            return false
        end
    end
    return true
end

local function isVisible(metaState, def)
    if not def.deps or #def.deps == 0 then
        return true
    end
    return depsSatisfied(metaState, def)
end

function Meta.getDefinitions()
    return DEFINITIONS
end

function Meta.getTreeLayout()
    return LAYOUT
end

function Meta.new(saved)
    local levels = makeDefaultLevels()
    if saved and saved.levels then
        for key, value in pairs(saved.levels) do
            if levels[key] ~= nil then
                levels[key] = value
            end
        end
    end

    return {
        essence = saved and saved.essence or 0,
        totalRuns = saved and saved.totalRuns or 0,
        levels = levels,
    }
end

function Meta.export(metaState)
    return {
        essence = metaState.essence,
        totalRuns = metaState.totalRuns,
        levels = metaState.levels,
    }
end

function Meta.computeBonuses(metaState)
    local bonuses = {
        speed = 0,
        reach = 0,
        magnet = 0,
        contactBite = 0,
        rareBonus = 0,
        eliteBonus = 0,
        spawnRate = 0,
        spawnCap = 0,
        essenceMult = 1,
        rareValue = 1,
        eliteValue = 1,
        lightningEnabled = 0,
        lightningDamage = 0,
        lightningChain = 0,
        lightningIntervalCut = 0,
        fireballEnabled = 0,
        fireballDamage = 0,
        fireballCount = 0,
        fireballRadius = 0,
        fireballIntervalCut = 0,
        fireballSplit = 0,
        frostEnabled = 0,
        frostDamage = 0,
        frostRadius = 0,
        frostSlow = 0,
        frostDuration = 0,
        frostIntervalCut = 0,
    }

    for _, def in ipairs(DEFINITIONS) do
        local level = metaState.levels[def.key] or 0
        if level > 0 and def.bonusKey then
            bonuses[def.bonusKey] = bonuses[def.bonusKey] + def.bonusPerLevel * level
        end
    end

    return bonuses
end

function Meta.getUnlockedCount(metaState)
    local count = 0
    for _, def in ipairs(DEFINITIONS) do
        if (metaState.levels[def.key] or 0) > 0 then
            count = count + 1
        end
    end
    return count
end

function Meta.allUnlocked(metaState)
    return Meta.getUnlockedCount(metaState) >= #DEFINITIONS
end

function Meta.getUpgradeInfo(metaState)
    local rows = {}
    for i, def in ipairs(DEFINITIONS) do
        local level = metaState.levels[def.key] or 0
        local visible = isVisible(metaState, def)
        local maxed = level >= def.maxLevel
        local cost = maxed and nil or getCost(def, level)
        local depsOk = depsSatisfied(metaState, def)
        local canBuy = (not maxed) and depsOk and metaState.essence >= cost
        local reason
        if maxed then
            reason = "MAX"
        elseif not depsOk then
            reason = "LOCKED"
        elseif metaState.essence < cost then
            reason = "NEED_ESSENCE"
        else
            reason = "BUY"
        end

        rows[#rows + 1] = {
            index = i,
            key = def.key,
            nameKey = def.nameKey,
            descKey = def.descKey,
            category = def.category,
            icon = def.icon,
            deps = def.deps,
            level = level,
            maxLevel = def.maxLevel,
            cost = cost,
            maxed = maxed,
            canBuy = canBuy,
            reason = reason,
            visible = visible,
            layout = LAYOUT[i],
        }
    end
    return rows
end

function Meta.tryBuy(metaState, index)
    local def = DEFINITIONS[index]
    if not def then
        return false, "invalid_index"
    end

    local level = metaState.levels[def.key] or 0
    if level >= def.maxLevel then
        return false, "already_max"
    end
    if not depsSatisfied(metaState, def) then
        return false, "dependency_missing"
    end

    local cost = getCost(def, level)
    if metaState.essence < cost then
        return false, "not_enough_essence"
    end

    metaState.essence = metaState.essence - cost
    metaState.levels[def.key] = level + 1
    return true, nil
end

function Meta.getSpentEssence(metaState)
    local spent = 0
    for _, def in ipairs(DEFINITIONS) do
        local level = math.max(0, math.floor(metaState.levels[def.key] or 0))
        for current = 0, level - 1 do
            spent = spent + getCost(def, current)
        end
    end
    return spent
end

return Meta
