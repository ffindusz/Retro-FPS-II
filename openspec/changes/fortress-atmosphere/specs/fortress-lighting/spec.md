## ADDED Requirements

### Requirement: Readable warm and cool lighting
The environment SHALL use warm existing torch pools against cooler moon/ambient tones, with a nonzero ambient visibility floor. At 1280×720 and 1920×1080, enemies, resource pickups, the key, exit, world route cues, and HUD SHALL remain readable under the tuned lighting. The pass SHALL NOT change weapon-viewmodel lighting, enemy perception, physics line of sight, combat timing, or add new shadow-casting lights.

#### Scenario: Review courtyard and crypt combat views
- **WHEN** the player views existing enemies, pickups, and objective landmarks in each area
- **THEN** warm/cool differentiation is visible without hiding threats, the route, or resource/objective cues in crushed darkness

### Requirement: Bounded subtle torch modulation
The six existing torches SHALL retain their positions, light ranges and non-shadowed behavior. Flicker SHALL be deterministic smooth energy modulation bounded to ±8% of each torch's authored base, with component frequencies below 3Hz. It SHALL NOT toggle lights on/off or alter collision/perception.

#### Scenario: Sample torch energy over time
- **WHEN** lighting is updated across a representative sequence of active gameplay steps
- **THEN** every torch stays within its configured energy bounds and retains constant range, transform, and shadow settings

### Requirement: Pausable and repeatable lighting state
Pause SHALL freeze torch modulation time and output. Fresh runs SHALL reset deterministic phases without accumulating light nodes, timers, or callbacks. With the developer presentation toggle off, the previous static lighting SHALL remain available.

#### Scenario: Pause and restart the level
- **WHEN** the player pauses, resumes, and later restarts
- **THEN** lighting freezes while paused, continues without elapsed-time catch-up, and the new run begins with the initial six-light state
