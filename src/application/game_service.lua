local C = require("src.constants")
local Utils = require("src.utils")
local GameState = require("src.game_state")
local Player = require("src.player_controller")
local Food = require("src.food_system")
local MapSystem = require("src.map_system")
local SkillTree = require("src.skill_tree_system")
local Boss = require("src.boss_system")
local Meta = require("src.meta_system")

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

local function mergeBonuses(skill, meta)
    local out = {
        speed = skill.speed + meta.speed,
        reach = skill.reach + meta.reach,
        nutritionMult = skill.nutritionMult + (meta.gainMult - 1),
        xpMult = skill.xpMult + (meta.gainMult - 1),
        rareBonus = skill.rareBonus,
        eliteBonus = skill.eliteBonus,
        bite = skill.bite + meta.bite,
        magnet = skill.magnet,
    }
    return out
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

function Service.resetAllData()
    love.filesystem.remove(C.SAVE_FILE)
    love.filesystem.remove(C.BACKUP_FILE)

    local state = Service.loadState()
    state.message = "All progress reset"
    GameState.saveNow(state, "reset-all")
    return state
end

function Service.tick(state, dt)
    state.totalPlayTime = state.totalPlayTime + dt

    if not state.runEnded then
        state.runTimeLeft = math.max(0, state.runTimeLeft - dt)
        if state.runTimeLeft <= 0 then
            if GameState.endRun(state, "time") then
                GameState.saveNow(state, "run-timeout")
            end
        end
    end

    if state.mode == "game" and not state.runEnded then
        local skillBonuses = SkillTree.computeBonuses(state.skillTree)
        state.bonuses = mergeBonuses(skillBonuses, state.metaBonuses)

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

        local progressionScore = state.resources.consumed
            + math.floor(state.resources.growth * 0.15)
            + math.floor(state.meta.totalRuns * 2)
        local unlockedAny = MapSystem.updateUnlocks(state.maps, progressionScore)
        if unlockedAny then
            state.message = "New map unlocked from run progress"
        end

        local wasDefeated = state.boss.defeated
        Boss.update(state, dt)
        if state.boss.defeated and not wasDefeated then
            GameState.saveNow(state, "boss-defeated")
        end

        if GameState.checkEnding(state) then
            if GameState.endRun(state, "victory") then
                GameState.saveNow(state, "run-victory")
            end
        end

        updateCamera(state)
    end

    state.autosaveTimer = state.autosaveTimer - dt
    if state.autosaveTimer <= 0 then
        GameState.saveNow(state, "autosave")
        state.autosaveTimer = C.AUTOSAVE_INTERVAL
    end
end

function Service.toggleMode(state)
    if state.runEnded then
        return
    end
    state.mode = state.mode == "game" and "tree" or "game"
end

function Service.save(state, reason)
    GameState.saveNow(state, reason)
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
        GameState.saveNow(state, "map-switch")
        state.message = "Map changed to " .. C.MAPS[mapId].name
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
            GameState.saveNow(state, "boss-enter")
            state.message = "Final boss engaged"
        end
        return entered
    end
    return false
end

function Service.tryBuyMetaUpgrade(state, index)
    local ok, err = GameState.tryBuyMetaUpgrade(state, index)
    if ok then
        GameState.saveNow(state, "meta-upgrade")
    else
        state.message = "Meta upgrade failed: " .. tostring(err)
    end
    return ok
end

function Service.restartRun(state)
    GameState.startNewRun(state)
    GameState.saveNow(state, "run-restart")
end

function Service.metaUpgradeIndexAtScreen(state, sx, sy)
    return Service.metaTreeNodeAtScreen(state, sx, sy)
end

function Service.metaTreeScreenToWorld(state, sx, sy)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local view = state.metaTreeView
    local scale = C.RUN_END_TREE_UI.worldScale
    local wx = (sx - sw * 0.5) / (view.zoom * scale) + view.cameraX
    local wy = (sy - sh * 0.5) / (view.zoom * scale) + view.cameraY
    return wx, wy
end

function Service.metaTreeNodeAtScreen(state, sx, sy)
    local wx, wy = Service.metaTreeScreenToWorld(state, sx, sy)
    local rows = Meta.getUpgradeInfo(state.meta)
    local layout = Meta.getTreeLayout()
    local scale = C.RUN_END_TREE_UI.worldScale
    local view = state.metaTreeView
    local radius = C.RUN_END_TREE_UI.nodeRadius / (view.zoom * scale)
    local best
    local bestDistSq = radius * radius

    for _, row in ipairs(rows) do
        if row.visible then
            local p = layout[row.index]
            if p then
                local dx = wx - p.x
                local dy = wy - p.y
                local distSq = dx * dx + dy * dy
                if distSq <= bestDistSq then
                    bestDistSq = distSq
                    best = row.index
                end
            end
        end
    end

    return best
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
    if state.runEnded then
        return false, "run ended"
    end

    local wx, wy = Service.skillTreeWorldPosition(state, sx, sy)
    local tree = state.skillTree
    local node = SkillTree.nodeAtWorldPosition(tree, wx, wy)

    if not node then
        return false, "no-node"
    end

        local ok, err, info = SkillTree.tryUnlock(tree, node.id, state)
    if ok then
        if info and info.maxLevel and info.maxLevel > 1 then
            state.message = string.format("Upgraded %s Lv.%d/%d", node.name, info.level, info.maxLevel)
        else
            state.message = "Unlocked " .. node.name
        end
        local skillBonuses = SkillTree.computeBonuses(state.skillTree)
        state.bonuses = mergeBonuses(skillBonuses, state.metaBonuses)
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

function Service.panMetaTree(state, dx, dy)
    local view = state.metaTreeView
    local scale = C.RUN_END_TREE_UI.worldScale
    view.cameraX = view.cameraX - dx / (view.zoom * scale)
    view.cameraY = view.cameraY - dy / (view.zoom * scale)
end

function Service.zoomTree(state, wheelY)
    if state.mode ~= "tree" then
        return
    end

    local tree = state.skillTree
    local zoomStep = wheelY > 0 and 1.1 or 0.9
    tree.zoom = Utils.clamp(tree.zoom * zoomStep, 0.35, 1.45)
end

function Service.zoomMetaTree(state, wheelY)
    if wheelY == 0 then
        return
    end

    local view = state.metaTreeView
    local oldZoom = view.zoom
    local zoomStep = wheelY > 0 and C.RUN_END_TREE_UI.zoomStepUp or C.RUN_END_TREE_UI.zoomStepDown
    local newZoom = Utils.clamp(oldZoom * zoomStep, C.RUN_END_TREE_UI.minZoom, C.RUN_END_TREE_UI.maxZoom)
    if oldZoom == newZoom then
        return
    end

    local mx, my = love.mouse.getPosition()
    local wx, wy = Service.metaTreeScreenToWorld(state, mx, my)
    view.zoom = newZoom

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local scale = C.RUN_END_TREE_UI.worldScale
    view.cameraX = wx - (mx - sw * 0.5) / (newZoom * scale)
    view.cameraY = wy - (my - sh * 0.5) / (newZoom * scale)
end

function Service.beginMetaTreePointer(state, x, y)
    local view = state.metaTreeView
    view.pointerDown = true
    view.moved = false
    view.pressX = x
    view.pressY = y
end

function Service.updateMetaTreePointer(state, _, _, dx, dy)
    local view = state.metaTreeView
    if not view.pointerDown then
        return
    end

    local mx, my = love.mouse.getPosition()
    local movedDx = mx - view.pressX
    local movedDy = my - view.pressY
    local threshold = C.RUN_END_TREE_UI.clickThreshold

    if not view.moved and (movedDx * movedDx + movedDy * movedDy) >= (threshold * threshold) then
        view.moved = true
    end

    if view.moved then
        Service.panMetaTree(state, dx, dy)
    end
end

function Service.endMetaTreePointer(state, x, y)
    local view = state.metaTreeView
    if not view.pointerDown then
        return nil
    end

    view.pointerDown = false
    if view.moved then
        return nil
    end

    return Service.metaTreeNodeAtScreen(state, x, y)
end

return Service
