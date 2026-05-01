local C = require("src.constants")
local Player = require("src.player_controller")
local Utils = require("src.presentation.world_render_utils")

local WorldEntityRenderer = {}

local MONSTER_SPRITE_SCALE = {
    common = 1.95,
    rare = 2.05,
    elite = 2.15,
}

local MONSTER_BOB = {
    common = 2,
    rare = 3,
    elite = 4,
}

local MONSTER_RARE_SWAY = math.rad(4)

local function monsterSpriteFor(item, assets, mapId)
    local tier = item.tier or "common"
    local mapSprites = assets
        and assets.monsterSpritesByMap
        and assets.monsterSpritesByMap[item.mapId or mapId]

    if item.eventTarget and mapSprites and mapSprites.events then
        local eventSprite = mapSprites.events[item.eventKind]
        if eventSprite then
            return eventSprite, tier
        end
    end
    if mapSprites and mapSprites[tier] then
        return mapSprites[tier], tier
    end
    return assets and assets.monsterSprites and assets.monsterSprites[tier], tier
end

local function drawMonsterSprite(item, assets, time, mapId)
    local tier = item.tier or "common"
    local sprite
    sprite, tier = monsterSpriteFor(item, assets, mapId)
    if not sprite then
        return nil
    end

    local phase = time * 2.1 + item.x * 0.01 + item.y * 0.008
    local renderX = item.x
    local renderY = item.y + math.sin(phase) * (MONSTER_BOB[tier] or 2)
    local rotation = tier == "rare" and not item.eventTarget and math.sin(phase * 0.85) * MONSTER_RARE_SWAY or 0
    if tier == "elite" then
        local glowAlpha = 0.12 + (math.sin(phase * 1.35) * 0.5 + 0.5) * 0.08
        love.graphics.setColor(item.color[1], item.color[2], item.color[3], glowAlpha)
        love.graphics.circle("fill", renderX, renderY, item.radius * 1.85)
    end

    Utils.drawSpriteCentered(
        sprite,
        renderX,
        renderY,
        item.radius * 3.0 * (MONSTER_SPRITE_SCALE[tier] or 1.0),
        rotation
    )
    return renderX, renderY
end

local function drawBossWeakPointSprite(point, assets, time)
    local sprite = assets and assets.bossWeakPointSprite
    if not sprite then
        return nil
    end

    local phase = time * 3.0 + point.x * 0.015 + point.y * 0.011
    local renderX = point.x
    local renderY = point.y + math.sin(phase) * 1.8
    local pulse = 0.97 + math.sin(phase * 1.4) * 0.04
    love.graphics.setColor(1.0, 0.72, 0.18, 0.14)
    love.graphics.circle("fill", renderX, renderY, point.radius * 1.45)
    Utils.drawSpriteCentered(sprite, renderX, renderY, point.radius * 2.8 * pulse, 0)
    return renderX, renderY
end

local function drawBossSprite(state, assets)
    local sprite = assets and assets.bossSprite
    if not sprite then
        return nil
    end

    local boss = state.boss
    local renderX = boss.x
    local renderY = boss.y + (boss.active and math.sin(boss.pulse * 1.8) * 4 or 0)
    local pulse = boss.active and (math.sin(boss.pulse * 4) * 0.08 + 0.92) or 0.6
    local spritePulse = 0.98 + math.sin(boss.pulse * 2.2) * 0.03
    if boss.shielded then
        love.graphics.setColor(0.32, 0.08, 0.08, 0.18)
        love.graphics.circle("fill", renderX, renderY, boss.radius + 20)
    elseif boss.active then
        love.graphics.setColor(1.0, 0.56, 0.22, 0.18 + (boss.vulnerableTimer or 0) * 0.08)
        love.graphics.circle("fill", renderX, renderY, boss.radius + 22)
    end

    local alpha = boss.defeated and 0.72 or 1.0
    Utils.drawSpriteCentered(sprite, renderX, renderY, boss.radius * 3.2 * spritePulse, 0, { 1, 1, 1, alpha })
    return renderX, renderY, pulse
end

local function drawPlayerSprite(state, assets)
    local targetSize = state.player.radius * C.PLAYER_SPRITE.targetScale
    local facingX = state.player.facingX or -1
    local flip = facingX < 0 and 1 or -1
    local animation = assets and assets.playerWalkAnimation

    if animation and animation.image and animation.quads then
        local frame = animation.idleFrame or 1
        if state.player.isMoving then
            frame = math.floor((state.player.walkTimer or 0) * animation.fps) % animation.frameCount + 1
        end
        local quad = animation.quads[frame]
        if quad then
            local scale = targetSize / math.max(animation.frameWidth, animation.frameHeight)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                animation.image,
                quad,
                state.player.x,
                state.player.y,
                0,
                scale * flip,
                scale,
                animation.frameWidth * 0.5,
                animation.frameHeight * 0.5
            )
            return true
        end
    end

    local sprite = assets and assets.playerSprite
    if sprite then
        local iw = sprite:getWidth()
        local ih = sprite:getHeight()
        local sx = targetSize / iw
        local sy = targetSize / ih
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(sprite, state.player.x, state.player.y, 0, sx * flip, sy, iw * 0.5, ih * 0.5)
        return true
    end

    return false
end

local function drawHpBar(centerX, topY, width, pct, fillColor, bgAlpha)
    pct = math.max(0, pct or 0)
    local x = centerX - width * 0.5
    love.graphics.setColor(0, 0, 0, bgAlpha)
    love.graphics.rectangle("fill", x, topY, width, 4)
    love.graphics.setColor(fillColor)
    love.graphics.rectangle("fill", x + 1, topY + 1, math.max(0, (width - 2) * pct), 2)
end

function WorldEntityRenderer.drawBossArena(state, view)
    if state.mode == "boss_arena" and state.boss.active then
        local arenaX = (state.player.x + state.boss.x) * 0.5
        local arenaY = (state.player.y + state.boss.y) * 0.5
        local arenaRadius = C.BOSS_ARENA.weakPointOrbitRadius + 200
        if Utils.isCircleInView(arenaX, arenaY, arenaRadius, view) then
            love.graphics.setColor(0.32, 0.09, 0.06, 0.18)
            love.graphics.circle("fill", arenaX, arenaY, arenaRadius)
            love.graphics.setColor(0.96, 0.52, 0.22, 0.65)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", arenaX, arenaY, arenaRadius)
        end
    end
end

function WorldEntityRenderer.drawFood(state, assets, view)
    for _, item in ipairs(state.food.list) do
        if Utils.isCircleInView(item.x, item.y, item.radius + 10, view) then
            local renderX, renderY = drawMonsterSprite(
                item,
                assets,
                state.totalPlayTime or 0,
                state.maps and state.maps.currentMapId
            )
            local drawX = renderX or item.x
            local drawY = renderY or item.y
            local flash = 0.2 + (item.hitFlash or 0) * 0.4
            if not renderX then
                love.graphics.setColor(item.color)
                love.graphics.circle("fill", drawX, drawY, item.radius)
            end

            love.graphics.setColor(1, 1, 1, flash)
            love.graphics.circle("line", drawX, drawY, item.radius + 1)
            if item.eventTarget then
                local pulse = 0.82 + math.sin((state.totalPlayTime or 0) * 6 + item.eventId) * 0.18
                local lineColor = item.eventKind == "final" and { 1.0, 0.74, 0.3, 0.92 } or { 0.48, 0.96, 0.82, 0.9 }
                love.graphics.setColor(lineColor[1], lineColor[2], lineColor[3], lineColor[4])
                love.graphics.setLineWidth(3)
                love.graphics.circle("line", drawX, drawY, item.radius + 6 + (1 - pulse) * 3)
                love.graphics.setColor(lineColor[1], lineColor[2], lineColor[3], 0.28)
                love.graphics.circle("fill", drawX, drawY, item.radius + 4)
            end

            drawHpBar(
                drawX,
                drawY - item.radius - 8,
                item.radius * 2.1,
                item.maxHp > 0 and item.hp / item.maxHp or 0,
                { 0.55, 1.0, 0.62 },
                0.7
            )
        end
    end
end

function WorldEntityRenderer.drawBossWeakPoints(state, assets, view)
    if state.boss.active and state.boss.weakPoints then
        for _, point in ipairs(state.boss.weakPoints) do
            if Utils.isCircleInView(point.x, point.y, point.radius + 8, view) then
                local renderX, renderY = drawBossWeakPointSprite(point, assets, state.totalPlayTime or 0)
                local drawX = renderX or point.x
                local drawY = renderY or point.y
                local flash = 0.2 + (point.hitFlash or 0) * 0.5
                if not renderX then
                    love.graphics.setColor(0.88, 0.74 + flash * 0.15, 0.28 + flash * 0.1, 0.95)
                    love.graphics.circle("fill", drawX, drawY, point.radius)
                end

                love.graphics.setColor(1, 0.97, 0.84, 0.35 + flash * 0.55)
                love.graphics.setLineWidth(2)
                love.graphics.circle("line", drawX, drawY, point.radius + 2)

                drawHpBar(
                    drawX,
                    drawY - point.radius - 10,
                    point.radius * 2.0,
                    point.maxHp > 0 and point.hp / point.maxHp or 0,
                    { 1.0, 0.86, 0.44 },
                    0.72
                )
            end
        end
    end
end

function WorldEntityRenderer.drawBoss(state, assets, view)
    if (state.boss.active or state.boss.defeated)
        and Utils.isCircleInView(state.boss.x, state.boss.y, state.boss.radius + 6, view) then
        local renderX, renderY, pulse = drawBossSprite(state, assets)
        local drawX = renderX or state.boss.x
        local drawY = renderY or state.boss.y
        pulse = pulse or (state.boss.active and (math.sin(state.boss.pulse * 4) * 0.08 + 0.92) or 0.6)
        local flash = state.boss.hitFlash or 0
        if not renderX then
            if state.boss.active and not state.boss.shielded then
                love.graphics.setColor(1.0, 0.56, 0.22, 0.18 + (state.boss.vulnerableTimer or 0) * 0.08)
                love.graphics.circle("fill", drawX, drawY, state.boss.radius + 18)
            end
            love.graphics.setColor(0.9 * pulse + flash * 0.25, 0.25 * pulse + flash * 0.15, 0.2 * pulse + flash * 0.15)
            love.graphics.circle("fill", drawX, drawY, state.boss.radius)
        end

        if state.boss.shielded then
            love.graphics.setColor(0.48, 0.08, 0.08, 0.88)
            love.graphics.setLineWidth(4)
            love.graphics.circle("line", drawX, drawY, state.boss.radius + 10)
        elseif state.boss.active then
            love.graphics.setColor(1.0, 0.68, 0.28, 0.88)
            love.graphics.setLineWidth(4)
            love.graphics.circle("line", drawX, drawY, state.boss.radius + 12 + (1 - pulse) * 4)
        end

        love.graphics.setColor(1, 0.92, 0.88, 0.18 + flash * 0.38)
        love.graphics.circle("line", drawX, drawY, state.boss.radius + 4)
        love.graphics.setColor(0.2, 0.05, 0.05, 0.9)
        love.graphics.circle("line", drawX, drawY, state.boss.radius + 2)
    end
end

function WorldEntityRenderer.drawPlayer(state, assets, view)
    local eatRadius = Player.getEatRadius(state.player, state.bonuses)
    local magnetRadius = state.player.magnetRadius or Player.getMagnetRadius(state.player, state.bonuses)
    local pulse = 0.84 + math.sin((state.totalPlayTime or 0) * 2.8) * 0.16
    local playerVisible = Utils.isCircleInView(
        state.player.x,
        state.player.y,
        math.max(magnetRadius, eatRadius, state.player.radius * C.WORLD_THEME.playerAuraLineScale),
        view
    )

    if playerVisible then
        if magnetRadius <= C.WORLD_THEME.magnetFillCutoff then
            Utils.setPaletteColor(C.WORLD_THEME.magnetFill)
            love.graphics.circle("fill", state.player.x, state.player.y, magnetRadius)
        end

        Utils.setPaletteColor(C.WORLD_THEME.aura, 0.7)
        love.graphics.circle("fill", state.player.x, state.player.y, state.player.radius * (C.WORLD_THEME.playerAuraScale + pulse * 0.12))
        Utils.setPaletteColor(C.WORLD_THEME.auraLine, 0.75)
        love.graphics.circle("line", state.player.x, state.player.y, state.player.radius * (C.WORLD_THEME.playerAuraLineScale + pulse * 0.18))

        if not drawPlayerSprite(state, assets) then
            love.graphics.setColor(0.9, 0.45, 0.3)
            love.graphics.circle("fill", state.player.x, state.player.y, state.player.radius)
            love.graphics.setColor(1, 0.9, 0.75)
            love.graphics.circle("fill", state.player.x + 5, state.player.y - 4, 2)
        end

        love.graphics.setLineWidth(C.WORLD_THEME.magnetOutlineWidth)
        Utils.setPaletteColor(C.WORLD_THEME.magnetLine)
        love.graphics.circle("line", state.player.x, state.player.y, magnetRadius)
        love.graphics.circle("line", state.player.x, state.player.y, magnetRadius * (0.18 + pulse * 0.04))
        Utils.setPaletteColor(C.WORLD_THEME.eatLine)
        love.graphics.circle("line", state.player.x, state.player.y, eatRadius)
    end

    return playerVisible
end

return WorldEntityRenderer
