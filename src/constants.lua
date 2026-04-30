local C = {}
local ProgressionBalance = require("src.data.progression_balance")
local CombatBalance = require("src.data.combat_balance")
local MutationBalance = require("src.data.mutation_balance")
local PresentationConfig = require("src.data.presentation_config")
local VisualConfig = require("src.data.visual_config")

C.SAVE_FILE = "save.json"
C.BACKUP_FILE = "save.bak"
C.SAVE_VERSION = 9
C.AUTOSAVE_INTERVAL = 30
C.RUN_TIME_LIMIT_SECONDS = 15

C.WORLD_WIDTH = 3200
C.WORLD_HEIGHT = 1800

C.MAPS = ProgressionBalance.maps

C.FOOD_BY_TIER = CombatBalance.foodByTier

C.MAX_FOOD = 125
C.FOOD_SPAWN_INTERVAL = 0.045
C.PLAYER_CONTACT_DAMAGE = 18

C.PLAYER_SPRITE = VisualConfig.playerSprite

C.PASSIVE_BASES = CombatBalance.passiveBases

C.BOSS_ARENA = CombatBalance.bossArena

C.NEST_UPGRADES = ProgressionBalance.nestUpgrades

C.NEST_LEVEL_COST_BANDS = ProgressionBalance.nestLevelCostBands

C.META_COST_DEPTH_MULTIPLIERS = ProgressionBalance.metaCostDepthMultipliers

C.META_PASSIVE_COST_DEPTH_MULTIPLIERS = ProgressionBalance.metaPassiveCostDepthMultipliers

C.DRAGON_EVOLUTION_LEVELS = ProgressionBalance.dragonEvolutionLevels

C.MUTATION_LEVEL_THRESHOLDS = MutationBalance.thresholds
C.MUTATION_RARITY_WEIGHTS = MutationBalance.rarityWeights

C.UI_ICONS = PresentationConfig.uiIcons
C.RUN_CHOICE_UI = PresentationConfig.runChoiceUi
C.RUN_END_TREE_UI = PresentationConfig.runEndTreeUi
C.RUN_HUD_UI = PresentationConfig.runHudUi
C.GUIDE_UI = PresentationConfig.guideUi
C.HUD_THEME = PresentationConfig.hudTheme
C.HELP_THEME = PresentationConfig.helpTheme
C.GUIDE_THEME = PresentationConfig.guideTheme
C.RUN_CHOICE_THEME = PresentationConfig.runChoiceTheme
C.WORLD_THEME = VisualConfig.worldTheme

return C
