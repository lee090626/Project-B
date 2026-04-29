local C = require("src.constants")
local Serialize = require("src.serialize")

local Save = {}

local LEGACY_MAP_STAR_REQUIREMENTS = {
    [1] = 0,
    [2] = 4,
    [3] = 10,
    [4] = 18,
}

local LEGACY_META_UNLOCK_THRESHOLDS = {
    { minNodes = 82, stars = 18 },
    { minNodes = 46, stars = 10 },
    { minNodes = 18, stars = 4 },
}

local NEW_TREE_CAPSTONE_KEYS = {
    "core_apex",
    "hunt_apex",
    "economy_apex",
    "lightning_apex",
    "fireball_apex",
}

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

local function inferStarsFromMeta(savedMeta)
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
        local savedStars = math.max(0, math.floor(tonumber(data.meta.runStars) or 0))
        local inferredStars = math.max(
            inferStarsFromSavedMaps(data.maps),
            inferStarsFromMeta(data.meta)
        )
        data.meta.runStars = math.max(savedStars, inferredStars)
        data.version = 9
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

function Save.snapshot(state)
    return {
        version = C.SAVE_VERSION,
        locale = state.locale,
        totalPlayTime = state.totalPlayTime,
        mode = state.mode,
        runTimeLeft = state.runTimeLeft,
        runDuration = state.runDuration,
        runEnded = state.runEnded,
        runEndedReason = state.runEndedReason,
        endingReached = state.endingReached,
        player = state.modules.playerExport(state.player),
        food = state.modules.foodExport(state.food),
        maps = state.modules.mapExport(state.maps),
        boss = state.modules.bossExport(state.boss),
        meta = state.modules.metaExport(state.meta),
        nest = state.modules.nestExport(state.nest),
        uxGuides = state.modules.guideExport(state.guides),
    }
end

return Save
