# Cinderkeep

An original, single-level dark-fantasy FPS prototype inspired by the atmosphere of early 3D fantasy shooters. Built with **Godot 4.7.x and GDScript**, a **2D HUD**, and **real 3D first-person weapons**.

**Status: user-confirmed working animated-Warden 0.5.0 integration ("works fine").** The four melee Wardens now use the approved Brigandine body and five native animations, with a corrected rigid sword grip and unchanged combat/encounter rules. Adepts and procedural fallback are unchanged. Verification passes **459 source checks**, **81 offline Python tests** and **311 packaged checks**; package audit and native startup/menu rendering pass. The user-confirmed **0.4.1 EXE/PCK/ZIP are preserved separately**. This is general integrated-build confirmation; detailed grip/gait/transition checks and a full disconnected native playthrough remain unreported. [Integration, evidence and known limits](docs/warden-runtime-integration.md).

## Play

**Optional comparison preview:** run `scenes/prototypes/warden_pilot_preview.tscn` with **F6** to compare the old static Warden and selected body. It shares the corrected grip, but the prototype scene/code/assets remain excluded from exports; the game uses independent runtime resources. [Pilot history and controls](docs/warden-animation-ready-pilot.md).

- **Current Windows build:** launch `builds/windows-0.5.0/Cinderkeep.exe` and keep `Cinderkeep.pck` next to it. No editor or export templates are required. It retains the photographic stone, dynamic lighting, key chime and moonlit sky.
- **Frozen accepted baseline:** `builds/windows/Cinderkeep.exe` or extract `builds/releases/Cinderkeep-0.4.1-windows-x64.zip`. These intentionally retain the old static enemies. [Packaging and validation](docs/release-packaging.md).
- Editor: import `project.godot` with the standard Godot 4.7.x editor (currently bundled: 4.7.2), then press **F6** on `scenes/main.tscn` or **F5** to run the project.
- Or, from PowerShell in this folder:

```powershell
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import
& .\Godot_v4.7.2-stable_win64.exe --path .
```

Run the first command on a fresh checkout, after deleting `.godot`, or when pulling new assets, and wait for it to finish before launching. It imports assets and registers the GDScript classes; without it, the menu can appear with nonworking buttons because the session script fails to load. Use executable names matching your installed Godot 4.7.x version.

The build directory is generated/ignored; rebuild if it is not present. No .NET, plugins, Meshy account, or network connection is required to play.

## Controls and objective

| Action | Input |
|---|---|
| Move / look | WASD / mouse |
| Jump | Space |
| Attack (hold to repeat) | Left mouse |
| Iron blade / ember staff | 1 / 2 |
| Interact with gate | E, nearby |
| Pause / resume | Escape |
| Combat sound volume / mute | SFX slider in pause menu; zero mutes |
| Environmental sound volume / mute | Independent Ambience slider in pause menu |
| Menu navigation / activate | Tab or arrows / Enter or Space |

Leave the safe entrance, cross the courtyard, and enter the crypt through the eastern opening. Find the gold **ember key**, then return to the sealed gate in the courtyard's northeast corner and press **E**. Red flasks restore health; blue flasks restore arcana. Full-resource flasks remain on the ground. The iron blade costs no mana; eliminating every enemy is not required. Defeat and victory both offer a clean restart.

**Melee:** get close and swing toward the enemy. Contact now sweeps an 80° frontal arc within 2.7m during the visible stroke, rather than hitting instantly along the crosshair. A swing has .12s preparation, .16s contact, and .24s recovery; holding LMB repeats after recovery. Weapon changes requested during a swing take effect when recovery ends. A gold crosshair hit marker confirms actual enemy damage; wall sparks/clangs do not. Nonlethal hits no longer cancel enemy windups—use cover, movement, or a lethal hit to avoid the committed attack.

**Sound:** twelve locally authored effects are bundled. Enemy/world sounds are spatial; player attacks/hurt and pickups are local. Health plays a warm chime and arcana a brighter chime only when restoration succeeds; full-resource pickups stay silent and available. First successful key collection plays a distinct 0.85-second ascending magical bell chord. It respects SFX mute/volume and cannot replay on duplicate collection. Use mouse or keyboard on the pause-menu SFX slider to adjust the mix. Its value persists across restarts in the current app session, not across app launches. Pausing stops one-shots; resume does not replay old sounds. No extra model generations or paid audio services were used.

**Atmosphere:** an original static night panorama adds cloud bands, sparse stars and a moon aligned with the existing moonlight. It is bundled offline and supplies no extra ambient lighting or reflections. Two CC0 photographic 1K stone sets supply shared wall/trim and floor color, roughness and OpenGL normal maps at physical tile scales. Six torches retain smooth energy variation of at most ±8%; one courtyard and one crypt torch now cast shadows. Casts, impacts and projectiles share at most six short-range shadowless lights. No collision, cover or gameplay rules change. Existing dressing and ten urns remain. Two original 20-second wind/crypt loops crossfade over about one second as you enter/leave the crypt. Their separate pause-menu volume defaults to 30% and persists within the session independently of SFX. Pause freezes playback/blend and dynamic-light aging; results/menu/restart clean up old presentation. Ambience mute does not mute combat or pickup sounds.

## Verify and build

```powershell
.\tools\verify.ps1
.\tools\verify.ps1 -Render
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/bake_navigation.gd
New-Item -ItemType Directory -Force builds/windows-0.5.0
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop"
```

The render check briefly opens game and Warden-preview windows and writes only their rendered viewports to `builds/validation/`. Verification covers the original game, runtime Warden and isolated prototypes. Only the original game and runtime Warden suites apply to exported resources; prototype paths stay excluded. Re-bake navigation only after changing solid level geometry (not needed for this visual integration). Windows export requires matching **4.7.2.stable** templates (Editor → Manage Export Templates); installed templates are not bundled in the repository. The preset writes to the separate 0.5.0 folder and excludes authoring tools, tests, OpenSpec files, generated validation output and developer prototypes. Do not export over the frozen 0.4.1 files.

Packaged-resource regression checks (using the editor executable with the exported PCK):

```powershell
& .\Godot_v4.7.2-stable_win64_console.exe --headless --main-pack builds/windows-0.5.0/Cinderkeep.pck --script "$PWD/tests/run_tests.gd"
& .\Godot_v4.7.2-stable_win64_console.exe --headless --main-pack builds/windows-0.5.0/Cinderkeep.pck --script "$PWD/tests/test_runtime_warden.gd"
```

Release executables do not support the editor's external `--script` test override; do not mistake an idle main menu for completed tests.

## Project map

- `scripts/session.gd`: menu/play/pause/defeat/victory transitions and fresh-run ownership.
- `scenes/player/`, `scripts/player.gd`: collision-based first-person player.
- `scenes/weapons/`, `scripts/weapons/`: 3D viewmodels, attacks, resources, and swept projectiles.
- `scenes/enemies/`, `scripts/enemies/`: shared melee/ranged enemy state machine.
- `scripts/level.gd`: fixed authored fortress layout, navigation, encounters, and key/exit progression.
- `scenes/props/`: replaceable decorative/pickup wrapper scenes.
- `assets/models/`, `scenes/models/`: original Meshy exports, texture import settings, and visual-only normalization.
- `scripts/ui/interface.gd`: signal-driven 2D HUD and keyboard/mouse menus.
- `scripts/combat/`, `assets/audio/combat/`: confirmed-hit events, bounded impact effects, and run-owned SFX playback.
- `scripts/environment/`, `assets/environment/`, `assets/audio/ambience/`: shared world materials/dressing, deterministic lighting, gameplay fingerprints, and two run-owned ambience loops.
- `tests/`: automated regression, viewport rendering, and short profiling scripts.

## Art, validation, and limitations

- [Meshy model workflow and prompts](docs/model-workflow.md)
- [Asset manifest and credits](docs/asset-manifest.md)
- [Development/physics conventions](docs/development.md)
- [Recorded validation and remaining manual checks](docs/validation.md)
- [Combat-polish baseline, placements, tests, and listening/playtest checklist](docs/combat-polish-validation.md)
- [Atmosphere baseline, before/after comparison, checks, and review checklist](docs/fortress-atmosphere-validation.md)
- [Photographic stone, dynamic lighting, key audio and current delivery evidence](docs/realistic-fortress-validation.md)
- [Portable release ZIP, notices, pinned hashes and packaging checks](docs/release-packaging.md)
- [Developer-only Warden motion study, controls and rigging limitations](docs/warden-motion-study.md)
- [Local Warden skeletal rig, editable source, preview controls and review limits](docs/warden-rig-prototype.md)
- [Actual local/Meshy animation A/B, 14-credit result, controls and observed sword-binding issue](docs/warden-meshy-animation-ab.md)
- [Selected animation-ready Warden pilot, 90-credit result, five clips and separate rigid blade](docs/warden-animation-ready-pilot.md)
- [Runtime Warden 0.5.0: corrected grip, state timing, validation and Windows handoff](docs/warden-runtime-integration.md)

The first six-model API batch completed on 2026-10-20 for 90 credits and is now integrated, following the user's paid monthly plan confirmation. [Generation records](docs/meshy-generation.md) preserve source IDs/checksums; [the manifest](docs/asset-manifest.md) records rights and normalization. No additional generation credits were used for import. The melee result is more sword-like than the original cleaver prompt, so the HUD calls it **Iron Blade**; original asset IDs are retained for provenance. The urn's lid and torch's lower basket are accepted demo details.

The pre-polish user run took roughly five minutes and was described as easy. The user subsequently approved combat/pickup audio, melee, difficulty, textures and sky, then confirmed project/native 0.4.1 playability ("did the playtest - works", "build works!"). On 2026-10-23 they approved the new Warden's look/animations, requested a sword-mount adjustment and authorized gameplay integration. After the 0.5.0 handoff they reported "works fine": general integration confirmation, not a separately reported detailed grip check or complete offline run. The Warden now has skeletal animation; the Adept retains static procedural feedback. Open fingers, native foot sliding and pose intersections remain limits; the combined 11,376 source triangles exceed the original ~10k guideline. There is no save/load, multiplayer, general settings screen, music or controller support. Synthetic audio is not professionally mastered. This is not a Hexen II remake and contains no Hexen II content.

For developer comparison, turn off **Atmosphere Enabled** on the main Cinderkeep session node (or set `DemoSession.atmosphere_enabled=false` before starting a run). This restores the pre-pass flat/static world without the sky, ambience, torch shadows or spell lights while retaining identical gameplay and key audio. It is a diagnostic toggle, not a player-facing graphics setting.
