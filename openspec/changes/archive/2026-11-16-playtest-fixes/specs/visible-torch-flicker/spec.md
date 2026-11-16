## ADDED Requirements

### Requirement: Perceptible comfortable flicker
Each of the six torches SHALL modulate its light energy by a visible amount within ±25% of its base energy, combining a slow sway with smaller faster variation (no component above 8 Hz). Per-torch phases SHALL differ. Light range, colour, shadow settings, torch count and positions SHALL NOT change, and energy SHALL never drop to zero or toggle on/off.

#### Scenario: Watch a torch-lit wall
- **WHEN** the player looks at a torch-lit area for a few seconds
- **THEN** the light visibly moves without strobing, and neighbouring torches are not in sync

### Requirement: Deterministic paused-safe modulation
Modulation SHALL be a deterministic function of the run clock, freeze while paused, and reset on a fresh run. It SHALL NOT affect enemy perception or gameplay.

#### Scenario: Pause and restart
- **WHEN** the game is paused and later restarted
- **THEN** torch energies hold steady during pause and start from the reset clock in the new run
