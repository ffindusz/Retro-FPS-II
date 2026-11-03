## ADDED Requirements

### Requirement: Additional procedural light fixtures
The fortress SHALL contain three new kinds of light fixture, all built in Godot from primitives and animated shaders with no external model assets:
- floor **braziers** with open fire
- hanging iron **lanterns** with a small enclosed flame
- **arcane crystal lamps** with a slow cyan glow pulse

Each fixture SHALL have a visible animated light element and a matching light whose energy follows that element. Fixtures SHALL be placed so that each main area (courtyard, crypt approach, key chamber) shows at least one new fixture type.

#### Scenario: Walk the level
- **WHEN** the player walks from the courtyard through the crypt to the key chamber
- **THEN** they pass at least one brazier, one lantern and one crystal lamp, and each visibly animates

### Requirement: Navigation and gameplay safety
Fixtures SHALL NOT add physics bodies that block walkable routes, SHALL NOT change the baked navigation, and SHALL NOT change enemy perception, line-of-sight results, pickups or any gameplay value. A floor brazier MAY carry a small collider only if it sits outside every navigation path and player route used by the tests.

#### Scenario: Gameplay fingerprints
- **WHEN** the existing gameplay and navigation test suite runs
- **THEN** all fingerprints and route checks match their 0.5.1 values

### Requirement: Bounded lighting cost
The level SHALL add at most 8 new dynamic lights, and at most 1 of them SHALL cast shadows. Fixture lights SHALL use limited ranges so that they don't wash out the torch-lit look. Glow animation SHALL follow the run clock, freeze while paused, and reset on restart.

#### Scenario: Count lights
- **WHEN** a run starts
- **THEN** the fixture light count is within budget, the shadow-casting count across torches and fixtures is at most 3, and pausing freezes every fixture's glow
