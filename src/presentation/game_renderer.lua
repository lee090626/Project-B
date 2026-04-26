local C = require("src.constants")
local Player = require("src.player_controller")
local MapSystem = require("src.map_system")
local SkillTree = require("src.skill_tree_system")
local GameState = require("src.game_state")
local Meta = require("src.meta_system")

local Renderer = {}
local ICON_LABELS = {
    spd = "SPD",
    rng = "RNG",
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

local function ellipsize(font, text, maxWidth)
    if font:getWidth(text) <= maxWidth then
        return text
    end
    local suffix = "..."
    local out = text
    while #out > 1 and font:getWidth(out .. suffix) > maxWidth do
        out = out:sub(1, #out - 1)
    end
    return out .. suffix
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

local function drawGameTopBar(state, fonts, ui)
    local sw = love.graphics.getWidth()
    local mapData = MapSystem.getCurrentMap(state.maps)
    local unlockedMaps = 0
    for _, map in ipairs(C.MAPS) do
        if state.maps.unlocked[map.id] then
            unlockedMaps = unlockedMaps + 1
        end
    end

    local cfg = C.RUN_HUD_UI
    local pad = cfg.padding
    local topY = pad
    local barH = cfg.topBarHeight

    love.graphics.setFont(fonts.hud)

    local mapText = string.format("Map %s (%d/%d)", mapData.name, unlockedMaps, #C.MAPS)
    mapText = ellipsize(fonts.hud, mapText, math.max(180, sw * 0.34))

    local leftText = string.format("Time %s   %s", formatTime(state.runTimeLeft), mapText)
    local rightText = string.format("Essence %d", state.meta.essence)

    local leftW = fonts.hud:getWidth(leftText) + cfg.chipPadX * 2
    local rightW = fonts.hud:getWidth(rightText) + cfg.chipPadX * 2
    local saveW = ui.saveBtn.w
    local helpText = "[H] Help"
    local helpW = fonts.hud:getWidth(helpText) + cfg.chipPadX * 2
    local rightGroupW = rightW + cfg.groupGap + saveW + cfg.groupGap + helpW

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", pad, topY, leftW, barH, 8, 8)
    love.graphics.rectangle("fill", sw - pad - rightGroupW, topY, rightGroupW, barH, 8, 8)

    love.graphics.setColor(0.86, 0.94, 1.0, 0.95)
    love.graphics.rectangle("line", pad, topY, leftW, barH, 8, 8)
    love.graphics.rectangle("line", sw - pad - rightGroupW, topY, rightGroupW, barH, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(leftText, pad + cfg.chipPadX, topY + 12)
    local rightStart = sw - pad - rightGroupW
    love.graphics.print(rightText, rightStart + cfg.chipPadX, topY + 12)

    ui.saveBtn.x = rightStart + rightW + cfg.groupGap
    ui.saveBtn.y = topY + 5
    ui.saveBtn.h = barH - 10
    ui.saveBtn.w = saveW
    love.graphics.setColor(0.05, 0.08, 0.1, 0.95)
    love.graphics.rectangle("fill", ui.saveBtn.x, ui.saveBtn.y, ui.saveBtn.w, ui.saveBtn.h, 6, 6)
    love.graphics.setColor(0.75, 0.92, 0.85, 0.95)
    love.graphics.rectangle("line", ui.saveBtn.x, ui.saveBtn.y, ui.saveBtn.w, ui.saveBtn.h, 6, 6)
    local saveText = "Manual Save"
    local saveTextX = ui.saveBtn.x + (ui.saveBtn.w - fonts.hud:getWidth(saveText)) * 0.5
    love.graphics.print(saveText, saveTextX, ui.saveBtn.y + 8)

    local helpX = ui.saveBtn.x + ui.saveBtn.w + cfg.groupGap
    love.graphics.setColor(0.78, 0.85, 1.0)
    love.graphics.print(helpText, helpX + cfg.chipPadX, topY + 12)
end

local function drawBossBar(state, fonts)
    if not state.boss.active then
        return
    end
    local sw = love.graphics.getWidth()
    local cfg = C.RUN_HUD_UI
    local y = cfg.padding + cfg.topBarHeight + 8
    local pct = state.boss.maxHp > 0 and (state.boss.hp / state.boss.maxHp) or 0
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", sw * 0.22, y, sw * 0.56, 20)
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.rectangle("fill", sw * 0.22 + 2, y + 2, (sw * 0.56 - 4) * pct, 16)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.hud)
    love.graphics.printf("Final Boss", sw * 0.22, y + 2, sw * 0.56, "center")
end

local function drawGameToasts(state, fonts)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local cfg = C.RUN_HUD_UI

    if state.uiAutosaveTimer > 0 then
        local a = math.min(1, state.uiAutosaveTimer / cfg.autosaveDuration)
        love.graphics.setColor(0, 0, 0, 0.42 * a)
        love.graphics.rectangle("fill", sw * 0.34, sh - 36, sw * 0.32, 22, 6, 6)
        love.graphics.setColor(0.85, 0.9, 0.98, a)
        love.graphics.setFont(fonts.hud)
        love.graphics.printf(state.lastSaveStatus, sw * 0.35, sh - 31, sw * 0.3, "center")
    end

    if state.message and state.uiToastTimer > 0 then
        local a = math.min(1, state.uiToastTimer / cfg.toastDuration)
        local w = math.min(sw - 24, 780)
        local x = (sw - w) * 0.5
        local y = sh - 74
        love.graphics.setColor(0, 0, 0, 0.65 * a)
        love.graphics.rectangle("fill", x, y, w, 36, 8, 8)
        love.graphics.setColor(1, 0.92, 0.78, a)
        love.graphics.setFont(fonts.hud)
        love.graphics.printf(state.message, x + 10, y + 10, w - 20, "center")
    end
end

local function drawHelpPanel(state, fonts)
    if not state.showHelp then
        return
    end

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local w = math.min(760, sw - 60)
    local h = 220
    local x = (sw - w) * 0.5
    local y = (sh - h) * 0.5

    love.graphics.setColor(0, 0, 0, 0.86)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)
    love.graphics.setColor(0.85, 0.92, 1.0)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)

    love.graphics.setFont(fonts.big)
    love.graphics.setColor(1, 0.95, 0.8)
    love.graphics.printf("HELP", x, y + 14, w, "center")

    love.graphics.setFont(fonts.hud)
    love.graphics.setColor(1, 1, 1)
    if state.mode == "run_end_tree" then
        love.graphics.printf(
            string.format("Reason: %s | Reward: +%d essence | Current: %d essence", state.runEndedReason or "unknown", state.lastRunReward, state.meta.essence),
            x + 24,
            y + 62,
            w - 48,
            "left"
        )
        love.graphics.printf("[Drag] Pan view", x + 24, y + 86, w - 48, "left")
        love.graphics.printf("[Wheel] Zoom in/out", x + 24, y + 110, w - 48, "left")
        love.graphics.printf("[Click] Buy upgrade  |  [R] Start new run", x + 24, y + 134, w - 48, "left")
        love.graphics.printf("New nodes appear after unlocking prerequisite nodes", x + 24, y + 158, w - 48, "left")
        love.graphics.printf("[H] Close help", x + 24, y + 182, w - 48, "left")
    else
        love.graphics.printf("Goal: keep eating, grow fast, and challenge the boss before time runs out.", x + 24, y + 62, w - 48, "left")
        love.graphics.printf("[1-4] Switch map", x + 24, y + 92, w - 48, "left")
        love.graphics.printf("[B] Enter boss", x + 24, y + 116, w - 48, "left")
        love.graphics.printf("[F5/F9] Save / Load  |  [F10] Reset all data", x + 24, y + 140, w - 48, "left")
        love.graphics.printf("[H] Close help", x + 24, y + 164, w - 48, "left")
    end
end

local function drawSkillTreeOverlay(state, fonts, treeWorldFromScreen)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local tree = state.skillTree
    local essence = state.meta and state.meta.essence or 0

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
        local tooltip = SkillTree.getTooltipInfo(tree, node, essence)
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
    love.graphics.print(string.format("Essence: %d | Unlocked: %d/%d", essence, tree.unlockedCount, #tree.nodes), 18, 40)

    local mx, my = love.mouse.getPosition()
    local treeX, treeY = treeWorldFromScreen(mx, my)
    local hovered = SkillTree.nodeAtWorldPosition(tree, treeX, treeY)

    if hovered then
        local t = SkillTree.getTooltipInfo(tree, hovered, essence)
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
        love.graphics.print("Cost: " .. (t.cost and tostring(t.cost) or "MAX") .. " essence", 30, sh - 40)
        love.graphics.setColor(t.canBuy and 0.4 or 1.0, 1.0, t.canBuy and 0.45 or 0.6)
        love.graphics.print(status, 300, sh - 84)
    end
end

local function metaTreeWorldToScreen(state, wx, wy, sw, sh)
    local view = state.metaTreeView
    local scale = C.RUN_END_TREE_UI.worldScale
    local sx = (wx - view.cameraX) * view.zoom * scale + sw * 0.5
    local sy = (wy - view.cameraY) * view.zoom * scale + sh * 0.5
    return sx, sy
end

local function drawRunEndTreeFullscreen(state, fonts)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local upgrades = GameState.getMetaUpgradeRows(state)
    local treeLayout = Meta.getTreeLayout()
    local byIndex = {}
    local visibleRows = {}
    for _, row in ipairs(upgrades) do
        byIndex[row.index] = row
        if row.visible then
            visibleRows[#visibleRows + 1] = row
        end
    end
    local ui = C.RUN_END_TREE_UI

    love.graphics.setColor(0, 0, 0, 0.82)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    love.graphics.setFont(fonts.big)
    love.graphics.setColor(1, 0.95, 0.78)
    love.graphics.printf("RUN ENDED", 0, 24, sw, "center")
    love.graphics.setFont(fonts.hud)

    local mx, my = love.mouse.getPosition()
    local hoveredIndex
    local hoveredDistSq = math.huge
    local hitRadiusPx = ui.nodeRadius + 2
    for _, row in ipairs(visibleRows) do
        local p = treeLayout[row.index]
        if p then
            local sx, sy = metaTreeWorldToScreen(state, p.x, p.y, sw, sh)
            local dx = mx - sx
            local dy = my - sy
            local distSq = dx * dx + dy * dy
            if distSq <= hitRadiusPx * hitRadiusPx and distSq < hoveredDistSq then
                hoveredDistSq = distSq
                hoveredIndex = row.index
            end
        end
    end
    local hovered = hoveredIndex and byIndex[hoveredIndex] or nil

    for _, row in ipairs(visibleRows) do
        if row.deps and #row.deps > 0 then
            local p1 = treeLayout[row.index]
            for _, dep in ipairs(row.deps) do
                local depRow = byIndex[dep]
                if depRow and depRow.visible then
                    local p0 = treeLayout[dep]
                    if p0 and p1 then
                        local sx0, sy0 = metaTreeWorldToScreen(state, p0.x, p0.y, sw, sh)
                        local sx1, sy1 = metaTreeWorldToScreen(state, p1.x, p1.y, sw, sh)
                        if depRow.level > 0 then
                            love.graphics.setColor(0.35, 1.0, 0.55, 0.9)
                        else
                            love.graphics.setColor(0.25, 0.95, 1.0, 0.45)
                        end
                        love.graphics.setLineWidth(3)
                        love.graphics.line(sx0, sy0, sx1, sy1)
                    end
                end
            end
        end
    end

    if hovered and hovered.reason == "BUY" then
        local p = treeLayout[hovered.index]
        local hsx, hsy = metaTreeWorldToScreen(state, p.x, p.y, sw, sh)
        love.graphics.setColor(0.35, 1.0, 0.55, 0.1)
        love.graphics.circle("fill", hsx, hsy, ui.nodeRadius + 8)
    end

    for _, row in ipairs(visibleRows) do
        local p = treeLayout[row.index]
        if p then
            local sx, sy = metaTreeWorldToScreen(state, p.x, p.y, sw, sh)
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

            love.graphics.polygon("fill", sx, sy - s, sx + s, sy, sx, sy + s, sx - s, sy)

            if row.maxed then
                love.graphics.setColor(0.45, 1.0, 0.6)
            elseif row.canBuy then
                love.graphics.setColor(0.35, 1.0, 0.55)
            else
                love.graphics.setColor(0.25, 0.95, 1.0)
            end
            love.graphics.setLineWidth(3)
            love.graphics.polygon("line", sx, sy - s, sx + s, sy, sx, sy + s, sx - s, sy)

            love.graphics.setColor(0.95, 0.95, 0.95)
            local icon = row.icon or tostring(row.index)
            local iconWidth = fonts.hud:getWidth(icon)
            love.graphics.print(icon, sx - iconWidth * 0.5, sy - 10)
            love.graphics.setColor(0.9, 0.95, 0.55)
            love.graphics.printf(string.format("%d/%d", row.level, row.maxLevel), sx - 24, sy + s + 4, 48, "center")
        end
    end

    local tooltipW = math.min(sw - 24, 880)
    local tooltipH = 108
    local tooltipX = (sw - tooltipW) * 0.5
    local tooltipY = sh - tooltipH - 58

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
        love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipW, tooltipH, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            string.format("[%d] %s  Lv.%d/%d", hovered.index, hovered.name, hovered.level, hovered.maxLevel),
            tooltipX + 14,
            tooltipY + 12,
            tooltipW - 28,
            "left"
        )
        love.graphics.printf(hovered.desc, tooltipX + 14, tooltipY + 36, tooltipW - 28, "left")
        love.graphics.setColor(statusColor)
        love.graphics.printf(
            string.format("Cost: %s | Status: %s", costText, status),
            tooltipX + 14,
            tooltipY + 62,
            tooltipW - 28,
            "left"
        )
    else
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipW, tooltipH, 8, 8)
        love.graphics.setColor(0.85, 0.86, 0.9)
        love.graphics.printf("Hover a node to inspect details", tooltipX, tooltipY + tooltipH * 0.35, tooltipW, "center")
    end

end

local function drawRunEndResultOverlay(state, fonts)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local w = math.min(760, sw - 80)
    local h = 270
    local x = (sw - w) * 0.5
    local y = (sh - h) * 0.5

    love.graphics.setColor(0, 0, 0, 0.74)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    love.graphics.setColor(0.06, 0.07, 0.1, 0.96)
    love.graphics.rectangle("fill", x, y, w, h, 12, 12)
    love.graphics.setColor(0.8, 0.9, 1.0, 0.9)
    love.graphics.rectangle("line", x, y, w, h, 12, 12)

    love.graphics.setFont(fonts.big)
    love.graphics.setColor(1, 0.95, 0.8)
    love.graphics.printf("RUN ENDED", x, y + 24, w, "center")

    love.graphics.setFont(fonts.hud)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Reason: " .. tostring(state.runEndedReason or "unknown"), x + 36, y + 94, w - 72, "left")
    love.graphics.printf("Total Eaten: " .. tostring(state.food and state.food.consumedTotal or 0), x + 36, y + 124, w - 72, "left")
    love.graphics.printf("Current Essence: " .. tostring(state.meta and state.meta.essence or 0), x + 36, y + 154, w - 72, "left")

    love.graphics.setColor(0.84, 0.9, 1.0)
    love.graphics.printf("Click to continue to skill tree", x, y + h - 42, w, "center")
end

function Renderer.draw(state, fonts, ui, assets, treeWorldFromScreen)
    if state.mode == "run_end_result" then
        drawWorld(state, assets)
        drawRunEndResultOverlay(state, fonts)
        drawHelpPanel(state, fonts)
        return
    end

    if state.mode == "run_end_tree" then
        drawRunEndTreeFullscreen(state, fonts)
        drawHelpPanel(state, fonts)
        return
    end

    drawWorld(state, assets)
    drawGameTopBar(state, fonts, ui)
    drawBossBar(state, fonts)
    drawGameToasts(state, fonts)
    drawHelpPanel(state, fonts)
end

return Renderer
