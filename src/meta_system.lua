local C = require("src.constants")
local BonusSchema = require("src.bonus_schema")
local MetaTree = require("src.data.meta_tree")

local Meta = {}

local DEFINITIONS = MetaTree.definitions
local LAYOUT = MetaTree.layout
local CAPSTONE_KEYS = MetaTree.capstoneKeys
local STARS_PER_MAP = 3

local function normalizeStarValue(value)
    return math.max(0, math.min(STARS_PER_MAP, math.floor(tonumber(value) or 0)))
end

local function makeDefaultMapStars()
    local mapStars = {}
    for _, mapData in ipairs(C.MAPS) do
        mapStars[mapData.id] = 0
    end
    return mapStars
end

local function distributeStars(total)
    local mapStars = makeDefaultMapStars()
    local remaining = math.max(0, math.floor(tonumber(total) or 0))
    for _, mapData in ipairs(C.MAPS) do
        local stars = math.min(STARS_PER_MAP, remaining)
        mapStars[mapData.id] = stars
        remaining = remaining - stars
    end
    return mapStars
end

local function normalizeMapStars(savedMapStars, fallbackTotal)
    if type(savedMapStars) ~= "table" then
        return distributeStars(fallbackTotal or 0)
    end

    local mapStars = makeDefaultMapStars()
    for key, value in pairs(savedMapStars) do
        local mapId = tonumber(key) or key
        if mapStars[mapId] ~= nil then
            mapStars[mapId] = normalizeStarValue(value)
        end
    end
    return mapStars
end

local function totalMapStars(mapStars)
    local total = 0
    for _, mapData in ipairs(C.MAPS) do
        total = total + normalizeStarValue(mapStars and mapStars[mapData.id] or 0)
    end
    return total
end

local function maxConfiguredStars()
    local defaultMax = #C.MAPS * STARS_PER_MAP
    local configured = C.STAR_BONUSES and C.STAR_BONUSES.maxStars
    return math.max(0, math.floor(tonumber(configured) or defaultMax))
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

    local mapStars = normalizeMapStars(
        saved and saved.mapStars or nil,
        saved and saved.runStars or 0
    )

    return {
        essence = saved and math.max(0, math.floor(saved.essence or 0)) or 0,
        totalRuns = saved and math.max(0, math.floor(saved.totalRuns or 0)) or 0,
        mapStars = mapStars,
        runStars = totalMapStars(mapStars),
        levels = levels,
    }
end

function Meta.export(metaState)
    metaState.mapStars = normalizeMapStars(metaState.mapStars, metaState.runStars or 0)
    local totalStars = totalMapStars(metaState.mapStars)
    metaState.runStars = totalStars
    return {
        essence = metaState.essence,
        totalRuns = metaState.totalRuns,
        mapStars = metaState.mapStars,
        runStars = totalStars,
        levels = metaState.levels,
    }
end

function Meta.getMapStars(metaState, mapId)
    if not metaState then
        return 0
    end
    local normalizedMapId = tonumber(mapId) or mapId
    return normalizeStarValue(metaState.mapStars and metaState.mapStars[normalizedMapId] or 0)
end

function Meta.setMapStars(metaState, mapId, stars)
    if not metaState then
        return 0, false
    end
    metaState.mapStars = metaState.mapStars or makeDefaultMapStars()

    local normalizedMapId = tonumber(mapId) or mapId
    local previous = Meta.getMapStars(metaState, normalizedMapId)
    local nextStars = normalizeStarValue(stars)
    local improved = nextStars > previous
    if improved then
        metaState.mapStars[normalizedMapId] = nextStars
    end

    metaState.runStars = Meta.getTotalStars(metaState)
    return Meta.getMapStars(metaState, normalizedMapId), improved
end

function Meta.getTotalStars(metaState)
    if not metaState then
        return 0
    end
    metaState.mapStars = normalizeMapStars(metaState.mapStars, metaState.runStars or 0)
    local totalStars = totalMapStars(metaState.mapStars)
    metaState.runStars = totalStars
    return totalStars
end

function Meta.getMaxStars()
    return maxConfiguredStars()
end

function Meta.getStarBonusCount(metaState)
    return math.min(Meta.getTotalStars(metaState), Meta.getMaxStars())
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

function Meta.computeStarBonuses(metaState)
    local bonuses = BonusSchema.newRaw()
    local config = C.STAR_BONUSES or {}
    local stars = Meta.getStarBonusCount(metaState)
    BonusSchema.applyPack(bonuses, config.bonusPack, stars)
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
            bonusPack = def.bonusPack,
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
