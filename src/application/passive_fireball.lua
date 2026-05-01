local C = require("src.constants")
local Utils = require("src.utils")
local Food = require("src.food_system")
local Boss = require("src.boss_system")

local PassiveFireball = {}

local function spawnProjectile(state, fromX, fromY, toX, toY, radius, pulseDamage, bossDamage, maxHits, targetKind, targetIndex)
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

local function pushImpact(state, x, y, radius)
    state.passives.fireballImpacts[#state.passives.fireballImpacts + 1] = {
        x = x,
        y = y,
        radius = radius,
        timer = C.PASSIVE_BASES.fireball.impactFxDuration,
    }
end

local function collectTargets(state, fromX, fromY)
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

local function getAimPoint(target, shotIndex, totalShots, impactRadius)
    if totalShots <= 1 then
        return target.x, target.y
    end

    local spreadRadius = math.min(
        impactRadius * C.PASSIVE_BASES.fireball.spreadRadiusScale,
        math.max(
            C.PASSIVE_BASES.fireball.spreadMinRadius,
            (target.radius or 0) * C.PASSIVE_BASES.fireball.spreadTargetRadiusScale
        )
    )
    local angle = ((shotIndex - 1) / totalShots) * math.pi * 2
    return target.x + math.cos(angle) * spreadRadius, target.y + math.sin(angle) * spreadRadius
end

function PassiveFireball.tickFx(state, dt, mapData, grantEssence)
    local passives = state.passives

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
                pushImpact(state, projectile.x, projectile.y, projectile.radius)

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
                if grantEssence(reward) then
                    return true
                end
            end
        end
    end

    return false
end

function PassiveFireball.trigger(state)
    local projectiles = state.bonuses.fireballCount
    local targets = collectTargets(state, state.player.x, state.player.y)
    if #targets == 0 then
        return false
    end

    for shotIndex = 1, projectiles do
        local target = targets[((shotIndex - 1) % #targets) + 1]
        local targetX, targetY = getAimPoint(target, shotIndex, projectiles, state.bonuses.fireballRadius)

        local pulseDamage = state.bonuses.fireballDamage
        local bossDamage = state.bonuses.fireballDamage * C.PASSIVE_BASES.fireball.bossDamageMultiplier
        local maxHits = math.max(
            C.PASSIVE_BASES.fireball.minFoodHits,
            projectiles + C.PASSIVE_BASES.fireball.hitCountPerProjectileBonus
        )
        if target.kind == "boss" then
            pulseDamage = pulseDamage * C.PASSIVE_BASES.fireball.bossPulseDamageMultiplier
            maxHits = math.max(C.PASSIVE_BASES.fireball.minBossHits, projectiles)
        elseif target.kind == "weak_point" then
            bossDamage = state.bonuses.fireballDamage * C.PASSIVE_BASES.fireball.bossDamageMultiplier
        end

        spawnProjectile(
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

return PassiveFireball
