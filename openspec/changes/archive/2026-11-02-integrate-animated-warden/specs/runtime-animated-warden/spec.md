## ADDED Requirements

### Requirement: Approved visual in real melee encounters
All default melee Wardens SHALL use the approved c02 runtime body, full PBR material and separate rigid blade. Runtime dependencies SHALL reside outside excluded prototype/authoring paths. Adept and procedural fallback SHALL retain their existing visual behavior.

#### Scenario: Start a new run
- **WHEN** default encounters are created
- **THEN** the four melee Wardens SHALL use independent animated instances while the two Adepts, actor counts and gameplay fingerprints remain unchanged

### Requirement: Corrected rigid handle placement
The blade SHALL remain unskinned, fixed in the named carrying-hand frame at stable world scale, with its measured handle centre at the documented palm target rather than its scene origin. Actor repositioning, pose changes, pause and disposal SHALL not detach or leak the blade.

#### Scenario: Move and animate a Warden
- **WHEN** clips, actor transforms and review positions change
- **THEN** the handle centre SHALL track the palm target and blade geometry SHALL remain rigid without changing source mesh bytes

### Requirement: Authoritative attack and damage timing
Presentation SHALL map its inspected strike reference onto the existing 0.55s windup and SHALL NOT apply damage, alter attack rules or repeat damage. Nonlethal feedback SHALL not interrupt/restart committed attacks. Lethal damage SHALL immediately cancel attacks/collision before visual death playback.

#### Scenario: Warden completes a windup
- **WHEN** the unchanged AI resolves the attack
- **THEN** the sampled strike pose SHALL be at its documented reference and exactly the existing range/LOS-validated damage SHALL be eligible

#### Scenario: Hit during committed windup
- **WHEN** nonlethal damage is accepted
- **THEN** the original remaining windup/damage opportunity SHALL continue without replacement by a blocking hit clip

### Requirement: State-driven paused-safe presentation
Idle, actual-travel Walk, Attack/recovery, bounded Hit and held Death SHALL follow authoritative state with independent per-instance clocks/material feedback. Animation root translation SHALL not move the collider. Pause/results SHALL freeze clocks; restart/menu SHALL clean up old instances.

#### Scenario: Pause, die and restart
- **WHEN** these game transitions occur
- **THEN** no clock catch-up, stale attacks, duplicate blades or shared-instance reactions SHALL occur

### Requirement: Preserved gameplay and versioned export evidence
Health/damage/range/cooldowns/movement tuning, collision/navigation, placements/resources/objective rules and original source assets SHALL remain unchanged. A separate 0.5.0 build SHALL include the new runtime assets, exclude prototypes/tools/credentials and preserve the accepted 0.4.1 artifacts.

#### Scenario: Verify source and exported resources
- **WHEN** regression, fingerprint, resource audit and native startup checks run
- **THEN** the integrated build SHALL load all runtime resources without project-local fallback, retain gameplay invariants and leave frozen old artifact hashes intact
