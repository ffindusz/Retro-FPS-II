## 1. Models

- [x] 1.1 Write the Meshy plan (`docs/meshy-rune-door.json`) and the PowerShell Meshy tool (`tools/meshy_generate.ps1`).
- [x] 1.2 Generate previews, check them, refine the chosen ones; copy the models and provenance into `assets/models/`.
  - 2026-11-25: frame and socket previews good. The first leaf preview was a hollow frame; one replacement preview (`rune-door-leaf-solid`) was made. 50 credits in total (1,331 → 1,281).
- [x] 1.3 Bake the rune glow masks (`tools/make_rune_masks.gd`).

## 2. Gameplay

- [x] 2.1 Rune door prop: frame, sliding leaves with collision and rune strokes, key socket, states, glow, sounds.
- [x] 2.2 Placement kind 19 with preview; builder exit rule (one Exit Gate or Rune Door); runtime spawning and interaction.
- [x] 2.3 Golem Sanctum far wall, corridor and lamp moves in `level_factory`; regenerate The Ossuary.

## 3. Verification and handoff

- [x] 3.1 Add `tests/test_rune_door.gd`; update the golem, skeleton and editor tests; run `tools/verify.ps1` and the real-editor test.
- [x] 3.2 Render the door (`tools/capture_rune_door.gd`); bump to 0.12.0; update README, asset manifest and model workflow.
- [x] 3.3 Get the user's playtest of the rune door. Record only what is reported.
  - 2026-11-25: the user played it in the game: "i like it!"
