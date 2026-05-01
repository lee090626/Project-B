local C = require("src.constants")
local Player = require("src.player_controller")
local Food = require("src.food_system")
local MapSystem = require("src.map_system")
local Boss = require("src.boss_system")
local Meta = require("src.meta_system")
local Nest = require("src.nest_system")
local Locale = require("src.locale")
local Guide = require("src.application.guide_system")
local Mutation = require("src.mutation_system")
local RunEvent = require("src.run_event_system")

local Factory = {}

function Factory.resetMetaTreeView(state)
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

function Factory.new(loadResult, loadErr)
    local saved = loadResult or {}
    local locale = Locale.isSupported(saved.locale) and saved.locale or Locale.DEFAULT
    local messageKey = loadErr and "message.save_warning" or nil
    local messageParams = loadErr and { error = tostring(loadErr) } or nil

    local metaState = Meta.new(saved.meta)
    local fallbackNestEssence = metaState.essence + Meta.getSpentEssence(metaState)

    local state = {
        totalPlayTime = saved.totalPlayTime or 0,
        events = {},
        autosaveTimer = C.AUTOSAVE_INTERVAL,
        mode = saved.mode or "game",
        showHelp = false,
        uiToastTimer = 0,
        uiAutosaveTimer = 0,
        camera = { x = 0, y = 0, zoom = 1.0 },
        metaTreeView = nil,
        locale = locale,
        messageKey = messageKey,
        messageParams = messageParams,
        messageVersion = messageKey and 1 or 0,
        uiLastMessageVersion = 0,
        endingReached = saved.endingReached or false,
        runEnded = saved.runEnded or false,
        runEndedReason = saved.runEndedReason,
        lastSaveStatusKey = "save_status.never",
        lastSaveStatusParams = nil,
        meta = metaState,
        nest = Nest.new(saved.nest),
        guides = Guide.new(saved.uxGuides),
        runMutations = Mutation.newRunState(),
        runEssenceTotal = 0,
        runStarsEarned = 0,
        runMapStarsBest = 0,
        runStarsImproved = false,
        runMapsUnlocked = false,
        runEndTab = "meta",
    }

    if saved.nest and saved.nest.totalEssence ~= nil then
        state.nest.totalEssence = math.max(0, math.floor(saved.nest.totalEssence or 0))
    else
        state.nest.totalEssence = fallbackNestEssence
    end

    state.player = Player.new(saved.player)
    state.food = Food.new(saved.food)
    state.maps = MapSystem.new(saved.maps)
    state.boss = Boss.new(saved.boss)
    state.runEvent = RunEvent.newRunState(MapSystem.getCurrentMap(state.maps))

    Factory.resetMetaTreeView(state)
    return state
end

return Factory
