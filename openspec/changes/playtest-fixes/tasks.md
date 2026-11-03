## 1. Baseline

- [ ] 1.1 Run the full gameplay/model/audio test suite on 0.5.0. Record the gameplay fingerprints, all SFX hashes, and the measured RMS/peak of both ambience loops and the combat cues at default volumes.

## 2. Audible ambience

- [ ] 2.1 Raise `FortressAmbience.BUS_GAIN` (and only if needed the default slider value) to the measured target: clearly audible, at least 9 dB below combat-cue peaks, no clipping. Document the chosen values.
- [ ] 2.2 Add or extend tests for the default bus level, headroom, slider/mute mapping, pause freeze, doorway blend and no loop stacking across restarts.

## 3. Visible torch flicker

- [ ] 3.1 Replace the ±8% modulation in `FortressPresentation.set_clock` with the three-component sum clamped to ±25%, with no component above 8 Hz and per-torch phases.
- [ ] 3.2 Test the energy bounds, the nonzero floor, determinism, pause freeze, fresh-run reset and the unchanged torch count, range and shadow settings.

## 4. Adept death presentation

- [ ] 4.1 Add `scripts/enemies/adept_presentation.gd` (with a `dead` flag, `die()`, `advance_visual()`, `show_hit()`, and attack hooks as no-ops) and wire it for archetype 1 in `enemy.gd` without touching the placeholder fallback or the Warden.
- [ ] 4.2 Implement the stagger → ground-pivot fall → settle sequence (0.8–1.5 s) with a bounded arcane burst through the existing VFX limits. Hold the body afterwards, freeze on pause, and free everything on restart or menu.
- [ ] 4.3 Verify that death timing, collision removal, the `died` signal, cancelled casts, enemy counts and the gameplay fingerprints are unchanged. Capture before/after frames of an Adept death at 1280×720.

## 5. Grounded enemy cues

- [ ] 5.1 Rework the `enemy_melee`, `enemy_charge` and `enemy_cast` synthesis in `tools/generate_combat_audio.gd` as noise/formant/crackle designs with new declared seeds. Regenerate only those three cues.
- [ ] 5.2 Test format, level, endpoints, durations (within ±25%) and that the other nine SFX hashes are unchanged. Update `assets/audio/combat/README.md` provenance.

## 6. Build and review

- [ ] 6.1 Run the full regression suite, bump the version to 0.5.1, export to `builds/windows-0.5.1/`, and run the packaged-resource audit and native startup smoke. Keep the 0.5.0 artifacts.
- [ ] 6.2 Obtain the user's re-review of ambience audibility/mix, flicker comfort, the Adept death and the new enemy cues. Then record the remaining `fortress-atmosphere` 6.5 checks (loop seams, doorway blend) from the same session. Do not infer unreported outcomes.
