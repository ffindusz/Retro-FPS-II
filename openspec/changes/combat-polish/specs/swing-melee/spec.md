## ADDED Requirements

### Requirement: Phase-timed melee contact
The iron blade SHALL use windup, active contact, and recovery phases driven by one authoritative attack cycle. The default durations SHALL be 0.12s, 0.16s, and 0.24s respectively, with configurable positive tuning values. Damage SHALL occur only for contacts in the active interval, not on initial input or during recovery. The 3D viewmodel SHALL show preparation, the corresponding striking stroke, and return using that cycle's progress.

#### Scenario: Start and complete a swing
- **WHEN** the player begins a ready melee attack with an enemy in reach
- **THEN** windup deals no damage, active contact can damage the enemy as the blade strikes, and recovery deals no additional damage

#### Scenario: Cross a phase boundary on a long physics step
- **WHEN** a physics step spans the whole or part of the active interval
- **THEN** the crossed contact interval is evaluated once along its sweep path rather than skipped or applied as repeated endpoint hits

### Requirement: Reach-limited frontal sweep
Melee SHALL cover a moving frontal arc rather than only the crosshair line. The default configured reach SHALL remain 2.7m and damage SHALL remain 34 without a mana cost. A target intersecting the active sweep within reach SHALL be eligible even when off the crosshair; out-of-reach and behind-player targets SHALL NOT be hit. Contact eligibility SHALL use world physics, independent of overlay-mesh collision.

#### Scenario: Strike an off-center target
- **WHEN** an exposed living enemy is within reach and intersects the active arc but not the center ray
- **THEN** it receives one melee damage event

#### Scenario: Reject targets outside the attack envelope
- **WHEN** an enemy is behind the player or beyond the configured reach, including the sweep volume's outer edge
- **THEN** that enemy receives no damage from the swing

### Requirement: Occlusion and per-attack deduplication
Melee SHALL respect the first blocking world contact along each evaluated contact path, including near walls and corners. Each exposed target SHALL take damage at most once per swing even across overlapping queries or physics steps. The arc SHALL be able to strike multiple exposed targets once each; a blocked target SHALL NOT be damaged just because another target in the same swing is visible.

#### Scenario: Swing beside a pillar
- **WHEN** one candidate is exposed and another candidate's contact path is blocked by the pillar
- **THEN** only the exposed candidate receives damage

#### Scenario: Overlap targets for several contact steps
- **WHEN** two exposed enemies remain inside overlapping sweep queries throughout the active interval
- **THEN** each receives one damage event for that attack, not one per query or frame

### Requirement: Attack commitment and weapon selection
A committed swing SHALL enforce its full recovery before another attack starts. Holding attack SHALL repeat only when the cycle is ready. Weapon requests during a swing SHALL defer to recovery end, applying the most recent requested slot without resetting either weapon's cooldown or creating another attack from the switch itself.

#### Scenario: Request a switch during windup
- **WHEN** the player requests the staff while a melee cycle is committed
- **THEN** the current cycle completes under its original timing and the staff becomes selected at recovery end with cooldowns preserved

### Requirement: Pause and terminal attack ownership
Pause SHALL freeze melee progress, contact history, and its animation; resume SHALL continue without elapsed-time catch-up. Player death, victory, menu return, and disposal SHALL prevent any further attack damage from that run. Restart SHALL clear pending attacks, queued selection, and contact history.

#### Scenario: Pause before contact
- **WHEN** the player pauses during windup and resumes later
- **THEN** no damage or progress occurs while paused and contact proceeds from the saved phase after resume

#### Scenario: End the run before contact
- **WHEN** the player dies or the run ends before a pending contact
- **THEN** that contact never applies damage, including after restart
