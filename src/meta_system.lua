local Utils = require("src.utils")

local Meta = {}

local DEFINITIONS = {
    {
        key = "swift_wings",
        name = "Swift Wings",
        desc = "Move speed +14 per level",
        deps = {},
        maxLevel = 20,
        baseCost = 8,
        scale = 1.35,
        bonusKey = "speed",
        bonusPerLevel = 14,
    },
    {
        key = "gluttony",
        name = "Gluttony",
        desc = "All gain +8% per level",
        deps = { 1 },
        maxLevel = 20,
        baseCost = 10,
        scale = 1.36,
        bonusKey = "gainMult",
        bonusPerLevel = 0.08,
    },
    {
        key = "sharp_fangs",
        name = "Sharp Fangs",
        desc = "Boss bite damage +2 per level",
        deps = { 1 },
        maxLevel = 20,
        baseCost = 12,
        scale = 1.34,
        bonusKey = "bite",
        bonusPerLevel = 2,
    },
    {
        key = "long_neck",
        name = "Long Neck",
        desc = "Eat range +1.5 per level",
        deps = { 2 },
        maxLevel = 20,
        baseCost = 11,
        scale = 1.33,
        bonusKey = "reach",
        bonusPerLevel = 1.5,
    },
    {
        key = "prep_instinct",
        name = "Prep Instinct",
        desc = "Start growth +12 per level",
        deps = { 2 },
        maxLevel = 20,
        baseCost = 7,
        scale = 1.38,
        bonusKey = "startGrowth",
        bonusPerLevel = 12,
    },
    {
        key = "hourglass_core",
        name = "Hourglass Core",
        desc = "Run time +5 sec per level",
        deps = { 3, 4, 5 },
        maxLevel = 15,
        baseCost = 16,
        scale = 1.4,
        bonusKey = "extraTime",
        bonusPerLevel = 5,
    },
}

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

local function depsSatisfied(meta, def)
    if not def.deps or #def.deps == 0 then
        return true
    end

    for _, depIndex in ipairs(def.deps) do
        local depDef = DEFINITIONS[depIndex]
        if not depDef then
            return false
        end
        if (meta.levels[depDef.key] or 0) <= 0 then
            return false
        end
    end
    return true
end

function Meta.getDefinitions()
    return DEFINITIONS
end

function Meta.new(saved)
    return {
        essence = saved and saved.essence or 0,
        totalRuns = saved and saved.totalRuns or 0,
        levels = saved and saved.levels or makeDefaultLevels(),
    }
end

function Meta.export(meta)
    return {
        essence = meta.essence,
        totalRuns = meta.totalRuns,
        levels = meta.levels,
    }
end

function Meta.computeBonuses(meta)
    local bonuses = {
        speed = 0,
        gainMult = 1,
        bite = 0,
        reach = 0,
        startGrowth = 0,
        extraTime = 0,
    }

    for _, def in ipairs(DEFINITIONS) do
        local level = meta.levels[def.key] or 0
        if level > 0 then
            if def.bonusKey == "gainMult" then
                bonuses.gainMult = bonuses.gainMult + def.bonusPerLevel * level
            else
                bonuses[def.bonusKey] = bonuses[def.bonusKey] + def.bonusPerLevel * level
            end
        end
    end

    return bonuses
end

function Meta.getUpgradeInfo(meta)
    local rows = {}
    for i, def in ipairs(DEFINITIONS) do
        local level = meta.levels[def.key] or 0
        local maxed = level >= def.maxLevel
        local cost = maxed and nil or getCost(def, level)
        local depsOk = depsSatisfied(meta, def)
        local canBuy = (not maxed) and depsOk and meta.essence >= cost
        local reason
        if maxed then
            reason = "MAX"
        elseif not depsOk then
            reason = "LOCKED"
        elseif meta.essence < cost then
            reason = "NEED ESSENCE"
        else
            reason = "BUY"
        end

        rows[#rows + 1] = {
            index = i,
            key = def.key,
            name = def.name,
            desc = def.desc,
            deps = def.deps,
            level = level,
            maxLevel = def.maxLevel,
            cost = cost,
            maxed = maxed,
            canBuy = canBuy,
            reason = reason,
        }
    end
    return rows
end

function Meta.tryBuy(meta, index)
    local def = DEFINITIONS[index]
    if not def then
        return false, "invalid index"
    end

    local level = meta.levels[def.key] or 0
    if level >= def.maxLevel then
        return false, "already max"
    end

    if not depsSatisfied(meta, def) then
        return false, "dependency missing"
    end

    local cost = getCost(def, level)
    if meta.essence < cost then
        return false, "not enough essence"
    end

    meta.essence = meta.essence - cost
    meta.levels[def.key] = level + 1
    return true, nil
end

function Meta.calculateRunReward(state)
    local nutrition = state.resources.nutrition
    local growth = state.resources.growth
    local consumed = state.food.consumedTotal
    local unlocked = state.skillTree.unlockedCount

    local base = nutrition * 0.22 + growth * 0.55 + consumed * 0.25 + unlocked * 1.4
    if state.boss.defeated then
        base = base + 85
    end
    if state.endingReached then
        base = base + 140
    end

    return Utils.round(math.max(10, base))
end

return Meta
