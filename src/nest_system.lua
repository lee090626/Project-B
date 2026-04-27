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

local function getCost(def, level)
    return math.floor(def.baseCost * (C.NEST_UPGRADE_SCALE ^ level))
end

local function getStartChoices(level)
    if level <= 0 then
        return 0
    end
    return 1 + math.floor((level - 1) / 3)
end

local function getThresholdFactor(level)
    return math.max(0.6, 1 - level * 0.04)
end

local function getChoiceCount(level)
    return level >= 5 and 4 or 3
end

local function getRarityShift(level)
    return level * 2
end

local function effectText(key, level)
    if key == "brooder" then
        return string.format("Start with %d instinct picks", getStartChoices(level))
    end
    if key == "larder" then
        local reduction = math.floor((1 - getThresholdFactor(level)) * 100 + 0.5)
        return string.format("Instinct level cost -%d%%", reduction)
    end
    if key == "roost" then
        return string.format("Speed +%d  Magnet +%d", level * 4, level * 8)
    end
    if key == "hatchery" then
        return string.format("Choices %d  Rarity shift %d", getChoiceCount(level), getRarityShift(level))
    end
    return ""
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
        nestMatter = saved and saved.nestMatter or 0,
        levels = levels,
    }
end

function Nest.export(nest)
    return {
        nestMatter = nest.nestMatter,
        levels = nest.levels,
    }
end

function Nest.computeBonuses(nest)
    local brooder = nest.levels.brooder or 0
    local larder = nest.levels.larder or 0
    local roost = nest.levels.roost or 0
    local hatchery = nest.levels.hatchery or 0

    return {
        speed = roost * 4,
        magnet = roost * 8,
        startingChoices = getStartChoices(brooder),
        thresholdFactor = getThresholdFactor(larder),
        choiceCount = getChoiceCount(hatchery),
        rarityShift = getRarityShift(hatchery),
    }
end

function Nest.getUpgradeRows(nest)
    local rows = {}
    for _, def in ipairs(C.NEST_UPGRADES) do
        local level = nest.levels[def.key] or 0
        local maxed = level >= def.maxLevel
        local cost = maxed and nil or getCost(def, level)
        local canBuy = (not maxed) and nest.nestMatter >= cost
        local reason = maxed and "MAX" or (canBuy and "BUY" or "NEED MATTER")
        rows[#rows + 1] = {
            key = def.key,
            name = def.name,
            desc = def.desc,
            level = level,
            maxLevel = def.maxLevel,
            cost = cost,
            canBuy = canBuy,
            maxed = maxed,
            reason = reason,
            effect = effectText(def.key, level),
            nextEffect = effectText(def.key, math.min(def.maxLevel, level + 1)),
        }
    end
    return rows
end

function Nest.tryUpgrade(nest, key)
    local def = getDefinition(key)
    if not def then
        return false, "invalid key"
    end

    local level = nest.levels[key] or 0
    if level >= def.maxLevel then
        return false, "already max"
    end

    local cost = getCost(def, level)
    if nest.nestMatter < cost then
        return false, "not enough matter"
    end

    nest.nestMatter = nest.nestMatter - cost
    nest.levels[key] = level + 1
    return true, nil
end

function Nest.awardRunMatter(state)
    local reward = math.floor((state.food.consumedTotal or 0) * C.NEST_RUN_REWARD_RATE)
    reward = reward + (state.maps.currentMapId or 1) * C.NEST_RUN_MAP_BONUS
    if state.boss.defeated then
        reward = reward + C.NEST_RUN_BOSS_BONUS
    end
    reward = math.max(C.NEST_MIN_RUN_REWARD, reward)
    state.nest.nestMatter = state.nest.nestMatter + reward
    return reward
end

return Nest
