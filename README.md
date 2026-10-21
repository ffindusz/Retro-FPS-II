# Cinderkeep

An original, single-level dark-fantasy FPS prototype inspired by the atmosphere of early 3D fantasy shooters. Built with **Godot 4.7 stable and GDScript**, a **2D HUD**, and **real 3D first-person weapons**.

**Status: playable fortress-atmosphere 0.3 demo with six integrated Meshy.ai models.** Adds original tiled stone surfaces, warm/cool lighting with subtle torch flicker, sparse nonblocking dressing, and quiet wind/crypt ambience to the accepted combat-polish gameplay. Combat, collision, navigation, placements, models, and combat/pickup SFX are unchanged. The new atmosphere still needs human visual/listening approval; prior detailed/offline acceptance remains pending.

## Play

- Windows build: launch `builds/windows/Cinderkeep.exe`. Keep `Cinderkeep.pck` next to it.
- Editor: import `project.godot` with the standard Godot 4.7 editor, then press **F6** on `scenes/main.tscn` or **F5** to run the project.
- Or, from PowerShell in this folder:

```powershell
& .\Godot_v4.7-stable_win64.exe --path .
```

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

**Sound:** eleven locally authored effects are bundled. Enemy/world sounds are spatial; player attacks/hurt and pickups are local. Health plays a warm chime and arcana a brighter chime only when restoration succeeds; full-resource pickups stay silent and available. Key audio is unchanged. Use mouse or keyboard on the pause-menu SFX slider to adjust the mix. Its value persists across restarts in the current app session, not across app launches. Pausing stops one-shots; resume does not replay old sounds. No extra model generations or paid audio services were used.

**Atmosphere:** three original 512px stone surface families replace flat world colors, with low-relief doorway/pillar accents and ten reused urns. Six torches have smooth energy variation of at most ±8%; no new shadow-casting lights, collision or cover were added. Two original 20-second wind/crypt loops crossfade over about one second as you enter/leave the existing crypt. Their separate pause-menu volume defaults to 30% and persists within the session independently of SFX. Pause freezes their playback/blend; results/menu/restart dispose of old loops. Ambience mute does not mute combat or pickup sounds.

## Verify and build

```powershell
.\tools\verify.ps1
.\tools\verify.ps1 -Render
& .\Godot_v4.7-stable_win64_console.exe --headless --path . --script tools/bake_navigation.gd
New-Item -ItemType Directory -Force builds/windows
& .\Godot_v4.7-stable_win64_console.exe --headless --path . --export-release "Windows Desktop"
```

The render check briefly opens game windows and writes only the game's rendered viewport to `builds/validation/`. Re-bake navigation after changing solid level geometry. Windows export requires **4.7.stable** export templates (Editor → Manage Export Templates); templates are not required for editor play. The preset excludes authoring tools, tests, OpenSpec files, and generated validation output.

Packaged-resource regression checks (using the editor executable with the exported PCK):

```powershell
& .\Godot_v4.7-stable_win64_console.exe --headless --main-pack builds/windows/Cinderkeep.pck --script "$PWD/tests/run_tests.gd"
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

The first six-model API batch completed on 2026-10-20 for 90 credits and is now integrated, following the user's paid monthly plan confirmation. [Generation records](docs/meshy-generation.md) preserve source IDs/checksums; [the manifest](docs/asset-manifest.md) records rights and normalization. No additional generation credits were used for import. The melee result is more sword-like than the original cleaver prompt, so the HUD calls it **Iron Blade**; original asset IDs are retained for provenance. The urn's lid and torch's lower basket are accepted demo details.

The pre-polish user run took roughly five minutes and was described as easy. After combat polish the user reported that sounds are okay, melee is better, and difficulty is okay, then confirmed pickup audio works. That feedback is preserved, not treated as approval of the new atmosphere. Timing, detailed mix/control and offline native-build acceptance are still unreported. Enemies remain static meshes with procedural feedback; there is no skeletal animation, save/load, multiplayer, general settings screen, music or controller support. Original synthetic audio has technical tests, not a professional mastering claim. This is not a Hexen II remake and contains no Hexen II content.

For developer comparison, turn off **Atmosphere Enabled** on the main Cinderkeep session node (or set `DemoSession.atmosphere_enabled=false` before starting a run). This restores the pre-pass flat/static world with no ambience while retaining identical gameplay. It is a diagnostic toggle, not a player-facing graphics setting.
