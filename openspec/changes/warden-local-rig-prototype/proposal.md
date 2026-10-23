## Why

The user tested the isolated whole-model Warden study and approved a local-only rigging workflow, including portable Blender LTS. The accepted Warden has no skeleton or clips; independently moving legs and a hand-carried blade require a real armature, skin weights and exported bone animation rather than more root transforms.

## What Changes

- Install checksum-verified official portable Blender LTS outside the repository, without registry/PATH changes, uploads, accounts or paid services.
- Assess source mesh connectivity, pose, armor/cape/weapon regions and deformation risks before authoring a separate derivative.
- Create a reproducible, locally authored humanoid Warden rig with normalized weights, a rigid hand-following blade and idle, in-place walk and one melee attack clip.
- Preserve source geometry/UVs/material appearance where feasible, and document any mesh-region separation/weight limitations honestly; do not replace the accepted source GLB.
- Add a separate Godot rig preview with clip, pause/replay and deformation review controls plus structural, skinning, playback, isolation and rendered checks.
- Preserve main game, enemy AI/damage/tuning, source models, 0.4.1 version, accepted EXE/PCK/ZIP and the prior whole-model preview. No integration or re-export of the accepted build.

## Capabilities

### New Capabilities

- `warden-skeletal-prototype`: Offline-authored derivative Warden armature, skinned body, rigid weapon and three independently testable skeletal animation clips.
- `warden-rig-review`: Isolated Godot preview and deterministic validation of real bone/skin deformation without gameplay effects.

### Modified Capabilities

None. Existing gameplay and accepted presentation remain unchanged.

## Impact

New optional Blender authoring script and assessment/provenance records; derived prototype GLB/authoring artifact; separate Godot preview/tests/captures. Prototype assets must be excluded from future exports alongside existing prototype scenes/scripts. Blender is a development-only dependency installed externally, not a runtime dependency or a redistributed tool. Human deformation review remains a gate before considering gameplay integration.
