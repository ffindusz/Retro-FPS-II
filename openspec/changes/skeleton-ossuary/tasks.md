## 1. Models

- [x] 1.1 Survey the supplied GLBs: clips, props, eyes, facing; pick the attack timing for each.
  - 2026-11-23: all requested clips present in both GLBs (idle, walk, run, attack, death; archer also aim_idle). Warrior contact at 0.56 s (sword's forward-most point). The archer's 7.8 s `attack` keeps the bow lowered; the draw in `aim_idle` 3.6 → 4.5 s is used instead. Both face +Z; the idle stance turns the head about 30°. The archer's `Arrow` mesh has zero size. Eyes: `EyeGlow` on the Head bone, imported at emission energy 1.0.
- [x] 1.2 Keep `.blend` files and raw `source/` folders out of Godot import and export.
  - `filesystem/import/blender/enabled=false` and `.gdignore` in both `source/` folders; the package audit checks that they are not packaged.
- [x] 1.3 Add `skeleton_presentation.gd` and the two model wrapper scenes (clips, blends, hit reaction, eyes).
  - Eyes use the supplied `eye_flicker.gd` at energy 5.0 plus a small red light (energy 0.2, range 0.35 m) in the `actor_lights` group; `authored_presentation.gd` now skips that group (it had treated the light as a torch and attached a flame).

## 2. Gameplay

- [x] 2.1 Add `skeleton_enemy.tscn` and `skeleton_archer.tscn`; arrow projectile style and archer events.
- [x] 2.2 Add `Kind.SKELETON` / `Kind.SKELETON_ARCHER`: previews, builder checks, runtime spawning.
- [x] 2.3 Create and build The Ossuary; add its main-menu button.
  - `tools/create_ossuary.gd`: 22 blocks, built without validation issues.

## 3. Verification and handoff

- [x] 3.1 Add skeleton tests and run `tools/verify.ps1`.
  - 2026-11-23: `tests/test_skeletons.gd` 34 checks. Full `tools/verify.ps1` passes with 0 failures. Real-editor `--test-level-editor`: 42 checks, 0 failures (the first editor launch crashed during the one-time texture re-import, before the tests ran; the second launch passed). Python tests not run (no Python on this machine).
- [x] 3.2 Render the skeletons in The Ossuary; bump to 0.10.0; update README and asset manifest.
  - `tools/capture_ossuary.gd` renders overview, eyes, slash, bow draw, arrow, run and death to `builds/validation/ossuary/`.
  - 2026-11-23: Windows build `builds/windows-0.10.0/Cinderkeep.exe` from bb903f4 via `tools/export_checked.ps1`; external package audit 313 resources, 0 failures; EXE starts headless. Record: `docs/release/release-0.10.0.json`.
- [x] 3.3 Get the user's playtest of The Ossuary. Record only what is reported.
  - 2026-11-23: user reports "ossuary is good".
