## ADDED Requirements

### Requirement: Local-only reproducible authoring

The rig SHALL be authored locally using checksum-verified official portable Blender LTS, without paid services, uploads or changes to the accepted source model. Tool/version/source and derived artifact provenance SHALL be recorded.

#### Scenario: Rebuild the prototype
- **WHEN** the authoring script runs against the recorded original Warden
- **THEN** it SHALL create a separate editable authoring file, derived GLB and report without overwriting the original model or game build

### Requirement: Real humanoid skin and rigid weapon

The derivative SHALL contain a humanoid armature with independently deforming leg/arm chains, finite normalized nonnegative skin weights with at most four influences per vertex, and a rigid weapon attached to the carrying hand. Mesh-region changes and deformation limitations SHALL be documented.

#### Scenario: Limb animation is sampled with a fixed root
- **WHEN** a walk or attack clip changes limb bone poses
- **THEN** corresponding skinned vertices SHALL move relative to the torso without moving the scene root

#### Scenario: Weapon is animated
- **WHEN** the carrying hand moves through attack poses
- **THEN** weapon vertices SHALL follow it while preserving their pairwise distances and hand-relative attachment

### Requirement: Three usable in-place clips

The derivative SHALL export Idle, Walk and Attack animations with independent bone tracks, finite bounded poses, no horizontal root motion or gameplay callbacks, and a documented 0.55-second attack visual windup reference. Idle/Walk SHALL have continuous loop endpoints.

#### Scenario: Imported clips are inspected
- **WHEN** the derivative is imported in Godot
- **THEN** all three clips SHALL be available and change actual bone poses instead of relying only on root transforms
