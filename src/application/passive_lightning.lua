local Food = require("src.food_system")
local Boss = require("src.boss_system")
local C = require("src.constants")

local PassiveLightning = {}

local function pushFx(state, segments)
    if not segments or #segments == 0 then
        state.passives.lightningFx = nil
        return
    end
    state.passives.lightningFx = {
        segments = segments,
        timer = C.PASSIVE_BASES.lightning.fxDuration,
    }
end

local function findNearestHostile(state, fromX, fromY)
    if state.mode == "boss_arena" then
        return Boss.getPriorityTarget(state, fromX, fromY)
    end

    local best
    local foodIndex, foodItem, foodDist = Food.findNearestTarget(state.food, fromX, fromY)
    if foodItem then
        best = {
            kind = "food",
            index = foodIndex,
            dist = foodDist,
            x = foodItem.x,
            y = foodItem.y,
        }
    end

    if state.boss.active and not state.boss.defeated then
        local bossDist = Boss.distanceTo(state.boss, fromX, fromY)
        if (not best) or bossDist < best.dist then
            best = {
                kind = "boss",
                dist = bossDist,
                x = state.boss.x,
                y = state.boss.y,
            }
        end
    end

    return best
end

function PassiveLightning.tickFx(state, dt)
    local passives = state.passives
    if passives.lightningFx then
        passives.lightningFx.timer = passives.lightningFx.timer - dt
        if passives.lightningFx.timer <= 0 then
            passives.lightningFx = nil
        end
    end
end

function PassiveLightning.trigger(state, mapData, grantEssence)
    local target = findNearestHostile(state, state.player.x, state.player.y)
    if not target then
        return false
    end

    if target.kind == "boss" then
        pushFx(state, {
            {
                fromX = state.player.x,
                fromY = state.player.y,
                toX = target.x,
                toY = target.y,
            },
        })
        Boss.applyDamage(
            state,
            math.max(
                C.PASSIVE_BASES.lightning.minBossDamage,
                state.bonuses.lightningDamage * C.PASSIVE_BASES.lightning.bossDamageMultiplier
            )
        )
        return false
    elseif target.kind == "weak_point" then
        pushFx(state, {
            {
                fromX = state.player.x,
                fromY = state.player.y,
                toX = target.x,
                toY = target.y,
            },
        })
        Boss.applyWeakPointDamage(
            state,
            target.index,
            math.max(
                C.PASSIVE_BASES.lightning.minBossDamage,
                state.bonuses.lightningDamage * C.PASSIVE_BASES.lightning.bossDamageMultiplier
            )
        )
        return false
    end

    local reward, _, _, segments = Food.chainLightning(
        state.food,
        target.index,
        state.bonuses.lightningDamage,
        state.bonuses.lightningChain,
        state.bonuses.lightningChainRadius,
        mapData,
        state.bonuses
    )
    if segments and #segments > 0 then
        local fullSegments = {
            {
                fromX = state.player.x,
                fromY = state.player.y,
                toX = segments[1].fromX,
                toY = segments[1].fromY,
            },
        }
        for _, segment in ipairs(segments) do
            fullSegments[#fullSegments + 1] = segment
        end
        pushFx(state, fullSegments)
    else
        pushFx(state, {
            {
                fromX = state.player.x,
                fromY = state.player.y,
                toX = target.x,
                toY = target.y,
            },
        })
    end
    return grantEssence(reward)
end

return PassiveLightning
