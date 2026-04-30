local C = require("src.constants")
local Player = require("src.player_controller")
local Food = require("src.food_system")
local MapSystem = require("src.map_system")
local Boss = require("src.boss_system")
local Meta = require("src.meta_system")
local Nest = require("src.nest_system")
local Guide = require("src.application.guide_system")

local Snapshot = {}

function Snapshot.build(state)
    return {
        version = C.SAVE_VERSION,
        locale = state.locale,
        totalPlayTime = state.totalPlayTime,
        mode = state.mode,
        runTimeLeft = state.runTimeLeft,
        runDuration = state.runDuration,
        runEnded = state.runEnded,
        runEndedReason = state.runEndedReason,
        endingReached = state.endingReached,
        player = Player.export(state.player),
        food = Food.export(state.food),
        maps = MapSystem.export(state.maps),
        boss = Boss.export(state.boss),
        meta = Meta.export(state.meta),
        nest = Nest.export(state.nest),
        uxGuides = Guide.export(state.guides),
    }
end

return Snapshot
