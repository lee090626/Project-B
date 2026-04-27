local C = require("src.constants")
local Locale = require("src.locale")
local MapSystem = require("src.map_system")
local GameState = require("src.game_state")
local Meta = require("src.meta_system")

local OverlayRenderer = {}

local function t(state, key, params)
    return Locale.text(state.locale, key, params)
end

local function runReasonRef(reason)
    return Locale.ref("run_reason." .. tostring(reason or "unknown"))
end

local function statusText(state, reason)
    return t(state, "status." .. reason)
end

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

function OverlayRenderer.drawGameTopBar(state, fonts, ui)
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

    local mapText = t(state, "hud.map", {
        map = Locale.ref(mapData.nameKey),
        unlocked = unlockedMaps,
        total = #C.MAPS,
    })
    mapText = ellipsize(fonts.hud, mapText, math.max(180, sw * 0.34))

    local leftText = t(state, "hud.time_map", {
        time = formatTime(state.runTimeLeft),
        map = mapText,
    })
    local rightText = t(state, "hud.essence", {
        essence = state.meta.essence,
        level = state.nestProgress and state.nestProgress.level or 0,
    })

    local leftW = fonts.hud:getWidth(leftText) + cfg.chipPadX * 2
    local rightW = fonts.hud:getWidth(rightText) + cfg.chipPadX * 2
    local saveW = ui.saveBtn.w
    local helpText = t(state, "hud.help")
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
    local saveText = t(state, "hud.manual_save")
    local saveTextX = ui.saveBtn.x + (ui.saveBtn.w - fonts.hud:getWidth(saveText)) * 0.5
    love.graphics.print(saveText, saveTextX, ui.saveBtn.y + 8)

    local helpX = ui.saveBtn.x + ui.saveBtn.w + cfg.groupGap
    love.graphics.setColor(0.78, 0.85, 1.0)
    love.graphics.print(helpText, helpX + cfg.chipPadX, topY + 12)
end

function OverlayRenderer.drawBossBar(state, fonts)
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
    love.graphics.printf(t(state, "boss.title"), sw * 0.22, y + 2, sw * 0.56, "center")
end

function OverlayRenderer.drawGameToasts(state, fonts)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local cfg = C.RUN_HUD_UI

    if state.uiAutosaveTimer > 0 and state.lastSaveStatusKey then
        local a = math.min(1, state.uiAutosaveTimer / cfg.autosaveDuration)
        love.graphics.setColor(0, 0, 0, 0.42 * a)
        love.graphics.rectangle("fill", sw * 0.34, sh - 36, sw * 0.32, 22, 6, 6)
        love.graphics.setColor(0.85, 0.9, 0.98, a)
        love.graphics.setFont(fonts.hud)
        love.graphics.printf(
            t(state, state.lastSaveStatusKey, state.lastSaveStatusParams),
            sw * 0.35,
            sh - 31,
            sw * 0.3,
            "center"
        )
    end

    if state.messageKey and state.uiToastTimer > 0 then
        local a = math.min(1, state.uiToastTimer / cfg.toastDuration)
        local w = math.min(sw - 24, 780)
        local x = (sw - w) * 0.5
        local y = sh - 74
        love.graphics.setColor(0, 0, 0, 0.65 * a)
        love.graphics.rectangle("fill", x, y, w, 36, 8, 8)
        love.graphics.setColor(1, 0.92, 0.78, a)
        love.graphics.setFont(fonts.hud)
        love.graphics.printf(t(state, state.messageKey, state.messageParams), x + 10, y + 10, w - 20, "center")
    end
end

function OverlayRenderer.drawHelpPanel(state, fonts)
    if not state.showHelp then
        return
    end

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local w = math.min(760, sw - 60)
    local h = 252
    local x = (sw - w) * 0.5
    local y = (sh - h) * 0.5

    love.graphics.setColor(0, 0, 0, 0.86)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)
    love.graphics.setColor(0.85, 0.92, 1.0)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)

    love.graphics.setFont(fonts.big)
    love.graphics.setColor(1, 0.95, 0.8)
    love.graphics.printf(t(state, "help.title"), x, y + 14, w, "center")

    love.graphics.setFont(fonts.hud)
    love.graphics.setColor(1, 1, 1)
    if state.mode == "run_end_tree" then
        love.graphics.printf(
            t(state, "help.run_end.summary", {
                reason = runReasonRef(state.runEndedReason),
                essence = state.meta.essence,
                level = state.nestProgress.level,
                points = state.nestProgress.availablePoints,
            }),
            x + 24,
            y + 62,
            w - 48,
            "left"
        )
        love.graphics.printf(t(state, "help.run_end.drag"), x + 24, y + 86, w - 48, "left")
        love.graphics.printf(t(state, "help.run_end.wheel"), x + 24, y + 110, w - 48, "left")
        love.graphics.printf(t(state, "help.run_end.tab"), x + 24, y + 134, w - 48, "left")
        love.graphics.printf(t(state, "help.run_end.buy"), x + 24, y + 158, w - 48, "left")
    elseif state.mode == "run_choice" then
        love.graphics.printf(t(state, "help.run_choice.line1"), x + 24, y + 62, w - 48, "left")
        love.graphics.printf(t(state, "help.run_choice.line2"), x + 24, y + 92, w - 48, "left")
        love.graphics.printf(t(state, "help.run_choice.line3"), x + 24, y + 122, w - 48, "left")
        love.graphics.printf(t(state, "help.run_choice.line4"), x + 24, y + 152, w - 48, "left")
    else
        love.graphics.printf(t(state, "help.game.goal"), x + 24, y + 62, w - 48, "left")
        love.graphics.printf(t(state, "help.game.map"), x + 24, y + 92, w - 48, "left")
        love.graphics.printf(t(state, "help.game.boss"), x + 24, y + 116, w - 48, "left")
        love.graphics.printf(t(state, "help.game.save"), x + 24, y + 140, w - 48, "left")
    end

    love.graphics.setColor(0.8, 0.9, 1.0)
    love.graphics.printf(
        t(state, "help.language", { language = Locale.ref("language." .. state.locale) }),
        x + 24,
        y + h - 68,
        w - 48,
        "left"
    )
    love.graphics.printf(t(state, "help.toggle_language"), x + 24, y + h - 44, w - 48, "left")
    love.graphics.printf(t(state, "help.close"), x + 24, y + h - 20, w - 48, "left")
end

local function metaTreeWorldToScreen(state, wx, wy, sw, sh)
    local view = state.metaTreeView
    local scale = C.RUN_END_TREE_UI.worldScale
    local sx = (wx - view.cameraX) * view.zoom * scale + sw * 0.5
    local sy = (wy - view.cameraY) * view.zoom * scale + sh * 0.5
    return sx, sy
end

local function drawOrthogonalConnector(fromX, fromY, toX, toY, radius)
    local dx = toX - fromX
    local dy = toY - fromY

    if math.abs(dx) < 1e-4 then
        local startY = fromY + (dy >= 0 and radius or -radius)
        local endY = toY - (dy >= 0 and radius or -radius)
        love.graphics.line(fromX, startY, toX, endY)
        return
    end

    if math.abs(dy) < 1e-4 then
        local startX = fromX + (dx >= 0 and radius or -radius)
        local endX = toX - (dx >= 0 and radius or -radius)
        love.graphics.line(startX, fromY, endX, toY)
        return
    end

    if math.abs(dx) >= math.abs(dy) then
        local startX = fromX + (dx >= 0 and radius or -radius)
        local startY = fromY
        local endX = toX
        local endY = toY - (dy >= 0 and radius or -radius)
        love.graphics.line(startX, startY, endX, startY)
        love.graphics.line(endX, startY, endX, endY)
        return
    end

    local startX = fromX
    local startY = fromY + (dy >= 0 and radius or -radius)
    local endX = toX - (dx >= 0 and radius or -radius)
    local endY = toY
    love.graphics.line(startX, startY, startX, endY)
    love.graphics.line(startX, endY, endX, endY)
end

local function drawRunEndTabs(state, fonts, ui, sw)
    local tabW = C.RUN_END_TREE_UI.tabWidth
    local tabH = C.RUN_END_TREE_UI.tabHeight
    local gap = C.RUN_END_TREE_UI.tabGap
    local startX = (sw - (tabW * 2 + gap)) * 0.5
    local y = 78

    ui.runEnd.tabs.meta = { x = startX, y = y, w = tabW, h = tabH }
    ui.runEnd.tabs.nest = { x = startX + tabW + gap, y = y, w = tabW, h = tabH }

    for _, tab in ipairs({
        { key = "meta", labelKey = "tab.meta", rect = ui.runEnd.tabs.meta },
        { key = "nest", labelKey = "tab.nest", rect = ui.runEnd.tabs.nest },
    }) do
        local active = state.runEndTab == tab.key
        love.graphics.setColor(active and 0.08 or 0.04, active and 0.22 or 0.08, active and 0.16 or 0.1, 0.96)
        love.graphics.rectangle("fill", tab.rect.x, tab.rect.y, tab.rect.w, tab.rect.h, 8, 8)
        love.graphics.setColor(active and 0.4 or 0.25, 1.0, active and 0.55 or 0.95, 0.95)
        love.graphics.rectangle("line", tab.rect.x, tab.rect.y, tab.rect.w, tab.rect.h, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(t(state, tab.labelKey), tab.rect.x, tab.rect.y + 9, tab.rect.w, "center")
    end
end

local function drawNestTab(state, fonts, ui, sw, sh)
    local rows = GameState.getNestUpgradeRows(state)
    local progress = state.nestProgress
    local panelW = math.min(sw - 80, 860)
    local panelH = math.min(sh - 180, 470)
    local panelX = (sw - panelW) * 0.5
    local panelY = 132
    local rowH = 76

    ui.runEnd.nestButtons = {}

    love.graphics.setColor(0, 0, 0, 0.76)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 12, 12)
    love.graphics.setColor(0.82, 0.92, 1.0)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 12, 12)

    love.graphics.setColor(1, 0.95, 0.78)
    love.graphics.printf(t(state, "nest.summary", {
        level = progress.level,
        points = progress.availablePoints,
        evolution = Locale.ref(progress.evolutionKey),
    }), panelX, panelY + 18, panelW, "center")
    love.graphics.setColor(0.82, 0.9, 0.98)
    love.graphics.printf(t(state, "nest.progress", {
        essence = progress.totalEssence,
        next = progress.nextLevelEssence,
    }), panelX, panelY + 42, panelW, "center")

    for i, row in ipairs(rows) do
        local x = panelX + 18
        local y = panelY + 84 + (i - 1) * (rowH + 10)
        local w = panelW - 36
        ui.runEnd.nestButtons[i] = { key = row.key, x = x, y = y, w = w, h = rowH }

        local activeColor = row.canBuy and { 0.08, 0.18, 0.12, 0.96 } or { 0.1, 0.1, 0.12, 0.96 }
        if row.maxed then
            activeColor = { 0.08, 0.16, 0.1, 0.96 }
        end

        love.graphics.setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
        love.graphics.rectangle("fill", x, y, w, rowH, 8, 8)
        love.graphics.setColor(row.canBuy and 0.35 or 0.25, 1.0, row.canBuy and 0.55 or 0.95, 0.9)
        love.graphics.rectangle("line", x, y, w, rowH, 8, 8)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            t(state, "nest.level", {
                name = Locale.ref(row.nameKey),
                level = row.level,
                max = row.maxLevel,
            }),
            x + 14,
            y + 10,
            w - 160,
            "left"
        )
        love.graphics.setColor(0.86, 0.92, 0.98)
        love.graphics.printf(t(state, row.effectKey, row.effectParams), x + 14, y + 34, w - 180, "left")

        local costText = row.maxed and t(state, "status.MAX") or t(state, "nest.cost", { cost = row.cost })
        love.graphics.setColor(row.canBuy and 0.9 or 0.78, 0.95, row.maxed and 0.68 or 0.55)
        love.graphics.printf(costText, x + w - 136, y + 12, 120, "right")
        love.graphics.setColor(0.72, 0.8, 0.9)
        love.graphics.printf(t(state, row.nextEffectKey, row.nextEffectParams), x + w - 220, y + 38, 204, "right")
    end

    love.graphics.setColor(0.78, 0.85, 0.92)
    love.graphics.printf(t(state, "nest.footer"), panelX, panelY + panelH - 30, panelW, "center")
end

function OverlayRenderer.drawRunEndTreeFullscreen(state, fonts, ui)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    love.graphics.setColor(0, 0, 0, 0.82)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    love.graphics.setFont(fonts.big)
    love.graphics.setColor(1, 0.95, 0.78)
    love.graphics.printf(t(state, "run_end.title"), 0, 24, sw, "center")
    love.graphics.setFont(fonts.hud)
    drawRunEndTabs(state, fonts, ui, sw)

    if state.runEndTab == "nest" then
        drawNestTab(state, fonts, ui, sw, sh)
        return
    end

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
    local treeUi = C.RUN_END_TREE_UI

    local mx, my = love.mouse.getPosition()
    local hoveredIndex
    local hoveredDistSq = math.huge
    local hitRadiusPx = treeUi.nodeRadius + 2
    for _, row in ipairs(visibleRows) do
        local point = treeLayout[row.index]
        if point then
            local sx, sy = metaTreeWorldToScreen(state, point.x, point.y, sw, sh)
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
            local point1 = treeLayout[row.index]
            for _, dep in ipairs(row.deps) do
                local depRow = byIndex[dep]
                if depRow and depRow.visible then
                    local point0 = treeLayout[dep]
                    if point0 and point1 then
                        local sx0, sy0 = metaTreeWorldToScreen(state, point0.x, point0.y, sw, sh)
                        local sx1, sy1 = metaTreeWorldToScreen(state, point1.x, point1.y, sw, sh)
                        if depRow.level > 0 then
                            love.graphics.setColor(0.35, 1.0, 0.55, 0.9)
                        else
                            love.graphics.setColor(0.25, 0.95, 1.0, 0.45)
                        end
                        love.graphics.setLineWidth(3)
                        drawOrthogonalConnector(sx0, sy0, sx1, sy1, treeUi.nodeRadius)
                    end
                end
            end
        end
    end

    if hovered and hovered.reason == "BUY" then
        local point = treeLayout[hovered.index]
        local hsx, hsy = metaTreeWorldToScreen(state, point.x, point.y, sw, sh)
        love.graphics.setColor(0.35, 1.0, 0.55, 0.1)
        love.graphics.circle("fill", hsx, hsy, treeUi.nodeRadius + 8)
    end

    for _, row in ipairs(visibleRows) do
        local point = treeLayout[row.index]
        if point then
            local sx, sy = metaTreeWorldToScreen(state, point.x, point.y, sw, sh)
            local size = treeUi.nodeRadius
            if row.maxed then
                love.graphics.setColor(0.12, 0.2, 0.12, 0.95)
            elseif row.canBuy then
                love.graphics.setColor(0.08, 0.2, 0.14, 0.95)
            elseif row.reason == "LOCKED" then
                love.graphics.setColor(0.12, 0.12, 0.12, 0.95)
            else
                love.graphics.setColor(0.1, 0.1, 0.12, 0.95)
            end

            love.graphics.polygon("fill", sx, sy - size, sx + size, sy, sx, sy + size, sx - size, sy)

            if row.maxed then
                love.graphics.setColor(0.45, 1.0, 0.6)
            elseif row.canBuy then
                love.graphics.setColor(0.35, 1.0, 0.55)
            else
                love.graphics.setColor(0.25, 0.95, 1.0)
            end
            love.graphics.setLineWidth(3)
            love.graphics.polygon("line", sx, sy - size, sx + size, sy, sx, sy + size, sx - size, sy)

            love.graphics.setColor(0.95, 0.95, 0.95)
            local icon = row.icon or tostring(row.index)
            local iconWidth = fonts.hud:getWidth(icon)
            love.graphics.print(icon, sx - iconWidth * 0.5, sy - 10)
            love.graphics.setColor(0.9, 0.95, 0.55)
            love.graphics.printf(string.format("%d/%d", row.level, row.maxLevel), sx - 24, sy + size + 4, 48, "center")
        end
    end

    local tooltipW = math.min(sw - 24, 880)
    local tooltipH = 108
    local tooltipX = (sw - tooltipW) * 0.5
    local tooltipY = sh - tooltipH - 58

    if hovered then
        local costText = hovered.cost and tostring(hovered.cost) or t(state, "status.MAX")
        local status = statusText(state, hovered.reason)
        local statusColor = { 1, 1, 1 }
        if hovered.reason == "BUY" then
            statusColor = { 0.45, 1.0, 0.55 }
        elseif hovered.reason == "LOCKED" then
            statusColor = { 1.0, 0.65, 0.65 }
        elseif hovered.reason == "NEED_ESSENCE" then
            statusColor = { 1.0, 0.85, 0.45 }
        elseif hovered.reason == "MAX" then
            statusColor = { 0.65, 1.0, 0.75 }
        end

        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipW, tooltipH, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            t(state, "run_end.tooltip.title", {
                index = hovered.index,
                name = Locale.ref(hovered.nameKey),
                level = hovered.level,
                max = hovered.maxLevel,
            }),
            tooltipX + 14,
            tooltipY + 12,
            tooltipW - 28,
            "left"
        )
        love.graphics.printf(t(state, hovered.descKey), tooltipX + 14, tooltipY + 36, tooltipW - 28, "left")
        love.graphics.setColor(statusColor)
        love.graphics.printf(
            t(state, "run_end.tooltip.cost_status", {
                cost = costText,
                status = status,
            }),
            tooltipX + 14,
            tooltipY + 62,
            tooltipW - 28,
            "left"
        )
    else
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipW, tooltipH, 8, 8)
        love.graphics.setColor(0.85, 0.86, 0.9)
        love.graphics.printf(t(state, "run_end.hover"), tooltipX, tooltipY + tooltipH * 0.35, tooltipW, "center")
    end
end

function OverlayRenderer.drawRunEndResultOverlay(state, fonts)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local w = math.min(760, sw - 80)
    local h = 350
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
    love.graphics.printf(t(state, "run_end.title"), x, y + 24, w, "center")

    love.graphics.setFont(fonts.hud)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(t(state, "run_end.result.reason", { reason = runReasonRef(state.runEndedReason) }), x + 36, y + 94, w - 72, "left")
    love.graphics.printf(t(state, "run_end.result.total_eaten", { total = state.food and state.food.consumedTotal or 0 }), x + 36, y + 124, w - 72, "left")
    love.graphics.printf(t(state, "run_end.result.current_essence", { essence = state.meta and state.meta.essence or 0 }), x + 36, y + 154, w - 72, "left")
    love.graphics.printf(t(state, "run_end.result.level", { level = state.nestProgress.level }), x + 36, y + 184, w - 72, "left")
    love.graphics.printf(t(state, "run_end.result.points", { points = state.nestProgress.availablePoints }), x + 36, y + 214, w - 72, "left")
    love.graphics.printf(t(state, "run_end.result.evolution", { evolution = Locale.ref(state.nestProgress.evolutionKey) }), x + 36, y + 244, w - 72, "left")

    love.graphics.setColor(0.84, 0.9, 1.0)
    love.graphics.printf(t(state, "run_end.result.continue"), x, y + h - 42, w, "center")
end

function OverlayRenderer.drawRunChoiceOverlay(state, fonts, ui)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local cards = state.runMutations.activeChoices or {}
    local cfg = C.RUN_CHOICE_UI
    local count = #cards
    local totalW = count * cfg.cardWidth + math.max(0, count - 1) * cfg.cardGap
    local startX = (sw - totalW) * 0.5
    local y = (sh - cfg.cardHeight) * 0.5 + 30

    ui.runChoice.cards = {}

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, sw, sh)
    love.graphics.setFont(fonts.big)
    love.graphics.setColor(1, 0.95, 0.78)
    love.graphics.printf(t(state, "run_choice.title"), 0, y - 92, sw, "center")
    love.graphics.setFont(fonts.hud)
    love.graphics.setColor(0.84, 0.9, 1.0)
    love.graphics.printf(
        t(state, "run_choice.summary", {
            essence = state.runEssenceTotal or 0,
            pending = state.runMutations.pendingChoices + 1,
        }),
        0,
        y - 48,
        sw,
        "center"
    )

    for i, card in ipairs(cards) do
        local x = startX + (i - 1) * (cfg.cardWidth + cfg.cardGap)
        ui.runChoice.cards[i] = { x = x, y = y, w = cfg.cardWidth, h = cfg.cardHeight }

        local fill = { 0.08, 0.1, 0.12, 0.95 }
        local line = { 0.45, 0.8, 1.0, 0.95 }
        if card.rarity == "rare" then
            line = { 0.6, 0.95, 0.55, 0.95 }
        elseif card.rarity == "mythic" then
            line = { 1.0, 0.82, 0.45, 0.95 }
        end

        love.graphics.setColor(fill[1], fill[2], fill[3], fill[4])
        love.graphics.rectangle("fill", x, y, cfg.cardWidth, cfg.cardHeight, 12, 12)
        love.graphics.setColor(line[1], line[2], line[3], line[4])
        love.graphics.rectangle("line", x, y, cfg.cardWidth, cfg.cardHeight, 12, 12)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(t(state, card.nameKey), x + 14, y + 18, cfg.cardWidth - 28, "center")
        love.graphics.setColor(0.82, 0.9, 1.0)
        love.graphics.printf(t(state, "category." .. card.category), x + 14, y + 56, cfg.cardWidth - 28, "center")
        love.graphics.setColor(line[1], line[2], line[3], line[4])
        love.graphics.printf(t(state, "rarity." .. card.rarity), x + 14, y + 84, cfg.cardWidth - 28, "center")
        love.graphics.setColor(0.95, 0.95, 0.95)
        love.graphics.printf(t(state, card.descKey), x + 18, y + 124, cfg.cardWidth - 36, "center")
        love.graphics.setColor(0.84, 0.9, 1.0)
        love.graphics.printf(t(state, "run_choice.click"), x + 14, y + cfg.cardHeight - 34, cfg.cardWidth - 28, "center")
    end
end

return OverlayRenderer
