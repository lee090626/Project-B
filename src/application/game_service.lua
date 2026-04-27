local C = require("src.constants")
local Utils = require("src.utils")
local GameState = require("src.game_state")
local Player = require("src.player_controller")
local Food = require("src.food_system")
local MapSystem = require("src.map_system")
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

local function buildRunBonuses(meta)
    local out = {
        speed = meta.speed or 0,
        reach = meta.reach or 0,
        essenceMult = meta.essenceMult or 1,
        rareBonus = meta.rareBonus or 0,
        eliteBonus = meta.eliteBonus or 0,
        contactBite = meta.contactBite or 0,
        magnet = meta.magnet or 0,
        spawnRate = meta.spawnRate or 0,
        spawnCap = meta.spawnCap or 0,
        rareValue = meta.rareValue or 1,
        eliteValue = meta.eliteValue or 1,
    }

    out.lightningEnabled = (meta.lightningEnabled or 0) > 0
    out.lightningDamage = C.PASSIVE_BASES.lightning.damage + (meta.lightningDamage or 0)
    out.lightningChain = math.max(1, 1 + math.floor(meta.lightningChain or 0))
    out.lightningInterval = Utils.clamp(
        C.PASSIVE_BASES.lightning.interval - (meta.lightningIntervalCut or 0),
        0.24,
        3.2
    )

    out.fireballEnabled = (meta.fireballEnabled or 0) > 0
    out.fireballDamage = C.PASSIVE_BASES.fireball.damage + (meta.fireballDamage or 0)
    out.fireballCount = math.max(1, 1 + math.floor(meta.fireballCount or 0) + math.floor(meta.fireballSplit or 0))
    out.fireballRadius = C.PASSIVE_BASES.fireball.radius + (meta.fireballRadius or 0)
    out.fireballInterval = Utils.clamp(
        C.PASSIVE_BASES.fireball.interval - (meta.fireballIntervalCut or 0),
        0.26,
        3.4
    )

    out.frostEnabled = (meta.frostEnabled or 0) > 0
    out.frostDamage = C.PASSIVE_BASES.frost.damage + (meta.frostDamage or 0)
    out.frostRadius = C.PASSIVE_BASES.frost.radius + (meta.frostRadius or 0)
    out.frostSlow = Utils.clamp(C.PASSIVE_BASES.frost.slow + (meta.frostSlow or 0), 0.05, 0.85)
    out.frostDuration = C.PASSIVE_BASES.frost.duration + (meta.frostDuration or 0)
    out.frostInterval = Utils.clamp(
        C.PASSIVE_BASES.frost.interval - (meta.frostIntervalCut or 0),
        0.28,
        3.6
    )

    return out
end

local function setMessage(state, text)
    state.message = text
    state.uiLastMessage = text
    state.uiToastTimer = C.RUN_HUD_UI.toastDuration
end

local function saveWithFeedback(state, reason)
    local ok = GameState.saveNow(state, reason)
    if ok then
        state.uiAutosaveTimer = C.RUN_HUD_UI.autosaveDuration
    end
    return ok
end

local function addEssence(state, rawAmount)
    if rawAmount <= 0 then
        return
    end
    state.meta.essence = state.meta.essence + math.max(1, math.floor(rawAmount + 0.5))
end

local function pushLightningFx(state, fromX, fromY, toX, toY)
    state.passives.lightningFx = {
        fromX = fromX,
        fromY = fromY,
        toX = toX,
        toY = toY,
        timer = 0.12,
    }
end

local function pushFireballFx(state, fromX, fromY, toX, toY, radius)
    state.passives.fireballFx = {
        fromX = fromX,
        fromY = fromY,
        toX = toX,
        toY = toY,
        radius = radius,
        timer = 0.2,
    }
end

local function triggerFrostFx(state, radius)
    state.passives.frostFxTimer = 0.22
    state.passives.frostFxRadius = radius
end

local function updatePassiveFx(state, dt)
    local p = state.passives
    if p.lightningFx then
        p.lightningFx.timer = p.lightningFx.timer - dt
        if p.lightningFx.timer <= 0 then
            p.lightningFx = nil
        end
    end
    if p.fireballFx then
        p.fireballFx.timer = p.fireballFx.timer - dt
        if p.fireballFx.timer <= 0 then
            p.fireballFx = nil
        end
    end
    p.frostFxTimer = math.max(0, p.frostFxTimer - dt)
end

function Service.loadState()
    local state = GameState.loadOrDefault()
    state.camera.zoom = 1.0
    state.bonuses = buildRunBonuses(state.metaBonuses)
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

local function findNearestHostile(state, fromX, fromY)
    local best = nil
    local foodIndex, foodItem, foodDist = Food.findNearestTarget(state.food, fromX, fromY)
    if foodItem then
        best = {
            kind = "food",
            index = foodIndex,
            item = foodItem,
            dist = foodDist,
            x = foodItem.x,
            y = foodItem.y,
        }
    end

    if state.boss.active and not state.boss.defeated then
        local bossDist = Boss.distanceTo(state.boss, fromX, fromY)
        if (not best) or bossDist < best.dist then
            best = {
                kind = "boss",
                dist = bossDist,
                x = state.boss.x,
                y = state.boss.y,
            }
        end
    end

    return best
end

local function triggerLightning(state, mapData)
    local target = findNearestHostile(state, state.player.x, state.player.y)
    if not target then
        return
    end

    pushLightningFx(state, state.player.x, state.player.y, target.x, target.y)
    if target.kind == "boss" then
        Boss.applyDamage(state, state.bonuses.lightningDamage)
        return
    end

    local reward = 0
    reward = reward + select(1, Food.chainLightning(
        state.food,
        target.index,
        state.bonuses.lightningDamage,
        state.bonuses.lightningChain,
        C.PASSIVE_BASES.lightning.chainRadius,
        mapData,
        state.bonuses
    ))
    addEssence(state, reward)
end

local function triggerFireball(state, mapData)
    local projectiles = state.bonuses.fireballCount
    for _ = 1, projectiles do
        local target = findNearestHostile(state, state.player.x, state.player.y)
        if not target then
            return
        end

        pushFireballFx(state, state.player.x, state.player.y, target.x, target.y, state.bonuses.fireballRadius)
        if target.kind == "boss" then
            Boss.applyDamage(state, state.bonuses.fireballDamage)
            local reward = Food.damagePulse(
                state.food,
                target.x,
                target.y,
                state.bonuses.fireballRadius,
                state.bonuses.fireballDamage * 0.6,
                mapData,
                state.bonuses,
                nil,
                nil,
                math.max(2, projectiles)
            )
            addEssence(state, reward)
        else
            local reward = Food.damagePulse(
                state.food,
                target.x,
                target.y,
                state.bonuses.fireballRadius,
                state.bonuses.fireballDamage,
                mapData,
                state.bonuses,
                nil,
                nil,
                math.max(3, projectiles + 1)
            )
            addEssence(state, reward)
        end
    end
end

local function triggerFrost(state, mapData)
    triggerFrostFx(state, state.bonuses.frostRadius)
    local reward = Food.damagePulse(
        state.food,
        state.player.x,
        state.player.y,
        state.bonuses.frostRadius,
        state.bonuses.frostDamage,
        mapData,
        state.bonuses,
        state.bonuses.frostSlow,
        state.bonuses.frostDuration,
        nil
    )
    addEssence(state, reward)

    if state.boss.active and not state.boss.defeated then
        local dist = Boss.distanceTo(state.boss, state.player.x, state.player.y)
        if dist <= state.bonuses.frostRadius + state.boss.radius then
            Boss.applyDamage(state, state.bonuses.frostDamage * 0.7)
        end
    end
end

local function updatePassives(state, dt, mapData)
    local p = state.passives
    local b = state.bonuses

    if b.lightningEnabled then
        p.lightningTimer = p.lightningTimer - dt
        while p.lightningTimer <= 0 do
            p.lightningTimer = p.lightningTimer + b.lightningInterval
            triggerLightning(state, mapData)
        end
    end

    if b.fireballEnabled then
        p.fireballTimer = p.fireballTimer - dt
        while p.fireballTimer <= 0 do
            p.fireballTimer = p.fireballTimer + b.fireballInterval
            triggerFireball(state, mapData)
        end
    end

    if b.frostEnabled then
        p.frostPulseTimer = p.frostPulseTimer - dt
        while p.frostPulseTimer <= 0 do
            p.frostPulseTimer = p.frostPulseTimer + b.frostInterval
            triggerFrost(state, mapData)
        end
    end
end

function Service.tick(state, dt)
    state.totalPlayTime = state.totalPlayTime + dt
    state.uiToastTimer = math.max(0, state.uiToastTimer - dt)
    state.uiAutosaveTimer = math.max(0, state.uiAutosaveTimer - dt)
    updatePassiveFx(state, dt)

    if state.message and state.uiLastMessage ~= state.message then
        state.uiLastMessage = state.message
        state.uiToastTimer = C.RUN_HUD_UI.toastDuration
    end
    if state.message and state.uiToastTimer <= 0 then
        state.message = nil
    end

    if not state.runEnded then
        state.runTimeLeft = math.max(0, state.runTimeLeft - dt)
        if state.runTimeLeft <= 0 then
            if GameState.endRun(state, "time") then
                saveWithFeedback(state, "run-timeout")
            end
        end
    end

    if state.mode == "game" and not state.runEnded then
        state.bonuses = buildRunBonuses(state.metaBonuses)

        local mx, my = love.mouse.getPosition()
        local wx, wy = screenToWorld(state, mx, my)

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
        addEssence(state, essenceGain)

        updatePassives(state, dt, mapData)

        local unlockedAny = MapSystem.updateUnlocks(state.maps, Meta.getUnlockedCount(state.meta))
        if unlockedAny then
            setMessage(state, "New map unlocked from skill tree")
        end

        local wasDefeated = state.boss.defeated
        Boss.update(state, dt)
        if state.boss.defeated and not wasDefeated then
            saveWithFeedback(state, "boss-defeated")
        end

        if GameState.checkEnding(state) then
            if GameState.endRun(state, "victory") then
                saveWithFeedback(state, "run-victory")
            end
        end

        updateCamera(state)
    end

    state.autosaveTimer = state.autosaveTimer - dt
    if state.autosaveTimer <= 0 then
        saveWithFeedback(state, "autosave")
        state.autosaveTimer = C.AUTOSAVE_INTERVAL
    end
end

function Service.save(state, reason)
    saveWithFeedback(state, reason)
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
    local ok, err = GameState.tryBuyMetaUpgrade(state, index)
    if ok then
        local unlockedAny = MapSystem.updateUnlocks(state.maps, Meta.getUnlockedCount(state.meta))
        if unlockedAny then
            setMessage(state, "Meta upgrade purchased. New map unlocked")
        end
        saveWithFeedback(state, "meta-upgrade")
    else
        setMessage(state, "Meta upgrade failed: " .. tostring(err))
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
    state.mode = "run_end_tree"
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

function Service.panMetaTree(state, dx, dy)
    local view = state.metaTreeView
    local scale = C.RUN_END_TREE_UI.worldScale
    view.cameraX = view.cameraX - dx / (view.zoom * scale)
    view.cameraY = view.cameraY - dy / (view.zoom * scale)
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
