local C = require("src.constants")

local MapSystem = {}

function MapSystem.new(savedMaps)
    local maps = {
        currentMapId = 1,
        unlocked = {},
    }

    for _, mapData in ipairs(C.MAPS) do
        maps.unlocked[mapData.id] = mapData.id == 1
    end

    if savedMaps then
        if savedMaps.currentMapId then
            maps.currentMapId = savedMaps.currentMapId
        end
        if savedMaps.unlocked then
            for id, unlocked in pairs(savedMaps.unlocked) do
                maps.unlocked[tonumber(id) or id] = unlocked
            end
        end
    end

    maps.currentMapId = math.max(1, math.min(#C.MAPS, maps.currentMapId))
    if not maps.unlocked[maps.currentMapId] then
        maps.currentMapId = 1
    end

    return maps
end

function MapSystem.export(maps)
    return {
        currentMapId = maps.currentMapId,
        unlocked = maps.unlocked,
    }
end

function MapSystem.getCurrentMap(maps)
    return C.MAPS[maps.currentMapId]
end

local function unlockRequirement(mapData)
    return mapData.starUnlockRequires or mapData.unlockRequires or 0
end

function MapSystem.updateUnlocks(maps, progressValue)
    local unlockedAny = false
    for _, mapData in ipairs(C.MAPS) do
        if not maps.unlocked[mapData.id] and progressValue >= unlockRequirement(mapData) then
            maps.unlocked[mapData.id] = true
            unlockedAny = true
        end
    end
    return unlockedAny
end

function MapSystem.syncUnlocks(maps, progressValue)
    for _, mapData in ipairs(C.MAPS) do
        maps.unlocked[mapData.id] = progressValue >= unlockRequirement(mapData)
    end

    if not maps.unlocked[maps.currentMapId] then
        maps.currentMapId = 1
    end
end

function MapSystem.allMapsUnlocked(maps)
    for _, mapData in ipairs(C.MAPS) do
        if not maps.unlocked[mapData.id] then
            return false
        end
    end
    return true
end

function MapSystem.getNextUnlockInfo(maps, progressValue)
    for _, mapData in ipairs(C.MAPS) do
        if not maps.unlocked[mapData.id] then
            return {
                mapId = mapData.id,
                nameKey = mapData.nameKey,
                current = progressValue,
                required = unlockRequirement(mapData),
            }
        end
    end
    return nil
end

function MapSystem.trySetCurrent(maps, mapId)
    if maps.unlocked[mapId] then
        maps.currentMapId = mapId
        return true
    end
    return false
end

return MapSystem
