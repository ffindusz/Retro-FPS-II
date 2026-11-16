## 1. Level

- [x] 1.1 Add the alcove walls and move the key sign above the gateway.
- [x] 1.2 Add the ward (`scripts/props/key_ward.gd`): collision, visuals, guard tracking, opening tween, messages, hint. Visual check: `tools/capture_key_ward.gd` renders closed and open views to `builds/validation/key-ward/`.
- [x] 1.3 Station the three guards and register them with the ward; keep all enemy stats unchanged.

## 2. Data

- [x] 2.1 Re-bake `resources/demo_navigation.tres`.
- [x] 2.2 Add `tools/record_world_baseline.gd` and re-record `resources/atmosphere_baseline.tres`.

## 3. Verification and handoff

- [x] 3.1 Add ward tests (blocks while guards live, opens once after the last guard, collision off, message, hint, pause, restart) and update enemy counts.
- [x] 3.2 Run `tools/verify.ps1` and record the results.
  - 2026-11-16, Godot 4.7.2: all suites pass with 0 failures: 310 main, 42 runtime-Warden, 30 authored-level, 24 editor-polish, 19 level-selection, 32 motion-study, 39 rig-preview, 33 A/B, 13 candidate and 31 pilot checks. Python tests were not run (no Python on this machine). No Windows export or packaged audit was made.
- [x] 3.3 Bump the version to 0.8.0 and update README.
  - 2026-11-16: Windows build `builds/windows-0.8.0/` exported through `tools/export_checked.ps1`. External package audit: 266 resources, 0 failures; the EXE starts and quits cleanly headless. Record: `docs/release/release-0.8.0.json`.
- [ ] 3.4 Get the user's playtest of the guarded key. Record only what is reported.
