## Context

Godot 4.7.2 and pinned Cyclops 1.5.2 provide the current 0.6.2 authoring foundation. The dock has thirteen kinds, undoable centre placement and a non-destructive builder. Validation returns strings; only the mapping example has a menu shortcut. Source SHA detects saved-scene changes but not external geometry data. All prior accepted builds must remain intact.

## Goals / Non-Goals

**Goals:** faster deliberate placement, actionable diagnostics, code-free built-map selection and an honest checked-export gate. Preserve balance, existing scene schemas/kind integers, fallback visuals, default Start/restart and the Cyclops vendor pin.

**Non-Goals:** campaign design, new art/paid services, arbitrary file/mod loading, multi-key/door mechanics, new collision/navigation tuning, or implying human usability approval from automation.

## Decisions

1. **Editor input mode.** Palette buttons arm placement; `_forward_3d_gui_input` uses the actual active camera/event position, not viewport 0. A transient ownerless ghost lives outside Architecture/Placements. Valid LMB clicks commit one marker via EditorUndoRedoManager; the mode remains armed for repetition. Escape/RMB, scene switches, build/playtest and disable clear mode/ghost. Alt navigation and Ctrl+Z pass through. Floor objects require upward surfaces; torch/lantern wall mounts use horizontal normals, preserving yaw-only markers. Add snap/grid/facing controls and explicit Place at View Centre compatibility action. Invalid hits never silently spawn at origin.
2. **Structured issues, compatible strings.** Builder keeps its existing `errors` array for CLI/tests and adds issue records `{message, node_path, code}`. Missing/global requirements link to their container/root; per-object checks retain exact node identity/path. The dock renders selectable issue rows and selects/inspects the resolved current-source node, handling deleted/stale targets safely. Plain labels prevent BBCode/markup injection.
3. **Runtime-safe discovery.** A small runtime catalog reads public `.tscn` built scenes under `scenes/levels/generated/`, including remapped exported resources, inspects PackedScene state without instantiating actors and exposes deterministic title/path entries. Private `_...` test/draft outputs are excluded. A bounded scrollable Choose Level menu uses path IDs (not titles), supports duplicate titles/empty lists/back/Escape, and preserves selection through restart. Existing Start and Mapping Example shortcuts remain compatible.
4. **Build provenance.** Keep the canonical scene SHA and add a versioned fingerprint for source resource dependencies and the builder recipe. Older outputs still run, but checked export requests a rebuild. No source geometry changes are required to update metadata; rebuild the sample through the normal builder. Normalize text newlines so Windows checkout does not make every map stale.
5. **Explicit export boundary.** Godot 4.7.2's EditorExportPlugin begin callback cannot cancel export; its configuration warning does not affect `can_export`'s bool. Do not pretend `push_error` blocks it, delete completed files or mutate presets. Provide Checked Export (PCK) in the dock and a PowerShell wrapper for release/pack CLI. Both run the same preflight before invoking Godot export, refuse stale/missing/orphaned public maps and existing output paths, and leave artifacts untouched on preflight failure. Stock export gets a clear warning when bypassing checks. Public authoring maps must have associated builds; underscore-prefixed drafts/tests are excluded from catalog/preflight/export.
6. **Editor-only dependencies.** Placement/validation/preflight/export helpers remain in the addon/tools; runtime catalog/menu contain no editor/source dependency. Export exclusions retain all existing secrets/prototype exclusions plus private generated test maps.
7. **Additive 0.7.0 checkpoint.** Version metadata/preset separately; do not overwrite 0.4.1 through 0.6.2 builds/records. Validate a fresh isolated export and document exact evidence. No commits/pushes without user request.

## Risks / Trade-offs

- [Placement steals navigation/selection or serializes a ghost] → Handle only armed valid placement gestures, pass through navigation/modifiers, test scene transitions/cancel/save/undo and preview ownership.
- [Wall mounts face into walls] → Kind-specific anchor conventions, numeric transform tests and actual wall-view inspection; do not change marker kind values.
- [Export warning mistaken for a gate] → Label Checked Export explicitly; document stock-export bypass and prove preflight prevents exporter invocation/output changes with failing tests.
- [Stale external resources escape scene SHA] → Versioned canonical dependency fingerprint; tests mutate external geometry and line endings.
- [Map discovery loads editor scenes or executes scripts] → Fixed res:// root, public names, PackedScene state inspection, runtime dependency closure and external-PCK menu tests.

## Migration Plan

Add issue/provenance helpers, implement placement/report UI and checked export, add catalog/menu, then rebuild only the sample runtime snapshot. Preserve source/placement semantics and all old build artifacts. Run source, real-editor, offline and isolated packaged tests/renders, then hand off for human review.

## Open Questions

Ergonomic preference for repeated placement/snap size and future map metadata/campaign progression remain user-review topics, not scope expansion.
