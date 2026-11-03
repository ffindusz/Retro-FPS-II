## ADDED Requirements

### Requirement: Actual isolated comparison
The scene SHALL compare the unchanged local rig with actual downloaded Meshy results under common presentation, with documented rest normalization, native clip durations and explicit rig/weight/material differences. It SHALL not instantiate gameplay actors, effects or damage.

#### Scenario: Select a comparison action
- **WHEN** Idle, Walk or Attack is selected
- **THEN** both actual rigs SHALL animate with clearly labelled source and timing information

### Requirement: Honest clocks and root-motion treatment
Native-speed playback SHALL be available. Any phase matching or horizontal drift compensation SHALL be labelled and reversible; neither SHALL change raw exports or imply matching damage/contact timing.

#### Scenario: Toggle timing or root review mode
- **WHEN** the reviewer changes modes
- **THEN** labels/times SHALL disclose the transformation and raw playback SHALL remain recoverable

### Requirement: Regressions and human decision
Safety, actual animation, controls, pause/replay, cleanup and isolation SHALL have automated coverage and both-resolution captures. Structural/deformation observations SHALL not substitute for human quality preference. Existing source models, local rig and accepted EXE/PCK/ZIP hashes SHALL remain unchanged.

#### Scenario: A/B work is validated
- **WHEN** original suites and artifact checks are rerun
- **THEN** they SHALL still pass and no accepted build SHALL contain the comparison resources
