local C = require("src.constants")
local Player = require("src.player_controller")
local Food = require("src.food_system")
local MapSystem = require("src.map_system")
local SkillTree = require("src.skill_tree_system")
local Boss = require("src.boss_system")
local Meta = require("src.meta_system")
local Save = require("src.save_system")

local GameState = {}

local function resetMetaTreeView(state)
    state.metaTreeView = {
        cameraX = 0.5,
        cameraY = 0.5,
        zoom = 1.0,
        pointerDown = false,
        moved = false,
        pressX = 0,
        pressY = 0,
    }
end

local function createResources(saved, startGrowth)
    return {
        nutrition = saved and saved.nutrition or 0,
        growth = saved and saved.growth or startGrowth or 0,
        consumed = saved and saved.consumed or 0,
    }
end

local function recomputeMetaBonuses(state)
    state.metaBonuses = Meta.computeBonuses(state.meta)
    state.runDuration = C.RUN_TIME_LIMIT_SECONDS + state.metaBonuses.extraTime
end

local function resetRunState(state)
    recomputeMetaBonuses(state)

    state.resources = createResources(nil, state.metaBonuses.startGrowth)
    state.player = Player.new(nil)
    state.food = Food.new(nil)
    state.maps = MapSystem.new(nil)
    state.skillTree = SkillTree.new(nil)
    state.boss = Boss.new(nil)

    state.bonuses = SkillTree.computeBonuses(state.skillTree)
    MapSystem.updateUnlocks(state.maps, state.skillTree.unlockedCount)

    state.camera.x = 0
    state.camera.y = 0
    state.camera.zoom = 1.0

    state.runTimeLeft = state.runDuration
    state.runEnded = false
    state.runEndedReason = nil
    state.endingReached = false
    state.mode = "game"
    resetMetaTreeView(state)
end

function GameState.new(loadResult, loadErr)
    local saved = loadResult or {}
    local state = {
        totalPlayTime = saved.totalPlayTime or 0,
        events = {},
        autosaveTimer = C.AUTOSAVE_INTERVAL,
        mode = saved.mode or "game",
        showHelp = false,
        treeDrag = false,
        treeDragX = 0,
        treeDragY = 0,
        camera = { x = 0, y = 0, zoom = 1.0 },
        metaTreeView = nil,
        message = loadErr and ("Save warning: " .. tostring(loadErr)) or nil,
        endingReached = saved.endingReached or false,
        runEnded = saved.runEnded or false,
        runEndedReason = saved.runEndedReason,
        lastRunReward = saved.lastRunReward or 0,
        lastSaveStatus = "never",
        meta = Meta.new(saved.meta),
    }

    recomputeMetaBonuses(state)

    state.resources = createResources(saved.resources, state.metaBonuses.startGrowth)
    state.player = Player.new(saved.player)
    state.food = Food.new(saved.food)
    state.maps = MapSystem.new(saved.maps)
    state.skillTree = SkillTree.new(saved.skills)
    state.boss = Boss.new(saved.boss)

    state.runTimeLeft = saved.runTimeLeft or state.runDuration
    resetMetaTreeView(state)

    state.modules = {
        playerExport = Player.export,
        foodExport = Food.export,
        mapExport = MapSystem.export,
        skillExport = SkillTree.export,
        bossExport = Boss.export,
        metaExport = Meta.export,
    }

    state.bonuses = SkillTree.computeBonuses(state.skillTree)
    MapSystem.updateUnlocks(state.maps, state.skillTree.unlockedCount)

    if state.runEnded then
        state.mode = "run_end_tree"
    end

    return state
end

function GameState.loadOrDefault()
    local loaded, err = Save.load()
    return GameState.new(loaded, err)
end

function GameState.startNewRun(state)
    resetRunState(state)
    state.message = "New run started"
end

function GameState.endRun(state, reason)
    if state.runEnded then
        return false
    end

    state.runEnded = true
    state.runEndedReason = reason
    state.mode = "run_end_tree"
    resetMetaTreeView(state)

    local reward = Meta.calculateRunReward(state)
    state.lastRunReward = reward
    state.meta.essence = state.meta.essence + reward
    state.meta.totalRuns = state.meta.totalRuns + 1
    state.message = string.format("Run ended: +%d essence", reward)
    return true
end

function GameState.tryBuyMetaUpgrade(state, index)
    if not state.runEnded then
        return false, "not in run end"
    end

    local ok, err = Meta.tryBuy(state.meta, index)
    if not ok then
        return false, err
    end

    recomputeMetaBonuses(state)
    state.message = "Meta upgrade purchased"
    return true, nil
end

function GameState.getMetaUpgradeRows(state)
    return Meta.getUpgradeInfo(state.meta)
end

function GameState.checkEnding(state)
    if state.endingReached then
        return true
    end

    local allMaps = MapSystem.allMapsUnlocked(state.maps)
    local bossDefeated = state.boss.defeated

    if allMaps and bossDefeated then
        state.endingReached = true
        state.events[#state.events + 1] = "Ending reached: All maps + boss defeated"
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
