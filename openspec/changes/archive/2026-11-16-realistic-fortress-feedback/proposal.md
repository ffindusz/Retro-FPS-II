## Why

The user completed a walkthrough and likes the atmosphere, but the simple stone textures do not match the more realistic enemies and weapons. They requested dynamic lighting and a special key-pickup sound, and approved bundled free CC0 photographic PBR textures plus limited torch shadows and spell/projectile lights.

## What Changes

- Replace the default fortress stone appearance with locally bundled photographic color, roughness and OpenGL normal maps, capped at 1024px, with verified CC0 provenance and no runtime downloads.
- Enable a small fixed budget of shadow-casting existing torches and bounded short-lived spell/projectile lights under the existing Compatibility renderer.
- Add an original, distinct magical key-pickup chime after successful collection, respecting the existing SFX volume, deduplication and session lifecycle.
- Preserve collision, navigation, encounters, objective positions, player/weapon tuning, imported models, accepted sounds and independent ambience controls.
- Record new visual/audio feedback and technical evidence without claiming detailed or offline acceptance that the user has not reported.

## Capabilities

### New Capabilities

- `photographic-fortress-materials`: Bundled CC0 photographic stone maps, consistent world scale, shared materials and offline provenance.
- `bounded-dynamic-lighting`: Limited torch shadows and run-owned bounded spell/projectile illumination without gameplay effects.
- `key-pickup-audio`: A unique original one-shot cue for confirmed key collection with existing audio lifecycle behavior.

### Modified Capabilities

None in the canonical registry, which remains empty. This follow-up explicitly supersedes the active fortress-atmosphere change's original default six-512px surface mapping and no-additional-shadow-light restriction; its original assets, provenance and historical evidence remain intact. Earlier unreported acceptance work is not completed or archived.

## Impact

Touches environment materials/presentation, projectile and combat-feedback presentation, key pickup events, offline sound authoring, tests, documentation and the Windows delivery workflow. Adds two CC0 texture sets and one original WAV, with no paid generation, runtime network dependency, renderer migration, new geometry, gameplay rebalance or new models.
