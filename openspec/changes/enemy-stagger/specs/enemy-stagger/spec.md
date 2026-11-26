## ADDED Requirements

### Requirement: Stagger on hit
When the awake stone golem, a skeleton warrior or a skeleton archer takes damage, it SHALL stagger: play its hit clip, stand still and drop an attack it is winding up. Hits SHALL still deal their full damage.

#### Scenario: Hit during the windup
- **WHEN** the player hits one of these enemies while it winds up an attack
- **THEN** it SHALL play its hit clip and the attack SHALL not land

### Requirement: Stagger guard
After a stagger ends, the enemy SHALL not stagger again for a few seconds, and hits during a stagger SHALL not restart it.

#### Scenario: Rapid magic
- **WHEN** the player keeps firing magic at a staggering enemy
- **THEN** the enemy SHALL recover from each stagger and get a few seconds to move and attack before it can stagger again

### Requirement: No golem stagger while waking
The hit that wakes the dormant golem, and hits during its awakening, SHALL not stagger it.

#### Scenario: Waking hit
- **WHEN** the player hits the dormant statue
- **THEN** the golem SHALL wake up without staggering
