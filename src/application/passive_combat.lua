local C = require("src.constants")
local MapSystem = require("src.map_system")
local Mutation = require("src.mutation_system")
local PassiveLightning = require("src.application.passive_lightning")
local PassiveFireball = require("src.application.passive_fireball")

local PassiveCombat = {}

function PassiveCombat.resetState(state)
    state.passives = {
        lightningTimer = C.PASSIVE_BASES.lightning.initialDelay,
        fireballTimer = C.PASSIVE_BASES.fireball.initialDelay,
        lightningFx = nil,
        fireballProjectiles = {},
        fireballImpacts = {},
        eatFxTimer = 0,
        eatFxRadius = 0,
    }
end

function PassiveCombat.triggerEatFx(state, amount)
    local passives = state.passives
    if not passives or amount <= 0 then
        return
    end
    passives.eatFxTimer = C.PASSIVE_BASES.eat.fxDuration
    passives.eatFxRadius = C.WORLD_THEME.eatPulseMinRadius
        + math.min(
            C.WORLD_THEME.eatPulseRadiusCap,
            amount * C.WORLD_THEME.eatPulseRadiusScale
        )
end

local function addEssence(state, rawAmount)
    if rawAmount <= 0 then
        return false
    end
    PassiveCombat.triggerEatFx(state, rawAmount)
    local _, opened = Mutation.gainEssenceAndCheckLevel(state, rawAmount)
    return opened
end

local function grantEssenceFor(state)
    return function(rawAmount)
        return addEssence(state, rawAmount)
    end
end

function PassiveCombat.tickFx(state, dt)
    local passives = state.passives
    local mapData = MapSystem.getCurrentMap(state.maps)
    local grantEssence = grantEssenceFor(state)
    PassiveLightning.tickFx(state, dt)
    if PassiveFireball.tickFx(state, dt, mapData, grantEssence) then
        return
    end
    passives.eatFxTimer = math.max(0, passives.eatFxTimer - dt)
end

function PassiveCombat.tickPassives(state, dt, mapData)
    local passives = state.passives
    local bonuses = state.bonuses
    local grantEssence = grantEssenceFor(state)

    if bonuses.lightningEnabled then
        passives.lightningTimer = passives.lightningTimer - dt
        while passives.lightningTimer <= 0 do
            passives.lightningTimer = passives.lightningTimer + bonuses.lightningInterval
            if PassiveLightning.trigger(state, mapData, grantEssence) or state.mode == "run_choice" then
                return
            end
        end
    end

    if bonuses.fireballEnabled then
        passives.fireballTimer = passives.fireballTimer - dt
        while passives.fireballTimer <= 0 do
            passives.fireballTimer = passives.fireballTimer + bonuses.fireballInterval
            if PassiveFireball.trigger(state) or state.mode == "run_choice" then
                return
            end
        end
    end
end

return PassiveCombat
