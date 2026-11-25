## ADDED Requirements

### Requirement: Sealed rune door
The game SHALL provide a Rune Door exit built from the Meshy frame, leaf and socket models. It SHALL start sealed: both leaves closed, blocking movement, projectiles and line of sight, with its runes glowing softly.

#### Scenario: Player without the key
- **WHEN** the player interacts at the socket or the doorway without the ember key
- **THEN** the door SHALL stay sealed and the player SHALL be told that the socket waits for the ember key

### Requirement: Key socket
The door's key socket SHALL accept the ember key once, when the player interacts within reach and in line of sight while holding it.

#### Scenario: Player inserts the key
- **WHEN** the player holding the ember key interacts at the socket
- **THEN** the key SHALL appear in the socket, the runes SHALL brighten, and after a short delay both leaves SHALL slide sideways into the walls

### Requirement: Walking through finishes the level
Once open, the doorway SHALL be clear, and walking through it SHALL finish the level exactly once.

#### Scenario: Through the open door
- **WHEN** the player walks past the threshold of the open door
- **THEN** the run SHALL end in victory

### Requirement: Pause and restart
Pausing SHALL freeze the door's opening. Restarting the level SHALL bring the door back sealed.

#### Scenario: Restart after opening
- **WHEN** the player restarts The Ossuary
- **THEN** the rune door SHALL be sealed with both leaves closed

### Requirement: Rune Door placement
Authored levels SHALL support a `Rune Door` placement kind, appended after the existing kinds, with an editor preview. A level SHALL have exactly one exit, either an Exit Gate or a Rune Door.

#### Scenario: Two exits
- **WHEN** a level has both an Exit Gate and a Rune Door
- **THEN** the build SHALL fail with a required-count issue

### Requirement: The Ossuary exit
The Golem Sanctum SHALL have the rune door set into its far wall, with the socket beside it and a short corridor behind it.

#### Scenario: Finish The Ossuary
- **WHEN** the player defeats the golem, takes the key, sets it into the socket and walks through the opened door
- **THEN** the run SHALL end in victory
