## Context

The user supplied `assets/models/stone_golem/stone_golem.glb` (with its `.blend` and a `source/` folder of Meshy files). Godot imports four clips:

| Clip | Length | Notes |
|---|---|---|
| idle | 1.67 s, loops | guard stance, hammer in the right hand |
| walk | 1.04 s, loops | in place (no root travel) |
| attack | 1.83 s | two-handed overhead slam: hammer raised by 1.22 s, head on the floor about 1 m ahead by 1.55–1.63 s |
| death | 2.5 s | topples and lies flat |

There is no run clip and no hit clip. The model faces +Z, is about 2.2 m tall, and carries its hammer on a `Prop_Hammer` bone. It has no eyes. The rig has a `headfront` bone at the face.

## Goals / Non-Goals

**Goals:** a readable boss fight at the end of The Ossuary, built from the supplied model and placeable from the editor; a room that only opens once the skeletons are dead; a boss health bar; the key as the boss's reward.

**Non-Goals:** editing the supplied GLB or Blender file, new paid Meshy generation, a second level (the exit still ends the run), phases or special attacks beyond the slam.

## Decisions

1. **Presentation reuse.** `golem_presentation.gd` extends `skeleton_presentation.gd`. The skeleton presentation gains a `_prepare_model()` hook (called before the model enters the tree), a `model_scale`, a configurable hit tilt, and a configurable eye light colour and range. Run maps to the walk clip.
2. **Scale and stats.** Model scale 1.35 (about 3 m tall), capsule radius 0.7 and height 3.0. 420 health (about 12 blade hits or 15 staff bolts), 2.2 m/s, 24 damage, 1.2 s windup, 2.0 s cooldown. `enemy.gd` gets `melee_range` (default 1.9, golem 3.0), used both to start and to land a melee attack, so stepping out of reach during the windup dodges the slam.
3. **Attack timing.** The windup maps `attack` 0.4 → 1.55 s (the hammer rises and comes down). Contact is at 1.55 s, with a dust ring at the impact point, then 0.28 s of recovery.
4. **Dormant statue.** `golem_enemy.gd` extends `enemy.gd`. While dormant, the golem neither moves nor animates, and its eyes are dark. It wakes when the player is within 6 m with line of sight (the closed seal blocks line of sight) or when it takes damage. Waking takes 1.6 s (a grinding shake, a dust ring and the eyes lighting up), then it chases. The dormant pose is the first frame of idle.
5. **Eyes.** Two small emissive spheres on the `headfront` bone, named `EyeGlow` so the supplied `eye_flicker.gd` drives them like the skeleton eyes, in ember orange with a small light. The sockets are dark stone until lit.
6. **Body tint.** The supplied texture is very light and read as white under torches, so the golem's body material is multiplied by a grey tint (0.62).
7. **Boss bar.** The HUD shows the first node in group `active_bosses` (name and health) at the top centre. The golem joins that group when it wakes and leaves it 2.5 s after dying.
8. **Held key.** In an authored level, a key marker within 1.5 m of a golem marker is held by that golem. The pickup is hidden and not monitoring until 1 s after the golem dies, then appears where the golem fell, with a message.
9. **Bone seal.** A `KeyWard` (now with configurable messages) placed by a `Bone Seal` marker and guarded by every enemy in the level except golems. If there are none, it opens at once.
10. **Statues.** `golem_statue.gd` (a `@tool` prop, so the editor preview shows it) instances the golem GLB at 0.6 scale on a 1 m plinth, freezes it in one of four poses by placement order (guard, hammer raised, mid-stride, ready), and replaces its materials with darker weathered stone. Collision covers the plinth and statue. Deriving the statues from the supplied model was chosen over Meshy generation: it costs no credits, and the statues match the boss.
11. **The Sanctum.** A round room centred at (0, 0, -23): 7 m inner radius, 5 m walls built from 24 prism segments (`level_factory.ring`), a 24-sided floor, and a straight facade with a 2 × 3 m doorway (the seal), reached by a short passage through the gallery's north wall. The pedestal is a sloped round block (radius 3.4 m → 1.8 m, 0.45 m high, about 16°). The first version used three 0.15 m steps, but the player's capsule cannot step up 0.15 m, so the steps were replaced by a slope that the player, the golem and the baked navigation all handle. Decoration: four statues, two braziers, four wall lanterns and two crystal lamps by the gate. The key marker moves onto the pedestal with the golem, and the exit gate moves to the far wall.
12. **Next level.** Not decided yet; the gate keeps the existing victory screen.
13. **Source files.** `.gdignore` in `stone_golem/source/`; Blender import was already disabled.
