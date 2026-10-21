# Asset manifest and credits

**Current runtime art status: six Meshy models integrated for the demo**, with procedural fallback visuals retained. The user confirmed a paid monthly Meshy subscription on 2026-10-20; the project's rights review applies the paid-output provision in [Meshy's September 19, 2026 terms, section 3.2](https://www.meshy.ai/terms-of-use). The review is based on the user's confirmation, not an independently inspected invoice. Inputs are original text prompts only, with no third-party reference uploads. Do not assert exclusive copyright or remove AI-origin metadata. See [generation records](meshy-generation.md) for exact prompts, task IDs, checksums, and actual cost (90 credits; last queried balance 1,380).

## Imported demo models

Each source is `assets/models/<id>/model.glb`, preserved byte-for-byte against its recorded SHA-256. Godot extracts `model_0.jpg`, `model_1.jpg`, and `model_2.jpg` alongside the source. Source textures are 2048×2048; all 18 checked-in texture import files use `process/size_limit=1024` with mipmaps. Scene import retains normal/tangent and PBR material support, generated LODs/shadow meshes, no generated gameplay collision, and scale 1 at import. Normalize only the imported child in the visual scene below. Default wrapper roots use `use_placeholder=false` and their corresponding `model_scene`.

| ID | Normalized visual scene | Triangles | Child transform (meters; yaw radians) | Status / review |
|---|---|---:|---|---|
| `weapon-cleaver` | `scenes/models/iron_blade.tscn` | 3,086 | scale 1; Y offset 0.28 | Demo model: sword-like result labeled **Iron Blade** in the HUD; grip/framing and swing reviewed in the 3D overlay |
| `weapon-staff` | `scenes/models/ember_staff.tscn` | 4,224 | scale 1.1; Y offset 0.25 | Demo model: cyan crystal, intact shaft; framing and fire feedback reviewed |
| `enemy-warden` | `scenes/models/warden.tscn` | 8,462 | scale 1.9; Y offset 0.90315; yaw PI | Demo model: feet at ground, about 1.81m overall, faces -Z; capsule/agent unchanged |
| `enemy-adept` | `scenes/models/adept.tscn` | 7,382 | scale 2.1; Y offset 0.99924; yaw PI | Demo model: feet at ground, about 2.00m including staff; blue robe/amber staff distinct; capsule/agent unchanged |
| `prop-torch` | `scenes/models/wall_torch.tscn` | 2,048 | scale 0.95; Y offset -0.33 | Demo model: flame near wrapper origin, independent light; walls orient the bracket inward; extra lower basket retained |
| `prop-urn` | `scenes/models/stone_urn.tscn` | 1,966 | scale 0.84; Y offset 0.3993 | Demo model: feet at ground, about 0.80m tall, nonblocking; generated lid retained |

Paid-plan output is recorded for these six generations; Meshy is credited as the authoring service without suggesting endorsement. The owner remains responsible for any separate account-specific agreement and final public-release review. No additional Meshy generations or purchases were made during integration.

## Procedural alternatives and other original assets

The fallback models/materials below are original primitive geometry and solid colors, not Meshy-generated content. Set the weapon/enemy/prop wrapper's `use_placeholder=true` to restore its fallback without changing collision or scripts. The project's overall source/distribution license remains the owner's decision.

| ID | Local wrapper/source | Origin and status | Import settings / attribution |
|---|---|---|---|
| `weapon-cleaver` | `scenes/weapons/melee_viewmodel.tscn`; `scripts/weapons/placeholder_weapon.gd` | Original procedural fallback | Grip-local visual root; no collision |
| `weapon-staff` | `scenes/weapons/magic_viewmodel.tscn`; same builder | Original procedural fallback | Separate first-person framing; no collision |
| `enemy-warden` | `scenes/enemies/melee_enemy.tscn`; `scripts/enemies/enemy.gd` | Original procedural fallback | Feet at Y=0; independent capsule/agent |
| `enemy-adept` | `scenes/enemies/ranged_enemy.tscn`; same builder | Original procedural fallback | Inherited wrapper with independent visual selection |
| `prop-torch` | `scenes/props/torch.tscn`; `scripts/props/placeholder_prop.gd` | Original procedural fallback | Flame-center origin, separate OmniLight, nonblocking |
| `prop-urn` | `scenes/props/urn.tscn`; same builder | Original procedural fallback | Ground origin, about 0.8 m tall, nonblocking |
| `pickup-health` | `scenes/props/pickup.tscn`; `scripts/pickup.gd`, kind 0 | Original procedural flask | Visual root independent of Area3D; red material |
| `pickup-mana` | Same wrapper, kind 1 | Original procedural flask | Blue material; same trigger, no downloaded textures |
| `pickup-key` | Same wrapper, kind 2 | Original procedural key | Gold material; same trigger |
| `magic-bolts` | `scenes/weapons/projectile.tscn`; `scripts/weapons/projectile.gd` | Original procedural spheres | Cyan player / amber enemy; swept queries, no mesh physics |
| `fortress` | `scripts/level.gd`; `scripts/primitive_art.gd` | Original fixed layout, boxes, labels, and stone/trim colors | Static box collision, generated `resources/demo_navigation.tres`; no copied map |
| `hud-and-menus` | `scripts/ui/interface.gd` | Original 2D layout and flat styles | Engine default font/theme; no downloaded fonts/icons |

## Required record for each future imported asset

For each imported model add: asset ID; local source/texture paths; author/source URL or Meshy generation/export identifier; source prompt/reference notes and generation date; account-plan/license evidence and attribution; reviewer's rights decision; triangle/texture counts; Godot import options; wrapper normalization transform; placeholder/final status; in-game review results. Use **unresolved** for unknown rights and exclude those assets from distributable builds.

## Original combat-polish audio and effects

`assets/audio/combat/` contains eleven original WAV effects authored locally by `tools/generate_combat_audio.gd`; [cue durations, synthesis parameters and provenance](../assets/audio/combat/README.md) are recorded alongside them. The 2026-10-21 follow-up adds distinct health/arcana pickup chimes while retaining the nine existing combat WAVs byte-for-byte. They are mono 22,050 Hz PCM16, peak at most 0.5, with short attack/release envelopes and zero-valued endpoints. Their `.import` settings preserve uncompressed PCM16 without normalization. No third-party sample, external audio-generation service, or additional Meshy credits were used. The owner chooses the overall distribution license for these original constructions.

Hit markers, screen-edge damage cues, and the short visual-only impact shards in `scripts/combat/impact_effect.gd` are original Godot UI/primitive constructions. Source Meshy GLBs and their normalization scenes are unchanged by this polish pass. The user approved the existing sounds generally and confirmed pickup sound works on 2026-10-21; unreported detailed listening/control checks remain pending. Technical resource/peak/event tests are not a listening review.

## Original fortress-atmosphere assets

- `assets/environment/{wall,floor,trim}_{albedo,roughness}.png`: six original 512×512 images authored by `tools/generate_fortress_assets.gd`; [seeds, patterns, mapping and imports](../assets/environment/README.md). Shared world-aligned materials use approximately two meters per tile, with repeat/mipmaps and modest area color variants. Iron/brass accents use solid-color shared materials. No downloaded texture or paid generation is involved.
- `assets/audio/ambience/{wind,crypt}.wav`: original 20-second mono 22,050 Hz PCM16 loops, seeds 7101/9103, source peaks at most .25, .75s overlap join, imported forward loops without normalization/compression. [Construction, mix and ownership](../assets/audio/ambience/README.md). Two run-owned players use the independent Ambience bus/control; no music or enemy-signaling audio is added.
- New doorway/pillar bands and key-floor inlay are original simple visual-only geometry. Six additional urn instances reuse the existing cleared model (ten urns total); torch/model sources and normalization remain unchanged. Thin accents do not cast redundant shadows over the existing solids.
- `docs/fortress-atmosphere-baseline.json` records original six GLB, eleven SFX and navigation-source hashes; offline tests compare all eighteen originals unchanged. `resources/atmosphere_baseline.tres` holds canonical gameplay fingerprints used in source/packaged tests.

The owner chooses the overall distribution license for these original constructions. Earlier combat/pickup approval does not approve new surface tiling, lighting/flicker comfort, ambience seams or mix; human atmosphere acceptance remains pending. There are no added third-party texture/audio attribution obligations from this pass.

## Credits and legal notes

- Engine: [Godot Engine](https://godotengine.org/), MIT licensed. Godot and its embedded third-party components retain their own licenses. See [Godot's license and third-party notices](https://godotengine.org/license/) and include the required notices when distributing engine binaries.
- Default UI font and engine-provided rendering/physics/navigation are distributed with Godot, not separately authored game assets.
- Meshy.ai: external authoring tool only; not a runtime dependency or an endorsement. Paid monthly subscription confirmed by the user; the project's generation-specific rights review is recorded above and in `docs/meshy-generation.md`.
- Hexen II is an atmosphere/style reference only. No names from its setting, models, layouts, textures, audio, or source code are bundled.
