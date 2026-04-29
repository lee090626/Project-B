local C = require("src.constants")
local Utils = require("src.presentation.world_render_utils")

local WorldBackgroundRenderer = {}

local cache = {
    backdrop = nil,
    backdropKey = nil,
    pattern = nil,
    patternKey = nil,
    field = nil,
    fieldKey = nil,
}

local function currentMapTheme(mapId)
    return C.WORLD_THEME.maps[mapId] or C.WORLD_THEME.maps[4]
end

local function hash01(a, b, c)
    local v = math.sin(a * 12.9898 + b * 78.233 + (c or 0) * 37.719) * 43758.5453
    return v - math.floor(v)
end

local function drawWorldBackdrop(sw, sh, mapTheme)
    Utils.setPaletteColor(mapTheme.sky)
    love.graphics.rectangle("fill", 0, 0, sw, sh)
    Utils.setPaletteColor(mapTheme.ground)
    love.graphics.rectangle("fill", 0, sh * 0.52, sw, sh * 0.48)
    Utils.setPaletteColor(mapTheme.glow)
    love.graphics.circle("fill", sw * 0.5, sh * 0.4, math.min(sw, sh) * 0.38)
    Utils.setPaletteColor(C.WORLD_THEME.vignette)
    love.graphics.rectangle("fill", 0, 0, sw, 70)
    love.graphics.rectangle("fill", 0, sh - 90, sw, 90)
    love.graphics.rectangle("fill", 0, 0, 80, sh)
    love.graphics.rectangle("fill", sw - 80, 0, 80, sh)
end

local function drawMapPattern(mapId, mapTheme)
    love.graphics.setLineWidth(1)
    Utils.setPaletteColor(mapTheme.grid)
    for x = 0, C.WORLD_WIDTH, 80 do
        love.graphics.line(x, 0, x, C.WORLD_HEIGHT)
    end
    for y = 0, C.WORLD_HEIGHT, 80 do
        love.graphics.line(0, y, C.WORLD_WIDTH, y)
    end

    Utils.setPaletteColor(mapTheme.sigil)
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
    Utils.setPaletteColor(C.WORLD_THEME.nestShadow)
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
    Utils.setPaletteColor(C.WORLD_THEME.vignette)
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

    Utils.setPaletteColor(C.WORLD_THEME.nestShadow)
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

function WorldBackgroundRenderer.prepare(mapData, assets)
    local mapTheme = currentMapTheme(mapData.id)
    local backgroundAssets = getBackgroundAssetSet(assets, mapData.id)
    return {
        mapTheme = mapTheme,
        backgroundAssets = backgroundAssets,
        assetFieldCanvas = rebuildAssetFieldCanvas(mapData.id, backgroundAssets),
        patternCanvas = rebuildPatternCanvas(mapData.id, mapTheme),
    }
end

function WorldBackgroundRenderer.drawScreenBackdrop(state, sw, sh, mapData, context)
    if not drawAssetBackdrop(state, sw, sh, context.backgroundAssets) then
        local backdropCanvas = rebuildBackdropCanvas(sw, sh, mapData.id, context.mapTheme)
        if backdropCanvas then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(backdropCanvas, 0, 0)
        else
            drawWorldBackdrop(sw, sh, context.mapTheme)
        end
    end
end

function WorldBackgroundRenderer.drawField(mapId, context)
    if context.assetFieldCanvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(context.assetFieldCanvas, 0, 0)
    elseif context.patternCanvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(context.patternCanvas, 0, 0)
    else
        Utils.setPaletteColor(C.WORLD_THEME.nestShadow)
        love.graphics.circle("fill", C.WORLD_WIDTH * 0.5, C.WORLD_HEIGHT * 0.52, math.min(C.WORLD_WIDTH, C.WORLD_HEIGHT) * 0.32)
        drawMapPattern(mapId, context.mapTheme)
    end
end

return WorldBackgroundRenderer
