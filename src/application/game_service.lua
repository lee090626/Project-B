local C = require("src.constants")
local GameState = require("src.game_state")
local MapSystem = require("src.map_system")
local Boss = require("src.boss_system")
local PassiveCombat = require("src.application.passive_combat")
local RunLoop = require("src.application.run_loop")
local MetaTreeController = require("src.application.meta_tree_controller")
local Mutation = require("src.mutation_system")

local Service = {}

local function setMessage(state, text)
    state.message = text
    state.uiLastMessage = text
    state.uiToastTimer = C.RUN_HUD_UI.toastDuration
end

local function saveWithFeedback(state, reason)
    if state.mode == "run_choice" then
        state.lastSaveStatus = "save delayed: instinct choice"
        return false
    end
    local ok = GameState.saveNow(state, reason)
    if ok then
        state.uiAutosaveTimer = C.RUN_HUD_UI.autosaveDuration
    end
    return ok
end

function Service.loadState()
    local state = GameState.loadOrDefault()
    state.camera.zoom = 1.0
    return state
end

function Service.reloadState()
    local state = Service.loadState()
    setMessage(state, "Save reloaded")
    return state
end

function Service.resetAllData()
    love.filesystem.remove(C.SAVE_FILE)
    love.filesystem.remove(C.BACKUP_FILE)

    local state = Service.loadState()
    setMessage(state, "All progress reset")
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

    if state.message and state.uiLastMessage ~= state.message then
        state.uiLastMessage = state.message
        state.uiToastTimer = C.RUN_HUD_UI.toastDuration
    end
    if state.message and state.uiToastTimer <= 0 then
        state.message = nil
    end

    if state.mode ~= "run_choice" and not state.runEnded then
        state.runTimeLeft = math.max(0, state.runTimeLeft - dt)
        if state.runTimeLeft <= 0 then
            if GameState.endRun(state, "time") then
                saveWithFeedback(state, "run-timeout")
            end
        end
    end

    if state.mode == "game" and not state.runEnded then
        local result = RunLoop.tickGameplay(state, dt)
        if result.mapUnlocked then
            setMessage(state, "New map unlocked from skill tree")
        end
        if result.bossDefeated then
            saveWithFeedback(state, "boss-defeated")
        end
        if result.runEndedReason == "victory" then
            saveWithFeedback(state, "run-victory")
        end
    end

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
        setMessage(state, "Save delayed until instinct choice ends")
        return false
    end
    saveWithFeedback(state, reason)
    return true
end

function Service.toggleHelp(state)
    state.showHelp = not state.showHelp
end

function Service.trySwitchMap(state, mapId)
    if state.runEnded then
        return false
    end
    if not C.MAPS[mapId] then
        return false
    end

    local switched = MapSystem.trySetCurrent(state.maps, mapId)
    if switched then
        saveWithFeedback(state, "map-switch")
        setMessage(state, "Map changed to " .. C.MAPS[mapId].name)
    end
    return switched
end

function Service.tryEnterBoss(state)
    if state.runEnded then
        return false
    end

    if Boss.canEnter(state) then
        local entered = Boss.enter(state)
        if entered then
            saveWithFeedback(state, "boss-enter")
            setMessage(state, "Final boss engaged")
        end
        return entered
    end
    return false
end

function Service.tryBuyMetaUpgrade(state, index)
    local ok, err, result = GameState.tryBuyMetaUpgrade(state, index)
    if ok then
        if result and result.mapUnlocked then
            setMessage(state, "Meta upgrade purchased. New map unlocked")
        end
        saveWithFeedback(state, "meta-upgrade")
    else
        setMessage(state, "Meta upgrade failed: " .. tostring(err))
    end
    return ok
end

function Service.tryBuyNestUpgrade(state, key)
    local ok, err = GameState.tryBuyNestUpgrade(state, key)
    if ok then
        setMessage(state, "Nest upgrade purchased")
        saveWithFeedback(state, "nest-upgrade")
    else
        setMessage(state, "Nest upgrade failed: " .. tostring(err))
    end
    return ok
end

function Service.restartRun(state)
    GameState.startNewRun(state)
    saveWithFeedback(state, "run-restart")
end

function Service.openRunEndTree(state)
    if not state.runEnded then
        return
    end
    state.runEndTab = "meta"
    state.mode = "run_end_tree"
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
        setMessage(state, "Instinct choice failed: " .. tostring(err))
        return false
    end

    GameState.refreshDerivedState(state)
    if state.runMutations.activeChoices then
        state.mode = "run_choice"
        setMessage(state, "Choose another instinct")
    else
        state.mode = "game"
        setMessage(state, "Instinct chosen")
    end
    return true
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
