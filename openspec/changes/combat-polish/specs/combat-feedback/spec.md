## ADDED Requirements

### Requirement: Confirm actual enemy damage
The HUD SHALL briefly confirm a hit only when a player-owned attack actually applies positive damage to a living enemy. A miss, blocking-world contact, owner/team exclusion, inactive/dead target, or duplicate contact SHALL NOT produce successful-enemy-hit confirmation. Melee and player magic SHALL use the same confirmation rule.

#### Scenario: Damage an enemy with either weapon
- **WHEN** a player melee contact or projectile applies positive enemy damage
- **THEN** a brief crosshair-centered hit marker appears for that confirmed event

#### Scenario: Hit only a wall or an invalid target
- **WHEN** a swing misses, a projectile strikes a wall, or damage is rejected
- **THEN** no successful-enemy-hit marker appears

### Requirement: Distinct and bounded world impacts
Confirmed enemy and blocking-world contacts SHALL produce distinguishable local visual feedback at the contact location. Impact visuals SHALL NOT apply gameplay damage. A swing SHALL produce at most one blocking-world feedback event; resolved projectiles SHALL produce at most one impact event. Effects SHALL expire within 0.5s of active gameplay and live world-impact instances SHALL NOT exceed 24.

#### Scenario: Repeated wall overlap
- **WHEN** several sweep queries contact the same blocking wall during one swing
- **THEN** wall feedback is emitted once for the swing without an enemy-hit marker or duplicate damage

#### Scenario: Exceed the effect budget
- **WHEN** more impact effects are requested than the live-effect limit
- **THEN** effects remain within the limit and older/low-priority presentation can be discarded without altering combat results

### Requirement: Readable reactions without obscuring play
Enemies receiving positive damage SHALL present a brief local hit reaction independent of attack-state progression. Positive player damage SHALL present a brief low-opacity screen-edge cue without hiding the crosshair, health display, or controls. Feedback SHALL NOT shake the camera, change FOV, slow time, or rewrite shared imported-model materials for other instances.

#### Scenario: Damage one of two enemies sharing a model
- **WHEN** one enemy receives a hit
- **THEN** only that enemy reacts and both actors retain correct imported materials and independent state

#### Scenario: Receive damage while aiming
- **WHEN** the living player receives positive damage during active gameplay
- **THEN** a brief edge cue appears while aiming and HUD values remain readable

### Requirement: Run-scoped feedback lifecycle
Feedback lifetimes SHALL freeze during pause and stale transient feedback SHALL clear on terminal/menu transitions and new runs. Repeated runs SHALL NOT accumulate feedback listeners, effect nodes, or callbacks. HUD refreshes and scene binding SHALL NOT create combat feedback without a combat event.

#### Scenario: Restart with active effects
- **WHEN** the player restarts while a marker, impact effect, or damage cue is active
- **THEN** the fresh run begins without old feedback or duplicate event reactions
