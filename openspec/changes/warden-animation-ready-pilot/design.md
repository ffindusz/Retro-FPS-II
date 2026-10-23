## Context

The prior 14-credit A/B succeeded but all 180 blade vertices in its automatic rig received leg-related influences. The new pilot has explicit approval for three 20-credit body previews, one 10-credit PBR refine, one 5-credit rig and five 3-credit presets: **90 total**, no extra paid retries. Current free balance check: 1,366. Existing game/art/exports remain accepted baselines.

## Goals / Non-Goals

**Goals:** generate genuinely animation-oriented alternatives, inspect before selecting, produce one fully inspectable pilot and remove the sword from character skinning entirely.

**Non-Goals:** generating the Adept/props, spending remaining account credits generally, new paid variants/retries, Ultra geometry, standalone paid remesh/retarget/conversion, live combat integration, replacing accepted files or exporting a new game release.

## Decisions

1. **Fixed versioned plan.** Use `meshy-7.1`, standard geometry, `pose_mode: a-pose`, integrated remesh enabled with 8,000 triangle target, GLB only. Three original prompts share red-cloth/iron/stone-mask direction while varying armor silhouette. No held objects, cape, long robe, scenery, insignia or copied characters. Texture only the selected preview with 2K/PBR; cap Godot imports at 1K.
2. **Checkpointed six-stage authorization.** Reserve 20+20+20+10+5+15 before each respective POST in an external fixed pilot directory. Persist IDs before polling. UNKNOWN/SUBMITTING without an ID and failed stages cannot be replaced. One lock avoids concurrent spending. Missing/new stages require `--submit`; resume mode never pays. A canonical plan hash prevents silently changing prompts/actions/budget mid-trial. No key, signed URL, raw error body or source data URI in records.
3. **Candidate selection gate.** Download/inspect all three previews and retain hashes plus actual views. Selection must be explicit in the record; ask the user if visual preference is needed. Once any downstream stage is reserved, selection cannot change. If no candidate has adequate separated limbs/empty hands/anatomy, stop rather than consume the remaining 30 credits on a bad input.
4. **One downstream winner.** Refine references the selected preview task. Rig references that successful textured task with the intended body height. Animation uses one batch for Idle (`0`), Walk Fight Forward (`21`), Right-hand Sword Slash (`219`), Hit Reaction (`178`) and Dead (`8`), after free live lookup confirms exact entries. No substitution or more actions without approval.
5. **Isolated review assets.** Preserve raw files/checkpoints outside the project and backup under ignored authoring output. Import reviewed copies only under excluded prototype paths; keep source metadata/provenance. Normalize from actual skinned rest bounds to avoid the prior centimetre-armature issue. Reuse selected body PBR maps when returned animation has only albedo, after UV compatibility checks.
6. **Weapon is a rigid hand attachment.** Reuse the accepted separate Iron Blade model, unskinned and parented/following the rig's carrying hand bone with documented grip/scale calibration. Compensate armature units so its world size is stable. Tests must show fixed hand-relative attachment and constant weapon shape across all clips; no skin weights can attach it to a leg because it is not in the body mesh.
7. **Technical evidence versus acceptance.** Show native five-clip playback with pause/replay/views/skeleton review, no AI/damage/colliders/audio. Check counts, source hashes, clips, material limits, actual skin movement, rigid attachment, pose/loop observations and lifecycle. Render both resolutions and leave body/hand/armor/foot/contact quality to human review. Existing suites and package hashes must remain green.

## Risks / Trade-offs

- [Generated pose or anatomy violates request] → Review actual three candidates before downstream spend; no automatic regeneration.
- [Body/armor still deforms poorly] → Empty hands and separated limbs reduce one failure mode, not all; inspect and report limitations rather than promising production quality.
- [Open/resting hand does not look clenched around the grip] → Calibrate a reusable rigid attachment and review the result; finger posing/remodeling is not silently claimed solved.
- [API timeout after paid submission] → Durable ambiguous reservation blocks new POSTs; reconcile existing ID/state instead.
- [Texture/rig processing changes geometry or loses PBR maps] → Preserve raw output and validate UV/material compatibility; no hidden retopo or paid repair.
- [Source/capsule/attack timing changes by accident] → Prototype-only import/scene, existing asset/build hash checks, no live enemy replacement.

## Migration Plan

Generate and review candidates first, select one explicitly, then finish within the remaining authorized budget. Offer the completed pilot for review before any separate gameplay integration or Adept work. Accepted files remain untouched rollback references.

## Open Questions

Which candidate has the strongest combination of readable Warden identity and clean riggable anatomy? Does the finished motion/attachment quality justify later integration? Those are review gates, not assumptions supplied by successful API tasks.
