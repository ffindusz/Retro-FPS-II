## ADDED Requirements

### Requirement: Walled key alcove
The original demo SHALL enclose the ember key in a walled alcove in the crypt's northeast corner with a single gateway. The key SHALL NOT be collectable from outside the alcove.

#### Scenario: Reach the key
- **WHEN** the navigation mesh is queried from the entrance to the key and from the key to the exit
- **THEN** both routes SHALL be connected through the gateway

### Requirement: Ward tied to its guards
A ward SHALL block the gateway for the player, enemies and projectiles until all of its three guards have died. It SHALL then stop blocking, sink out of sight and tell the player the key is free. It SHALL open at most once.

#### Scenario: Guards partly defeated
- **WHEN** two of the three guards are dead
- **THEN** the ward SHALL still block the gateway

#### Scenario: Last guard dies
- **WHEN** the last guard dies
- **THEN** the ward SHALL stop colliding immediately, sink into the floor over about one second and show "The ward lifts. The ember key is free."

### Requirement: Closed-ward hint
While the ward is closed, approaching it SHALL show a message explaining that the key guards must be defeated, once per approach.

#### Scenario: Approach the closed ward
- **WHEN** the player comes within 3.5 m of the closed ward
- **THEN** the player SHALL see "Defeat the key guards to lift the ward."

### Requirement: Pause and restart
Pausing SHALL freeze the ward while it sinks. Restarting SHALL create a closed ward with three living guards and the exact initial actor counts.

#### Scenario: Restart after opening
- **WHEN** the run is restarted after the ward opened
- **THEN** the new run SHALL have a closed ward, three guards and seven enemies in total
