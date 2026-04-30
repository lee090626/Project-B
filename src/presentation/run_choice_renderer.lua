local C = require("src.constants")
local Text = require("src.presentation.presentation_text")
local Ui = require("src.presentation.ui_primitives")

local RunChoiceRenderer = {}
local t = Text.text

local function getChoicePalette(rarity)
    return C.RUN_CHOICE_THEME[rarity] or C.RUN_CHOICE_THEME.common
end

local function drawRunChoiceCardFrame(x, y, cfg, palette, assets, rarity)
    local frame = assets and assets.runChoiceCardFrames and assets.runChoiceCardFrames[rarity]
    if frame and frame:getWidth() == cfg.cardWidth and frame:getHeight() == cfg.cardHeight then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(frame, x, y)
        return
    end

    Ui.drawDecoratedPanel(x, y, cfg.cardWidth, cfg.cardHeight, {
        panelFill = palette.fill,
        panelInner = palette.inner,
        panelLine = palette.line,
        panelGlow = palette.line,
        accent = palette.line,
    })

    Ui.setPaletteColor(palette.ribbon)
    love.graphics.rectangle("fill", x + 16, y + 16, cfg.cardWidth - 32, 28, 8, 8)
    Ui.setPaletteColor(palette.line)
    love.graphics.rectangle("line", x + 16, y + 16, cfg.cardWidth - 32, 28, 8, 8)
    Ui.setPaletteColor(palette.ribbon)
    love.graphics.rectangle("fill", x + 18, y + cfg.cardHeight - 46, cfg.cardWidth - 36, 28, 10, 10)
    Ui.setPaletteColor(palette.line)
    love.graphics.rectangle("line", x + 18, y + cfg.cardHeight - 46, cfg.cardWidth - 36, 28, 10, 10)
end

local function getCategorySymbol(category)
    if category == "hunt" then
        return "hunt"
    elseif category == "stomach" then
        return "stomach"
    elseif category == "sense" then
        return "sense"
    elseif category == "spawn" then
        return "spawn"
    end
    return "instinct"
end

function RunChoiceRenderer.drawRunChoiceOverlay(state, fonts, ui, assets)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local cards = state.runMutations.activeChoices or {}
    local cfg = C.RUN_CHOICE_UI
    local theme = C.RUN_CHOICE_THEME
    local count = #cards
    local totalW = count * cfg.cardWidth + math.max(0, count - 1) * cfg.cardGap
    local startX = (sw - totalW) * 0.5
    local y = (sh - cfg.cardHeight) * 0.5 + 34

    ui.runChoice.cards = {}

    Ui.setPaletteColor(theme.overlay)
    love.graphics.rectangle("fill", 0, 0, sw, sh)
    love.graphics.setFont(fonts.big)
    Ui.setPaletteColor(theme.title)
    love.graphics.printf(t(state, "run_choice.title"), 0, y - 92, sw, "center")
    Ui.drawPanelRule(sw * 0.36, y - 52, sw * 0.28, C.HUD_THEME.accent)
    love.graphics.setFont(fonts.hud)
    Ui.setPaletteColor(theme.summary)
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

        local palette = getChoicePalette(card.rarity)
        drawRunChoiceCardFrame(x, y, cfg, palette, assets, card.rarity)

        Ui.setPaletteColor(C.HUD_THEME.text)
        love.graphics.printf(t(state, "rarity." .. card.rarity), x + 16, y + 22, cfg.cardWidth - 32, "center")

        Ui.setPaletteColor(C.HUD_THEME.dim)
        love.graphics.printf(t(state, card.nameKey), x + 18, y + 58, cfg.cardWidth - 36, "center")

        Ui.setPaletteColor(C.HUD_THEME.chipFill)
        love.graphics.rectangle("fill", x + 22, y + 88, 90, 24, 8, 8)
        Ui.setPaletteColor(palette.line)
        love.graphics.rectangle("line", x + 22, y + 88, 90, 24, 8, 8)
        Ui.setPaletteColor(C.HUD_THEME.text)
        love.graphics.printf(t(state, "category." .. card.category), x + 22, y + 93, 90, "center")

        Ui.drawRuneBadge(getCategorySymbol(card.category), x + cfg.cardWidth * 0.5, y + 132, 20, palette.inner, palette.line)

        Ui.setPaletteColor(C.HUD_THEME.text)
        love.graphics.printf(t(state, card.descKey), x + 26, y + 160, cfg.cardWidth - 52, "center")

        Ui.setPaletteColor(C.HUD_THEME.text)
        love.graphics.printf(t(state, "run_choice.click"), x + 18, y + cfg.cardHeight - 40, cfg.cardWidth - 36, "center")
    end
end

return RunChoiceRenderer
