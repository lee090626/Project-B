# V1 Balance Notes

## Current Time Target

- Target full completion time: `8-10 hours`
- Curve shape: `fast first 20-30 minutes then longer late-game finish`

## Current Tables Worth Externalizing Later

- `C.MAPS`
  - reward multipliers
  - hp scale
  - spawn rarity tables
- `C.NEST_LEVEL_COST_BANDS`
- `C.FOOD_BY_TIER`
  - hp
  - essence
  - speed
- `C.META_COST_DEPTH_MULTIPLIERS`
- `C.META_PASSIVE_COST_DEPTH_MULTIPLIERS`
- `C.PASSIVE_BASES`
  - lightning
  - fireball
  - frost
- `C.MUTATION_LEVEL_THRESHOLDS`
- `src/meta_system.lua`
  - branch node costs
  - scaling
  - per-level bonus values
- `src/mutation_system.lua`
  - mutation rarity weights
  - per-rarity bonus values

## Manual Balance Checks For v1 Closeout

- First instinct choice should open reliably within the first 5 minutes.
- Map 2 and Map 3 should unlock at a pace that feels faster than passive waiting.
- Entering the final map should not require a fully complete tree.
- Lightning, fireball, and frost builds should each reach a viable mid-run state without one build dominating every run.
- Boss entry should feel reachable before the timer expires on a competent run, but not trivial on a weak build.

## Notes

- Keep final v1 tuning inside the current Lua tables unless repeated balance passes become too slow.
- If more than one pass requires editing the same values across multiple files, move map, passive, and mutation tuning into dedicated data tables next.

## 2026-04-28 Tuning Pass

- Nest progression now uses cost bands instead of a single square-root curve.
  - Level `1-20`: `x1`
  - Level `21-40`: `x3`
  - Level `41-60`: `x6`
  - Level `61+`: `x10`
- Meta tree costs now scale by dependency depth.
  - Main tree depth `0-2`: `x1.0`
  - Main tree depth `3-4`: `x1.25`
  - Main tree depth `5-6`: `x1.55`
  - Main tree depth `7+`: `x1.9`
  - Passive root: `x1.35`
  - Passive depth `1-2`: `x1.55`
  - Passive depth `3-4`: `x1.85`
  - Passive depth `5+`: `x2.15`
- Map tuning for slower late-game acceleration.
  - Rewards: `1.0 / 1.28 / 1.62 / 2.0`
  - Unlock requirements: `0 / 18 / 46 / 82`
- Intentionally unchanged in this pass.
  - Run timer
  - Food base essence
  - Mutation thresholds
  - Passive base damage and cooldowns
  - Boss arena timer and HP
