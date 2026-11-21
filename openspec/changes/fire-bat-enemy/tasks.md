## 1. Gameplay

- [x] 1.1 Add `bat_enemy.gd`/`bat_enemy.tscn`: flight, distance keeping, fireball attack, death fall, placeholder visual.
- [x] 1.2 Add `Kind.BAT` placement: preview, builder hover clearance, authored-level spawning.
- [x] 1.3 Add a bat to the Mapping Example and rebuild it.

## 2. Model

- [x] 2.1 Check the Meshy balance; generate one textured bat within the 100-credit budget; record provenance.
  - 2026-11-20: balance 1,580. One preview (20 credits) and one texture pass (10 credits), no retries; balance 1,550. Record: `assets/models/bat-animated/provenance.json`; staging with task records (signed URLs removed) in `%LOCALAPPDATA%/Temp/cinderkeep-meshy-bat-2026-11-20/`.
- [x] 2.2 Rig and animate in Blender (fly, attack, hit, death); export the GLB.
  - The Blender connector could not reach Blender, so `tools/blender/rig_bat.py` runs Blender 5.3 headless instead. Renders of each clip were checked.
- [x] 2.3 Integrate the model with a presentation script; keep the placeholder fallback.
  - `scenes/models/bat_animated.tscn` + `scripts/enemies/bat_presentation.gd`; scaled to about 1.7 m wingspan after the first in-game render looked small.

## 3. Verification and handoff

- [x] 3.1 Add bat tests and run `tools/verify.ps1`.
  - 2026-11-19 (placeholder model): `tests/test_bat_enemy.gd` added, 19 checks. Full `tools/verify.ps1` passes with 0 failures.
  - 2026-11-21 (Meshy model): 24 bat checks (adds clips, looping, rigged wing motion, attack/hit/death clips, placeholder fallback). Full `tools/verify.ps1` passes with 0 failures. Python tests not run (no Python on this machine).
- [x] 3.2 Render the bat in the Mapping Example; bump to 0.9.0; update README.
  - `tools/capture_bat.gd` renders hover, windup, fireball and death to `builds/validation/fire-bat/`.
  - 2026-11-21: Windows build `builds/windows-0.9.0/Cinderkeep.exe` from 2c4978f via `tools/export_checked.ps1`; external package audit 283 resources, 0 failures; EXE starts headless. Record: `docs/release/release-0.9.0.json`.
- [ ] 3.3 Get the user's playtest of the bat. Record only what is reported.
