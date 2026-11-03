## Why

The 2026-11-03 re-review of 0.5.1 accepted the new ambience but still flagged two problems:

- **Torches still look static.** Their flame is part of the unanimated `prop-torch` mesh, and light-energy flicker alone isn't perceived.
- **The wizards still have no death.** The unrigged Adept model can only tip over as a rigid block, and that doesn't read as an animation.

The user also asked for more kinds of light in the fortress (fires, lamps, magic lamps) to make it feel lived in.

## What Changes

- **Animated torch flames.** Each wall torch gets a procedural, camera-facing flame (an animated shader plus small ember particles) seated on the existing torch head. Flame size and brightness follow the same deterministic flicker signal that drives the torch's OmniLight. The static mesh flame is hidden or covered.
- **New light sources, all procedural in Godot from primitives plus animated flame or glow shaders:**
  - floor braziers with open fire
  - hanging iron lanterns
  - arcane crystal lamps with a slow cyan pulse

  They are placed off navigation paths, add no new physics blockers to walkable routes, and stay within a fixed light and shadow budget.
- **Rigged, animated Adept.** Using the Warden's Meshy pipeline, the existing Adept model goes through Meshy auto-rigging and library animations (Idle, Walk, a cast/attack, Hit and Dead).
  - Spending is user-authorized, capped at **40 credits** with **no paid retries**, and provenance is recorded.
  - The result is integrated as an Adept presentation with the same interface as the Warden's.
  - The 0.5.1 rigid-tween death and the placeholder fallback remain only as fallbacks.
- **Version 0.5.2** export for re-review.

Unchanged: ambience and mix (both accepted), gameplay values and timing, the Warden. Out of scope: music and the guarded key barrier.

## Capabilities

### New Capabilities
- `animated-torch-flames`: visible, deterministic, pause-safe animated flames on every wall torch, synced with the torch light flicker.
- `fortress-light-sources`: procedural braziers, hanging lanterns and arcane crystal lamps, with placement, navigation safety, a light/shadow budget and pause behaviour.
- `runtime-animated-adept`: a Meshy-rigged and animated Adept with a real death animation, gameplay-authoritative timing, a bounded and recorded credit spend, and fallbacks.

### Modified Capabilities
<!-- None: runtime-animated-warden and moonlit-fortress-sky requirements are unchanged. -->

## Impact

- **Code:**
  - `scripts/environment/fortress_presentation.gd`: flame drive and new light dressing
  - new `scripts/environment/flame_visual.gd` and `scripts/environment/light_fixtures.gd`
  - a flame shader
  - `scripts/enemies/enemy.gd`: use the presentation for archetype 1 when present
  - new `scripts/enemies/adept_presentation.gd`
- **Assets:**
  - new `assets/models/adept-animated/` containing the rigged/animated GLB and `provenance.json`
  - new `scenes/models/adept_animated.tscn`
- **Tooling:** a new bounded `tools/meshy_adept_rig.py` that follows the existing Meshy safety pattern: checked routes, a credit ceiling, no retries, and no secrets checkpointed.
- **External:** a paid Meshy API call, capped at 40 credits, using the existing local API key.
- **Tests:** `tests/run_tests.gd` gets flame, fixture and Adept-presentation checks, and the gameplay fingerprints must stay unchanged. Plus the packaged audit and a version bump to 0.5.2.
