local Utils = require("src.utils")

local SkillTree = {}

local CATEGORIES = {
    { id = "core", name = "Core", color = { 0.95, 0.9, 0.35 } },
    { id = "hunting", name = "Hunting", color = { 0.95, 0.5, 0.45 } },
    { id = "efficiency", name = "Efficiency", color = { 0.45, 0.9, 0.95 } },
    { id = "combat", name = "Combat", color = { 0.78, 0.55, 0.98 } },
}

local EFFECT_ROTATION = {
    { stat = "speed", perLevel = 4, iconId = "spd" },
    { stat = "reach", perLevel = 1.2, iconId = "rng" },
    { stat = "nutritionMult", perLevel = 0.03, iconId = "nut" },
    { stat = "xpMult", perLevel = 0.03, iconId = "xp" },
    { stat = "rareBonus", perLevel = 0.004, iconId = "rar" },
    { stat = "eliteBonus", perLevel = 0.0022, iconId = "elt" },
    { stat = "bite", perLevel = 0.9, iconId = "dmg" },
    { stat = "magnet", perLevel = 2.0, iconId = "mag" },
}

local function recomputeUnlockedCount(tree)
    local count = 0
    for _, node in ipairs(tree.nodes) do
        if node.level > 0 then
            count = count + 1
        end
    end
    tree.unlockedCount = count
end

local function buildAnchorSet(nodes)
    local byCategory = {}
    for _, cat in ipairs(CATEGORIES) do
        byCategory[cat.id] = {}
    end

    for _, node in ipairs(nodes) do
        if node.gridRow == 2 or node.gridRow == 5 or node.gridRow == 8 then
            byCategory[node.category][#byCategory[node.category] + 1] = node.id
        end
    end

    local anchorSet = {}
    for _, cat in ipairs(CATEGORIES) do
        local ids = byCategory[cat.id]
        for i = 1, math.min(3, #ids) do
            anchorSet[ids[i]] = true
        end
    end

    return anchorSet
end

local function createNodes()
    local nodes = {}
    local cols = 10
    local rows = 10
    local xSpacing = 180
    local ySpacing = 130
    local startX = -850
    local startY = -560

    local index = 1
    for col = 1, cols do
        for row = 1, rows do
            local cat = CATEGORIES[((col - 1) % #CATEGORIES) + 1]
            local effect = EFFECT_ROTATION[((index - 1) % #EFFECT_ROTATION) + 1]
            local deps = {}

            if col > 1 then
                deps[#deps + 1] = (col - 2) * rows + row
                if row > 1 and row % 2 == 0 then
                    deps[#deps + 1] = (col - 2) * rows + (row - 1)
                end
            elseif row > 1 then
                deps[#deps + 1] = row - 1
            end

            local baseCost = 5 + (col - 1) * 5 + math.floor((row - 1) * 1.8)
            nodes[index] = {
                id = index,
                name = string.format("%s Node %02d", cat.name, index),
                category = cat.id,
                categoryColor = cat.color,
                x = startX + (col - 1) * xSpacing + ((row % 2) * 20),
                y = startY + (row - 1) * ySpacing,
                gridRow = row,
                deps = deps,
                iconId = effect.iconId,
                isAnchor = false,
                level = 0,
                maxLevel = 1,
                costBase = baseCost,
                costScale = 1.0,
                effect = {
                    stat = effect.stat,
                    perLevel = effect.perLevel,
                },
            }
            index = index + 1
        end
    end

    local anchorSet = buildAnchorSet(nodes)
    for _, node in ipairs(nodes) do
        if anchorSet[node.id] then
            node.isAnchor = true
            node.maxLevel = 10
            node.costScale = 1.33
        end
    end

    nodes[1].level = 1
    return nodes
end

local function applySaved(tree, savedSkills)
    if not savedSkills then
        return
    end

    if savedSkills.nodes then
        for _, entry in ipairs(savedSkills.nodes) do
            local node = tree.nodes[entry.id]
            if node then
                node.level = Utils.clamp(entry.level or 0, 0, node.maxLevel)
            end
        end
        return
    end

    if savedSkills.unlocked then
        for _, nodeId in ipairs(savedSkills.unlocked) do
            local node = tree.nodes[nodeId]
            if node then
                node.level = math.max(node.level, 1)
            end
        end
    end
end

function SkillTree.new(savedSkills)
    local tree = {
        nodes = createNodes(),
        categoryList = CATEGORIES,
        unlockedCount = 0,
        cameraX = 0,
        cameraY = 0,
        zoom = 0.65,
    }

    applySaved(tree, savedSkills)

    if savedSkills then
        tree.cameraX = savedSkills.cameraX or tree.cameraX
        tree.cameraY = savedSkills.cameraY or tree.cameraY
        tree.zoom = savedSkills.zoom or tree.zoom
    end

    if tree.nodes[1].level <= 0 then
        tree.nodes[1].level = 1
    end

    recomputeUnlockedCount(tree)
    return tree
end

function SkillTree.export(tree)
    local nodeLevels = {}
    for _, node in ipairs(tree.nodes) do
        if node.level > 0 then
            nodeLevels[#nodeLevels + 1] = {
                id = node.id,
                level = node.level,
            }
        end
    end

    return {
        nodes = nodeLevels,
        cameraX = tree.cameraX,
        cameraY = tree.cameraY,
        zoom = tree.zoom,
    }
end

function SkillTree.isUnlocked(node)
    return node.level > 0
end

function SkillTree.allUnlocked(tree)
    return tree.unlockedCount >= #tree.nodes
end

function SkillTree.depSatisfied(tree, node)
    if #node.deps == 0 then
        return true
    end
    for _, depId in ipairs(node.deps) do
        local dep = tree.nodes[depId]
        if not dep or dep.level <= 0 then
            return false
        end
    end
    return true
end

function SkillTree.getNextCost(node)
    if node.level >= node.maxLevel then
        return nil
    end
    local scalePow = node.isAnchor and node.level or 0
    return math.floor(node.costBase * (node.costScale ^ scalePow))
end

function SkillTree.getCurrentValue(node)
    return node.effect.perLevel * node.level
end

function SkillTree.getNextValue(node)
    local nextLevel = math.min(node.level + 1, node.maxLevel)
    return node.effect.perLevel * nextLevel
end

function SkillTree.canUnlock(tree, node, growth)
    if not SkillTree.depSatisfied(tree, node) then
        return false, "dependency missing"
    end

    if node.level >= node.maxLevel then
        return false, node.isAnchor and "max level" or "already unlocked"
    end

    local cost = SkillTree.getNextCost(node)
    if not cost or growth < cost then
        return false, "need more growth"
    end

    return true, nil
end

function SkillTree.tryUnlock(tree, nodeId, state)
    local node = tree.nodes[nodeId]
    if not node then
        return false, "node not found", nil
    end

    local ok, err = SkillTree.canUnlock(tree, node, state.resources.growth)
    if not ok then
        return false, err, nil
    end

    local cost = SkillTree.getNextCost(node)
    local wasUnlocked = node.level > 0

    state.resources.growth = state.resources.growth - cost
    node.level = node.level + 1

    if not wasUnlocked and node.level > 0 then
        tree.unlockedCount = tree.unlockedCount + 1
    end

    return true, nil, {
        level = node.level,
        maxLevel = node.maxLevel,
        cost = cost,
        isAnchor = node.isAnchor,
    }
end

function SkillTree.computeBonuses(tree)
    local bonuses = {
        speed = 0,
        reach = 0,
        nutritionMult = 0,
        xpMult = 0,
        rareBonus = 0,
        eliteBonus = 0,
        bite = 0,
        magnet = 0,
    }

    for _, node in ipairs(tree.nodes) do
        if node.level > 0 then
            local effect = node.effect
            bonuses[effect.stat] = bonuses[effect.stat] + (effect.perLevel * node.level)
        end
    end

    return bonuses
end

function SkillTree.nodeAtWorldPosition(tree, wx, wy)
    local hitRadius = 24
    for _, node in ipairs(tree.nodes) do
        local dx = math.abs(wx - node.x)
        local dy = math.abs(wy - node.y)
        if (dx + dy) <= hitRadius then
            return node
        end
    end
    return nil
end

function SkillTree.getTooltipInfo(tree, node, growth)
    local canBuy, reason = SkillTree.canUnlock(tree, node, growth)
    return {
        canBuy = canBuy,
        reason = reason,
        currentLevel = node.level,
        maxLevel = node.maxLevel,
        cost = SkillTree.getNextCost(node),
        currentValue = SkillTree.getCurrentValue(node),
        nextValue = SkillTree.getNextValue(node),
    }
end

return SkillTree
