## Context

The 0.5.1 re-review (recorded in `playtest-fixes` 6.2):

- Ambience is accepted.
- Torches still read as static. The only animation is a ±25% OmniLight energy modulation in `FortressPresentation.set_clock`. The visible flame is part of the static `assets/models/prop-torch/model.glb` mesh.
- The Adept death (`_play_adept_death()` in `enemy.gd`, a rigid 0.90 s tween of `visual`) plays, as the captured frames show, but isn't accepted as an animation.
- The user asked for more kinds of light: fires, lamps and magic lamps.

Assets and tools already in place:

- The Warden has a proven Meshy route: rigging (5 credits) plus library animations (15 credits for 5 actions), integrated through `warden_presentation.gd`. Its interface is `die()`, `advance_visual()`, `show_hit()`, `begin_attack()`, `attack_contact()` and `dead`.
- The Adept's refine task is recorded as `01a15a18-22aa-76bd-a5dc-272a0ef2da97` (`docs/meshy-generation.md`). The shipped GLB is `assets/models/enemy-adept/model.glb` (SHA-256 `32c0f410…`, 6.47 MB, staff fused into the single mesh).

## Goals / Non-Goals

**Goals:**
- Flames that visibly move on all six torches, driven by the existing deterministic flicker signal.
- Three new procedural fixture types placed through the level, within a light budget, with no gameplay or navigation change.
- A skeletal Adept with a real death animation, integrated with the Warden-style presentation interface.
- Credit spend capped at 40.
- Fallbacks retained, gameplay fingerprints unchanged, a 0.6.1 export.

**Non-Goals:**
- Music, the guarded key barrier, layout/encounter changes, new enemies.
- Re-authoring the torch model.
- Finger or IK quality on the Adept.
- Separating the fused staff from the Adept mesh.

## Decisions

1. **Flames: a camera-facing shader quad plus a small GPUParticles3D ember emitter, driven by one shared flicker value.**
   - `flame_visual.gd` builds a `QuadMesh` with a spatial shader: unshaded, additive, billboard on the Y axis. Its procedural flame shape uses scrolling value noise and a teardrop mask, plus inner-white → orange → red colour bands.
   - The shader reads a `time` uniform and an `intensity` uniform that `FortressPresentation.set_clock` sets from the same modulation it applies to the light. It never reads `TIME`, so motion is deterministic, freezes on pause and resets on restart.
   - Embers come from a ~12-particle emitter whose `speed_scale` is set to 0 while paused.
   - The flame is placed by locating the torch head in the model's local AABB: top centre, offset toward the wall-facing side, measured once. The static mesh flame is covered by the new flame's base glow. The GLB is not edited.
   *Alternative:* a flipbook texture. Rejected: it needs an authored atlas and can't be scaled per flicker.

2. **Fixtures: one `light_fixtures.gd` builder with three kinds, sharing the flame shader and a glow-pulse shader.**
   - **Brazier:** a stone bowl on a short pedestal (cylinders/torus), with a larger flame, embers and an OmniLight (range 5).
   - **Lantern:** a chain of thin boxes from a wall bracket or ceiling, an iron cage with emissive glass panes, a small inner flame and an OmniLight (range 4).
   - **Arcane crystal lamp:** a stone plinth or wall sconce holding an emissive cyan prism with a slow 0.25 Hz pulse (±20%), plus a cyan OmniLight (range 3.5).

   `FortressPresentation` owns them and drives their clocks from `set_clock`, alongside the torches.
   - Placement is a fixed list in `_dress()`: about 2 braziers, 3 lanterns and 3 crystal lamps, at most 8 lights.
   - Floor fixtures sit against walls or cover blocks, at least 0.6 m from any navmesh edge used by the route tests.
   - No fixture has collision. Braziers are small enough to read as dressing, and the existing walls already stop movement.
   - None casts shadows. The torches keep their 2 shadow casters, so the total stays at 2.

   *Alternative:* Meshy models. The user chose procedural.

3. **Adept rig: Meshy rigging from the existing refine task, then one library animation request.**
   New `tools/meshy_adept_rig.py` reuses `meshy_generate.read_key/download/SafeError` and copies the pilot's safety pattern:
   - a whitelist of routes and bodies
   - a checkpoint after every paid POST
   - no retry of an ambiguous or failed stage
   - credentials and signed URLs never stored
   - a `--submit` flag required for any POST

   Stages:
   1. Read-only preflight: check the balance (≥ 40) and query the animation library to resolve the action IDs: Idle (0), a walk, a spell-cast / staff attack, Hit_Reaction (178) and Dead (8). The chosen cast and walk entries are printed and recorded before any spend.
   2. Rig: `POST /openapi/v1/rigging {input_task_id: <adept refine id>, height_meters: <measured Adept height>}`, reserving 5 credits. If Meshy rejects the old task ID (for example because it expired), use one fallback route: upload the checksum-verified GLB as a data URI. That is still one rig submission.
   3. Animate: `POST /openapi/v1/animations {rig_task_id, action_ids: [5 ids]}`, reserving 15 credits.

   Expected spend is 20 credits, with a hard ceiling of 40 checked before each POST.

   Outputs go to `assets/models/adept-animated/`: the animated GLB, any textured GLB, and `provenance.json`.

4. **Adept presentation: `adept_presentation.gd` mirrors the Warden's interface.**
   - `scenes/models/adept_animated.tscn` selects the presentation script.
   - In `enemy.gd`, `presentation` is set when the instantiated model `has_method("advance_visual")`, now for either archetype. The `archetype == 0` guard on that line is removed.
   - The ranged path calls `presentation.begin_attack()` at windup start (already wired for both archetypes in `_physics_process`) and `attack_contact()` at release.
   - The Adept implementation plays the cast clip scaled to `windup_duration` and does not change resolve timing.
   - Hit flash and windup lean are provided by the presentation's own hit and cast clips, so dropping the null-presentation visuals is intended for animated Adepts only.
   - `die()` plays `Dead` once and holds the last frame.
   - The clock is advanced by `advance_visual(delta, …)` from the physics step, so pause freezes it, as with the Warden.
   - The ranged enemy scene switches `model_scene` to `adept_animated.tscn`. If that scene fails to load, it reverts to `adept.tscn`, which keeps the 0.5.1 tween death path.

5. **Version 0.6.1** (after the upstream 0.6.0 level-authoring sync), exported to `builds/windows-0.6.1/`. Earlier builds are kept.

## Risks / Trade-offs

- **The staff fused to the mesh may deform oddly when rigged.**
  Mitigation: accept minor bending. Review frames before integrating. If unusable, keep the fallback and stop spending; a separate staff is a follow-up.
- **The old refine task may no longer be riggable through `input_task_id`.**
  Mitigation: the single data-URI upload fallback. The GLB is 6.5 MB; if the request size is rejected, record it and stop rather than retry.
- **The library may lack a fitting cast clip.**
  Mitigation: use a generic attack or spell action chosen at preflight. As a last resort, use Idle with a procedural lean.
- **Additive flames can look like a flat sprite from some angles.**
  Mitigation: Y-billboarding, a second crossed quad, and an ember layer. Review frames at 1280×720.
- **Additional lights cost performance.**
  Mitigation: no new shadow casters, short ranges, at most 8 lights. Profile frame time against 0.5.1.
- **The paid step is an external, irreversible spend.**
  Mitigation: user authorization to a 40-credit cap was given on 2026-11-03. Run preflight first, and pass `--submit` only after the preflight output looks right.
