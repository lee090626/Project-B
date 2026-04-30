local C = require("src.constants")
local GameState = require("src.game_state")
local MapSystem = require("src.map_system")
local Boss = require("src.boss_system")
local Locale = require("src.locale")
local PassiveCombat = require("src.application.passive_combat")
local Guide = require("src.application.guide_system")
local Mutation = require("src.mutation_system")
local Feedback = require("src.application.game_service_feedback")

local CommandService = {}

function CommandService.loadState()
    local state = GameState.loadOrDefault()
    state.camera.zoom = 1.0
    Feedback.refreshWindowTitle(state)
    Guide.tick(state)
    return state
end

function CommandService.reloadState()
    local state = CommandService.loadState()
    Feedback.setMessage(state, "message.save_reloaded")
    return state
end

function CommandService.resetAllData()
    love.filesystem.remove(C.SAVE_FILE)
    love.filesystem.remove(C.BACKUP_FILE)

    local state = CommandService.loadState()
    Feedback.setMessage(state, "message.all_progress_reset")
    Feedback.saveWithFeedback(state, "reset-all")
    return state
end

function CommandService.save(state, reason)
    if state.mode == "run_choice" then
        Feedback.setMessage(state, "message.save_delayed_until_choice_ends")
        return false
    end
    if state.mode == "boss_arena" then
        Feedback.setMessage(state, "message.save_delayed_during_boss_arena")
        return false
    end
    Feedback.saveWithFeedback(state, reason)
    return true
end

function CommandService.toggleHelp(state)
    state.showHelp = not state.showHelp
end

function CommandService.cycleLocale(state)
    state.locale = Locale.next(state.locale)
    Feedback.refreshWindowTitle(state)
    Feedback.setMessage(state, "message.language_changed", {
        language = Feedback.nestedKey("language." .. state.locale),
    })
end

function CommandService.trySwitchMap(state, mapId)
    if state.runEnded or state.mode == "boss_arena" then
        return false
    end
    if not C.MAPS[mapId] then
        return false
    end

    local switched = MapSystem.trySetCurrent(state.maps, mapId)
    if switched then
        Feedback.saveWithFeedback(state, "map-switch")
        Feedback.setMessage(state, "message.map_changed", {
            mapName = Feedback.nestedKey(C.MAPS[mapId].nameKey),
        })
    end
    return switched
end

function CommandService.tryEnterBoss(state)
    if state.runEnded or state.mode == "boss_arena" then
        return false
    end

    if Boss.canEnter(state) then
        if not Feedback.saveWithFeedback(state, "boss-enter-prep") then
            return false
        end
        local entered = Boss.enter(state)
        if entered then
            PassiveCombat.resetState(state)
            Feedback.setMessage(state, "message.final_boss_engaged")
        end
        return entered
    end
    return false
end

function CommandService.tryBuyMetaUpgrade(state, index)
    local ok, err = GameState.tryBuyMetaUpgrade(state, index)
    if ok then
        Feedback.setMessage(state, "message.meta_upgrade_purchased")
        Feedback.saveWithFeedback(state, "meta-upgrade")
    else
        Feedback.setMessage(state, "message.meta_upgrade_failed", {
            error = Feedback.localizedErrorRef(err == "not_in_run_end" and "generic" or "meta", err),
        })
    end
    return ok
end

function CommandService.tryBuyNestUpgrade(state, key)
    local ok, err = GameState.tryBuyNestUpgrade(state, key)
    if ok then
        Feedback.setMessage(state, "message.nest_upgrade_purchased")
        Feedback.saveWithFeedback(state, "nest-upgrade")
    else
        Feedback.setMessage(state, "message.nest_upgrade_failed", {
            error = Feedback.localizedErrorRef(err == "not_in_run_end" and "generic" or "nest", err),
        })
    end
    return ok
end

function CommandService.restartRun(state)
    GameState.startNewRun(state)
    Guide.tick(state)
    Feedback.saveWithFeedback(state, "run-restart")
end

function CommandService.openRunEndTree(state)
    if not state.runEnded then
        return
    end
    state.runEndTab = "meta"
    state.mode = "run_end_tree"
    Guide.tick(state)
end

function CommandService.openMetaTab(state)
    state.metaTreeView.pointerDown = false
    state.metaTreeView.moved = false
    state.runEndTab = "meta"
end

function CommandService.openNestTab(state)
    state.metaTreeView.pointerDown = false
    state.metaTreeView.moved = false
    state.runEndTab = "nest"
end

function CommandService.chooseRunMutation(state, choiceIndex)
    local ok, err = Mutation.applyChoice(state, choiceIndex)
    if not ok then
        Feedback.setMessage(state, "message.instinct_choice_failed", {
            error = Feedback.localizedErrorRef("mutation", err),
        })
        return false
    end

    GameState.refreshDerivedState(state)
    if state.runMutations.activeChoices then
        state.mode = "run_choice"
        Feedback.setMessage(state, "message.choose_another_instinct")
    else
        state.mode = "game"
        Feedback.setMessage(state, "message.instinct_chosen")
    end
    Guide.tick(state)
    return true
end

function CommandService.dismissGuide(state)
    Guide.dismiss(state)
    Guide.tick(state)
end

return CommandService
