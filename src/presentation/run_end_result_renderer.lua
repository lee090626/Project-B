local C = require("src.constants")
local Presenter = require("src.presentation.run_end_status_presenter")
local Text = require("src.presentation.presentation_text")
local Ui = require("src.presentation.ui_primitives")

local RunEndResultRenderer = {}
local t = Text.text

local function themeFor(model)
    local cfg = C.RUN_END_RESULT_UI
    return cfg.themes[model.tone] or cfg.themes.time
end

local function panelSize(sw, sh)
    local cfg = C.RUN_END_RESULT_UI
    local w = math.min(cfg.maxWidth, sw - cfg.marginX * 2)
    local h = math.min(cfg.maxHeight, sh - cfg.marginY * 2)
    return w, h, (sw - w) * 0.5, (sh - h) * 0.5
end

local function setThemeColor(color)
    Ui.setPaletteColor(color)
end

local function drawStars(x, y, model, theme)
    local cfg = C.RUN_END_RESULT_UI
    local startX = x - cfg.starGap
    for i = 1, model.stars.max do
        local filled = i <= model.stars.earned
        local cx = startX + (i - 1) * cfg.starGap
        local fill = filled and theme.starFill or theme.emptyStarFill
        local line = filled and theme.starLine or theme.emptyStarLine
        if filled then
            setThemeColor(theme.panelGlow)
            love.graphics.circle("fill", cx, y, cfg.starRadius + 9)
        end
        Ui.drawRuneBadge("star", cx, y, cfg.starRadius, fill, line)
    end
end

local function drawCallout(state, x, y, w, model, theme)
    local cfg = C.RUN_END_RESULT_UI
    setThemeColor(theme.calloutFill)
    love.graphics.rectangle("fill", x, y, w, cfg.calloutHeight, 10, 10)
    setThemeColor(theme.calloutLine)
    love.graphics.rectangle("line", x, y, w, cfg.calloutHeight, 10, 10)
    Ui.drawRuneBadge("star", x + 24, y + cfg.calloutHeight * 0.5, 9, theme.calloutFill, theme.calloutLine)
    setThemeColor(theme.text)
    love.graphics.printf(
        t(state, model.calloutKey, model.calloutParams),
        x + 44,
        y + 12,
        w - 68,
        "center"
    )
end

local function drawStats(state, fonts, x, y, w, model, theme)
    local cfg = C.RUN_END_RESULT_UI
    local count = #model.stats
    local colW = (w - cfg.statGap * (count - 1)) / count

    for index, stat in ipairs(model.stats) do
        local colX = x + (index - 1) * (colW + cfg.statGap)
        Ui.drawRuneBadge(stat.icon, colX + colW * 0.5, y + 8, 8, theme.panelFill, theme.accentSoft)
        setThemeColor(theme.dim)
        love.graphics.printf(t(state, stat.labelKey), colX, y + 24, colW, "center")
        setThemeColor(theme.text)
        local value = stat.valueRef and t(state, stat.valueRef.key, stat.valueRef.params) or tostring(stat.value)
        value = Ui.ellipsize(fonts.hud, value, colW - 8)
        love.graphics.printf(value, colX, y + 44, colW, "center")
    end
end

local function drawNextUnlock(state, x, y, w, model, theme)
    local cfg = C.RUN_END_RESULT_UI
    local nextUnlock = model.nextUnlock
    local label = t(state, nextUnlock.labelKey, nextUnlock.labelParams)
    local value = nextUnlock.valueKey and t(state, nextUnlock.valueKey) or nextUnlock.value

    setThemeColor(theme.dim)
    love.graphics.print(label, x, y)
    setThemeColor(theme.text)
    love.graphics.printf(value, x, y, w, "right")

    local barY = y + 24
    setThemeColor(theme.progressBg)
    love.graphics.rectangle("fill", x, barY, w, cfg.progressHeight, 6, 6)
    setThemeColor(theme.progressFill)
    love.graphics.rectangle("fill", x + 2, barY + 2, math.max(0, (w - 4) * nextUnlock.progress), cfg.progressHeight - 4, 5, 5)
    setThemeColor(theme.panelLine)
    love.graphics.rectangle("line", x, barY, w, cfg.progressHeight, 6, 6)
end

function RunEndResultRenderer.draw(state, fonts)
    local cfg = C.RUN_END_RESULT_UI
    local model = Presenter.build(state)
    local theme = themeFor(model)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local w, h, x, y = panelSize(sw, sh)
    local contentX = x + cfg.padX
    local contentW = w - cfg.padX * 2

    setThemeColor(theme.overlay)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    Ui.drawDecoratedPanel(x, y, w, h, theme)

    love.graphics.setFont(fonts.big)
    setThemeColor(theme.text)
    love.graphics.printf(t(state, model.titleKey), contentX, y + cfg.titleY, contentW, "center")

    love.graphics.setFont(fonts.hud)
    setThemeColor(theme.dim)
    love.graphics.printf(t(state, model.subtitleKey), contentX, y + cfg.subtitleY, contentW, "center")

    drawStars(x + w * 0.5, y + cfg.starCenterY, model, theme)
    drawCallout(state, contentX, y + cfg.calloutY, contentW, model, theme)
    drawStats(state, fonts, contentX, y + cfg.statsY, contentW, model, theme)
    drawNextUnlock(state, contentX, y + cfg.nextY, contentW, model, theme)

    setThemeColor(theme.accentSoft)
    love.graphics.printf(t(state, "run_end.result.continue"), contentX, y + h - cfg.continueBottom, contentW, "center")
end

return RunEndResultRenderer
