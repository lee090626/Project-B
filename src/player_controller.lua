local Utils = require("src.utils")
local C = require("src.constants")

local Player = {}

function Player.new(savedPlayer)
    local p = {
        x = C.WORLD_WIDTH * 0.5,
        y = C.WORLD_HEIGHT * 0.5,
        radius = 18,
        baseSpeed = 120,
        baseReach = 25,
        baseMagnet = 0,
        facingX = -1,
        isMoving = false,
        walkTimer = 0,
    }

    if savedPlayer then
        p.x = savedPlayer.x or p.x
        p.y = savedPlayer.y or p.y
    end

    return p
end

function Player.export(player)
    return {
        x = player.x,
        y = player.y,
    }
end

function Player.update(player, dt, mouseWorldX, mouseWorldY, bonuses)
    local speed = player.baseSpeed + bonuses.speed
    local dx = mouseWorldX - player.x
    local dy = mouseWorldY - player.y
    local dist = math.sqrt(dx * dx + dy * dy)
    local moved = false

    if dist > 0.1 then
        local move = math.min(dist, speed * dt)
        if math.abs(dx) > 0.1 then
            player.facingX = dx < 0 and -1 or 1
        end
        player.x = player.x + (dx / dist) * move
        player.y = player.y + (dy / dist) * move
        moved = move > 0.001
    end

    player.isMoving = moved
    if moved then
        player.walkTimer = (player.walkTimer or 0) + dt
    else
        player.walkTimer = 0
    end

    player.x = Utils.clamp(player.x, 0, C.WORLD_WIDTH)
    player.y = Utils.clamp(player.y, 0, C.WORLD_HEIGHT)
end

function Player.getEatRadius(player, bonuses)
    return player.radius + player.baseReach + bonuses.reach
end

function Player.getMagnetRadius(player, bonuses)
    return Player.getEatRadius(player, bonuses) + player.baseMagnet + bonuses.magnet
end

return Player
