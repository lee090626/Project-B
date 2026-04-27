local C = require("src.constants")
local Player = require("src.player_controller")
local Food = require("src.food_system")
local MapSystem = require("src.map_system")
local Boss = require("src.boss_system")
local Meta = require("src.meta_system")
local Nest = require("src.nest_system")
local Save = require("src.save_system")
local PassiveCombat = require("src.application.passive_combat")
local Mutation = require("src.mutation_system")

local GameState = {}

local BONUS_KEYS = {
    "speed",
    "reach",
    "magnet",
    "contactBite",
    "rareBonus",
    "eliteBonus",
    "spawnRate",
    "spawnCap",
    "lightningEnabled",
    "lightningDamage",
    "lightningChain",
    "lightningIntervalCut",
    "fireballEnabled",
    "fireballDamage",
    "fireballCount",
    "fireballRadius",
    "fireballIntervalCut",
    "fireballSplit",
    "frostEnabled",
    "frostDamage",
    "frostRadius",
    "frostSlow",
    "frostDuration",
    "frostIntervalCut",
}

local MULT_KEYS = {
    essenceMult = true,
    rareValue = true,
    eliteValue = true,
}

local function combineBonuses(metaBonuses, nestBonuses, runOnlyBonuses)
    local out = {
        essenceMult = 1,
        rareValue = 1,
        eliteValue = 1,
    }

    for _, key in ipairs(BONUS_KEYS) do
        out[key] = (metaBonuses[key] or 0) + (nestBonuses[key] or 0) + (runOnlyBonuses[key] or 0)
    end

    for key in pairs(MULT_KEYS) do
        out[key] = 1
            + ((metaBonuses[key] or 1) - 1)
            + ((nestBonuses[key] or 1) - 1)
            + ((runOnlyBonuses[key] or 1) - 1)
    end

    return out
end

local function resetMetaTreeView(state)
    state.metaTreeView = {
        cameraX = 0,
        cameraY = 0,
        zoom = 1.0,
        pointerDown = false,
        moved = false,
        pressX = 0,
        pressY = 0,
    }
end

local function resetRunState(state)
    state.player = Player.new(nil)
    state.food = Food.new(nil)
    state.maps = MapSystem.new(nil)
    state.boss = Boss.new(nil)
    state.runMutations = Mutation.newRunState()
    state.runEssenceTotal = 0
    GameState.refreshDerivedState(state)
    GameState.normalizeProgression(state)

    state.camera.x = 0
    state.camera.y = 0
    state.camera.zoom = 1.0

    state.runTimeLeft = state.runDuration
    state.runEnded = false
    state.runEndedReason = nil
    state.endingReached = false
    state.mode = "game"
    state.runEndTab = "meta"
    resetMetaTreeView(state)
    PassiveCombat.resetState(state)

    state.runMutations.pendingChoices = state.nestBonuses.startingChoices or 0
    if state.runMutations.pendingChoices > 0 then
        Mutation.rollChoices(state)
        if state.runMutations.activeChoices then
            state.mode = "run_choice"
            state.message = "Choose an instinct"
        end
    end
end

function GameState.new(loadResult, loadErr)
    local saved = loadResult or {}
    local state = {
        totalPlayTime = saved.totalPlayTime or 0,
        events = {},
        autosaveTimer = C.AUTOSAVE_INTERVAL,
        mode = saved.mode or "game",
        showHelp = false,
        uiToastTimer = 0,
        uiAutosaveTimer = 0,
        uiLastMessage = nil,
        camera = { x = 0, y = 0, zoom = 1.0 },
        metaTreeView = nil,
        message = loadErr and ("Save warning: " .. tostring(loadErr)) or nil,
        endingReached = saved.endingReached or false,
        runEnded = saved.runEnded or false,
        runEndedReason = saved.runEndedReason,
        lastSaveStatus = "never",
        meta = Meta.new(saved.meta),
        nest = Nest.new(saved.nest),
        runMutations = Mutation.newRunState(),
        runEssenceTotal = 0,
        lastNestMatterReward = 0,
        runEndTab = "meta",
    }

    state.player = Player.new(saved.player)
    state.food = Food.new(saved.food)
    state.maps = MapSystem.new(saved.maps)
    state.boss = Boss.new(saved.boss)

    resetMetaTreeView(state)
    PassiveCombat.resetState(state)

    state.modules = {
        playerExport = Player.export,
        foodExport = Food.export,
        mapExport = MapSystem.export,
        bossExport = Boss.export,
        metaExport = Meta.export,
        nestExport = Nest.export,
    }

    GameState.refreshDerivedState(state)
    GameState.normalizeProgression(state)
    state.runTimeLeft = saved.runTimeLeft or state.runDuration

    if state.mode == "run_choice" then
        state.mode = "game"
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
    state.metaBonuses = Meta.computeBonuses(state.meta)
    state.nestBonuses = Nest.computeBonuses(state.nest)
    state.runOnlyBonuses = Mutation.buildRunBonuses(state.runMutations)
    state.bonuses = PassiveCombat.buildRunBonuses(
        combineBonuses(state.metaBonuses, state.nestBonuses, state.runOnlyBonuses)
    )
    state.runDuration = C.RUN_TIME_LIMIT_SECONDS
end

function GameState.normalizeProgression(state)
    MapSystem.syncUnlocks(state.maps, Meta.getUnlockedCount(state.meta))
end

function GameState.startNewRun(state)
    resetRunState(state)
    if state.mode ~= "run_choice" then
        state.message = "New run started"
    end
end

function GameState.endRun(state, reason)
    if state.runEnded then
        return false
    end

    state.runEnded = true
    state.runEndedReason = reason
    state.mode = "run_end_result"
    resetMetaTreeView(state)
    PassiveCombat.resetState(state)

    state.meta.totalRuns = state.meta.totalRuns + 1
    state.lastNestMatterReward = Nest.awardRunMatter(state)
    state.message = "Run ended"
    return true
end

function GameState.tryBuyMetaUpgrade(state, index)
    if not state.runEnded then
        return false, "not in run end", nil
    end

    local ok, err = Meta.tryBuy(state.meta, index)
    if not ok then
        return false, err, nil
    end

    GameState.refreshDerivedState(state)
    local mapUnlocked = MapSystem.updateUnlocks(state.maps, Meta.getUnlockedCount(state.meta))
    state.message = "Meta upgrade purchased"
    return true, nil, { mapUnlocked = mapUnlocked }
end

function GameState.getMetaUpgradeRows(state)
    return Meta.getUpgradeInfo(state.meta)
end

function GameState.getNestUpgradeRows(state)
    return Nest.getUpgradeRows(state.nest)
end

function GameState.tryBuyNestUpgrade(state, key)
    if not state.runEnded then
        return false, "not in run end"
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

function GameState.saveNow(state, reason)
    local payload = Save.snapshot(state)
    local ok, err = Save.write(payload)
    if ok then
        state.lastSaveStatus = "saved (" .. reason .. ")"
        return true
    end
    state.lastSaveStatus = "save failed: " .. tostring(err)
    return false
end

return GameState
