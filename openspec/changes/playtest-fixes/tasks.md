## 1. Baseline

- [x] 1.1 Run the full gameplay/model/audio test suite on 0.5.0. Record the gameplay fingerprints, all SFX hashes, and the measured RMS/peak of both ambience loops and the combat cues at default volumes.
  - 0.5.0 baseline: 269 checks with 1 failure ("pause freezes ambience blend and playback position", repeatable here on unchanged code and timing-sensitive under the headless dummy driver; it passes with a diagnostic print and in packaged runs), runtime Warden 42/0. Default output: wind -53.8 / crypt -45.5 dBFS RMS, combat cues about -24 dBFS peak and -38 dBFS RMS. 45% / 76% of loop energy below 150 Hz. Logs are in builds/validation/playtest-fixes/.

## 2. Audible ambience

- [x] 2.1 Re-author both loops for mid-band content (RMS-matched at about -24.7 dBFS) and raise `FortressAmbience.BUS_GAIN` from 0.15 to 0.3, with the default slider unchanged at 0.3: about -45 dBFS RMS / -34 dBFS peak at default, 9 dB under combat-cue peaks. Documented in assets/audio/ambience/README.md.
- [x] 2.2 Add or extend tests for the default bus level, headroom, slider/mute mapping, pause freeze, doorway blend and no loop stacking across restarts.

## 3. Visible torch flicker

- [x] 3.1 Replace the ±8% modulation in `FortressPresentation.set_clock` with the three-component sum clamped to ±25%, with no component above 8 Hz and per-torch phases.
- [x] 3.2 Test the energy bounds, the nonzero floor, determinism, pause freeze, fresh-run reset and the unchanged torch count, range and shadow settings.

## 4. Adept death presentation

- [x] 4.1 Add a model-Adept-only death path (`_play_adept_death()` in `enemy.gd`) without touching the placeholder fallback, the Warden or the Adept's living hit and windup visuals. A presentation node was dropped: see design Decision 3.
- [x] 4.2 Implement the stagger → ground-pivot fall → settle sequence (0.90 s) with one bounded, self-freeing arcane burst. Hold the body afterwards, freeze on pause, and free everything on restart or menu.
- [x] 4.3 Verify that death timing, collision removal, the `died` signal, cancelled casts, enemy counts and the gameplay fingerprints are unchanged. Capture frames of an Adept death at 1280×720.
  - 5 new Adept checks pass. Side-view frames (alive/stagger/fall/landing/settled) via tools/capture_adept_death.gd in builds/validation/playtest-fixes/.

## 5. Grounded enemy cues

- [x] 5.1 Rework the `enemy_melee`, `enemy_charge` and `enemy_cast` synthesis in `tools/generate_combat_audio.gd` as noise/formant/crackle designs, keeping their declared seeds. Regenerate only those three cues.
- [x] 5.2 Test format, level, endpoints, durations (within ±25%) and that the other nine SFX hashes are unchanged. Update `assets/audio/combat/README.md` provenance.

## 6. Build and review

- [x] 6.1 Run the full regression suite, bump the version to 0.5.1, export to `builds/windows-0.5.1/`, and run the packaged-resource audit and native startup smoke. Keep the 0.5.0 artifacts.
  - Source: 276 checks with the same single pre-existing ambience-pause failure; runtime Warden 42/0; Python suites pass except the two frozen 0.4.1 hash checks, which fail on unchanged code because builds/windows/ holds an older local 4.7.0 export. Packaged (external --main-pack): audit 204 resources / 0 failures, 276/0, 42/0. Native smoke exit 0. Exported with Godot 4.7.0 (0.5.0 used 4.7.2). Record: docs/release/release-0.5.1.json.
- [ ] 6.2 Obtain the user's re-review of ambience audibility/mix, flicker comfort, the Adept death and the new enemy cues. Then record the remaining `fortress-atmosphere` 6.5 checks (loop seams, doorway blend) from the same session. Do not infer unreported outcomes.
