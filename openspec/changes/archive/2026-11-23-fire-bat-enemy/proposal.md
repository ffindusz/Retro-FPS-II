## Why

On 2026-11-19 the user asked for a new enemy: a flying bat that fires small fireballs at the player. The model is to be made with Meshy, with textures and animations, and tested in the current test level. In follow-up answers the user chose the Mapping Example as the test level, rigging and animating in Blender (Meshy's rigging only supports humanoids), and a Meshy budget of up to 100 credits.

## What Changes

- New `FireBat` enemy (archetype 2): hovers about 2.4 m above the floor, keeps a preferred 5 to 9 m distance, strafes, backs off when the player closes in, and fires small fireballs after a short windup. On death it drops to the floor.
- New editor placement kind `Fire Bat` (appended, integer 13) with a preview, builder validation of its hover clearance, and runtime spawning in authored levels.
- A bat is added to the Mapping Example's courtyard, and the example is rebuilt.
- Model: one Meshy text-to-3D bat with PBR textures (budget up to 100 credits, balance checked first). Rig and clips (fly, attack, hit, death) authored in Blender and exported as one GLB. Until it is approved, a procedural placeholder with flapping wings is used.
- Tests for flight, distance keeping, fireballs, death, pause/restart, editor placement and the rebuilt example; version 0.9.0.

## Capabilities

### New Capabilities

- `fire-bat-enemy`: flying fireball enemy, its editor placement, model/animation pipeline and fallback.

### Modified Capabilities

None. Existing enemies, the original demo and its gameplay baseline are unchanged.

## Impact

New `scripts/enemies/bat_enemy.gd`, `scenes/enemies/bat_enemy.tscn`, bat model/presentation files, `scripts/levels/level_placement.gd`, `scripts/levels/authored_level.gd`, level builder/factory, the Mapping Example source and build, tests and docs. Paid Meshy generation only within the approved budget.
