local C = require("src.constants")
local Player = require("src.player_controller")
local MapSystem = require("src.map_system")

local WorldRenderer = {}

local MONSTER_SPRITE_SCALE = {
    common = 0.95,
    rare = 1.05,
    elite = 1.15,
}

local MONSTER_BOB = {
    common = 2,
    rare = 3,
    elite = 4,
}

local MONSTER_RARE_SWAY = math.rad(4)

local cache = {
    backdrop = nil,
    backdropKey = nil,
    pattern = nil,
    patternKey = nil,
    field = nil,
    fieldKey = nil,
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

local function hash01(a, b, c)
    local v = math.sin(a * 12.9898 + b * 78.233 + (c or 0) * 37.719) * 43758.5453
    return v - math.floor(v)
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

local function getBackgroundAssetSet(assets, mapId)
    return assets and assets.backgrounds and assets.backgrounds[mapId] or nil
end

local function drawScreenVignette(sw, sh)
    setPaletteColor(C.WORLD_THEME.vignette)
    love.graphics.rectangle("fill", 0, 0, sw, 70)
    love.graphics.rectangle("fill", 0, sh - 90, sw, 90)
    love.graphics.rectangle("fill", 0, 0, 80, sh)
    love.graphics.rectangle("fill", sw - 80, 0, 80, sh)
end

local function drawImageCover(image, sw, sh)
    local iw = image:getWidth()
    local ih = image:getHeight()
    if iw <= 0 or ih <= 0 then
        return
    end

    local scale = math.max(sw / iw, sh / ih)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, (sw - iw * scale) * 0.5, (sh - ih * scale) * 0.5, 0, scale, scale)
end

local function drawImageRepeatedToScreen(image, sw, sh, shift)
    local iw = image:getWidth()
    local ih = image:getHeight()
    if iw <= 0 or ih <= 0 then
        return
    end

    local scale = sh / ih
    local step = iw * scale
    local x = -((shift or 0) % step)
    while x < sw do
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, x, 0, 0, scale, scale)
        x = x + step
    end
end

local function drawTiledImage(image, width, height)
    local iw = image:getWidth()
    local ih = image:getHeight()
    if iw <= 0 or ih <= 0 then
        return false
    end

    love.graphics.setColor(1, 1, 1, 1)
    for y = 0, height - 1, ih do
        for x = 0, width - 1, iw do
            love.graphics.draw(image, x, y)
        end
    end

    return true
end

local function drawAssetDecals(mapId, image)
    if not image then
        return
    end

    local iw = image:getWidth()
    local ih = image:getHeight()
    love.graphics.setColor(1, 1, 1, 0.68)
    for row = 0, 3 do
        for col = 0, 5 do
            local seed = mapId * 100 + row * 19 + col * 7
            local x = 180 + col * 560 + (hash01(seed, 1, 0.2) - 0.5) * 140
            local y = 180 + row * 430 + (hash01(seed, 2, 0.4) - 0.5) * 110
            local scale = 0.42 + hash01(seed, 3, 0.6) * 0.2
            local flip = hash01(seed, 4, 0.8) > 0.5 and -1 or 1
            if x < C.WORLD_WIDTH - 80 and y < C.WORLD_HEIGHT - 80 then
                love.graphics.draw(image, x, y, 0, scale * flip, scale, iw * 0.5, ih * 0.5)
            end
        end
    end
end

local function drawAssetFeature(image)
    if not image then
        return
    end

    local iw = image:getWidth()
    local ih = image:getHeight()
    love.graphics.setColor(1, 1, 1, 0.78)
    love.graphics.draw(image, C.WORLD_WIDTH * 0.5, C.WORLD_HEIGHT * 0.42, 0, 1, 1, iw * 0.5, ih * 0.5)
end

local function drawAssetBackdrop(state, sw, sh, assetSet)
    if not assetSet or not assetSet.backdropFar then
        return false
    end

    drawImageCover(assetSet.backdropFar, sw, sh)
    if assetSet.backdropMid then
        drawImageRepeatedToScreen(assetSet.backdropMid, sw, sh, state.camera.x * 0.12)
    end
    drawScreenVignette(sw, sh)
    return true
end

local function drawAssetFieldLayer(mapId, assetSet)
    if not assetSet or not assetSet.fieldBaseTile then
        return false
    end

    if not drawTiledImage(assetSet.fieldBaseTile, C.WORLD_WIDTH, C.WORLD_HEIGHT) then
        return false
    end

    setPaletteColor(C.WORLD_THEME.nestShadow)
    love.graphics.circle("fill", C.WORLD_WIDTH * 0.5, C.WORLD_HEIGHT * 0.52, math.min(C.WORLD_WIDTH, C.WORLD_HEIGHT) * 0.32)
    drawAssetDecals(mapId, assetSet.fieldDecalSet)
    drawAssetFeature(assetSet.fieldFeature01)
    return true
end

local function rebuildAssetFieldCanvas(mapId, assetSet)
    if not assetSet or not assetSet.fieldBaseTile then
        return nil
    end

    local key = string.format("%d:%d", assetSet.version or 0, mapId)
    if cache.field and cache.fieldKey == key then
        return cache.field
    end

    local ok, canvas = pcall(love.graphics.newCanvas, C.WORLD_WIDTH, C.WORLD_HEIGHT)
    if not ok or not canvas then
        cache.field = nil
        cache.fieldKey = nil
        return nil
    end

    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    drawAssetFieldLayer(mapId, assetSet)
    love.graphics.setCanvas()
    love.graphics.pop()

    cache.field = canvas
    cache.fieldKey = key
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

local function drawSpriteCentered(sprite, x, y, targetSize, rotation, tint)
    local iw = sprite:getWidth()
    local ih = sprite:getHeight()
    local scale = targetSize / math.max(iw, ih)
    local color = tint or { 1, 1, 1, 1 }
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.draw(sprite, x, y, rotation or 0, scale, scale, iw * 0.5, ih * 0.5)
end

local function drawMonsterSprite(item, assets, time)
    local tier = item.tier or "common"
    local sprite = assets and assets.monsterSprites and assets.monsterSprites[tier]
    if not sprite then
        return nil
    end

    local phase = time * 2.1 + item.x * 0.01 + item.y * 0.008
    local renderX = item.x
    local renderY = item.y + math.sin(phase) * (MONSTER_BOB[tier] or 2)
    local rotation = tier == "rare" and math.sin(phase * 0.85) * MONSTER_RARE_SWAY or 0
    if tier == "elite" then
        local glowAlpha = 0.12 + (math.sin(phase * 1.35) * 0.5 + 0.5) * 0.08
        love.graphics.setColor(item.color[1], item.color[2], item.color[3], glowAlpha)
        love.graphics.circle("fill", renderX, renderY, item.radius * 1.85)
    end

    drawSpriteCentered(
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
    drawSpriteCentered(sprite, renderX, renderY, point.radius * 2.8 * pulse, 0)
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
    drawSpriteCentered(sprite, renderX, renderY, boss.radius * 3.2 * spritePulse, 0, { 1, 1, 1, alpha })
    return renderX, renderY, pulse
end

function WorldRenderer.draw(state, assets)
    local mapData = MapSystem.getCurrentMap(state.maps)
    local mapTheme = currentMapTheme(mapData.id)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local backgroundAssets = getBackgroundAssetSet(assets, mapData.id)
    local assetFieldCanvas = rebuildAssetFieldCanvas(mapData.id, backgroundAssets)
    local patternCanvas = rebuildPatternCanvas(mapData.id, mapTheme)

    if not drawAssetBackdrop(state, sw, sh, backgroundAssets) then
        local backdropCanvas = rebuildBackdropCanvas(sw, sh, mapData.id, mapTheme)
        if backdropCanvas then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(backdropCanvas, 0, 0)
        else
            drawWorldBackdrop(sw, sh, mapTheme)
        end
    end

    local left, top, right, bottom = getViewport(state, sw, sh)
    local margin = C.WORLD_THEME.cullMargin

    love.graphics.push()
    love.graphics.scale(state.camera.zoom)
    love.graphics.translate(-state.camera.x, -state.camera.y)

    if assetFieldCanvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(assetFieldCanvas, 0, 0)
    elseif patternCanvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(patternCanvas, 0, 0)
    else
        setPaletteColor(C.WORLD_THEME.nestShadow)
        love.graphics.circle("fill", C.WORLD_WIDTH * 0.5, C.WORLD_HEIGHT * 0.52, math.min(C.WORLD_WIDTH, C.WORLD_HEIGHT) * 0.32)
        drawMapPattern(mapData.id, mapTheme)
    end

    if state.mode == "boss_arena" and state.boss.active then
        local arenaX = (state.player.x + state.boss.x) * 0.5
        local arenaY = (state.player.y + state.boss.y) * 0.5
        local arenaRadius = C.BOSS_ARENA.weakPointOrbitRadius + 200
        if isCircleVisible(arenaX, arenaY, arenaRadius, left, top, right, bottom, margin) then
            love.graphics.setColor(0.32, 0.09, 0.06, 0.18)
            love.graphics.circle("fill", arenaX, arenaY, arenaRadius)
            love.graphics.setColor(0.96, 0.52, 0.22, 0.65)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", arenaX, arenaY, arenaRadius)
        end
    end

    for _, item in ipairs(state.food.list) do
        if isCircleVisible(item.x, item.y, item.radius + 10, left, top, right, bottom, margin) then
            local renderX, renderY = drawMonsterSprite(item, assets, state.totalPlayTime or 0)
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

            local hpPct = item.maxHp > 0 and math.max(0, item.hp / item.maxHp) or 0
            local barW = item.radius * 2.1
            local barX = drawX - barW * 0.5
            local barY = drawY - item.radius - 8
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", barX, barY, barW, 4)
            love.graphics.setColor(0.55, 1.0, 0.62)
            love.graphics.rectangle("fill", barX + 1, barY + 1, math.max(0, (barW - 2) * hpPct), 2)
        end
    end

    if state.boss.active and state.boss.weakPoints then
        for _, point in ipairs(state.boss.weakPoints) do
            if isCircleVisible(point.x, point.y, point.radius + 8, left, top, right, bottom, margin) then
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

                local hpPct = point.maxHp > 0 and math.max(0, point.hp / point.maxHp) or 0
                local barW = point.radius * 2.0
                local barX = drawX - barW * 0.5
                local barY = drawY - point.radius - 10
                love.graphics.setColor(0, 0, 0, 0.72)
                love.graphics.rectangle("fill", barX, barY, barW, 4)
                love.graphics.setColor(1.0, 0.86, 0.44)
                love.graphics.rectangle("fill", barX + 1, barY + 1, math.max(0, (barW - 2) * hpPct), 2)
            end
        end
    end

    if (state.boss.active or state.boss.defeated)
        and isCircleVisible(state.boss.x, state.boss.y, state.boss.radius + 6, left, top, right, bottom, margin) then
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
        if state.passives.eatFxTimer and state.passives.eatFxTimer > 0
            and playerVisible then
            local a = state.passives.eatFxTimer / 0.18
            local radius = (state.passives.eatFxRadius or C.WORLD_THEME.eatPulseMinRadius) * (1.18 - a * 0.2)
            love.graphics.setColor(1.0, 0.82, 0.34, 0.12 * a)
            love.graphics.circle("fill", state.player.x, state.player.y, radius)
            love.graphics.setColor(1.0, 0.95, 0.72, 0.72 * a)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", state.player.x, state.player.y, radius)
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
