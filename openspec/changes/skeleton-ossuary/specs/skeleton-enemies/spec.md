## ADDED Requirements

### Requirement: Skeleton warrior
The game SHALL provide a Skeleton melee enemy using the supplied skeleton warrior model. It SHALL idle when it has not noticed the player, walk or run along the navigation path depending on its speed, and slash with its sword after a windup, damaging the player within melee range.

#### Scenario: Warrior attacks
- **WHEN** a Skeleton reaches melee range of a visible player and its windup ends
- **THEN** the attack clip SHALL reach its contact pose and the player SHALL take the Skeleton's damage

### Requirement: Skeleton archer
The game SHALL provide a Skeleton Archer ranged enemy using the supplied archer model. After drawing its bow, it SHALL shoot an arrow projectile toward the player, and it SHALL NOT shoot without line of sight.

#### Scenario: Archer shoots
- **WHEN** a Skeleton Archer has a visible player within range and its windup ends
- **THEN** an arrow SHALL be spawned from the archer that damages the player on hit and uses arrow (not magic) feedback

### Requirement: Skeleton presentation
Both skeletons SHALL play their idle, walk, run, attack and death clips at the matching gameplay moments, show a visible hit reaction, keep their glowing red eyes pulsing while alive, and extinguish the eyes on death.

#### Scenario: Skeleton dies
- **WHEN** a skeleton's health reaches zero
- **THEN** it SHALL emit `died`, stop colliding with attacks, play its death clip once and its eyes SHALL go dark

### Requirement: Editor placement
Authored levels SHALL support `Skeleton` and `Skeleton Archer` placement kinds, appended after the existing kinds, with editor previews and the builder's ground enemy checks.

#### Scenario: Place skeletons
- **WHEN** an authored map with skeleton placements is built and played
- **THEN** the runtime SHALL spawn the matching enemies at the markers

### Requirement: Ossuary test map
The project SHALL include a second built test map, The Ossuary, with skeleton warriors and archers, a key and an exit. It SHALL be listed in Choose Level and SHALL be reachable from the main menu.

#### Scenario: Play the Ossuary
- **WHEN** the player chooses The Ossuary
- **THEN** the map SHALL load with its skeletons, and collecting the key and reaching the exit SHALL complete it
