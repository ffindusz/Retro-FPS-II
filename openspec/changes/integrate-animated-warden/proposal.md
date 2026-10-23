## Why

The user approved the selected new Warden's appearance and animations, reported a slightly off sword mount, and requested using it in the project. The pilot must now become a self-contained runtime visual driven by authoritative enemy state, with a measured grip correction rather than a preview-only asset or an animation that changes combat balance.

## What Changes

- Measure/correct the sword handle-to-palm mount and share the calibrated attachment with the pilot and runtime visual.
- Promote unchanged copies of the approved c02 body/texture/animation outputs into runtime asset paths; retain originals, prior prototypes and provenance. No new Meshy requests or credits.
- Use the new animated visual for the four melee Wardens only. Keep Adept, procedural fallback, colliders/navigation, placements, health/damage/ranges, 0.55s windup, cooldowns and resource/objective rules unchanged.
- Drive Idle/Walk/Attack/Hit/Death from gameplay, sample visual strike at the existing damage boundary, suppress nonlethal hit-clip interruption of committed attacks, remove root-motion displacement and hold death after immediate gameplay cancellation.
- Validate pause/results/restart, per-instance feedback/materials, rigid hand following, native resource inclusion and gameplay fingerprints in source and packaged tests.
- Version the integrated project as 0.5.0 and produce a separately versioned Windows validation build without overwriting the accepted 0.4.1 EXE/PCK/ZIP. Keep authoring/prototype paths excluded.

## Capabilities

### New Capabilities

- `runtime-animated-warden`: State-driven runtime Warden visual, corrected rigid grip and exportable resources without gameplay-balance changes.

### Modified Capabilities

None in canonical `openspec/specs/` (none exist). Prior change acceptance histories remain intact; new integration scenarios specify preservation of existing gameplay contracts.

## Impact

Add runtime assets/presentation/grip code and a visual wrapper; update the melee model selection and minimal enemy presentation hooks. Adjust tests that assumed static mesh bounds or the historical project version, while preserving their gameplay assertions. Add state/timing/attachment/export regressions, actual-level renders and a short same-view comparison. Project/export/menu metadata and delivery evidence change; no accepted source model or 0.4.1 package is discarded.
