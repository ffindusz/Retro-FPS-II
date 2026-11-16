## Context

The 0.3 demo has 233 regression checks, original 512px stone color/roughness maps, six non-shadowed flickering torches, two ambience loops and eleven accepted SFX. The user completed a walkthrough, likes the overall presentation, but requests more realistic stone, dynamic light and a special key cue. They approved free bundled CC0 photographic textures and limited torch shadows plus spell/projectile lights.

The current machine runs Godot 4.7.2 Compatibility on AMD Radeon Graphics; historical GTX 1060 measurements are not this machine's performance baseline. A fresh checkout requires an editor import before direct game startup.

## Goals / Non-Goals

**Goals:** Match model detail with photographic stone and normal relief; make selected torch and spell illumination dynamic; distinguish objective collection from resource pickups; retain offline play, gameplay fingerprints and bounded presentation.

**Non-Goals:** Renderer migration, new collision or geometry, moved actors/objectives, altered stats, new models, paid generation, runtime downloads, music, new settings UI, or inferred human/offline acceptance.

## Decisions

### Bundled photographic stone with verified provenance

Use Poly Haven's CC0 Medieval Blocks 03 (Rob Tuytel, 2m tile) for walls/trim and Monastery Stone Floor (Amal Kumar, approximately 1.8m tile) for floors. Bundle six original 1K JPEG downloads: diffuse, OpenGL normal and roughness per asset. Verify official API checksums and record SHA-256, source URLs, authors and the official license URL. Only texture assets are redistributed, not website content. Keep original procedural assets and their historical evidence unchanged.

Shared StandardMaterial3D variants use world-aligned repeat/mipmaps, correct physical scale, red-channel roughness and restrained normal strength. Trim reuses wall resources rather than introducing another set. No displacement changes the silhouette or collision. Alternative: procedural refinement would not deliver the user-selected photographic source; 2K/4K maps add unnecessary memory.

### Two torch shadow sources and six shared spell lights

Retain all six torch transforms, ranges and slow energy modulation. Enable shadows on exactly two fixed existing lights (one courtyard, one crypt), with emitter meshes excluded from casting self-shadows. Retain the directional light and ambient visibility floor. No new static torch lights are added.

CombatFeedback owns a maximum of six spell light records, shared by short cast/impact flashes and projectile-attached lights. Lights have short finite ranges and no shadows; saturation drops new presentation, never attacks. Cast/impact flashes expire in at most 0.2 seconds; projectile lights follow the projectile and disappear when it resolves/expires. Pause freezes flash aging, terminal/menu cleanup removes all spell lights, and restarts own no old nodes. The developer atmosphere-off path adds no new shadows or spell lights. Alternative: an unbounded light per projectile/impact is unsafe under held fire and repeated runs; Forward+ is unnecessary.

### Confirmed key event through existing audio

Extend the successful pickup event path with pickup_key. Publish only after collect_key succeeds, using the pickup-specific event ID. The existing feedback deduplication and SFX service play a local original longer ascending magical chord, distinct from health/mana. No new bus or volume is needed; mute, pause, voice limits and teardown retain existing semantics. Append synthesis to the offline authoring tool and generate only the new cue, preserving all eleven accepted WAV hashes. Alternative: audio owned by the pickup would be cut off when collection frees it.

## Risks / Trade-offs

- [Normal maps look too strong or repeat conspicuously] -> Physical tile scales, restrained normal strength and matching close/wide rendered review.
- [Torch self-shadowing or depth bias hides light] -> Non-shadow-casting emitter meshes, limited shadow sources and courtyard/crypt review.
- [Shadow/light cost on integrated graphics] -> Two shadowed torches, six short-range shadowless spell lights and same-machine before/after measurements; reduce cost if needed.
- [Pickup cue repeats or plays on rejected collection] -> Successful key event, existing event-ID deduplication and focused paused/dead/already-owned/muted/restart tests.
- [Multiple active changes confuse acceptance] -> Explicit superseding constraints and separate new technical/human evidence; no automatic archive.

## Migration Plan

Capture 0.3 fixed views/performance, verify/download licensed maps, implement materials/lights/key cue, import and run regression/asset/render checks, compare performance and update delivery notes. Rebuild a Windows export only with matching installed templates; otherwise record the blocker. Rollback affects presentation/assets only, not gameplay data.

## Open Questions

Final photographic scale/normal appearance, shadow comfort, spell brightness and key chime character require human feedback on the new build.
