local C = require("src.constants")
local Utils = require("src.utils")
local Player = require("src.player_controller")
local Food = require("src.food_system")
local MapSystem = require("src.map_system")
local Boss = require("src.boss_system")
local Meta = require("src.meta_system")
local GameState = require("src.game_state")
local PassiveCombat = require("src.application.passive_combat")
local Mutation = require("src.mutation_system")

local RunLoop = {}

function RunLoop.screenToWorld(state, sx, sy)
    local wx = sx / state.camera.zoom + state.camera.x
    local wy = sy / state.camera.zoom + state.camera.y
    return wx, wy
end

local function updateCamera(state)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local targetX = state.player.x - sw * 0.5 / state.camera.zoom
    local targetY = state.player.y - sh * 0.5 / state.camera.zoom

    state.camera.x = Utils.lerp(state.camera.x, targetX, 0.12)
    state.camera.y = Utils.lerp(state.camera.y, targetY, 0.12)

    local maxX = math.max(0, C.WORLD_WIDTH - sw / state.camera.zoom)
    local maxY = math.max(0, C.WORLD_HEIGHT - sh / state.camera.zoom)
    state.camera.x = Utils.clamp(state.camera.x, 0, maxX)
    state.camera.y = Utils.clamp(state.camera.y, 0, maxY)
end

function RunLoop.tickGameplay(state, dt)
    local result = {
        mapUnlocked = false,
        bossDefeated = false,
        runEndedReason = nil,
    }

    local mx, my = love.mouse.getPosition()
    local wx, wy = RunLoop.screenToWorld(state, mx, my)

    Player.update(state.player, dt, wx, wy, state.bonuses)

    local mapData = MapSystem.getCurrentMap(state.maps)
    local eatRadius = Player.getEatRadius(state.player, state.bonuses)
    state.player.magnetRadius = Player.getMagnetRadius(state.player, state.bonuses)

    Food.update(state.food, dt, mapData, state.bonuses, state.player)

    local contactDamage = C.PLAYER_CONTACT_DAMAGE + state.bonuses.contactBite
    local essenceGain = Food.damageTouching(
        state.food,
        state.player,
        eatRadius,
        contactDamage,
        dt,
        mapData,
        state.bonuses
    )
    if essenceGain > 0 then
        PassiveCombat.triggerEatFx(state, essenceGain)
        Mutation.gainEssenceAndCheckLevel(state, essenceGain)
        if state.mode == "run_choice" then
            updateCamera(state)
            return result
        end
    end

    PassiveCombat.tickPassives(state, dt, mapData)
    if state.mode == "run_choice" then
        updateCamera(state)
        return result
    end

    result.mapUnlocked = MapSystem.updateUnlocks(state.maps, Meta.getUnlockedCount(state.meta))

    updateCamera(state)
    return result
end

function RunLoop.tickBossArena(state, dt)
    local result = {
        mapUnlocked = false,
        bossDefeated = false,
        runEndedReason = nil,
    }

    local mx, my = love.mouse.getPosition()
    local wx, wy = RunLoop.screenToWorld(state, mx, my)

    Player.update(state.player, dt, wx, wy, state.bonuses)
    state.player.magnetRadius = Player.getMagnetRadius(state.player, state.bonuses)

    local mapData = MapSystem.getCurrentMap(state.maps)
    PassiveCombat.tickPassives(state, dt, mapData)
    if state.mode == "run_choice" then
        updateCamera(state)
        return result
    end

    local bossResult = Boss.update(state, dt)
    result.bossDefeated = state.boss.defeated

    if result.bossDefeated and GameState.checkEnding(state) and GameState.endRun(state, "victory") then
        result.runEndedReason = "victory"
    elseif bossResult == "failed" and GameState.endRun(state, "boss_failed") then
        result.runEndedReason = "boss_failed"
    end

    updateCamera(state)
    return result
end

return RunLoop
