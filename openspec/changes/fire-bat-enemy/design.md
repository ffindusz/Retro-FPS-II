## Context

Enemies are `CharacterBody3D`s driven by `scripts/enemies/enemy.gd`: ground navigation, gravity, a melee (0) or ranged (1) attack, and an optional presentation node with `advance_visual`/`begin_attack`/`attack_contact`/`show_hit`/`die`. The player's blade sweeps a 2.7 m capsule along the camera's forward direction, so airborne targets can be hit by looking up at them. Authored levels spawn enemies from `LevelPlacement` kinds, which are stored as integers in saved maps.

## Goals / Non-Goals

**Goals:** a readable flying ranged enemy that the staff counters well and the blade can still reach, placeable from the editor and tested in the Mapping Example.

**Non-Goals:** adding bats to the original demo, free 3D pathfinding, new audio, flocking.

## Decisions

1. **Subclass, not a fork.** `bat_enemy.gd` extends `enemy.gd` and overrides movement, line of sight and the attack. Damage, death, hit flash, groups, the `died` signal and the presentation hooks stay shared.
2. **Flight.** No gravity while alive. Horizontal movement follows the ground navigation path (so walls are respected); altitude is held at `hover_height` above the floor with a small bob. In range it strafes sideways and backs off below 3.5 m. Collision mask 1 keeps it out of walls.
3. **Fireball.** 0.5 s windup (`enemy_charge` event), then a small fireball from the bat's body toward the player's camera: 7 damage, 12 m/s, orange tint, existing projectile code. Cooldown 2.2 s. 30 health, so one staff bolt or two blade hits kill it.
4. **Death.** Gravity returns, the body drops to the floor and the presentation plays its death clip; collision is removed like other enemies.
5. **Placement.** `Kind.BAT = 13`, appended. The marker sits on the floor like other enemies (so the existing floor/navigation checks apply); the bat spawns `hover_height` above it. The builder additionally checks a 0.5 m sphere at hover height for clearance.
6. **Model pipeline.** Meshy text-to-3D (preview + texture), downloaded with a provenance record. Meshy rigging is humanoid-only, so wings and body are rigged in Blender, with `fly`, `attack`, `hit` and `death` clips exported as one GLB into `assets/models/bat-animated/`. `scenes/models/bat_animated.tscn` wraps it with a presentation script matching the existing interface.
7. **Fallback.** Until the model is approved, the bat uses a procedural placeholder (body, ears, flapping wings, glowing eyes) so code and tests don't depend on paid assets.

## Risks / Trade-offs

- [Meshy produces a bat with merged or folded wings that rig badly] → Prompt for spread wings in a symmetric pose; a retry stays within the budget; the placeholder is kept as a fallback.
- [Bats can hide above cover] → Line of sight is required before firing; the hover height is below the 4 m walls.
- [Blade can't reach] → The hover height of about 2.4 m is within reach of the 2.7 m sweep when the player looks up at close range.

## Migration Plan

Additive. Existing saved maps keep their kind integers; the Mapping Example is rebuilt through the normal builder.
