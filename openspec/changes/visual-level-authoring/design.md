## Context

Godot 4.7.2 Compatibility runs the accepted 0.5.0 game. `DemoLevel` currently owns hardcoded geometry/placements/exit/environment and a fixed navigation resource; session startup selects only that scene. Existing actors and run-scoped combat/audio are reusable. The user chose hand-building inside Godot with Cyclops, not procedural generation or an in-game editor.

## Goals / Non-Goals

**Goals:** complete no-code map-authoring loop, visible gameplay placements, reproducible geometry/navigation build, normal-session playtest/restart and exported example. Preserve the original demo/fingerprints, combat defaults and accepted build artifacts.

**Non-Goals:** generation, arbitrary scene/mod loading, multi-key inventory, moving/locked intermediate doors, new paid art, public distribution, replacing accepted builds or declaring editor usability human-approved from automation.

## Decisions

1. **Pinned vendor, editor isolation.** Vendor the official Cyclops 1.5.2 release, verified against published SHA-256 `ea6d7a018e596d4a7c33657513622b2acd9c21b7590b764c9d62f6db7144517e`. Preserve MIT and bundled component notices. Upstream installs a project autoload for editor drawing; replace that narrowly with an editor-owned root service so it cannot load in gameplay/export. Document and hash the patch; otherwise retain vendor bytes. Exclude both editor addons and authoring scenes from exports.
2. **Editable source, independently generated runtime.** Authoring root has Architecture and Placements containers. Cyclops creates/edit blocks normally. Build creates new ordinary MeshInstance3D/StaticBody3D/ConvexPolygonShape3D nodes using block data, preserves transforms/materials, and copies placement data rather than live actors. It never mutates/deletes designer geometry/placements. Runtime output is restricted to `scenes/levels/generated/`, with source path/hash metadata to prevent accidental overwrite and detect stale builds.
3. **Runtime level adapter instead of replacing accepted demo.** A separate authored-level controller extends the existing level interface and reuses player/enemy/pickup/combat/environment setup where safe, overriding hardcoded geometry/population/navigation/exit. Per-level baked NavigationMesh is embedded in the generated scene. Placement-driven zones replace world-coordinate ambience for authored levels only. Keep the player a direct level child for the existing interaction contract.
4. **Shared marker schema, safe previews.** Runtime-safe `@tool` placement nodes expose a bounded object enum, amount and zone extents. Editor-only transient preview descendants have no persisted owner and no collision/AI/audio. Actual actors are instantiated only by the runtime level. Node transforms/Inspector provide snapping, move, rotate, duplicate and undo; dock insertion uses EditorUndoRedoManager and correct scene ownership. Preserve existing tuning; start with exactly one start/key/exit.
5. **Explicit build and validation.** Save source before build. Validate required groups/counts, unit transforms, finite/positive zone data and supported static collision geometry. Convert architecture, bake navigation against world collision only, then check body clearance, floor support, nav proximity and connectivity to objectives/enemy spawns. Errors block output/playtest; warnings explain limits. Navigation connectivity is not proof of every jump/encounter. Rebuilding is permitted only for an output linked to the same authoring scene. Check Level detects stale output.
6. **Normal-session playtest.** Session accepts an exported default level and retains the selected PackedScene through restart; Start still selects the original demo. An additional menu entry plays the generated example. Editor playtest saves a local ignored wrapper of the normal main session with selected generated scene/auto-start, then uses EditorInterface.play_custom_scene. No runtime editor dependency, global singleton test state or damage shortcut.
7. **Additive 0.6.0 delivery.** New project/menu/preset version and `builds/windows-0.6.0/` preserve 0.4.1/0.5.0. Export contains built sample geometry/navigation/runtime code, not source Cyclops/authoring tools. Editor and packaged tests verify original demo and new map independently. Historical version tests move their frozen assertions to release records; retain gameplay assertions.

## Risks / Trade-offs

- [Cyclops editor service leaks into export] → No project autoload, editor-owned service, runtime dependency closure/package audit and external-working-directory tests.
- [Source/build divergence or overwritten designer work] → Separate paths, source fingerprint and same-source ownership guard, no destructive architecture conversion.
- [Editor previews accidentally run AI or serialize duplicates] → Static transient preview meshes; runtime marker does nothing outside editor; verify save/reopen, counts, undo/redo and pause/restart.
- [Navigation appears valid but actor gets stuck] → Bake with existing radius/height/climb settings, collider/clearance/path checks and real movement tests; human playtest still required.
- [Environment logic still assumes demo coordinates] → Authored-level environment uses explicit zone bounds/props rather than calling demo dressing setup.
- [Broad vendor surface/updates] → Pin official archive and component hashes, document minimal local patch, do not auto-upgrade.

## Migration Plan

Install/test pinned addon, introduce additive runtime/schema/build components, add editor dock and authored sample, then verify source/editor/export workflows. Default demo and old artifacts remain available. No commits/pushes without a separate user request.

## Open Questions

Actual designer ergonomics and desired future door/key complexity remain follow-up review points, not assumptions that expand this milestone.
