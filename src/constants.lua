local C = {}

C.SAVE_FILE = "save.json"
C.BACKUP_FILE = "save.bak"
C.SAVE_VERSION = 3
C.AUTOSAVE_INTERVAL = 30
C.RUN_TIME_LIMIT_SECONDS = 15

C.WORLD_WIDTH = 3200
C.WORLD_HEIGHT = 1800

C.MAPS = {
    {
        id = 1,
        name = "Sprout Meadow",
        reward = 1.0,
        hpScale = 1.0,
        spawn = { common = 0.78, rare = 0.2, elite = 0.02 },
        unlockRequires = 0,
    },
    {
        id = 2,
        name = "Crystal Cave",
        reward = 1.35,
        hpScale = 1.28,
        spawn = { common = 0.68, rare = 0.26, elite = 0.06 },
        unlockRequires = 18,
    },
    {
        id = 3,
        name = "Molten Ridge",
        reward = 1.75,
        hpScale = 1.62,
        spawn = { common = 0.56, rare = 0.32, elite = 0.12 },
        unlockRequires = 42,
    },
    {
        id = 4,
        name = "Abyss Nursery",
        reward = 2.3,
        hpScale = 2.05,
        spawn = { common = 0.46, rare = 0.36, elite = 0.18 },
        unlockRequires = 74,
    },
}

C.FOOD_BY_TIER = {
    common = {
        radius = 10,
        essence = 1,
        hp = 9,
        color = { 0.4, 0.95, 0.45 },
        speed = 25,
    },
    rare = {
        radius = 13,
        essence = 5,
        hp = 34,
        color = { 0.25, 0.8, 1.0 },
        speed = 32,
    },
    elite = {
        radius = 17,
        essence = 14,
        hp = 88,
        color = { 1.0, 0.45, 0.25 },
        speed = 45,
    },
}

C.MAX_FOOD = 125
C.FOOD_SPAWN_INTERVAL = 0.045
C.PLAYER_CONTACT_DAMAGE = 18

C.PASSIVE_BASES = {
    lightning = {
        interval = 1.7,
        damage = 18,
        chainRadius = 220,
    },
    fireball = {
        interval = 2.0,
        damage = 14,
        radius = 60,
    },
    frost = {
        interval = 2.4,
        damage = 9,
        radius = 85,
        slow = 0.32,
        duration = 1.2,
    },
}

C.RUN_END_TREE_UI = {
    worldScale = 460,
    minZoom = 0.4,
    maxZoom = 2.6,
    zoomStepUp = 1.12,
    zoomStepDown = 0.88,
    nodeRadius = 24,
    clickThreshold = 8,
}

C.RUN_HUD_UI = {
    padding = 14,
    topBarHeight = 42,
    groupGap = 10,
    chipPadX = 10,
    toastDuration = 2.2,
    autosaveDuration = 2.8,
}

return C
