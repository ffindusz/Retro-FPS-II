# Warden animation A/B — actual Meshy outputs

## Authorization, provenance and exact spend

On 2026-10-23 the user approved the proposed A/B test: upload only the original textured Warden, one automatic rig and three fixed preset actions, **14-credit maximum with no automatic paid retries**. The initial missing-key blocker was resolved by the user adding the key locally to the ignored `.env`. The key was read through the existing helper, never displayed or added to records.

Live preflight confirmed **1,380 credits** and exactly actions **0 Idle**, **21 Walk Fight Forward**, **219 Right-hand Sword Slash**. Published pricing remained 5 credits per rig and 3 per action. Exactly two paid tasks succeeded:

| Stage | Saved task ID | Actual credits |
|---|---|---:|
| Rig original Warden | `01a168c6-d5eb-7539-a613-96c91b801559` | 5 |
| Combined three-action batch | `01a168c7-7e14-75d7-a9cb-c5c480a26787` | 9 |
| **Total** | **No paid retries or extra actions** | **14** |

Final reported balance: **1,366 credits**. No new model generation, Text to Motion, remesh, paid conversion, credit purchase or subscription change occurred.

The uploaded 6,967,512-byte original was `assets/models/enemy-warden/model.glb`, SHA-256 `969cef958b48e06ce33e40d8efef62797a6cba104a045e4253ac16175135e2d4`, with embedded textures and original +Z-facing coordinates. Height was specified as 1.8063m. The untextured -Z-facing local derivative was **not** uploaded.

Raw outputs and the sanitized checkpoint remain outside the project in `%LOCALAPPDATA%/Temp/opencode/cinderkeep-warden-meshy-ab-2026-10-23/`:

- `rigged.glb`: 7,260,104 bytes; SHA-256 `4ac76e4afe9077375320865948f41d87dd7d814a1a2a4b44ff32191d152807b8`.
- `animations.glb`: 3,437,776 bytes; SHA-256 `0eff67371db54cd5589088df9a87a82a2f73b52915516dd48cc010b7383b6e20`.
- `record.json`: authorized scope, source hash, whitelisted task/status/charge fields, file hashes and balances; no credentials, upload data URI or signed URLs.

The same three raw files are also backed up locally under ignored `builds/authoring/warden-meshy-ab/` so the trial does not depend on API retention or only the temporary staging directory.

An unchanged copy of the combined character/animation output is in excluded `assets/prototypes/warden-meshy-ab/`, with sanitized `provenance.json`. Source glTF metadata is retained. The prior paid-monthly-plan confirmation (2026-10-20) and current [terms](https://www.meshy.ai/terms-of-use), version 2026-09-19, are the review basis: sections 2.4/3.2 cover output/AI metadata; section 3.1 licenses library **Service Assets within the output**, not as newly exclusively owned standalone presets. A working key/balance is not independent plan/legal evidence. Owner-specific agreements and public distribution review remain the owner's responsibility; these assets are prototype-only and excluded from normal exports.

## What actually came back

Both versions retain 7,327 vertices, 8,462 triangles and the original UV inventory. Meshy returned **24 bones**, versus **21** locally. The automatic rig file includes only a tiny initial clip; optional walking/running examples were not assumed or purchased separately. The requested combined output has the three actual clips:

| Action | Local native duration | Meshy native duration |
|---|---:|---:|
| Idle | 2.0s | 4.0s |
| Walk / Walk Fight Forward | 1.0s | ~1.6667s |
| Attack / Right-hand Sword Slash | 1.4s | 1.5s |

The animated Meshy export retains the original albedo bytes but omits the source's separate roughness/normal images. After verifying matching UVs/albedo, **both sides use the exact accepted original PBR material/1K textures** in the preview. The raw Meshy export is not edited to add them. Its extracted albedo import is capped at 1024px too.

This compares two **rig + weights + motion pipelines**, not identical choreography on an identical rig. Differences cannot all be attributed to animation authoring alone.

### Important observed weapon problem

UV-matching the original disconnected blade region identifies the same **180 vertices** in each export:

| Blade observation | Local | Meshy |
|---|---|---|
| One shared rigid bone | `Weapon.R`, all 180 vertices | None |
| Individually rigid vertices | 180 | 0 |
| Vertices with leg/hip-related influences | 0 | **180** |

Meshy's blade influences include `RightHand` on 90 vertices, `RightLeg` on 153, `RightToeBase` on 96 and `RightUpLeg` on 174 (counts overlap because vertices have multiple influences). The result can drag/bend the blade with the leg and break the apparent grip. This is an **actual raw auto-rig outcome**, not a hypothetical risk. It has not been silently repaired for the comparison. `tools/analyze_meshy_ab.py` reproduces the observation offline and writes `builds/validation/warden-ab-asset-metrics.json`.

The captured Meshy clips show more full-body stance/torso/leg changes than the deliberately simple local clips. That is not a blanket quality win: weapon binding, cape/armor behavior, foot contact and attack timing still need review. A useful later direction could be repairing Meshy weights or retargeting useful motion onto the controlled local rig, but neither is part of this authorized trial or integrated into gameplay.

## Run and review controls

Open `scenes/prototypes/warden_animation_ab.tscn` and press **F6**, or:

```powershell
& .\Godot_v4.7.2-stable_win64.exe --path . scenes/prototypes/warden_animation_ab.tscn
```

Default: **local A left, Meshy B right**, native clip speeds, clearly labelled optional horizontal-cycle anchoring. Both share the same camera, lighting, floor and material. Height is normalized once from actual **skinned rest bounds**, not raw mesh-node bounds; Meshy's centimetre-scaled armature otherwise gives misleading bounds and a 100x presentation error. Rest height is 1.8063m. No per-frame rescaling or vertical ground snapping hides poses.

| Input | Action |
|---|---|
| 1 / 2 / 3 | Idle / Walk / Attack pair |
| 0 | Auto sequence |
| Space / R | Pause/resume / replay both |
| T | Native speed / phase-matched retimed review; restarts pair |
| G | Compensated / raw horizontal cycle motion |
| V | Common front / side / back view |
| B | Both skeleton overlays |
| X | Swap actual left/right positions and labels |
| Escape | Quit standalone preview |

Native mode samples each duration independently at native speed and shows both times. Phase mode explicitly retimes both clips to the longer pair duration to compare equal normalized phases; it is **not native-speed footage**. Anchoring subtracts only the linear XZ start-to-end cycle displacement measured at the pelvis/hips; vertical movement and within-cycle sway/lunges remain. Raw mode restores that displacement without modifying the exports. No Meshy impact/contact time is assumed or aligned to the local **0.55s visual windup**. No gameplay actors, damage, navigation, combat audio or projectiles are created.

## Authoring safety and verification commands

`tools/meshy_animation_ab.py` uses fixed source/actions/routes and a durable 5+9 credit reservation before POST, stores task IDs before polling, and blocks failed/ambiguous replacement submissions. An external lock prevents simultaneous trial runs. Downloads use HTTPS without forwarding API authorization; error bodies, credentials, signed URLs and source data URIs are excluded from saved records. Offline tests exercise the guards without reading the real key or using credits.

```powershell
# Read-only; no credits.
python tools/meshy_animation_ab.py preflight
# Resume/check only existing tasks: deliberately omit --submit.
python tools/meshy_animation_ab.py run
# Offline inspection/reproduction of existing downloaded outputs; no API requests.
python tools/prepare_meshy_ab.py
python tools/analyze_meshy_ab.py
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/analyze_warden_ab.gd
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/test_warden_ab.gd
& .\Godot_v4.7.2-stable_win64_console.exe --path . --script tools/capture_warden_ab.gd
```

The approved paid trial has already completed. Do not clear/replace the staging record or create another paid trial without separate approval. Preserve raw results locally before Meshy's API retention expires. The comparison and new tools/assets remain excluded from accepted builds; original source/local rig and accepted EXE/PCK/ZIP are unchanged.

## Recorded verification — 2026-10-23

- `tools/verify.ps1 -Render` passes editor import/startup, **269 game checks**, **32 prior whole-model checks**, **39 local rig checks**, and **33 A/B checks**, with no script/runtime errors. Existing game/preview renders plus **16 new A/B viewport captures at 1280x720/1920x1080** complete successfully.
- All **56 offline Python tests** pass: the prior 39 plus 11 bounded-authoring safety tests and six actual A/B asset/provenance/weight/material/isolation tests. These do not read the real key, submit tasks or spend credits.
- A/B regressions cover native versus phase clocks, explicit XZ-only compensation/raw recovery, real skin movement, actual names/durations, shared 1K material, correct skinned-rest scale, source side labels/swapping, pause/replay/selection/auto, views/bones, layout, no gameplay actors/colliders and clean disposal/reopening. Temporarily freezing both actors at time zero caused a focused animation failure even while clocks/labels continued; restoring playback returns all 33 checks to green.
- Initial capture review caught the centimetre-armature presentation error. Skinned-rest normalization now yields near-unit scale on both sides (~1.0000003 local / ~1.0000152 Meshy), rather than the incorrect 100x mesh-node estimate. Real posed-skin size tests guard against off-stage giants; raw GLB bytes are unchanged.
- Runtime measurements at `builds/validation/warden-ab-runtime-metrics.json` show local start-to-end pelvis displacement is zero for all three clips. Meshy's walk hips differ by ~**5.12mm horizontally** and ~**11.66mm vertically** across endpoints; the optional anchoring removes only the horizontal linear component. This is an endpoint/root observation, not a foot-sliding score or proof of a seamless loop. Idle/attack net XZ drift is effectively zero.
- Inspected native and phase-matched idle/walk/attack, side views and skeleton captures at both resolutions. The more extensive Meshy body poses and raw sword/leg-binding problem are visible. These controlled views do not establish user preference, animation-quality certification, contact timing or a performance claim.
- The accepted PCK again passes **269 checks** from an external temporary working directory; the accepted native EXE and the documented standalone A/B scene both pass headless startup with exit 0 and empty stderr. Existing offline hash tests verify original models/audio/navigation, local rig and accepted EXE/PCK/ZIP remain unchanged. Strict OpenSpec validation passes. No accepted game export was rebuilt.
- Evidence: `builds/validation/warden-ab-{verification,offline-tests,preview-startup,import,render,disabled-animation}.log`, `warden-ab-baseline-{packaged-tests,native-startup}.log`, `warden-ab-{asset,runtime}-metrics.json`, and PNGs under `builds/validation/warden-ab/`.

- [ ] User preference after reviewing actual Walk/Attack, weapon grip, cape/shoulders and native timing.
- [ ] Separate decision on cleanup/retargeting/integration; no new paid operation is authorized automatically.
