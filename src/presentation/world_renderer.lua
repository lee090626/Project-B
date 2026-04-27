local C = require("src.constants")
local Player = require("src.player_controller")
local MapSystem = require("src.map_system")

local WorldRenderer = {}

local function currentMapColor(mapId)
    if mapId == 1 then
        return { 0.12, 0.17, 0.12 }, { 0.2, 0.32, 0.2 }
    elseif mapId == 2 then
        return { 0.08, 0.09, 0.15 }, { 0.16, 0.18, 0.28 }
    elseif mapId == 3 then
        return { 0.2, 0.08, 0.06 }, { 0.38, 0.13, 0.1 }
    end
    return { 0.08, 0.05, 0.1 }, { 0.19, 0.1, 0.25 }
end

function WorldRenderer.draw(state, assets)
    local mapData = MapSystem.getCurrentMap(state.maps)
    local bgA, bgB = currentMapColor(mapData.id)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    love.graphics.setColor(bgA)
    love.graphics.rectangle("fill", 0, 0, sw, sh)
    love.graphics.setColor(bgB)
    love.graphics.rectangle("fill", 0, sh * 0.52, sw, sh * 0.48)

    love.graphics.push()
    love.graphics.scale(state.camera.zoom)
    love.graphics.translate(-state.camera.x, -state.camera.y)

    love.graphics.setColor(0.15, 0.15, 0.15, 0.35)
    for x = 0, C.WORLD_WIDTH, 80 do
        love.graphics.line(x, 0, x, C.WORLD_HEIGHT)
    end
    for y = 0, C.WORLD_HEIGHT, 80 do
        love.graphics.line(0, y, C.WORLD_WIDTH, y)
    end

    for _, item in ipairs(state.food.list) do
        local flash = 0.2 + (item.hitFlash or 0) * 0.4
        love.graphics.setColor(item.color)
        love.graphics.circle("fill", item.x, item.y, item.radius)
        love.graphics.setColor(1, 1, 1, flash)
        love.graphics.circle("line", item.x, item.y, item.radius + 1)

        local hpPct = item.maxHp > 0 and math.max(0, item.hp / item.maxHp) or 0
        local barW = item.radius * 2.1
        local barX = item.x - barW * 0.5
        local barY = item.y - item.radius - 8
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", barX, barY, barW, 4)
        love.graphics.setColor(0.55, 1.0, 0.62)
        love.graphics.rectangle("fill", barX + 1, barY + 1, math.max(0, (barW - 2) * hpPct), 2)
    end

    if state.boss.active or state.boss.defeated then
        local pulse = state.boss.active and (math.sin(state.boss.pulse * 4) * 0.08 + 0.92) or 0.6
        local flash = state.boss.hitFlash or 0
        love.graphics.setColor(0.9 * pulse + flash * 0.25, 0.25 * pulse + flash * 0.15, 0.2 * pulse + flash * 0.15)
        love.graphics.circle("fill", state.boss.x, state.boss.y, state.boss.radius)
        love.graphics.setColor(0.2, 0.05, 0.05)
        love.graphics.circle("line", state.boss.x, state.boss.y, state.boss.radius + 4)
    end

    local eatRadius = Player.getEatRadius(state.player, state.bonuses)
    local magnetRadius = state.player.magnetRadius or Player.getMagnetRadius(state.player, state.bonuses)

    love.graphics.setColor(0.9, 0.8, 0.2, 0.12)
    love.graphics.circle("fill", state.player.x, state.player.y, magnetRadius)

    if assets and assets.playerSprite then
        local sprite = assets.playerSprite
        local iw = sprite:getWidth()
        local ih = sprite:getHeight()
        local targetSize = state.player.radius * 3
        local sx = targetSize / iw
        local sy = targetSize / ih
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(sprite, state.player.x, state.player.y, 0, sx, sy, iw * 0.5, ih * 0.5)
    else
        love.graphics.setColor(0.9, 0.45, 0.3)
        love.graphics.circle("fill", state.player.x, state.player.y, state.player.radius)
        love.graphics.setColor(1, 0.9, 0.75)
        love.graphics.circle("fill", state.player.x + 5, state.player.y - 4, 2)
    end

    love.graphics.setColor(0.95, 0.7, 0.3, 0.25)
    love.graphics.circle("line", state.player.x, state.player.y, eatRadius)

    if state.passives then
        if state.passives.frostFxTimer and state.passives.frostFxTimer > 0 then
            local a = state.passives.frostFxTimer / 0.22
            love.graphics.setColor(0.55, 0.85, 1.0, 0.24 * a)
            love.graphics.circle("fill", state.player.x, state.player.y, state.passives.frostFxRadius or 0)
            love.graphics.setColor(0.8, 0.95, 1.0, 0.45 * a)
            love.graphics.circle("line", state.player.x, state.player.y, state.passives.frostFxRadius or 0)
        end

        if state.passives.lightningFx then
            local fx = state.passives.lightningFx
            local a = math.max(0, fx.timer / 0.12)
            love.graphics.setColor(0.8, 0.95, 1.0, a)
            love.graphics.setLineWidth(3)
            love.graphics.line(fx.fromX, fx.fromY, fx.toX, fx.toY)
        end

        if state.passives.fireballFx then
            local fx = state.passives.fireballFx
            local a = math.max(0, fx.timer / 0.2)
            love.graphics.setColor(1.0, 0.65, 0.2, a)
            love.graphics.setLineWidth(2)
            love.graphics.line(fx.fromX, fx.fromY, fx.toX, fx.toY)
            love.graphics.setColor(1.0, 0.42, 0.16, 0.18 * a)
            love.graphics.circle("fill", fx.toX, fx.toY, fx.radius or 0)
        end
    end

    love.graphics.pop()
end

return WorldRenderer
