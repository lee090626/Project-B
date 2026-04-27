local C = require("src.constants")
local Utils = require("src.utils")
local Food = require("src.food_system")
local Boss = require("src.boss_system")

local PassiveCombat = {}

function PassiveCombat.buildRunBonuses(metaBonuses)
    local out = {
        speed = metaBonuses.speed or 0,
        reach = metaBonuses.reach or 0,
        essenceMult = metaBonuses.essenceMult or 1,
        rareBonus = metaBonuses.rareBonus or 0,
        eliteBonus = metaBonuses.eliteBonus or 0,
        contactBite = metaBonuses.contactBite or 0,
        magnet = metaBonuses.magnet or 0,
        spawnRate = metaBonuses.spawnRate or 0,
        spawnCap = metaBonuses.spawnCap or 0,
        rareValue = metaBonuses.rareValue or 1,
        eliteValue = metaBonuses.eliteValue or 1,
    }

    out.lightningEnabled = (metaBonuses.lightningEnabled or 0) > 0
    out.lightningDamage = C.PASSIVE_BASES.lightning.damage + (metaBonuses.lightningDamage or 0)
    out.lightningChain = math.max(1, 1 + math.floor(metaBonuses.lightningChain or 0))
    out.lightningInterval = Utils.clamp(
        C.PASSIVE_BASES.lightning.interval - (metaBonuses.lightningIntervalCut or 0),
        0.24,
        3.2
    )

    out.fireballEnabled = (metaBonuses.fireballEnabled or 0) > 0
    out.fireballDamage = C.PASSIVE_BASES.fireball.damage + (metaBonuses.fireballDamage or 0)
    out.fireballCount = math.max(1, 1 + math.floor(metaBonuses.fireballCount or 0) + math.floor(metaBonuses.fireballSplit or 0))
    out.fireballRadius = C.PASSIVE_BASES.fireball.radius + (metaBonuses.fireballRadius or 0)
    out.fireballInterval = Utils.clamp(
        C.PASSIVE_BASES.fireball.interval - (metaBonuses.fireballIntervalCut or 0),
        0.26,
        3.4
    )

    out.frostEnabled = (metaBonuses.frostEnabled or 0) > 0
    out.frostDamage = C.PASSIVE_BASES.frost.damage + (metaBonuses.frostDamage or 0)
    out.frostRadius = C.PASSIVE_BASES.frost.radius + (metaBonuses.frostRadius or 0)
    out.frostSlow = Utils.clamp(C.PASSIVE_BASES.frost.slow + (metaBonuses.frostSlow or 0), 0.05, 0.85)
    out.frostDuration = C.PASSIVE_BASES.frost.duration + (metaBonuses.frostDuration or 0)
    out.frostInterval = Utils.clamp(
        C.PASSIVE_BASES.frost.interval - (metaBonuses.frostIntervalCut or 0),
        0.28,
        3.6
    )

    return out
end

function PassiveCombat.resetState(state)
    state.passives = {
        lightningTimer = 0.35,
        fireballTimer = 0.6,
        frostPulseTimer = 0.9,
        lightningFx = nil,
        fireballFx = nil,
        frostFxTimer = 0,
        frostFxRadius = 0,
    }
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

function PassiveCombat.tickFx(state, dt)
    local passives = state.passives
    if passives.lightningFx then
        passives.lightningFx.timer = passives.lightningFx.timer - dt
        if passives.lightningFx.timer <= 0 then
            passives.lightningFx = nil
        end
    end
    if passives.fireballFx then
        passives.fireballFx.timer = passives.fireballFx.timer - dt
        if passives.fireballFx.timer <= 0 then
            passives.fireballFx = nil
        end
    end
    passives.frostFxTimer = math.max(0, passives.frostFxTimer - dt)
end

local function findNearestHostile(state, fromX, fromY)
    local best
    local foodIndex, foodItem, foodDist = Food.findNearestTarget(state.food, fromX, fromY)
    if foodItem then
        best = {
            kind = "food",
            index = foodIndex,
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

    local reward = select(1, Food.chainLightning(
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

function PassiveCombat.tickPassives(state, dt, mapData)
    local passives = state.passives
    local bonuses = state.bonuses

    if bonuses.lightningEnabled then
        passives.lightningTimer = passives.lightningTimer - dt
        while passives.lightningTimer <= 0 do
            passives.lightningTimer = passives.lightningTimer + bonuses.lightningInterval
            triggerLightning(state, mapData)
        end
    end

    if bonuses.fireballEnabled then
        passives.fireballTimer = passives.fireballTimer - dt
        while passives.fireballTimer <= 0 do
            passives.fireballTimer = passives.fireballTimer + bonuses.fireballInterval
            triggerFireball(state, mapData)
        end
    end

    if bonuses.frostEnabled then
        passives.frostPulseTimer = passives.frostPulseTimer - dt
        while passives.frostPulseTimer <= 0 do
            passives.frostPulseTimer = passives.frostPulseTimer + bonuses.frostInterval
            triggerFrost(state, mapData)
        end
    end
end

return PassiveCombat
