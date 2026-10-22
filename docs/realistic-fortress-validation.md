# Fortress refinement 0.4 validation

## Scope and feedback

On 2026-10-22 the user confirmed the startup fix, completed a 0.3 walkthrough and said the demo looks good, but its stone does not match the more realistic enemies/weapons. They requested dynamic lighting and a special key sound, then approved free bundled CC0 photographic maps and limited torch shadows plus spell/projectile lights. This record covers the resulting `realistic-fortress-feedback` change, not retrospective approval of its new visuals/audio.

Gameplay geometry, canonical collider/placement/stat/navigation fingerprints, six source models, eleven accepted WAVs, original procedural textures and two ambience loops remain unchanged. The existing flat/static atmosphere-off diagnostic remains available, now also disabling the new torch shadows and spell lights. Key audio is independent of that developer toggle.

## Materials and lighting

- Six unchanged 1K maps from Poly Haven: Medieval Blocks 03 by Rob Tuytel for walls/trim (2m tiles), Monastery Stone Floor by Amal Kumar for floors (approximately 1.8m). Both are CC0; official download MD5 and local SHA-256 are recorded in `assets/environment/photographic/provenance.json`, with licensing/credit/import notes alongside it. No runtime download or paid generation occurs.
- Shared world-aligned color/roughness/OpenGL normal maps use mipmaps, 1024px import caps and normal strength 0.4. Trim reuses wall images. The original six 512px procedural assets and authoring workflow remain intact.
- Exactly two existing torches cast shadows: the courtyard's west-wall torch and crypt's east-wall torch. Their emitter meshes cannot self-occlude the lights. All six light transforms, seven-meter ranges and slow eight-percent flicker bounds remain unchanged; ambient readability and the Compatibility renderer are retained.
- Run-owned combat presentation shares at most six short-range shadowless lights: 0.16-second fading cast/impact flashes and projectile-attached illumination. Saturation cannot reject a spell or alter damage/cost. Pause freezes ages; actual wall contact/expiry removes projectile lights; results/menu/restart clear all records, including already-freed projectile children.

## Key audio

`pickup_key.wav` is one original 0.85-second local bell arpeggio/chord, authored only through the existing offline generator. Existing eleven WAV hashes still match the baseline. Successful first key ownership publishes a pickup-specific event; consumed/already-owned/enemy/paused/dead attempts do not sound. Event deduplication, the existing SFX slider/mute/12-voice cap and one-shot cleanup apply. Muted collection still grants the key without queued playback. The sound outlives the collected pickup and produces no combat hit marker/effect.

## Technical evidence

- Source regression: **263 checks, 0 failures**. Offline asset/tool suite: **12 tests pass**, including photographic file hashes/imports and all original model/audio/navigation checks.
- Navigation's Git blob exactly matches the baseline hash. Windows checked it out with CRLF, so its offline text-resource hash check now normalizes only CRLF to LF; binary models/WAVs still use exact original bytes. No navigation data or baseline expected hash was changed.
- Temporarily disabling normal mapping, torch shadows, spell lights and key sound caused **19 focused failures**; restoring implementation returned all checks to green. A rendered result/restart pass also exposed stale freed projectile-light records; the cleanup regression fails without pruning those records and passes with the fix.
- Rendered 1280x720/1920x1080 HUD/menu/combat checks pass with no script/runtime errors. Matching six-view captures and short profiles are in `builds/validation/realistic-before/` and `realistic-after/`; active cast/projectile illumination is captured by `spell-light-1280.png` and `spell-light-1920.png`. These controlled frames are not a human gameplay/listening review.
- Normal project startup and keyboard Start/Resume checks pass. A fresh checkout or new asset pull requires the documented editor import before direct launch.

## Same-machine short comparison

Godot **4.7.2.stable.official.ed1daf0bf**, Compatibility/OpenGL 3.3, **AMD Radeon (TM) Graphics**, driver reported as 23.19.16.08.250418. This is not the earlier GTX 1060 reference PC. Same fixed courtyard camera, frozen actors, deterministic torch phase, vsync disabled and roughly two seconds per resolution:

| Resolution | 0.3 mean ms | 0.4 mean ms | Observed delta | Draw calls before/after | 0.4 observed frames/s |
|---|---:|---:|---:|---:|---:|
| 1280x720 | 4.171 | 4.760 | +0.589ms (~14%) | 244 / 313 | 210.07 |
| 1920x1080 | 7.310 | 9.662 | +2.353ms (~32%) | 243 / 310 | 103.50 |

The bounded two-shadow-light pass has a measurable cost, especially at 1080p; it is not free. These are short view samples, not minimum-FPS guarantees, whole-run benchmarks or saturated-spell performance claims. Integrated/other GPUs and sustained combat still need human review.

## Windows delivery blocker and acceptance

This machine has the Godot 4.7.2 executables but no matching `4.7.2.stable` export templates. No new 0.4 EXE/PCK was produced or tested; old 0.3 packaged evidence must not be relabeled. The 0.4 project runs locally without templates. Install matching templates through the editor before exporting with the updated preset, then run packaged-resource and native/offline checks.

- [x] General photographic texture approval: the user's follow-up says "textures are good", then requests a skybox.
- [ ] Detailed scale/normal-relief review, shadow readability/comfort, spell brightness and actual gameplay performance.
- [ ] Human listening approval of the unique key chime and SFX/ambience balance.
- [ ] Updated timing/difficulty, zero-mana route, pause/results/restart/menu and offline native-build acceptance with tested hardware/resolution.

Earlier active changes retain their unreported acceptance tasks. This change is implemented but not archived or declared fully human-accepted.

## Moonlit fortress 0.4.1 follow-up

The requested sky adds one original static 1024x512 RGB PNG (137,504 bytes), authored entirely offline with spherical cloud noise, sparse seeded stars and a moon. Its generator, seed and SHA-256 are in `assets/environment/sky/provenance.json`; re-running the generator on the installed engine reproduces the PNG byte-for-byte. No external download, paid generation, runtime authoring, new light or geometry is introduced. Existing stone/model materials and audio remain unchanged.

Each normal run owns a Sky/PanoramaSkyMaterial, sharing the bundled image. Explicit color ambient (0.42, `9eacbd`), moon (0.8, `a6bddd`, rotation -55/-30/0), torch behavior and the 0.85 weapon-viewport ambient remain unchanged. Sky reflections are explicitly disabled. The smallest radiance cache and static quality processing are used; pause introduces no animation, restart disposes the old world, and atmosphere-off retains its previous flat background with no sky.

- `tools/verify.ps1 -Render` passes editor import, normal startup, **269 source checks** and both-resolution rendered checks, without script/runtime errors. All **13 offline asset/tool tests pass**. The existing gameplay/model/audio/navigation baseline checks remain green.
- Disabling only `BG_SKY` produces **one focused source failure** and **two rendered moon failures**. Restoring it returns all checks to green. The rendered test also caught incorrect longitude orientation during authoring; the final moon is centered when the camera looks along the existing directional light's positive Z.
- Inspected `builds/validation/sky-courtyard-{1280,1920}.png` and `sky-moon-{1280,1920}.png`: cloudy night background above the unchanged fortress and moon facing the light source at 1280x720/1920x1080. Moon captures temporarily hide the HUD; these are controlled game-viewport views, not desktop captures or human acceptance.
- Previous 0.4 performance numbers above remain historical; no new whole-run performance or packaged/offline claims are made. Matching `4.7.2.stable` export templates are still absent, so **no new 0.4.1 Windows EXE/PCK** was delivered. Editor/project play includes the sky.

- [x] General sky appearance approved on 2026-10-22: "skybox looks good!"
- [ ] Detailed human seam review while looking around the actual level.

The photographic textures and general sky appearance now have user approval. No separate manual seam check was reported. Earlier unreported lighting/key-audio/detailed/offline acceptance remains open.
