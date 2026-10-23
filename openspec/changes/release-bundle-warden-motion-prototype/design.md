## Context

The accepted Windows 0.4.1 EXE/PCK already pass 269 packaged checks and native startup; the user now confirms the build works. Existing Warden/Adept GLBs each contain one static mesh, zero skins and zero clips. The main enemy script already supplies a whole-model windup lean, hit scaling and a death tween. A true limb/walking animation requires separately scoped rigging/weights; this first prototype must not claim otherwise.

## Goals / Non-Goals

**Goals:** preserve and package the exact accepted binaries; include offline controls/credits/notices and checksums; assess one existing enemy through a deterministic side-by-side visual study; prove isolation and preserve all gameplay regressions.

**Non-Goals:** public publishing, selecting a source/distribution license for the owner, silently closing old acceptance tasks, paid services, new model generations, skeletal deformation, AI/damage/collider changes, a second level or a new game release/version.

## Decisions

1. **Explicit package allowlist and pinned baseline.** A standard-library Python tool reads a tracked 0.4.1 artifact record, verifies both accepted binary hashes/sizes, then writes a deterministic versioned ZIP containing only EXE, PCK, player README, credits, engine license/copyright notices and SHA-256 sums. Unrelated files in `builds/windows` are never globbed. Existing different output is not overwritten. This is preferable to zipping a workspace folder or re-exporting after prototype files arrive.
2. **Offline notices from the exact official engine release.** Preserve Godot's license and component copyright notices verbatim with URL/hash provenance. Credits identify Meshy AI origin/paid-plan basis, Poly Haven CC0 authors and original project assets, without inventing an overall game license or legal clearance.
3. **Separate visual-only scene.** `scenes/prototypes/warden_motion_study.tscn` uses two existing normalized Warden visuals, not enemy/player instances. The left side approximates current whole-model presentation; the right samples candidate timing. A pure pose sampler provides idle, in-place locomotion silhouette, attack (existing 0.55s anticipation marker), hit and death clips. Transforming visual bounds keeps the candidate grounded. No physics, AI, damage or combat events exist in the sandbox.
4. **Deterministic review controls.** Number keys choose clips/auto sequence; Space pauses; R resets; Escape quits. UI names phases and labels contact as a visual timing reference, not actual damage. A fixed scene/camera/light setup supports 720p/1080p viewport-only captures. No desktop automation/capture, network or new audio.
5. **No accidental integration.** Main scene/version, existing enemy script/scenes, model bytes and accepted binaries remain untouched. Prototype paths are excluded from future exports. Tests cover deterministic sampling, bounds/phase transitions, real preview input, pause/replay, scene cleanup and unchanged original gameplay checks.

## Risks / Trade-offs

- [Rigid feet and weapon cannot move independently] → Label locomotion as an in-place silhouette study, not a walk cycle; document rigging as the recommended next experiment if approved.
- [Comparing visual timing could imply changed damage] → Keep both examples visual-only, retain the 0.55s marker and explicitly state no gameplay integration.
- [Whole-body rotations intersect the floor] → Correct candidate translation from transformed normalized mesh bounds and test all sampled frames.
- [Notices imply a public project license] → State the project-wide license remains the owner's decision; provide a local playtest bundle, not a public release claim.
- [Prototype accidentally enters a later build] → Add explicit prototype path exclusions and retain exact accepted binary hashes in the bundle.

## Migration Plan

Package and verify the accepted binaries first. Add isolated scene/tool/tests without replacing any live actors. Review the preview, then decide whether to obtain/author a proper rig. Removal of prototype paths reverts the experiment; the ZIP and accepted EXE/PCK remain identical.

## Open Questions

Does the user approve the candidate anticipation/recovery/death timing? If so, should a later change locally rig the existing Warden or use a separately authorized rigging service? No such service or credits are authorized by this change.
