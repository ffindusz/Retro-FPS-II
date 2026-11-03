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

1. **Ambience: re-author the loops for audible bands, then raise BUS_GAIN moderately.**
   Measurement (task 1.1) showed loudness was not the only problem. The 0.5.0 loops put 45% (wind) and 76% (crypt) of their energy below 150 Hz, which small speakers and headphones barely reproduce at low levels. Combat cues play at about −24 dBFS peak and −38 dBFS RMS at default, after the −8 dB voice and −9.8 dB SFX bus gains.
   - Re-author both loops with mid-band content: wind body at 350 Hz, hiss and gust whistle; crypt with 110/165 Hz harmonics, an air bed and sparse drips. RMS-match them at about −24.7 dBFS with a tanh soft limit under the existing 0.25 peak ceiling, so no per-loop trims are needed.
   - Raise `BUS_GAIN` from 0.15 to 0.3 and keep the 0.3 default slider. Ambience then sits at about −45 dBFS RMS and −34 dBFS peak, 9 dB under the combat-cue peaks.
   *Alternative:* gain only. That is rejected: it would mostly have amplified inaudible rumble, and reaching audibility would have broken the headroom.

2. **Torch flicker: a three-component sum clamped to ±25%.**
   Use a slow sway (~0.4 Hz, ±10%), a medium flutter (~2–3 Hz, ±7%) and a small fast jitter made from incommensurate sines (≤ 7 Hz, ±4%). It stays deterministic from `elapsed` with per-torch phases. Range, shadows and colour are left unchanged.
   *Alternative:* a random noise texture lookup. It is rejected because it complicates determinism and tests for no visual gain.

3. **Adept death: a node-owned tween sequence in `enemy.gd`, not a presentation node or a rig.**
   Setting `presentation` for the Adept would also switch off its existing hit pulse and windup lean, which only run while `presentation` is null. Instead, model-based Adepts (`archetype == 1`, not placeholder) replace the 0.3 s fallback tween with `_play_adept_death()`. The sequence runs 0.90 s:
   - 0.15 s stagger: a backward lean and a slight crouch
   - 0.55 s eased-in backward fall about the feet, with a 0.3 m lift so the lying robe rests on the floor
   - a 0.20 s settle
   One additive, unshaded arcane burst sphere spawns at the start of the fall and frees itself after 0.45 s. It is one per death, a child of the enemy, and outside the combat VFX pool. Tweens pause with the tree and are freed with the enemy. The body is then held.
   *Alternative:* a Meshy rig with a death clip. That is rejected as far too large for this fix.

4. **Enemy cues: noise-first synthesis with formant filters.**
   Regenerate only the three cues through the existing generator's cue-selection argument, keeping their original declared seeds so that no other cue's seed changes:
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

- Resolved: gain alone was not enough. The loops were re-authored (Decision 1).
- The 0.5.1 build was exported with the Godot 4.7.0 editor available on this machine; 0.5.0 used 4.7.2.
