local CombatBalance = {
    foodByTier = {
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
    },
    passiveBases = {
        lightning = {
            interval = 1.7,
            damage = 18,
            chainRadius = 300,
        },
        fireball = {
            interval = 2.0,
            damage = 14,
            radius = 60,
            projectileSpeed = 380,
            impactFxDuration = 0.2,
        },
        frost = {
            interval = 2.4,
            damage = 9,
            radius = 85,
            slow = 0.32,
            duration = 1.2,
        },
    },
    bossArena = {
        timeLimit = 8,
        bossHp = 420,
        weakPointCount = 3,
        weakPointHp = 36,
        weakPointRadius = 22,
        weakPointOrbitRadius = 140,
        vulnerableDuration = 1.6,
    },
}

return CombatBalance
