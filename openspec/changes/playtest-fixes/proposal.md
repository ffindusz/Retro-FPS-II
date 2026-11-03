## Why

The 2026-11-03 playtest of the 0.5.0 build found four presentation problems. The background ambience could not be heard. The torches did not visibly flicker. The Adept (ranged wizard) has no real death animation. The enemy attack sounds read as cartoonish ("like Mario"). Each one undercuts the fortress atmosphere the earlier changes aimed for. The playtest confirmed that the mix balance, mute, stone, readability, sky and core loop are fine, so this change touches only those four problems.

## What Changes

- Raise the default ambience level so the wind/crypt loops are clearly audible, while combat and pickup cues still sit on top. The volume slider, mute and pause behaviour stay unchanged.
- Increase the torch light modulation from the current imperceptible ±8% to a visible but comfortable flicker. There are still no on/off strobes, range changes or new lights, and the flicker still freezes on pause.
- Give the Adept a readable death sequence in place of the 0.3 s tip-and-squash tween. The sequence is a staggered collapse to the ground with a short magical dissipation, and the body is held afterwards. Gameplay death timing does not change.
- Replace the three enemy cues (`enemy_melee`, `enemy_charge`, `enemy_cast`) with grittier original procedural sounds. All other accepted SFX stay byte-identical.
- Ship the result as a separate 0.5.1 Windows build, and keep the 0.5.0 artifacts.

Out of scope: music, extra ambient layers, a guarded key barrier or other level/encounter changes, and a rigged Adept model.

## Capabilities

### New Capabilities
- `audible-fortress-ambience`: default ambience level, headroom against combat cues, preserved slider/mute/pause behaviour.
- `visible-torch-flicker`: perceptible yet comfortable torch light modulation, bounds, pause and reset.
- `adept-death-presentation`: readable, gameplay-neutral death sequence for the unrigged Adept model.
- `grounded-enemy-cues`: realistic-sounding original enemy windup/cast cues and the preservation of other SFX.

### Modified Capabilities
<!-- None: openspec/specs/ only holds runtime-animated-warden and moonlit-fortress-sky, which are unaffected. -->

## Impact

- `scripts/environment/fortress_ambience.gd` (gain), possibly `scripts/session.gd` (default slider value), and the ambience loop WAVs only if their level has to be re-authored.
- `scripts/environment/fortress_presentation.gd` (torch modulation).
- `scripts/enemies/enemy.gd` (Adept death path) or a new small Adept presentation script.
- `tools/generate_combat_audio.gd`, `assets/audio/combat/enemy_{melee,charge,cast}.wav` and the audio README provenance.
- Tests in `tests/run_tests.gd` and `tests/test_atmosphere_assets.py`, plus the version bump and export to `builds/windows-0.5.1/`.
- This supersedes the ±8% flicker bound and the "conservative default gain" wording in the still-active `fortress-atmosphere` change, whose review tasks stay open until re-reviewed.
