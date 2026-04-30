local C = require("src.constants")
local BackgroundAssetManifest = require("src.data.background_asset_manifest")

local AssetLoader = {}

local UI_FONT_PATH = "fonts/NanumGothic-Regular.ttf"
local BASIC_IMAGE_PATHS = {
    playerSprite = C.PLAYER_SPRITE.fallbackPath, fireballSprite = "FireBall.png",
    bossSprite = "BossFinal.png", bossWeakPointSprite = "BossWeakPoint.png",
}
local MONSTER_SPRITE_PATHS = { common = "MonsterCommon.png", rare = "MonsterRare.png", elite = "MonsterElite.png" }
local BACKGROUND_IMAGE_FIELDS = { "backdropFar", "backdropMid", "fieldBaseTile", "fieldDecalSet", "fieldFeature01" }

local function loadUiFont(size)
    local ok, font = pcall(love.graphics.newFont, UI_FONT_PATH, size)
    return ok and font or love.graphics.newFont(size)
end

local function loadOptionalImage(path)
    local ok, image = pcall(love.graphics.newImage, path)
    return ok and image or nil
end

local function loadImageMap(paths)
    local images = {}
    for key, path in pairs(paths) do
        images[key] = loadOptionalImage(type(path) == "table" and path.path or path)
    end
    return images
end

local function loadPlayerWalkAnimation()
    local sheet = loadOptionalImage(C.PLAYER_SPRITE.walkSheetPath)
    if not sheet then
        return nil
    end

    local frameWidth = C.PLAYER_SPRITE.walkFrameWidth
    local frameHeight = C.PLAYER_SPRITE.walkFrameHeight
    local columns = C.PLAYER_SPRITE.walkColumns
    local rows = C.PLAYER_SPRITE.walkRows
    local expectedWidth = frameWidth * columns
    local expectedHeight = frameHeight * rows
    if sheet:getWidth() ~= expectedWidth or sheet:getHeight() ~= expectedHeight then
        error(string.format(
            "invalid player walk sheet size: expected %dx%d, got %dx%d",
            expectedWidth,
            expectedHeight,
            sheet:getWidth(),
            sheet:getHeight()
        ))
    end

    local quads = {}
    for frame = 1, C.PLAYER_SPRITE.walkFrameCount do
        local index = frame - 1
        local x = (index % columns) * frameWidth
        local y = math.floor(index / columns) * frameHeight
        quads[frame] = love.graphics.newQuad(x, y, frameWidth, frameHeight, sheet:getDimensions())
    end

    return {
        image = sheet,
        quads = quads,
        frameWidth = frameWidth,
        frameHeight = frameHeight,
        frameCount = C.PLAYER_SPRITE.walkFrameCount,
        fps = C.PLAYER_SPRITE.walkFps,
    }
end

local function loadRunChoiceCardFrames()
    local frames = {}

    for rarity, path in pairs(C.RUN_CHOICE_UI.cardFramePaths) do
        local image = loadOptionalImage(path)
        if image
            and image:getWidth() == C.RUN_CHOICE_UI.cardWidth
            and image:getHeight() == C.RUN_CHOICE_UI.cardHeight then
            frames[rarity] = image
        end
    end

    return frames
end

local function loadBackgroundAssets()
    local backgrounds = {}

    for mapId, manifest in pairs(BackgroundAssetManifest) do
        local assetSet = { version = manifest.version or 1 }
        for _, field in ipairs(BACKGROUND_IMAGE_FIELDS) do
            assetSet[field] = loadOptionalImage(manifest[field])
        end
        backgrounds[mapId] = assetSet
    end

    return backgrounds
end

function AssetLoader.loadAll()
    local assets = loadImageMap(BASIC_IMAGE_PATHS)
    assets.playerWalkAnimation, assets.monsterSprites = loadPlayerWalkAnimation(), loadImageMap(MONSTER_SPRITE_PATHS)
    assets.runChoiceCardFrames, assets.icons = loadRunChoiceCardFrames(), loadImageMap(C.UI_ICONS)
    assets.backgrounds = loadBackgroundAssets()
    return { hud = loadUiFont(15), big = loadUiFont(30) }, assets
end

return AssetLoader
