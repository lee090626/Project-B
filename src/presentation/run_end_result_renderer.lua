local MapSystem = require("src.map_system")
local Text = require("src.presentation.presentation_text")
local Ui = require("src.presentation.ui_primitives")

local RunEndResultRenderer = {}
local t = Text.text
local ref = Text.ref
local runReasonRef = Text.runReasonRef

function RunEndResultRenderer.draw(state, fonts)
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
    love.graphics.printf(t(state, "run_end.result.reason", { reason = runReasonRef(state.runEndedReason) }), x + 36, y + 94, w - 72, "left")
    love.graphics.printf(t(state, "run_end.result.grade", { grade = state.runGrade or "F" }), x + 36, y + 124, w - 72, "left")
    love.graphics.printf(t(state, "run_end.result.bonus_time", { time = state.runBonusTimeEarned or 0 }), x + 36, y + 154, w - 72, "left")
    Ui.drawRuneBadge("star", x + 48, y + 194, 9, { 0.16, 0.12, 0.08, 0.96 }, { 1.0, 0.84, 0.38, 0.98 })
    love.graphics.printf(t(state, "run_end.result.stars", { stars = state.runStarsEarned or 0 }), x + 66, y + 184, w - 102, "left")
    Ui.drawRuneBadge("star", x + 48, y + 224, 9, { 0.16, 0.12, 0.08, 0.96 }, { 1.0, 0.84, 0.38, 0.98 })
    love.graphics.printf(t(state, "run_end.result.total_stars", { stars = state.meta and state.meta.runStars or 0 }), x + 66, y + 214, w - 102, "left")
    love.graphics.printf(t(state, "run_end.result.current_essence", { essence = state.meta and state.meta.essence or 0 }), x + 36, y + 244, w - 72, "left")
    love.graphics.printf(t(state, "run_end.result.level", { level = state.nestProgress.level }), x + 36, y + 274, w - 72, "left")
    love.graphics.printf(nextUnlockText, x + 36, y + 304, w - 72, "left")
    love.graphics.printf(t(state, "run_end.result.evolution", { evolution = ref(state.nestProgress.evolutionKey) }), x + 36, y + 334, w - 72, "left")

    love.graphics.setColor(0.84, 0.9, 1.0)
    love.graphics.printf(t(state, "run_end.result.continue"), x, y + h - 42, w, "center")
end

return RunEndResultRenderer
