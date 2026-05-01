local C = require("src.constants")
local BonusSchema = require("src.bonus_schema")
local MetaTree = require("src.data.meta_tree")

local Meta = {}

local DEFINITIONS = MetaTree.definitions
local LAYOUT = MetaTree.layout
local CAPSTONE_KEYS = MetaTree.capstoneKeys

local function depthMultiplierFor(def)
    local depth = def.treeDepth or 0
    for _, rule in ipairs(C.META_COST_DEPTH_MULTIPLIERS) do
        if depth <= rule.maxDepth then
            return rule.multiplier
        end
    end
    return 1
end

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

function Meta.getTreeLayout()
    return LAYOUT
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
