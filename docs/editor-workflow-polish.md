# Editor workflow polish — 0.7.0

## What's ready

This builds on the user-smoke-tested Cyclops foundation and the 0.6.2 lights/animated Adept. It adds deliberate surface placement, navigable validation, automatic built-map selection and an explicitly checked export route. No new art, paid API request, key access or Meshy credits were needed. Combat/actor tuning, authored source layout, source models/audio and pinned Cyclops vendor files remain unchanged.

**Human review is pending.** The previous "simple test works" report applies to the earlier workflow, not automatic acceptance of these new controls.

**Repository sync — 2026-11-06:** feature commit `c632b44` is combined with upstream `fc8570c` (0.6.3): trimmed baked torch flame and flickering lantern glow. Current combined source passes **559 source + 42 editor checks, 102 Python tests and 387 checks against a separate checked-export PCK**, plus its 264-resource audit and native startup. The supplied 0.7.0 handoff remains the original pre-merge snapshot; its recorded hashes/counts below are not overwritten or relabelled. Sync logs are `builds/validation/editor-polish/repo-sync-*`. Export current source to a new output folder/filename when needed.

## 1. Click to place

Open `scenes/authoring/mapping_example.tscn` or use **Cinderkeep → New Level…**. Select a palette kind, then move into the actual 3D viewport:

- The palette **arms a mode**; it no longer immediately creates an object at the camera centre.
- A transient **PLACEMENT PREVIEW** follows valid source architecture. LMB commits one placement; stay armed to place more.
- **R** rotates facing by 90 degrees. **Escape or RMB** cancels. **Alt navigation, wheel/middle navigation and Ctrl+Z** are not turned into placements.
- Floor kinds require an upward-facing floor. Torch and wall-lantern kinds require a vertical wall and use the measured existing mount conventions (torch +Z, lantern arm -Z facing away from the wall).
- **Grid snap**, **Grid (m)**, **Facing / wall offset** and **Height offset** are in the scrollable placement section. Floor snapping preserves actual floor height; wall snapping stays on the wall plane. Default ambience boxes are centred above the floor.
- **Place at View Centre** is the explicit compatibility action. It still requires a valid surface: misses never silently create an object at the origin.
- After placement, cancel the mode to manipulate existing nodes with Godot's usual gizmos. Placement uses the scene's normal undo/redo history.

The input handler uses the camera supplied by the active editor viewport. The ghost has no saved owner, lives outside Architecture/Placements and adds no collision or gameplay AI. Build, Playtest, Checked Export, scene changes and plugin teardown clear it. Root/Placements transforms must remain identity.

The dock now has compact action rows and a two-column palette; long labels retain full tooltips. Existing marker enum values and Inspector properties are preserved.

## 2. Fix issues directly

**Check Level** and **Build Level + Navigation** retain all previous structural, clearance, floor and navigation checks. Errors now include a source file, node path, issue code and (for live source checks) node identity.

Click an issue row to select/inspect the relevant marker or architecture node. Missing-required-object issues select the Placements container; root/output problems select the root. Deleted/renamed/replaced targets ask for a new check rather than selecting another object accidentally. Export issues can open the corresponding authoring source before selecting its root.

**Open Source / Level Root** selects the source root or returns from a generated scene to its source. **Open Built Scene** opens the generated snapshot for inspection; do not edit it as your authoring source.

**Saved build: current / missing / stale** explicitly describes saved data, not unsaved gizmo edits. Save/check/build before relying on it. Build metadata now records:

- Canonical-LF scene SHA.
- A versioned build-recipe number.
- A canonical fingerprint of external source resources/dependencies (including external Cyclops geometry data and materials).

Old builds can still run, but Checked Export requires rebuilding them once to record the stronger metadata. Windows newline conversion does not make a map stale. The example was rebuilt normally; its 20 source blocks and gameplay placements were not edited. Navigation polygon representation can differ after a rebake; actual route/fingerprint checks remain authoritative.

## 3. Choose built maps without code

The main menu now includes **Choose Level**. Public built `.tscn` files directly under `scenes/levels/generated/` appear automatically after build. The menu uses the saved title plus filename, sorts deterministically and selects by path rather than title; duplicate titles remain distinguishable.

Keyboard focus follows scrolling. Back and Escape return to the main menu. Selecting a map uses the normal HUD/combat/session flow and restart retains that selected map with fresh state. **Start** still selects the configured default/original demo; the **Mapping Example** shortcut remains available.

The catalog inspects PackedScene state without instantiating actors and resolves exported/remapped resource names. It cannot load `user://`, arbitrary paths or authoring scenes. Underscore-prefixed maps are private drafts/tests and are excluded from the menu and exports. Keep public source/build associations intact; if making a draft private, both source and output must use private names (or remove that draft's generated output).

## 4. Export through the checked route

### Important Godot API boundary

**Godot's stock export-plugin begin callback cannot cancel export.** Adding an error/warning is not a reliable gate. Therefore:

- **Cinderkeep → Checked Export PCK…** is the guarded editor action.
- **`tools/export_checked.ps1`** is the guarded Windows CLI route for a PCK or full Windows build.
- Stock **Project → Export** / direct `--export-*` bypasses the guard. If stale/missing maps are detected, the addon warns explicitly; it does not pretend the artifact was blocked. Use the checked routes for verified handoffs.

Checked Export saves open scenes, validates every public source/output association, then starts Godot in a child process. It rejects missing/stale/orphaned maps, duplicate output ownership, empty navigation and existing target files. Unbuilt public maps must be built (or deliberately made private) first. It never silently rebuilds or discards your edits.

Exports are staged under ignored `builds/validation/checked-export-*`. Only after the exporter succeeds and preflight still matches is a new final output published. Keep the destination dedicated to this operation and do not write to it externally during export. If the editor closes, its own child exporter is stopped; prior outputs are not deleted/replaced. The editor action creates a **PCK**, not an adjacent EXE; use the CLI for a full portable Windows pair:

```powershell
# Use a NEW output filename. Existing output/PCK files are refused.
.\tools\export_checked.ps1 -Output "$PWD/builds/windows-current/Cinderkeep.exe"
# Or create just a resource pack:
.\tools\export_checked.ps1 -Pack -Output "$PWD/builds/checked-exports/Cinderkeep-current.pck"
```

The default preset is **Windows Desktop**, using the existing export settings/exclusions. The CLI's .NET copy refuses existing destinations, and its preflight runs before invoking the exporter. On failure, inspect the reported issue/source or retained staging log, rebuild affected maps and choose a new output path.

This guard validates saved map freshness and association—not every jump, visual intersection, gameplay balance or a malicious scene/mod sandbox.

## Initial handoff validation — 2026-11-04

- **557 headless source checks:** existing 514, **24 policy/provenance checks** and **19 map-selection checks**. Existing original-demo fingerprints and actor tuning pass unchanged.
- **42 real-editor checks:** palette arming/viewport InputEvents, all thirteen kinds, undo/redo, navigation pass-through, misses, Escape/RMB, transient preview save/duplication, structured issue click selection/renames, non-destructive build, staleness, Playtest launch/stop, real child-process checked PCK export, existing-output preservation and scene-switch cleanup.
- **102 offline Python tests:** previous 96 plus six new bounded catalog/schema/export-exclusion/CLI-order/notice-preservation checks.
- The actual checked CLI successfully exported a new PCK/full Windows pair; a missing-public-build fixture was rejected with exit 1 **before savepack/export**, with no target file created. Existing-output and stale/external-resource cases are covered without starting an exporter in policy tests.
- **385 packaged checks** (294 game + 42 Warden + 30 authored map + 19 selector) pass against the fresh PCK from an external approved working directory. Catalog discovery works through exported remaps; no local editor/source fallback.
- A separate source copy with no `.godot` cache or credentials passes first editor import, checked-export preflight and all 19 selector checks. Resource fingerprints remain current after a clean import.
- **263-resource audit** passes, including required catalog/runtime assets and absence of editor addons, authoring/prototypes/credentials/private test maps. Native EXE headless startup and rendered menu startup pass externally.
- Game/prototype renders pass. New menu/selector/synthetic-long-list captures cover 720p/1080p (six images); editor screenshots show the compact dock and actual validation selection. The render review caught/fixed a clipped Back action; small-list visibility and long-list focus scrolling now have explicit checks. Synthetic list entries are UI stress data, not shipped levels.

Evidence: `builds/validation/editor-polish/` contains `verification.log`, `source-verification-final.log`, `offline-tests.log`, `editor-tests.log`, `polish-policy-tests.log`, `level-selection-tests.log`, `checked-cli*.log`, `release-export.log`, packaged-suite logs, `package-audit.{log,json}`, native-startup/menu logs, `fresh-{import,preflight,level-selection-tests}.log`, `delivery-validation.json` and viewport PNGs. Final source verification includes the two added menu clipping/focus regressions. Generated evidence/builds are ignored, not source-controlled release uploads.

## Handoff

Launch **`builds/windows-0.7.0/Cinderkeep.exe`** with its adjacent PCK; use **Choose Level** or the retained shortcuts. The Windows build is separate from all earlier handoffs. Existing 0.4.1/0.5.0/0.6.0 files present locally retain their pinned hashes; no older release records or vendor source fingerprints were replaced. No new public ZIP, upload or publishing approval is implied.

- [ ] User tries click placement and wall orientation, snap/facing, cancellation, undo/redo and issue selection in normal editing.
- [ ] User builds another map, selects it through Choose Level and judges keyboard/menu ergonomics.
- [ ] User exercises checked export and plays the current Windows build; a full explicitly disconnected playthrough remains unreported.

Existing animation/foot-planting/finger/pose limits are not solved by this workflow polish. Repository commits/pushes occur only on explicit request; that is separate from human workflow acceptance.
