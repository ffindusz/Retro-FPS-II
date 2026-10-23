# Runtime Warden — 0.5.0

## Outcome and playtest

On 2026-10-23 the user said the new Warden looks good, liked the animations, reported the sword mount was slightly off and asked to use it in the project. **All four melee Wardens now use the selected c02 Brigandine visual.** The two Adepts retain their old static/ranged presentation. No new Meshy call, key access or credit spend was needed; the earlier pilot's 90-credit spend and 1,276 post-pilot balance remain historical, not a fresh balance check.

Launch **`builds/windows-0.5.0/Cinderkeep.exe`**, keeping its adjacent PCK. The folder includes controls, credits, engine notices and SHA-256 sums. Editor F5 also runs 0.5.0. The accepted `builds/windows/` EXE/PCK and `builds/releases/Cinderkeep-0.4.1-windows-x64.zip` are unchanged, and still have the old Warden. No new portable ZIP or public release is implied.

**User confirmation — 2026-10-23:** after the 0.5.0 handoff, the user reported **"works fine"**. This confirms the integrated version generally works and satisfies the general integration review gate. It does not separately report every grip/gait/transition check, a complete route or an explicitly disconnected native run. Known finger/pose limitations remain documented rather than inferred resolved.

## Independent runtime resources

- `scenes/models/warden_animated.tscn` selects `scripts/enemies/warden_presentation.gd`; the melee scene selects this wrapper. The ranged override still selects `adept.tscn`.
- `assets/models/warden-animated/{animate,texture}.glb` are unchanged copies of the selected pilot outputs, with independent imports and full PBR restoration. All four extracted JPEG imports are capped at 1024px with mipmaps; raw 2K sources remain intact.
- Animation SHA-256: `18a8b2a90452dc8a6d0b71f913065d42eec702f6b3f77dc56c186f7dabe8f11f`.
- Texture SHA-256: `65f36707e6125b7ca8183842eeb58e1e03712b65879789f362062780d5b34d67`.
- Runtime provenance explicitly sets `gameplay_integration: true` and records adoption, grip, cost and review state. Original prototype provenance remains unchanged and correctly describes its historical nonintegrated milestone.
- The original static Warden, all prior prototypes, original blade/model/audio/navigation sources and accepted 0.4.1 artifacts remain retained. Runtime dependencies never enter excluded `prototypes/` or authoring paths.

## Corrected grip, including measurement correction

`scripts/enemies/warden_grip.gd` supplies the shared runtime/pilot calibration:

| Setting | Value |
|---|---|
| Carrying bone | `RightHand` |
| Rotation | `(90, 0, 0)` degrees |
| Palm target in orthonormal hand coordinates | `(0.015, 0.115, 0.025)m` |
| Dark leather centre in blade-wrapper coordinates | `(-0.000733, 0.041225, -0.001466)m` |
| Stable world scale | `0.75` |

The mount origin is `palm_target - rotated_scaled_basis * handle_centre`. It places the **handle**, not the scene origin, into the palm. The old 0.045m hand-Y target sat near the wrist; dominant hand vertices span roughly 0.041–0.222m along that axis, so the target is now farther into the palm. The handle-origin compensation itself is approximately **3.1cm at scale 0.75**.

The initial brown-only texture filter was **wrong**: its `(-0.003175, -0.114778, 0)` result identified the brass pommel rather than the dark grip. The preliminary 8.6cm claim is superseded. Full longitudinal geometry/colour bands, viewport markers and a dark-leather sample between the pommel and guard corrected it. The runtime suite independently repeats that texture/geometry measurement, and independently resolves RightHand over 65 poses. Corrected idle/contact close-ups were inspected at 720p/1080p.

The blade remains a separate unskinned descendant of the hand attachment, using an orthonormal world hand frame to remove the centimetre rig scale. Physics sampling updates it immediately; render processing only follows transforms, never ages animation clocks. Actor teleports/turns with AI frozen cannot leave it behind; disposal frees it with its owning actor.

**Limits:** relaxed/open fingers do not close around the handle. The rigid mount fixes placement/following, not hand anatomy, every body/weapon/floor intersection or professional-quality grasp.

## Gameplay remains authoritative

The existing melee tuning remains **68 health, 12 damage, 2.6m/s speed, 1.9m attack range, 0.55s windup and 1.6s cooldown**. Collider/navigation and complete encounter/resource/objective fingerprints match the original snapshot. No placement or balance changes were made.

Presentation priority is Death → committed Attack/recovery → brief cosmetic Hit → actual-travel Walk → Idle. Movement phase uses horizontal distance actually travelled after `move_and_slide()`, not the CHASE enum, so a stalled enemy does not walk in place. Horizontal Hips translation is stripped; vertical native motion remains. A configured 1.6m gait cycle and 0.08s per-bone transitions are visual choices, not movement authority or foot IK.

Native strike **frame 18/30 (0.60s)** shows the forward slash; frame 15/30 had the raised/back-facing blade. The controller maps 0→0.60s onto the existing 0.55s windup, samples the contact pose **before** `resolve_attack()`, then finishes the 1.5s native clip as visual follow-through. This does not turn the sword geometry into a hitbox: the existing range/LOS query remains authoritative, including its generous reach. Cover or leaving range still causes a miss. No animation method/audio tracks can cause damage.

Nonlethal damage cannot cancel/restart the windup or replace a committed attack with Hit; instance-local tint remains available. Outside attacks, Hit is a bounded 0.2s cosmetic cue. Lethal damage immediately cancels attack authority and disables collision through the existing deferred setters, then plays/holds Dead (~2.9667s) instead of adding the old shrink/roll tween. Pause/results inherit normal tree freezing; restart creates fresh clocks/material feedback and disposes old blades.

## Verification — 2026-10-23

- **459 source checks:** 269 original game, **42 runtime Warden**, 32 whole-model, 39 local rig, 33 A/B, 13 candidate and 31 pilot. All pass. Only superseded static-bound and historical-project-version assumptions were adapted; gameplay assertions remain.
- **81 offline Python tests:** original 75 plus six runtime-copy/provenance, dependency, texture, version/frozen-artifact and shared-calibration checks. No real key or API access.
- **311 packaged checks:** 269 original plus 42 runtime, run with the editor engine against the exported PCK from an external approved temporary directory. No local project-resource fallback. All pass with empty stderr.
- **204-resource package audit:** required runtime body/texture/blade/Adept/original Warden are present; no prototype, authoring/tool/test/document/credential/build paths. Project version is 0.5.0.
- Native EXE headless startup and rendered **menu** startup pass outside the repository. A direct release scene-path override was attempted but the official template rejects it (`disable_path_overrides`); it is **not counted** as a native-level automated smoke pass. Packaged tests cover live actors through the editor engine. The user subsequently reported "works fine" for the handed-off integration; exact playtest steps/environment were not specified.
- Actual skinned bind-rest measures position `(-0.541881, 0, -0.269986)`, size `(1.083763, 1.806272, 0.539963)m`, matching the cached body rest bound. Conservative custom culling bounds contain all body vertices in bind rest and 65 native sampled poses. Weapon bounds are independent; it is not included in rest-height tests.
- Wrong-pelvis follower mutation: **three focused failures**. Wrong contact sample: **one focused failure**. Both mutations were restored; final checks pass. These establish regression sensitivity, not visual acceptance.
- Full game/prototype render checks pass. Runtime captures include Idle, sampled Walk, **real navigation travel**, windup, authoritative contact (health 100→88 at native 0.60s), recovery, Hit, held Death, first-person view and grip close-ups at both resolutions: **36 viewport images**. No desktop capture.

Evidence under `builds/validation/warden-integration/`: `verification.log`, `source-verification-final.log`, `offline-tests.log`, `runtime-source-tests.log`, `runtime-render.log`, `captures.json`, `wrong-{hand,contact}-tests.log`, `export.log`, `packaged-{game,warden}-tests.log`, `package-audit.{log,json}`, `native-{startup,render-menu,render-level}.log`, `delivery-validation.json`, before/after profiles and PNGs. The rejected release-level override log is retained explicitly as a limitation, not a success.

## Cost and controlled comparison

Body **8,290** + reused blade **3,086** = **11,376 maximum source triangles**, an explicit integration exception to the original ~10k combined-enemy guideline. Runtime source size is not a guarantee about generated LOD/shadow draw costs. Consider a later world-blade LOD only if justified; no source decimation was made here.

`tools/profile_warden_integration.gd` recorded matching fixed courtyard/camera/actor transforms, frozen AI/combat/torch aging, vsync disabled, 30 warmup frames and two seconds per view. The after run advances Warden visuals with virtual travel at 60Hz. Both used Godot 4.7.2 Compatibility on this machine's **AMD Radeon (TM) Graphics**.

| Resolution | Before mean frame ms | After mean frame ms | Before → after draw calls |
|---|---:|---:|---:|
| 1280×720 | 2.22685 | 2.86995 | 230 → 260 |
| 1920×1080 | 4.01781 | 5.16877 | 230 → 260 |

This short view sample increased by about 29%; it is **not a full-game/minimum-FPS benchmark or hardware-independent promise**. Native vertical motion, visible foot sliding/airborne poses, relaxed fingers and pose/floor intersections remain review limits. No foot IK, root-motion locomotion or cloth/finger rig was added.

## Handoff checklist

- [x] Approved body adopted, grip recalibrated and real-level technical evidence captured.
- [x] Gameplay/frozen assets and accepted 0.4.1 files preserved; 0.5.0 exported separately.
- [x] General integrated-version user confirmation recorded: "works fine" on 2026-10-23. No rebuild was needed for this feedback-only record; delivered binary/checksum files remain unchanged.
- [ ] User checks the corrected grip in motion, telegraph/contact feel, navigation gait and death in the current Windows build.
- [ ] User completes a normal run, pause/resume, defeat/restart and victory; explicitly disconnected native playthrough remains unreported.

No Adept generation, further refinement credits, public distribution or human production-quality approval is inferred.
