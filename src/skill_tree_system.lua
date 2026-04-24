local Utils = require("src.utils")

local SkillTree = {}

local CATEGORIES = {
    { id = "core", name = "Core", color = { 0.95, 0.9, 0.35 } },
    { id = "hunting", name = "Hunting", color = { 0.95, 0.5, 0.45 } },
    { id = "efficiency", name = "Efficiency", color = { 0.45, 0.9, 0.95 } },
    { id = "combat", name = "Combat", color = { 0.78, 0.55, 0.98 } },
}

local EFFECT_ROTATION = {
    { stat = "speed", add = 4 },
    { stat = "reach", add = 1.2 },
    { stat = "nutritionMult", add = 0.03 },
    { stat = "xpMult", add = 0.03 },
    { stat = "rareBonus", add = 0.004 },
    { stat = "eliteBonus", add = 0.0022 },
    { stat = "bite", add = 0.9 },
    { stat = "magnet", add = 2.0 },
}

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
                cost = baseCost,
                deps = deps,
                effect = effect,
                unlocked = false,
            }
            index = index + 1
        end
    end

    nodes[1].cost = 0
    return nodes
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

    if savedSkills and savedSkills.unlocked then
        for _, nodeId in ipairs(savedSkills.unlocked) do
            local node = tree.nodes[nodeId]
            if node and not node.unlocked then
                node.unlocked = true
                tree.unlockedCount = tree.unlockedCount + 1
            end
        end
    else
        tree.nodes[1].unlocked = true
        tree.unlockedCount = 1
    end

    if tree.unlockedCount == 0 then
        tree.nodes[1].unlocked = true
        tree.unlockedCount = 1
    end

    return tree
end

function SkillTree.export(tree)
    local unlocked = {}
    for _, node in ipairs(tree.nodes) do
        if node.unlocked then
            unlocked[#unlocked + 1] = node.id
        end
    end
    return {
        unlocked = unlocked,
        cameraX = tree.cameraX,
        cameraY = tree.cameraY,
        zoom = tree.zoom,
    }
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
        if not dep or not dep.unlocked then
            return false
        end
    end
    return true
end

function SkillTree.canUnlock(tree, node, growth)
    if node.unlocked then
        return false, "already unlocked"
    end
    if not SkillTree.depSatisfied(tree, node) then
        return false, "dependency missing"
    end
    if growth < node.cost then
        return false, "need more growth"
    end
    return true, nil
end

function SkillTree.tryUnlock(tree, nodeId, state)
    local node = tree.nodes[nodeId]
    if not node then
        return false, "node not found"
    end

    local ok, err = SkillTree.canUnlock(tree, node, state.resources.growth)
    if not ok then
        return false, err
    end

    state.resources.growth = state.resources.growth - node.cost
    node.unlocked = true
    tree.unlockedCount = tree.unlockedCount + 1
    return true, nil
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
        if node.unlocked then
            local effect = node.effect
            bonuses[effect.stat] = bonuses[effect.stat] + effect.add
        end
    end

    return bonuses
end

function SkillTree.nodeAtWorldPosition(tree, wx, wy)
    local hitRadius = 22
    for _, node in ipairs(tree.nodes) do
        if Utils.distance(wx, wy, node.x, node.y) <= hitRadius then
            return node
        end
    end
    return nil
end

return SkillTree
