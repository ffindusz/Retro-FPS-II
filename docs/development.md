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

`tools/verify.ps1` checks native exit codes **and** scans for script/runtime errors (Godot can otherwise return zero after a script failure). It runs the original game suite, runtime animated Warden, isolated whole-model study, skeletal rig, local/Meshy A/B, candidate and five-clip pilot suites. Add `-Render` for game/preview checks plus actual-level Warden/grip captures. Only rendered viewports are captured; no desktop capture or UI automation is used. Run offline Python tests separately with `python -m unittest discover -s tests -p 'test_*.py' -v`.

```powershell
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/run_tests.gd
& .\Godot_v4.7.2-stable_win64_console.exe --path . --script tests/render_check.gd
& .\Godot_v4.7.2-stable_win64_console.exe --path . --script tests/profile_demo.gd
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/bake_navigation.gd
```

The level is a fixed, explicitly positioned layout constructed by `scripts/level.gd` at runtime. Its scene root owns the player, enemies, pickups, and projectiles, so destroying the root cleans up a run. `build_geometry()` can also be called by the navigation authoring tool without spawning gameplay actors. Static collision changes require rebaking the checked-in navigation resource. Torches and urns are nonblocking, independently replaceable visual wrappers.

## Combat polish architecture

### Animated Warden 0.5.0

`warden_presentation.gd` owns visual-only clocks/poses/material feedback. `enemy.gd` calls it after actual physical travel, at windup start, immediately before authoritative attack resolution, on nonlethal hit and on death; the AI retains all combat/navigation authority. Death still advances visually after gameplay cancellation. Adept/fallback use the legacy path. Do not add animation-driven damage or stun on nonlethal hit.

`warden_grip.gd` is shared with the isolated pilot, compensates the measured **dark grip** centre and removes inherited rig unit/shear scale through an orthonormal hand frame. Render processing refreshes the follower only; physics ages animation. Runtime resources are independent copies under `assets/models/warden-animated/`, never imports from excluded prototypes. [State/timing, correction to the preliminary pommel measurement, bounds and evidence](warden-runtime-integration.md).

The current export preset writes **`builds/windows-0.5.0/`**. Keep the pinned `builds/windows/` and frozen 0.4.1 ZIP/packaging inputs intact; the old offline packager intentionally remains tied to those accepted bytes.

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

Successful key collection publishes `pickup_key` through the existing pickup-specific event ID and deduplicated SFX path. Generate only its new original cue with `--script tools/generate_combat_audio.gd -- pickup_key`; all eleven older WAVs remain unchanged. See [current validation, measurements and Windows delivery](realistic-fortress-validation.md) and [texture provenance](../assets/environment/photographic/README.md).

### Moonlit sky patch 0.4.1

`FortressPresentation._setup_sky()` attaches a per-run Sky/PanoramaSkyMaterial to the existing WorldEnvironment, sharing one bundled static panorama. Keep `AMBIENT_SOURCE_COLOR` and `REFLECTION_SOURCE_DISABLED` explicit so the background cannot change illumination. The sky uses the smallest radiance cache and quality processing, with no per-frame animation or generation. Atmosphere-off never attaches a sky. [Original authoring, provenance and import instructions](../assets/environment/README.md) describe the clockwise longitude mapping; rendered checks aim along the moon light's positive Z and reject a missing/misaligned moon at both resolutions.

## Release packaging and developer-only motion study

`python tools/package_release.py` packages the exact accepted binaries from a tracked hash record; it never re-exports the game. See [portable bundle notes](release-packaging.md) for allowlisting, notices, checksums and output handling.

`scenes/prototypes/warden_motion_study.tscn` is an isolated whole-model pose/timing experiment, not a gameplay actor. It reuses the original unrigged Warden twice and samples deterministic visual transforms from `scripts/prototypes/warden_motion.gd`. It has no physics, damage, combat events or audio. Grounding uses the transformed normalized visual AABB. [Preview controls, tests and limitations](warden-motion-study.md) explain why this is not a walk cycle or skeletal animation. Prototype paths are excluded from exports; do not integrate them into the live enemy state machine without a separately reviewed change.

`scenes/prototypes/warden_rig_preview.tscn` is the later real skeletal experiment: a separate normalized GLB with 21 bones, skin weights and Idle/Walk/Attack clips. It reuses the original material and remains isolated from all gameplay code. `tools/author_warden_rig.py` runs only in externally installed portable Blender; `tools/warden_rig_geometry.py` supplies offline assessment and deterministic fitted/topology-smoothed weights. Derived assets live under excluded `assets/prototypes/`, while editable `.blend` output is generated under ignored `builds/authoring/`. [Rig instructions and review limits](warden-rig-prototype.md) cover guarded rebuilds, source/tool provenance, actual CPU-skinned vertex tests, rigid-weapon checks, review controls and the lack of production animation/foot-planting approval.

`scenes/prototypes/warden_animation_ab.tscn` compares that unchanged local rig against the separately authorized Meshy rig/presets. `animation_ab_actor.gd` normalizes actual skinned rest bounds (important for Meshy's centimetre armature), while `animation_ab_clock.gd` explicitly distinguishes native timing, phase retiming and optional linear XZ cycle compensation. Raw Meshy output is retained, including its observed blade/leg weights; no silent weight repair or live enemy integration occurs. [A/B evidence, controls, exact 14-credit spend and limitations](warden-meshy-animation-ab.md) explain the comparison. `tools/meshy_animation_ab.py` is opt-in, fixed-budget authoring only; the normal verification/tests/game never contact Meshy.

The separately approved 90-credit pilot is in `scenes/prototypes/warden_pilot_preview.tscn`, with `warden_candidate_review.tscn` retaining the three untextured alternatives. The selected c02 body uses its own verified-compatible PBR atlas and five native Meshy clips. The accepted Iron Blade is an **unskinned separate scene** owned by a `RightHand` BoneAttachment; its top-level mount follows an orthonormal meter-scale hand frame so rig centimetres/shear cannot resize it. This is distinct from editing body weights or retargeting gameplay. [Pilot scope, raw hashes, calibration, controls and limits](warden-animation-ready-pilot.md) record the actual 90-credit completion, imperfect requested pose compliance, open-finger/pose limitations and 11,376 combined source-triangle prototype cost. `tools/meshy_warden_pilot.py` is plan-hashed/checkpointed opt-in authoring; `prepare_warden_candidates.py` / `prepare_warden_pilot.py` are offline copy/inspection tools. No extra paid attempt, Adept generation or live enemy replacement is authorized by these files.
