local C = require("src.constants")
local Serialize = require("src.serialize")

local Save = {}
local STARS_PER_MAP = 3

local LEGACY_MAP_STAR_REQUIREMENTS = {
    [1] = 0,
    [2] = 2,
    [3] = 5,
    [4] = 8,
}

local LEGACY_META_UNLOCK_THRESHOLDS = {
    { minNodes = 82, stars = 8 },
    { minNodes = 46, stars = 5 },
    { minNodes = 18, stars = 2 },
}

local NEW_TREE_CAPSTONE_KEYS = {
    "core_apex",
    "hunt_apex",
    "economy_apex",
    "lightning_apex",
    "fireball_apex",
}

local inferStarsFromMeta

local function inferStarsFromSavedMaps(savedMaps)
    if type(savedMaps) ~= "table" or type(savedMaps.unlocked) ~= "table" then
        return 0
    end

    local stars = 0
    for mapId, unlocked in pairs(savedMaps.unlocked) do
        if unlocked then
            stars = math.max(stars, LEGACY_MAP_STAR_REQUIREMENTS[tonumber(mapId) or mapId] or 0)
        end
    end
    return stars
end

local function normalizeStarValue(value)
    return math.max(0, math.min(STARS_PER_MAP, math.floor(tonumber(value) or 0)))
end

local function distributeMapStars(total)
    local mapStars = {}
    local remaining = math.min(#C.MAPS * STARS_PER_MAP, math.max(0, math.floor(tonumber(total) or 0)))
    for _, mapData in ipairs(C.MAPS) do
        local stars = math.min(STARS_PER_MAP, remaining)
        mapStars[mapData.id] = stars
        remaining = remaining - stars
    end
    return mapStars
end

local function normalizeMapStars(savedMapStars)
    local mapStars = distributeMapStars(0)
    if type(savedMapStars) ~= "table" then
        return mapStars
    end

    for key, value in pairs(savedMapStars) do
        local mapId = tonumber(key) or key
        if mapStars[mapId] ~= nil then
            mapStars[mapId] = normalizeStarValue(value)
        end
    end
    return mapStars
end

local function sumMapStars(mapStars)
    local total = 0
    for _, mapData in ipairs(C.MAPS) do
        total = total + normalizeStarValue(mapStars and mapStars[mapData.id] or 0)
    end
    return total
end

local function migrateMapStars(data)
    data.meta = data.meta or {}
    local savedStars = math.max(0, math.floor(tonumber(data.meta.runStars) or 0))
    local inferredStars = math.max(
        inferStarsFromSavedMaps(data.maps),
        inferStarsFromMeta(data.meta)
    )
    local requiredStars = math.max(savedStars, inferredStars)
    local mapStars = normalizeMapStars(data.meta.mapStars)

    if sumMapStars(mapStars) < requiredStars then
        mapStars = distributeMapStars(requiredStars)
    end

    data.meta.mapStars = mapStars
    data.meta.runStars = sumMapStars(mapStars)
end

local function countUnlockedMetaNodes(savedMeta)
    if type(savedMeta) ~= "table" or type(savedMeta.levels) ~= "table" then
        return 0
    end

    local count = 0
    for _, level in pairs(savedMeta.levels) do
        if math.max(0, math.floor(tonumber(level) or 0)) > 0 then
            count = count + 1
        end
    end
    return count
end

local function looksLikeLegacyMeta(savedMeta)
    if type(savedMeta) ~= "table" or type(savedMeta.levels) ~= "table" then
        return false
    end

    local levels = savedMeta.levels
    return levels.up_swift ~= nil
        or levels.right_greed ~= nil
        or levels.frost_root ~= nil
        or levels.lightning_dmg1 ~= nil
end

local function hasAllNewCapstones(savedMeta)
    if type(savedMeta) ~= "table" or type(savedMeta.levels) ~= "table" then
        return false
    end

    local levels = savedMeta.levels
    for _, key in ipairs(NEW_TREE_CAPSTONE_KEYS) do
        if math.max(0, math.floor(tonumber(levels[key]) or 0)) <= 0 then
            return false
        end
    end
    return true
end

inferStarsFromMeta = function(savedMeta)
    if looksLikeLegacyMeta(savedMeta) then
        local unlockedNodes = countUnlockedMetaNodes(savedMeta)
        for _, rule in ipairs(LEGACY_META_UNLOCK_THRESHOLDS) do
            if unlockedNodes >= rule.minNodes then
                return rule.stars
            end
        end
    end

    if hasAllNewCapstones(savedMeta) then
        return LEGACY_MAP_STAR_REQUIREMENTS[4]
    end

    return 0
end

local function migrate(data)
    if type(data) ~= "table" then
        return data
    end

    local version = math.max(0, math.floor(tonumber(data.version) or 0))
    if version < 7 then
        data.uxGuides = data.uxGuides or { shown = {} }
        data.version = 7
    end
    if version < 8 then
        data.version = 8
    end
    if version < 9 then
        data.meta = data.meta or {}
        data.meta.runStars = math.max(
            math.max(0, math.floor(tonumber(data.meta.runStars) or 0)),
            inferStarsFromSavedMaps(data.maps),
            inferStarsFromMeta(data.meta)
        )
        data.version = 9
    end
    if version < 10 or type(data.meta) ~= "table" or type(data.meta.mapStars) ~= "table" then
        migrateMapStars(data)
        data.version = 10
    end

    return data
end

local function readAndDecode(path)
    if not love.filesystem.getInfo(path) then
        return nil, "not found"
    end
    local raw, err = love.filesystem.read(path)
    if not raw then
        return nil, err or "read failed"
    end
    local decoded, decodeErr = Serialize.decode(raw)
    if not decoded then
        return nil, decodeErr or "decode failed"
    end
    return migrate(decoded), nil
end

function Save.load()
    local data, err = readAndDecode(C.SAVE_FILE)
    if data then
        data._loadedFromBackup = false
        return data, nil
    end

    local backupData = readAndDecode(C.BACKUP_FILE)
    if backupData then
        backupData._loadedFromBackup = true
        return backupData, "primary save failed: " .. tostring(err)
    end

    return nil, err
end

function Save.write(data)
    local payload = Serialize.encode(data)

    if love.filesystem.getInfo(C.SAVE_FILE) then
        local existing = love.filesystem.read(C.SAVE_FILE)
        if existing and #existing > 0 then
            love.filesystem.write(C.BACKUP_FILE, existing)
        end
    end

    local ok, err = love.filesystem.write(C.SAVE_FILE, payload)
    if not ok then
        return false, err or "failed write"
    end
    return true, nil
end

return Save
