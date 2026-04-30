local C = require("src.constants")
local MapSystem = require("src.map_system")
local Mutation = require("src.mutation_system")
local RunEvent = require("src.run_event_system")
local Text = require("src.presentation.presentation_text")
local Ui = require("src.presentation.ui_primitives")

local HudRenderer = {}
local t = Text.text
local ref = Text.ref

local function formatTime(seconds)
    local total = math.max(0, math.floor(seconds))
    local m = math.floor(total / 60)
    local s = total % 60
    return string.format("%02d:%02d", m, s)
end

local function formatBossTime(seconds)
    return string.format("%.1f", math.max(0, seconds or 0))
end

local function getToastTheme(key, isStatus)
    local theme = C.HUD_THEME
    if isStatus then
        if key == "save_status.failed" then
            return theme.danger
        end
        return theme.accentSoft
    end
    if key and key:find("failed", 1, true) then
        return theme.warning
    end
    return theme.accent
end

local function eventStripLabel(state, hud)
    local eventState = state.runEvent or {}
    if hud.activeLabelKey then
        return t(state, hud.activeLabelKey)
    end
    if eventState.finalCompleted then
        return t(state, "hud.event.done")
    end
    if eventState.finalTriggered then
        return t(state, "hud.event.final")
    end
    if eventState.midCompleted then
        return t(state, "hud.event.final_prep")
    end
    if eventState.midTriggered then
        return t(state, "hud.event.mid")
    end
    return t(state, "hud.event.opening")
end

function HudRenderer.drawGameTopBar(state, fonts, ui, assets)
    local sw = love.graphics.getWidth()
    local mapData = MapSystem.getCurrentMap(state.maps)
    local unlockedMaps = 0
    for _, map in ipairs(C.MAPS) do
        if state.maps.unlocked[map.id] then
            unlockedMaps = unlockedMaps + 1
        end
    end

    local cfg = C.RUN_HUD_UI
    local theme = C.HUD_THEME
    local pad = cfg.padding
    local topY = pad
    local barH = cfg.topBarHeight
    local compact = sw < 1180

    love.graphics.setFont(fonts.hud)

    local mapText = t(state, "hud.map", {
        map = ref(mapData.nameKey),
        unlocked = unlockedMaps,
        total = #C.MAPS,
    })
    mapText = Ui.ellipsize(fonts.hud, mapText, math.max(180, sw * 0.34))

    local statusText = t(state, "hud.time_map", {
        time = formatTime(state.runTimeLeft),
        map = mapText,
    })
    local resourceText = t(state, "hud.essence", {
        essence = state.meta.essence,
        level = state.nestProgress and state.nestProgress.level or 0,
        current = state.nestProgress and state.nestProgress.currentLevelProgress or 0,
        goal = state.nestProgress and state.nestProgress.essencePerLevel or 0,
    })
    local instinct = Mutation.getProgress(state)
    local instinctText
    if instinct.complete then
        instinctText = t(state, "hud.instinct_complete")
    else
        if compact then
            instinctText = t(state, "hud.instinct_short", { remain = instinct.remain })
        else
            instinctText = t(state, "hud.instinct_progress", {
                current = instinct.current,
                next = instinct.next,
                remain = instinct.remain,
            })
        end
    end

    local statusW = math.max(320, math.min(sw * 0.38, fonts.hud:getWidth(statusText) + 84))
    local resourceW = math.max(270, math.min(sw * 0.28, math.max(fonts.hud:getWidth(resourceText), fonts.hud:getWidth(instinctText)) + 86))
    local saveW = compact and 118 or 132
    local helpText = t(state, "hud.help")
    local helpW = fonts.hud:getWidth(helpText) + 40
    local controlsW = saveW + cfg.groupGap + helpW
    local resourceX = pad
    local statusX = sw - pad - statusW
    local controlsMinX = resourceX + resourceW + cfg.groupGap
    local controlsMaxX = statusX - controlsW - cfg.groupGap
    local controlsX = (sw - controlsW) * 0.5
    if controlsMinX <= controlsMaxX then
        controlsX = math.max(controlsMinX, math.min(controlsX, controlsMaxX))
    else
        controlsX = math.max(pad, math.min(controlsX, sw - pad - controlsW))
    end

    Ui.drawDecoratedPanel(resourceX, topY, resourceW, barH, theme, nil, { hideCorners = true })
    Ui.drawDecoratedPanel(statusX, topY, statusW, barH, theme, nil, { hideCorners = true })

    local essenceIcon = assets and assets.icons and assets.icons.essence
    local essenceIconSize = C.UI_ICONS.essence.hudSize
    if not Ui.drawIconAtSize(essenceIcon, resourceX + 18, topY + 18, essenceIconSize) then
        Ui.drawRuneBadge("essence", resourceX + 18, topY + 18, 11, theme.chipFill, theme.accent)
    end
    Ui.drawRuneBadge("level", resourceX + 18, topY + 44, 11, theme.chipFill, theme.accentSoft)
    Ui.setPaletteColor(theme.text)
    love.graphics.print(resourceText, resourceX + 38, topY + 8)
    Ui.setPaletteColor(theme.dim)
    love.graphics.print(instinctText, resourceX + 38, topY + 34)
    local pct = instinct.complete and 1 or (instinct.next > 0 and instinct.current / instinct.next or 0)
    Ui.drawProgressBar(resourceX + 38, topY + 54, resourceW - 52, 12, pct, theme, instinct.complete)

    Ui.drawRuneBadge("time", statusX + 20, topY + 22, 12, theme.chipFill, theme.accent)
    Ui.drawRuneBadge("map", statusX + 20, topY + 50, 12, theme.chipFill, theme.accentSoft)
    Ui.setPaletteColor(theme.text)
    love.graphics.print(formatTime(state.runTimeLeft), statusX + 40, topY + 12)
    Ui.setPaletteColor(theme.dim)
    love.graphics.print(mapText, statusX + 40, topY + 40)
    Ui.setPaletteColor(theme.accentSoft)
    love.graphics.print(string.format("%d/%d", unlockedMaps, #C.MAPS), statusX + statusW - 54, topY + 40)

    ui.saveBtn.x = controlsX
    ui.saveBtn.y = topY + 10
    ui.saveBtn.h = 26
    ui.saveBtn.w = saveW
    Ui.setPaletteColor(theme.buttonFill)
    love.graphics.rectangle("fill", ui.saveBtn.x, ui.saveBtn.y, ui.saveBtn.w, ui.saveBtn.h, 8, 8)
    Ui.setPaletteColor(theme.buttonLine)
    love.graphics.rectangle("line", ui.saveBtn.x, ui.saveBtn.y, ui.saveBtn.w, ui.saveBtn.h, 8, 8)
    Ui.drawRuneBadge("save", ui.saveBtn.x + 16, ui.saveBtn.y + 13, 8, theme.chipFill, theme.buttonLine)
    local saveText = t(state, "hud.manual_save")
    local saveTextX = ui.saveBtn.x + 30 + (ui.saveBtn.w - 30 - fonts.hud:getWidth(saveText)) * 0.5
    Ui.setPaletteColor(theme.buttonText)
    love.graphics.print(saveText, saveTextX, ui.saveBtn.y + 5)

    local helpX = controlsX + saveW + cfg.groupGap
    Ui.setPaletteColor(theme.chipFill)
    love.graphics.rectangle("fill", helpX, topY + 10, helpW, 26, 8, 8)
    Ui.setPaletteColor(theme.chipLine)
    love.graphics.rectangle("line", helpX, topY + 10, helpW, 26, 8, 8)
    Ui.drawRuneBadge("help", helpX + 14, topY + 23, 7, theme.chipFill, theme.chipLine)
    Ui.setPaletteColor(theme.text)
    love.graphics.print(helpText, helpX + 28, topY + 15)

    if state.mode ~= "game" or state.runEnded or state.boss.active then
        return
    end

    local hud = RunEvent.getHudState(state)
    if not hud then
        return
    end

    local label = eventStripLabel(state, hud)
    local starText = t(state, "hud.stars_short", { stars = hud.starsEarned or 0 })
    local bonusText = t(state, "hud.bonus_time_short", { time = hud.bonusTimeEarned or 0 })
    local starBlockW = 18 + fonts.hud:getWidth(starText)
    local chipContentW = fonts.hud:getWidth(label) + 18 + starBlockW + fonts.hud:getWidth(bonusText)
    local chipW = math.min(sw - 40, math.max(320, chipContentW + 52))
    local chipX = (sw - chipW) * 0.5
    local chipY = topY + barH + 8

    Ui.drawDecoratedPanel(chipX, chipY, chipW, 28, {
        panelFill = { 0.07, 0.08, 0.09, 0.93 },
        panelInner = { 0.11, 0.13, 0.14, 0.88 },
        panelLine = theme.accentSoft,
        panelGlow = theme.accentSoft,
        accent = theme.accent,
    })
    Ui.setPaletteColor(theme.text)
    local contentX = chipX + (chipW - chipContentW) * 0.5
    love.graphics.print(label, contentX, chipY + 7)
    local starX = contentX + fonts.hud:getWidth(label) + 18
    Ui.drawRuneBadge("star", starX + 8, chipY + 14, 7, theme.chipFill, theme.accent)
    love.graphics.print(starText, starX + 18, chipY + 7)
    local bonusX = starX + starBlockW + 18
    love.graphics.print(bonusText, bonusX, chipY + 7)
end

function HudRenderer.drawBossBar(state, fonts)
    if not state.boss.active then
        return
    end
    local sw = love.graphics.getWidth()
    local cfg = C.RUN_HUD_UI
    local theme = C.HUD_THEME
    local y = cfg.padding + cfg.topBarHeight + 12
    local x = sw * 0.18
    local w = sw * 0.64
    local h = 54
    local pct = state.boss.maxHp > 0 and (state.boss.hp / state.boss.maxHp) or 0
    local statusKey = state.boss.shielded and "boss.status.shielded" or "boss.status.vulnerable"
    local info = string.format(
        "%s   %s   %s",
        t(state, "boss.timer", { time = formatBossTime(state.boss.arenaTimer) }),
        t(state, statusKey),
        t(state, "boss.weak_points", { count = #(state.boss.weakPoints or {}) })
    )
    Ui.setPaletteColor(theme.panelFill)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)
    Ui.setPaletteColor(theme.panelLine)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)
    love.graphics.polygon("fill", x - 12, y + h * 0.5, x, y + 5, x, y + h - 5)
    love.graphics.polygon("fill", x + w + 12, y + h * 0.5, x + w, y + 5, x + w, y + h - 5)
    Ui.setPaletteColor({ 0.24, 0.07, 0.07, 0.95 })
    love.graphics.rectangle("fill", x + 4, y + 18, w - 8, 20, 8, 8)
    Ui.setPaletteColor({ 0.96, 0.48, 0.18, 0.96 })
    love.graphics.rectangle("fill", x + 4, y + 18, math.max(0, (w - 8) * pct), 20, 8, 8)
    Ui.setPaletteColor({ 0.98, 0.74, 0.38, 0.35 })
    love.graphics.rectangle("fill", x + 4, y + 18, math.max(0, (w - 8) * pct), 8, 8, 8)
    Ui.drawRuneBadge("boss", x + 22, y + 12, 10, theme.chipFill, theme.accent)
    Ui.setPaletteColor(theme.text)
    love.graphics.setFont(fonts.hud)
    love.graphics.printf(t(state, "boss.title"), x, y + 4, w, "center")
    Ui.setPaletteColor(theme.dim)
    love.graphics.printf(info, x + 12, y + 38, w - 24, "center")
end

function HudRenderer.drawGameToasts(state, fonts)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local cfg = C.RUN_HUD_UI

    if state.uiAutosaveTimer > 0 and state.lastSaveStatusKey then
        local a = math.min(1, state.uiAutosaveTimer / cfg.autosaveDuration)
        local color = getToastTheme(state.lastSaveStatusKey, true)
        local y = sh - 44 - (1 - a) * 5
        Ui.drawDecoratedPanel(sw * 0.33, y, sw * 0.34, 28, {
            panelFill = { 0.07, 0.08, 0.07, 0.9 },
            panelInner = { 0.11, 0.13, 0.1, 0.85 },
            panelLine = color,
            panelGlow = color,
            accent = color,
        }, a)
        Ui.setPaletteColor(color, a)
        love.graphics.setFont(fonts.hud)
        love.graphics.printf(
            t(state, state.lastSaveStatusKey, state.lastSaveStatusParams),
            sw * 0.35,
            y + 6,
            sw * 0.3,
            "center"
        )
    end

    if state.messageKey and state.uiToastTimer > 0 then
        local a = math.min(1, state.uiToastTimer / cfg.toastDuration)
        local color = getToastTheme(state.messageKey, false)
        local w = math.min(sw - 24, 780)
        local x = (sw - w) * 0.5
        local y = sh - 80 - (1 - a) * 6
        Ui.drawDecoratedPanel(x, y, w, 40, {
            panelFill = { 0.09, 0.08, 0.06, 0.93 },
            panelInner = { 0.15, 0.11, 0.08, 0.85 },
            panelLine = color,
            panelGlow = color,
            accent = color,
        }, a)
        Ui.setPaletteColor(color, a)
        love.graphics.setFont(fonts.hud)
        love.graphics.printf(t(state, state.messageKey, state.messageParams), x + 14, y + 10, w - 28, "center")
    end
end

return HudRenderer
