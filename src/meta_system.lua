local C = require("src.constants")
local BonusSchema = require("src.bonus_schema")

local Meta = {}

local DEFINITIONS = {}
local LAYOUT = {}
local CAPSTONE_KEYS = {
    "core_apex",
    "hunt_apex",
    "economy_apex",
    "lightning_apex",
    "fireball_apex",
}

local function addNode(args)
    local index = #DEFINITIONS + 1
    DEFINITIONS[index] = {
        key = args.key,
        nameKey = "meta." .. args.key .. ".name",
        descKey = "meta." .. args.key .. ".desc",
        category = args.category,
        icon = args.icon,
        deps = args.deps or {},
        maxLevel = args.maxLevel or 1,
        baseCost = args.baseCost or 1,
        scale = args.scale or 1.0,
        bonusPack = args.bonusPack or {},
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

local function addBranch(prefix, category, nodes)
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
            bonusPack = node.bonusPack,
            x = node.x,
            y = node.y,
        }
    end
    return out
end

refs.core = addBranch("core", "time", {
    { key = "mid_clock", icon = "MID", deps = { "origin" }, maxLevel = 1, baseCost = 6, scale = 1.0, bonusPack = { midBonusTime = 1 }, x = 0.0, y = -0.18 },
    { key = "final_clock", icon = "FIN", deps = { 1 }, maxLevel = 1, baseCost = 8, scale = 1.0, bonusPack = { finalBonusTime = 1 }, x = 0.0, y = -0.36 },
    { key = "overtime", icon = "OT", deps = { 2 }, maxLevel = 2, baseCost = 10, scale = 1.22, bonusPack = { bonusTimeCap = 1 }, x = 0.0, y = -0.54 },
    { key = "last_window", icon = "WND", deps = { 3 }, maxLevel = 2, baseCost = 12, scale = 1.24, bonusPack = { finalWindowMin = 1 }, x = 0.0, y = -0.72 },
    { key = "flow", icon = "SPD", deps = { 4 }, maxLevel = 3, baseCost = 14, scale = 1.26, bonusPack = { speed = 8 }, x = -0.14, y = -0.9 },
    { key = "focus", icon = "BTE", deps = { 4 }, maxLevel = 3, baseCost = 14, scale = 1.26, bonusPack = { eventBiteBonus = 10 }, x = 0.14, y = -0.9 },
    { key = "hoard", icon = "ESS", deps = { 5, 6 }, maxLevel = 3, baseCost = 18, scale = 1.28, bonusPack = { essenceMult = 0.08 }, x = 0.0, y = -1.08 },
    {
        key = "apex",
        icon = "APX",
        deps = { 7 },
        maxLevel = 1,
        baseCost = 28,
        scale = 1.0,
        bonusPack = { midBonusTime = 1, finalBonusTime = 1, bonusTimeCap = 1, eventBiteBonus = 14 },
        x = 0.0,
        y = -1.26,
    },
})

refs.hunt = addBranch("hunt", "hunt", {
    { key = "stride", icon = "SPD", deps = { "origin" }, maxLevel = 4, baseCost = 5, scale = 1.22, bonusPack = { speed = 12 }, x = 0.18, y = 0.0 },
    { key = "maw", icon = "MAW", deps = { 1 }, maxLevel = 4, baseCost = 7, scale = 1.23, bonusPack = { reach = 1.8 }, x = 0.36, y = 0.0 },
    { key = "bite", icon = "BTE", deps = { 2 }, maxLevel = 4, baseCost = 9, scale = 1.24, bonusPack = { contactBite = 8 }, x = 0.54, y = 0.0 },
    { key = "pursuit", icon = "RSH", deps = { 3 }, maxLevel = 4, baseCost = 11, scale = 1.25, bonusPack = { speed = 16 }, x = 0.72, y = 0.0 },
    { key = "hook", icon = "JAW", deps = { 4 }, maxLevel = 3, baseCost = 13, scale = 1.26, bonusPack = { reach = 2.2 }, x = 0.9, y = -0.1 },
    { key = "maul", icon = "RAM", deps = { 4 }, maxLevel = 3, baseCost = 13, scale = 1.26, bonusPack = { contactBite = 12 }, x = 0.9, y = 0.1 },
    { key = "lock", icon = "LCK", deps = { 5, 6 }, maxLevel = 3, baseCost = 18, scale = 1.28, bonusPack = { eventBiteBonus = 18 }, x = 1.08, y = 0.0 },
    {
        key = "apex",
        icon = "APX",
        deps = { 7 },
        maxLevel = 1,
        baseCost = 28,
        scale = 1.0,
        bonusPack = { contactBite = 18, eventBiteBonus = 24 },
        x = 1.26,
        y = 0.0,
    },
})

refs.economy = addBranch("economy", "economy", {
    { key = "greed", icon = "ESS", deps = { "origin" }, maxLevel = 4, baseCost = 5, scale = 1.22, bonusPack = { essenceMult = 0.08 }, x = -0.18, y = 0.0 },
    { key = "scent", icon = "RAR", deps = { 1 }, maxLevel = 3, baseCost = 7, scale = 1.23, bonusPack = { rareBonus = 0.015 }, x = -0.36, y = 0.0 },
    { key = "crown", icon = "ELT", deps = { 2 }, maxLevel = 3, baseCost = 9, scale = 1.24, bonusPack = { eliteBonus = 0.008 }, x = -0.54, y = 0.0 },
    { key = "pull", icon = "MAG", deps = { 3 }, maxLevel = 4, baseCost = 11, scale = 1.25, bonusPack = { magnet = 16 }, x = -0.72, y = 0.0 },
    { key = "trail", icon = "SPN", deps = { 4 }, maxLevel = 4, baseCost = 13, scale = 1.26, bonusPack = { spawnRate = 0.10 }, x = -0.9, y = -0.1 },
    { key = "brood", icon = "CAP", deps = { 4 }, maxLevel = 3, baseCost = 13, scale = 1.26, bonusPack = { spawnCap = 8 }, x = -0.9, y = 0.1 },
    { key = "gold", icon = "VAL", deps = { 5, 6 }, maxLevel = 3, baseCost = 18, scale = 1.28, bonusPack = { rareValue = 0.18, eliteValue = 0.2 }, x = -1.08, y = 0.0 },
    {
        key = "apex",
        icon = "APX",
        deps = { 7 },
        maxLevel = 1,
        baseCost = 28,
        scale = 1.0,
        bonusPack = { essenceMult = 0.14, magnet = 24, spawnCap = 10 },
        x = -1.26,
        y = 0.0,
    },
})

refs.lightning = addBranch("lightning", "lightning", {
    { key = "root", icon = "LIT", deps = { "origin" }, maxLevel = 1, baseCost = 8, scale = 1.0, bonusPack = { lightningEnabled = 1 }, x = 0.18, y = 0.18 },
    { key = "shock", icon = "DMG", deps = { 1 }, maxLevel = 4, baseCost = 10, scale = 1.23, bonusPack = { lightningDamage = 10 }, x = 0.36, y = 0.36 },
    { key = "link", icon = "LNK", deps = { 2 }, maxLevel = 2, baseCost = 12, scale = 1.24, bonusPack = { lightningChain = 1 }, x = 0.54, y = 0.54 },
    { key = "pulse", icon = "CLD", deps = { 3 }, maxLevel = 3, baseCost = 14, scale = 1.26, bonusPack = { lightningIntervalCut = 0.12 }, x = 0.72, y = 0.72 },
    { key = "storm", icon = "STM", deps = { 4 }, maxLevel = 3, baseCost = 16, scale = 1.27, bonusPack = { lightningDamage = 14 }, x = 0.9, y = 0.72 },
    { key = "arc", icon = "ARC", deps = { 4 }, maxLevel = 2, baseCost = 16, scale = 1.27, bonusPack = { lightningChain = 1, lightningDamage = 8 }, x = 0.9, y = 0.54 },
    { key = "relay", icon = "RLY", deps = { 5, 6 }, maxLevel = 3, baseCost = 20, scale = 1.29, bonusPack = { lightningIntervalCut = 0.14 }, x = 1.08, y = 0.63 },
    {
        key = "apex",
        icon = "APX",
        deps = { 7 },
        maxLevel = 1,
        baseCost = 30,
        scale = 1.0,
        bonusPack = { lightningDamage = 18, lightningChain = 1 },
        x = 1.26,
        y = 0.63,
    },
})

refs.fireball = addBranch("fireball", "fireball", {
    { key = "root", icon = "FIR", deps = { "origin" }, maxLevel = 1, baseCost = 8, scale = 1.0, bonusPack = { fireballEnabled = 1 }, x = -0.18, y = 0.18 },
    { key = "blast", icon = "DMG", deps = { 1 }, maxLevel = 4, baseCost = 10, scale = 1.23, bonusPack = { fireballDamage = 9 }, x = -0.36, y = 0.36 },
    { key = "core", icon = "RAD", deps = { 2 }, maxLevel = 3, baseCost = 12, scale = 1.24, bonusPack = { fireballRadius = 12 }, x = -0.54, y = 0.54 },
    { key = "count", icon = "CNT", deps = { 3 }, maxLevel = 2, baseCost = 14, scale = 1.26, bonusPack = { fireballCount = 1 }, x = -0.72, y = 0.72 },
    { key = "cinder", icon = "CLD", deps = { 4 }, maxLevel = 3, baseCost = 16, scale = 1.27, bonusPack = { fireballIntervalCut = 0.12 }, x = -0.9, y = 0.72 },
    { key = "salvo", icon = "SPL", deps = { 4 }, maxLevel = 2, baseCost = 16, scale = 1.27, bonusPack = { fireballDamage = 14, fireballSplit = 1 }, x = -0.9, y = 0.54 },
    { key = "furnace", icon = "FRN", deps = { 5, 6 }, maxLevel = 3, baseCost = 20, scale = 1.29, bonusPack = { fireballRadius = 18, fireballIntervalCut = 0.14 }, x = -1.08, y = 0.63 },
    {
        key = "apex",
        icon = "APX",
        deps = { 7 },
        maxLevel = 1,
        baseCost = 30,
        scale = 1.0,
        bonusPack = { fireballDamage = 18, fireballCount = 1, fireballRadius = 20 },
        x = -1.26,
        y = 0.63,
    },
})

local function computeTreeDepth(index)
    local def = DEFINITIONS[index]
    if def.treeDepth ~= nil then
        return def.treeDepth
    end

    if not def.deps or #def.deps == 0 then
        def.treeDepth = 0
        return def.treeDepth
    end

    local maxDepth = 0
    for _, depIndex in ipairs(def.deps) do
        maxDepth = math.max(maxDepth, computeTreeDepth(depIndex) + 1)
    end
    def.treeDepth = maxDepth
    return def.treeDepth
end

local function depthMultiplierFor(def)
    local depth = def.treeDepth or 0
    for _, rule in ipairs(C.META_COST_DEPTH_MULTIPLIERS) do
        if depth <= rule.maxDepth then
            return rule.multiplier
        end
    end
    return 1
end

for index = 1, #DEFINITIONS do
    computeTreeDepth(index)
end

local function assertUniqueLayout()
    local seen = {}
    for index, point in ipairs(LAYOUT) do
        local key = point.x .. ":" .. point.y
        local prev = seen[key]
        if prev then
            error(("meta tree layout overlap between %s and %s"):format(DEFINITIONS[prev].key, DEFINITIONS[index].key))
        end
        seen[key] = index
    end
end

assertUniqueLayout()
assert(#DEFINITIONS == 41, "meta tree must contain 41 nodes")

local function makeDefaultLevels()
    local levels = {}
    for _, def in ipairs(DEFINITIONS) do
        levels[def.key] = 0
    end
    return levels
end

local function getCost(def, level)
    return math.floor(def.baseCost * (def.scale ^ level) * depthMultiplierFor(def))
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

function Meta.getRequiredCapstoneKeys()
    return CAPSTONE_KEYS
end

function Meta.new(saved)
    local levels = makeDefaultLevels()
    if saved and saved.levels then
        for key, value in pairs(saved.levels) do
            if levels[key] ~= nil then
                levels[key] = math.max(0, math.floor(value))
            end
        end
    end

    return {
        essence = saved and math.max(0, math.floor(saved.essence or 0)) or 0,
        totalRuns = saved and math.max(0, math.floor(saved.totalRuns or 0)) or 0,
        runStars = saved and math.max(0, math.floor(saved.runStars or 0)) or 0,
        levels = levels,
    }
end

function Meta.export(metaState)
    return {
        essence = metaState.essence,
        totalRuns = metaState.totalRuns,
        runStars = metaState.runStars or 0,
        levels = metaState.levels,
    }
end

function Meta.computeBonuses(metaState)
    local bonuses = BonusSchema.newRaw()

    for _, def in ipairs(DEFINITIONS) do
        local level = metaState.levels[def.key] or 0
        if level > 0 then
            BonusSchema.applyPack(bonuses, def.bonusPack, level)
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

function Meta.hasRequiredCapstones(metaState)
    for _, key in ipairs(CAPSTONE_KEYS) do
        if (metaState.levels[key] or 0) <= 0 then
            return false
        end
    end
    return true
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
