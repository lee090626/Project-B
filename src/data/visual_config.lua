local ProgressionBalance = require("src.data.progression_balance")
local SpriteManifest = require("src.data.sprite_manifest")
local WorldVisualConfig = require("src.data.world_visual_config")

local MAP_MONSTER_SPRITE_ROOT = "assets/sprites/monsters"
local MAP_MONSTER_SPRITE_SIZE = 256

local function mapMonsterSpritePath(mapData, fileName)
    return MAP_MONSTER_SPRITE_ROOT .. "/" .. mapData.assetSlug .. "/" .. fileName
end

local function mapMonsterSpriteSpec(mapData, fileName)
    return {
        mode = "image",
        path = mapMonsterSpritePath(mapData, fileName),
        width = MAP_MONSTER_SPRITE_SIZE,
        height = MAP_MONSTER_SPRITE_SIZE,
    }
end

local function buildMapMonsterSpriteGroup(mapData, files)
    local group = {}
    for key, fileName in pairs(files or {}) do
        group[key] = mapMonsterSpriteSpec(mapData, fileName)
    end
    return group
end

local function buildMapThemes()
    local themes = {}
    for _, mapData in ipairs(ProgressionBalance.maps) do
        themes[mapData.id] = mapData.theme
    end
    return themes
end

local function buildWorldSprites()
    local sprites = {
        fireball = SpriteManifest.world.fireball,
        boss = SpriteManifest.world.boss,
        bossWeakPoint = SpriteManifest.world.bossWeakPoint,
        monsters = SpriteManifest.world.monsters,
        monstersByMap = {},
    }

    for _, mapData in ipairs(ProgressionBalance.maps) do
        if mapData.monsterSpriteFiles then
            sprites.monstersByMap[mapData.id] = {
                tiers = buildMapMonsterSpriteGroup(mapData, mapData.monsterSpriteFiles.tiers),
                events = buildMapMonsterSpriteGroup(mapData, mapData.monsterSpriteFiles.events),
            }
        end
    end

    return sprites
end

local function buildWorldTheme()
    local theme = {}
    for key, value in pairs(WorldVisualConfig) do
        theme[key] = value
    end
    theme.maps = buildMapThemes()
    return theme
end

return {
    playerSprite = SpriteManifest.player,
    worldSprites = buildWorldSprites(),
    worldTheme = buildWorldTheme(),
}
