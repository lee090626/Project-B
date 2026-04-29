local C = require("src.constants")
local Locale = require("src.locale")
local Ui = require("src.presentation.ui_primitives")

local ModalRenderer = {}

local function t(state, key, params)
    return Locale.text(state.locale, key, params)
end

local function runReasonRef(reason)
    return Locale.ref("run_reason." .. tostring(reason or "unknown"))
end

function ModalRenderer.drawGuidePanel(state, fonts, ui)
    local active = state.guides and state.guides.active or nil
    ui.guide.button = nil
    if not active then
        return
    end

    local sw = love.graphics.getWidth()
    local cfg = C.GUIDE_UI
    local theme = C.GUIDE_THEME
    local w = math.min(cfg.width, sw - 40)
    local bodyW = w - cfg.padX * 2 - 54
    local body = t(state, active.bodyKey)
    local _, wrappedBody = fonts.hud:getWrap(body, bodyW)
    local bodyH = #wrappedBody * fonts.hud:getHeight()
    local h = math.max(cfg.minHeight, cfg.padY * 2 + bodyH + 42)
    local x = (sw - w) * 0.5
    local y = cfg.topYGame
    if state.mode == "run_choice" then
        y = cfg.topYChoice
    elseif state.mode == "run_end_tree" then
        y = cfg.topYRunEnd
    end

    Ui.drawDecoratedPanel(x, y, w, h, {
        panelFill = theme.panelFill,
        panelInner = theme.panelInner,
        panelLine = theme.panelLine,
        panelGlow = theme.panelGlow,
        accent = theme.panelLine,
    })
    Ui.drawPanelRule(x + 18, y + 48, w - 36, theme.panelLine)
    Ui.drawRuneBadge(active.icon or "help", x + 30, y + 28, 11, theme.chipFill, theme.chipLine)

    love.graphics.setFont(fonts.hud)
    Ui.setPaletteColor(theme.title)
    love.graphics.print(t(state, active.titleKey), x + 52, y + 16)
    Ui.setPaletteColor(theme.text)
    love.graphics.printf(body, x + 22, y + 58, w - 44, "left")

    local buttonW = cfg.buttonWidth
    local buttonH = cfg.buttonHeight
    local buttonX = x + w - buttonW - cfg.padX
    local buttonY = y + h - buttonH - cfg.padY
    ui.guide.button = { x = buttonX, y = buttonY, w = buttonW, h = buttonH }

    Ui.setPaletteColor(theme.buttonFill)
    love.graphics.rectangle("fill", buttonX, buttonY, buttonW, buttonH, 8, 8)
    Ui.setPaletteColor(theme.buttonLine)
    love.graphics.rectangle("line", buttonX, buttonY, buttonW, buttonH, 8, 8)
    Ui.setPaletteColor(theme.dim)
    love.graphics.printf(t(state, "guide.confirm"), buttonX, buttonY + 7, buttonW, "center")
end

function ModalRenderer.drawHelpPanel(state, fonts)
    if not state.showHelp then
        return
    end

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local w = math.min(760, sw - 60)
    local h = 282
    local x = (sw - w) * 0.5
    local y = (sh - h) * 0.5
    local theme = C.HELP_THEME

    love.graphics.setColor(0, 0, 0, 0.78)
    love.graphics.rectangle("fill", 0, 0, sw, sh)
    Ui.drawDecoratedPanel(x, y, w, h, {
        panelFill = theme.panelFill,
        panelInner = theme.panelInner,
        panelLine = theme.panelLine,
        panelGlow = theme.panelLine,
        accent = theme.panelLine,
    })

    love.graphics.setFont(fonts.big)
    Ui.setPaletteColor(theme.text)
    love.graphics.printf(t(state, "help.title"), x, y + 14, w, "center")
    Ui.drawPanelRule(x + 62, y + 52, w - 124, theme.panelLine)

    love.graphics.setFont(fonts.hud)
    Ui.setPaletteColor(theme.text)
    if state.mode == "run_end_tree" then
        love.graphics.printf(
            t(state, "help.run_end.summary", {
                reason = runReasonRef(state.runEndedReason),
                essence = state.meta.essence,
                level = state.nestProgress.level,
                points = state.nestProgress.availablePoints,
            }),
            x + 24,
            y + 72,
            w - 48,
            "left"
        )
        love.graphics.printf(t(state, "help.run_end.drag"), x + 24, y + 98, w - 48, "left")
        love.graphics.printf(t(state, "help.run_end.wheel"), x + 24, y + 122, w - 48, "left")
        love.graphics.printf(t(state, "help.run_end.tab"), x + 24, y + 146, w - 48, "left")
        love.graphics.printf(t(state, "help.run_end.buy"), x + 24, y + 170, w - 48, "left")
    elseif state.mode == "run_choice" then
        love.graphics.printf(t(state, "help.run_choice.line1"), x + 24, y + 72, w - 48, "left")
        love.graphics.printf(t(state, "help.run_choice.line2"), x + 24, y + 102, w - 48, "left")
        love.graphics.printf(t(state, "help.run_choice.line3"), x + 24, y + 132, w - 48, "left")
        love.graphics.printf(t(state, "help.run_choice.line4"), x + 24, y + 162, w - 48, "left")
    else
        love.graphics.printf(t(state, "help.game.goal"), x + 24, y + 72, w - 48, "left")
        love.graphics.printf(t(state, "help.game.map"), x + 24, y + 102, w - 48, "left")
        love.graphics.printf(t(state, "help.game.boss"), x + 24, y + 126, w - 48, "left")
        love.graphics.printf(t(state, "help.game.save"), x + 24, y + 150, w - 48, "left")
    end

    Ui.setPaletteColor(theme.dim)
    love.graphics.printf(
        t(state, "help.language", { language = Locale.ref("language." .. state.locale) }),
        x + 24,
        y + h - 78,
        w - 48,
        "left"
    )

    local chipX = x + 24
    local chipY = y + h - 42
    chipX = chipX + Ui.drawKeyChip(fonts.hud, chipX, chipY, "H", t(state, "help.close_label"), theme) + 16
    Ui.drawKeyChip(fonts.hud, chipX, chipY, "L", t(state, "help.toggle_language_label"), theme)
end

return ModalRenderer
