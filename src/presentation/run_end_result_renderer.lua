local MapSystem = require("src.map_system")
local Meta = require("src.meta_system")
local Text = require("src.presentation.presentation_text")
local Ui = require("src.presentation.ui_primitives")

local RunEndResultRenderer = {}
local t = Text.text
local ref = Text.ref
local runReasonRef = Text.runReasonRef

local STAR_FILL = { 0.16, 0.12, 0.08, 0.96 }
local STAR_LINE = { 1.0, 0.84, 0.38, 0.98 }

local function drawResultLine(state, x, y, w, key, params)
    love.graphics.printf(t(state, key, params), x + 36, y, w - 72, "left")
end

local function drawStarLine(state, x, y, w, key, params)
    Ui.drawRuneBadge("star", x + 48, y + 10, 9, STAR_FILL, STAR_LINE)
    love.graphics.printf(t(state, key, params), x + 66, y, w - 102, "left")
end

function RunEndResultRenderer.draw(state, fonts)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local w = math.min(760, sw - 80)
    local h = 394
    local x = (sw - w) * 0.5
    local y = (sh - h) * 0.5
    local currentMap = MapSystem.getCurrentMap(state.maps)
    local currentMapBest = currentMap and Meta.getMapStars(state.meta, currentMap.id) or 0
    local totalStars = Meta.getTotalStars(state.meta)
    local maxStars = Meta.getMaxStars()
    local nextUnlock = MapSystem.getNextUnlockInfo(state.maps, totalStars)
    local nextUnlockText
    if nextUnlock then
        nextUnlockText = t(state, "run_end.result.next_map", {
            map = ref(nextUnlock.nameKey),
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
    drawResultLine(state, x, y + 86, w, "run_end.result.reason", { reason = runReasonRef(state.runEndedReason) })
    drawResultLine(state, x, y + 116, w, "run_end.result.bonus_time", { time = state.runBonusTimeEarned or 0 })
    drawStarLine(state, x, y + 146, w, "run_end.result.run_stars", { stars = state.runStarsEarned or 0 })
    drawStarLine(state, x, y + 176, w, "run_end.result.map_best", { best = currentMapBest })
    drawStarLine(state, x, y + 206, w, "run_end.result.total_stars", { stars = totalStars, max = maxStars })
    drawResultLine(state, x, y + 236, w, "run_end.result.current_essence", { essence = state.meta and state.meta.essence or 0 })
    drawResultLine(state, x, y + 266, w, "run_end.result.level", { level = state.nestProgress.level })
    love.graphics.printf(nextUnlockText, x + 36, y + 296, w - 72, "left")
    drawResultLine(state, x, y + 326, w, "run_end.result.evolution", { evolution = ref(state.nestProgress.evolutionKey) })

    love.graphics.setColor(0.84, 0.9, 1.0)
    love.graphics.printf(t(state, "run_end.result.continue"), x, y + h - 42, w, "center")
end

return RunEndResultRenderer
