## Why

On 2026-11-23 the user asked for a second test map with two new enemy models, `skeleton` and `skeleton_archer`, using all of their idle/walk/run/attack/die animations and their glowing red eyes. The user supplied both models (Meshy sources rigged and animated in Blender) in `assets/models/skeleton/` and `assets/models/skeleton_archer/`, each with an `eye_flicker.gd` for the eyes.

## What Changes

- New `Skeleton` melee enemy and `Skeleton Archer` ranged enemy, using the shared enemy AI with their own stats, clips and presentation. The warrior walks or runs depending on speed and slashes with its sword; the archer draws its bow and shoots arrows.
- One shared presentation script for both skeletons: idle, walk, run, attack (stretched over the AI windup), death, hit flash, and the red eyes made brighter, pulsing with the supplied `eye_flicker.gd`, plus a small red light.
- Arrows: the existing projectile gets an arrow style (a shaft with no light) with arrow impact feedback, and the archer has its own shot event (no magic cast sound).
- Editor placement kinds `Skeleton` (14) and `Skeleton Archer` (15), appended, with previews and the same builder checks as other ground enemies.
- A second test map, **The Ossuary** (an entrance hall, a pillared gallery and a side chamber), with skeletons and archers, reachable from **Choose Level** and from a main menu button.
- Godot's `.blend` import is disabled and the raw `source/` folders are ignored, so the Blender files and Meshy sources stay in the repository without being imported or exported.
- Tests and version 0.10.0.

## Capabilities

### New Capabilities

- `skeleton-enemies`: the skeleton warrior and archer, their presentation, editor placement and the Ossuary test map.

### Modified Capabilities

None. Existing enemies, the original demo and the Mapping Example are unchanged.

## Impact

New skeleton enemy and model scenes, `scripts/enemies/skeleton_presentation.gd`, the Ossuary authoring and generated scenes, `level_placement.gd`, `authored_level.gd`, the level builder and factory, `projectile.gd`, `enemy.gd` (configurable attack events and projectile style), combat audio and feedback for arrows, `session.gd` (menu button), `project.godot`, tests and docs. No paid generation.
