local Nest = require("src.nest_system")
local MutationBalance = require("src.data.mutation_balance")

local Mutation = {}

local DEFINITIONS = MutationBalance.definitions

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

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function buildWeights(state)
    local shift = math.max(0, math.floor(state.nestBonuses.rarityShift or 0))
    local common = clamp(MutationBalance.rarityWeights.common - shift, 45, MutationBalance.rarityWeights.common)
    local rare = MutationBalance.rarityWeights.rare + math.min(shift, 7)
    local mythic = MutationBalance.rarityWeights.mythic + math.max(0, shift - 7)
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
    for i, value in ipairs(MutationBalance.thresholds) do
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

function Mutation.getProgress(state)
    local thresholds = getThresholds(state)
    local nextIndex = state.runMutations.nextThresholdIndex or 1
    local nextThreshold = thresholds[nextIndex]
    local currentEssence = state.runEssenceTotal or 0

    if nextThreshold == nil then
        return {
            essence = currentEssence,
            current = currentEssence,
            next = currentEssence,
            remain = 0,
            complete = true,
            pending = state.runMutations.pendingChoices or 0,
        }
    end

    local prevThreshold = 0
    if nextIndex > 1 then
        prevThreshold = thresholds[nextIndex - 1] or 0
    end

    return {
        essence = currentEssence,
        current = math.max(0, currentEssence - prevThreshold),
        next = math.max(1, nextThreshold - prevThreshold),
        remain = math.max(0, nextThreshold - currentEssence),
        complete = false,
        pending = state.runMutations.pendingChoices or 0,
    }
end

local function openChoiceState(state)
    state.mode = "run_choice"
    state.messageKey = "message.choose_instinct"
    state.messageParams = nil
    state.messageVersion = (state.messageVersion or 0) + 1
end

function Mutation.grantChoices(state, count)
    local amount = math.max(0, math.floor(count or 0))
    if amount <= 0 then
        return false
    end

    state.runMutations.pendingChoices = (state.runMutations.pendingChoices or 0) + amount
    if state.runMutations.activeChoices then
        return false
    end

    Mutation.rollChoices(state)
    if state.runMutations.activeChoices then
        openChoiceState(state)
        return true
    end
    return false
end

function Mutation.gainEssenceAndCheckLevel(state, amount)
    local gain = math.max(1, math.floor(amount + 0.5))
    state.meta.essence = state.meta.essence + gain
    state.nest.totalEssence = (state.nest.totalEssence or 0) + gain
    if state.nestProgress then
        state.nestProgress = Nest.getProgress(state.nest)
    end
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
        if state.runMutations.activeChoices then
            openChoiceState(state)
        end
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
            nameKey = "mutation." .. def.key .. ".name",
            category = def.category,
            rarity = rarity,
            descKey = "mutation." .. def.key .. ".desc." .. rarity,
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
        return false, "invalid_choice"
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
