local MapSystem = require("src.map_system")
local Meta = require("src.meta_system")
local Text = require("src.presentation.presentation_text")

local Presenter = {}
local ref = Text.ref

local TONE_BY_REASON = {
    time = "time",
    boss_failed = "boss_failed",
    victory = "victory",
}

local function normalizeReason(reason)
    if TONE_BY_REASON[reason] then
        return reason
    end
    return "unknown"
end

local function formatProgress(current, required)
    return string.format("%d/%d", math.max(0, current or 0), math.max(0, required or 0))
end

local function buildCallout(state, reason, stars)
    if reason == "victory" or state.endingReached then
        return "run_end.status.callout.victory", nil
    end
    if state.runMapsUnlocked then
        return "run_end.status.callout.new_map", nil
    end
    if state.runStarsImproved then
        return "run_end.status.callout.best_improved", { stars = stars }
    end
    if stars > 0 then
        return "run_end.status.callout.stars_secured", { stars = stars }
    end
    return "run_end.status.callout.no_stars", nil
end

local function buildNextUnlock(state, totalStars)
    local nextUnlock = MapSystem.getNextUnlockInfo(state.maps, totalStars)
    if not nextUnlock then
        return {
            complete = true,
            labelKey = "run_end.status.next.all_maps",
            valueKey = "run_end.result.all_maps",
            progress = 1,
        }
    end

    local required = math.max(1, nextUnlock.required or 0)
    return {
        complete = false,
        labelKey = "run_end.status.next.map",
        labelParams = { map = ref(nextUnlock.nameKey) },
        value = formatProgress(nextUnlock.current, nextUnlock.required),
        progress = math.max(0, math.min(1, (nextUnlock.current or 0) / required)),
    }
end

function Presenter.build(state)
    local reason = normalizeReason(state.runEndedReason)
    local currentMap = MapSystem.getCurrentMap(state.maps)
    local currentMapBest = currentMap and Meta.getMapStars(state.meta, currentMap.id) or 0
    local totalStars = Meta.getTotalStars(state.meta)
    local maxStars = Meta.getMaxStars()
    local runStars = math.max(0, math.min(3, math.floor(state.runStarsEarned or 0)))
    local calloutKey, calloutParams = buildCallout(state, reason, runStars)
    local nestProgress = state.nestProgress or {}

    return {
        reason = reason,
        tone = TONE_BY_REASON[reason] or "time",
        titleKey = "run_end.status.title." .. reason,
        subtitleKey = "run_end.status.subtitle." .. reason,
        calloutKey = calloutKey,
        calloutParams = calloutParams,
        stars = {
            earned = runStars,
            max = 3,
            mapBest = currentMapBest,
            total = totalStars,
            totalMax = maxStars,
        },
        nextUnlock = buildNextUnlock(state, totalStars),
        stats = {
            {
                labelKey = "run_end.status.stat.essence",
                value = state.meta and state.meta.essence or 0,
                icon = "essence",
            },
            {
                labelKey = "run_end.status.stat.level",
                value = nestProgress.level or 0,
                icon = "level",
            },
            {
                labelKey = "run_end.status.stat.evolution",
                valueRef = ref(nestProgress.evolutionKey or "evolution.stage.1"),
                icon = "instinct",
            },
            {
                labelKey = "run_end.status.stat.total_stars",
                value = formatProgress(totalStars, maxStars),
                icon = "star",
            },
        },
    }
end

return Presenter
