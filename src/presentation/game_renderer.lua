local C = require("src.constants")
local Player = require("src.player_controller")
local MapSystem = require("src.map_system")
local SkillTree = require("src.skill_tree_system")

local Renderer = {}

local function currentMapColor(mapId)
    if mapId == 1 then
        return { 0.12, 0.17, 0.12 }, { 0.2, 0.32, 0.2 }
    elseif mapId == 2 then
        return { 0.08, 0.09, 0.15 }, { 0.16, 0.18, 0.28 }
    elseif mapId == 3 then
        return { 0.2, 0.08, 0.06 }, { 0.38, 0.13, 0.1 }
    end
    return { 0.08, 0.05, 0.1 }, { 0.19, 0.1, 0.25 }
end

local function drawWorld(state)
    local mapData = MapSystem.getCurrentMap(state.maps)
    local bgA, bgB = currentMapColor(mapData.id)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    love.graphics.setColor(bgA)
    love.graphics.rectangle("fill", 0, 0, sw, sh)
    love.graphics.setColor(bgB)
    love.graphics.rectangle("fill", 0, sh * 0.52, sw, sh * 0.48)

    love.graphics.push()
    love.graphics.scale(state.camera.zoom)
    love.graphics.translate(-state.camera.x, -state.camera.y)

    love.graphics.setColor(0.15, 0.15, 0.15, 0.35)
    for x = 0, C.WORLD_WIDTH, 80 do
        love.graphics.line(x, 0, x, C.WORLD_HEIGHT)
    end
    for y = 0, C.WORLD_HEIGHT, 80 do
        love.graphics.line(0, y, C.WORLD_WIDTH, y)
    end

    for _, item in ipairs(state.food.list) do
        love.graphics.setColor(item.color)
        love.graphics.circle("fill", item.x, item.y, item.radius)
    end

    if state.boss.active or state.boss.defeated then
        local pulse = state.boss.active and (math.sin(state.boss.pulse * 4) * 0.08 + 0.92) or 0.6
        love.graphics.setColor(0.9 * pulse, 0.25 * pulse, 0.2 * pulse)
        love.graphics.circle("fill", state.boss.x, state.boss.y, state.boss.radius)
        love.graphics.setColor(0.2, 0.05, 0.05)
        love.graphics.circle("line", state.boss.x, state.boss.y, state.boss.radius + 4)
    end

    local eatRadius = Player.getEatRadius(state.player, state.bonuses)
    local magnetRadius = Player.getMagnetRadius(state.player, state.bonuses)
    state.player.magnetRadius = magnetRadius

    love.graphics.setColor(0.9, 0.8, 0.2, 0.12)
    love.graphics.circle("fill", state.player.x, state.player.y, magnetRadius)

    love.graphics.setColor(0.9, 0.45, 0.3)
    love.graphics.circle("fill", state.player.x, state.player.y, state.player.radius)
    love.graphics.setColor(1, 0.9, 0.75)
    love.graphics.circle("fill", state.player.x + 5, state.player.y - 4, 2)

    love.graphics.setColor(0.95, 0.7, 0.3, 0.25)
    love.graphics.circle("line", state.player.x, state.player.y, eatRadius)

    love.graphics.pop()
end

local function drawHUD(state, fonts, ui)
    local sw = love.graphics.getWidth()
    local mapData = MapSystem.getCurrentMap(state.maps)
    local unlockedMaps = 0
    for _, map in ipairs(C.MAPS) do
        if state.maps.unlocked[map.id] then
            unlockedMaps = unlockedMaps + 1
        end
    end

    love.graphics.setFont(fonts.hud)
    love.graphics.setColor(0, 0, 0, 0.42)
    love.graphics.rectangle("fill", 12, 12, 420, 190, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("Nutrition: %.0f", state.resources.nutrition), 24, 24)
    love.graphics.print(string.format("Growth: %.0f", state.resources.growth), 24, 48)
    love.graphics.print(string.format("Consumed: %d", state.food.consumedTotal), 24, 72)
    love.graphics.print(string.format("Skills: %d / %d", state.skillTree.unlockedCount, #state.skillTree.nodes), 24, 96)
    love.graphics.print(string.format("Map: %s (%d/%d)", mapData.name, unlockedMaps, #C.MAPS), 24, 120)
    love.graphics.print("[TAB] Skill Tree  [1-4] Map  [B] Boss", 24, 144)
    love.graphics.print("[F5] Save  [F9] Load", 24, 168)

    ui.saveBtn.x = sw - 146
    ui.saveBtn.y = 20
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", ui.saveBtn.x, ui.saveBtn.y, ui.saveBtn.w, ui.saveBtn.h, 6, 6)
    love.graphics.setColor(0.9, 0.95, 0.9)
    love.graphics.rectangle("line", ui.saveBtn.x, ui.saveBtn.y, ui.saveBtn.w, ui.saveBtn.h, 6, 6)
    love.graphics.print("Manual Save", ui.saveBtn.x + 14, ui.saveBtn.y + 8)

    if state.boss.active then
        local pct = state.boss.maxHp > 0 and (state.boss.hp / state.boss.maxHp) or 0
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", sw * 0.2, 16, sw * 0.6, 20)
        love.graphics.setColor(0.9, 0.2, 0.2)
        love.graphics.rectangle("fill", sw * 0.2 + 2, 18, (sw * 0.6 - 4) * pct, 16)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Final Boss", sw * 0.2, 18, sw * 0.6, "center")
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Autosave: " .. state.lastSaveStatus, 0, love.graphics.getHeight() - 24, sw, "center")

    if state.message then
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", 12, love.graphics.getHeight() - 70, 680, 30, 6, 6)
        love.graphics.setColor(1, 0.9, 0.7)
        love.graphics.print(state.message, 20, love.graphics.getHeight() - 62)
    end

    if state.endingReached then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", sw * 0.2, love.graphics.getHeight() * 0.35, sw * 0.6, 120, 10, 10)
        love.graphics.setColor(1, 0.95, 0.75)
        love.graphics.setFont(fonts.big)
        love.graphics.printf("ENDING CLEARED", sw * 0.2, love.graphics.getHeight() * 0.39, sw * 0.6, "center")
        love.graphics.setFont(fonts.hud)
        love.graphics.printf("All skills + all maps + final boss complete", sw * 0.2, love.graphics.getHeight() * 0.45, sw * 0.6, "center")
    end
end

local function drawSkillTreeOverlay(state, fonts, treeWorldFromScreen)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local tree = state.skillTree

    love.graphics.setColor(0, 0, 0, 0.82)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    love.graphics.push()
    love.graphics.translate(sw * 0.5, sh * 0.5)
    love.graphics.scale(tree.zoom)
    love.graphics.translate(-tree.cameraX, -tree.cameraY)

    for _, node in ipairs(tree.nodes) do
        if #node.deps > 0 then
            for _, depId in ipairs(node.deps) do
                local dep = tree.nodes[depId]
                if dep then
                    if node.unlocked and dep.unlocked then
                        love.graphics.setColor(0.95, 0.85, 0.45, 0.7)
                    else
                        love.graphics.setColor(0.45, 0.45, 0.45, 0.45)
                    end
                    love.graphics.line(dep.x, dep.y, node.x, node.y)
                end
            end
        end
    end

    for _, node in ipairs(tree.nodes) do
        local unlocked = node.unlocked
        local canBuy = SkillTree.depSatisfied(tree, node) and state.resources.growth >= node.cost and not unlocked

        if unlocked then
            love.graphics.setColor(0.95, 0.95, 0.45)
        elseif canBuy then
            love.graphics.setColor(0.45, 0.98, 0.5)
        else
            love.graphics.setColor(node.categoryColor[1], node.categoryColor[2], node.categoryColor[3], 0.45)
        end

        love.graphics.circle("fill", node.x, node.y, 17)
        love.graphics.setColor(0.12, 0.12, 0.12)
        love.graphics.circle("line", node.x, node.y, 17)
    end

    love.graphics.pop()

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.hud)
    love.graphics.print("SKILL TREE [TAB to close, drag to pan, wheel to zoom, click to unlock]", 18, 16)
    love.graphics.print(string.format("Growth: %.0f | Unlocked: %d/%d", state.resources.growth, tree.unlockedCount, #tree.nodes), 18, 40)

    local mx, my = love.mouse.getPosition()
    local treeX, treeY = treeWorldFromScreen(mx, my)
    local hovered = SkillTree.nodeAtWorldPosition(tree, treeX, treeY)

    if hovered then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 18, sh - 116, 520, 94, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(hovered.name, 30, sh - 104)
        love.graphics.print("Cost: " .. hovered.cost .. " growth", 30, sh - 80)
        love.graphics.print("Effect: +" .. hovered.effect.add .. " " .. hovered.effect.stat, 30, sh - 56)
        local depsOk = SkillTree.depSatisfied(tree, hovered)
        love.graphics.print("Deps: " .. (depsOk and "ready" or "locked"), 30, sh - 32)
    end
end

function Renderer.draw(state, fonts, ui, treeWorldFromScreen)
    drawWorld(state)
    drawHUD(state, fonts, ui)

    if state.mode == "tree" then
        drawSkillTreeOverlay(state, fonts, treeWorldFromScreen)
    end
end

return Renderer
