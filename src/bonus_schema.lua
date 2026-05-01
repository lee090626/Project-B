local C = require("src.constants")
local Utils = require("src.utils")

local BonusSchema = {}

local ADDITIVE_KEYS = {
    "speed",
    "reach",
    "magnet",
    "contactBite",
    "rareBonus",
    "eliteBonus",
    "spawnRate",
    "spawnCap",
    "lightningEnabled",
    "lightningDamage",
    "lightningChain",
    "lightningIntervalCut",
    "fireballEnabled",
    "fireballDamage",
    "fireballCount",
    "fireballRadius",
    "fireballIntervalCut",
    "fireballSplit",
    "eventBiteBonus",
}

local FACTOR_KEYS = {
    "essenceMult",
    "rareValue",
    "eliteValue",
}

local DEFAULTS = {}
local VALID_KEYS = {}

for _, key in ipairs(ADDITIVE_KEYS) do
    DEFAULTS[key] = 0
    VALID_KEYS[key] = true
end

for _, key in ipairs(FACTOR_KEYS) do
    DEFAULTS[key] = 1
    VALID_KEYS[key] = true
end

local function sourceValue(source, key)
    if not source or source[key] == nil then
        return DEFAULTS[key]
    end
    return source[key]
end

local function assertKnownBonusKey(key)
    if not VALID_KEYS[key] then
        error(("unknown bonus key: %s"):format(tostring(key)), 3)
    end
end

local function assertNumericBonusValue(key, value)
    if type(value) ~= "number" then
        error(("bonus %s must be a number"):format(tostring(key)), 3)
    end
end

function BonusSchema.newRaw()
    local out = {}

    for _, key in ipairs(ADDITIVE_KEYS) do
        out[key] = DEFAULTS[key]
    end
    for _, key in ipairs(FACTOR_KEYS) do
        out[key] = DEFAULTS[key]
    end

    return out
end

function BonusSchema.applyPack(out, pack, level)
    if not pack then
        return out
    end

    local levelValue = level or 1
    for key, value in pairs(pack) do
        assertKnownBonusKey(key)
        assertNumericBonusValue(key, value)
        out[key] = sourceValue(out, key) + value * levelValue
    end

    return out
end

function BonusSchema.combineSources(...)
    local out = BonusSchema.newRaw()
    local count = select("#", ...)

    for _, key in ipairs(ADDITIVE_KEYS) do
        local total = DEFAULTS[key]
        for index = 1, count do
            local source = select(index, ...)
            total = total + sourceValue(source, key)
        end
        out[key] = total
    end

    for _, key in ipairs(FACTOR_KEYS) do
        local total = DEFAULTS[key]
        for index = 1, count do
            local source = select(index, ...)
            total = total + (sourceValue(source, key) - DEFAULTS[key])
        end
        out[key] = total
    end

    return out
end

function BonusSchema.toRuntime(raw)
    local source = raw or BonusSchema.newRaw()
    local out = {
        speed = source.speed or 0,
        reach = source.reach or 0,
        essenceMult = source.essenceMult or 1,
        rareBonus = source.rareBonus or 0,
        eliteBonus = source.eliteBonus or 0,
        contactBite = source.contactBite or 0,
        magnet = source.magnet or 0,
        spawnRate = source.spawnRate or 0,
        spawnCap = source.spawnCap or 0,
        rareValue = source.rareValue or 1,
        eliteValue = source.eliteValue or 1,
        eventBiteBonus = source.eventBiteBonus or 0,
    }

    out.lightningEnabled = (source.lightningEnabled or 0) > 0
    out.lightningDamage = C.PASSIVE_BASES.lightning.damage + (source.lightningDamage or 0)
    out.lightningChain = math.max(1, 1 + math.floor(source.lightningChain or 0))
    out.lightningChainRadius = C.PASSIVE_BASES.lightning.chainRadius
        + math.max(0, out.lightningChain - 1) * C.PASSIVE_BASES.lightning.chainRadiusPerExtra
    out.lightningInterval = Utils.clamp(
        C.PASSIVE_BASES.lightning.interval - (source.lightningIntervalCut or 0),
        C.PASSIVE_BASES.lightning.minInterval,
        C.PASSIVE_BASES.lightning.maxInterval
    )

    out.fireballEnabled = (source.fireballEnabled or 0) > 0
    out.fireballDamage = C.PASSIVE_BASES.fireball.damage + (source.fireballDamage or 0)
    out.fireballCount = math.max(1, 1 + math.floor(source.fireballCount or 0) + math.floor(source.fireballSplit or 0))
    out.fireballRadius = C.PASSIVE_BASES.fireball.radius + (source.fireballRadius or 0)
    out.fireballInterval = Utils.clamp(
        C.PASSIVE_BASES.fireball.interval - (source.fireballIntervalCut or 0),
        C.PASSIVE_BASES.fireball.minInterval,
        C.PASSIVE_BASES.fireball.maxInterval
    )

    return out
end

return BonusSchema
