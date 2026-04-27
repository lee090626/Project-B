local C = require("src.constants")

local Mutation = {}

local DEFINITIONS = {
    {
        key = "hunt_bite",
        name = "Razor Bite",
        category = "hunt",
        desc = {
            common = "Contact bite +8",
            rare = "Contact bite +14",
            mythic = "Contact bite +22",
        },
        effects = {
            common = { contactBite = 8 },
            rare = { contactBite = 14 },
            mythic = { contactBite = 22 },
        },
    },
    {
        key = "hunt_pursuit",
        name = "Pursuit Muscle",
        category = "hunt",
        desc = {
            common = "Move speed +10",
            rare = "Move speed +16",
            mythic = "Move speed +24",
        },
        effects = {
            common = { speed = 10 },
            rare = { speed = 16 },
            mythic = { speed = 24 },
        },
    },
    {
        key = "hunt_jaw",
        name = "Latch Jaw",
        category = "hunt",
        desc = {
            common = "Reach +1.0",
            rare = "Reach +1.6",
            mythic = "Reach +2.4",
        },
        effects = {
            common = { reach = 1.0 },
            rare = { reach = 1.6 },
            mythic = { reach = 2.4 },
        },
    },
    {
        key = "stomach_feast",
        name = "Feast Stomach",
        category = "stomach",
        desc = {
            common = "Essence gain +6%",
            rare = "Essence gain +12%",
            mythic = "Essence gain +18%",
        },
        effects = {
            common = { essenceMult = 0.06 },
            rare = { essenceMult = 0.12 },
            mythic = { essenceMult = 0.18 },
        },
    },
    {
        key = "stomach_gem",
        name = "Gem Tongue",
        category = "stomach",
        desc = {
            common = "Rare value +12%",
            rare = "Rare value +20%",
            mythic = "Rare value +30%",
        },
        effects = {
            common = { rareValue = 0.12 },
            rare = { rareValue = 0.20 },
            mythic = { rareValue = 0.30 },
        },
    },
    {
        key = "stomach_crown",
        name = "Royal Appetite",
        category = "stomach",
        desc = {
            common = "Elite value +15%",
            rare = "Elite value +24%",
            mythic = "Elite value +36%",
        },
        effects = {
            common = { eliteValue = 0.15 },
            rare = { eliteValue = 0.24 },
            mythic = { eliteValue = 0.36 },
        },
    },
    {
        key = "sense_pull",
        name = "Far Scent",
        category = "sense",
        desc = {
            common = "Magnet +10",
            rare = "Magnet +18",
            mythic = "Magnet +28",
        },
        effects = {
            common = { magnet = 10 },
            rare = { magnet = 18 },
            mythic = { magnet = 28 },
        },
    },
    {
        key = "sense_sprint",
        name = "Spring Tendon",
        category = "sense",
        desc = {
            common = "Move speed +12",
            rare = "Move speed +20",
            mythic = "Move speed +30",
        },
        effects = {
            common = { speed = 12 },
            rare = { speed = 20 },
            mythic = { speed = 30 },
        },
    },
    {
        key = "sense_jaw",
        name = "Long Tongue",
        category = "sense",
        desc = {
            common = "Reach +0.8",
            rare = "Reach +1.3",
            mythic = "Reach +2.0",
        },
        effects = {
            common = { reach = 0.8 },
            rare = { reach = 1.3 },
            mythic = { reach = 2.0 },
        },
    },
    {
        key = "spawn_bloom",
        name = "Brood Heat",
        category = "spawn",
        desc = {
            common = "Spawn speed +8%",
            rare = "Spawn speed +14%",
            mythic = "Spawn speed +22%",
        },
        effects = {
            common = { spawnRate = 0.08 },
            rare = { spawnRate = 0.14 },
            mythic = { spawnRate = 0.22 },
        },
    },
    {
        key = "spawn_pack",
        name = "Crowded Tracks",
        category = "spawn",
        desc = {
            common = "Spawn cap +4",
            rare = "Spawn cap +7",
            mythic = "Spawn cap +11",
        },
        effects = {
            common = { spawnCap = 4 },
            rare = { spawnCap = 7 },
            mythic = { spawnCap = 11 },
        },
    },
    {
        key = "spawn_lure",
        name = "Lure Gland",
        category = "spawn",
        desc = {
            common = "Rare and elite spawn up",
            rare = "Rare and elite spawn up",
            mythic = "Rare and elite spawn up",
        },
        effects = {
            common = { rareBonus = 0.01, eliteBonus = 0.004 },
            rare = { rareBonus = 0.018, eliteBonus = 0.007 },
            mythic = { rareBonus = 0.028, eliteBonus = 0.011 },
        },
    },
    {
        key = "instinct_storm",
        name = "Storm Mouth",
        category = "instinct",
        requires = function(state)
            return state.metaBonuses.lightningEnabled and state.metaBonuses.lightningEnabled > 0
        end,
        desc = {
            common = "Lightning damage and speed up",
            rare = "Lightning damage and speed up",
            mythic = "Lightning damage and speed up",
        },
        effects = {
            common = { lightningDamage = 8, lightningIntervalCut = 0.05 },
            rare = { lightningDamage = 14, lightningIntervalCut = 0.08 },
            mythic = { lightningDamage = 22, lightningIntervalCut = 0.12 },
        },
    },
    {
        key = "instinct_ember",
        name = "Ember Sac",
        category = "instinct",
        requires = function(state)
            return state.metaBonuses.fireballEnabled and state.metaBonuses.fireballEnabled > 0
        end,
        desc = {
            common = "Fireball damage and radius up",
            rare = "Fireball damage and radius up",
            mythic = "Fireball damage and radius up",
        },
        effects = {
            common = { fireballDamage = 6, fireballRadius = 8 },
            rare = { fireballDamage = 11, fireballRadius = 14 },
            mythic = { fireballDamage = 18, fireballRadius = 22 },
        },
    },
    {
        key = "instinct_frost",
        name = "Frost Lung",
        category = "instinct",
        requires = function(state)
            return state.metaBonuses.frostEnabled and state.metaBonuses.frostEnabled > 0
        end,
        desc = {
            common = "Frost damage and radius up",
            rare = "Frost damage and radius up",
            mythic = "Frost damage and radius up",
        },
        effects = {
            common = { frostDamage = 5, frostRadius = 8, frostDuration = 0.08 },
            rare = { frostDamage = 9, frostRadius = 14, frostDuration = 0.14 },
            mythic = { frostDamage = 15, frostRadius = 20, frostDuration = 0.20 },
        },
    },
}

local MULT_KEYS = {
    essenceMult = true,
    rareValue = true,
    eliteValue = true,
}

local function findDefinition(key)
    for _, def in ipairs(DEFINITIONS) do
        if def.key == key then
            return def
        end
    end
    return nil
end

local function buildWeights(state)
    local shift = math.max(0, math.floor(state.nestBonuses.rarityShift or 0))
    local common = math.max(0, C.MUTATION_RARITY_WEIGHTS.common - shift)
    local rare = C.MUTATION_RARITY_WEIGHTS.rare + math.min(shift, 10)
    local mythic = C.MUTATION_RARITY_WEIGHTS.mythic + math.max(0, shift - 10)
    return common, rare, mythic
end

local function rollRarity(state)
    local common, rare, mythic = buildWeights(state)
    local total = common + rare + mythic
    local pick = love.math.random(total)
    if pick <= common then
        return "common"
    end
    if pick <= common + rare then
        return "rare"
    end
    return "mythic"
end

local function getEffects(def, rarity)
    return def.effects[rarity]
end

local function getThresholds(state)
    local factor = state.nestBonuses.thresholdFactor or 1
    local thresholds = {}
    for i, value in ipairs(C.MUTATION_LEVEL_THRESHOLDS) do
        thresholds[i] = math.max(1, math.floor(value * factor + 0.5))
    end
    return thresholds
end

local function buildPool(state)
    local pool = {}
    for _, def in ipairs(DEFINITIONS) do
        local count = state.runMutations.counts[def.key] or 0
        local allowed = count < 3
        if allowed and def.requires and not def.requires(state) then
            allowed = false
        end
        if allowed then
            pool[#pool + 1] = def
        end
    end
    return pool
end

function Mutation.newRunState()
    return {
        nextThresholdIndex = 1,
        pendingChoices = 0,
        activeChoices = nil,
        picks = {},
        counts = {},
    }
end

function Mutation.gainEssenceAndCheckLevel(state, amount)
    local gain = math.max(1, math.floor(amount + 0.5))
    state.meta.essence = state.meta.essence + gain
    state.runEssenceTotal = state.runEssenceTotal + gain

    local thresholds = getThresholds(state)
    local opened = false
    while state.runMutations.nextThresholdIndex <= #thresholds
        and state.runEssenceTotal >= thresholds[state.runMutations.nextThresholdIndex] do
        state.runMutations.pendingChoices = state.runMutations.pendingChoices + 1
        state.runMutations.nextThresholdIndex = state.runMutations.nextThresholdIndex + 1
        opened = true
    end

    if opened and not state.runMutations.activeChoices then
        Mutation.rollChoices(state)
    end

    return gain, opened
end

function Mutation.rollChoices(state)
    if state.runMutations.pendingChoices <= 0 or state.runMutations.activeChoices then
        return nil
    end

    local pool = buildPool(state)
    if #pool == 0 then
        return nil
    end

    local offerCount = math.min(#pool, state.nestBonuses.choiceCount or 3)
    local activeChoices = {}
    local blocked = {}
    while #activeChoices < offerCount do
        local available = {}
        for _, def in ipairs(pool) do
            if not blocked[def.key] then
                available[#available + 1] = def
            end
        end
        if #available == 0 then
            break
        end

        local def = available[love.math.random(#available)]
        local rarity = rollRarity(state)
        activeChoices[#activeChoices + 1] = {
            key = def.key,
            name = def.name,
            category = def.category,
            rarity = rarity,
            desc = def.desc[rarity],
        }
        blocked[def.key] = true
    end

    if #activeChoices == 0 then
        return nil
    end

    state.runMutations.pendingChoices = state.runMutations.pendingChoices - 1
    state.runMutations.activeChoices = activeChoices
    return activeChoices
end

function Mutation.applyChoice(state, choiceIndex)
    local choice = state.runMutations.activeChoices and state.runMutations.activeChoices[choiceIndex] or nil
    if not choice then
        return false, "invalid choice"
    end

    state.runMutations.counts[choice.key] = (state.runMutations.counts[choice.key] or 0) + 1
    state.runMutations.picks[#state.runMutations.picks + 1] = {
        key = choice.key,
        rarity = choice.rarity,
    }
    state.runMutations.activeChoices = nil

    if state.runMutations.pendingChoices > 0 then
        Mutation.rollChoices(state)
    end

    return true, nil
end

function Mutation.buildRunBonuses(runMutations)
    local bonuses = {
        speed = 0,
        reach = 0,
        magnet = 0,
        contactBite = 0,
        rareBonus = 0,
        eliteBonus = 0,
        spawnRate = 0,
        spawnCap = 0,
        essenceMult = 1,
        rareValue = 1,
        eliteValue = 1,
        lightningDamage = 0,
        lightningIntervalCut = 0,
        fireballDamage = 0,
        fireballRadius = 0,
        frostDamage = 0,
        frostRadius = 0,
        frostDuration = 0,
    }

    for _, pick in ipairs(runMutations.picks) do
        local def = findDefinition(pick.key)
        local effects = def and getEffects(def, pick.rarity) or nil
        if effects then
            for key, value in pairs(effects) do
                if MULT_KEYS[key] then
                    bonuses[key] = bonuses[key] + value
                else
                    bonuses[key] = (bonuses[key] or 0) + value
                end
            end
        end
    end

    return bonuses
end

return Mutation
