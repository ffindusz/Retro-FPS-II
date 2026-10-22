## ADDED Requirements

### Requirement: Limited readable torch shadows
Exactly two of the existing six torches SHALL cast shadows in atmosphere-enabled gameplay. Torch positions, seven-meter ranges, deterministic eight-percent modulation bounds and the ambient visibility floor SHALL remain unchanged. The Compatibility renderer and existing directional light SHALL be retained, and torch emitters SHALL NOT self-occlude the selected lights.

#### Scenario: Enter courtyard and crypt
- **WHEN** the player approaches the selected courtyard or crypt torch
- **THEN** nearby world/actor geometry casts torch shadows while enemies, resources and routes remain readable

### Requirement: Bounded spell illumination
Accepted player/enemy spell casts, magic impacts and live projectiles SHALL provide short-range shadowless illumination with at most six spell lights per run. Cast/impact flashes SHALL last no more than 0.2 seconds, projectile lights SHALL follow their owning projectile, and saturation SHALL drop only presentation without changing attack/damage/projectile rules.

#### Scenario: Saturate spell presentation
- **WHEN** many casts, impacts and projectiles overlap
- **THEN** at most six spell lights exist and gameplay events still resolve normally

### Requirement: Paused and disposable dynamic lights
Pause SHALL freeze flash ages and projectile movement. Terminal/menu/disposal transitions SHALL remove all spell lights, and fresh runs SHALL reset the pool. The atmosphere-disabled diagnostic path SHALL add neither torch shadows nor spell lights.

#### Scenario: Pause, finish and restart
- **WHEN** a spell-lit run is paused, resumed, finished and restarted
- **THEN** lighting does not catch up or leak old nodes and the new run starts with an empty spell-light pool
