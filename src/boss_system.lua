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
        attackTimer = 0,
        pulse = 0,
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
    boss.maxHp = 3000 + state.skillTree.unlockedCount * 55
    boss.hp = boss.maxHp
    boss.attackTimer = 0
    return true
end

function Boss.update(state, dt)
    local boss = state.boss
    if not boss.active or boss.defeated then
        return
    end

    boss.pulse = boss.pulse + dt
    boss.attackTimer = boss.attackTimer + dt

    local player = state.player
    local bonuses = state.bonuses

    local biteRange = player.radius + boss.radius + 15 + bonuses.reach
    local dist = Utils.distance(player.x, player.y, boss.x, boss.y)
    if dist <= biteRange then
        local dps = 8 + bonuses.bite + state.skillTree.unlockedCount * 0.25
        boss.hp = boss.hp - dps * dt
    end

    if boss.attackTimer >= 0.65 then
        boss.attackTimer = 0
    end

    if boss.hp <= 0 then
        boss.hp = 0
        boss.active = false
        boss.defeated = true
        state.events[#state.events + 1] = "Final boss defeated!"
    end
end

return Boss
