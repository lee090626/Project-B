local C = require("src.constants")
local Player = require("src.player_controller")
local MapSystem = require("src.map_system")
local SkillTree = require("src.skill_tree_system")
local GameState = require("src.game_state")
local Meta = require("src.meta_system")
local MetaTreeLayout = require("src.meta_tree_layout")

local Renderer = {}
local ICON_LABELS = {
    spd = "SPD",
    rng = "RNG",
    nut = "NUT",
    xp = "XP",
    rar = "RAR",
    elt = "ELT",
    dmg = "DMG",
    mag = "MAG",
}

local function formatTime(seconds)
    local total = math.max(0, math.floor(seconds))
    local m = math.floor(total / 60)
    local s = total % 60
    return string.format("%02d:%02d", m, s)
end

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

local function drawWorld(state, assets)
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

    if assets and assets.playerSprite then
        local sprite = assets.playerSprite
        local iw = sprite:getWidth()
        local ih = sprite:getHeight()
        local targetSize = state.player.radius * 3
        local sx = targetSize / iw
        local sy = targetSize / ih
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(sprite, state.player.x, state.player.y, 0, sx, sy, iw * 0.5, ih * 0.5)
    else
        love.graphics.setColor(0.9, 0.45, 0.3)
        love.graphics.circle("fill", state.player.x, state.player.y, state.player.radius)
        love.graphics.setColor(1, 0.9, 0.75)
        love.graphics.circle("fill", state.player.x + 5, state.player.y - 4, 2)
    end

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
    love.graphics.rectangle("fill", 12, 12, 460, 216, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("Time Left: %s", formatTime(state.runTimeLeft)), 24, 24)
    love.graphics.print(string.format("Meta Essence: %d", state.meta.essence), 24, 48)
    love.graphics.print(string.format("Nutrition: %.0f", state.resources.nutrition), 24, 72)
    love.graphics.print(string.format("Growth: %.0f", state.resources.growth), 24, 96)
    love.graphics.print(string.format("Consumed: %d", state.food.consumedTotal), 24, 120)
    love.graphics.print(string.format("Runs: %d", state.meta.totalRuns), 24, 144)
    love.graphics.print(string.format("Map: %s (%d/%d)", mapData.name, unlockedMaps, #C.MAPS), 24, 168)
    love.graphics.print("[1-4] Map  [B] Boss  [F5/F9] Save/Load  [F10] Reset", 24, 192)

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
        love.graphics.rectangle("fill", 12, love.graphics.getHeight() - 70, 760, 30, 6, 6)
        love.graphics.setColor(1, 0.9, 0.7)
        love.graphics.print(state.message, 20, love.graphics.getHeight() - 62)
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
                    if SkillTree.isUnlocked(node) and SkillTree.isUnlocked(dep) then
                        love.graphics.setColor(0.35, 1.0, 0.55, 0.9)
                    else
                        love.graphics.setColor(0.25, 0.95, 1.0, 0.45)
                    end
                    love.graphics.setLineWidth(2)
                    love.graphics.line(dep.x, dep.y, node.x, node.y)
                end
            end
        end
    end

    for _, node in ipairs(tree.nodes) do
        local tooltip = SkillTree.getTooltipInfo(tree, node, state.resources.growth)
        local unlocked = SkillTree.isUnlocked(node)

        if unlocked then
            love.graphics.setColor(0.12, 0.12, 0.16)
        elseif tooltip.canBuy then
            love.graphics.setColor(0.08, 0.2, 0.14)
        else
            love.graphics.setColor(0.08, 0.08, 0.1)
        end

        local s = node.isAnchor and 24 or 18
        love.graphics.polygon(
            "fill",
            node.x, node.y - s,
            node.x + s, node.y,
            node.x, node.y + s,
            node.x - s, node.y
        )

        if unlocked then
            love.graphics.setColor(0.35, 1.0, 0.55)
        else
            love.graphics.setColor(0.25, 0.95, 1.0)
        end
        love.graphics.setLineWidth(node.isAnchor and 3 or 2)
        love.graphics.polygon(
            "line",
            node.x, node.y - s,
            node.x + s, node.y,
            node.x, node.y + s,
            node.x - s, node.y
        )

        love.graphics.setColor(0.92, 0.95, 1.0)
        local iconLabel = ICON_LABELS[node.iconId] or "SKL"
        love.graphics.printf(iconLabel, node.x - 16, node.y - 8, 32, "center")

        if node.isAnchor then
            love.graphics.setColor(0.85, 0.95, 0.45)
            love.graphics.printf(string.format("%d/%d", node.level, node.maxLevel), node.x - 24, node.y + s + 3, 48, "center")
        end
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
        local t = SkillTree.getTooltipInfo(tree, hovered, state.resources.growth)
        local status
        if t.canBuy then
            status = "BUY AVAILABLE"
        elseif t.reason == "max level" or t.reason == "already unlocked" then
            status = "MAXED"
        elseif t.reason == "dependency missing" then
            status = "NEED PREV NODE"
        else
            status = "NEED MORE GROWTH"
        end

        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 18, sh - 116, 520, 94, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(hovered.name, 30, sh - 106)
        love.graphics.print(string.format("Lv %d/%d", t.currentLevel, t.maxLevel), 30, sh - 84)
        love.graphics.print(string.format("%.2f -> %.2f %s", t.currentValue, t.nextValue, hovered.effect.stat), 30, sh - 62)
        love.graphics.print("Cost: " .. (t.cost and tostring(t.cost) or "MAX") .. " growth", 30, sh - 40)
        love.graphics.setColor(t.canBuy and 0.4 or 1.0, 1.0, t.canBuy and 0.45 or 0.6)
        love.graphics.print(status, 300, sh - 84)
    end
end

local function drawRunEndOverlay(state, fonts)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local upgrades = GameState.getMetaUpgradeRows(state)
    local treeLayout = Meta.getTreeLayout()
    local byIndex = {}
    local visibleIndices = {}
    for _, row in ipairs(upgrades) do
        byIndex[row.index] = row
        if row.visible then
            visibleIndices[row.index] = true
        end
    end
    local projected = MetaTreeLayout.build(sw, sh, treeLayout, visibleIndices)
    local ui = C.RUN_END_TREE_UI
    local panel = projected.panel
    local header = projected.headerRect
    local tooltipRect = projected.tooltipRect
    local footer = projected.footerRect

    love.graphics.setColor(0, 0, 0, 0.82)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    love.graphics.setColor(0.1, 0.1, 0.12, 0.95)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 12, 12)

    love.graphics.setFont(fonts.big)
    love.graphics.setColor(1, 0.95, 0.78)
    love.graphics.printf("RUN ENDED", header.x, header.y + 2, header.w, "center")

    love.graphics.setFont(fonts.hud)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        string.format(
            "Reason: %s | Reward: +%d essence | Current: %d essence",
            state.runEndedReason or "unknown",
            state.lastRunReward,
            state.meta.essence
        ),
        header.x,
        header.y + header.h * 0.62,
        header.w,
        "left"
    )

    for _, row in ipairs(upgrades) do
        if row.visible and row.deps and #row.deps > 0 then
            local p1 = projected.project(row.index)
            for _, dep in ipairs(row.deps) do
                if visibleIndices[dep] then
                    local p0 = projected.project(dep)
                    if p0 and p1 then
                        local depRow = byIndex[dep]
                        if depRow and depRow.level > 0 then
                            love.graphics.setColor(0.35, 1.0, 0.55, 0.9)
                        else
                            love.graphics.setColor(0.25, 0.95, 1.0, 0.45)
                        end
                        love.graphics.setLineWidth(3)
                        love.graphics.line(p0.x, p0.y, p1.x, p1.y)
                    end
                end
            end
        end
    end

    local mx, my = love.mouse.getPosition()
    local hoveredIndex = projected.hitTest(mx, my)
    local hovered = hoveredIndex and byIndex[hoveredIndex] or nil
    if hovered and hovered.reason == "BUY" then
        love.graphics.setColor(0.35, 1.0, 0.55, 0.1)
        local p = projected.project(hovered.index)
        if p then
            love.graphics.circle("fill", p.x, p.y, ui.nodeRadius + 8)
        end
    end

    for _, row in ipairs(upgrades) do
        if row.visible then
            local p = projected.project(row.index)
            if p then
                local s = ui.nodeRadius
                if row.maxed then
                    love.graphics.setColor(0.12, 0.2, 0.12, 0.95)
                elseif row.canBuy then
                    love.graphics.setColor(0.08, 0.2, 0.14, 0.95)
                elseif row.reason == "LOCKED" then
                    love.graphics.setColor(0.12, 0.12, 0.12, 0.95)
                else
                    love.graphics.setColor(0.1, 0.1, 0.12, 0.95)
                end

                love.graphics.polygon("fill", p.x, p.y - s, p.x + s, p.y, p.x, p.y + s, p.x - s, p.y)

                if row.maxed then
                    love.graphics.setColor(0.45, 1.0, 0.6)
                elseif row.canBuy then
                    love.graphics.setColor(0.35, 1.0, 0.55)
                else
                    love.graphics.setColor(0.25, 0.95, 1.0)
                end
                love.graphics.setLineWidth(3)
                love.graphics.polygon("line", p.x, p.y - s, p.x + s, p.y, p.x, p.y + s, p.x - s, p.y)

                love.graphics.setColor(0.95, 0.95, 0.95)
                local icon = row.icon or tostring(row.index)
                local iconWidth = fonts.hud:getWidth(icon)
                love.graphics.print(icon, p.x - iconWidth * 0.5, p.y - 10)
                love.graphics.setColor(0.9, 0.95, 0.55)
                love.graphics.printf(string.format("%d/%d", row.level, row.maxLevel), p.x - 24, p.y + s + 4, 48, "center")
            end
        end
    end

    if hovered then
        local costText = hovered.cost and tostring(hovered.cost) or "MAX"
        local status = hovered.reason
        local statusColor = { 1, 1, 1 }
        if status == "BUY" then
            statusColor = { 0.45, 1.0, 0.55 }
        elseif status == "LOCKED" then
            statusColor = { 1.0, 0.65, 0.65 }
        elseif status == "NEED ESSENCE" then
            statusColor = { 1.0, 0.85, 0.45 }
        elseif status == "MAX" then
            statusColor = { 0.65, 1.0, 0.75 }
        end

        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", tooltipRect.x, tooltipRect.y, tooltipRect.w, tooltipRect.h, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            string.format("[%d] %s  Lv.%d/%d", hovered.index, hovered.name, hovered.level, hovered.maxLevel),
            tooltipRect.x + 14,
            tooltipRect.y + 12,
            tooltipRect.w - 28,
            "left"
        )
        love.graphics.printf(hovered.desc, tooltipRect.x + 14, tooltipRect.y + 36, tooltipRect.w - 28, "left")
        love.graphics.setColor(statusColor)
        love.graphics.printf(
            string.format("Cost: %s | Status: %s", costText, status),
            tooltipRect.x + 14,
            tooltipRect.y + 60,
            tooltipRect.w - 28,
            "left"
        )
    else
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.rectangle("fill", tooltipRect.x, tooltipRect.y, tooltipRect.w, tooltipRect.h, 8, 8)
        love.graphics.setColor(0.85, 0.86, 0.9)
        love.graphics.printf("Hover a node to inspect details", tooltipRect.x, tooltipRect.y + tooltipRect.h * 0.35, tooltipRect.w, "center")
    end

    love.graphics.setColor(1, 0.95, 0.75)
    love.graphics.printf("Click node to buy, R to start new run", footer.x, footer.y, footer.w, "center")
    love.graphics.setColor(0.75, 0.85, 1.0)
    love.graphics.printf("New nodes appear after unlocking prerequisite nodes", footer.x, footer.y + 18, footer.w, "center")
end

function Renderer.draw(state, fonts, ui, assets, treeWorldFromScreen)
    drawWorld(state, assets)
    drawHUD(state, fonts, ui)

    if state.mode == "run_end" then
        drawRunEndOverlay(state, fonts)
    end
end

return Renderer
