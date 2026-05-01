local Locale = require("src.locale")

local BonusText = {}

local ORDER = {
    "lightningEnabled",
    "fireballEnabled",
    "speed",
    "reach",
    "magnet",
    "contactBite",
    "eventBiteBonus",
    "essenceMult",
    "rareBonus",
    "eliteBonus",
    "rareValue",
    "eliteValue",
    "spawnRate",
    "spawnCap",
    "lightningDamage",
    "lightningChain",
    "lightningIntervalCut",
    "fireballDamage",
    "fireballRadius",
    "fireballCount",
    "fireballSplit",
    "fireballIntervalCut",
}

local DESCRIPTORS = {
    lightningEnabled = { key = "bonus.lightningEnabled", fixed = true },
    fireballEnabled = { key = "bonus.fireballEnabled", fixed = true },
    speed = { key = "bonus.speed", value = "number" },
    reach = { key = "bonus.reach", value = "number" },
    magnet = { key = "bonus.magnet", value = "number" },
    contactBite = { key = "bonus.contactBite", value = "number" },
    eventBiteBonus = { key = "bonus.eventBiteBonus", value = "number" },
    essenceMult = { key = "bonus.essenceMult", value = "percent" },
    rareBonus = { key = "bonus.rareBonus", value = "percent" },
    eliteBonus = { key = "bonus.eliteBonus", value = "percent" },
    rareValue = { key = "bonus.rareValue", value = "percent" },
    eliteValue = { key = "bonus.eliteValue", value = "percent" },
    spawnRate = { key = "bonus.spawnRate", value = "percent" },
    spawnCap = { key = "bonus.spawnCap", value = "number" },
    lightningDamage = { key = "bonus.lightningDamage", value = "number" },
    lightningChain = { key = "bonus.lightningChain", value = "number" },
    lightningIntervalCut = { key = "bonus.lightningIntervalCut", value = "seconds" },
    fireballDamage = { key = "bonus.fireballDamage", value = "number" },
    fireballRadius = { key = "bonus.fireballRadius", value = "number" },
    fireballCount = { key = "bonus.fireballCount", value = "number" },
    fireballSplit = { key = "bonus.fireballSplit", value = "number" },
    fireballIntervalCut = { key = "bonus.fireballIntervalCut", value = "seconds" },
}

local function trimNumber(text)
    return (text:gsub("(%..-)0+$", "%1"):gsub("%.$", ""))
end

local function formatNumber(value)
    if math.abs(value - math.floor(value + 0.5)) < 0.0001 then
        return tostring(math.floor(value + 0.5))
    end
    return trimNumber(string.format("%.2f", value))
end

local function formatPercent(value)
    return formatNumber(value * 100)
end

local function paramsFor(desc, value)
    if desc.fixed then
        return nil
    end
    if desc.value == "percent" then
        return { value = formatPercent(value) }
    end
    return { value = formatNumber(value) }
end

function BonusText.describe(locale, pack, options)
    local parts = {}
    local perLevel = options and options.perLevel
    local suffix = perLevel and Locale.text(locale, "bonus.period.per_level") or ""

    for key, value in pairs(pack or {}) do
        if value and value ~= 0 and not DESCRIPTORS[key] then
            error(("missing bonus text descriptor for %s"):format(tostring(key)), 2)
        end
    end

    for _, key in ipairs(ORDER) do
        local value = pack and pack[key] or nil
        local desc = DESCRIPTORS[key]
        if desc and value and value ~= 0 then
            local text = Locale.text(locale, desc.key, paramsFor(desc, value))
            if perLevel and not desc.fixed then
                text = text .. suffix
            end
            parts[#parts + 1] = text
        end
    end

    return table.concat(parts, " / ")
end

return BonusText
