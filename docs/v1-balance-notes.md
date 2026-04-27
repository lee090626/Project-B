# V1 Balance Notes

## Current Tables Worth Externalizing Later

- `C.MAPS`
  - reward multipliers
  - hp scale
  - spawn rarity tables
- `C.FOOD_BY_TIER`
  - hp
  - essence
  - speed
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
