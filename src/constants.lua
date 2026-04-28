local C = {}
local ProgressionBalance = require("src.data.progression_balance")
local CombatBalance = require("src.data.combat_balance")
local MutationBalance = require("src.data.mutation_balance")

C.SAVE_FILE = "save.json"
C.BACKUP_FILE = "save.bak"
C.SAVE_VERSION = 8
C.AUTOSAVE_INTERVAL = 30
C.RUN_TIME_LIMIT_SECONDS = 15

C.WORLD_WIDTH = 3200
C.WORLD_HEIGHT = 1800

C.MAPS = ProgressionBalance.maps

C.FOOD_BY_TIER = CombatBalance.foodByTier

C.MAX_FOOD = 125
C.FOOD_SPAWN_INTERVAL = 0.045
C.PLAYER_CONTACT_DAMAGE = 18

C.PASSIVE_BASES = CombatBalance.passiveBases

C.BOSS_ARENA = CombatBalance.bossArena

C.NEST_UPGRADES = {
    {
        key = "brooder",
        basePointCost = 1,
        maxLevel = 10,
    },
    {
        key = "larder",
        basePointCost = 1,
        maxLevel = 10,
    },
    {
        key = "roost",
        basePointCost = 1,
        maxLevel = 10,
    },
    {
        key = "hatchery",
        basePointCost = 2,
        maxLevel = 10,
    },
}

C.NEST_LEVEL_COST_BANDS = ProgressionBalance.nestLevelCostBands

C.META_COST_DEPTH_MULTIPLIERS = ProgressionBalance.metaCostDepthMultipliers

C.META_PASSIVE_COST_DEPTH_MULTIPLIERS = ProgressionBalance.metaPassiveCostDepthMultipliers

C.DRAGON_EVOLUTION_LEVELS = { 20, 50, 90 }

C.MUTATION_LEVEL_THRESHOLDS = MutationBalance.thresholds
C.MUTATION_RARITY_WEIGHTS = MutationBalance.rarityWeights

C.RUN_CHOICE_UI = {
    cardWidth = 272,
    cardHeight = 252,
    cardGap = 28,
}

C.RUN_END_TREE_UI = {
    worldScale = 460,
    minZoom = 0.4,
    maxZoom = 2.6,
    zoomStepUp = 1.12,
    zoomStepDown = 0.88,
    nodeRadius = 24,
    clickThreshold = 8,
    tabWidth = 140,
    tabHeight = 34,
    tabGap = 12,
}

C.RUN_HUD_UI = {
    padding = 14,
    topBarHeight = 74,
    groupGap = 10,
    chipPadX = 10,
    toastDuration = 2.2,
    autosaveDuration = 2.8,
}

C.GUIDE_UI = {
    width = 620,
    minHeight = 132,
    topYGame = 100,
    topYChoice = 24,
    topYRunEnd = 126,
    buttonWidth = 116,
    buttonHeight = 30,
    padX = 22,
    padY = 18,
}

C.HUD_THEME = {
    panelFill = { 0.04, 0.08, 0.08, 0.92 },
    panelInner = { 0.08, 0.12, 0.12, 0.82 },
    panelLine = { 0.87, 0.73, 0.42, 0.95 },
    panelGlow = { 0.23, 0.74, 0.58, 0.25 },
    text = { 0.97, 0.94, 0.84, 1.0 },
    dim = { 0.73, 0.86, 0.8, 1.0 },
    accent = { 0.92, 0.78, 0.44, 1.0 },
    accentSoft = { 0.35, 0.76, 0.6, 1.0 },
    warning = { 0.92, 0.47, 0.25, 1.0 },
    danger = { 0.93, 0.36, 0.28, 1.0 },
    progressBg = { 0.1, 0.14, 0.14, 0.92 },
    progressFill = { 0.36, 0.88, 0.68, 0.95 },
    progressDone = { 0.93, 0.78, 0.42, 0.95 },
    buttonFill = { 0.12, 0.16, 0.14, 0.96 },
    buttonLine = { 0.92, 0.76, 0.43, 0.96 },
    buttonText = { 0.98, 0.94, 0.84, 1.0 },
    chipFill = { 0.08, 0.11, 0.11, 0.94 },
    chipLine = { 0.31, 0.75, 0.62, 0.95 },
}

C.HELP_THEME = {
    panelFill = { 0.08, 0.07, 0.06, 0.95 },
    panelInner = { 0.16, 0.13, 0.1, 0.9 },
    panelLine = { 0.86, 0.72, 0.42, 0.96 },
    text = { 0.97, 0.94, 0.86, 1.0 },
    dim = { 0.8, 0.84, 0.78, 1.0 },
    chipFill = { 0.14, 0.12, 0.1, 0.96 },
    chipLine = { 0.33, 0.77, 0.61, 0.96 },
}

C.GUIDE_THEME = {
    panelFill = { 0.07, 0.08, 0.11, 0.96 },
    panelInner = { 0.12, 0.14, 0.18, 0.92 },
    panelLine = { 0.93, 0.79, 0.44, 0.98 },
    panelGlow = { 0.32, 0.8, 0.65, 0.28 },
    title = { 0.98, 0.95, 0.85, 1.0 },
    text = { 0.86, 0.93, 0.95, 1.0 },
    dim = { 0.74, 0.82, 0.88, 1.0 },
    chipFill = { 0.08, 0.1, 0.12, 0.96 },
    chipLine = { 0.38, 0.82, 0.7, 0.98 },
    buttonFill = { 0.14, 0.18, 0.24, 0.98 },
    buttonLine = { 0.93, 0.79, 0.44, 0.98 },
}

C.RUN_CHOICE_THEME = {
    overlay = { 0.01, 0.03, 0.03, 0.78 },
    title = { 0.97, 0.92, 0.78, 1.0 },
    summary = { 0.75, 0.87, 0.83, 1.0 },
    common = {
        fill = { 0.08, 0.11, 0.11, 0.96 },
        inner = { 0.12, 0.16, 0.16, 0.94 },
        line = { 0.44, 0.84, 0.67, 0.96 },
        ribbon = { 0.2, 0.45, 0.38, 0.96 },
    },
    rare = {
        fill = { 0.07, 0.1, 0.12, 0.96 },
        inner = { 0.11, 0.16, 0.18, 0.94 },
        line = { 0.49, 0.86, 0.92, 0.96 },
        ribbon = { 0.2, 0.41, 0.52, 0.96 },
    },
    mythic = {
        fill = { 0.12, 0.08, 0.06, 0.97 },
        inner = { 0.18, 0.12, 0.09, 0.95 },
        line = { 0.96, 0.78, 0.43, 0.98 },
        ribbon = { 0.64, 0.32, 0.12, 0.98 },
    },
}

C.WORLD_THEME = {
    vignette = { 0.01, 0.02, 0.02, 0.18 },
    nestShadow = { 0.11, 0.08, 0.05, 0.16 },
    aura = { 0.36, 0.93, 0.7, 0.1 },
    auraLine = { 0.88, 0.76, 0.44, 0.24 },
    magnetFill = { 0.88, 0.74, 0.35, 0.06 },
    magnetLine = { 0.93, 0.78, 0.42, 0.24 },
    eatLine = { 0.38, 0.85, 0.66, 0.28 },
    magnetFillCutoff = 240,
    magnetOutlineWidth = 1.5,
    playerAuraScale = 2.05,
    playerAuraLineScale = 2.45,
    fireballGlowScale = 0.12,
    fireballImpactFillScale = 0.22,
    eatPulseMinRadius = 18,
    eatPulseRadiusScale = 1.5,
    cullMargin = 64,
    maps = {
        [1] = {
            sky = { 0.08, 0.13, 0.11 },
            ground = { 0.16, 0.22, 0.16 },
            glow = { 0.3, 0.41, 0.25, 0.2 },
            grid = { 0.34, 0.44, 0.3, 0.11 },
            sigil = { 0.54, 0.66, 0.46, 0.07 },
        },
        [2] = {
            sky = { 0.07, 0.09, 0.14 },
            ground = { 0.12, 0.16, 0.25 },
            glow = { 0.18, 0.28, 0.46, 0.18 },
            grid = { 0.42, 0.56, 0.72, 0.1 },
            sigil = { 0.58, 0.8, 0.95, 0.08 },
        },
        [3] = {
            sky = { 0.16, 0.07, 0.05 },
            ground = { 0.3, 0.12, 0.08 },
            glow = { 0.52, 0.22, 0.1, 0.18 },
            grid = { 0.74, 0.34, 0.18, 0.1 },
            sigil = { 0.97, 0.62, 0.24, 0.08 },
        },
        [4] = {
            sky = { 0.07, 0.05, 0.09 },
            ground = { 0.16, 0.09, 0.19 },
            glow = { 0.3, 0.14, 0.33, 0.2 },
            grid = { 0.55, 0.33, 0.66, 0.09 },
            sigil = { 0.82, 0.53, 0.92, 0.07 },
        },
    },
}

return C
