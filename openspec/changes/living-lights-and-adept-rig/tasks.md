## 1. Baseline

- [ ] 1.1 Record the 0.5.1 gameplay fingerprints, the light count and shadow-caster count, and the frame time of a fixed camera path in the courtyard and crypt. Capture reference frames of a torch close-up and an Adept death.

## 2. Animated torch flames

- [ ] 2.1 Add the flame shader (deterministic `time`/`intensity` uniforms, additive, Y-billboard, noise teardrop) and `scripts/environment/flame_visual.gd` (crossed quads plus a small ember emitter).
- [ ] 2.2 Seat a flame on each torch head and drive it from `FortressPresentation.set_clock` with the same modulation as the light. Freeze on pause; reset on restart.
- [ ] 2.3 Test: six flames, intensity tracks the light energy, out of sync, frozen on pause, no duplicates after restart, torch light settings unchanged. Capture torch close-ups.

## 3. Procedural light fixtures

- [ ] 3.1 Add `scripts/environment/light_fixtures.gd` with brazier, lantern and arcane crystal lamp builders (primitives, flame shader, glow-pulse shader, no collision).
- [ ] 3.2 Place about 2 braziers, 3 lanterns and 3 crystal lamps across the courtyard, crypt approach and key chamber (at most 8 lights, no shadows) and drive them from `set_clock`.
- [ ] 3.3 Test: fixture counts per kind and area, the light budget and the total shadow casters, no physics bodies, pause freeze and restart reset, gameplay fingerprints and navigation unchanged. Capture area frames and compare frame time with the baseline.

## 4. Adept rig and animation (Meshy, ≤ 40 credits, no paid retries)

- [ ] 4.1 Write `tools/meshy_adept_rig.py` (route/body whitelist, ceiling check, checkpoint per stage, `--submit` gate, no secrets stored) and its offline unit tests.
- [ ] 4.2 Run the read-only preflight: balance and animation library. Choose and record the Idle, Walk, Cast, Hit and Dead action IDs.
- [ ] 4.3 Submit the rig (5 credits), then the animation request (15 credits). Download, verify and inventory the GLBs (skins, clip names, bones) into `assets/models/adept-animated/` with `provenance.json`. If any stage fails, stop, record the failure and keep the fallback.

## 5. Adept presentation integration

- [ ] 5.1 Add `scripts/enemies/adept_presentation.gd` and `scenes/models/adept_animated.tscn` (Warden interface; idle/walk blend, cast scaled to the windup, hit, death hold, clock driven by the physics step).
- [ ] 5.2 Wire the presentation in `enemy.gd` for any model exposing `advance_visual`, and switch the ranged scene to the animated Adept. Keep the static model and the 0.5.1 tween death as fallbacks.
- [ ] 5.3 Test: the death clip plays and holds, cast timing and projectile origin are unchanged, the `died` signal, collision removal, pause freeze, restart cleanup, fallback when the resource is missing, the Warden unchanged and the fingerprints unchanged. Capture Adept death frames.

## 6. Build and review

- [ ] 6.1 Run the full regression suite, bump the version to 0.5.2, export to `builds/windows-0.5.2/`, and run the packaged audit and native smoke test. Add the release record and update the asset and provenance docs.
- [ ] 6.2 Get the user's review of the torch flames, the new fixtures, the Adept death and animations, and performance. Record only what is reported.
