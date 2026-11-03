## ADDED Requirements

### Requirement: Readable Adept death
When an Adept dies, its model SHALL play a visible death sequence of 0.8 to 1.5 s: a short stagger, a collapse onto the floor without sinking through it, and a brief magical dissipation effect. Afterwards the body SHALL remain visibly lying down and stay still for the rest of the run.

#### Scenario: Kill an Adept
- **WHEN** an Adept's health reaches zero
- **THEN** the player sees it stagger, fall and settle on the floor with a brief arcane burst, instead of an instant 0.3 s tip

### Requirement: Gameplay-neutral death
The sequence SHALL be presentation-only. Collision removal, cancelled attacks and casts, the `died` signal, objective rules and enemy counts SHALL happen exactly as before and at the same moment. The sequence SHALL freeze on pause, use per-instance state only, and be freed with the run. Warden death presentation and the placeholder fallback SHALL remain unchanged.

#### Scenario: Pause mid-collapse and restart
- **WHEN** the game is paused during the sequence and then restarted
- **THEN** the collapse freezes while paused, and the new run contains no leftover bodies or effects
