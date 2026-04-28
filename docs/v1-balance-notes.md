# V1 Balance Notes

## Current Time Target

- Target full completion time: `8-10 hours`
- Curve shape: `fast first 20-30 minutes then longer late-game finish`

## Current Balance Data Modules

- `src/data/progression_balance.lua`
  - map rewards
  - map unlock requirements
  - nest level cost bands
  - meta tree depth multipliers
- `src/data/combat_balance.lua`
  - food tier stats
  - passive base values
  - boss arena values
- `src/data/mutation_balance.lua`
  - instinct thresholds
  - rarity weights
  - instinct card effect values

## Remaining Tables Worth Externalizing Later

- `src/meta_system.lua`
  - branch node costs
  - branch scaling
  - per-level bonus values

## Manual Balance Checks For v1 Closeout

- First instinct choice should open reliably within the first 5 minutes.
- Map 2 and Map 3 should unlock at a pace that feels faster than passive waiting.
- Entering the final map should not require a fully complete tree.
- Lightning, fireball, and frost builds should each reach a viable mid-run state without one build dominating every run.
- Boss entry should feel reachable before the timer expires on a competent run, but not trivial on a weak build.

## Notes

- Keep final v1 tuning inside the current data modules unless repeated balance passes become too slow.
- If more than one pass still requires editing the same values across multiple systems, move meta node definitions into a dedicated data module next.

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

## Playtest Session Log

| Session | Save | Build focus | First instinct | Map 2 | Map 3 | Map 4 | Boss ready | First victory | Ending | Longest no-buy gap | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | fresh |  |  |  |  |  |  |  |  |  |  |
| 2 | fresh |  |  |  |  |  |  |  |  |  |  |
| 3 | fresh |  |  |  |  |  |  |  |  |  |  |
| 4 | existing |  |  |  |  |  |  |  |  |  |  |
| 5 | existing |  |  |  |  |  |  |  |  |  |  |

## Second Pass Tuning Rules

- If the first instinct exceeds `5 minutes`, only lower `thresholds` in `src/data/mutation_balance.lua`.
- If Map 2 or Map 3 is too late, lower `unlockRequires` only and keep `reward` unchanged.
- If late-game income spikes again after Map 4, lower `reward` only and keep `hpScale` unchanged.
- If the boss is still too hard, tune in this order only: `bossHp`, `weakPointHp`, `arenaTimer`.
- If any run produces a no-buy gap over `30 minutes`, relax meta depth multipliers before touching nest bands.

## V1 Candidate Freeze Gate

- Full completion on a skilled route must land inside `8-10 hours`.
- New save runs must reach the first instinct inside `5 minutes`.
- Map 3 must be reachable before `2 hours`.
- No single build should trivialize the boss while other builds consistently fail.
- Once these targets are met, run the full manual regression checklist and freeze new feature work except critical bugs.
