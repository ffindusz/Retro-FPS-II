# Development

Toolchain: Godot 4.7.x stable (currently bundled: 4.7.2), standard GDScript, Compatibility renderer. No addons or .NET required. Use executable names and export templates matching the installed engine.

From the project root in PowerShell:

```powershell
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit-after 10
& .\Godot_v4.7.2-stable_win64.exe --path . --editor
```

Use the console executable to capture errors. A missing export template does not prevent editor play.

## Physics contract

| Bit / mask | Layer | Purpose |
|---|---|---|
| 1 / 1 | World | Static level and independently authored model collision |
| 2 / 2 | Player | Player body |
| 3 / 4 | Enemy | Living enemy bodies |
| 4 / 8 | Pickup | Collectible areas, monitoring the player only |

Projectiles are swept world-space ray queries, not colliding rigid bodies: player bolts query World + Enemy (5), enemy bolts query World + Player (3). They ignore the firing actor RID. Melee candidates use moving capsule queries against Enemy (4), then World + Enemy (5) rays validate first contact, reach, frontal bounds, and occlusion. Imported viewmodel meshes have no physics layers. Mouse look uses `InputEventMouseMotion`; all discrete controls are named actions in `project.godot`.

## Regression and authoring tools

`tools/verify.ps1` checks native exit codes **and** scans for script/runtime errors (Godot can otherwise return zero after a script failure). Add `-Render` to open a short game-only rendering check. No desktop capture or UI automation is used.

```powershell
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/run_tests.gd
& .\Godot_v4.7.2-stable_win64_console.exe --path . --script tests/render_check.gd
& .\Godot_v4.7.2-stable_win64_console.exe --path . --script tests/profile_demo.gd
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/bake_navigation.gd
```

The level is a fixed, explicitly positioned layout constructed by `scripts/level.gd` at runtime. Its scene root owns the player, enemies, pickups, and projectiles, so destroying the root cleans up a run. `build_geometry()` can also be called by the navigation authoring tool without spawning gameplay actors. Static collision changes require rebaking the checked-in navigation resource. Torches and urns are nonblocking, independently replaceable visual wrappers.

## Combat polish architecture

- `weapon_controller.gd` owns a physics-driven melee phase clock, hit IDs, and deferred selection; `viewmodels.gd` reads that clock. The overlay camera/light are outside the animated weapon root so moving that root changes the visible stroke, not the camera.
- `CombatEvents.apply_hit()` uses actual applied damage returned by actors before emitting confirmation. Events contain IDs/values, not actor references, and route through the owning level's `CombatFeedback` instance.
- `CombatFeedback` deduplicates recent event IDs, bounds visual effects to 24/.32s, and forwards valid events to the HUD and SFX service. Presentation never applies damage.
- `CombatAudio` loads the bundled WAVs, owns at most 12 local/spatial voices, and uses a conservative SFX bus/limiter. Pause/terminal/disposal stop one-shots without a replay queue. The session retains volume and removes a game-created SFX bus on teardown, without removing a preexisting custom bus.
- Tests use real input events for the pause slider and event counts/resource inspection for headless audio. They explicitly detach stopped streams and allow .2s at final test shutdown for backend audio buffers to drain; old-run node/voice cleanup is tested separately. This is not subjective listening evidence.

To regenerate the original bundled SFX (no API calls):

```powershell
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/generate_combat_audio.gd
```

Preserve the checked-in WAV `.import` settings (`compress/mode=0`, no normalization) when regenerating. See `docs/combat-polish-validation.md` for pre/post evidence and the revised placement table.

`builds/.gdignore` prevents generated screenshots, logs, and binaries from being imported by Godot. Keep `.gd.uid` files alongside scripts, but never commit the generated `.godot/` cache. No source-control repository was initialized automatically.

## Optional external model authoring

The user-authorized Meshy authoring tool is separate from all runtime GDScript. Python 3.11+ is needed only for this optional developer tool, not for playing or exporting the game. Run its offline safety checks with:

```powershell
python -m unittest discover -s tests -p test_meshy_generate.py -v
```

See `docs/model-workflow.md` before making paid requests. Unreviewed downloads remain in the approved external staging directory; no key or signed URL belongs in tracked files or the export. `tools/inspect_glb.py <path-to-model.glb>` reads geometry counts and embedded texture metadata without importing the asset or contacting a service.

## Fortress atmosphere

`FortressPresentation` applies shared environment-only materials, low-relief dressing and six-light modulation after the original geometry is built; it adds no physics objects. `WorldFingerprint` compares sorted collider/actor/item/objective/stat and navigation data against the pre-pass snapshot. Geometry-only `build_geometry()`/navigation authoring does not instantiate presentation, a player or ambience.

`FortressAmbience` owns two forward-loop players outside the one-shot SFX pool, a complementary one-second crypt blend and an independent app-session volume. Session transitions explicitly pause/resume or stop/detach streams; only game-created buses are removed. Audio tests allow backend buffers to settle before comparing paused playheads. Pointer tests send the window mouse-enter notification absent from a headless display driver, then actual local mouse events; no OS cursor warping or desktop capture is used.

```powershell
# Original assets only: does not call any API or rewrite accepted models/SFX.
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/generate_fortress_assets.gd
# Reproducible fixed views and frozen-scene comparison; keeps before captures intact.
& .\Godot_v4.7.2-stable_win64_console.exe --path . --script tools/capture_atmosphere.gd -- after
python -m unittest discover -s tests -p 'test_*.py' -v
```

The original `before` capture refuses to overwrite its recorded baseline. Set the main session's exported **Atmosphere Enabled** to false for a flat/static diagnostic run; normal builds default on. Keep the authored PNG mipmap and WAV forward-loop/PCM/no-normalization import settings when regenerating. New visual/listening approval remains a user test, not an inference from headless checks.

## Fortress refinement 0.4

`FortressPresentation.surface()` now loads bundled CC0 photographic maps, with trim sharing wall textures, OpenGL normals and physical wall/floor tile scales. The six original procedural images remain historical authoring resources. Exactly two existing torches cast shadows; their emitter meshes do not self-shadow.

`CombatFeedback` shares a six-light budget across short fading spell flashes and projectile-attached lights. Projectile nodes own their illumination; feedback prunes freed records before cleanup, freezes aging on pause and clears all lights on terminal transitions. The atmosphere-off diagnostic disables both additions without changing gameplay.

Successful key collection publishes `pickup_key` through the existing pickup-specific event ID and deduplicated SFX path. Generate only its new original cue with `--script tools/generate_combat_audio.gd -- pickup_key`; all eleven older WAVs remain unchanged. See [current validation, measurements and export blocker](realistic-fortress-validation.md) and [texture provenance](../assets/environment/photographic/README.md).

### Moonlit sky patch 0.4.1

`FortressPresentation._setup_sky()` attaches a per-run Sky/PanoramaSkyMaterial to the existing WorldEnvironment, sharing one bundled static panorama. Keep `AMBIENT_SOURCE_COLOR` and `REFLECTION_SOURCE_DISABLED` explicit so the background cannot change illumination. The sky uses the smallest radiance cache and quality processing, with no per-frame animation or generation. Atmosphere-off never attaches a sky. [Original authoring, provenance and import instructions](../assets/environment/README.md) describe the clockwise longitude mapping; rendered checks aim along the moon light's positive Z and reject a missing/misaligned moon at both resolutions.
