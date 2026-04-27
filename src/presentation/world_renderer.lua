local C = require("src.constants")
local Player = require("src.player_controller")
local MapSystem = require("src.map_system")

local WorldRenderer = {}

local cache = {
    backdrop = nil,
    backdropKey = nil,
    pattern = nil,
    patternKey = nil,
}

local function angleFromVector(dx, dy)
    if dx == 0 then
        if dy > 0 then
            return math.pi * 0.5
        elseif dy < 0 then
            return -math.pi * 0.5
        end
        return 0
    end

    local angle = math.atan(dy / dx)
    if dx < 0 then
        angle = angle + math.pi
    end
    return angle
end

local function currentMapTheme(mapId)
    return C.WORLD_THEME.maps[mapId] or C.WORLD_THEME.maps[4]
end

local function setPaletteColor(color, alphaMul)
    local a = (color[4] or 1) * (alphaMul or 1)
    love.graphics.setColor(color[1], color[2], color[3], a)
end

local function drawWorldBackdrop(sw, sh, mapTheme)
    setPaletteColor(mapTheme.sky)
    love.graphics.rectangle("fill", 0, 0, sw, sh)
    setPaletteColor(mapTheme.ground)
    love.graphics.rectangle("fill", 0, sh * 0.52, sw, sh * 0.48)
    setPaletteColor(mapTheme.glow)
    love.graphics.circle("fill", sw * 0.5, sh * 0.4, math.min(sw, sh) * 0.38)
    setPaletteColor(C.WORLD_THEME.vignette)
    love.graphics.rectangle("fill", 0, 0, sw, 70)
    love.graphics.rectangle("fill", 0, sh - 90, sw, 90)
    love.graphics.rectangle("fill", 0, 0, 80, sh)
    love.graphics.rectangle("fill", sw - 80, 0, 80, sh)
end

local function drawMapPattern(mapId, mapTheme)
    love.graphics.setLineWidth(1)
    setPaletteColor(mapTheme.grid)
    for x = 0, C.WORLD_WIDTH, 80 do
        love.graphics.line(x, 0, x, C.WORLD_HEIGHT)
    end
    for y = 0, C.WORLD_HEIGHT, 80 do
        love.graphics.line(0, y, C.WORLD_WIDTH, y)
    end

    setPaletteColor(mapTheme.sigil)
    if mapId == 1 then
        for x = 40, C.WORLD_WIDTH, 240 do
            for y = 40, C.WORLD_HEIGHT, 240 do
                love.graphics.circle("line", x, y, 18)
            end
        end
    elseif mapId == 2 then
        for x = 80, C.WORLD_WIDTH, 220 do
            for y = 80, C.WORLD_HEIGHT, 220 do
                love.graphics.line(x - 14, y, x, y - 14)
                love.graphics.line(x, y - 14, x + 14, y)
                love.graphics.line(x + 14, y, x, y + 14)
                love.graphics.line(x, y + 14, x - 14, y)
            end
        end
    elseif mapId == 3 then
        for x = 0, C.WORLD_WIDTH, 180 do
            love.graphics.line(x, C.WORLD_HEIGHT * 0.55, x + 90, C.WORLD_HEIGHT)
        end
    else
        for x = 120, C.WORLD_WIDTH, 260 do
            for y = 120, C.WORLD_HEIGHT, 260 do
                love.graphics.arc("line", "open", x, y, 22, -math.pi * 0.3, math.pi * 1.1)
            end
        end
    end
end

local function rebuildBackdropCanvas(sw, sh, mapId, mapTheme)
    local key = string.format("%d:%dx%d", mapId, sw, sh)
    if cache.backdrop and cache.backdropKey == key then
        return cache.backdrop
    end

    local ok, canvas = pcall(love.graphics.newCanvas, sw, sh)
    if not ok or not canvas then
        cache.backdrop = nil
        cache.backdropKey = nil
        return nil
    end

    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    drawWorldBackdrop(sw, sh, mapTheme)
    love.graphics.setCanvas()
    love.graphics.pop()

    cache.backdrop = canvas
    cache.backdropKey = key
    return canvas
end

local function rebuildPatternCanvas(mapId, mapTheme)
    local key = tostring(mapId)
    if cache.pattern and cache.patternKey == key then
        return cache.pattern
    end

    local ok, canvas = pcall(love.graphics.newCanvas, C.WORLD_WIDTH, C.WORLD_HEIGHT)
    if not ok or not canvas then
        cache.pattern = nil
        cache.patternKey = nil
        return nil
    end

    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    setPaletteColor(C.WORLD_THEME.nestShadow)
    love.graphics.circle("fill", C.WORLD_WIDTH * 0.5, C.WORLD_HEIGHT * 0.52, math.min(C.WORLD_WIDTH, C.WORLD_HEIGHT) * 0.32)
    drawMapPattern(mapId, mapTheme)
    love.graphics.setCanvas()
    love.graphics.pop()

    cache.pattern = canvas
    cache.patternKey = key
    return canvas
end

local function getViewport(state, sw, sh)
    local left = state.camera.x
    local top = state.camera.y
    local right = left + sw / state.camera.zoom
    local bottom = top + sh / state.camera.zoom
    return left, top, right, bottom
end

local function isCircleVisible(x, y, radius, left, top, right, bottom, margin)
    local pad = radius + (margin or 0)
    return x + pad >= left and x - pad <= right and y + pad >= top and y - pad <= bottom
end

local function isSegmentVisible(x1, y1, x2, y2, left, top, right, bottom, margin)
    local pad = margin or 0
    local minX = math.min(x1, x2) - pad
    local maxX = math.max(x1, x2) + pad
    local minY = math.min(y1, y2) - pad
    local maxY = math.max(y1, y2) + pad
    return maxX >= left and minX <= right and maxY >= top and minY <= bottom
end

function WorldRenderer.draw(state, assets)
    local mapData = MapSystem.getCurrentMap(state.maps)
    local mapTheme = currentMapTheme(mapData.id)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local backdropCanvas = rebuildBackdropCanvas(sw, sh, mapData.id, mapTheme)
    local patternCanvas = rebuildPatternCanvas(mapData.id, mapTheme)

    if backdropCanvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(backdropCanvas, 0, 0)
    else
        drawWorldBackdrop(sw, sh, mapTheme)
    end

    local left, top, right, bottom = getViewport(state, sw, sh)
    local margin = C.WORLD_THEME.cullMargin

    love.graphics.push()
    love.graphics.scale(state.camera.zoom)
    love.graphics.translate(-state.camera.x, -state.camera.y)

    if patternCanvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(patternCanvas, 0, 0)
    else
        setPaletteColor(C.WORLD_THEME.nestShadow)
        love.graphics.circle("fill", C.WORLD_WIDTH * 0.5, C.WORLD_HEIGHT * 0.52, math.min(C.WORLD_WIDTH, C.WORLD_HEIGHT) * 0.32)
        drawMapPattern(mapData.id, mapTheme)
    end

    for _, item in ipairs(state.food.list) do
        if isCircleVisible(item.x, item.y, item.radius + 10, left, top, right, bottom, margin) then
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
    end

    if (state.boss.active or state.boss.defeated)
        and isCircleVisible(state.boss.x, state.boss.y, state.boss.radius + 6, left, top, right, bottom, margin) then
        local pulse = state.boss.active and (math.sin(state.boss.pulse * 4) * 0.08 + 0.92) or 0.6
        local flash = state.boss.hitFlash or 0
        love.graphics.setColor(0.9 * pulse + flash * 0.25, 0.25 * pulse + flash * 0.15, 0.2 * pulse + flash * 0.15)
        love.graphics.circle("fill", state.boss.x, state.boss.y, state.boss.radius)
        love.graphics.setColor(0.2, 0.05, 0.05)
        love.graphics.circle("line", state.boss.x, state.boss.y, state.boss.radius + 4)
    end

    local eatRadius = Player.getEatRadius(state.player, state.bonuses)
    local magnetRadius = state.player.magnetRadius or Player.getMagnetRadius(state.player, state.bonuses)
    local pulse = 0.84 + math.sin((state.totalPlayTime or 0) * 2.8) * 0.16
    local playerVisible = isCircleVisible(
        state.player.x,
        state.player.y,
        math.max(magnetRadius, eatRadius, state.player.radius * C.WORLD_THEME.playerAuraLineScale),
        left,
        top,
        right,
        bottom,
        margin
    )

    if playerVisible then
        if magnetRadius <= C.WORLD_THEME.magnetFillCutoff then
            setPaletteColor(C.WORLD_THEME.magnetFill)
            love.graphics.circle("fill", state.player.x, state.player.y, magnetRadius)
        end

        setPaletteColor(C.WORLD_THEME.aura, 0.7)
        love.graphics.circle("fill", state.player.x, state.player.y, state.player.radius * (C.WORLD_THEME.playerAuraScale + pulse * 0.12))
        setPaletteColor(C.WORLD_THEME.auraLine, 0.75)
        love.graphics.circle("line", state.player.x, state.player.y, state.player.radius * (C.WORLD_THEME.playerAuraLineScale + pulse * 0.18))

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

        love.graphics.setLineWidth(C.WORLD_THEME.magnetOutlineWidth)
        setPaletteColor(C.WORLD_THEME.magnetLine)
        love.graphics.circle("line", state.player.x, state.player.y, magnetRadius)
        love.graphics.circle("line", state.player.x, state.player.y, magnetRadius * (0.18 + pulse * 0.04))
        setPaletteColor(C.WORLD_THEME.eatLine)
        love.graphics.circle("line", state.player.x, state.player.y, eatRadius)
    end

    if state.passives then
        if state.passives.frostFxTimer and state.passives.frostFxTimer > 0
            and playerVisible then
            local a = state.passives.frostFxTimer / 0.22
            love.graphics.setColor(0.55, 0.85, 1.0, 0.24 * a)
            love.graphics.circle("fill", state.player.x, state.player.y, state.passives.frostFxRadius or 0)
            love.graphics.setColor(0.8, 0.95, 1.0, 0.45 * a)
            love.graphics.circle("line", state.player.x, state.player.y, state.passives.frostFxRadius or 0)
        end

        if state.passives.lightningFx then
            local fx = state.passives.lightningFx
            local a = math.max(0, fx.timer / 0.18)
            love.graphics.setColor(0.8, 0.95, 1.0, a)
            love.graphics.setLineWidth(4)
            for _, segment in ipairs(fx.segments or {}) do
                if isSegmentVisible(segment.fromX, segment.fromY, segment.toX, segment.toY, left, top, right, bottom, margin) then
                    love.graphics.line(segment.fromX, segment.fromY, segment.toX, segment.toY)
                    love.graphics.circle("fill", segment.toX, segment.toY, 4)
                end
            end
        end

        if state.passives.fireballProjectiles then
            for _, projectile in ipairs(state.passives.fireballProjectiles) do
                local projectileVisible = isCircleVisible(
                    projectile.x,
                    projectile.y,
                    math.max(12, projectile.radius * 0.75),
                    left,
                    top,
                    right,
                    bottom,
                    margin
                )
                local trailVisible = isSegmentVisible(
                    projectile.prevX,
                    projectile.prevY,
                    projectile.x,
                    projectile.y,
                    left,
                    top,
                    right,
                    bottom,
                    margin
                )

                if trailVisible then
                    love.graphics.setColor(1.0, 0.68, 0.24, 0.28)
                    love.graphics.setLineWidth(2)
                    love.graphics.line(projectile.prevX, projectile.prevY, projectile.x, projectile.y)
                end

                if projectileVisible then
                    if assets and assets.fireballSprite then
                        local sprite = assets.fireballSprite
                        local iw = sprite:getWidth()
                        local ih = sprite:getHeight()
                        local diameter = math.max(40, projectile.radius * 1.35)
                        local scale = diameter / math.max(iw, ih)
                        local angle = angleFromVector(projectile.vx, projectile.vy)
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.draw(sprite, projectile.x, projectile.y, angle, scale, scale, iw * 0.5, ih * 0.5)
                    else
                        love.graphics.setColor(1.0, 0.42, 0.16)
                        love.graphics.circle("fill", projectile.x, projectile.y, math.max(7, projectile.radius * 0.16))
                    end

                    love.graphics.setColor(1.0, 0.86, 0.5, 0.12)
                    love.graphics.circle("fill", projectile.x, projectile.y, math.max(6, projectile.radius * C.WORLD_THEME.fireballGlowScale))
                end
            end
        end

        if state.passives.fireballImpacts then
            for _, impact in ipairs(state.passives.fireballImpacts) do
                if isCircleVisible(impact.x, impact.y, impact.radius, left, top, right, bottom, margin) then
                    local a = math.max(0, impact.timer / C.PASSIVE_BASES.fireball.impactFxDuration)
                    love.graphics.setColor(1.0, 0.52, 0.18, 0.1 * a)
                    love.graphics.circle("fill", impact.x, impact.y, impact.radius * C.WORLD_THEME.fireballImpactFillScale)
                    love.graphics.setColor(1.0, 0.82, 0.36, 0.7 * a)
                    love.graphics.setLineWidth(2)
                    love.graphics.circle("line", impact.x, impact.y, impact.radius * (0.55 + (1 - a) * 0.45))
                end
            end
        end
    end

    love.graphics.pop()
end

return WorldRenderer
