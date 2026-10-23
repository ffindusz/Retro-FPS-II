# Asset manifest and credits

**Current runtime art status: original six Meshy sources preserved; 0.5.0 replaces the default melee visual with the approved animated Brigandine Warden**, retaining procedural fallback. The user confirmed a paid monthly Meshy subscription on 2026-10-20; the project's rights review applies [Meshy's September 19, 2026 terms, section 3.2](https://www.meshy.ai/terms-of-use), based on that confirmation rather than an inspected invoice. Inputs were original text only, without third-party reference uploads. Do not assert exclusive copyright or remove AI-origin metadata. [Initial generation records](meshy-generation.md) cover the original 90-credit batch (historical balance 1,380). Later A/B and pilot costs and the authorized runtime adoption are recorded separately below.

## Imported demo models

Each source is `assets/models/<id>/model.glb`, preserved byte-for-byte against its recorded SHA-256. Godot extracts `model_0.jpg`, `model_1.jpg`, and `model_2.jpg` alongside the source. Source textures are 2048×2048; all 18 checked-in texture import files use `process/size_limit=1024` with mipmaps. Scene import retains normal/tangent and PBR material support, generated LODs/shadow meshes, no generated gameplay collision, and scale 1 at import. Normalize only the imported child in the visual scene below. Default wrapper roots use `use_placeholder=false` and their corresponding `model_scene`.

| ID | Normalized visual scene | Triangles | Child transform (meters; yaw radians) | Status / review |
|---|---|---:|---|---|
| `weapon-cleaver` | `scenes/models/iron_blade.tscn` | 3,086 | scale 1; Y offset 0.28 | Demo model: sword-like result labeled **Iron Blade** in the HUD; grip/framing and swing reviewed in the 3D overlay |
| `weapon-staff` | `scenes/models/ember_staff.tscn` | 4,224 | scale 1.1; Y offset 0.25 | Demo model: cyan crystal, intact shaft; framing and fire feedback reviewed |
| `enemy-warden` | `scenes/models/warden.tscn` | 8,462 | scale 1.9; Y offset 0.90315; yaw PI | Preserved static reference and frozen 0.4.1 visual; no longer the default melee model in 0.5.0 |
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

`assets/audio/combat/` contains twelve original WAV effects authored locally by `tools/generate_combat_audio.gd`; [cue durations, synthesis parameters and provenance](../assets/audio/combat/README.md) are recorded alongside them. The 2026-10-21 follow-up added health/arcana pickup chimes while retaining the nine existing combat WAVs byte-for-byte. The 2026-10-22 follow-up adds only the 0.85-second `pickup_key.wav` bell chord, preserving all eleven accepted cues. They are mono 22,050 Hz PCM16, peak at most 0.5, with short attack/release envelopes and zero-valued endpoints. Their `.import` settings preserve uncompressed PCM16 without normalization. No third-party sample, external audio-generation service, or additional Meshy credits were used. The owner chooses the overall distribution license for these original constructions.

Hit markers, screen-edge damage cues, and the short visual-only impact shards in `scripts/combat/impact_effect.gd` are original Godot UI/primitive constructions. Source Meshy GLBs and their normalization scenes are unchanged by this polish pass. The user approved the existing sounds generally and confirmed pickup sound works on 2026-10-21; unreported detailed listening/control checks remain pending. Technical resource/peak/event tests are not a listening review.

## Original fortress-atmosphere 0.3 assets

- `assets/environment/{wall,floor,trim}_{albedo,roughness}.png`: six original 512×512 images authored by `tools/generate_fortress_assets.gd`; [seeds, patterns, mapping and imports](../assets/environment/README.md). Shared world-aligned materials use approximately two meters per tile, with repeat/mipmaps and modest area color variants. Iron/brass accents use solid-color shared materials. No downloaded texture or paid generation is involved.
- `assets/audio/ambience/{wind,crypt}.wav`: original 20-second mono 22,050 Hz PCM16 loops, seeds 7101/9103, source peaks at most .25, .75s overlap join, imported forward loops without normalization/compression. [Construction, mix and ownership](../assets/audio/ambience/README.md). Two run-owned players use the independent Ambience bus/control; no music or enemy-signaling audio is added.
- New doorway/pillar bands and key-floor inlay are original simple visual-only geometry. Six additional urn instances reuse the existing cleared model (ten urns total); torch/model sources and normalization remain unchanged. Thin accents do not cast redundant shadows over the existing solids.
- `docs/fortress-atmosphere-baseline.json` records original six GLB, eleven SFX and navigation-source hashes; offline tests compare all eighteen originals unchanged. `resources/atmosphere_baseline.tres` holds canonical gameplay fingerprints used in source/packaged tests.

The owner chooses the overall distribution license for these original constructions. The user completed a 0.3 walkthrough and said it looks good but requested better-matching textures and dynamic lighting; unreported detailed ambience/control/offline checks remain pending. There were no added third-party texture/audio attribution obligations from that original pass.

## CC0 photographic fortress-refinement 0.4 textures

The default world now uses six unchanged 1024px JPEG downloads from [Poly Haven](https://polyhaven.com/), replacing the original procedural maps in the shared runtime material mapping while preserving their files. The user explicitly approved downloading and bundling free CC0 photographic PBR textures on 2026-10-22.

| Asset | Author | Local maps | Physical tile |
|---|---|---|---|
| [Medieval Blocks 03](https://polyhaven.com/a/medieval_blocks_03) | Rob Tuytel | `assets/environment/photographic/wall_{albedo,normal,roughness}.jpg`; shared by walls/trim | 2m |
| [Monastery Stone Floor](https://polyhaven.com/a/monastery_stone_floor) | Amal Kumar | `assets/environment/photographic/floor_{albedo,normal,roughness}.jpg` | Approximately 1.8m |

License: **CC0-1.0**, verified against [Poly Haven's official licensing page](https://polyhaven.com/license); [CC0 dedication](https://creativecommons.org/publicdomain/zero/1.0/). Redistribution/commercial use is permitted without mandatory attribution; authors are credited here voluntarily. Exact source/download URLs, official MD5 and verified local SHA-256 are in [the provenance manifest](../assets/environment/photographic/provenance.json). [Import/mapping details](../assets/environment/photographic/README.md) include mipmaps, the 1024px cap, unflipped OpenGL normals and shared physical world scale. Only the texture assets, not protected website content, are bundled.

New torch shadows and bounded cast/impact/projectile lights are original Godot presentation logic, not new downloaded models. No Meshy generation, paid service or runtime network dependency was added. The user subsequently approved the photographic textures ("textures are good"); detailed shadow/spell-light/key-audio acceptance remains pending.

## Original moonlit fortress 0.4.1 sky

`assets/environment/sky/moonlit_fortress.png` is one original 1024x512 RGB panorama with seeded spherical clouds, sparse stars and a moon aligned with the existing directional light. It was authored locally by `tools/generate_fortress_sky.gd`, with no external image, paid generation or runtime network dependency. [Parameters and SHA-256](../assets/environment/sky/provenance.json) and [generation/import/mapping details](../assets/environment/README.md) accompany it. Mipmaps and a 1024px import cap apply. The panorama is background-only: explicit color ambient, existing lights and isolated weapon lighting are unchanged, with sky reflections disabled. The owner chooses the distribution license for this original construction; no new third-party attribution is required. The user approved its general appearance on 2026-10-22 ("skybox looks good!"); a separate manual seam check remains unreported.

## Developer-only Warden skeletal derivative

`assets/prototypes/warden-rig/warden_rig.glb` is a separate, locally rigged derivative of the unchanged `enemy-warden` Meshy source. Its original AI origin/paid-plan review above remains applicable; local rigging does not remove that provenance or imply exclusive rights. The user authorized portable Blender LTS/local-only rigging on 2026-10-22. No model-generation credits, rigging service, uploads or new textures were used.

The derivative preserves 7,327 render vertices, 8,462 triangles and UV inventory, adds 21 bones with normalized weights/rigid weapon attachment, and contains Idle/Walk/Attack clips. It embeds no images; the isolated Godot preview reuses the original accepted material/1K textures. Source/derived/tool hashes and region/clip details are in `assets/prototypes/warden-rig/provenance.json`; the generated editable `.blend` is in ignored `builds/authoring/warden-rig/`. [Authoring, validation and limitations](warden-rig-prototype.md) describe its technical-prototype status. It is excluded from normal exports and is not part of the accepted 0.4.1 game or portable ZIP. No new project-wide asset license or human deformation approval is inferred.

## Developer-only Meshy Warden animation comparison

On 2026-10-23 the user explicitly authorized uploading the unchanged original textured Warden and spending at most 14 credits on one rig plus Idle (`0`), Walk Fight Forward (`21`) and Right-hand Sword Slash (`219`). Both tasks succeeded for **14 credits total**, no paid retries; balance 1,380 → 1,366. The raw combined character/animation GLB is preserved byte-for-byte at `assets/prototypes/warden-meshy-ab/animations.glb`, SHA-256 `0eff67371db54cd5589088df9a87a82a2f73b52915516dd48cc010b7383b6e20`; sanitized task/charge/download/source provenance is alongside it. Original rig/combined exports and checkpoint are retained in external staging and ignored authoring backup.

This variant has 24 bones, the same 7,327-vertex/8,462-triangle geometry count and original UV/albedo inventory. The A/B presentation reuses the original PBR material/1K textures after compatibility checks; no raw output metadata or weights are removed. The result's blade has leg-related weights, which is an observed quality limitation, not a repaired/final asset. The original source/local rig and accepted game/ZIP remain unchanged; all comparison assets/scenes/scripts are excluded from exports.

The prior paid-plan confirmation and Meshy's 2026-09-19 terms sections 2.4/3.1/3.2 are the review basis. Preset animations are **Service Assets licensed as incorporated in Customer Output**, not newly claimed as exclusively owned standalone motions. AI origin and generation/rigging provenance remain explicit. No public distribution, legal guarantee or human animation approval is inferred. [Full comparison, rights context, findings and evidence](warden-meshy-animation-ab.md).

## Animation-ready Warden pilot (historical authoring phase)

The user authorized the separate 90-credit Meshy 7.1 pilot on 2026-10-23 and selected **c02 Brigandine guard** after viewing three actual untextured previews. All six planned stages succeeded: three previews (60), one selected PBR texture (10), rig (5), and five presets (15); no extra paid retries. Reported balance 1,366 → 1,276. Original text-only prompts/pose/geometry/cost/action scope are in `docs/warden-pilot-plan.json`. The requested strict A-pose was not fully delivered (bent elbows); unwanted horns/other variants were not hidden or regenerated.

Raw candidate/texture/rig/five-clip files and sanitized checkpoints are retained in external staging and ignored authoring backup. Reviewed copies/provenance are under excluded `assets/prototypes/warden-pilot/`; no raw AI metadata is stripped. The selected body is 8,290 triangles with 24 bones and Idle/Walk/Attack/Hit/Death clips. Texture and animation exports differ in render-vertex splits (14,933 / 15,174); matching triangle UVs/albedo verify that selected full PBR maps may be reused in the animated preview at 1K runtime limits. No source model is replaced.

The weapon is the unchanged accepted `scenes/models/iron_blade.tscn` / `assets/models/weapon-cleaver/model.glb`, attached as a separate unskinned hand-following object. It is not part of the generated body's skin and cannot inherit leg skin weights. Combined maximum source geometry is **11,376 triangles** (body 8,290 + blade 3,086), an explicitly unaccepted production-budget/performance exception in this prototype. Finger grip, pose clipping, body deformation and gameplay timing remain review/integration tasks. [Complete pilot evidence, raw hashes, calibration and limitations](warden-animation-ready-pilot.md).

Prior paid-plan confirmation and terms sections 2.4/3.1/3.2 are the rights-review basis; library Service Assets are licensed within character output, not new exclusive standalone animation rights. No public release, legal guarantee, full visual approval, Adept generation or accepted EXE/PCK/ZIP replacement is inferred.

## Runtime animated Warden 0.5.0

The user subsequently approved the selected body's appearance/animations, requested a sword-mount correction and authorized using it in gameplay. Unchanged `animate.glb`/`texture.glb` copies and runtime-specific provenance now live in `assets/models/warden-animated/`; `scenes/models/warden_animated.tscn` is the default melee visual. The original prototype assets/provenance and static Warden remain preserved. Full PBR maps use four 1K mipmapped imports. No new API requests, credentials or credits were used for adoption.

Body 8,290 + original blade 3,086 = **11,376 maximum source triangles**, now an explicit **integration guideline exception**, not a performance promise. The shared corrected mount places the actual dark-leather centre into the palm; the preliminary pommel-based measurement was corrected through viewport inspection. Gameplay remains authoritative and unchanged; open fingers, foot planting and pose intersections remain limits. New 0.5.0 source/package checks pass; after handoff the user reported "works fine", confirming the integrated version generally works without separately reporting detailed grip/gait/offline checks. [Calibration, hashes, timing, evidence and separate Windows handoff](warden-runtime-integration.md). Rights context is inherited from the pilot above; new adjacent build credits preserve AI origin and incorporated Service Asset notices.

## Credits and legal notes

- Engine: [Godot Engine](https://godotengine.org/), MIT licensed. Godot and its embedded third-party components retain their own licenses. See [Godot's license and third-party notices](https://godotengine.org/license/) and include the required notices when distributing engine binaries.
- Default UI font and engine-provided rendering/physics/navigation are distributed with Godot, not separately authored game assets.
- Meshy.ai: external authoring tool only; not a runtime dependency or an endorsement. Paid monthly subscription confirmed by the user; the project's generation-specific rights review is recorded above and in `docs/meshy-generation.md`.
- Hexen II is an atmosphere/style reference only. No names from its setting, models, layouts, textures, audio, or source code are bundled.
