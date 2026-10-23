## ADDED Requirements

### Requirement: Isolated one-enemy unrigged study

The project SHALL provide a separate Warden preview using existing normalized visuals with baseline/candidate whole-model motion. It SHALL label itself unrigged and visual-only, provide idle, in-place locomotion silhouette, attack, hit and death clips, and SHALL NOT instantiate gameplay actors, produce damage/events or change the main game.

#### Scenario: Launch the preview
- **WHEN** the prototype scene is run independently
- **THEN** both Warden visuals and readable limitation/comparison labels SHALL appear without entering the game session or capturing the mouse

#### Scenario: Model provenance is inspected
- **WHEN** the source Warden is checked
- **THEN** its original checksum SHALL be unchanged and its zero skins/clips SHALL be documented instead of claiming skeletal animation

### Requirement: Deterministic, grounded timing

Candidate poses SHALL be deterministic functions of clip/time, ground their transformed visual bounds, and show anticipation before a 0.55-second attack reference marker followed by release and recovery. The marker SHALL be explicitly visual-only.

#### Scenario: Attack timing is sampled
- **WHEN** the attack clip advances across 0.55 seconds
- **THEN** the phase SHALL change from anticipation to release without any gameplay damage

#### Scenario: Candidate poses are sampled
- **WHEN** each clip is sampled throughout its duration
- **THEN** all transforms SHALL be finite, bounded and nonpenetrating at the floor

### Requirement: Review controls and lifecycle

The preview SHALL support keyboard clip selection/auto sequence, pause/resume, replay and quit. Pause SHALL freeze clip time and transforms; replay SHALL restore a deterministic initial pose. Reopening SHALL not retain old preview nodes.

#### Scenario: Paused preview is advanced
- **WHEN** Space pauses playback and frames continue
- **THEN** the sampled time/pose SHALL remain unchanged until resumed

#### Scenario: Reviewer chooses a clip and replays it
- **WHEN** the reviewer selects a numbered clip or presses R
- **THEN** playback SHALL restart at that clip's initial pose without accumulating animation nodes

### Requirement: Preserve release gameplay

The accepted EXE/PCK, original model/gameplay resources and application version SHALL remain unchanged. Prototype paths SHALL be excluded from future Windows exports and all 269 existing gameplay/presentation checks SHALL still pass.

#### Scenario: Main demo runs after prototype addition
- **WHEN** the normal project and accepted package are checked
- **THEN** neither SHALL instantiate the preview and the existing regression suite SHALL pass
