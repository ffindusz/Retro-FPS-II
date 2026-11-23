## Context

The user supplied two rigged, animated GLBs that share a 26/27-bone humanoid rig. Godot imports their clips with the `_loop` suffix removed and looping set:

| Model | Clips (seconds) | Props on bones |
|---|---|---|
| `skeleton/skeleton_warrior.glb` | idle 1.67, walk 1.04, run 0.67, attack 1.5, death 2.21 | Sword, Shield, EyeGlow |
| `skeleton_archer/skeleton_archer.glb` | idle 1.67, walk 1.04, run 0.67, aim_idle 5.0, attack 7.83, death 2.21 | Bow, Quiver, Arrow, EyeGlow |

Both models face +Z, like the Meshy Adept. The warrior's sword reaches furthest forward at about 0.56 s into `attack`. The archer's `attack` clip keeps the bow at the hip and only moves the drawing hand. In `aim_idle` the bow is raised from 3.6 s, fully drawn by about 4.5 s and held across the loop wrap. The `Arrow` mesh has zero size, so no nocked arrow is ever visible. Each `EyeGlow` mesh is very small (about 9 × 1 cm) and imports with emission energy 1.0.

## Goals / Non-Goals

**Goals:** two readable undead enemies built from the supplied models, placeable from the editor, and a second test map to play them in.

**Non-Goals:** editing the supplied GLBs or Blender files, new paid generation, retreat or kiting AI for the archer, adding skeletons to the original demo or the Mapping Example.

## Decisions

1. **Shared AI, own scenes.** `skeleton_enemy.tscn` (archetype 0) and `skeleton_archer.tscn` (archetype 1) reuse `enemy.gd`. The warrior has 48 health, 3.0 m/s, 11 damage and a 0.6 s windup. The archer has 40 health, 2.2 m/s, 9 damage, a 0.9 s windup, a 2.4 s cooldown and 18 m/s arrows.
2. **One presentation script.** `skeleton_presentation.gd` takes the GLB and a clip table as exports, following the Adept's sampling approach: manual seek, short blends, root drift locked to the collider, and windup progress mapped onto the native release time. The walk or run clip is chosen from the actual travel speed, and the stride keeps the feet in step.
3. **Warrior attack.** `attack` from 0 to 0.56 s during the windup, contact at 0.56 s, then the rest of the clip as recovery.
4. **Archer attack.** It uses `aim_idle` 3.6 → 4.5 s as the draw (it reads as a bow shot; the supplied `attack` clip does not). The arrow leaves at 4.5 s, the draw is held 0.25 s for recovery, and then the archer blends back to idle. The 7.8 s `attack` clip stays in the GLB unused.
5. **No hit clip.** Neither model has a hit reaction, so a hit gets a brief bone-tint flash and a small backward tilt of the body.
6. **Eyes.** The supplied `eye_flicker.gd` is attached above the model with a raised `base_energy` (5.0) so the eyes read in the game's dark rooms. A small red OmniLight (no shadows) at the eyes follows the same pulse. The eyes go out over the death clip.
7. **Arrow projectile.** `projectile.gd` gets a `style` (`magic`, the default, or `arrow`). Arrows draw a thin shaft and head pointing along their flight, have no projectile light, and report `weapon = arrow`, so impacts use the non-magic effect and the wall sound. `enemy.gd` gets optional windup and release event names. The archer publishes `enemy_draw` (silent) and `enemy_shot` (the swing cue) instead of the magic charge and cast events.
8. **Placement.** `Kind.SKELETON = 14` and `Kind.SKELETON_ARCHER = 15`, appended. Previews instance the GLB turned to face -Z. The builder applies the same capsule overlap check as the Warden and Adept.
9. **The Ossuary.** `level_factory.create_ossuary()` builds Cyclops blocks: an 8 × 8 m entrance hall, a 12 × 22 m gallery with six pillars for cover from archers, and an 8 × 8 m side chamber that holds the key. Three warriors and three archers, health and mana, torches, a brazier, urns and ambience zones. `tools/create_ossuary.gd` writes the authoring scene once, and `tools/build_level.gd` builds it. The built map appears in **Choose Level** automatically, and a main-menu button opens it directly.
10. **Source files.** `filesystem/import/blender/enabled=false` and `.gdignore` in both `source/` folders keep the Blender files and raw Meshy files versioned but out of import and export.
