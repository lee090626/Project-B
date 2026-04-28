local MutationBalance = {
    thresholds = { 50, 140, 280, 480, 760, 1120, 1560, 2080 },
    rarityWeights = {
        common = 70,
        rare = 25,
        mythic = 5,
    },
    definitions = {
        {
            key = "hunt_bite",
            category = "hunt",
            effects = {
                common = { contactBite = 8 },
                rare = { contactBite = 14 },
                mythic = { contactBite = 22 },
            },
        },
        {
            key = "hunt_pursuit",
            category = "hunt",
            effects = {
                common = { speed = 10 },
                rare = { speed = 16 },
                mythic = { speed = 24 },
            },
        },
        {
            key = "hunt_jaw",
            category = "hunt",
            effects = {
                common = { reach = 1.0 },
                rare = { reach = 1.6 },
                mythic = { reach = 2.4 },
            },
        },
        {
            key = "stomach_feast",
            category = "stomach",
            effects = {
                common = { essenceMult = 0.06 },
                rare = { essenceMult = 0.12 },
                mythic = { essenceMult = 0.18 },
            },
        },
        {
            key = "stomach_gem",
            category = "stomach",
            effects = {
                common = { rareValue = 0.12 },
                rare = { rareValue = 0.20 },
                mythic = { rareValue = 0.30 },
            },
        },
        {
            key = "stomach_crown",
            category = "stomach",
            effects = {
                common = { eliteValue = 0.15 },
                rare = { eliteValue = 0.24 },
                mythic = { eliteValue = 0.36 },
            },
        },
        {
            key = "sense_pull",
            category = "sense",
            effects = {
                common = { magnet = 10 },
                rare = { magnet = 18 },
                mythic = { magnet = 28 },
            },
        },
        {
            key = "sense_sprint",
            category = "sense",
            effects = {
                common = { speed = 12 },
                rare = { speed = 20 },
                mythic = { speed = 30 },
            },
        },
        {
            key = "sense_jaw",
            category = "sense",
            effects = {
                common = { reach = 0.8 },
                rare = { reach = 1.3 },
                mythic = { reach = 2.0 },
            },
        },
        {
            key = "spawn_bloom",
            category = "spawn",
            effects = {
                common = { spawnRate = 0.08 },
                rare = { spawnRate = 0.14 },
                mythic = { spawnRate = 0.22 },
            },
        },
        {
            key = "spawn_pack",
            category = "spawn",
            effects = {
                common = { spawnCap = 4 },
                rare = { spawnCap = 7 },
                mythic = { spawnCap = 11 },
            },
        },
        {
            key = "spawn_lure",
            category = "spawn",
            effects = {
                common = { rareBonus = 0.01, eliteBonus = 0.004 },
                rare = { rareBonus = 0.018, eliteBonus = 0.007 },
                mythic = { rareBonus = 0.028, eliteBonus = 0.011 },
            },
        },
        {
            key = "instinct_storm",
            category = "instinct",
            requires = function(state)
                return state.metaBonuses.lightningEnabled and state.metaBonuses.lightningEnabled > 0
            end,
            effects = {
                common = { lightningDamage = 8, lightningIntervalCut = 0.05 },
                rare = { lightningDamage = 14, lightningIntervalCut = 0.08 },
                mythic = { lightningDamage = 22, lightningIntervalCut = 0.12 },
            },
        },
        {
            key = "instinct_ember",
            category = "instinct",
            requires = function(state)
                return state.metaBonuses.fireballEnabled and state.metaBonuses.fireballEnabled > 0
            end,
            effects = {
                common = { fireballDamage = 6, fireballRadius = 8 },
                rare = { fireballDamage = 11, fireballRadius = 14 },
                mythic = { fireballDamage = 18, fireballRadius = 22 },
            },
        },
        {
            key = "instinct_frost",
            category = "instinct",
            requires = function(state)
                return state.metaBonuses.frostEnabled and state.metaBonuses.frostEnabled > 0
            end,
            effects = {
                common = { frostDamage = 5, frostRadius = 8, frostDuration = 0.08 },
                rare = { frostDamage = 9, frostRadius = 14, frostDuration = 0.14 },
                mythic = { frostDamage = 15, frostRadius = 20, frostDuration = 0.20 },
            },
        },
    },
}

return MutationBalance
