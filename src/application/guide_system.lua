local C = require("src.constants")
local Boss = require("src.boss_system")

local Guide = {}

local ORDER = {
    "first_instinct",
    "run_start",
    "first_map_unlock",
    "boss_ready",
    "run_end_tree",
}

local DEFINITIONS = {
    run_start = {
        titleKey = "guide.run_start.title",
        bodyKey = "guide.run_start.body",
        icon = "hunt",
    },
    first_instinct = {
        titleKey = "guide.first_instinct.title",
        bodyKey = "guide.first_instinct.body",
        icon = "instinct",
    },
    first_map_unlock = {
        titleKey = "guide.first_map_unlock.title",
        bodyKey = "guide.first_map_unlock.body",
        icon = "map",
    },
    boss_ready = {
        titleKey = "guide.boss_ready.title",
        bodyKey = "guide.boss_ready.body",
        icon = "boss",
    },
    run_end_tree = {
        titleKey = "guide.run_end_tree.title",
        bodyKey = "guide.run_end_tree.body",
        icon = "level",
    },
}

local function defaultShown()
    return {
        run_start = false,
        first_instinct = false,
        first_map_unlock = false,
        boss_ready = false,
        run_end_tree = false,
    }
end

local function cloneShown(savedShown)
    local shown = defaultShown()
    if not savedShown then
        return shown
    end
    for key in pairs(shown) do
        shown[key] = savedShown[key] == true
    end
    return shown
end

local function unlockedMapCount(state)
    local count = 0
    for _, map in ipairs(C.MAPS) do
        if state.maps.unlocked[map.id] then
            count = count + 1
        end
    end
    return count
end

local function isRelevant(state, id)
    if id == "run_start" then
        return state.mode == "game"
            and not state.runEnded
            and (state.runEssenceTotal or 0) <= 0
            and state.food
            and (state.food.consumedTotal or 0) <= 0
    elseif id == "first_instinct" then
        return state.mode == "run_choice"
            and state.runMutations
            and state.runMutations.activeChoices
            and #state.runMutations.activeChoices > 0
    elseif id == "first_map_unlock" then
        return state.mode == "game"
            and not state.runEnded
            and unlockedMapCount(state) > 1
    elseif id == "boss_ready" then
        return state.mode == "game"
            and not state.runEnded
            and Boss.canEnter(state)
    elseif id == "run_end_tree" then
        return state.mode == "run_end_tree"
    end
    return false
end

local function activate(state, id)
    local def = DEFINITIONS[id]
    if not def then
        return false
    end
    state.guides.active = {
        id = id,
        titleKey = def.titleKey,
        bodyKey = def.bodyKey,
        icon = def.icon,
    }
    state.guides.shown[id] = true
    return true
end

local function scanContext(state)
    for _, id in ipairs(ORDER) do
        if not state.guides.shown[id] and isRelevant(state, id) then
            Guide.request(state, id)
        end
    end
end

function Guide.new(savedGuides)
    return {
        shown = cloneShown(savedGuides and savedGuides.shown or savedGuides),
        queue = {},
        queued = {},
        active = nil,
    }
end

function Guide.resetRuntime(guides)
    guides.queue = {}
    guides.queued = {}
    guides.active = nil
end

function Guide.export(guides)
    return {
        shown = cloneShown(guides and guides.shown or nil),
    }
end

function Guide.request(state, id)
    local guides = state.guides
    if not guides or not DEFINITIONS[id] then
        return false
    end
    if guides.shown[id] or guides.queued[id] or (guides.active and guides.active.id == id) then
        return false
    end
    guides.queue[#guides.queue + 1] = id
    guides.queued[id] = true
    return true
end

function Guide.dismiss(state)
    if not state.guides then
        return
    end
    state.guides.active = nil
end

function Guide.tick(state)
    if not state.guides then
        return
    end

    scanContext(state)

    local active = state.guides.active
    if active and not isRelevant(state, active.id) then
        state.guides.active = nil
    end
    if state.guides.active then
        return
    end

    for i = 1, #state.guides.queue do
        local id = state.guides.queue[i]
        if isRelevant(state, id) then
            table.remove(state.guides.queue, i)
            state.guides.queued[id] = nil
            activate(state, id)
            return
        end
    end
end

return Guide
