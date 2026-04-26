local Meta = {}

local DEFINITIONS = {
    {
        key = "origin_heart",
        name = "Origin Heart",
        desc = "Unlocks the four primal paths",
        category = "Core",
        icon = "ORG",
        deps = {},
        maxLevel = 1,
        baseCost = 3,
        scale = 1,
        bonusKey = "gainMult",
        bonusPerLevel = 0,
    },
    -- Mobility (Up)
    {
        key = "swift_wings",
        name = "Swift Wings",
        desc = "Move speed +12 per level",
        category = "Mobility",
        icon = "SPD",
        deps = { 1 },
        maxLevel = 20,
        baseCost = 8,
        scale = 1.32,
        bonusKey = "speed",
        bonusPerLevel = 12,
    },
    {
        key = "tail_thrust",
        name = "Tail Thrust",
        desc = "Move speed +9 per level",
        category = "Mobility",
        icon = "DAS",
        deps = { 2 },
        maxLevel = 20,
        baseCost = 10,
        scale = 1.34,
        bonusKey = "speed",
        bonusPerLevel = 9,
    },
    {
        key = "air_step",
        name = "Air Step",
        desc = "Move speed +15 per level",
        category = "Mobility",
        icon = "JET",
        deps = { 3 },
        maxLevel = 18,
        baseCost = 14,
        scale = 1.36,
        bonusKey = "speed",
        bonusPerLevel = 15,
    },
    {
        key = "long_neck",
        name = "Long Neck",
        desc = "Eat range +1.4 per level",
        category = "Mobility",
        icon = "RNG",
        deps = { 2 },
        maxLevel = 20,
        baseCost = 10,
        scale = 1.33,
        bonusKey = "reach",
        bonusPerLevel = 1.4,
    },
    {
        key = "jaw_link",
        name = "Jaw Link",
        desc = "Eat range +1.8 per level",
        category = "Mobility",
        icon = "JAW",
        deps = { 5 },
        maxLevel = 18,
        baseCost = 13,
        scale = 1.35,
        bonusKey = "reach",
        bonusPerLevel = 1.8,
    },
    {
        key = "swoop",
        name = "Sky Swoop",
        desc = "Move speed +20 per level",
        category = "Mobility",
        icon = "WNG",
        deps = { 4, 6 },
        maxLevel = 15,
        baseCost = 20,
        scale = 1.38,
        bonusKey = "speed",
        bonusPerLevel = 20,
    },

    -- Economy (Right)
    {
        key = "gluttony",
        name = "Gluttony",
        desc = "All gain +7% per level",
        category = "Economy",
        icon = "ECO",
        deps = { 1 },
        maxLevel = 20,
        baseCost = 9,
        scale = 1.34,
        bonusKey = "gainMult",
        bonusPerLevel = 0.07,
    },
    {
        key = "dense_scales",
        name = "Dense Scales",
        desc = "All gain +5% per level",
        category = "Economy",
        icon = "GLD",
        deps = { 8 },
        maxLevel = 20,
        baseCost = 11,
        scale = 1.35,
        bonusKey = "gainMult",
        bonusPerLevel = 0.05,
    },
    {
        key = "molting_memory",
        name = "Molting Memory",
        desc = "All gain +9% per level",
        category = "Economy",
        icon = "MRY",
        deps = { 9 },
        maxLevel = 18,
        baseCost = 16,
        scale = 1.37,
        bonusKey = "gainMult",
        bonusPerLevel = 0.09,
    },
    {
        key = "prep_instinct",
        name = "Prep Instinct",
        desc = "Start growth +10 per level",
        category = "Economy",
        icon = "STG",
        deps = { 8 },
        maxLevel = 20,
        baseCost = 7,
        scale = 1.36,
        bonusKey = "startGrowth",
        bonusPerLevel = 10,
    },
    {
        key = "full_stomach",
        name = "Full Stomach",
        desc = "Start growth +16 per level",
        category = "Economy",
        icon = "GRO",
        deps = { 11 },
        maxLevel = 16,
        baseCost = 14,
        scale = 1.38,
        bonusKey = "startGrowth",
        bonusPerLevel = 16,
    },
    {
        key = "golden_yolk",
        name = "Golden Yolk",
        desc = "All gain +14% per level",
        category = "Economy",
        icon = "YLK",
        deps = { 10, 12 },
        maxLevel = 12,
        baseCost = 28,
        scale = 1.42,
        bonusKey = "gainMult",
        bonusPerLevel = 0.14,
    },

    -- Combat (Down)
    {
        key = "sharp_fangs",
        name = "Sharp Fangs",
        desc = "Boss bite damage +2 per level",
        category = "Combat",
        icon = "DMG",
        deps = { 1 },
        maxLevel = 20,
        baseCost = 9,
        scale = 1.33,
        bonusKey = "bite",
        bonusPerLevel = 2,
    },
    {
        key = "plasma_tooth",
        name = "Plasma Tooth",
        desc = "Boss bite damage +3 per level",
        category = "Combat",
        icon = "BIT",
        deps = { 14 },
        maxLevel = 18,
        baseCost = 12,
        scale = 1.35,
        bonusKey = "bite",
        bonusPerLevel = 3,
    },
    {
        key = "ember_tear",
        name = "Ember Tear",
        desc = "Boss bite damage +4 per level",
        category = "Combat",
        icon = "FIR",
        deps = { 15 },
        maxLevel = 16,
        baseCost = 18,
        scale = 1.37,
        bonusKey = "bite",
        bonusPerLevel = 4,
    },
    {
        key = "scale_guard",
        name = "Scale Guard",
        desc = "All gain +4% per level",
        category = "Combat",
        icon = "GRD",
        deps = { 14 },
        maxLevel = 15,
        baseCost = 12,
        scale = 1.34,
        bonusKey = "gainMult",
        bonusPerLevel = 0.04,
    },
    {
        key = "bloodrush",
        name = "Bloodrush",
        desc = "Move speed +10 per level",
        category = "Combat",
        icon = "RSH",
        deps = { 17 },
        maxLevel = 16,
        baseCost = 12,
        scale = 1.35,
        bonusKey = "speed",
        bonusPerLevel = 10,
    },
    {
        key = "dragon_howl",
        name = "Dragon Howl",
        desc = "Boss bite damage +7 per level",
        category = "Combat",
        icon = "HOW",
        deps = { 16, 18 },
        maxLevel = 10,
        baseCost = 34,
        scale = 1.44,
        bonusKey = "bite",
        bonusPerLevel = 7,
    },

    -- Utility (Left)
    {
        key = "hourglass_core",
        name = "Hourglass Core",
        desc = "Run time +4 sec per level",
        category = "Utility",
        icon = "TIM",
        deps = { 1 },
        maxLevel = 18,
        baseCost = 11,
        scale = 1.36,
        bonusKey = "extraTime",
        bonusPerLevel = 4,
    },
    {
        key = "chrono_shell",
        name = "Chrono Shell",
        desc = "Run time +6 sec per level",
        category = "Utility",
        icon = "CLK",
        deps = { 20 },
        maxLevel = 16,
        baseCost = 15,
        scale = 1.37,
        bonusKey = "extraTime",
        bonusPerLevel = 6,
    },
    {
        key = "drift_engine",
        name = "Drift Engine",
        desc = "Run time +8 sec per level",
        category = "Utility",
        icon = "ENG",
        deps = { 21 },
        maxLevel = 14,
        baseCost = 20,
        scale = 1.4,
        bonusKey = "extraTime",
        bonusPerLevel = 8,
    },
    {
        key = "sense_veil",
        name = "Sense Veil",
        desc = "Eat range +1.0 per level",
        category = "Utility",
        icon = "SNS",
        deps = { 20 },
        maxLevel = 14,
        baseCost = 10,
        scale = 1.34,
        bonusKey = "reach",
        bonusPerLevel = 1.0,
    },
    {
        key = "overclock",
        name = "Overclock",
        desc = "Move speed +14 per level",
        category = "Utility",
        icon = "OVR",
        deps = { 23 },
        maxLevel = 12,
        baseCost = 16,
        scale = 1.38,
        bonusKey = "speed",
        bonusPerLevel = 14,
    },
    {
        key = "eternal_core",
        name = "Eternal Core",
        desc = "All gain +10% per level",
        category = "Utility",
        icon = "ETR",
        deps = { 22, 24 },
        maxLevel = 10,
        baseCost = 40,
        scale = 1.45,
        bonusKey = "gainMult",
        bonusPerLevel = 0.10,
    },
}

local LAYOUT = {
    [1] = { x = 0.5, y = 0.5 },

    -- Up branch
    [2] = { x = 0.5, y = 0.36 },
    [3] = { x = 0.5, y = 0.24 },
    [4] = { x = 0.5, y = 0.12 },
    [5] = { x = 0.38, y = 0.24 },
    [6] = { x = 0.32, y = 0.14 },
    [7] = { x = 0.42, y = 0.08 },

    -- Right branch
    [8] = { x = 0.64, y = 0.5 },
    [9] = { x = 0.76, y = 0.5 },
    [10] = { x = 0.86, y = 0.5 },
    [11] = { x = 0.76, y = 0.62 },
    [12] = { x = 0.86, y = 0.68 },
    [13] = { x = 0.92, y = 0.58 },

    -- Down branch
    [14] = { x = 0.5, y = 0.64 },
    [15] = { x = 0.5, y = 0.76 },
    [16] = { x = 0.5, y = 0.88 },
    [17] = { x = 0.62, y = 0.76 },
    [18] = { x = 0.68, y = 0.88 },
    [19] = { x = 0.58, y = 0.92 },

    -- Left branch
    [20] = { x = 0.36, y = 0.5 },
    [21] = { x = 0.24, y = 0.5 },
    [22] = { x = 0.14, y = 0.5 },
    [23] = { x = 0.24, y = 0.38 },
    [24] = { x = 0.14, y = 0.32 },
    [25] = { x = 0.08, y = 0.42 },
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

local function isVisible(meta, def)
    if not def.deps or #def.deps == 0 then
        return true
    end
    return depsSatisfied(meta, def)
end

function Meta.getDefinitions()
    return DEFINITIONS
end

function Meta.getTreeLayout()
    return LAYOUT
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
        local visible = isVisible(meta, def)
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
    return 0
end

return Meta
