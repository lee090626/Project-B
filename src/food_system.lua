local C = require("src.constants")
local Utils = require("src.utils")

local Food = {}

local function randomTier(mapSpawn, bonuses)
    local rareChance = mapSpawn.rare + (bonuses.rareBonus or 0)
    local eliteChance = mapSpawn.elite + (bonuses.eliteBonus or 0)

    eliteChance = Utils.clamp(eliteChance, 0.0, 0.65)
    rareChance = Utils.clamp(rareChance, 0.0, 0.9 - eliteChance)

    local roll = love.math.random()
    if roll < eliteChance then
        return "elite"
    end
    if roll < eliteChance + rareChance then
        return "rare"
    end
    return "common"
end

local function rewardMultiplierForTier(tier, bonuses)
    if tier == "rare" then
        return bonuses.rareValue or 1
    elseif tier == "elite" then
        return bonuses.eliteValue or 1
    end
    return 1
end

local function rewardForKill(item, mapData, bonuses)
    local essenceMult = bonuses.essenceMult or 1
    local tierMult = rewardMultiplierForTier(item.tier, bonuses)
    return item.essence * mapData.reward * essenceMult * tierMult
end

function Food.new(savedFood)
    local system = {
        list = {},
        spawnTimer = 0,
        consumedTotal = 0,
    }

    if savedFood then
        system.consumedTotal = savedFood.consumedTotal or 0
    end

    return system
end

function Food.export(food)
    return {
        consumedTotal = food.consumedTotal,
    }
end

function Food.spawnOne(food, mapData, bonuses)
    local tier = randomTier(mapData.spawn, bonuses)
    local info = C.FOOD_BY_TIER[tier]
    local edgePad = 40
    local hpScale = mapData.hpScale or 1

    local item = {
        x = love.math.random(edgePad, C.WORLD_WIDTH - edgePad),
        y = love.math.random(edgePad, C.WORLD_HEIGHT - edgePad),
        vx = love.math.random(-100, 100) * 0.01,
        vy = love.math.random(-100, 100) * 0.01,
        tier = tier,
        radius = info.radius,
        essence = info.essence,
        color = info.color,
        speed = info.speed,
        maxHp = math.floor(info.hp * hpScale + 0.5),
        hp = math.floor(info.hp * hpScale + 0.5),
        slowFactor = 0,
        slowTimer = 0,
        hitFlash = 0,
    }

    food.list[#food.list + 1] = item
end

function Food.update(food, dt, mapData, bonuses, player)
    food.spawnTimer = food.spawnTimer - dt

    local targetCount = C.MAX_FOOD + math.floor((bonuses.spawnCap or 0) + 0.5)
    targetCount = math.max(20, targetCount)
    if #food.list < targetCount and food.spawnTimer <= 0 then
        Food.spawnOne(food, mapData, bonuses)
        local spawnRate = math.max(0, bonuses.spawnRate or 0)
        food.spawnTimer = C.FOOD_SPAWN_INTERVAL / (1 + spawnRate)
    end

    local magnetRadius = player and player.magnetRadius or 0
    for i = #food.list, 1, -1 do
        local item = food.list[i]

        item.hitFlash = math.max(0, item.hitFlash - dt * 4)
        item.slowTimer = math.max(0, item.slowTimer - dt)
        if item.slowTimer <= 0 then
            item.slowFactor = 0
        end

        if player and magnetRadius > 0 then
            local dx = player.x - item.x
            local dy = player.y - item.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0 and dist < magnetRadius then
                local pull = (magnetRadius - dist) / magnetRadius
                item.vx = item.vx + (dx / dist) * pull * 90 * dt
                item.vy = item.vy + (dy / dist) * pull * 90 * dt
            end
        end

        local noiseX = love.math.random(-100, 100) * 0.003
        local noiseY = love.math.random(-100, 100) * 0.003
        item.vx = Utils.clamp(item.vx + noiseX, -1.0, 1.0)
        item.vy = Utils.clamp(item.vy + noiseY, -1.0, 1.0)

        local slowScale = 1 - Utils.clamp(item.slowFactor, 0, 0.85)
        item.x = item.x + item.vx * item.speed * slowScale * dt
        item.y = item.y + item.vy * item.speed * slowScale * dt

        if item.x < 20 or item.x > C.WORLD_WIDTH - 20 then
            item.vx = -item.vx
            item.x = Utils.clamp(item.x, 20, C.WORLD_WIDTH - 20)
        end
        if item.y < 20 or item.y > C.WORLD_HEIGHT - 20 then
            item.vy = -item.vy
            item.y = Utils.clamp(item.y, 20, C.WORLD_HEIGHT - 20)
        end
    end
end

function Food.applyDamageAtIndex(food, index, damage, mapData, bonuses)
    local item = food.list[index]
    if not item or damage <= 0 then
        return 0, false, nil
    end

    item.hp = item.hp - damage
    item.hitFlash = 0.9
    if item.hp > 0 then
        return 0, false, item
    end

    local reward = rewardForKill(item, mapData, bonuses)
    food.consumedTotal = food.consumedTotal + 1
    table.remove(food.list, index)
    return reward, true, item
end

function Food.applySlow(item, slowPower, duration)
    if not item then
        return
    end
    item.slowFactor = math.max(item.slowFactor or 0, slowPower or 0)
    item.slowTimer = math.max(item.slowTimer or 0, duration or 0)
end

function Food.findNearestTarget(food, x, y)
    local bestIndex
    local bestItem
    local bestDist = math.huge

    for i, item in ipairs(food.list) do
        local dist = Utils.distance(x, y, item.x, item.y)
        if dist < bestDist then
            bestDist = dist
            bestIndex = i
            bestItem = item
        end
    end

    return bestIndex, bestItem, bestDist
end

function Food.damageTouching(food, player, eatRadius, dps, dt, mapData, bonuses)
    local essenceGain = 0
    local killed = 0
    local totalDamage = dps * dt

    for i = #food.list, 1, -1 do
        local item = food.list[i]
        local dist = Utils.distance(player.x, player.y, item.x, item.y)
        if dist <= eatRadius + item.radius then
            local reward, didKill = Food.applyDamageAtIndex(food, i, totalDamage, mapData, bonuses)
            essenceGain = essenceGain + reward
            if didKill then
                killed = killed + 1
            end
        end
    end

    return essenceGain, killed
end

function Food.damagePulse(food, x, y, radius, damage, mapData, bonuses, slowPower, slowDuration, maxHits)
    local essenceGain = 0
    local killed = 0
    local hits = 0

    for i = #food.list, 1, -1 do
        local item = food.list[i]
        local dist = Utils.distance(x, y, item.x, item.y)
        if dist <= radius + item.radius then
            if slowPower and slowPower > 0 then
                Food.applySlow(item, slowPower, slowDuration)
            end
            local reward, didKill = Food.applyDamageAtIndex(food, i, damage, mapData, bonuses)
            essenceGain = essenceGain + reward
            hits = hits + 1
            if didKill then
                killed = killed + 1
            end
            if maxHits and hits >= maxHits then
                break
            end
        end
    end

    return essenceGain, killed, hits
end

local function findIndexByItem(food, targetItem)
    for i, item in ipairs(food.list) do
        if item == targetItem then
            return i
        end
    end
    return nil
end

local function buildLightningRoute(food, startIndex, chainCount, chainRadius)
    local route = {}
    local currentItem = food.list[startIndex]
    local hitItems = {}
    local maxJump = chainRadius or math.huge

    while currentItem and #route < chainCount do
        route[#route + 1] = currentItem
        hitItems[currentItem] = true

        local bestItem
        local bestDist = math.huge
        for _, nextItem in ipairs(food.list) do
            if not hitItems[nextItem] then
                local dist = Utils.distance(currentItem.x, currentItem.y, nextItem.x, nextItem.y)
                if dist <= maxJump and dist < bestDist then
                    bestDist = dist
                    bestItem = nextItem
                end
            end
        end
        currentItem = bestItem
    end

    return route
end

local function buildLightningSegments(route)
    local segments = {}
    for i = 1, #route - 1 do
        local fromItem = route[i]
        local toItem = route[i + 1]
        segments[#segments + 1] = {
            fromX = fromItem.x,
            fromY = fromItem.y,
            toX = toItem.x,
            toY = toItem.y,
        }
    end
    return segments
end

function Food.chainLightning(food, startIndex, damage, chainCount, chainRadius, mapData, bonuses)
    local essenceGain = 0
    local killed = 0
    local hitCount = 0
    local route = buildLightningRoute(food, startIndex, chainCount, chainRadius)
    local segments = buildLightningSegments(route)

    for _, item in ipairs(route) do
        local currentIndex = findIndexByItem(food, item)
        if currentIndex then
            local reward, didKill = Food.applyDamageAtIndex(food, currentIndex, damage, mapData, bonuses)
            essenceGain = essenceGain + reward
            hitCount = hitCount + 1
            if didKill then
                killed = killed + 1
            end
        end
    end

    return essenceGain, killed, hitCount, segments
end

return Food
