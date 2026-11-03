## 1. Baseline

- [x] 1.1 Record the 0.5.1 gameplay fingerprints, the light count and shadow-caster count, and the frame time of a fixed camera path in the courtyard and crypt. Capture reference frames of a torch close-up and an Adept death.
  - Baseline after the 0.6.0 sync: run_tests 276/0, authored 30/0, Warden suites 42 + 148 / 0. Gameplay fingerprints are the existing `resources/atmosphere_baseline.tres` snapshot. 6 torch lights, 2 shadow casters. The Adept-death reference is builds/validation/playtest-fixes/adept-death-*.png. Frame-time A/B (same process, 1280x720, vsync off, two fixed views) is in builds/validation/living-lights/profile-ab.log: 7.4-9.5 ms with the new lights vs 8.1-8.2 ms without, within run-to-run noise; +60-85 draw calls.

## 2. Animated torch flames

- [x] 2.1 Add the flame shader (deterministic `time`/`intensity` uniforms, additive, Y-billboard, noise teardrop) and `scripts/environment/flame_visual.gd` (crossed quads plus a small ember emitter).
- [x] 2.2 Seat a flame on each torch head and drive it from `FortressPresentation.set_clock` with the same modulation as the light. Freeze on pause; reset on restart.
- [x] 2.3 Test: six flames, intensity tracks the light energy, out of sync, frozen on pause, no duplicates after restart, torch light settings unchanged. Capture torch close-ups.
  - Embers are drawn in the flame shader rather than with GPUParticles, so they stay deterministic and pause-safe. The flame is seated on the measured torch head (-0.11 m), over the model's static flame. Frames: builds/validation/living-lights/torch-{a,b}.png via tools/capture_lights.gd.

## 3. Procedural light fixtures

- [x] 3.1 Add `scripts/environment/light_fixtures.gd` with brazier, lantern and arcane crystal lamp builders (primitives, flame shader, glow-pulse shader, no collision).
- [x] 3.2 Place about 2 braziers, 3 lanterns and 3 crystal lamps across the courtyard, crypt approach and key chamber (at most 8 lights, no shadows) and drive them from `set_clock`.
  - Also available in the level editor as Brazier / Wall Lantern / Crystal Lamp placements: kinds appended to `LevelPlacement.Kind`, editor preview, authored runtime spawn, builder skips floor/nav checks for decor. `AuthoredPresentation` no longer treats fixture lights as torches. Documented in docs/level-authoring.md.
- [x] 3.3 Test: fixture counts per kind and area, the light budget and the total shadow casters, no physics bodies, pause freeze and restart reset, gameplay fingerprints and navigation unchanged. Capture area frames and compare frame time with the baseline.
  - `test_living_lights` adds 11 checks (run_tests 287/0). Area frames are in builds/validation/living-lights/.

## 4. Adept rig and animation (Meshy, ≤ 40 credits, no paid retries)

- [x] 4.1 Write `tools/meshy_adept_rig.py` (route/body whitelist, ceiling check, checkpoint per stage, `--submit` gate, no secrets stored) and its offline unit tests.
  - 7 offline tests in tests/test_meshy_adept_rig.py, including the single upload fallback after a pre-creation rejection.
- [x] 4.2 Run the read-only preflight: balance and animation library. Choose and record the Idle, Walk, Cast, Hit and Dead action IDs.
  - Balance 1113. Library of 678 entries searched. Chosen (docs/adept-rig-plan.json): 0 Idle, 30 Casual_Walk, 125 Charged_Spell_Cast, 178 Hit_Reaction, 188 Fall_Dead_from_Abdominal_Injury.
- [x] 4.3 Submit the rig (5 credits), then the animation request (15 credits). Download, verify and inventory the GLBs (skins, clip names, bones) into `assets/models/adept-animated/` with `provenance.json`. If any stage fails, stop, record the failure and keep the fallback.
  - The refine-task rig request got HTTP 400 before any task was created (balance unchanged at 1113). The single authorized fallback uploaded the checksum-verified GLB. Rig 5 + animate 15 = **20 / 40 credits**; balance now 1093. animate.glb: 7,382 triangles, 24 joints, 5 clips, 2.0 m, textures imported at 1K. The rig-only GLB is kept outside the repo in the stage folder.

## 5. Adept presentation integration

- [x] 5.1 Add `scripts/enemies/adept_presentation.gd` and `scenes/models/adept_animated.tscn` (Warden interface; idle/walk blend, cast scaled to the windup, hit, death hold, clock driven by the physics step).
- [x] 5.2 Wire the presentation in `enemy.gd` for any model exposing `advance_visual`, and switch the ranged scene to the animated Adept. Keep the static model and the 0.5.1 tween death as fallbacks.
- [x] 5.3 Test: the death clip plays and holds, cast timing and projectile origin are unchanged, the `died` signal, collision removal, pause freeze, restart cleanup, fallback when the resource is missing, the Warden unchanged and the fingerprints unchanged. Capture Adept death frames.
  - Cast release at native 1.85 s (forward hand thrust, measured), mapped onto the existing 0.8 s windup; the bolt still comes from `resolve_attack`. Death: head 1.6 m -> under 0.6 m over 3.5 s, then held. The static `adept.tscn` fallback still plays the 0.5.1 tween and burst. Frames: builds/validation/living-lights/adept/. The staff is fused into the skinned mesh and bends slightly during the fall.

## 7. Meshy fixture models (0.6.1 review follow-up; ≤ 50 credits, one candidate each, no paid retries)

- [x] 7.1 Generate brazier, wall lantern and crystal lamp with the existing `tools/meshy_generate.py` (new `--plan docs/meshy-fixtures.json`, whole-plan ceiling check).
  - Previews were reviewed before the refine stage. Reported cost: 3 × (5 + 10) = **45 / 50 credits**; balance 1093 -> 1048. Models are in `assets/models/prop-{brazier,lantern,crystal-lamp}/` with `provenance.json` (task IDs, prompts, downloads; no credentials or signed URLs). Textures imported at 1K, lossless.
- [x] 7.2 Seat the procedural flame/glow and lights on measured model anchors (brazier rim at 0.74 m; lantern rotated so its wall plate sits on the wall and the body hangs 0.71 m out along -Z; crystal lamp scaled to 1.5 m with a calm cyan wisp). Keep the 0.6.1 primitive build as a fallback (`use_model = false` or a missing model).
- [x] 7.3 Tests: every fixture uses its model, flame/glow present, textures within 1K, no collision, fallback works; pause/restart/fingerprint checks unchanged (run_tests 294/0). Frames in builds/validation/living-lights/.
- [ ] 7.4 Get the user's review of the 0.6.2 Meshy fixtures. Record only what is reported.

## 6. Build and review

- [x] 6.1 Run the full regression suite, bump the version to 0.6.1, export to `builds/windows-0.6.1/`, and run the packaged audit and native smoke test. Add the release record and update the asset and provenance docs.
  - Source: run_tests 292/0 (3 consecutive runs), Warden 42/0, authored 30/0, Warden prototype suites 148/0, rendered editor 27/0. Python 96 run, 3 fail, all the known stale builds/windows/ 0.4.1 hash checks. Packaged (external --main-pack): 292/0, 42/0, 30/0. Audit 234 resources / 0 failures. Native startup exit 0. Exported with Godot 4.7.0. Record: docs/release/release-0.6.1.json.
  - Also stabilized the pre-existing flaky ambience-pause check: Godot mixes one final buffer (0.0116 s) after `stream_paused`. The check now allows that single buffer and then requires a frozen playhead.
- [x] 6.2 Get the user's review of the torch flames, the new fixtures, the Adept death and animations, and performance. Record only what is reported.
  - 2026-11-03 user review of 0.6.1: "played it - animation much better, new lights (should be replaced by something made with meshy)".
  - Adept animation: accepted as much better. New fixtures: the procedural brazier/lantern/crystal-lamp models are not accepted visually; the user wants Meshy-generated models instead (follow-up change). The animated torch flames and performance were not separately reported, so they are not recorded.
