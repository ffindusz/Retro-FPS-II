## Context

The original demo (`scripts/level.gd`) is built from code. The key sits at (28, 0.5, -12) in the crypt's northeast corner. The crypt already holds a Warden at (25, -10) and an Adept at (29, -8) near it. Navigation is baked from the `Geometry` node into `resources/demo_navigation.tres`, and several tests compare runs to the gameplay snapshot in `resources/atmosphere_baseline.tres`.

## Goals / Non-Goals

**Goals:** the key can only be reached after a fight at a clearly readable barrier, without changing combat stats or the gate/victory rules.

**Non-Goals:** new art or audio, levers or switches, changes to the authored mapping example, difficulty retuning beyond one extra Warden.

## Decisions

1. **Alcove geometry.** Static 3.2 m walls: a west wall at x = 25.4 (z -14 to -9) and a south wall at z = -9.4 with a 2 m gap at x 27 to 29. They are part of `Geometry`, so navigation and fingerprints include them. The "THE EMBER KEY" sign moves above the gateway on the outer face.
2. **Ward outside `Geometry`.** The ward is a separate `StaticBody3D` (layer 1) so the baked navigation keeps the gateway open. Nobody needs to path through it while it is closed because the player cannot be inside, and after it opens the existing navigation is already correct.
3. **Guards.** `_populate` spawns three guards (Warden (26.5, -7.5), Warden (30, -7.5), Adept (28, -8.3)) with the existing scenes and stats and registers them with the ward. The other crypt Warden at (18, -4) is not a guard.
4. **Opening.** The ward listens to each guard's `died` signal and opens once all have died: a 1.2 s tween sinks the bars 3.1 m into the floor slab and then hides them, so nothing hangs above the 3.2 m walls (a first version raised them and left them floating; changed after the render check). Collision is disabled when opening starts, so the player never waits on the animation. Opening happens once and emits the player message. The tween is owned by the ward, so pausing freezes it and restart frees the old run as before.
5. **Hint.** While closed, entering within 3.5 m of the ward shows "Defeat the key guards to lift the ward." once per approach.
6. **Baseline.** The gameplay world changes on purpose, so `tools/record_world_baseline.gd` re-records `atmosphere_baseline.tres` after the navigation re-bake. Historical docs keep their old hashes.

## Risks / Trade-offs

- [The extra Warden makes the run harder] → One Warden only; the full run felt right at 5 to 10 minutes. Revisit after the user's playtest.
- [Guards get stuck on the new walls] → Guards spawn outside the alcove, and a test checks navigation paths from the entrance to the key and from the key to the exit.
- [The crystal lamp at (25.9, -13.4) clipped the new west wall] → Moved to (26.5, -13.4), inside the alcove beside the key.
- [The ward blocks while opening] → Collision is disabled when opening starts.

## Migration Plan

Re-bake navigation, re-record the baseline, run `tools/verify.ps1`. Older builds and release records are untouched; no new Windows export unless the user asks.
