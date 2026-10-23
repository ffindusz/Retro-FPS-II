## ADDED Requirements

### Requirement: Inspect actual empty-handed candidates
The pilot SHALL retain and present all three actual preview meshes with their generation parameters, counts and hashes. It SHALL review pose, empty hands, limb gaps, feet, clothing and unwanted accessories before selecting one for downstream work.

#### Scenario: No candidate is suitable
- **WHEN** inspection finds none meets the basic animation-oriented constraints
- **THEN** the pilot SHALL pause before texturing/rigging rather than silently generate more candidates

### Requirement: Five-clip rig with separate rigid blade
The standalone pilot SHALL provide actual Idle/Walk/Attack/Hit/Death clips and reuse the accepted Iron Blade as a separately calibrated unskinned carrying-hand attachment. The blade SHALL not be part of the character's skin or follow leg weights.

#### Scenario: Sample all five clips
- **WHEN** the hand and body animate
- **THEN** the separate blade SHALL retain its shape and a fixed hand-relative attachment with stable world scale

### Requirement: Isolated validated handoff
The prototype SHALL expose native playback and review controls, contain no gameplay actors/damage/navigation/audio, and preserve original sources, prior prototypes, application version and accepted EXE/PCK/ZIP. Both-resolution captures and structural/attachment/lifecycle/safety checks SHALL precede human quality review.

#### Scenario: Completed pilot is reviewed
- **WHEN** verification runs
- **THEN** existing checks/artifact hashes SHALL remain unchanged and no output SHALL be declared production-ready or integrated solely because generation/tests succeeded
