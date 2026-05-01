local C = require("src.constants")
local BonusText = require("src.bonus_text")
local GameState = require("src.game_state")
local Meta = require("src.meta_system")
local Text = require("src.presentation.presentation_text")

local RunEndMetaTreeRenderer = {}
local t = Text.text
local ref = Text.ref

local STATUS_COLORS = {
    BUY = { 0.45, 1.0, 0.55 },
    LOCKED = { 1.0, 0.65, 0.65 },
    NEED_ESSENCE = { 1.0, 0.85, 0.45 },
    MAX = { 0.65, 1.0, 0.75 },
}

local function statusText(state, reason)
    return t(state, "status." .. reason)
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

function RunEndMetaTreeRenderer.draw(state, fonts, _, sw, sh)
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
                love.graphics.setColor(0.95, 0.88, 0.32, 0.12)
                love.graphics.circle("fill", sx, sy, size + 12)
            end
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

            if row.maxed then
                local inner = math.max(10, size - 8)
                love.graphics.setColor(0.96, 0.88, 0.34, 0.95)
                love.graphics.setLineWidth(2)
                love.graphics.polygon("line", sx, sy - inner, sx + inner, sy, sx, sy + inner, sx - inner, sy)
                love.graphics.setColor(1.0, 0.92, 0.42, 0.95)
                love.graphics.polygon(
                    "fill",
                    sx + size - 9, sy - 4,
                    sx + size - 3, sy - 10,
                    sx + size + 3, sy - 4,
                    sx + size - 3, sy + 2
                )
            end

            love.graphics.setColor(0.95, 0.95, 0.95)
            local icon = row.icon or tostring(row.index)
            if row.maxed then
                love.graphics.setColor(1.0, 0.95, 0.72)
            end
            local iconWidth = fonts.hud:getWidth(icon)
            love.graphics.print(icon, sx - iconWidth * 0.5, sy - 10)
            if row.maxed then
                love.graphics.setColor(1.0, 0.9, 0.45)
            else
                love.graphics.setColor(0.9, 0.95, 0.55)
            end
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
        local effectText = BonusText.describe(state.locale, hovered.bonusPack, {
            perLevel = hovered.maxLevel > 1,
        })
        if effectText == "" then
            effectText = t(state, hovered.descKey)
        end

        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipW, tooltipH, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            t(state, "run_end.tooltip.title", {
                index = hovered.index,
                name = ref(hovered.nameKey),
                level = hovered.level,
                max = hovered.maxLevel,
            }),
            tooltipX + 14,
            tooltipY + 12,
            tooltipW - 28,
            "left"
        )
        love.graphics.printf(effectText, tooltipX + 14, tooltipY + 36, tooltipW - 28, "left")
        love.graphics.setColor(STATUS_COLORS[hovered.reason] or { 1, 1, 1 })
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

return RunEndMetaTreeRenderer
