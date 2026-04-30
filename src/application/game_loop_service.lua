local C = require("src.constants")
local GameState = require("src.game_state")
local PassiveCombat = require("src.application.passive_combat")
local Guide = require("src.application.guide_system")
local RunLoop = require("src.application.run_loop")
local Feedback = require("src.application.game_service_feedback")

local LoopService = {}

local function handleLoopResult(state, result)
    if result.bossDefeated and not result.runEndedReason then
        Feedback.setMessage(state, "message.final_boss_defeated")
        Feedback.saveWithFeedback(state, "boss-defeated")
        return
    end

    if not result.runEndedReason then
        return
    end

    if result.runEndedReason == "victory" then
        Feedback.saveWithFeedback(state, "run-victory")
    elseif result.runEndedReason == "boss_failed" then
        Feedback.saveWithFeedback(state, "boss-failed")
    else
        Feedback.saveWithFeedback(state, "run-ended")
    end
end

function LoopService.tick(state, dt)
    state.totalPlayTime = state.totalPlayTime + dt
    state.uiToastTimer = math.max(0, state.uiToastTimer - dt)
    state.uiAutosaveTimer = math.max(0, state.uiAutosaveTimer - dt)
    if state.mode ~= "run_choice" then
        PassiveCombat.tickFx(state, dt)
    end

    if state.messageKey and state.uiLastMessageVersion ~= state.messageVersion then
        state.uiLastMessageVersion = state.messageVersion
        state.uiToastTimer = C.RUN_HUD_UI.toastDuration
    end
    if state.messageKey and state.uiToastTimer <= 0 then
        GameState.clearMessage(state)
    end

    if state.mode ~= "run_choice" and state.mode ~= "boss_arena" and not state.runEnded then
        state.runTimeLeft = math.max(0, state.runTimeLeft - dt)
        if state.runTimeLeft <= 0 then
            if GameState.endRun(state, "time") then
                Feedback.saveWithFeedback(state, "run-timeout")
            end
        end
    end

    if state.mode == "game" and not state.runEnded then
        local result = RunLoop.tickGameplay(state, dt)
        handleLoopResult(state, result)
    elseif state.mode == "boss_arena" and not state.runEnded then
        local result = RunLoop.tickBossArena(state, dt)
        handleLoopResult(state, result)
    end

    Guide.tick(state)

    if state.mode == "run_choice" then
        return
    end

    state.autosaveTimer = state.autosaveTimer - dt
    if state.autosaveTimer <= 0 then
        Feedback.saveWithFeedback(state, "autosave")
        state.autosaveTimer = C.AUTOSAVE_INTERVAL
    end
end

return LoopService
