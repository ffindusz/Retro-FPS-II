# fire-bat-enemy Specification

## Purpose
Defines the Fire Bat: a flying enemy that hovers, keeps its distance and spits fireballs, with its animated model, editor placement and Mapping Example appearance.

## Requirements
### Requirement: Flying fireball enemy
The game SHALL provide a Fire Bat enemy that flies at a hover height above the floor without gravity while alive, follows the navigation path horizontally, keeps a preferred distance from the player and backs off when the player is close.

#### Scenario: Engage the player
- **WHEN** the player is within detection range and in line of sight
- **THEN** the bat SHALL approach to its preferred range while staying near its hover height

### Requirement: Fireball attack
After a short windup, the bat SHALL fire a small fireball from its body toward the player. The fireball SHALL damage the player on hit and SHALL NOT be fired without line of sight.

#### Scenario: Fireball hits
- **WHEN** the windup ends with the player in sight
- **THEN** a fireball SHALL be spawned and damage the player when it reaches them

### Requirement: Bat death
When killed, the bat SHALL stop attacking, drop to the floor and play its death presentation.

#### Scenario: Kill a bat
- **WHEN** the bat's health reaches zero
- **THEN** it SHALL emit `died`, stop colliding with attacks and fall to the floor

### Requirement: Editor placement
Authored levels SHALL support a `Fire Bat` placement kind with an editor preview. The builder SHALL validate its floor anchor, navigation connection and hover clearance, and the runtime SHALL spawn a bat above the marker.

#### Scenario: Place a bat in the Mapping Example
- **WHEN** the Mapping Example with a bat placement is built and played
- **THEN** the level SHALL contain the bat at its hover height in addition to the existing enemies

### Requirement: Model and animation
The bat SHALL use a Meshy-generated textured model rigged with fly, attack, hit and death clips when available, and a procedural placeholder with flapping wings otherwise.

#### Scenario: Missing model
- **WHEN** the animated bat model is not available
- **THEN** the bat SHALL still play using the placeholder
