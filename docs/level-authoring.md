# Visual level authoring — Cinderkeep 0.6.0

## Start here

This is the user-selected **hand-building workflow inside Godot**, not a random generator or an in-game map editor. Geometry uses the pinned **Cyclops Level Builder 1.5.2**; Cinderkeep supplies placements, validation, build and normal-session playtest. No additional Meshy requests, key access or credits were used.

**User confirmation — 2026-11-03:** after the handoff the user reported **"simple test works"** and requested repository sync. This confirms a successful basic test of the delivered workflow. Exact actions/platform, detailed designer ergonomics, a complete example playthrough and explicitly disconnected native acceptance were not separately reported. This feedback-only record does not change or rebuild the delivered binaries/checksums.

**Repository-sync follow-up:** upstream `9a4f0fb` and its two preceding commits have been integrated, retaining archived specifications and 0.5.1's Adept collapse, grounded enemy cues, louder ambience and visible bounded flicker. Combined source passes **496 source + 27 editor checks**, **89 Python tests**, and **348 checks against a temporary merged-source PCK**, plus package audit/native startup. The supplied 0.6.0 EXE/PCK remain the original smoke-tested handoff from feature commit `3df7971`; no versioned binaries were replaced. The initial validation numbers below describe that original handoff. Export current source to a new folder instead of overwriting pinned snapshots.

1. Import `project.godot` with bundled **Godot 4.7.2 standard**, letting imports finish.
2. Both plugins are already enabled under **Project → Project Settings → Plugins**. Do not separately install a newer Cyclops over this pinned copy.
3. Find the **Cinderkeep** dock below the Inspector. If hidden, open **Editor → Editor Docks → Cinderkeep**. Placement buttons scroll; Build/Check/Playtest stay above the list.
4. Click **Open Mapping Example**, or open `scenes/authoring/mapping_example.tscn`.
5. Try **Check Level**, then **Playtest Level**. The latter builds and launches the normal game session with the selected map.

**Do not use F6 on the authoring source:** it is editor data, not a complete game entry. Use the dock's Playtest action. F5/main scene still opens the normal menu: **Start** preserves the original demo; **Mapping Example** plays the new map.

## Make your own map

### Create and edit architecture

Choose **New Level…** and save a unique name such as `scenes/authoring/my_crypt.tscn` (letters/digits/underscores). This creates an editable starter room, Player Start, Ember Key and Exit Gate. It also sets a separate runtime output such as `scenes/levels/generated/my_crypt.tscn`.

Select a **Cyclops block beneath Architecture** to activate Cyclops's toolbar. Use its Block/Face/Clip/Stairs and transform tools to build floors, walls, doorways, cover and platforms. Use grid snapping to keep seams aligned. Keep the level root and Placements container at identity transform; move individual blocks/objects instead.

Use the shared game materials:

- `resources/materials/mapping_wall.tres`
- `resources/materials/mapping_floor.tres`

They reuse the unchanged, cleared 1K photographic PBR maps. Use them through Cyclops's material tools. Unassigned surfaces build with the game wall material; addon preview/grid materials must be replaced before build. Native meshes/CSG/moving physics architecture are not supported by this first converter: use Cyclops blocks with **static World-layer collision** or non-colliding decoration. Non-finite/zero/mirrored block transforms are rejected.

### Place gameplay objects

The palette includes **Player Start, Warden, Adept, Health, Mana, Ember Key, Exit Gate, Torch, Urn and Crypt Ambience**.

Click a palette button to place a marker on the floor under the **centre of the 3D viewport**. If no floor is hit, it is placed at the level origin and the dock says so. Use Godot's move/rotate gizmos and snapping to position it. The yellow direction indicator points along local **-Z**. Placement supports normal selection, duplication and Ctrl+Z/Ctrl+Shift+Z. Previews never run AI or create gameplay collision/audio.

| Object | Editing notes |
|---|---|
| Player Start | Exactly one. Floor anchor at ground height; Y rotation sets initial facing. |
| Warden / Adept | Floor anchors, unit scale, Y rotation. Existing combat defaults remain authoritative; this milestone does not add tuning overrides. Warden editor preview is static, not animation playback. |
| Health / Mana | Floor anchor; Inspector **Amount** controls restoration. Preview/runtime bottle rises above that anchor. |
| Ember Key | Exactly one, using the existing single `has_key` inventory rule. |
| Exit Gate | Exactly one, placed inside reachable space, not embedded in the wall. Nearby E interaction requires the ember key. This is a level-completion marker, not a newly implemented physical locked door. |
| Torch / Urn | Position and Y rotation. First two authored torches cast shadows; extra torches remain shadowless. Props retain existing nonblocking behaviour. |
| Crypt Ambience | Axis-aligned box; **Zone Size** is full width/height/depth. Centre it above the floor, e.g. Y=1.5 for height 3. No zone rotation. |

Move objects under their existing **Placements** container. Preview descendants are transient and deliberately not saved. Do not manually add live enemy/player scenes under this container.

### Build, check and play

- **Build Level + Navigation** saves the source, converts architecture into native Godot meshes/static convex collision, checks gameplay placements and saves an independent runtime scene with embedded navigation. It does **not** replace/delete the source blocks or hand placements.
- **Check Level** saves and validates the current source, including fresh navigation checks, without updating the runtime output. It reports when the built output is missing/stale.
- **Playtest Level** builds first, then launches a local ignored wrapper of the normal main session. You get real HUD/title, combat/audio, pause, defeat/victory and restart. Restart retains the selected map.

Validation blocks missing/duplicate start/key/exit, unsupported containers/transforms/material dependencies, obstructed placements, missing floor support, out-of-navigation objects and disconnected objectives/enemies. It checks with the existing **0.4m agent radius, 2m bake height and 0.2m climb**. An existing output linked to a different source is left untouched. If you use Save As on a source, choose a **new Runtime Path** in the root Inspector.

These are authoring safeguards, **not proof of every jump, stair ascent, line of sight or encounter**. Player/AI movement is unchanged; test your actual stairs/corridors in play. Lighting quality, item spacing and difficulty still need human judgement.

**Build after changing a map and before exporting.** Export ships generated snapshots; it does not automatically rebuild every source. New maps are not automatically added to a catalogue/menu. To make your map the exported Start level without code, open `scenes/main.tscn`, select the root, assign your generated scene to **Default Level**, save, then export. Keep the supplied original/default scene setting if you want Start to remain the original demo.

## Example and file separation

```text
scenes/authoring/mapping_example.tscn       editable Cyclops source
                    │ Build
                    ▼
scenes/levels/generated/mapping_example.tscn
                    native geometry + placements + per-level navigation
                    │
                    ▼
normal Cinderkeep session / Windows game
```

**The Mason's Trial** has an entrance, courtyard with cover/practice steps, crypt, two Wardens, one Adept, two health pickups, one mana pickup, ember key, exit, three torches, two urns and an ambience zone. Its 20 Cyclops blocks produce 49 navigation polygons. Collect the key in the eastern room and return to the gate at the courtyard's northwest side. This example is deliberately small; it is not a new polished campaign or difficulty claim.

`scripts/levels/authored_level.gd` adapts authored data to the existing level/session services. It does not call coordinate-specific demo dressing; `authored_presentation.gd` registers placed lights and authored ambience uses explicit box bounds. The original `scripts/level.gd`, accepted demo layout/navigation fingerprints and enemy balance remain the reference.

Runtime scenes do not depend on Cyclops. Both `addons/*` and `scenes/authoring/*` are excluded from exports; the project contains **no Cyclops autoload**. The editor playtest entry `scenes/authoring/_playtest.tscn` is local/ignored and not a distributable map.

## Pinned addon and integration fixes

Official release: [Cyclops 1.5.2 for Godot 4.7](https://github.com/blackears/cyclopsLevelBuilder/releases/tag/v1.5.2), archive **4,651,544 bytes**, SHA-256 `ea6d7a018e596d4a7c33657513622b2acd9c21b7590b764c9d62f6db7144517e`.

`docs/third-party/cyclops-1.5.2.json` fingerprints **854 upstream source/assets** (canonical LF text; Godot-generated `.import` and the archive's scratch `.tmp` file excluded) and four locally patched scripts. The exact patch is retained alongside it. Local fixes:

1. Own the drawing root in the editor instead of installing a game autoload.
2. Dispose unparented action dialogs, inactive dock panels and the snapping helper on plugin teardown.
3. Skip GPU thumbnail readback during headless import.
4. Use weak topology backlinks to avoid temporary convex-volume reference cycles during repeated editing/building.

Vendor **MIT** notice remains at `addons/cyclops_level_builder/LICENSE.md`; bundled **Roboto Apache-2.0** notice remains at `art/fonts/Roboto/LICENSE.txt`. Fonts/addon code are editor-only and not in the game PCK. This is not permission to remove vendor notices or auto-upgrade over local fixes.

Godot's editor initially auto-switched existing 3D texture imports to VRAM compression. This integration restores lossless 1K/mipmapped compression and disables that automatic switch for the affected editor-preview/world textures (`detect_3d/compress_to=0`). The editor's explicit normal-map detection metadata is retained. Raw images/models and size limits remain unchanged; no pixel-identical rendering claim is inferred from import metadata. The accepted 0.4.1/0.5.0 binaries are not re-exported. Godot also reserializes the project/input-event properties without changing the configured bindings.

## Initial validation and Windows handoff — 2026-11-03

- **489 runtime/prototype source checks**: original 269, Warden 42, authored map **30**, and prior prototype suites 148. All pass.
- **27 real-editor checks**: actual New Level/save dialog, all palette buttons, editor undo/redo, save/reopen, transient preview duplication, non-destructive build, staleness and focused missing-key/obstructed-start/disconnected-island/output-ownership failures. Actual Playtest launch and Stop also pass. This uses a rendered Godot editor and its signals/API, not desktop input automation.
- **87 offline Python tests** include six new vendor/dependency/source-fingerprint/version/notice checks.
- **341 packaged checks**: original 269 + Warden 42 + authored map 30, run through the editor engine against the exported PCK outside the repository. No project-resource fallback.
- A separate clean source copy with **no `.godot` cache or credentials** passes first editor import and the 30 authored-map checks. This also verifies initial class registration rather than relying solely on the working project's import cache.
- Package audit verifies required generated/runtime resources and absence of editor addons, authoring/prototypes/tools/tests/credentials. Native EXE headless startup and rendered menu startup pass externally. The official release template cannot use external script/scene overrides; those are not relabelled as interactive native-map tests.
- Existing game/prototype renders pass. New game captures include menu, entrance, courtyard, crypt and overview at 720p/1080p (10 images), plus an actual editor-viewport workflow image. No desktop capture.

Evidence: `builds/validation/level-authoring/{verification,offline-tests,editor-tests,editor-tests-final,export,packaged-game-tests,packaged-warden-tests,packaged-authored-tests,package-audit,native-startup,native-menu-render,fresh-import,fresh-authored-tests,fresh-asset-tests}.log`, `package-audit.json`, `delivery-validation.json` and viewport PNGs. Final verification records supersede the retained early compatibility diagnostics. Spatial validation uses a private physics world and synchronous private navigation region/map, without changing global navigation-server activation.

Sync-specific evidence is retained separately as `repo-sync-{verification,offline-tests,editor-tests,export,packaged-game-tests,packaged-warden-tests,packaged-authored-tests,package-audit,native-startup}.log`, `repo-sync-package-audit.json` and `repo-sync-validation.json`. These validate the combined source/temporary PCK, not a replacement of the original 0.6.0 handoff.

Launch **`builds/windows-0.6.0/Cinderkeep.exe`** with its adjacent PCK; select **Mapping Example**. The original demo remains **Start**. Accepted 0.4.1 and user-confirmed 0.5.0 files/hashes remain intact. This is a separate local validation handoff, not a public release or a new portable ZIP.

### Remaining human review

- [x] Basic user smoke-test feedback recorded: "simple test works" (2026-11-03).
- [ ] Build/resize a room yourself, place objects, undo/redo, rebuild and playtest without code changes.
- [ ] Judge dock ergonomics, orientation/preview clarity, materials, actual stair/doorway traversal and encounter spacing.
- [ ] Complete the example, exercise defeat/restart/pause and test the Windows map interactively; explicitly disconnected full-run acceptance remains unreported.

Existing open-finger/foot-planting/pose limitations of the accepted Warden remain. Automated checks and generated screenshots do not close these human-review items.
