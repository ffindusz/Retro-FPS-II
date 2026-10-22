## Context

The 0.4 project uses Compatibility rendering, photographic stone, six torches (two shadowed), bounded spell lights and explicit color-based ambient lighting. The user approves the textures and asks for a skybox. The world currently uses a flat background, while the isolated weapon viewport has its own environment.

## Goals / Non-Goals

**Goals:** A readable moonlit background visible above the fortress, bundled offline, with unchanged gameplay and current light values.

**Non-Goals:** Animated weather/clouds, a day/night cycle, HDRI-driven lighting, new lights, renderer changes, fog, geometry, audio changes or external downloads.

## Decisions

### Original static panorama

Author one original 1024x512 RGB PNG offline using spherical seeded noise for clouds, sparse seeded stars and an analytic moon aligned to the existing directional light. Close the longitude seam explicitly and avoid poles with star stamps. Bundle its generation parameters and SHA-256; no generation runs during gameplay. Original art avoids the external-download approval requirement without changing the requested skybox outcome.

Alternative: a downloaded panorama requires approval; a runtime cloud shader adds unnecessary shader work and animation state.

### Background-only integration

Within FortressPresentation, attach a PanoramaSkyMaterial and per-run Sky to the existing WorldEnvironment, set BG_SKY and retain explicit ambient-color lighting. Disable sky-derived reflections so the panorama does not become a new lighting source. Use the smallest radiance cache and a static quality update; leave ambient values, moon/torches, weapon viewport and gameplay untouched. The atmosphere-disabled path never attaches the sky and retains its previous flat background.

Alternative: a huge mesh dome adds geometry/layer/clipping concerns unnecessarily; sharing a mutable Environment globally would complicate restarts.

### Focused evidence and feedback

Cover local panorama loading, dimensions/seam, lighting-source isolation, fallback and run replacement. Capture courtyard and moon-facing views at 720p and 1080p, checking the moon renders in the existing directional-light direction. Preserve 0.4 performance/package evidence as historical and record the still-missing matching export templates. Record only the user's texture approval, not implied shadow/key-audio acceptance.

## Risks / Trade-offs

- [Visible seam or pole stretching] -> Spherical noise, wrapped stamps, closed edge columns and panoramic render review.
- [Sky too bright/dark or moon points away from existing illumination] -> Conservative night palette, explicit light isolation and moon-facing captures.
- [New sky affects model lighting] -> Retain color ambient, disable sky reflections and assert unchanged light values.
- [Static source art looks synthetic] -> Restrained cloud/star detail; final artistic judgment remains a human check.

## Migration Plan

Generate the bundled PNG/provenance, import it, integrate the existing presentation branch, run focused/full regression and rendered checks, then update the patch version and documentation. Rollback removes only sky presentation/assets; no gameplay data migrates.
