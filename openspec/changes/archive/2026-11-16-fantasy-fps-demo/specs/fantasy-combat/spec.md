## ADDED Requirements

### Requirement: Two selectable 3D first-person weapons
The player SHALL start with a melee weapon and a mana-powered magic weapon, select them with 1 and 2, and attack with the left mouse button. Both first-person weapons SHALL be rendered as actual 3D meshes with visible attack feedback, not weapon sprites or HUD illustrations. Weapon presentation SHALL remain aligned when the window resizes and SHALL NOT determine world hit collision.

#### Scenario: Select and use each weapon
- **WHEN** the player selects each weapon and makes a valid attack
- **THEN** the corresponding 3D viewmodel is visible and presents attack feedback

#### Scenario: Approach a wall
- **WHEN** the player faces a wall at close range and attacks
- **THEN** the viewmodel does not disappear into the wall and the attack does not damage targets behind it

### Requirement: Bounded melee attacks
The melee weapon SHALL require no mana, enforce a configured cooldown and range, respect solid-world occlusion, and damage each struck target at most once per attack. Switching weapons SHALL NOT reset attack cooldowns.

#### Scenario: Hit a nearby enemy
- **WHEN** a living enemy is in melee range and unobstructed during a valid swing
- **THEN** the enemy receives one configured damage event from that swing

#### Scenario: Reject invalid melee hits
- **WHEN** the target is out of range or behind a solid wall
- **THEN** the melee attack deals no damage to that target

#### Scenario: Prevent rapid-fire switching
- **WHEN** the player attacks, switches away, switches back, and attacks before the original cooldown expires
- **THEN** the additional attack is rejected

### Requirement: Mana-powered projectiles
The magic weapon SHALL fire a visible world-space 3D projectile toward the world-camera aim point only when its cooldown has elapsed and enough mana is available. A successful shot SHALL consume its configured mana cost exactly once; rejected attacks SHALL consume none. Mana SHALL remain between zero and its configured maximum.

#### Scenario: Fire with sufficient mana
- **WHEN** the player fires a ready magic weapon with sufficient mana
- **THEN** one projectile appears and mana decreases by the configured cost

#### Scenario: Fire with insufficient mana
- **WHEN** the player fires with mana below the shot cost
- **THEN** no projectile appears, mana is unchanged, and the interface indicates insufficient mana

### Requirement: Safe projectile collision and lifetime
Projectiles SHALL detect collisions along each physics-step travel segment, resolve only the first blocking impact, apply damage at most once, and expire after impact or their configured lifetime. Projectiles SHALL NOT pass through walls, including when fired point-blank or at high speed. Player attacks SHALL NOT damage the player, and enemy attacks SHALL NOT damage other enemies.

#### Scenario: Hit an enemy before a wall
- **WHEN** a player projectile crosses an enemy before reaching the wall behind it
- **THEN** that enemy takes damage once and the projectile stops

#### Scenario: Block a high-speed or point-blank shot
- **WHEN** a wall intersects a projectile's travel segment or obstructs its spawn path
- **THEN** the shot is blocked at the obstruction without hitting an enemy behind the wall

#### Scenario: Expire a missed projectile
- **WHEN** a projectile reaches its configured lifetime without hitting anything
- **THEN** it is removed from the run

### Requirement: Two navigable enemy archetypes
The demo SHALL provide distinct 3D melee and ranged enemies. Living enemies SHALL detect the player, navigate traversable level routes, telegraph attacks, and enforce attack cooldowns. Melee attacks SHALL require range and clear line of sight; ranged attacks SHALL launch visible projectiles on a clear firing line.

#### Scenario: Melee enemy pursues around cover
- **WHEN** an alerted melee enemy has a traversable route around an obstacle to the living player
- **THEN** it follows that route and attacks only when in range with a clear line of sight

#### Scenario: Ranged enemy attacks
- **WHEN** a ranged enemy has the living player within firing range and an unobstructed firing line
- **THEN** it presents a visible windup and fires a projectile subject to its cooldown

#### Scenario: Player moves behind cover during windup
- **WHEN** cover blocks a melee or ranged enemy's attack line before the attack resolves
- **THEN** the enemy does not apply direct damage through the cover and any projectile is blocked by world collision

### Requirement: Enemy damage and death feedback
Enemies SHALL visibly react to damage and death. An enemy at zero health SHALL transition to death once, stop movement and attacks, and cease blocking the traversable route after its death feedback.

#### Scenario: Kill an enemy during its attack windup
- **WHEN** an enemy takes lethal damage before its attack resolves
- **THEN** death feedback occurs once, the pending attack is cancelled, and the enemy no longer functions as an active combatant
