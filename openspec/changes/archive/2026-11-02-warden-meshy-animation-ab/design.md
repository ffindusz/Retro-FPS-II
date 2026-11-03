## Context

The user approved upload of the original textured +Z-facing Warden and a fixed 14-credit trial: one rig (5) plus actions 0/21/219 (3 each). The initial missing-key blocker is resolved; a read-only check returned 1,380 credits. The local 21-bone rig and accepted 0.4.1 package are existing baselines, not candidates to overwrite.

## Goals / Non-Goals

**Goals:** obtain exactly the authorized outputs safely, preserve raw results/provenance, provide a fair isolated comparison and distinguish motion, skinning, timing and root-motion effects.

**Non-Goals:** additional generations/actions, paid retries, Text to Motion, rebuilding the source model, subscriptions/purchases, live gameplay integration, replacing prior prototypes or declaring a winner from automated checks alone.

## Decisions

1. **Separate tightly scoped authoring tool.** Reuse the existing credential reader and safe downloader, not the old model-generation route allowlist. New routes are exact balance/library GETs, rig/animation POSTs and saved-task GETs only. Source SHA-256, height and action IDs are fixed. Read the ignored `.env` through the helper without ever printing it.
2. **Durable before-POST reservation.** External staging holds one sanitized record with an authorization ceiling of 14 and at most two paid stages. Reserve 5/9 and write SUBMITTING before sending. Save the returned opaque ID before polling. UNKNOWN/SUBMITTING without an ID, failures or excessive/missing charge reports stop the workflow; no automatic replacement task. Resuming a saved ID performs only GET/download calls. A lock prevents concurrent local submissions.
3. **No sensitive records.** Upload the hash-pinned original textured GLB as a data URI over HTTPS to Meshy only; do not upload the untextured -Z-facing local derivative. Persist source hash/size, height, IDs, whitelisted status/credit fields and downloaded file hashes, never model data URIs, keys, raw errors or signed URLs. Downloads never receive the API Authorization header.
4. **Stage then inspect.** Download raw rig and combined three-action GLBs outside the project before retention expires. Review skin, names, dimensions, topology/UVs/materials, metadata and rights. The prior user-confirmed paid-plan basis and current terms sections 2.4/3.1/3.2 apply; library Service Assets are licensed within output, not newly claimed as exclusively owned animation. Preserve original exports/metadata.
5. **Identical presentation, explicit confounds.** A new excluded A/B scene shows local rig left and Meshy right under the same stage/camera/light/material when compatible. Normalize rest height/orientation once, not per frame; record the transform. Different rigs/weights make this a pipeline comparison, not a pure motion-only experiment. If source UVs differ, retain native material and disclose that instead of forcing an incompatible atlas.
6. **Native timing plus labelled comparison modes.** Default sampling uses each clip's native duration/speed; a clearly labelled phase-match mode may retime both to a common period for pose comparison. Show both times/durations. Do not claim Meshy contact occurs at the local 0.55s reference. Optional anchored-root review must disclose exactly the removed horizontal cycle drift and preserve vertical motion/within-cycle sway; raw mode remains available.
7. **Measurements, not quality assertions.** Capture structural counts, loop/root-displacement and representative bone/skin/weapon behavior. Keep bad motion/deformation results visible rather than repairing one candidate invisibly. Tests prove clocks, controls, resources, actual animation, cleanup, safety and isolation; renders/human review decide usefulness. No gameplay damage/events/colliders/audio in the scene.

## Risks / Trade-offs

- [Timeout after a paid POST] → Persist ambiguous state and stop; reconcile saved task state rather than retrying.
- [Invalid/retired preset] → Verify exact IDs/names with free live library lookup before any POST; no substitute action without approval.
- [Rig/texture/topology differs] → Inspect returned data, normalize only documented presentation transforms and label pipeline confounds.
- [Root motion causes off-stage movement or misleading speed] → Expose native durations and raw drift; label optional compensation/phase retiming explicitly.
- [Automatic rig bends the blade or stretches cape] → Measure/show it as an A/B outcome; do not silently fix Meshy weights or claim success means superior quality.
- [Credentials accidentally exported] → Explicit tool/record whitelists, offline tests, existing export exclusions and package-hash checks.

## Migration Plan

All results live in external staging and excluded prototype paths. The original game, local derivative and package remain untouched. Review before any later integration choice.

## Open Questions

Which candidate reads better on the actual Warden, particularly foot contact, weapon grip and cape/shoulder deformation? Does any improvement justify later cleanup/retiming? Those remain human decisions after actual outputs are inspected.
