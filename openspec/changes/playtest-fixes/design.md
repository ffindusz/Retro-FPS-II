## Context

The 0.5.0 playtest (recorded in the active `fortress-atmosphere`, `combat-polish` and `realistic-fortress-feedback` task notes) traced four problems to specific code:

- **Ambience:** `FortressAmbience` sets the bus to `linear_to_db(volume * BUS_GAIN)`, which is 0.3 × 0.15 ≈ −27 dB at default. The loops were also authored "quiet", so the combined level is effectively silent.
- **Torches:** `FortressPresentation.set_clock` uses `0.05·sin(1.1 Hz) + 0.03·sin(0.37 Hz)`, at most ±8% and slow, which is below what people notice.
- **Adept death:** the Adept is an unrigged static GLB (`scenes/models/adept.tscn`). It has no `advance_visual` presentation, so `enemy.gd` falls back to a 0.3 s tween that rotates `visual` 90° on Z and squashes it. In play this reads as no animation.
- **Enemy cues:** `tools/generate_combat_audio.gd` builds `enemy_melee` from a low rumble/noise pulse, `enemy_charge` from rising low harmonics and `enemy_cast` from a short falling chirp. The pitched sweeps are what sound cartoonish.

## Goals / Non-Goals

**Goals:**
- Fix the four reported problems with minimal, presentation-only edits.
- Keep the gameplay fingerprints, all other SFX bytes, the controls and the lifecycle behaviour.
- Produce a 0.5.1 build for re-review.

**Non-Goals:**
- Music, new ambient layers, level or encounter changes (the guarded key barrier).
- A rigged or animated Adept model, or Meshy work.
- Re-tuning the overall mix. The user confirmed it is good.

## Decisions

1. **Ambience: raise BUS_GAIN and measure, rather than re-author the loops.**
   Raise `BUS_GAIN` (target around 0.6–0.8) and keep the 0.3 default slider, so the slider range and the saved session values still mean the same thing. Measure the RMS of each loop and of the combat cues offline, and pick the gain that gives roughly −18 to −22 dB RMS at default with at least 9 dB under the combat-cue peaks.
   *Alternative:* re-normalize the loop WAVs. That is rejected unless the gain alone can't reach the target, because it changes accepted assets.

2. **Torch flicker: a three-component sum clamped to ±25%.**
   Use a slow sway (~0.4 Hz, ±10%), a medium flutter (~2–3 Hz, ±7%) and a small fast jitter made from incommensurate sines (≤ 7 Hz, ±4%). It stays deterministic from `elapsed` with per-torch phases. Range, shadows and colour are left unchanged.
   *Alternative:* a random noise texture lookup. It is rejected because it complicates determinism and tests for no visual gain.

3. **Adept death: a procedural presentation node instead of a rig.**
   Add a small `adept_presentation.gd` that `enemy.gd` uses for archetype 1. It exposes `die()`, `advance_visual()`, `show_hit()` and `dead`, the same interface the Warden presentation uses, so the existing `presentation` branch drives it. It gets its own pause-aware clock. The sequence is:
   - 0.15 s stagger (a backward lean and a slight crouch)
   - about 0.6 s fall, eased in, rotating around a ground-contact pivot so the model doesn't sink
   - a short settle bounce
   - one bounded arcane burst: a few short-lived particles or an emissive pulse on the shared VFX path, within the existing 24-effect cap
   The body is then held.
   *Alternative:* a Meshy rig with a death clip. That is rejected as far too large for this fix.

   Wiring the Adept into `presentation` must not change its attack logic. `enemy.gd` calls `begin_attack` and `attack_contact` only on the melee path, so the Adept implementation keeps those as no-ops and is checked by the existing gameplay fingerprint tests.

4. **Enemy cues: noise-first synthesis with formant filters.**
   Regenerate only the three cues through the existing generator's cue-selection argument, with new declared seeds:
   - `enemy_melee`: a low breathy grunt (band-passed noise with two formants around 300 and 800 Hz) plus a leather/metal scrape
   - `enemy_charge`: a crackling arcane build (sparse impulse crackle over hiss that rises in density, not in pitch)
   - `enemy_cast`: a noise burst plus a short low thump (a "fwoosh")

   Durations stay within ±25%.

## Risks / Trade-offs

- [Loud ambience could mask enemy cues spatially] → Enforce the 9 dB headroom with a measured test, and ask about it in the re-review.
- [Visible flicker could cause discomfort] → No strobing, ≤ 7 Hz components and a ±25% clamp. Ask about comfort in the re-review.
- [Adept presentation path changes how `enemy.gd` branches] → Keep the interface identical to the Warden's, make the attack hooks no-ops, and run the full regression and fingerprint suite.
- ["Realistic" is subjective] → Make a quick A/B listen of the three cues part of the review task. Keep the generator parameterized for a fast second pass.

## Migration Plan

Bump the version to 0.5.1 and export to `builds/windows-0.5.1/`, leaving `builds/windows-0.5.0/` untouched. Rolling back means reverting the commit and regenerating the three cues from the old seeds.

## Open Questions

- Whether a gain change is enough for the ambience, or the loops need light re-authoring. The measurement in task 1.1 decides this.
