local C = {}

C.SAVE_FILE = "save.json"
C.BACKUP_FILE = "save.bak"
C.SAVE_VERSION = 1
C.AUTOSAVE_INTERVAL = 30

C.WORLD_WIDTH = 3200
C.WORLD_HEIGHT = 1800

C.MAPS = {
    {
        id = 1,
        name = "Sprout Meadow",
        reward = 1.0,
        spawn = { common = 0.78, rare = 0.2, elite = 0.02 },
        unlockRequires = 0,
    },
    {
        id = 2,
        name = "Crystal Cave",
        reward = 1.35,
        spawn = { common = 0.68, rare = 0.26, elite = 0.06 },
        unlockRequires = 18,
    },
    {
        id = 3,
        name = "Molten Ridge",
        reward = 1.75,
        spawn = { common = 0.56, rare = 0.32, elite = 0.12 },
        unlockRequires = 42,
    },
    {
        id = 4,
        name = "Abyss Nursery",
        reward = 2.3,
        spawn = { common = 0.46, rare = 0.36, elite = 0.18 },
        unlockRequires = 74,
    },
}

C.FOOD_BY_TIER = {
    common = {
        radius = 10,
        nutrition = 1,
        xp = 1,
        color = { 0.4, 0.95, 0.45 },
        speed = 25,
    },
    rare = {
        radius = 13,
        nutrition = 4,
        xp = 3,
        color = { 0.25, 0.8, 1.0 },
        speed = 32,
    },
    elite = {
        radius = 17,
        nutrition = 10,
        xp = 8,
        color = { 1.0, 0.45, 0.25 },
        speed = 45,
    },
}

C.MAX_FOOD = 125

return C
