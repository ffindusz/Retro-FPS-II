# Validation record

This preserves the original demo/model-integration baseline and the user's pre-polish feedback. Combat-polish 0.2/0.2.1 behavior, **196-check** latest results, audio provenance, revised placements, historical performance sample, and the user's positive polish/pickup-sound feedback are recorded separately in [combat-polish validation](combat-polish-validation.md). Unreported detailed/offline acceptance remains pending.

Historical **fortress-atmosphere 0.3** source/package evidence includes **233 gameplay/presentation checks** and **11 asset/tool tests**; matching before/after views, unchanged-source/gameplay fingerprints and lighting/ambience evidence are in [fortress-atmosphere validation](fortress-atmosphere-validation.md). The **fortress-refinement 0.4 project** recorded **263 source checks** and **12 asset/tool tests**, photographic CC0 stone, bounded dynamic lighting and key audio. The latest **0.4.1 moonlit-sky project** has **269 source checks** and **13 asset/tool tests**, plus passing courtyard/moon renders at 720p/1080p; [current evidence, texture approval and the missing matching-template export blocker](realistic-fortress-validation.md) are recorded separately. Older package/performance observations below are not relabeled as 0.4/0.4.1 results or approval.

## Scope and machine

- Date: 2026-10-20.
- Editor/templates: Godot **4.7.stable.official.5b4e0cb0f**, standard GDScript build; Windows 4.7.stable x86-64 release templates.
- OS: Microsoft Windows 10 Home, 10.0.19045.
- CPU: Intel Core i3-8100 @ 3.60 GHz.
- GPU: NVIDIA GeForce GTX 1060 6GB; OpenGL 3.3, NVIDIA driver 582.66; Compatibility renderer.
- Render checks: 1280×720 and 1920×1080. HUD and weapon overlay share the logical canvas aspect, with `canvas_items` scaling; the overlay renders at the logical canvas resolution and scales with the HUD.
- Asset status: **six Meshy models integrated and reviewed**, with original procedural fallbacks. The user confirmed a paid monthly plan; source provenance, terms review, transforms, geometry counts, and original checksums are in `docs/asset-manifest.md` and `docs/meshy-generation.md`.

## Completed automated checks

- Headless editor import and main-scene smoke launch: pass, no script/resource errors.
- `tests/run_tests.gd`: **104 checks, 0 failures** against source resources and again against the updated Windows PCK loaded with the matching editor engine. The original 77 checks cover keyboard menu activation/focus, floor/wall/diagonal/jump behavior, health/mana bounds, single-hit melee, range/occlusion, cooldown switching, shot costs, projectile wall/owner/impact/expiry rules, both enemy windups and navigation, death cancellation, useful-only pickups, key/exit gating, pause timers, terminal guards, and repeated fresh runs. The additional 27 checks cover all six imported visuals, no visual gameplay collision, loaded material/texture limits, enemy/urn normalization, and working procedural alternatives.
- Python authoring-tool and GLB-inspection safety tests: **8 tests pass**, with no API requests or credits used by those tests.
- Navigation: 80 baked polygons; connected entrance → crypt key → exit paths. Both enemy types move around test cover. Navigation updates are asynchronous, so tests wait for an active region before querying paths.
- `tests/render_check.gd`: pass; saved game-only viewport images in `builds/validation/`. Reviewed the updated menu, imported iron blade/staff and swing, both front-facing enemies and their windup/death presentation, torch/urn placement in the actual level, a near-wall weapon view, 1080p resize, pause, victory, and defeat. HUD bounds, logical weapon viewport size, and capture/release are checked. Controlled render views reposition actors and use scripted damage; they are not a substitute for a full human gameplay pass.
- Windows release export: rebuilt `builds/windows/Cinderkeep.exe` and `Cinderkeep.pck` with all six models and 1024px runtime textures. Authoring/tests/validation files and `.env` files are excluded explicitly. The updated native executable completes a headless `--quit-after 10` startup smoke with exit code 0 and no stderr output. A full interactive offline native-binary acceptance run remains pending.
- Release `--script` overrides are unsupported: the first attempt only opened the menu and was not counted as a test pass. Packaged-resource tests were instead run using the editor executable's `--main-pack` option.

No game code contains networking, account access, or remote asset fetching. Tests did not disable the machine's network; an explicitly disconnected native-build playthrough is still pending.

## Short profiling sample

`tests/profile_demo.gd`, fixed courtyard view, active enemies, vsync disabled, 30 warmup frames followed by approximately 3 seconds per resolution, original placeholders:

| Resolution | Mean observed frame ms | Mean observed frame rate | Longest sampled frame ms | Draw calls / primitives |
|---|---:|---:|---:|---|
| 1280×720 | 1.71 | 584.85 | 5.14 | 248 / 11,190 |
| 1920×1080 | 1.72 | 581.38 | 5.22 | 248 / 11,190 |

The table above is the historical placeholder baseline. After integration, the same fixed courtyard view was sampled again, with player health refreshed to keep combat active rather than transition to a defeat menu:

| Integrated-model resolution | Mean observed frame ms | Mean observed frame rate | Longest sampled frame ms | Draw calls / primitives |
|---|---:|---:|---:|---|
| 1280×720 | 1.62 | 615.95 | 6.86 | 181 / 96,792 |
| 1920×1080 | 1.69 | 590.22 | 3.40 | 181 / 99,864 |

The sample counts match `Engine.get_frames_drawn()` (1,849 and 1,772 frames respectively). Latest raw output is at `builds/validation/profile.json`. Enemy positions/draw counts vary during active combat, so these are not controlled comparative benchmarks. This is a short local post-draw timing sample, **not** a minimum-FPS guarantee or a full-run benchmark. Test the actual export under sustained combat before setting performance claims.

## Model integration review

- All six source GLBs are retained unchanged in `assets/models/<id>/model.glb`, with Godot-extracted texture sources. Normalization scenes isolate scale/pivot/orientation from gameplay actors.
- Both enemies face -Z, stand on the floor, and retain their original capsules/navigation. Static models use a visible windup lean, brief hit scale reaction, and a rotated/shrunken death pose; no rigged or independently animated weapon swing is claimed.
- Weapon meshes render in the isolated overlay without wall clipping or crosshair obstruction. The generated cleaver was sword-like, so the player-facing name is now **Iron Blade** while provenance IDs stay unchanged.
- Torch lights remain independent of their visual mesh. Wall mounts orient inward. Urns remain nonblocking. The generated torch's extra lower basket and urn's lid are accepted demo details, not missing mechanics.
- All 18 runtime textures load within the 1024px limit, while 2K source texture data and original GLB metadata are preserved. No extra generation credits were spent on integration.
- Render views are `models-in-level-1280.png`, `combat-models-1280.png`, `enemy-death-models-1280.png`, `wall-viewmodel-1280.png`, `melee-swing-1280.png`, and the existing 720p/1080p HUD/menu images in `builds/validation/`.

## User playtest feedback — 2026-10-20

- The user first reported: "played it -works!"
- The user subsequently reported playing through the demo, using both weapons, and getting to the exit. This confirms a human playthrough of the main route with both weapon types exercised.
- The user's question about how the first weapon works highlights a melee clarity/feedback issue: the current narrow camera ray does not match the apparent blade swing. A sweep timed to the visible swing, plus clearer hit feedback, is a recommended follow-up rather than a change made during acceptance reporting.
- The user reported a roughly **5-minute** run and described the difficulty as **easy**. This run meets the lower end of the 5–10 minute demo target; broader first-time-player balance is not yet established.
- Explicit victory-screen behavior, defeat/restart/pause coverage, and offline launch status were not reported. Do not infer those checks or close tasks 8.3/8.5 from this feedback alone.

## Remaining human acceptance checklist

- [x] User reports a main-route playthrough using both weapons and reaching the exit.
- [x] Record this player's duration/difficulty feedback: approximately 5 minutes, easy.

- [ ] Play a complete new run without test teleports/direct damage, including melee and magic, actual item collection, and nearby E exit interaction.
- [ ] Judge movement feel, sensitivity, aim readability, both attack telegraphs, wall occlusion, and weapon feedback.
- [ ] Exhaust mana before the key and complete the route with melee/navigation only.
- [ ] Pause/resume and alt-tab during combat; confirm no input leakage, cursor trapping, or timer catch-up.
- [ ] Die, restart, win, restart, quit to menu, and start again repeatedly in the editor.
- [ ] Gather broader first-time-player timing/balance feedback and tune toward 5–10 minutes; this user's reported run was 5 minutes and easy.
- [ ] Re-export after final asset review; launch the native EXE offline and repeat the complete win/lose/restart loop at both resolutions.
- [ ] Record final build hardware, performance, provenance/attribution notices, and remaining issues before marking export acceptance complete.

## Known limitations / blockers

- Tasks 7.3–7.5 are complete for the six-model demo art pass. Paid-plan confirmation and the review basis are recorded; the owner should still review any separate account agreement and final public-release notices.
- Tasks 8.3 and 8.5 need interactive human acceptance; automated coverage and screenshots do not complete those tasks.
- Models are static low-poly meshes with procedural feedback. Combat-polish adds original combat SFX and a pause-menu volume slider; save/load, a general graphics/settings screen, rigged animation, multiplayer, and controller support remain out of scope.
- Final legal notices and the project's distribution license should be reviewed by the owner before public release.
