local C = require("src.constants")
local Locale = require("src.locale")
local MapSystem = require("src.map_system")
local GameState = require("src.game_state")
local Meta = require("src.meta_system")
local Mutation = require("src.mutation_system")
local RunEvent = require("src.run_event_system")

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

local function formatBossTime(seconds)
    return string.format("%.1f", math.max(0, seconds or 0))
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

local function setPaletteColor(color, alphaMul)
    local a = (color[4] or 1) * (alphaMul or 1)
    love.graphics.setColor(color[1], color[2], color[3], a)
end

local function drawDiamond(x, y, radius)
    love.graphics.polygon("line", x, y - radius, x + radius, y, x, y + radius, x - radius, y)
end

local function drawIconAtSize(image, x, y, size)
    if not image or not size or size <= 0 then
        return false
    end

    local iw = image:getWidth()
    local ih = image:getHeight()
    if iw <= 0 or ih <= 0 then
        return false
    end

    local scale = size / math.max(iw, ih)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, x, y, 0, scale, scale, iw * 0.5, ih * 0.5)
    return true
end

local function buildStarPoints(x, y, outerRadius, innerRadius)
    local points = {}
    for i = 0, 9 do
        local angle = -math.pi * 0.5 + i * math.pi * 0.2
        local radius = (i % 2 == 0) and outerRadius or innerRadius
        points[#points + 1] = x + math.cos(angle) * radius
        points[#points + 1] = y + math.sin(angle) * radius
    end
    return points
end

local function drawDecoratedPanel(x, y, w, h, theme, alphaMul, options)
    setPaletteColor(theme.panelFill, alphaMul)
    love.graphics.rectangle("fill", x, y, w, h, 14, 14)
    setPaletteColor(theme.panelInner or theme.panelFill, 0.72 * (alphaMul or 1))
    love.graphics.rectangle("fill", x + 8, y + 8, w - 16, h - 16, 10, 10)
    setPaletteColor(theme.panelGlow or theme.panelLine, alphaMul)
    love.graphics.rectangle("line", x + 3, y + 3, w - 6, h - 6, 12, 12)
    setPaletteColor(theme.panelLine, alphaMul)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 14, 14)

    if not (options and options.hideCorners) then
        local corner = 8
        setPaletteColor(theme.accent or theme.panelLine, 0.9 * (alphaMul or 1))
        love.graphics.polygon("fill", x + 14, y + 8, x + 14 + corner, y + 14, x + 14, y + 20, x + 14 - corner, y + 14)
        love.graphics.polygon("fill", x + w - 14, y + 8, x + w - 14 + corner, y + 14, x + w - 14, y + 20, x + w - 14 - corner, y + 14)
    end
end

local function drawPanelRule(x, y, w, color, alphaMul)
    setPaletteColor(color, alphaMul)
    love.graphics.setLineWidth(2)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x + w * 0.32, y - 4, x + w * 0.5, y - 4)
    love.graphics.line(x + w * 0.5, y + 4, x + w * 0.68, y + 4)
end

local function drawRuneBadge(kind, x, y, radius, fillColor, lineColor)
    love.graphics.setLineWidth(2)
    setPaletteColor(fillColor)
    love.graphics.circle("fill", x, y, radius)
    setPaletteColor(lineColor)
    love.graphics.circle("line", x, y, radius)

    if kind == "time" then
        love.graphics.line(x, y, x, y - radius * 0.45)
        love.graphics.line(x, y, x + radius * 0.32, y)
    elseif kind == "map" then
        drawDiamond(x, y, radius * 0.48)
        love.graphics.line(x, y - radius * 0.48, x, y + radius * 0.48)
    elseif kind == "star" then
        local fillPoints = buildStarPoints(x, y, radius * 0.42, radius * 0.2)
        local linePoints = buildStarPoints(x, y, radius * 0.56, radius * 0.26)
        setPaletteColor(fillColor)
        love.graphics.polygon("fill", fillPoints)
        setPaletteColor(lineColor)
        love.graphics.polygon("line", linePoints)
    elseif kind == "essence" then
        love.graphics.circle("fill", x, y, radius * 0.34)
        love.graphics.arc("line", "open", x, y, radius * 0.6, -math.pi * 0.15, math.pi * 1.15)
    elseif kind == "level" then
        love.graphics.line(x - radius * 0.4, y + radius * 0.35, x, y - radius * 0.45)
        love.graphics.line(x, y - radius * 0.45, x + radius * 0.4, y + radius * 0.35)
        love.graphics.line(x - radius * 0.26, y + radius * 0.06, x + radius * 0.26, y + radius * 0.06)
    elseif kind == "instinct" then
        love.graphics.arc("line", "open", x - radius * 0.16, y, radius * 0.44, -math.pi * 0.4, math.pi * 0.4)
        love.graphics.arc("line", "open", x + radius * 0.16, y, radius * 0.44, math.pi * 0.6, math.pi * 1.4)
        love.graphics.circle("fill", x, y, radius * 0.14)
    elseif kind == "save" then
        love.graphics.rectangle("line", x - radius * 0.34, y - radius * 0.34, radius * 0.68, radius * 0.68, 3, 3)
        love.graphics.line(x - radius * 0.18, y - radius * 0.08, x + radius * 0.18, y - radius * 0.08)
        love.graphics.line(x - radius * 0.14, y + radius * 0.2, x + radius * 0.14, y + radius * 0.2)
    elseif kind == "help" then
        love.graphics.arc("line", "open", x, y - radius * 0.08, radius * 0.34, math.pi, math.pi * 2)
        love.graphics.line(x + radius * 0.16, y + radius * 0.02, x, y + radius * 0.22)
        love.graphics.circle("fill", x, y + radius * 0.42, radius * 0.06)
    elseif kind == "boss" then
        love.graphics.line(x - radius * 0.36, y + radius * 0.3, x - radius * 0.12, y - radius * 0.26)
        love.graphics.line(x + radius * 0.36, y + radius * 0.3, x + radius * 0.12, y - radius * 0.26)
        love.graphics.line(x - radius * 0.12, y - radius * 0.26, x + radius * 0.12, y - radius * 0.26)
    elseif kind == "hunt" then
        love.graphics.line(x - radius * 0.3, y + radius * 0.24, x, y - radius * 0.32)
        love.graphics.line(x + radius * 0.18, y + radius * 0.26, x, y - radius * 0.32)
    elseif kind == "stomach" then
        love.graphics.circle("line", x, y, radius * 0.4)
        love.graphics.circle("fill", x, y, radius * 0.12)
    elseif kind == "sense" then
        love.graphics.arc("line", "open", x, y, radius * 0.56, math.pi * 0.15, math.pi * 0.85)
        love.graphics.arc("line", "open", x, y, radius * 0.56, math.pi * 1.15, math.pi * 1.85)
        love.graphics.circle("fill", x, y, radius * 0.12)
    elseif kind == "spawn" then
        for i = 0, 3 do
            local angle = i * math.pi * 0.5
            love.graphics.line(x, y, x + math.cos(angle) * radius * 0.42, y + math.sin(angle) * radius * 0.42)
        end
        love.graphics.circle("fill", x, y, radius * 0.1)
    end
end

local function drawKeyChip(font, x, y, keyLabel, desc, theme)
    local padX = 10
    local keyW = font:getWidth(keyLabel) + padX * 2
    local descW = font:getWidth(desc)
    local totalW = keyW + 10 + descW

    setPaletteColor(theme.chipFill)
    love.graphics.rectangle("fill", x, y, keyW, 24, 8, 8)
    setPaletteColor(theme.chipLine)
    love.graphics.rectangle("line", x, y, keyW, 24, 8, 8)
    setPaletteColor(theme.text or theme.panelLine)
    love.graphics.print(keyLabel, x + padX, y + 4)
    setPaletteColor(theme.dim or theme.text)
    love.graphics.print(desc, x + keyW + 10, y + 4)
    return totalW
end

local function drawProgressBar(x, y, w, h, pct, theme, complete)
    pct = math.max(0, math.min(1, pct or 0))
    setPaletteColor(theme.progressBg)
    love.graphics.rectangle("fill", x, y, w, h, 5, 5)
    setPaletteColor(complete and theme.progressDone or theme.progressFill)
    love.graphics.rectangle("fill", x + 2, y + 2, math.max(0, (w - 4) * pct), h - 4, 4, 4)
    setPaletteColor(theme.panelLine)
    love.graphics.rectangle("line", x, y, w, h, 5, 5)
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

    drawDecoratedPanel(x, y, cfg.cardWidth, cfg.cardHeight, {
        panelFill = palette.fill,
        panelInner = palette.inner,
        panelLine = palette.line,
        panelGlow = palette.line,
        accent = palette.line,
    })

    setPaletteColor(palette.ribbon)
    love.graphics.rectangle("fill", x + 16, y + 16, cfg.cardWidth - 32, 28, 8, 8)
    setPaletteColor(palette.line)
    love.graphics.rectangle("line", x + 16, y + 16, cfg.cardWidth - 32, 28, 8, 8)
    setPaletteColor(palette.ribbon)
    love.graphics.rectangle("fill", x + 18, y + cfg.cardHeight - 46, cfg.cardWidth - 36, 28, 10, 10)
    setPaletteColor(palette.line)
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

function OverlayRenderer.drawGameTopBar(state, fonts, ui, assets)
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
        map = Locale.ref(mapData.nameKey),
        unlocked = unlockedMaps,
        total = #C.MAPS,
    })
    mapText = ellipsize(fonts.hud, mapText, math.max(180, sw * 0.34))

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

    drawDecoratedPanel(resourceX, topY, resourceW, barH, theme, nil, { hideCorners = true })
    drawDecoratedPanel(statusX, topY, statusW, barH, theme, nil, { hideCorners = true })

    local essenceIcon = assets and assets.icons and assets.icons.essence
    local essenceIconSize = C.UI_ICONS.essence.hudSize
    if not drawIconAtSize(essenceIcon, resourceX + 18, topY + 18, essenceIconSize) then
        drawRuneBadge("essence", resourceX + 18, topY + 18, 11, theme.chipFill, theme.accent)
    end
    drawRuneBadge("level", resourceX + 18, topY + 44, 11, theme.chipFill, theme.accentSoft)
    setPaletteColor(theme.text)
    love.graphics.print(resourceText, resourceX + 38, topY + 8)
    setPaletteColor(theme.dim)
    love.graphics.print(instinctText, resourceX + 38, topY + 34)
    local pct = instinct.complete and 1 or (instinct.next > 0 and instinct.current / instinct.next or 0)
    drawProgressBar(resourceX + 38, topY + 54, resourceW - 52, 12, pct, theme, instinct.complete)

    drawRuneBadge("time", statusX + 20, topY + 22, 12, theme.chipFill, theme.accent)
    drawRuneBadge("map", statusX + 20, topY + 50, 12, theme.chipFill, theme.accentSoft)
    setPaletteColor(theme.text)
    love.graphics.print(formatTime(state.runTimeLeft), statusX + 40, topY + 12)
    setPaletteColor(theme.dim)
    love.graphics.print(mapText, statusX + 40, topY + 40)
    setPaletteColor(theme.accentSoft)
    love.graphics.print(string.format("%d/%d", unlockedMaps, #C.MAPS), statusX + statusW - 54, topY + 40)

    ui.saveBtn.x = controlsX
    ui.saveBtn.y = topY + 10
    ui.saveBtn.h = 26
    ui.saveBtn.w = saveW
    setPaletteColor(theme.buttonFill)
    love.graphics.rectangle("fill", ui.saveBtn.x, ui.saveBtn.y, ui.saveBtn.w, ui.saveBtn.h, 8, 8)
    setPaletteColor(theme.buttonLine)
    love.graphics.rectangle("line", ui.saveBtn.x, ui.saveBtn.y, ui.saveBtn.w, ui.saveBtn.h, 8, 8)
    drawRuneBadge("save", ui.saveBtn.x + 16, ui.saveBtn.y + 13, 8, theme.chipFill, theme.buttonLine)
    local saveText = t(state, "hud.manual_save")
    local saveTextX = ui.saveBtn.x + 30 + (ui.saveBtn.w - 30 - fonts.hud:getWidth(saveText)) * 0.5
    setPaletteColor(theme.buttonText)
    love.graphics.print(saveText, saveTextX, ui.saveBtn.y + 5)

    local helpX = controlsX + saveW + cfg.groupGap
    setPaletteColor(theme.chipFill)
    love.graphics.rectangle("fill", helpX, topY + 10, helpW, 26, 8, 8)
    setPaletteColor(theme.chipLine)
    love.graphics.rectangle("line", helpX, topY + 10, helpW, 26, 8, 8)
    drawRuneBadge("help", helpX + 14, topY + 23, 7, theme.chipFill, theme.chipLine)
    setPaletteColor(theme.text)
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

    drawDecoratedPanel(chipX, chipY, chipW, 28, {
        panelFill = { 0.07, 0.08, 0.09, 0.93 },
        panelInner = { 0.11, 0.13, 0.14, 0.88 },
        panelLine = theme.accentSoft,
        panelGlow = theme.accentSoft,
        accent = theme.accent,
    })
    setPaletteColor(theme.text)
    local contentX = chipX + (chipW - chipContentW) * 0.5
    love.graphics.print(label, contentX, chipY + 7)
    local starX = contentX + fonts.hud:getWidth(label) + 18
    drawRuneBadge("star", starX + 8, chipY + 14, 7, theme.chipFill, theme.accent)
    love.graphics.print(starText, starX + 18, chipY + 7)
    local bonusX = starX + starBlockW + 18
    love.graphics.print(bonusText, bonusX, chipY + 7)
end

function OverlayRenderer.drawBossBar(state, fonts)
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
    setPaletteColor(theme.panelFill)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)
    setPaletteColor(theme.panelLine)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)
    love.graphics.polygon("fill", x - 12, y + h * 0.5, x, y + 5, x, y + h - 5)
    love.graphics.polygon("fill", x + w + 12, y + h * 0.5, x + w, y + 5, x + w, y + h - 5)
    setPaletteColor({ 0.24, 0.07, 0.07, 0.95 })
    love.graphics.rectangle("fill", x + 4, y + 18, w - 8, 20, 8, 8)
    setPaletteColor({ 0.96, 0.48, 0.18, 0.96 })
    love.graphics.rectangle("fill", x + 4, y + 18, math.max(0, (w - 8) * pct), 20, 8, 8)
    setPaletteColor({ 0.98, 0.74, 0.38, 0.35 })
    love.graphics.rectangle("fill", x + 4, y + 18, math.max(0, (w - 8) * pct), 8, 8, 8)
    drawRuneBadge("boss", x + 22, y + 12, 10, theme.chipFill, theme.accent)
    setPaletteColor(theme.text)
    love.graphics.setFont(fonts.hud)
    love.graphics.printf(t(state, "boss.title"), x, y + 4, w, "center")
    setPaletteColor(theme.dim)
    love.graphics.printf(info, x + 12, y + 38, w - 24, "center")
end

function OverlayRenderer.drawGameToasts(state, fonts)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local cfg = C.RUN_HUD_UI

    if state.uiAutosaveTimer > 0 and state.lastSaveStatusKey then
        local a = math.min(1, state.uiAutosaveTimer / cfg.autosaveDuration)
        local color = getToastTheme(state.lastSaveStatusKey, true)
        local y = sh - 44 - (1 - a) * 5
        drawDecoratedPanel(sw * 0.33, y, sw * 0.34, 28, {
            panelFill = { 0.07, 0.08, 0.07, 0.9 },
            panelInner = { 0.11, 0.13, 0.1, 0.85 },
            panelLine = color,
            panelGlow = color,
            accent = color,
        }, a)
        setPaletteColor(color, a)
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
        drawDecoratedPanel(x, y, w, 40, {
            panelFill = { 0.09, 0.08, 0.06, 0.93 },
            panelInner = { 0.15, 0.11, 0.08, 0.85 },
            panelLine = color,
            panelGlow = color,
            accent = color,
        }, a)
        setPaletteColor(color, a)
        love.graphics.setFont(fonts.hud)
        love.graphics.printf(t(state, state.messageKey, state.messageParams), x + 14, y + 10, w - 28, "center")
    end
end

function OverlayRenderer.drawGuidePanel(state, fonts, ui)
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

    drawDecoratedPanel(x, y, w, h, {
        panelFill = theme.panelFill,
        panelInner = theme.panelInner,
        panelLine = theme.panelLine,
        panelGlow = theme.panelGlow,
        accent = theme.panelLine,
    })
    drawPanelRule(x + 18, y + 48, w - 36, theme.panelLine)
    drawRuneBadge(active.icon or "help", x + 30, y + 28, 11, theme.chipFill, theme.chipLine)

    love.graphics.setFont(fonts.hud)
    setPaletteColor(theme.title)
    love.graphics.print(t(state, active.titleKey), x + 52, y + 16)
    setPaletteColor(theme.text)
    love.graphics.printf(body, x + 22, y + 58, w - 44, "left")

    local buttonW = cfg.buttonWidth
    local buttonH = cfg.buttonHeight
    local buttonX = x + w - buttonW - cfg.padX
    local buttonY = y + h - buttonH - cfg.padY
    ui.guide.button = { x = buttonX, y = buttonY, w = buttonW, h = buttonH }

    setPaletteColor(theme.buttonFill)
    love.graphics.rectangle("fill", buttonX, buttonY, buttonW, buttonH, 8, 8)
    setPaletteColor(theme.buttonLine)
    love.graphics.rectangle("line", buttonX, buttonY, buttonW, buttonH, 8, 8)
    setPaletteColor(theme.dim)
    love.graphics.printf(t(state, "guide.confirm"), buttonX, buttonY + 7, buttonW, "center")
end

function OverlayRenderer.drawHelpPanel(state, fonts)
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
    drawDecoratedPanel(x, y, w, h, {
        panelFill = theme.panelFill,
        panelInner = theme.panelInner,
        panelLine = theme.panelLine,
        panelGlow = theme.panelLine,
        accent = theme.panelLine,
    })

    love.graphics.setFont(fonts.big)
    setPaletteColor(theme.text)
    love.graphics.printf(t(state, "help.title"), x, y + 14, w, "center")
    drawPanelRule(x + 62, y + 52, w - 124, theme.panelLine)

    love.graphics.setFont(fonts.hud)
    setPaletteColor(theme.text)
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

    setPaletteColor(theme.dim)
    love.graphics.printf(
        t(state, "help.language", { language = Locale.ref("language." .. state.locale) }),
        x + 24,
        y + h - 78,
        w - 48,
        "left"
    )

    local chipX = x + 24
    local chipY = y + h - 42
    chipX = chipX + drawKeyChip(fonts.hud, chipX, chipY, "H", t(state, "help.close_label"), theme) + 16
    drawKeyChip(fonts.hud, chipX, chipY, "L", t(state, "help.toggle_language_label"), theme)
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
        spent = progress.spentPoints,
        evolution = Locale.ref(progress.evolutionKey),
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
    local h = 394
    local x = (sw - w) * 0.5
    local y = (sh - h) * 0.5
    local nextUnlock = MapSystem.getNextUnlockInfo(state.maps, state.meta.runStars or 0)
    local nextUnlockText
    if nextUnlock then
        nextUnlockText = t(state, "run_end.result.next_map", {
            map = Locale.ref(nextUnlock.nameKey),
            current = nextUnlock.current,
            required = nextUnlock.required,
        })
    else
        nextUnlockText = t(state, "run_end.result.all_maps")
    end

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
    love.graphics.printf(t(state, "run_end.result.grade", { grade = state.runGrade or "F" }), x + 36, y + 124, w - 72, "left")
    love.graphics.printf(t(state, "run_end.result.bonus_time", { time = state.runBonusTimeEarned or 0 }), x + 36, y + 154, w - 72, "left")
    drawRuneBadge("star", x + 48, y + 194, 9, { 0.16, 0.12, 0.08, 0.96 }, { 1.0, 0.84, 0.38, 0.98 })
    love.graphics.printf(t(state, "run_end.result.stars", { stars = state.runStarsEarned or 0 }), x + 66, y + 184, w - 102, "left")
    drawRuneBadge("star", x + 48, y + 224, 9, { 0.16, 0.12, 0.08, 0.96 }, { 1.0, 0.84, 0.38, 0.98 })
    love.graphics.printf(t(state, "run_end.result.total_stars", { stars = state.meta and state.meta.runStars or 0 }), x + 66, y + 214, w - 102, "left")
    love.graphics.printf(t(state, "run_end.result.current_essence", { essence = state.meta and state.meta.essence or 0 }), x + 36, y + 244, w - 72, "left")
    love.graphics.printf(t(state, "run_end.result.level", { level = state.nestProgress.level }), x + 36, y + 274, w - 72, "left")
    love.graphics.printf(nextUnlockText, x + 36, y + 304, w - 72, "left")
    love.graphics.printf(t(state, "run_end.result.evolution", { evolution = Locale.ref(state.nestProgress.evolutionKey) }), x + 36, y + 334, w - 72, "left")

    love.graphics.setColor(0.84, 0.9, 1.0)
    love.graphics.printf(t(state, "run_end.result.continue"), x, y + h - 42, w, "center")
end

function OverlayRenderer.drawRunChoiceOverlay(state, fonts, ui, assets)
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

    setPaletteColor(theme.overlay)
    love.graphics.rectangle("fill", 0, 0, sw, sh)
    love.graphics.setFont(fonts.big)
    setPaletteColor(theme.title)
    love.graphics.printf(t(state, "run_choice.title"), 0, y - 92, sw, "center")
    drawPanelRule(sw * 0.36, y - 52, sw * 0.28, C.HUD_THEME.accent)
    love.graphics.setFont(fonts.hud)
    setPaletteColor(theme.summary)
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

        setPaletteColor(C.HUD_THEME.text)
        love.graphics.printf(t(state, "rarity." .. card.rarity), x + 16, y + 22, cfg.cardWidth - 32, "center")

        setPaletteColor(C.HUD_THEME.dim)
        love.graphics.printf(t(state, card.nameKey), x + 18, y + 58, cfg.cardWidth - 36, "center")

        setPaletteColor(C.HUD_THEME.chipFill)
        love.graphics.rectangle("fill", x + 22, y + 88, 90, 24, 8, 8)
        setPaletteColor(palette.line)
        love.graphics.rectangle("line", x + 22, y + 88, 90, 24, 8, 8)
        setPaletteColor(C.HUD_THEME.text)
        love.graphics.printf(t(state, "category." .. card.category), x + 22, y + 93, 90, "center")

        drawRuneBadge(getCategorySymbol(card.category), x + cfg.cardWidth * 0.5, y + 132, 20, palette.inner, palette.line)

        setPaletteColor(C.HUD_THEME.text)
        love.graphics.printf(t(state, card.descKey), x + 26, y + 160, cfg.cardWidth - 52, "center")

        setPaletteColor(C.HUD_THEME.text)
        love.graphics.printf(t(state, "run_choice.click"), x + 18, y + cfg.cardHeight - 40, cfg.cardWidth - 36, "center")
    end
end

return OverlayRenderer
