## Why

On 2026-11-25 the user added a stagger animation to the stone golem (`hit` clip in `assets/models/stone_golem/stone_golem.glb`, Meshy source `source/golem_hit_meshy.glb`) and asked for it to be used when the golem gets hit. They then added the same kind of `hit` clip to the skeleton warrior and archer (`source/skeleton_hit_meshy.glb` in both folders) and asked for the same hit reaction there. Until now a hit only flashed these enemies and tilted them slightly.

## What Changes

- A hit staggers the stone golem, the skeleton warrior and the skeleton archer: each plays its `hit` clip (1.67 s), stands still, and loses an attack it was winding up (the golem's slam, the warrior's slash, the archer's shot).
- After recovering, an enemy ignores further staggers for 4 s, so rapid magic (one bolt every 0.36 s) cannot hold it in place. Hits still deal full damage.
- The golem: the hit that wakes the dormant statue, and hits during its awakening, do not stagger it. Its stagger also plays the stone `wall` cue.
- The stagger is an opt-in setting on the shared enemy (`stagger_on_hit`), so other enemies are unchanged.
- Version 0.12.1.

## Capabilities

### New Capabilities

- `enemy-stagger`: the hit reaction of the golem and the skeletons.

## Impact

`scripts/enemies/enemy.gd`, `skeleton_presentation.gd`, `golem_enemy.gd`, `golem_presentation.gd`; the golem and skeleton enemy and model scenes; `combat_audio.gd` (one cue); `tests/test_golem_boss.gd`, `tests/test_skeletons.gd`; `tools/capture_sanctum.gd`, `tools/capture_ossuary.gd`; docs and version. No Meshy credits used by this change.

## Addendum 2026-11-26: golem crumble

The user replaced the golem's death animation with a 3.5 s crumble: a separate `GolemRubble` mesh with 36 chunk bones breaks apart and settles into a pile. The game changes needed for it:

- The skeleton presentation now copies and tints every skinned surface (body and rubble), not just the last one found, so the golem's stone tint and hit flash reach the whole model.
- A `cull_radius` setting on the presentation; the golem uses 2.6 (model metres) so flying chunks are not culled.
- The ember key now appears 2 s after the golem dies (was 1 s), once the rubble has settled.
