local C = require("src.constants")
local Utils = require("src.utils")
local Food = require("src.food_system")
local Boss = require("src.boss_system")
local MapSystem = require("src.map_system")
local Mutation = require("src.mutation_system")

local PassiveCombat = {}

function PassiveCombat.resetState(state)
    state.passives = {
        lightningTimer = 0.35,
        fireballTimer = 0.6,
        lightningFx = nil,
        fireballProjectiles = {},
        fireballImpacts = {},
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

local function spawnFireballProjectile(state, fromX, fromY, toX, toY, radius, pulseDamage, bossDamage, maxHits, targetKind, targetIndex)
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
        targetKind = targetKind,
        targetIndex = targetIndex,
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

                if projectile.targetKind == "weak_point" then
                    local weakIndex, weakPoint, weakDist = Boss.getNearestWeakPoint(state, projectile.targetX, projectile.targetY)
                    if weakPoint and weakDist <= projectile.radius + weakPoint.radius then
                        Boss.applyWeakPointDamage(state, weakIndex, projectile.bossDamage)
                    end
                elseif state.boss.active and not state.boss.defeated then
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
                    projectile.maxHits,
                    "fireball"
                )
                table.remove(passives.fireballProjectiles, i)
                if addEssence(state, reward) then
                    return
                end
            end
        end
    end
    passives.eatFxTimer = math.max(0, passives.eatFxTimer - dt)
end

local function findNearestHostile(state, fromX, fromY)
    if state.mode == "boss_arena" then
        return Boss.getPriorityTarget(state, fromX, fromY)
    end

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

local function collectFireballTargets(state, fromX, fromY)
    local targets = {}

    if state.mode == "boss_arena" then
        if state.boss.active and not state.boss.defeated then
            if state.boss.shielded then
                for index, point in ipairs(state.boss.weakPoints or {}) do
                    targets[#targets + 1] = {
                        kind = "weak_point",
                        index = index,
                        dist = Utils.distance(fromX, fromY, point.x, point.y),
                        x = point.x,
                        y = point.y,
                        radius = point.radius,
                    }
                end
            else
                targets[#targets + 1] = {
                    kind = "boss",
                    dist = Boss.distanceTo(state.boss, fromX, fromY),
                    x = state.boss.x,
                    y = state.boss.y,
                    radius = state.boss.radius,
                }
            end
        end
    else
        for index, item in ipairs(state.food.list) do
            targets[#targets + 1] = {
                kind = "food",
                index = index,
                dist = Utils.distance(fromX, fromY, item.x, item.y),
                x = item.x,
                y = item.y,
                radius = item.radius,
            }
        end
    end

    table.sort(targets, function(a, b)
        return a.dist < b.dist
    end)

    return targets
end

local function getFireballAimPoint(target, shotIndex, totalShots, impactRadius)
    if totalShots <= 1 then
        return target.x, target.y
    end

    local spreadRadius = math.min(
        impactRadius * 0.3,
        math.max(10, (target.radius or 0) * 0.45)
    )
    local angle = ((shotIndex - 1) / totalShots) * math.pi * 2
    return target.x + math.cos(angle) * spreadRadius, target.y + math.sin(angle) * spreadRadius
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
        Boss.applyDamage(state, math.max(1, state.bonuses.lightningDamage * 0.18))
        return false
    elseif target.kind == "weak_point" then
        pushLightningFx(state, {
            {
                fromX = state.player.x,
                fromY = state.player.y,
                toX = target.x,
                toY = target.y,
            },
        })
        Boss.applyWeakPointDamage(state, target.index, math.max(1, state.bonuses.lightningDamage * 0.18))
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
    local targets = collectFireballTargets(state, state.player.x, state.player.y)
    if #targets == 0 then
        return false
    end

    for shotIndex = 1, projectiles do
        local target = targets[((shotIndex - 1) % #targets) + 1]
        local targetX, targetY = getFireballAimPoint(target, shotIndex, projectiles, state.bonuses.fireballRadius)

        local pulseDamage = state.bonuses.fireballDamage
        local bossDamage = state.bonuses.fireballDamage * 0.35
        local maxHits = math.max(3, projectiles + 1)
        if target.kind == "boss" then
            pulseDamage = pulseDamage * 0.6
            maxHits = math.max(2, projectiles)
        elseif target.kind == "weak_point" then
            bossDamage = state.bonuses.fireballDamage * 0.35
        end

        spawnFireballProjectile(
            state,
            state.player.x,
            state.player.y,
            targetX,
            targetY,
            state.bonuses.fireballRadius,
            pulseDamage,
            bossDamage,
            maxHits,
            target.kind,
            target.index
        )
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
end

return PassiveCombat
