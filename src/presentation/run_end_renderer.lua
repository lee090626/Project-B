local C = require("src.constants")
local Text = require("src.presentation.presentation_text")
local RunEndMetaTreeRenderer = require("src.presentation.run_end_meta_tree_renderer")
local RunEndNestRenderer = require("src.presentation.run_end_nest_renderer")
local RunEndResultRenderer = require("src.presentation.run_end_result_renderer")

local RunEndRenderer = {}
local t = Text.text

local function drawRunEndTabs(state, _, ui, sw)
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

function RunEndRenderer.drawRunEndTreeFullscreen(state, fonts, ui)
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
        RunEndNestRenderer.draw(state, fonts, ui, sw, sh)
        return
    end

    RunEndMetaTreeRenderer.draw(state, fonts, ui, sw, sh)
end

function RunEndRenderer.drawRunEndResultOverlay(state, fonts)
    return RunEndResultRenderer.draw(state, fonts)
end

return RunEndRenderer
