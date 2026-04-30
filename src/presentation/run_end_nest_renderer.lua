local GameState = require("src.game_state")
local Text = require("src.presentation.presentation_text")

local RunEndNestRenderer = {}
local t = Text.text
local ref = Text.ref

function RunEndNestRenderer.draw(state, _, ui, sw, sh)
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
        spent = progress.spentPoints,
        evolution = ref(progress.evolutionKey),
    }), panelX, panelY + 18, panelW, "center")
    love.graphics.setColor(0.82, 0.9, 0.98)
    love.graphics.printf(t(state, "nest.progress", {
        essence = progress.totalEssence,
        next = progress.nextLevelCost,
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
                name = ref(row.nameKey),
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

return RunEndNestRenderer
