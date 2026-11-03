## Why

The user approves the photographic textures and requests a skybox. The open fortress currently ends in a flat dark background, so a restrained moonlit sky will complete the setting without another gameplay or lighting pass.

## What Changes

- Add an original static panoramic night sky with a moon, sparse stars and cloud bands, bundled for offline play.
- Use the existing Compatibility renderer's sky background while retaining ambient, directional, torch and weapon lighting values; do not introduce sky-derived ambient lighting or reflections.
- Keep geometry, navigation, encounters, combat, textures and audio unchanged, with the existing flat-background developer fallback intact.
- Record texture approval separately from unreported lighting/key-audio acceptance, and add focused resource/render/lifecycle checks.

## Capabilities

### New Capabilities

- `moonlit-fortress-sky`: An original bundled night-sky panorama, background-only integration, static lifecycle and developer fallback.

### Modified Capabilities

None in the canonical registry, which is still empty. The current active presentation changes remain unarchived and retain their unreported acceptance work.

## Impact

Touches environment presentation, one offline panorama authoring tool and its bundled image/provenance, regression/render tests and documentation. External downloading was not automatically approved, so the equivalent original panorama avoids external licensing, paid generation and runtime networking. No renderer migration, animated weather, day/night cycle, new light, geometry or settings UI is added.
