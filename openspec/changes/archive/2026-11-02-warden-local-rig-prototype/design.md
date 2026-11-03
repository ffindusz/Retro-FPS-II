## Context

The user explicitly approved portable Blender LTS and a local-only Warden rig with idle, walk and one melee attack, isolated from the accepted game. Source metadata shows one static primitive (7,327 render vertices / 8,462 triangles), no skin or animation, original source SHA-256 `969cef958b48e06ce33e40d8efef62797a6cba104a045e4253ac16175135e2d4`. The masked, armored rest pose, close arms, coat/cape and carried blade make naive automatic weights risky.

## Goals / Non-Goals

**Goals:** verify/install external portable tooling; assess mesh regions; author an inspectable reproducible humanoid skeleton/normalized weights/rigid weapon; export actual bone animation; validate independently articulated limbs and weapon in an isolated Godot review scene.

**Non-Goals:** production-quality animation claims, fingers/facial animation, cloth simulation, retopology/new model generation, paid/remote rigging, live AI/damage integration, changing combat timings, replacing source models or re-exporting the accepted game/package.

## Decisions

1. **Portable Blender 4.5 LTS, verified official download.** Install outside the repository and run factory-startup/background with auto-execution disabled. Record exact version/download/checksum. No registry/PATH changes, add-on purchases, accounts or uploads. Blender remains authoring-only.
2. **Assessment precedes deformation.** Inspect mesh components with welded-position connectivity (analysis only), anatomical/weapon/cape bounds and representative views. Preserve original source bytes; keep derived output under `assets/prototypes/`. If weapon/limbs cannot be isolated safely, report the blocker rather than asserting a clean rig.
3. **Small, fitted humanoid armature.** Use named pelvis/spine/chest/neck/head, mirrored shoulder/upper-arm/forearm/hand and thigh/shin/foot chains, with a rigid weapon bone parented to the carrying hand. Author deterministic mesh-aware spatial weights with explicit semantic regions, maximum four normalized influences and rigid weapon assignment; inspect joints/cape rather than relying on unreviewed heat weights. Region assignments/landmarks remain inspectable in the authoring script/report.
4. **Preserve appearance without duplicating accepted texture sources.** Keep topology/UVs where feasible; export a separate normalized meter-scale glTF skin and three clips. Reuse the original imported material/1K textures in the Godot preview if the derivative exports without images. Keep editable `.blend` and authoring diagnostics in ignored `builds/authoring/`; source script and derived GLB/provenance remain available for reproduction/review.
5. **Bake modest in-place clips.** Idle, Walk and Attack use independent leg/arm/spine/weapon bone channels at 30fps, no horizontal root motion or gameplay callbacks. The attack retains a labelled 0.55s visual windup reference. Rigged animation is not authoritative damage; only a later integration change can connect them. Loop idle/walk deliberately and hold/replay attack through preview controls.
6. **Separate preview and proof of skinning.** Reuse stage concepts while retaining the prior whole-model study unchanged. Compare static original to rigged candidate; offer clip selection, pause/replay, view changes and skeleton/weight review when useful. Verify skeleton, clip tracks, bone deltas and CPU-skinned representative vertices (not just root transforms), rigid blade shape/hand following, normalized weights, cleanup and source/package isolation.
7. **Prototype export isolation.** Exclude `assets/prototypes/*` as well as existing scene/script prototype paths. Preserve existing game/version, original models/audio/navigation, accepted binaries and ZIP hashes. Run all original suites plus new focused offline/Godot tests and 720p/1080p captures.

## Risks / Trade-offs

- [Generated rest topology may bridge armor, hands, cape or sword] → Component/region assessment first; record any semantic face separation and preserve the original. Pause if meaningful independent deformation is infeasible without larger remodeling.
- [Spatial weights can pinch shoulders/hips or stretch cloth] → Constrain initial ranges, use explicit hand/weapon/cape regions, inspect extreme frames and document limitations instead of claiming production quality.
- [An animated skeleton could exist without deforming the mesh] → Verify joint/weight attributes and actual skinned vertex motion with fixed root transforms; mutation checks reject missing skin/animation.
- [Rigid weapon bends or leaves the hand] → Assign its vertices to one child bone and test pairwise distances/hand-relative attachment across sampled frames.
- [Walk slides or penetrates the floor] → Keep in-place motion and inspect foot extrema/loop boundary; document residual planting limits before human review. No navigation/root-motion claim.
- [New asset leaks into a later all-resource export] → Explicit asset/scene/script exclusions plus regression checks; do not touch accepted output files.

## Migration Plan

Create all tooling/assets/previews as additive prototype files. Review deformation and clips before changing the live enemy scene/state machine. The accepted model and package remain a rollback baseline without requiring a source-control reset.

## Open Questions

Does the first locally authored rig deform the generated shoulders/coat convincingly enough? Are the walk/attack clips useful foundations, or is manual mesh/weight refinement needed? These require user visual review; no approval or integration is inferred from the earlier unrigged preview test.
