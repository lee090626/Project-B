local C = require("src.constants")
local BackgroundAssetManifest = require("src.data.background_asset_manifest")

local AssetLoader = {}

local UI_FONT_PATH = "fonts/NanumGothic-Regular.ttf"
local BACKGROUND_IMAGE_FIELDS = { "backdropFar", "backdropMid", "fieldBaseTile", "fieldDecalSet", "fieldFeature01" }

local function loadUiFont(size)
    local ok, font = pcall(love.graphics.newFont, UI_FONT_PATH, size)
    return ok and font or love.graphics.newFont(size)
end

local function loadOptionalImage(path)
    local ok, image = pcall(love.graphics.newImage, path)
    return ok and image or nil
end

local function invalidSpriteConfig(label, message)
    error(string.format("invalid sprite config for %s: %s", label, message))
end

local function requireField(spec, field, label)
    if not spec or spec[field] == nil then
        invalidSpriteConfig(label, "missing " .. field)
    end
    return spec[field]
end

local function requirePositiveNumber(spec, field, label)
    local value = requireField(spec, field, label)
    if type(value) ~= "number" or value <= 0 then
        invalidSpriteConfig(label, field .. " must be a positive number")
    end
    return value
end

local function requirePositiveInteger(spec, field, label)
    local value = requirePositiveNumber(spec, field, label)
    if value % 1 ~= 0 then
        invalidSpriteConfig(label, field .. " must be an integer")
    end
    return value
end

local function requireSpriteMode(spec, label, mode)
    local actual = requireField(spec, "mode", label)
    if actual ~= mode then
        invalidSpriteConfig(label, string.format("expected mode %q, got %q", mode, tostring(actual)))
    end
end

local function loadRequiredImage(path, label)
    local ok, image = pcall(love.graphics.newImage, path)
    if ok and image then
        return image
    end
    error(string.format("failed to load %s image at %q", label, tostring(path)))
end

local function loadImageMap(paths)
    local images = {}
    for key, path in pairs(paths) do
        images[key] = loadOptionalImage(type(path) == "table" and path.path or path)
    end
    return images
end

local function loadSpriteImage(spec, label)
    requireSpriteMode(spec, label, "image")
    local image = loadRequiredImage(requireField(spec, "path", label), label)
    if spec.width or spec.height then
        local width = requirePositiveInteger(spec, "width", label)
        local height = requirePositiveInteger(spec, "height", label)
        if image:getWidth() ~= width or image:getHeight() ~= height then
            error(string.format(
                "invalid %s image size: expected %dx%d, got %dx%d",
                label,
                width,
                height,
                image:getWidth(),
                image:getHeight()
            ))
        end
    end
    return image
end

local function loadSpriteSheet(spec, label)
    requireSpriteMode(spec, label, "sheet")
    local sheet = loadRequiredImage(requireField(spec, "path", label), label)
    local frameWidth = requirePositiveInteger(spec, "frameWidth", label)
    local frameHeight = requirePositiveInteger(spec, "frameHeight", label)
    local columns = requirePositiveInteger(spec, "columns", label)
    local rows = requirePositiveInteger(spec, "rows", label)
    local frameCount = requirePositiveInteger(spec, "frameCount", label)
    local fps = requirePositiveNumber(spec, "fps", label)
    local idleFrame = spec.idleFrame or 1
    local originX = spec.originX or frameWidth * 0.5
    local originY = spec.originY or frameHeight * 0.5

    if frameCount > columns * rows then
        invalidSpriteConfig(label, "frameCount exceeds sheet cell count")
    end
    if type(idleFrame) ~= "number" or idleFrame % 1 ~= 0 or idleFrame < 1 or idleFrame > frameCount then
        invalidSpriteConfig(label, "idleFrame must be inside frameCount")
    end
    if type(originX) ~= "number" or originX < 0 or originX > frameWidth then
        invalidSpriteConfig(label, "originX must be inside frameWidth")
    end
    if type(originY) ~= "number" or originY < 0 or originY > frameHeight then
        invalidSpriteConfig(label, "originY must be inside frameHeight")
    end

    local expectedWidth = frameWidth * columns
    local expectedHeight = frameHeight * rows
    if sheet:getWidth() ~= expectedWidth or sheet:getHeight() ~= expectedHeight then
        error(string.format(
            "invalid %s sheet size: expected %dx%d, got %dx%d",
            label,
            expectedWidth,
            expectedHeight,
            sheet:getWidth(),
            sheet:getHeight()
        ))
    end

    local quads = {}
    for frame = 1, frameCount do
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
        frameCount = frameCount,
        fps = fps,
        idleFrame = idleFrame,
        originX = originX,
        originY = originY,
    }
end

local function loadSpriteAsset(spec, label)
    if spec.mode == "image" then
        return loadSpriteImage(spec, label)
    end
    if spec.mode == "sheet" then
        return loadSpriteSheet(spec, label)
    end
    invalidSpriteConfig(label, "mode must be image or sheet")
end

local function loadPlayerSprite()
    if C.PLAYER_SPRITE.mode == "sheet" then
        return nil, loadSpriteSheet(C.PLAYER_SPRITE, "playerSprite")
    end
    if C.PLAYER_SPRITE.mode == "image" then
        return loadSpriteImage(C.PLAYER_SPRITE, "playerSprite"), nil
    end
    invalidSpriteConfig("playerSprite", "mode must be image or sheet")
end

local function loadMonsterSprites()
    local sprites = {}
    for tier, spec in pairs(requireField(C.WORLD_SPRITES, "monsters", "worldSprites")) do
        sprites[tier] = loadSpriteImage(spec, "monsterSprites." .. tier)
    end
    return sprites
end

local function loadMapMonsterSprites()
    local sprites = {}

    for mapId, mapSpec in pairs(C.WORLD_SPRITES.monstersByMap or {}) do
        local set = { events = {} }
        for tier, spec in pairs(requireField(mapSpec, "tiers", "monsterSpritesByMap." .. mapId)) do
            set[tier] = loadSpriteImage(spec, "monsterSpritesByMap." .. mapId .. "." .. tier)
        end
        for eventKind, spec in pairs(mapSpec.events or {}) do
            set.events[eventKind] = loadSpriteImage(
                spec,
                "monsterSpritesByMap." .. mapId .. ".events." .. eventKind
            )
        end
        sprites[mapId] = set
    end

    return sprites
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
    local playerSprite, playerWalkAnimation = loadPlayerSprite()
    local assets = {
        playerSprite = playerSprite,
        playerWalkAnimation = playerWalkAnimation,
        fireballSprite = loadSpriteAsset(C.WORLD_SPRITES.fireball, "fireballSprite"),
        bossSprite = loadSpriteImage(C.WORLD_SPRITES.boss, "bossSprite"),
        bossWeakPointSprite = loadSpriteImage(C.WORLD_SPRITES.bossWeakPoint, "bossWeakPointSprite"),
        monsterSprites = loadMonsterSprites(),
        monsterSpritesByMap = loadMapMonsterSprites(),
    }
    assets.runChoiceCardFrames, assets.icons = loadRunChoiceCardFrames(), loadImageMap(C.UI_ICONS)
    assets.backgrounds = loadBackgroundAssets()
    return { hud = loadUiFont(15), big = loadUiFont(30) }, assets
end

return AssetLoader
