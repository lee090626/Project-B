local C = require("src.constants")

local Nest = {}

local ORDER = {}
for _, def in ipairs(C.NEST_UPGRADES) do
    ORDER[#ORDER + 1] = def.key
end

local function makeDefaultLevels()
    local levels = {}
    for _, key in ipairs(ORDER) do
        levels[key] = 0
    end
    return levels
end

local function getDefinition(key)
    for _, def in ipairs(C.NEST_UPGRADES) do
        if def.key == key then
            return def
        end
    end
    return nil
end

local function getCost(def, currentLevel)
    return def.basePointCost + math.floor(currentLevel / 4)
end

local function getLevelBandMultiplier(level)
    for _, band in ipairs(C.NEST_LEVEL_COST_BANDS) do
        if level >= band.fromLevel and level <= band.toLevel then
            return band.multiplier
        end
    end
    return 1
end

local function getLevelCost(level)
    local baseCost = 5 * (2 * level - 1)
    return math.floor(baseCost * getLevelBandMultiplier(level) + 0.5)
end

local function getStartChoices(level)
    if level <= 0 then
        return 0
    end
    return 1 + math.floor((level - 1) / 3)
end

local function getThresholdFactor(level)
    return math.max(0.75, 1 - level * 0.025)
end

local function getChoiceCount(level)
    return level >= 7 and 4 or 3
end

local function getRarityShift(level)
    return level
end

local function effectPayload(key, level)
    if key == "brooder" then
        return "nest.effect.brooder", { count = getStartChoices(level) }
    end
    if key == "larder" then
        local reduction = math.floor((1 - getThresholdFactor(level)) * 100 + 0.5)
        return "nest.effect.larder", { percent = reduction }
    end
    if key == "roost" then
        return "nest.effect.roost", { speed = level * 3, magnet = level * 6 }
    end
    if key == "hatchery" then
        return "nest.effect.hatchery", { count = getChoiceCount(level), shift = getRarityShift(level) }
    end
    return "", {}
end

function Nest.new(saved)
    local levels = makeDefaultLevels()
    if saved and saved.levels then
        for key, value in pairs(saved.levels) do
            if levels[key] ~= nil then
                levels[key] = math.max(0, math.floor(value))
            end
        end
    end

    return {
        totalEssence = saved and math.max(0, math.floor(saved.totalEssence or 0)) or 0,
        levels = levels,
    }
end

function Nest.export(nest)
    return {
        totalEssence = nest.totalEssence,
        levels = nest.levels,
    }
end

function Nest.getEssenceThreshold(level)
    local cappedLevel = math.max(0, math.floor(level or 0))
    local total = 0
    for currentLevel = 1, cappedLevel do
        total = total + getLevelCost(currentLevel)
    end
    return total
end

local function getSpentPoints(nest)
    local spent = 0
    for _, key in ipairs(ORDER) do
        local def = getDefinition(key)
        local level = math.max(0, math.floor(nest.levels[key] or 0))
        for currentLevel = 0, level - 1 do
            spent = spent + getCost(def, currentLevel)
        end
    end
    return spent
end

function Nest.getProgress(nest)
    local totalEssence = math.max(0, math.floor(nest.totalEssence or 0))
    local level = 0
    local currentLevelStart = 0
    local nextLevelEssence = getLevelCost(1)

    while nextLevelEssence <= totalEssence do
        level = level + 1
        currentLevelStart = nextLevelEssence
        nextLevelEssence = currentLevelStart + getLevelCost(level + 1)
    end

    local spentPoints = getSpentPoints(nest)
    local availablePoints = math.max(0, level - spentPoints)

    local evolutionIndex = 1
    for i, threshold in ipairs(C.DRAGON_EVOLUTION_LEVELS) do
        if level >= threshold then
            evolutionIndex = i + 1
        end
    end

    return {
        totalEssence = totalEssence,
        level = level,
        spentPoints = spentPoints,
        availablePoints = availablePoints,
        nextLevelEssence = nextLevelEssence,
        nextLevelCost = math.max(0, nextLevelEssence - totalEssence),
        currentLevelStart = currentLevelStart,
        currentLevelProgress = totalEssence - currentLevelStart,
        essencePerLevel = getLevelCost(level + 1),
        evolutionIndex = evolutionIndex,
        evolutionKey = "evolution.stage." .. evolutionIndex,
    }
end

function Nest.computeBonuses(nest)
    local brooder = nest.levels.brooder or 0
    local larder = nest.levels.larder or 0
    local roost = nest.levels.roost or 0
    local hatchery = nest.levels.hatchery or 0

    return {
        speed = roost * 3,
        magnet = roost * 6,
        startingChoices = getStartChoices(brooder),
        thresholdFactor = getThresholdFactor(larder),
        choiceCount = getChoiceCount(hatchery),
        rarityShift = getRarityShift(hatchery),
    }
end

function Nest.getUpgradeRows(nest)
    local rows = {}
    local progress = Nest.getProgress(nest)
    for _, def in ipairs(C.NEST_UPGRADES) do
        local level = nest.levels[def.key] or 0
        local maxed = level >= def.maxLevel
        local cost = maxed and nil or getCost(def, level)
        local canBuy = (not maxed) and progress.availablePoints >= cost
        local reason = maxed and "MAX" or (canBuy and "BUY" or "NEED_POINTS")
        local effectKey, effectParams = effectPayload(def.key, level)
        local nextEffectKey, nextEffectParams = effectPayload(def.key, math.min(def.maxLevel, level + 1))
        rows[#rows + 1] = {
            key = def.key,
            nameKey = "nest.upgrade." .. def.key .. ".name",
            descKey = "nest.upgrade." .. def.key .. ".desc",
            level = level,
            maxLevel = def.maxLevel,
            cost = cost,
            canBuy = canBuy,
            maxed = maxed,
            reason = reason,
            effectKey = effectKey,
            effectParams = effectParams,
            nextEffectKey = nextEffectKey,
            nextEffectParams = nextEffectParams,
        }
    end
    return rows
end

function Nest.tryUpgrade(nest, key)
    local def = getDefinition(key)
    if not def then
        return false, "invalid_key"
    end

    local level = nest.levels[key] or 0
    if level >= def.maxLevel then
        return false, "already_max"
    end

    local cost = getCost(def, level)
    local progress = Nest.getProgress(nest)
    if progress.availablePoints < cost then
        return false, "not_enough_points"
    end

    nest.levels[key] = level + 1
    return true, nil
end

return Nest
