## Why

The user confirmed that the exported 0.4.1 Windows build works and approved packaging that baseline before prototyping animation for one enemy. The Warden source has zero skins and animation clips, so an isolated whole-model motion study can establish useful timing without pretending to supply skeletal walking or risking the accepted game.

## What Changes

- Package the exact accepted EXE/PCK into a versioned portable playtest ZIP with controls, credits, engine/component license notices and checksums; do not re-export or silently include prototype code.
- Record the user's native-build confirmation without inferring disconnected or detailed checklist coverage.
- Add an editor/project-only Warden motion-study scene comparing current presentation with candidate idle, locomotion silhouette, anticipation/release/recovery, hit and death poses.
- Provide deterministic controls, pause/replay, automated pose/lifecycle checks and rendered evidence. Label the absence of rigging and gameplay integration prominently.
- Keep the main scene/version, source models, gameplay code/tuning, existing export and earlier unreported acceptance tasks unchanged. No paid services, new model generation or public publishing.

## Capabilities

### New Capabilities

- `portable-playtest-bundle`: Reproducible local Windows ZIP packaging with an exact file allowlist, notices and verified binary hashes.
- `warden-motion-study`: Isolated one-enemy visual timing study with deterministic clips, comparison controls and honest unrigged limitations.

### Modified Capabilities

None. Existing gameplay and accepted presentation are not changed.

## Impact

New release packaging tooling/docs/notices, a Python packaging regression suite, isolated prototype scene/scripts and Godot prototype tests/render capture. Standard Python/Godot only at execution; license notices are fetched once from the matching official engine source and bundled locally. The output is a local playtest package, not a declaration of a project-wide distribution license or a public release.
