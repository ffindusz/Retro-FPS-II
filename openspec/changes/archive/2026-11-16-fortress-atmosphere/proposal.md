## Why

The user reports that the demo works, melee is better, difficulty is okay, and combat/pickup sounds work; the environment is now the largest presentation gap, with mostly flat-colored blockout surfaces. Make the existing five-minute-scale fortress feel intentional and atmospheric before adding levels or changing accepted gameplay.

## What Changes

- Replace flat environment surfaces with original, tileable stone wall, flagstone floor, and worn trim materials, with consistent world scale and restrained variation.
- Refine warm torch/cool moonlight contrast and add subtle, bounded torch flicker without making enemies, pickups, the key, or the exit hard to see.
- Dress existing entrances, pillars, and the sealed gate with nonblocking frames/trim, small clusters of the existing urn model, and clearer visual landmarks.
- Add two original bundled ambience loops: subdued fortress wind and a crypt bed, with a smooth transition at the existing crypt entrance.
- Add a separate pause-menu ambience volume/mute control while preserving the accepted SFX mix, cues, and session volume behavior.
- Keep the current layout, solid collision, navigation, encounters, resource/objective positions, combat stats, and six Meshy models unchanged. Use no additional Meshy generation, paid service, or external asset download.
- Extend regression/render/audio validation and rebuild the Windows demo; record subjective visual/ambience approval and remaining manual checks rather than inferring them from existing feedback.

## Capabilities

### New Capabilities

- `fortress-materials`: Original bundled tileable environment textures, consistent mapping/scale, surface differentiation, and bounded material resources.
- `fortress-lighting`: Readable warm/cool environment lighting, subtle deterministic torch modulation, and safe pause/reset behavior.
- `fortress-dressing`: Reused props, nonblocking architectural accents, and route/objective landmarks that preserve gameplay geometry.
- `fortress-ambience`: Two bounded local audio loops, crypt transitions, independent volume/mute, and run/session lifecycle behavior.

### Modified Capabilities

None in the canonical registry: `openspec/specs/` is empty because `fantasy-fps-demo` and `combat-polish` are still active. These additive presentation capabilities depend on their implemented behavior and do not silently complete or archive either change's outstanding acceptance work.

## Impact

- Builds on combat-polish 0.2.1: 196 source/packaged checks and eight authoring tests, with positive user feedback on sounds, melee, and difficulty.
- Main touchpoints: `scripts/level.gd`, torch/prop scenes and scripts, new environment material/presentation resources, `scripts/session.gd`, `scripts/ui/interface.gd`, and new run-owned ambience code.
- Adds original offline authoring outputs under `assets/environment/` and `assets/audio/ambience/`, a small Ambience bus/control, provenance records, and presentation regression/render checks.
- Retains Godot 4.7 Compatibility rendering, GDScript gameplay, offline playback, and existing model import/texture limits. Does not require a renderer upgrade, plugins, credentials, new source models, or runtime generation.
- Excludes new rooms/roofs, altered collision/cover, secrets or puzzles, encounter/balance changes, skeletal animation, music, volumetric effects, post-processing overhaul, and a general settings screen.
