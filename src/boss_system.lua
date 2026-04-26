local Utils = require("src.utils")
local C = require("src.constants")

local Boss = {}

function Boss.new(savedBoss)
    local system = {
        active = false,
        defeated = false,
        hp = 0,
        maxHp = 0,
        x = C.WORLD_WIDTH * 0.8,
        y = C.WORLD_HEIGHT * 0.5,
        radius = 70,
        pulse = 0,
        hitFlash = 0,
    }

    if savedBoss then
        system.defeated = savedBoss.defeated or false
        system.active = savedBoss.active or false
        system.hp = savedBoss.hp or 0
        system.maxHp = savedBoss.maxHp or 0
    end

    return system
end

function Boss.export(boss)
    return {
        defeated = boss.defeated,
        active = boss.active,
        hp = boss.hp,
        maxHp = boss.maxHp,
    }
end

function Boss.canEnter(state)
    return state.maps.currentMapId == #C.MAPS and not state.boss.defeated
end

function Boss.enter(state)
    local boss = state.boss
    if boss.active then
        return false
    end
    boss.active = true
    boss.maxHp = 1600 + state.food.consumedTotal * 12 + state.skillTree.unlockedCount * 24
    boss.hp = boss.maxHp
    boss.pulse = 0
    boss.hitFlash = 0
    return true
end

function Boss.distanceTo(boss, x, y)
    return Utils.distance(x, y, boss.x, boss.y)
end

function Boss.applyDamage(state, damage)
    local boss = state.boss
    if not boss.active or boss.defeated or damage <= 0 then
        return false
    end

    boss.hp = boss.hp - damage
    boss.hitFlash = 0.9
    if boss.hp > 0 then
        return false
    end

    boss.hp = 0
    boss.active = false
    boss.defeated = true
    state.events[#state.events + 1] = "Final boss defeated!"
    return true
end

function Boss.update(state, dt)
    local boss = state.boss
    if not boss.active or boss.defeated then
        return
    end

    boss.pulse = boss.pulse + dt
    boss.hitFlash = math.max(0, boss.hitFlash - dt * 3)

    local player = state.player
    local bonuses = state.bonuses
    local biteRange = player.radius + boss.radius + 12 + bonuses.reach
    local dist = Boss.distanceTo(boss, player.x, player.y)
    if dist <= biteRange then
        local dps = C.PLAYER_CONTACT_DAMAGE + (bonuses.contactBite or 0)
        Boss.applyDamage(state, dps * dt)
    end
end

return Boss
