## ADDED Requirements

### Requirement: Visible animated flame on every wall torch
Each of the six wall torches SHALL show an animated flame seated on its torch head. The flame SHALL have visible shape motion (licking and swaying) and rising embers. The flame's height and brightness SHALL follow the same flicker signal that drives that torch's light energy. The static mesh flame SHALL NOT remain visible as a separate frozen flame. Torch count, positions, light range, colour and shadow settings SHALL NOT change.

#### Scenario: Look at a torch
- **WHEN** the player looks at any wall torch from normal play distance
- **THEN** the flame visibly moves and changes height, embers rise, and the wall light brightens and dims in step with it

#### Scenario: Neighbouring torches
- **WHEN** two torches are visible at once
- **THEN** their flames are not in sync

### Requirement: Deterministic, pause-safe, comfortable flame motion
Flame motion SHALL be driven by the run clock: it SHALL freeze while the game is paused and reset on a fresh run. Brightness changes SHALL stay within the existing ±25% flicker limit with no component above 8 Hz, and flames SHALL never strobe, vanish or toggle. Flames SHALL be presentation-only: no collision, no effect on enemy perception, and no cost counted against the combat VFX pool.

#### Scenario: Pause during play
- **WHEN** the game is paused
- **THEN** flame shapes, embers and light energy hold still until play resumes

#### Scenario: Restart
- **WHEN** a run restarts or returns to the menu
- **THEN** flame visuals are freed with the level, and the new run starts from the reset clock without duplicates
