## Why

The user wants to hand-build Cinderkeep levels visually in Godot and explicitly selected Cyclops plus a game-specific placement/build/playtest workflow. The current level, encounters, navigation and environment regions are hardcoded, so installing a geometry addon alone cannot produce a complete playable map.

## What Changes

- Pin and verify Cyclops 1.5.2 for Godot 4.7; retain its licenses and document any minimal integration patch. Keep editor dependencies out of gameplay/export.
- Add an editable authored-level template, visible placements for player start/enemies/pickups/key/exit/props/zones, and a Cinderkeep editor dock with undoable placement, build, validation and normal-session playtest.
- Convert Cyclops blocks to ordinary runtime meshes/collision, bake per-level navigation and save an independent generated runtime scene without overwriting the authored source or hand placements.
- Generalize level selection/session restart and provide an authored-level controller reusing existing gameplay without changing the original demo or combat balance.
- Provide a small complete entrance/courtyard/crypt example, documentation, tests, renders and a separate Windows validation export. Preserve accepted 0.4.1/0.5.0 artifacts; no paid services or new art generation.

## Capabilities

### New Capabilities

- `visual-level-authoring`: Cyclops-backed editing, game-object palette, validation/build/playtest and portable runtime levels.

### Modified Capabilities

None; no canonical specs directory currently exists. Existing demo gameplay remains a regression reference.

## Impact

New editor addons, runtime authored-level/placement/zone support, authoring and generated example scenes, per-level navigation, session level selection and UI wiring. Export exclusions, tests, credits and developer documentation change. No procedural generation, in-game map editor, arbitrary mod loading, new enemy AI or multi-key/door system is included.
