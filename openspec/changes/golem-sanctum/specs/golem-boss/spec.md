## ADDED Requirements

### Requirement: Dormant stone golem
The game SHALL provide a Stone Golem boss built from the supplied golem model. It SHALL start dormant: motionless, not animating, with dark eyes. It SHALL wake when the player comes within its wake range with line of sight, or when it takes damage.

#### Scenario: Player approaches
- **WHEN** the player comes within 6 m of a dormant golem with a clear line of sight
- **THEN** the golem SHALL wake (shake, dust, eyes lighting up) and then chase the player

#### Scenario: Player stays away
- **WHEN** the player is beyond wake range or behind the closed seal
- **THEN** the golem SHALL stay dormant and motionless

### Requirement: Hammer slam
An awake golem SHALL walk at the player and slam its hammer after a telegraphed windup, damaging the player only if the player is still within its melee range when the hammer lands.

#### Scenario: Slam lands
- **WHEN** the windup ends with the player within 3 m and in line of sight
- **THEN** the player SHALL take the golem's damage

#### Scenario: Slam dodged
- **WHEN** the player moves out of reach during the windup
- **THEN** the slam SHALL deal no damage

### Requirement: Boss health bar
While a boss is awake, the HUD SHALL show its name and a health bar that follows its health. It SHALL hide the bar shortly after the boss dies, on restart and in menus.

#### Scenario: Fight begins
- **WHEN** the golem wakes
- **THEN** the boss bar SHALL appear with "STONE GOLEM" and full health

### Requirement: Golem holds the key
A key placed with a golem SHALL be hidden and uncollectable until that golem dies, and SHALL then appear where the golem fell.

#### Scenario: Golem dies
- **WHEN** the golem's health reaches zero
- **THEN** after about a second the key SHALL appear at the golem's position and the player SHALL be able to collect it

### Requirement: Bone seal
A Bone Seal SHALL block its doorway (movement, projectiles and line of sight) until every enemy in the level other than golems has died, then open once.

#### Scenario: Last skeleton dies
- **WHEN** the last non-golem enemy dies
- **THEN** the seal SHALL stop blocking, sink away and show its open message

### Requirement: Golem Sanctum
The Ossuary SHALL include a round Golem Sanctum behind a bone seal, with the dormant golem and the ember key on a walkable pedestal in the middle, golem statues and lamps as decoration, and the exit gate on its far wall.

#### Scenario: Finish The Ossuary
- **WHEN** the player kills every skeleton, defeats the golem, takes the key and uses the sanctum gate
- **THEN** the run SHALL end in victory

### Requirement: Editor placement
Authored levels SHALL support `Bone Seal`, `Stone Golem` and `Golem Statue` placement kinds, appended after the existing kinds, with editor previews. The builder SHALL check the golem's larger footprint for overlap.

#### Scenario: Golem in a wall
- **WHEN** a Stone Golem marker is placed so its body overlaps world collision
- **THEN** the build SHALL fail with an overlap issue
