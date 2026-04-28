local C = require("src.constants")
local GameState = require("src.game_state")
local MapSystem = require("src.map_system")
local Boss = require("src.boss_system")
local Locale = require("src.locale")
local PassiveCombat = require("src.application.passive_combat")
local Guide = require("src.application.guide_system")
local RunLoop = require("src.application.run_loop")
local MetaTreeController = require("src.application.meta_tree_controller")
local Mutation = require("src.mutation_system")

local Service = {}

local function nestedKey(key)
    return { key = key }
end

local function setMessage(state, key, params)
    GameState.setMessage(state, key, params)
    state.uiToastTimer = C.RUN_HUD_UI.toastDuration
end

local function refreshWindowTitle(state)
    love.window.setTitle(Locale.text(state.locale, "app.title"))
end

local function saveWithFeedback(state, reason)
    if state.mode == "run_choice" then
        GameState.setSaveStatus(state, "save_status.delayed_choice")
        return false
    end
    if state.mode == "boss_arena" then
        GameState.setSaveStatus(state, "save_status.delayed_boss")
        return false
    end
    local ok = GameState.saveNow(state, reason)
    if ok then
        state.uiAutosaveTimer = C.RUN_HUD_UI.autosaveDuration
    end
    return ok
end

local function localizedErrorRef(domain, code)
    if domain == "generic" then
        return nestedKey("error.generic." .. code)
    end
    return nestedKey("error." .. domain .. "." .. code)
end

local function handleLoopResult(state, result)
    if result.bossDefeated and not result.runEndedReason then
        setMessage(state, "message.final_boss_defeated")
        saveWithFeedback(state, "boss-defeated")
        return
    end

    if not result.runEndedReason then
        return
    end

    if result.runEndedReason == "victory" then
        saveWithFeedback(state, "run-victory")
    elseif result.runEndedReason == "boss_failed" then
        saveWithFeedback(state, "boss-failed")
    else
        saveWithFeedback(state, "run-ended")
    end
end

function Service.loadState()
    local state = GameState.loadOrDefault()
    state.camera.zoom = 1.0
    refreshWindowTitle(state)
    Guide.tick(state)
    return state
end

function Service.reloadState()
    local state = Service.loadState()
    setMessage(state, "message.save_reloaded")
    return state
end

function Service.resetAllData()
    love.filesystem.remove(C.SAVE_FILE)
    love.filesystem.remove(C.BACKUP_FILE)

    local state = Service.loadState()
    setMessage(state, "message.all_progress_reset")
    saveWithFeedback(state, "reset-all")
    return state
end

function Service.tick(state, dt)
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
                saveWithFeedback(state, "run-timeout")
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
        saveWithFeedback(state, "autosave")
        state.autosaveTimer = C.AUTOSAVE_INTERVAL
    end
end

function Service.save(state, reason)
    if state.mode == "run_choice" then
        setMessage(state, "message.save_delayed_until_choice_ends")
        return false
    end
    if state.mode == "boss_arena" then
        setMessage(state, "message.save_delayed_during_boss_arena")
        return false
    end
    saveWithFeedback(state, reason)
    return true
end

function Service.toggleHelp(state)
    state.showHelp = not state.showHelp
end

function Service.cycleLocale(state)
    state.locale = Locale.next(state.locale)
    refreshWindowTitle(state)
    setMessage(state, "message.language_changed", {
        language = nestedKey("language." .. state.locale),
    })
end

function Service.trySwitchMap(state, mapId)
    if state.runEnded or state.mode == "boss_arena" then
        return false
    end
    if not C.MAPS[mapId] then
        return false
    end

    local switched = MapSystem.trySetCurrent(state.maps, mapId)
    if switched then
        saveWithFeedback(state, "map-switch")
        setMessage(state, "message.map_changed", {
            mapName = nestedKey(C.MAPS[mapId].nameKey),
        })
    end
    return switched
end

function Service.tryEnterBoss(state)
    if state.runEnded or state.mode == "boss_arena" then
        return false
    end

    if Boss.canEnter(state) then
        if not saveWithFeedback(state, "boss-enter-prep") then
            return false
        end
        local entered = Boss.enter(state)
        if entered then
            PassiveCombat.resetState(state)
            setMessage(state, "message.final_boss_engaged")
        end
        return entered
    end
    return false
end

function Service.tryBuyMetaUpgrade(state, index)
    local ok, err = GameState.tryBuyMetaUpgrade(state, index)
    if ok then
        setMessage(state, "message.meta_upgrade_purchased")
        saveWithFeedback(state, "meta-upgrade")
    else
        setMessage(state, "message.meta_upgrade_failed", {
            error = localizedErrorRef(err == "not_in_run_end" and "generic" or "meta", err),
        })
    end
    return ok
end

function Service.tryBuyNestUpgrade(state, key)
    local ok, err = GameState.tryBuyNestUpgrade(state, key)
    if ok then
        setMessage(state, "message.nest_upgrade_purchased")
        saveWithFeedback(state, "nest-upgrade")
    else
        setMessage(state, "message.nest_upgrade_failed", {
            error = localizedErrorRef(err == "not_in_run_end" and "generic" or "nest", err),
        })
    end
    return ok
end

function Service.restartRun(state)
    GameState.startNewRun(state)
    Guide.tick(state)
    saveWithFeedback(state, "run-restart")
end

function Service.openRunEndTree(state)
    if not state.runEnded then
        return
    end
    state.runEndTab = "meta"
    state.mode = "run_end_tree"
    Guide.tick(state)
end

function Service.openMetaTab(state)
    state.metaTreeView.pointerDown = false
    state.metaTreeView.moved = false
    state.runEndTab = "meta"
end

function Service.openNestTab(state)
    state.metaTreeView.pointerDown = false
    state.metaTreeView.moved = false
    state.runEndTab = "nest"
end

function Service.chooseRunMutation(state, choiceIndex)
    local ok, err = Mutation.applyChoice(state, choiceIndex)
    if not ok then
        setMessage(state, "message.instinct_choice_failed", {
            error = localizedErrorRef("mutation", err),
        })
        return false
    end

    GameState.refreshDerivedState(state)
    if state.runMutations.activeChoices then
        state.mode = "run_choice"
        setMessage(state, "message.choose_another_instinct")
    else
        state.mode = "game"
        setMessage(state, "message.instinct_chosen")
    end
    Guide.tick(state)
    return true
end

function Service.dismissGuide(state)
    Guide.dismiss(state)
    Guide.tick(state)
end

function Service.metaUpgradeIndexAtScreen(state, sx, sy)
    return MetaTreeController.nodeAtScreen(state, sx, sy)
end

function Service.metaTreeScreenToWorld(state, sx, sy)
    return MetaTreeController.screenToWorld(state, sx, sy)
end

function Service.metaTreeNodeAtScreen(state, sx, sy)
    return MetaTreeController.nodeAtScreen(state, sx, sy)
end

function Service.panMetaTree(state, dx, dy)
    MetaTreeController.pan(state, dx, dy)
end

function Service.zoomMetaTree(state, wheelY)
    MetaTreeController.zoom(state, wheelY)
end

function Service.beginMetaTreePointer(state, x, y)
    MetaTreeController.beginPointer(state, x, y)
end

function Service.updateMetaTreePointer(state, _, _, dx, dy)
    MetaTreeController.updatePointer(state, nil, nil, dx, dy)
end

function Service.endMetaTreePointer(state, x, y)
    return MetaTreeController.endPointer(state, x, y)
end

return Service
