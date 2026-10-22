# Cinderkeep

An original, single-level dark-fantasy FPS prototype inspired by the atmosphere of early 3D fantasy shooters. Built with **Godot 4.7.x and GDScript**, a **2D HUD**, and **real 3D first-person weapons**.

**Status: playable fortress-refinement 0.4.1 project with six integrated Meshy.ai models.** Adds an original bundled moonlit sky above the user-approved photographic stone, alongside two shadow-casting torches, bounded spell illumination and a unique ember-key chime. Collision, navigation, placements, combat tuning, models, the eleven accepted SFX and ambience are unchanged. General texture and sky appearance are user-approved; detailed seam and unreported lighting/audio review remain pending. A fresh 0.4.1 Windows export is blocked by missing matching 4.7.2 export templates on this machine; earlier package evidence is historical.

## Play

- Windows build: launch `builds/windows/Cinderkeep.exe`. Keep `Cinderkeep.pck` next to it. The existing older export does not include 0.4/0.4.1 changes; use editor/project play until matching templates allow re-export.
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
New-Item -ItemType Directory -Force builds/windows
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop"
```

The render check briefly opens game windows and writes only the game's rendered viewport to `builds/validation/`. Re-bake navigation after changing solid level geometry. Windows export requires templates matching the engine exactly (**4.7.2.stable** for the bundled executable; Editor → Manage Export Templates). Templates are not required for editor play. The preset excludes authoring tools, tests, OpenSpec files, and generated validation output.

Packaged-resource regression checks (using the editor executable with the exported PCK):

```powershell
& .\Godot_v4.7.2-stable_win64_console.exe --headless --main-pack builds/windows/Cinderkeep.pck --script "$PWD/tests/run_tests.gd"
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

The first six-model API batch completed on 2026-10-20 for 90 credits and is now integrated, following the user's paid monthly plan confirmation. [Generation records](docs/meshy-generation.md) preserve source IDs/checksums; [the manifest](docs/asset-manifest.md) records rights and normalization. No additional generation credits were used for import. The melee result is more sword-like than the original cleaver prompt, so the HUD calls it **Iron Blade**; original asset IDs are retained for provenance. The urn's lid and torch's lower basket are accepted demo details.

The pre-polish user run took roughly five minutes and was described as easy. After combat polish the user reported that sounds are okay, melee is better, and difficulty is okay, then confirmed pickup audio works. On 2026-10-22 the user confirmed the startup fix, completed a 0.3 walkthrough and said it looks good, while requesting better-matching textures, dynamic light and key audio. They subsequently approved the new textures ("textures are good"), requested the sky, and approved its appearance ("skybox looks good!"). This does not imply detailed seam checks or approval of unreported shadows/spell/key-audio details. Timing, detailed mix/control and offline native-build acceptance are still unreported. Enemies remain static meshes with procedural feedback; there is no skeletal animation, save/load, multiplayer, general settings screen, music or controller support. Original synthetic audio has technical tests, not a professional mastering claim. This is not a Hexen II remake and contains no Hexen II content.

For developer comparison, turn off **Atmosphere Enabled** on the main Cinderkeep session node (or set `DemoSession.atmosphere_enabled=false` before starting a run). This restores the pre-pass flat/static world without the sky, ambience, torch shadows or spell lights while retaining identical gameplay and key audio. It is a diagnostic toggle, not a player-facing graphics setting.
