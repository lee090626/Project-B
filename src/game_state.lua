local C = require("src.constants")
local Player = require("src.player_controller")
local Food = require("src.food_system")
local MapSystem = require("src.map_system")
local SkillTree = require("src.skill_tree_system")
local Boss = require("src.boss_system")
local Save = require("src.save_system")

local GameState = {}

local function createResources(saved)
    return {
        nutrition = saved and saved.nutrition or 0,
        growth = saved and saved.growth or 0,
        consumed = saved and saved.consumed or 0,
    }
end

function GameState.new(loadResult, loadErr)
    local saved = loadResult or {}
    local state = {
        totalPlayTime = saved.totalPlayTime or 0,
        resources = createResources(saved.resources),
        events = {},
        autosaveTimer = C.AUTOSAVE_INTERVAL,
        mode = "game",
        treeDrag = false,
        treeDragX = 0,
        treeDragY = 0,
        camera = { x = 0, y = 0, zoom = 1.0 },
        message = loadErr and ("Save warning: " .. tostring(loadErr)) or nil,
        endingReached = false,
        lastSaveStatus = "never",
    }

    state.player = Player.new(saved.player)
    state.food = Food.new(saved.food)
    state.maps = MapSystem.new(saved.maps)
    state.skillTree = SkillTree.new(saved.skills)
    state.boss = Boss.new(saved.boss)

    state.modules = {
        playerExport = Player.export,
        foodExport = Food.export,
        mapExport = MapSystem.export,
        skillExport = SkillTree.export,
        bossExport = Boss.export,
    }

    state.bonuses = SkillTree.computeBonuses(state.skillTree)
    MapSystem.updateUnlocks(state.maps, state.skillTree.unlockedCount)

    return state
end

function GameState.loadOrDefault()
    local loaded, err = Save.load()
    return GameState.new(loaded, err)
end

function GameState.checkEnding(state)
    if state.endingReached then
        return true
    end

    local allSkills = SkillTree.allUnlocked(state.skillTree)
    local allMaps = MapSystem.allMapsUnlocked(state.maps)
    local bossDefeated = state.boss.defeated

    if allSkills and allMaps and bossDefeated then
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
