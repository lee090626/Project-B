# Manual Regression Checklist

## Core Loop

- Start a fresh save and confirm the game enters a playable run without load errors.
- Eat nearby food and confirm the player gains essence, level progress moves, and the eat pulse appears around the dragon.
- Let autosave run, restart the game, and confirm the run state restores correctly.

## Context Guides

- On a fresh save, confirm the `run_start` guide appears once and does not reappear after saving and reloading.
- Reach the first instinct choice and confirm the `first_instinct` guide appears once while the run is paused.
- Unlock any new map and confirm the `first_map_unlock` guide appears once.
- Reach boss entry conditions on map 4 and confirm the `boss_ready` guide appears once.
- Open the growth screen after a run and confirm the `run_end_tree` guide appears once.
- Verify every guide renders correctly in English and Korean.

## Combat Fixes

- Buy lightning chain nodes and confirm extra chain targets are hit.
- Confirm lightning stops chaining outside the allowed chain radius.
- Confirm lightning segments render as a visible chain instead of one straight line.
- Reach the instinct threshold and confirm the card overlay opens immediately.
- Unlock frost-side passive nodes near node 41 and confirm node 41 remains clickable.

## Progression and Save Safety

- Switch maps, save, reload, and confirm current map and unlock state are preserved.
- Enter the final boss, save before or after the fight, reload, and confirm boss state restores safely.
- Finish a run, open the Meta Tree, buy an upgrade, reload, and confirm purchases persist.

## Acceptance Gates

- First instinct appears within `5 minutes` on a fresh save.
- Map 2 opens in the early session and Map 3 is reachable before `2 hours`.
- Map 4 and boss entry remain late-game goals but are visible before full tree completion.
- Full completion on a skilled route lands inside `8-10 hours`.
- No run produces a `30 minute` or longer no-buy gap.
- Boss success is not locked to a single dominant build.

## V1 Candidate Signoff

- Record `3` fresh-save sessions and `2` existing-save sessions in `docs/v1-balance-notes.md`.
- Re-run every checklist item after the final balance pass.
- Freeze feature work after signoff and allow only critical bug fixes.
