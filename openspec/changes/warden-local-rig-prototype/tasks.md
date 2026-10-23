## 1. Tooling and feasibility

- [x] 1.1 Install/verify official portable Blender LTS externally and record version/checksum/authorization.
- [x] 1.2 Inspect normalized source mesh components and anatomical/weapon/cape regions; record topology risks and preserve source hashes.

## 2. Local skeletal asset

- [x] 2.1 Add reproducible local authoring with fitted humanoid bones, normalized mesh-aware weights and rigid hand-following blade.
- [x] 2.2 Author/bake Idle, in-place Walk and Attack clips with a labelled 0.55-second visual windup reference and inspect deformation extrema/loop endpoints.
- [x] 2.3 Save editable authoring output and a separate derived GLB/provenance, retaining accepted appearance and source geometry/UVs where feasible.

## 3. Independent Godot review

- [x] 3.1 Add a separate rig preview with static comparison, clip/pause/replay and deformation-view controls; no gameplay effects.
- [x] 3.2 Exclude prototype assets from future exports and preserve accepted game/version/model/build/package hashes.

## 4. Verification and handoff

- [x] 4.1 Add offline structural/weight/source-isolation checks and Godot skin/bone/rigid-weapon/playback/lifecycle checks; prove focused failures with animation disabled.
- [x] 4.2 Run original game/whole-model/package/offline checks and inspect rig captures at 720p/1080p without script/runtime errors.
- [x] 4.3 Document tooling, authoring/rebuild/preview instructions, exact evidence and limitations without claiming gameplay integration or human approval.
- [ ] 4.4 Obtain human review of shoulder/hip/cape/weapon deformation and walk/attack usefulness before considering gameplay integration.
