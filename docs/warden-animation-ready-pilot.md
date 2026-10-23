# Animation-ready Warden pilot

**Adoption update:** the user subsequently approved c02's look/animations, requested a sword-mount correction and authorized gameplay integration. The [separate runtime 0.5.0 adoption](warden-runtime-integration.md) is now implemented with independent resources and a shared corrected grip; no new credits were spent. Statements below about an unchanged game/version describe the historical pilot phase, not the current project. Original raw pilot assets/provenance and the accepted 0.4.1 files remain unchanged.

## Authorized scope

On 2026-10-23 the user approved the proposed **90-credit Warden-only pilot**. This is not permission to regenerate all assets, generate the Adept or spend the remaining account balance. The initial free balance check returned **1,366 credits**.

| Planned stage | Credits |
|---|---:|
| Three standard Meshy 7.1 untextured A-pose candidates | 3 × 20 = 60 |
| PBR texture for one selected candidate | 10 |
| Rig that textured candidate | 5 |
| Idle, Walk, Attack, Hit, Death preset batch | 5 × 3 = 15 |
| **Maximum planned total** | **90** |

No automatic paid retries, fourth candidate, second textured branch, Ultra geometry, paid standalone remesh/conversion, credit purchase or subscription change is authorized. Integrated generation remesh is a generation option, not an additional paid API request. All original accepted sources, local/Meshy A/B prototypes, gameplay/version and 0.4.1 EXE/PCK/ZIP remain unchanged; this is additive prototype work only.

## Fixed plan and safety

`docs/warden-pilot-plan.json` records the three original prompts, common texture prompt, standard `meshy-7.1` geometry with `pose_mode: a-pose`, 8,000-triangle target and the five exact preset IDs: Idle `0`, Walk Fight Forward `21`, Right-hand Sword Slash `219`, Hit Reaction `178`, Dead `8`. Free live lookup confirmed every ID/key. Price reference: [Meshy API pricing](https://docs.meshy.ai/en/api/pricing), checked 2026-10-23.

The body prompts request empty relaxed hands clear of hips, separated straight legs/feet, short clothing, visible joints, stone mask/iron armor, and no weapons, cape, long robe, scenery or insignia. The variants are **c01 Plate guard**, **c02 Brigandine guard**, **c03 Tabard guard**. They are original text-only inputs, with no uploaded references or copied game characters.

`tools/meshy_warden_pilot.py` uses a canonical plan hash, six fixed stage reservations written before POST, durable task IDs before polling, strict route/payload checks, a process lock, and a single downstream selection lock. Ambiguous submissions and failed tasks cannot be replaced automatically. Keys, raw error bodies and signed asset URLs are not printed/saved. Credentials use the existing ignored `.env`/environment helper. Normal game/test code does not use the API.

External staging: `%LOCALAPPDATA%/Temp/opencode/cinderkeep-warden-pilot-2026-10-23/`. Raw GLBs and sanitized stage records are retained there; inspected candidate copies use excluded `assets/prototypes/warden-pilot/candidates/` and backups use ignored `builds/authoring/warden-pilot/`.

The prior user-confirmed paid monthly plan and Meshy's 2026-09-19 terms sections 2.4/3.1/3.2 remain the rights-review basis. Preserve AI-origin metadata. Preset Service Assets are licensed within character output, not newly exclusively owned standalone clips. Account-specific agreements and eventual public-release rights remain the owner's review; no public publishing is part of this pilot.

## Candidate review gate

Review actual empty hands, limb/armpit gaps, feet/knees, mask and armor silhouette, short clothing and unwanted accessories before choosing one winner. A requested A-pose or successful API result is not proof of clean anatomy or animation readiness. If all three are unsuitable, pause before the downstream 30-credit spend; do not silently generate another.

### Actual preview milestone — 2026-10-23

All three planned previews succeeded at **20 credits each**, **60 total**, no paid retries. Balance after previews: **1,306 credits**. Texturing/rigging/animation has not yet started at this milestone; 30 planned credits remain unspent.

| Candidate | Preview task | Actual triangles | Review observation |
|---|---|---:|---|
| c01 Plate guard | `01a16901-0477-70fc-bf59-5bdb7254f921` | 8,295 | Empty hands/limb gaps, but unwanted horns and longer side cloth contradict prompt constraints |
| c02 Brigandine guard | `01a16902-2e6c-7771-b0d8-8ac6b4954997` | 8,290 | Closest clean guard silhouette; clear limbs/knees and comparatively short clothing; technical recommendation for selection |
| c03 Tabard guard | `01a16903-2b8f-71e3-aaa2-22f8ca27e4f9` | 8,298 | Empty hands, larger hood/armor silhouette and more cloth; less close to the requested plain guard |

All three returned with bent elbows/raised palms rather than a strict straight-arm A-pose, despite `pose_mode: a-pose` being requested. The task response supplied only one GLB per candidate and no alternative posed-model URL. The renderer now explicitly labels the pose as **requested**, not validated. Do not infer that a parameter guarantees pose compliance. These bodies may still be riggable because hands/limbs are separated, but that remains unproven until a selected body is rigged and reviewed.

Inspected actual front/side/back and focused views under common neutral material/height with a shared front fill light to reveal anatomy. **13 candidate-review checks** pass (actual counts, no gameplay/rig actors, shared material, normalized size, left/right order, real focus/view controls, layout and disposal). Twelve rendered viewport captures at 720p/1080p are under `builds/validation/warden-pilot-candidates/`, with logs `warden-pilot-candidates-{import,tests,render}.log`. The twelve offline authoring guard tests pass; no key was read or credits used by those tests. Raw files/checkpoints and inspected copies/backups retain hashes/provenance.

At the preview milestone no downstream fee had been spent. The user then explicitly selected **2 — Brigandine guard (c02)** through the review question. Only c02 may enter the remaining 30-credit texture/rig/five-action branch. Selecting a body does not guarantee production-quality anatomy, weights, finger grip or animation.

```powershell
# Free preflight or resume-only calls; no new paid stages without --submit.
python tools/meshy_warden_pilot.py preflight
python tools/meshy_warden_pilot.py candidates
# Offline preparation/captures after all three previews have completed.
python tools/prepare_warden_candidates.py
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import
& .\Godot_v4.7.2-stable_win64.exe --path . scenes/prototypes/warden_candidate_review.tscn
& .\Godot_v4.7.2-stable_win64_console.exe --path . --script tools/capture_warden_candidates.gd
```

In the candidate scene, **0** shows all three, **1/2/3** focuses one, **V** cycles front/side/back, **Escape** quits. Gray material and normalized height are common presentation only; raw meshes remain unchanged. Captures use rendered viewports, never the desktop. Candidate selection itself does not call the API; downstream requests still require explicit submission and remain inside the existing pilot cap.

## Downstream intent

Only the recorded selected body will be textured/rigged/animated. Reuse the existing separate Iron Blade as a rigid carrying-hand attachment, not a skinned part of the body. This removes the old blade-to-leg weighting failure by construction but does not guarantee good hand grip, armor/cloth deformation, foot planting or combat synchronization. Review the native five-clip pilot independently before any separately authorized game integration or Adept work.

## Completed selected branch — 2026-10-23

The user selected **c02 Brigandine guard**. All three downstream tasks succeeded on the first paid submission; no unselected body was textured or rigged:

| Stage | Task ID | Actual credits |
|---|---|---:|
| Selected c02 PBR texture | `01a1691a-c558-774c-8648-12b9c7877cb3` | 10 |
| Selected textured-body rig | `01a1691b-5914-74c8-ac89-5d86b477ae88` | 5 |
| Five-action batch | `01a1691b-f08a-73cf-9036-cf69f3340f2b` | 15 |
| Earlier three previews | Above | 60 |
| **Total** | **No extra paid requests/retries** | **90** |

Balance snapshots: **1,366 before**, **1,306 after previews**, **1,276 after completion**. The approved budget is exhausted; this is not permission to regenerate/refine variants, create the Adept or buy more actions. Phase balance milestones are retained instead of being overwritten by later read-only resumes/account activity.

Raw files and the sanitized finished checkpoint remain in external staging and are backed up under `builds/authoring/warden-pilot/`. Reviewed copies `texture.glb`, `animate.glb` and `provenance.json` are in excluded `assets/prototypes/warden-pilot/winner/`. `tools/prepare_warden_pilot.py` performs offline stage/hash/cost checks and preserves different existing outputs.

- Textured body GLB: 7,581,648 bytes; SHA-256 `65f36707e6125b7ca8183842eeb58e1e03712b65879789f362062780d5b34d67`.
- Raw rig GLB: 8,164,952 bytes; SHA-256 `490e7e68f54f687ca01e57f55e9966edec685ecf6c157bf70ef307ad9cd523cc`.
- Five-clip GLB: 3,923,744 bytes; SHA-256 `18a8b2a90452dc8a6d0b71f913065d42eec702f6b3f77dc56c186f7dabe8f11f`.

The body remains **8,290 triangles**, with 24 bones. Texture output has 14,933 render vertices; rig/animation output has 15,174 (API export seam/normal splits), so exact vertex-count equality is not claimed. Matching per-triangle UV inventories and identical albedo bytes verify atlas compatibility. The animated export includes only albedo; the preview restores the selected texture output's full PBR material after that check. All four extracted texture imports are capped at 1024px with mipmaps; source 2K images/raw GLBs remain unchanged.

Actual native clips: **Idle 4.0s**, **Walk Fight Forward ~1.6667s**, **Right-hand Sword Slash 1.5s**, **Hit Reaction ~1.6333s**, **Dead ~2.9667s**. No timing has been synchronized with live gameplay. Death holds its last frame in single-clip review; Auto mode continues to the next clip.

## Run the completed pilot preview

Open `scenes/prototypes/warden_pilot_preview.tscn` and press **F6**, or:

```powershell
& .\Godot_v4.7.2-stable_win64.exe --path . scenes/prototypes/warden_pilot_preview.tscn
```

The accepted static Warden remains on the **left**; the new selected body with its own verified PBR material and separate blade is on the **right**. This is a visual prototype, not a modified game enemy.

| Input | Action |
|---|---|
| 1 / 2 / 3 / 4 / 5 | Idle / Walk / Attack / Hit / Death |
| 0 | Auto sequence |
| Space / R | Pause/resume / replay |
| V | Common front / side / back view |
| B | Pilot skeleton overlay |
| W | Blade visibility, to inspect the genuinely empty-handed body |
| Escape | Quit standalone preview |

### Rigid weapon attachment and review limits

The unchanged accepted `scenes/models/iron_blade.tscn` is a separate scene beneath a `BoneAttachment3D` owned by `RightHand`. Its meter-scale mount is top-level in transform space and updated from the named hand's **orthonormal world frame**, removing inherited centimetre units/shear while retaining hand-relative motion. The initial pilot used rotation **(90, 0, 0) degrees**, palm offset **(0, 0.045, 0)m**, scale **0.75**. Following the user's feedback, the preview now shares the [corrected runtime handle-centre/palm calibration](warden-runtime-integration.md#corrected-grip-including-measurement-correction). These are inspectable/exported preview parameters, not edits to the weapon source or body weights.

Every weapon mesh is unskinned. Checks independently resolve `RightHand` (not the production follower helper), verify the fixed calibration across 65 native poses, stable scale and unchanged blade-vertex distances. A temporary wrong-root attachment caused two focused failures; restoring the real hand follower returns checks to green. That proves this fix is not merely a parent/name label while the blade follows a leg/root.

The body still has relaxed/open hands and no articulated finger rig. The default grip was reviewed against alternative local axis calibrations, but closed fingers, convincing weapon poses in every clip, body/weapon/floor intersections, armor deformation and foot planting remain **human review/refinement tasks**, not solved by the structural attachment checks. The native motion is raw, with no foot IK or ground snapping and no attack/hit/death gameplay callbacks.

Body plus the reused 3,086-triangle blade has a maximum source total of **11,376 triangles**. This exceeds the original ~10k per-enemy guideline when combined, even though the body alone is near the requested 8k target. It is an explicitly recorded prototype cost, not a silently accepted production budget/performance claim; review world-weapon LOD/geometry before any integration.

## Final technical verification — 2026-10-23

- `tools/verify.ps1 -Render` passes import/startup and all **417 source checks**: 269 original game, 32 whole-model, 39 local rig, 33 Meshy A/B, **13 candidate review** and **31 selected-pilot** checks. Existing game/prototype render checks also pass. No script/runtime errors were reported.
- All **75 offline Python tests** pass, including the previous 56, twelve new pilot-authoring safety checks and seven completed-pilot asset/provenance/UV/PBR/weight/isolation checks. These tests do not read the real key, contact Meshy or use credits.
- The selected-pilot suite independently resolves the named carrying hand and checks **65 poses across all five clips**: fixed hand-relative calibration, stable world scale, finite transforms and unchanged actual blade-vertex separation within 0.0001m. It also verifies actual skin/bone motion, 24-bone/five-clip import, full 1K PBR restoration, no gameplay actors/colliders, native clocks, held death/replay, real keys, views/overlays/visibility, both-resolution UI bounds and complete cleanup of the compensated top-level weapon descendant.
- A temporary root/pelvis-following weapon mutation produced **two focused failures** (hand-relative poses and view-rotated attachment). The correct hand follower was restored; all 31 checks pass. This is structural/transform evidence, not proof of a natural finger grasp or absence of every visual intersection.
- Inspected actual textured idle, walk, attack front/side/back, hit, death and skeleton views at 720p/1080p. The final capture tools produce **12 candidate images** and **16 pilot images** in their validation folders. They capture only Godot viewports, never the desktop. Candidate 1's unrequested horns and the bent-elbow pose discrepancies remain visible/documented, not silently repaired or regenerated.
- The accepted PCK again passes **269 checks** from an external temporary working directory. The accepted native EXE, standalone candidate review and standalone selected pilot all pass headless startup with exit 0 and empty stderr. Existing asset tests verify source models/audio/navigation, prior local/Meshy outputs and accepted EXE/PCK/ZIP hashes remain unchanged. No accepted game export occurred. Strict OpenSpec validation passes.
- Evidence: `builds/validation/warden-pilot-{verification,offline-tests,import,render,preview-startup,candidate-startup,wrong-bone-tests}.log`, `warden-pilot-baseline-{packaged-tests,native-startup}.log`, `warden-pilot-candidates-{import,tests,render}.log` and rendered PNGs under `warden-pilot/` / `warden-pilot-candidates/`. Raw files and milestone/finished records are backed up under `builds/authoring/warden-pilot/` as well as external staging.

- [x] User approved the new Warden's general appearance/animations and authorized gameplay adoption on 2026-10-23; they reported the sword mount was slightly off.
- [x] Separate runtime integration implemented with shared calibrated grip and unchanged combat rules; see the 0.5.0 record. The preliminary brown/pommel measurement was corrected to the actual dark handle centre.
- [x] General integrated-version feedback received after the 0.5.0 handoff: "works fine" (2026-10-23). Detailed grip/gait checks were not separately reported. Open fingers/foot planting/pose intersections remain limits; no Adept work or additional paid refinement is authorized.
