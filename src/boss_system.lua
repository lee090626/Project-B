local Utils = require("src.utils")
local C = require("src.constants")
local Meta = require("src.meta_system")

local Boss = {}

local function resetArenaState(system)
    system.active = false
    system.hp = 0
    system.maxHp = 0
    system.arenaTimer = 0
    system.phase = "inactive"
    system.shielded = false
    system.vulnerableTimer = 0
    system.weakPoints = {}
    system.cycleIndex = 0
end

local function spawnWeakPoints(boss)
    boss.weakPoints = {}
    local count = C.BOSS_ARENA.weakPointCount
    local angleOffset = (boss.cycleIndex - 1) * (math.pi / math.max(1, count))
    for i = 1, count do
        local angle = angleOffset + (i - 1) * (math.pi * 2 / count)
        boss.weakPoints[i] = {
            x = boss.x + math.cos(angle) * C.BOSS_ARENA.weakPointOrbitRadius,
            y = boss.y + math.sin(angle) * C.BOSS_ARENA.weakPointOrbitRadius,
            radius = C.BOSS_ARENA.weakPointRadius,
            hp = C.BOSS_ARENA.weakPointHp,
            maxHp = C.BOSS_ARENA.weakPointHp,
            hitFlash = 0,
        }
    end
end

local function openVulnerableWindow(state)
    local boss = state.boss
    boss.phase = "vulnerable"
    boss.shielded = false
    boss.vulnerableTimer = C.BOSS_ARENA.vulnerableDuration
    boss.weakPoints = {}
    boss.hitFlash = 0.5
end

local function allMapsUnlocked(state)
    for _, mapData in ipairs(C.MAPS) do
        if not state.maps.unlocked[mapData.id] then
            return false
        end
    end
    return true
end

function Boss.new(savedBoss)
    local system = {
        active = false,
        defeated = false,
        hp = 0,
        maxHp = 0,
        x = C.WORLD_WIDTH * 0.5,
        y = C.WORLD_HEIGHT * 0.34,
        radius = 70,
        pulse = 0,
        hitFlash = 0,
        arenaTimer = 0,
        phase = "inactive",
        shielded = false,
        vulnerableTimer = 0,
        weakPoints = {},
        cycleIndex = 0,
    }

    if savedBoss then
        system.defeated = savedBoss.defeated == true
    end

    return system
end

function Boss.export(boss)
    return {
        defeated = boss.defeated == true,
    }
end

function Boss.canEnter(state)
    return state.mode == "game"
        and not state.runEnded
        and state.maps.currentMapId == #C.MAPS
        and allMapsUnlocked(state)
        and Meta.allUnlocked(state.meta)
        and not state.boss.defeated
        and not state.boss.active
end

function Boss.enter(state)
    if not Boss.canEnter(state) then
        return false
    end

    local boss = state.boss
    if state.food then
        state.food.list = {}
        state.food.spawnTimer = 0
    end

    state.player.x = C.WORLD_WIDTH * 0.5
    state.player.y = C.WORLD_HEIGHT * 0.72

    boss.x = C.WORLD_WIDTH * 0.5
    boss.y = C.WORLD_HEIGHT * 0.34
    boss.radius = 70
    boss.pulse = 0
    boss.hitFlash = 0
    boss.active = true
    boss.defeated = false
    boss.hp = C.BOSS_ARENA.bossHp
    boss.maxHp = C.BOSS_ARENA.bossHp
    boss.arenaTimer = C.BOSS_ARENA.timeLimit
    boss.phase = "shielded"
    boss.shielded = true
    boss.vulnerableTimer = 0
    boss.cycleIndex = 1
    spawnWeakPoints(boss)

    state.mode = "boss_arena"
    return true
end

function Boss.distanceTo(boss, x, y)
    return Utils.distance(x, y, boss.x, boss.y)
end

function Boss.isShielded(boss)
    return boss.active and boss.shielded
end

function Boss.getNearestWeakPoint(state, x, y)
    local boss = state.boss
    if not boss.active or not boss.shielded then
        return nil, nil, math.huge
    end

    local bestIndex
    local bestPoint
    local bestDist = math.huge
    for index, point in ipairs(boss.weakPoints) do
        local dist = Utils.distance(x, y, point.x, point.y)
        if dist < bestDist then
            bestIndex = index
            bestPoint = point
            bestDist = dist
        end
    end
    return bestIndex, bestPoint, bestDist
end

function Boss.getPriorityTarget(state, x, y)
    local boss = state.boss
    if not boss.active or boss.defeated then
        return nil
    end

    if state.mode == "boss_arena" and boss.shielded and #boss.weakPoints > 0 then
        local index, point, dist = Boss.getNearestWeakPoint(state, x, y)
        if point then
            return {
                kind = "weak_point",
                index = index,
                dist = dist,
                x = point.x,
                y = point.y,
                radius = point.radius,
            }
        end
    end

    return {
        kind = "boss",
        dist = Boss.distanceTo(boss, x, y),
        x = boss.x,
        y = boss.y,
        radius = boss.radius,
    }
end

function Boss.applyWeakPointDamage(state, index, damage)
    local boss = state.boss
    if not boss.active or boss.defeated or not boss.shielded or damage <= 0 then
        return false
    end

    local point = boss.weakPoints[index]
    if not point then
        return false
    end

    point.hp = point.hp - damage
    point.hitFlash = 0.9
    if point.hp > 0 then
        return false
    end

    table.remove(boss.weakPoints, index)
    if #boss.weakPoints == 0 then
        openVulnerableWindow(state)
    end
    return true
end

function Boss.applyDamage(state, damage)
    local boss = state.boss
    if not boss.active or boss.defeated or boss.shielded or damage <= 0 then
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
    boss.phase = "defeated"
    boss.shielded = false
    boss.vulnerableTimer = 0
    boss.arenaTimer = 0
    boss.weakPoints = {}
    state.events[#state.events + 1] = "Final boss defeated!"
    return true
end

function Boss.update(state, dt)
    local boss = state.boss
    if not boss.active or boss.defeated then
        return nil
    end

    boss.pulse = boss.pulse + dt
    boss.hitFlash = math.max(0, boss.hitFlash - dt * 3)
    for _, point in ipairs(boss.weakPoints) do
        point.hitFlash = math.max(0, point.hitFlash - dt * 4)
    end

    local player = state.player
    local bonuses = state.bonuses
    local dps = C.PLAYER_CONTACT_DAMAGE + (bonuses.contactBite or 0)
    if boss.shielded then
        local index, point, dist = Boss.getNearestWeakPoint(state, player.x, player.y)
        if point then
            local biteRange = player.radius + point.radius + 12 + bonuses.reach
            if dist <= biteRange then
                Boss.applyWeakPointDamage(state, index, dps * dt)
            end
        elseif #boss.weakPoints == 0 then
            openVulnerableWindow(state)
        end
    else
        local biteRange = player.radius + boss.radius + 12 + bonuses.reach
        local dist = Boss.distanceTo(boss, player.x, player.y)
        if dist <= biteRange then
            Boss.applyDamage(state, dps * dt)
        end
    end

    if boss.defeated then
        return nil
    end

    boss.arenaTimer = math.max(0, boss.arenaTimer - dt)
    if boss.arenaTimer <= 0 then
        resetArenaState(boss)
        return "failed"
    end

    if not boss.shielded then
        boss.vulnerableTimer = math.max(0, boss.vulnerableTimer - dt)
        if boss.vulnerableTimer <= 0 then
            boss.cycleIndex = boss.cycleIndex + 1
            boss.phase = "shielded"
            boss.shielded = true
            boss.vulnerableTimer = 0
            spawnWeakPoints(boss)
        end
    end

    return nil
end

return Boss
