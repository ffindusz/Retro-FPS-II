## Context

The user approves the selected c02 appearance/animations, requests project adoption and reports a slightly off sword mount. Current melee AI owns 68 health, 12 damage, 1.9m attack distance, 0.55s windup and 1.6s cooldown; nonlethal hits preserve committed attacks. The Adept inherits the same base scene/script and must keep its existing visual/ranged rules. Pilot assets/code are deliberately export-excluded, so runtime integration needs independent resource paths/code, not references into prototypes.

## Goals / Non-Goals

**Goals:** correct the measured grip, use the approved Warden in real encounters, synchronize presentation to existing gameplay, preserve fallback/Adept/baselines and validate an exportable 0.5.0 project/build.

**Non-Goals:** more Meshy requests/credits, new enemies, damage/balance/layout/collider/navigation changes, animation-driven damage/root motion, professional foot IK/finger rigging, replacing the accepted 0.4.1 files or claiming a new human/offline acceptance pass.

## Decisions

1. **Additive runtime promotion.** Copy approved raw `texture.glb`/`animate.glb`, 1K texture import settings and source/rights provenance into `assets/models/warden-animated/`. Use a new runtime visual scene/script selected only by the melee scene. Keep the original static visual, raw prototypes and all accepted source hashes intact. Runtime code/resources must have no prototype/authoring/API dependency.
2. **Measured shared grip configuration.** The blade wrapper's origin is not its handle centre. Full geometry/colour profiling and viewport markers identified the dark leather centre as `(-0.000733, 0.041225, -0.001466)m`; use hand-palm target `(0.015, 0.115, 0.025)m`, existing orientation and 0.75 world scale. The preliminary brown-only filter incorrectly selected the brass pommel at `(-0.003175, -0.114778, 0)`; that measurement/8.6cm claim is superseded by the corrected ~3.1cm handle-origin compensation. Share constants/follower code with the pilot, use an orthonormal world hand frame to remove centimetre/shear scale and inspect close-up contact/idle views. No source mesh edits or weapon skin weights.
3. **Presentation component, not an AI rewrite.** Enemy instantiation detects the new visual interface. Minimal hooks begin attacks, report actual windup/physical travel, mark the authoritative resolution boundary, notify confirmed damage/death and advance visuals. Existing range/LOS/damage/cooldown/navigation/collision behavior remains authoritative. Legacy procedural/static/Adept feedback uses its existing path.
4. **Deterministic state/pose priorities.** Death > committed attack/recovery > brief noninterrupting hit reaction > movement-driven Walk > Idle. Map the inspected native strike reference onto the existing 0.55s windup; sample that pose before `resolve_attack`, then finish visual recovery without blocking AI. Nonlethal hits never restart/cancel the windup or replace its telegraph. Use a per-instance bounded tint cue during protected attacks; Hit clip is cosmetic outside them. Lethal damage disables collision/attacks immediately, then plays/holds the native death pose.
5. **Manual pose sampling and short transitions.** Drive animation clocks from enemy physics, not wall time or render FPS. Strip horizontal root translation so animation cannot displace the character relative to its collider; preserve vertical body motion. Walk phase uses actual horizontal travel/configured stride (including collision stalls), not merely a CHASE enum. Short per-bone transition blending avoids abrupt clip changes; no method/audio animation tracks can apply gameplay effects.
6. **Rigid follower updates independently of animation aging.** Pose sampling updates the weapon immediately; a render callback may only refresh its transform when the actor is teleported/rotated with AI disabled. Pause/results stop clocks through normal inherited processing. Frozen animation does not leave a top-level blade behind when a developer repositions an actor. Restart/disposal must free every descendant.
7. **Correct bounds and resource isolation.** Cache actual meter-scale rest bounds from approved data rather than interpreting the raw centimetre-parent mesh-node AABB as rendered size. Provide conservative skinned culling bounds and independently validate them; import tests should check genuine body rest bounds, not transient weapon swings. Shared texture resources are retained, while mutable flash materials/pose state are per-instance.
8. **Versioned delivery and honest cost.** Update project/menu/export metadata to 0.5.0, write the Windows build to a separate versioned folder and retain frozen 0.4.1 binaries/ZIP and packaging record. Preserve all prototype exclusions. The 11,376 body+blade source-triangle cost remains an explicit guideline exception; collect a short same-view sample and do not turn it into a universal FPS claim.

## Risks / Trade-offs

- [A clip's apparent strike is not the old damage instant] → Inspect native hand/blade motion and map its reference frame to the unchanged windup; test both the pose and actual single damage event including cover/misses.
- [Hit animation stuns/cancels attacks] → Attack priority and authoritative timers remain untouched; cosmetic hit handling is tested mid-windup.
- [Source rig root movement/centimetre binds affect collision or scale] → Separate in-place visual sampling, explicit unit grip compensation, body-only rest/culling validation and unchanged gameplay fingerprints.
- [New full-body gait slides at existing move speed] → Travel-based phase/explicit stride; inspect real navigation and document remaining foot-planting limits rather than altering speed or buying clips.
- [Correct handle centre still leaves open fingers/pose clipping] → Close-up visual verification and user review; no claim of closed fingers/cloth physics.
- [Historical tests hardcode 0.4.1/static bounds] → Preserve gameplay assertions, adapt only the superseded presentation/version assumption, and retain frozen package hashes separately.

## Migration Plan

Record before evidence against the retained 0.4.1 package, add runtime resources/component, switch the melee visual, fix grip in both runtime/pilot and verify source/package behavior. Export 0.5.0 separately. Rollback is an explicit visual-scene choice, not deletion/reset of user work or old packages.

## Open Questions

Does the corrected mount and integrated state timing feel right during an actual run? Does the live cost justify a lower world-weapon LOD later? Those remain human/performance review points after technical integration.
