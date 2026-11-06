## Why

The user smoke-tested the initial Cyclops workflow and selected editor polish before designing a full level. Placement currently drops at the viewport centre, validation is plain text, built maps need manual session configuration, and export can silently ship stale geometry/navigation.

## What Changes

- Add armed click-to-place placement with a transient preview, surface-aware orientation, grid/facing controls, cancel and undo/redo; retain a clearly labelled centre-placement fallback.
- Make structured validation issues select their associated source nodes; offer direct navigation to source/output and useful build/stale status.
- Discover public built maps in a runtime-safe level-selection menu, preserving Start/default level and restart semantics without loading authoring code.
- Add a guarded Checked Export action and offline CLI preflight/wrapper; reject stale/missing/orphaned public maps before invoking export. Clearly warn that Godot's stock export bypasses this guard (its plugin API has no cancellable begin hook).
- Strengthen build provenance for external source resources, retain existing gameplay/assets/Cyclops pin, and provide tests/docs plus a separately validated 0.7.0 checkpoint without overwriting prior builds.

## Capabilities

### New Capabilities

- `polished-level-editor`: surface placement, navigable validation, built-map selection and checked-export workflow.

### Modified Capabilities

None. Canonical Warden/sky contracts and the existing gameplay rules remain unchanged.

## Impact

Cinderkeep editor addon/build metadata, runtime level discovery/session/menu UI, editor/runtime/offline/export tests, versioned delivery configuration and mapping documentation. No paid requests, new art, procedural generation, multi-key gameplay, in-game editing or arbitrary external mod loading.
