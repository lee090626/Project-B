local C = require("src.constants")
local Utils = require("src.utils")
local GameState = require("src.game_state")
local Player = require("src.player_controller")
local Food = require("src.food_system")
local MapSystem = require("src.map_system")
local SkillTree = require("src.skill_tree_system")
local Boss = require("src.boss_system")

local Service = {}

local function screenToWorld(state, sx, sy)
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

function Service.loadState()
    local state = GameState.loadOrDefault()
    state.camera.zoom = 1.0
    return state
end

function Service.reloadState()
    local state = Service.loadState()
    state.message = "Save reloaded"
    return state
end

function Service.tick(state, dt)
    state.totalPlayTime = state.totalPlayTime + dt

    if state.mode == "game" then
        state.bonuses = SkillTree.computeBonuses(state.skillTree)

        local mx, my = love.mouse.getPosition()
        local wx, wy = screenToWorld(state, mx, my)

        Player.update(state.player, dt, wx, wy, state.bonuses)

        local mapData = MapSystem.getCurrentMap(state.maps)
        local eatRadius = Player.getEatRadius(state.player, state.bonuses)
        state.player.magnetRadius = Player.getMagnetRadius(state.player, state.bonuses)

        Food.update(state.food, dt, mapData, state.bonuses, state.player)
        local nutrition, xp, consumed = Food.consumeNearby(state.food, state.player, eatRadius, mapData.reward, state.bonuses)
        state.resources.nutrition = state.resources.nutrition + nutrition
        state.resources.growth = state.resources.growth + xp
        state.resources.consumed = state.resources.consumed + consumed

        local unlockedAny = MapSystem.updateUnlocks(state.maps, state.skillTree.unlockedCount)
        if unlockedAny then
            state.message = "New map unlocked from skill progress"
        end

        local wasDefeated = state.boss.defeated
        Boss.update(state, dt)
        if state.boss.defeated and not wasDefeated then
            GameState.saveNow(state, "boss-defeated")
        end

        updateCamera(state)
    end

    state.autosaveTimer = state.autosaveTimer - dt
    if state.autosaveTimer <= 0 then
        GameState.saveNow(state, "autosave")
        state.autosaveTimer = C.AUTOSAVE_INTERVAL
    end

    GameState.checkEnding(state)
end

function Service.toggleMode(state)
    state.mode = state.mode == "game" and "tree" or "game"
end

function Service.save(state, reason)
    GameState.saveNow(state, reason)
end

function Service.trySwitchMap(state, mapId)
    if not C.MAPS[mapId] then
        return false
    end

    local switched = MapSystem.trySetCurrent(state.maps, mapId)
    if switched then
        GameState.saveNow(state, "map-switch")
        state.message = "Map changed to " .. C.MAPS[mapId].name
    end
    return switched
end

function Service.tryEnterBoss(state)
    if Boss.canEnter(state) then
        local entered = Boss.enter(state)
        if entered then
            GameState.saveNow(state, "boss-enter")
            state.message = "Final boss engaged"
        end
        return entered
    end
    return false
end

function Service.skillTreeWorldPosition(state, sx, sy)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local tree = state.skillTree
    local wx = (sx - sw * 0.5) / tree.zoom + tree.cameraX
    local wy = (sy - sh * 0.5) / tree.zoom + tree.cameraY
    return wx, wy
end

function Service.tryUnlockTreeNodeAtScreen(state, sx, sy)
    local wx, wy = Service.skillTreeWorldPosition(state, sx, sy)
    local tree = state.skillTree
    local node = SkillTree.nodeAtWorldPosition(tree, wx, wy)

    if not node then
        return false, "no-node"
    end

    local ok, err = SkillTree.tryUnlock(tree, node.id, state)
    if ok then
        state.message = "Unlocked " .. node.name
        state.bonuses = SkillTree.computeBonuses(state.skillTree)
        MapSystem.updateUnlocks(state.maps, state.skillTree.unlockedCount)
        return true, nil
    end

    state.message = "Cannot unlock: " .. tostring(err)
    return false, err
end

function Service.startTreeDrag(state, x, y)
    state.treeDrag = true
    state.treeDragX = x
    state.treeDragY = y
end

function Service.stopTreeDrag(state)
    state.treeDrag = false
end

function Service.panTree(state, dx, dy)
    if state.mode ~= "tree" or not state.treeDrag then
        return
    end

    local tree = state.skillTree
    tree.cameraX = tree.cameraX - dx / tree.zoom
    tree.cameraY = tree.cameraY - dy / tree.zoom
end

function Service.zoomTree(state, wheelY)
    if state.mode ~= "tree" then
        return
    end

    local tree = state.skillTree
    local zoomStep = wheelY > 0 and 1.1 or 0.9
    tree.zoom = Utils.clamp(tree.zoom * zoomStep, 0.35, 1.45)
end

return Service
