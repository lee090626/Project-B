local C = require("src.constants")
local Serialize = require("src.serialize")

local Save = {}

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
