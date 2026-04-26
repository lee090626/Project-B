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

function Food.consumeNearby(food, player, eatRadius, mapReward, bonuses)
    local essenceGain = 0
    local consumed = 0

    local essenceMult = bonuses.essenceMult or 1

    for i = #food.list, 1, -1 do
        local item = food.list[i]
        local dist = Utils.distance(player.x, player.y, item.x, item.y)
        if dist <= eatRadius + item.radius then
            essenceGain = essenceGain + item.essence * mapReward * essenceMult
            consumed = consumed + 1
            table.remove(food.list, i)
        end
    end

    food.consumedTotal = food.consumedTotal + consumed
    return essenceGain, consumed
end

return Food
