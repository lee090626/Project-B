local C = require("src.constants")
local Player = require("src.player_controller")
local Food = require("src.food_system")
local MapSystem = require("src.map_system")
local Boss = require("src.boss_system")
local Meta = require("src.meta_system")
local Nest = require("src.nest_system")
local Save = require("src.save_system")
local BonusSchema = require("src.bonus_schema")
local PassiveCombat = require("src.application.passive_combat")
local Guide = require("src.application.guide_system")
local Mutation = require("src.mutation_system")
local RunEvent = require("src.run_event_system")
local StateFactory = require("src.game_state_factory")
local Snapshot = require("src.game_state_snapshot")

local GameState = {}

function GameState.setMessage(state, key, params)
    state.messageKey = key
    state.messageParams = params
    state.messageVersion = (state.messageVersion or 0) + 1
end

function GameState.clearMessage(state)
    state.messageKey = nil
    state.messageParams = nil
end

function GameState.setSaveStatus(state, key, params)
    state.lastSaveStatusKey = key
    state.lastSaveStatusParams = params
end

local function resetRunState(state)
    state.player = Player.new(nil)
    state.food = Food.new(nil)
    state.maps = MapSystem.new(nil)
    state.boss = Boss.new(nil)
    state.runMutations = Mutation.newRunState()
    state.runEssenceTotal = 0
    state.runBonusTimeEarned = 0
    state.runStarsEarned = 0
    state.runMapsUnlocked = false
    state.runGrade = "F"
    GameState.refreshDerivedState(state)
    GameState.normalizeProgression(state)
    state.runEvent = RunEvent.newRunState(MapSystem.getCurrentMap(state.maps))

    state.camera.x = 0
    state.camera.y = 0
    state.camera.zoom = 1.0

    state.runTimeLeft = state.runDuration
    state.runEnded = false
    state.runEndedReason = nil
    state.endingReached = false
    state.mode = "game"
    state.runEndTab = "meta"
    StateFactory.resetMetaTreeView(state)
    PassiveCombat.resetState(state)
    Guide.resetRuntime(state.guides)

    Mutation.grantChoices(state, math.max(1, state.nestBonuses.startingChoices or 0))
end

function GameState.new(loadResult, loadErr)
    local saved = loadResult or {}
    local state = StateFactory.new(loadResult, loadErr)
    PassiveCombat.resetState(state)

    GameState.refreshDerivedState(state)
    GameState.normalizeProgression(state)
    state.runTimeLeft = saved.runTimeLeft or state.runDuration

    if state.mode == "run_choice" or state.mode == "boss_arena" then
        state.mode = "game"
    end
    if state.boss.active then
        state.boss = Boss.new({ defeated = state.boss.defeated })
    end
    if state.runEnded and state.mode ~= "run_end_tree" and state.mode ~= "run_end_result" then
        state.mode = "run_end_result"
    end

    return state
end

function GameState.loadOrDefault()
    local loaded, err = Save.load()
    return GameState.new(loaded, err)
end

function GameState.refreshDerivedState(state)
    state.nestProgress = Nest.getProgress(state.nest)
    state.metaBonuses = Meta.computeBonuses(state.meta)
    state.nestBonuses = Nest.computeBonuses(state.nest)
    state.runOnlyBonuses = Mutation.buildRunBonuses(state.runMutations)
    state.bonuses = BonusSchema.toRuntime(
        BonusSchema.combineSources(state.metaBonuses, state.nestBonuses, state.runOnlyBonuses)
    )
    state.runDuration = C.RUN_TIME_LIMIT_SECONDS
end

function GameState.normalizeProgression(state)
    MapSystem.syncUnlocks(state.maps, state.meta.runStars or 0)
end

function GameState.startNewRun(state)
    resetRunState(state)
    if state.mode ~= "run_choice" then
        GameState.setMessage(state, "message.new_run_started")
    end
end

function GameState.endRun(state, reason)
    if state.runEnded then
        return false
    end

    state.runEnded = true
    state.runEndedReason = reason
    state.mode = "run_end_result"
    StateFactory.resetMetaTreeView(state)
    PassiveCombat.resetState(state)
    RunEvent.finalize(state)
    state.runMapsUnlocked = MapSystem.updateUnlocks(state.maps, state.meta.runStars or 0)

    state.meta.totalRuns = state.meta.totalRuns + 1
    if state.runMapsUnlocked then
        GameState.setMessage(state, "message.new_map_unlocked_from_stars")
    else
        GameState.setMessage(state, "message.run_ended")
    end
    return true
end

function GameState.tryBuyMetaUpgrade(state, index)
    if not state.runEnded then
        return false, "not_in_run_end", nil
    end

    local ok, err = Meta.tryBuy(state.meta, index)
    if not ok then
        return false, err, nil
    end

    GameState.refreshDerivedState(state)
    GameState.setMessage(state, "message.meta_upgrade_purchased")
    return true, nil, nil
end

function GameState.getMetaUpgradeRows(state)
    return Meta.getUpgradeInfo(state.meta)
end

function GameState.getNestUpgradeRows(state)
    return Nest.getUpgradeRows(state.nest)
end

function GameState.tryBuyNestUpgrade(state, key)
    if not state.runEnded then
        return false, "not_in_run_end"
    end

    local ok, err = Nest.tryUpgrade(state.nest, key)
    if not ok then
        return false, err
    end

    GameState.refreshDerivedState(state)
    return true, nil
end

function GameState.checkEnding(state)
    if state.endingReached then
        return true
    end

    local allMaps = MapSystem.allMapsUnlocked(state.maps)
    local allSkills = Meta.allUnlocked(state.meta)
    local bossDefeated = state.boss.defeated

    if allMaps and allSkills and bossDefeated then
        state.endingReached = true
        state.events[#state.events + 1] = "Ending reached: All skills + all maps + boss defeated"
        return true
    end
    return false
end

function GameState.saveNow(state, _reason)
    local payload = Snapshot.build(state)
    local ok, err = Save.write(payload)
    if ok then
        GameState.setSaveStatus(state, "save_status.saved")
        return true
    end
    GameState.setSaveStatus(state, "save_status.failed", { error = tostring(err) })
    return false
end

return GameState
