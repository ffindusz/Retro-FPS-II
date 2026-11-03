## ADDED Requirements

### Requirement: Isolated rigged review scene

A separate preview SHALL compare the original static Warden against the rigged derivative with clip selection, pause/resume and replay controls and clear prototype/no-gameplay labels. It SHALL reuse the accepted appearance and SHALL NOT create AI, gameplay colliders, damage, projectiles or combat audio.

#### Scenario: Reviewer selects walk or attack
- **WHEN** the standalone preview is run and a clip selected
- **THEN** the right-hand candidate SHALL visibly articulate bones/skin while the comparison original remains unmodified

#### Scenario: Reviewer pauses and replays
- **WHEN** pause or replay input is sent
- **THEN** the rig SHALL freeze or reset deterministically without accumulated actors/animation players

### Requirement: Structural and deformation evidence

Validation SHALL check GLB skin/joints/weights/clips, actual independent skinned vertex motion, rigid weapon behavior, fixed root and lifecycle, and rendered 720p/1080p poses. Focused checks SHALL reject disabled skinning or bone animation. Human deformation approval SHALL remain separate from technical results.

#### Scenario: Skeleton animation is disabled
- **WHEN** the implementation no longer drives the skin/bones
- **THEN** focused deformation/playback checks SHALL fail even if the model still renders

### Requirement: Preserve accepted game and package

The original Warden, main game/version, gameplay tuning and accepted EXE/PCK/ZIP SHALL remain unchanged. Prototype assets, scenes and scripts SHALL be excluded from future exports; existing game and whole-model study regressions SHALL continue to pass.

#### Scenario: Prototype is added
- **WHEN** normal game tests and accepted artifact checks are rerun
- **THEN** the game SHALL preserve its baseline and accepted artifact hashes while only the isolated preview uses the new rig
