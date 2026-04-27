local C = require("src.constants")
local Utils = require("src.utils")
local Food = require("src.food_system")
local Boss = require("src.boss_system")
local MapSystem = require("src.map_system")
local Mutation = require("src.mutation_system")

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
    out.lightningChainRadius = C.PASSIVE_BASES.lightning.chainRadius + math.max(0, out.lightningChain - 1) * 70
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
        fireballProjectiles = {},
        fireballImpacts = {},
        frostFxTimer = 0,
        frostFxRadius = 0,
        eatFxTimer = 0,
        eatFxRadius = 0,
    }
end

function PassiveCombat.triggerEatFx(state, amount)
    local passives = state.passives
    if not passives or amount <= 0 then
        return
    end
    passives.eatFxTimer = 0.18
    passives.eatFxRadius = C.WORLD_THEME.eatPulseMinRadius
        + math.min(30, amount * C.WORLD_THEME.eatPulseRadiusScale)
end

local function addEssence(state, rawAmount)
    if rawAmount <= 0 then
        return false
    end
    PassiveCombat.triggerEatFx(state, rawAmount)
    local _, opened = Mutation.gainEssenceAndCheckLevel(state, rawAmount)
    return opened
end

local function pushLightningFx(state, segments)
    if not segments or #segments == 0 then
        state.passives.lightningFx = nil
        return
    end
    state.passives.lightningFx = {
        segments = segments,
        timer = 0.18,
    }
end

local function spawnFireballProjectile(state, fromX, fromY, toX, toY, radius, pulseDamage, bossDamage, maxHits)
    local dist = Utils.distance(fromX, fromY, toX, toY)
    if dist <= 0 then
        dist = 1
    end

    local speed = C.PASSIVE_BASES.fireball.projectileSpeed
    local vx = (toX - fromX) / dist * speed
    local vy = (toY - fromY) / dist * speed

    state.passives.fireballProjectiles[#state.passives.fireballProjectiles + 1] = {
        x = fromX,
        y = fromY,
        prevX = fromX,
        prevY = fromY,
        targetX = toX,
        targetY = toY,
        vx = vx,
        vy = vy,
        speed = speed,
        radius = radius,
        pulseDamage = pulseDamage,
        bossDamage = bossDamage,
        maxHits = maxHits,
    }
end

local function pushFireballImpact(state, x, y, radius)
    state.passives.fireballImpacts[#state.passives.fireballImpacts + 1] = {
        x = x,
        y = y,
        radius = radius,
        timer = C.PASSIVE_BASES.fireball.impactFxDuration,
    }
end

local function triggerFrostFx(state, radius)
    state.passives.frostFxTimer = 0.22
    state.passives.frostFxRadius = radius
end

function PassiveCombat.tickFx(state, dt)
    local passives = state.passives
    local mapData = MapSystem.getCurrentMap(state.maps)
    if passives.lightningFx then
        passives.lightningFx.timer = passives.lightningFx.timer - dt
        if passives.lightningFx.timer <= 0 then
            passives.lightningFx = nil
        end
    end

    if passives.fireballImpacts then
        for i = #passives.fireballImpacts, 1, -1 do
            local impact = passives.fireballImpacts[i]
            impact.timer = impact.timer - dt
            if impact.timer <= 0 then
                table.remove(passives.fireballImpacts, i)
            end
        end
    end

    if passives.fireballProjectiles then
        for i = #passives.fireballProjectiles, 1, -1 do
            local projectile = passives.fireballProjectiles[i]
            projectile.prevX = projectile.x
            projectile.prevY = projectile.y
            projectile.x = projectile.x + projectile.vx * dt
            projectile.y = projectile.y + projectile.vy * dt

            local reachedTarget = Utils.distance(projectile.x, projectile.y, projectile.targetX, projectile.targetY)
                <= projectile.speed * dt
            if reachedTarget then
                projectile.x = projectile.targetX
                projectile.y = projectile.targetY
                pushFireballImpact(state, projectile.x, projectile.y, projectile.radius)

                if state.boss.active and not state.boss.defeated then
                    local bossDist = Boss.distanceTo(state.boss, projectile.x, projectile.y)
                    if bossDist <= projectile.radius + state.boss.radius then
                        Boss.applyDamage(state, projectile.bossDamage)
                    end
                end

                local reward = Food.damagePulse(
                    state.food,
                    projectile.x,
                    projectile.y,
                    projectile.radius,
                    projectile.pulseDamage,
                    mapData,
                    state.bonuses,
                    nil,
                    nil,
                    projectile.maxHits
                )
                table.remove(passives.fireballProjectiles, i)
                if addEssence(state, reward) then
                    return
                end
            end
        end
    end
    passives.frostFxTimer = math.max(0, passives.frostFxTimer - dt)
    passives.eatFxTimer = math.max(0, passives.eatFxTimer - dt)
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
        return false
    end

    if target.kind == "boss" then
        pushLightningFx(state, {
            {
                fromX = state.player.x,
                fromY = state.player.y,
                toX = target.x,
                toY = target.y,
            },
        })
        Boss.applyDamage(state, state.bonuses.lightningDamage)
        return false
    end

    local reward, _, _, segments = Food.chainLightning(
        state.food,
        target.index,
        state.bonuses.lightningDamage,
        state.bonuses.lightningChain,
        state.bonuses.lightningChainRadius,
        mapData,
        state.bonuses
    )
    if segments and #segments > 0 then
        local fullSegments = {
            {
                fromX = state.player.x,
                fromY = state.player.y,
                toX = segments[1].fromX,
                toY = segments[1].fromY,
            },
        }
        for _, segment in ipairs(segments) do
            fullSegments[#fullSegments + 1] = segment
        end
        pushLightningFx(state, fullSegments)
    else
        pushLightningFx(state, {
            {
                fromX = state.player.x,
                fromY = state.player.y,
                toX = target.x,
                toY = target.y,
            },
        })
    end
    return addEssence(state, reward)
end

local function triggerFireball(state, mapData)
    local projectiles = state.bonuses.fireballCount
    for _ = 1, projectiles do
        local target = findNearestHostile(state, state.player.x, state.player.y)
        if not target then
            return
        end

        local pulseDamage = state.bonuses.fireballDamage
        local bossDamage = state.bonuses.fireballDamage
        local maxHits = math.max(3, projectiles + 1)
        if target.kind == "boss" then
            pulseDamage = pulseDamage * 0.6
            maxHits = math.max(2, projectiles)
        end

        spawnFireballProjectile(
            state,
            state.player.x,
            state.player.y,
            target.x,
            target.y,
            state.bonuses.fireballRadius,
            pulseDamage,
            bossDamage,
            maxHits
        )
    end
    return false
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
    if addEssence(state, reward) then
        return true
    end

    if state.boss.active and not state.boss.defeated then
        local dist = Boss.distanceTo(state.boss, state.player.x, state.player.y)
        if dist <= state.bonuses.frostRadius + state.boss.radius then
            Boss.applyDamage(state, state.bonuses.frostDamage * 0.7)
        end
    end
    return false
end

function PassiveCombat.tickPassives(state, dt, mapData)
    local passives = state.passives
    local bonuses = state.bonuses

    if bonuses.lightningEnabled then
        passives.lightningTimer = passives.lightningTimer - dt
        while passives.lightningTimer <= 0 do
            passives.lightningTimer = passives.lightningTimer + bonuses.lightningInterval
            if triggerLightning(state, mapData) or state.mode == "run_choice" then
                return
            end
        end
    end

    if bonuses.fireballEnabled then
        passives.fireballTimer = passives.fireballTimer - dt
        while passives.fireballTimer <= 0 do
            passives.fireballTimer = passives.fireballTimer + bonuses.fireballInterval
            if triggerFireball(state, mapData) or state.mode == "run_choice" then
                return
            end
        end
    end

    if bonuses.frostEnabled then
        passives.frostPulseTimer = passives.frostPulseTimer - dt
        while passives.frostPulseTimer <= 0 do
            passives.frostPulseTimer = passives.frostPulseTimer + bonuses.frostInterval
            if triggerFrost(state, mapData) or state.mode == "run_choice" then
                return
            end
        end
    end
end

return PassiveCombat
