local C = require("src.constants")
local Food = require("src.food_system")
local Mutation = require("src.mutation_system")

local RunEvent = {}

local function setMessage(state, key, params)
    state.messageKey = key
    state.messageParams = params
    state.messageVersion = (state.messageVersion or 0) + 1
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function getProfile(state)
    local mapData = C.MAPS[state.maps.currentMapId]
    return mapData and mapData.eventProfile or nil
end

local function getBonusRewards(state)
    local mapData = C.MAPS[state.maps.currentMapId]
    return mapData and mapData.bonusTimeRewards or C.RUN_EVENTS.fallbackBonusTimeRewards
end

local function spawnPositionNearPlayer(state, radius)
    local player = state.player
    local angle = love.math.random() * math.pi * 2
    local distance = C.RUN_EVENTS.spawnDistanceMin + love.math.random() * C.RUN_EVENTS.spawnDistanceRange
    local edge = C.RUN_EVENTS.spawnEdgePadding
    local x = clamp(player.x + math.cos(angle) * distance, edge + radius, C.WORLD_WIDTH - edge - radius)
    local y = clamp(player.y + math.sin(angle) * distance, edge + radius, C.WORLD_HEIGHT - edge - radius)
    return x, y
end

local function spawnTarget(state, kind, spec)
    local x, y = spawnPositionNearPlayer(state, spec.radius or C.RUN_EVENTS.fallbackTargetRadius)
    local eventState = state.runEvent
    eventState.nextTargetId = (eventState.nextTargetId or 0) + 1
    local target = Food.spawnEventTarget(state.food, {
        x = x,
        y = y,
        tier = spec.tier,
        mapId = state.maps.currentMapId,
        radius = spec.radius,
        hp = spec.hp,
        essence = spec.essence,
        speed = spec.speed,
        moveStyle = spec.moveStyle,
        labelKey = spec.labelKey,
        eventKind = kind,
        eventId = eventState.nextTargetId,
    })
    eventState.activeTargetKind = kind
    eventState.activeTargetId = target.eventId
    setMessage(state, kind == "mid" and "message.mid_event_started" or "message.final_event_started")
    return target
end

function RunEvent.newRunState(mapData)
    local profile = mapData and mapData.eventProfile or {}
    return {
        elapsed = 0,
        midTime = profile.midTime or C.RUN_EVENTS.fallbackMidTime,
        finalTime = profile.finalTime or C.RUN_EVENTS.fallbackFinalTime,
        midTriggered = false,
        finalTriggered = false,
        midCompleted = false,
        finalCompleted = false,
        activeTargetKind = nil,
        activeTargetId = nil,
        nextTargetId = 0,
        bonusTimeEarned = 0,
        starsEarned = 0,
        grade = "F",
        finalized = false,
    }
end

function RunEvent.spawnEventTarget(state, kind)
    local profile = getProfile(state)
    if not profile then
        return nil
    end

    local spec = kind == "mid" and profile.midTarget or profile.finalTarget
    if not spec then
        return nil
    end
    return spawnTarget(state, kind, spec)
end

function RunEvent.clearActiveTarget(state)
    local eventState = state.runEvent
    if not eventState or not eventState.activeTargetId then
        return
    end
    Food.removeEventTarget(state.food, eventState.activeTargetId)
    eventState.activeTargetKind = nil
    eventState.activeTargetId = nil
end

function RunEvent.awardBonusTime(state, sourceKey)
    local eventState = state.runEvent
    if not eventState then
        return 0
    end

    local rewards = getBonusRewards(state)
    local base = rewards[sourceKey] or 0
    if base <= 0 then
        return 0
    end

    if sourceKey == "mid" then
        base = base + (state.bonuses.midBonusTime or 0)
    elseif sourceKey == "final" then
        base = base + (state.bonuses.finalBonusTime or 0)
    end

    local cap = C.RUN_EVENTS.bonusTimeCap + (state.bonuses.bonusTimeCap or 0)
    local remaining = math.max(0, cap - (eventState.bonusTimeEarned or 0))
    local granted = math.min(base, remaining)
    if granted <= 0 then
        return 0
    end

    state.runTimeLeft = state.runTimeLeft + granted
    eventState.bonusTimeEarned = (eventState.bonusTimeEarned or 0) + granted
    state.runBonusTimeEarned = eventState.bonusTimeEarned
    return granted
end

function RunEvent.resolveEventTargetKill(state, item)
    local eventState = state.runEvent
    if not eventState or not item or not item.eventTarget then
        return false
    end
    if item.eventId ~= eventState.activeTargetId or item.eventKind ~= eventState.activeTargetKind then
        return false
    end

    local kind = item.eventKind
    eventState.activeTargetId = nil
    eventState.activeTargetKind = nil

    if kind == "mid" and not eventState.midCompleted then
        eventState.midCompleted = true
        eventState.starsEarned = eventState.starsEarned + 1
        RunEvent.awardBonusTime(state, "mid")
        Mutation.gainEssenceAndCheckLevel(state, item.essence * C.RUN_EVENTS.midEssenceMultiplier)
        Mutation.grantChoices(state, C.RUN_EVENTS.midChoiceReward)
        setMessage(state, "message.mid_event_cleared")
        return true
    end

    if kind == "final" and not eventState.finalCompleted then
        eventState.finalCompleted = true
        eventState.starsEarned = eventState.starsEarned + 1
        RunEvent.awardBonusTime(state, "final")
        Mutation.gainEssenceAndCheckLevel(state, item.essence * C.RUN_EVENTS.finalEssenceMultiplier)
        setMessage(state, "message.final_event_cleared")
        return true
    end

    return false
end

function RunEvent.tick(state, dt)
    local eventState = state.runEvent
    if not eventState or state.mode ~= "game" or state.runEnded then
        return
    end

    eventState.elapsed = eventState.elapsed + dt
    local profile = getProfile(state)
    if not profile then
        return
    end

    if not eventState.midTriggered and eventState.elapsed >= eventState.midTime then
        eventState.midTriggered = true
        RunEvent.spawnEventTarget(state, "mid")
    end

    if not eventState.finalTriggered and eventState.elapsed >= eventState.finalTime then
        if eventState.activeTargetKind == "mid" then
            RunEvent.clearActiveTarget(state)
        end
        eventState.finalTriggered = true
        if state.runTimeLeft < (state.bonuses.finalWindowMin or 0) then
            state.runTimeLeft = state.bonuses.finalWindowMin
        end
        RunEvent.spawnEventTarget(state, "final")
    end
end

function RunEvent.getHudState(state)
    local eventState = state.runEvent
    if not eventState then
        return nil
    end

    local activeLabelKey
    if eventState.activeTargetKind and eventState.activeTargetId then
        for _, item in ipairs(state.food.list or {}) do
            if item.eventTarget and item.eventId == eventState.activeTargetId then
                activeLabelKey = item.eventLabelKey
                break
            end
        end
    end

    return {
        starsEarned = eventState.starsEarned or 0,
        activeKind = eventState.activeTargetKind,
        activeLabelKey = activeLabelKey,
        bonusTimeEarned = eventState.bonusTimeEarned or 0,
        midCompleted = eventState.midCompleted,
        finalCompleted = eventState.finalCompleted,
    }
end

function RunEvent.finalize(state)
    local eventState = state.runEvent
    if not eventState or eventState.finalized then
        return state.runGrade or "F", 0
    end

    RunEvent.clearActiveTarget(state)

    local grade = "F"
    if eventState.midCompleted and eventState.finalCompleted then
        if state.runTimeLeft >= C.RUN_EVENTS.sGradeRemainingTime then
            grade = "S"
        else
            grade = "A"
        end
    elseif eventState.finalCompleted then
        grade = "B"
    elseif eventState.midCompleted then
        grade = "C"
    end

    local stars = eventState.starsEarned or 0
    if grade == "S" then
        stars = stars + 1
    end

    eventState.finalized = true
    eventState.grade = grade
    state.runGrade = grade
    state.runStarsEarned = stars
    state.runBonusTimeEarned = eventState.bonusTimeEarned or 0
    state.meta.runStars = math.max(0, math.floor((state.meta.runStars or 0) + stars))
    return grade, stars
end

return RunEvent
