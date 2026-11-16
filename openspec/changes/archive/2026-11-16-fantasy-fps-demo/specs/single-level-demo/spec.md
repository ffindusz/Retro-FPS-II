## ADDED Requirements

### Requirement: One complete original fantasy level
The demo SHALL contain one original, connected 3D ruined-fortress level with a safe entrance, courtyard, and crypt; solid collision; navigable routes; and encounters using both enemy archetypes. The route SHALL be completable without precision platforming, clearing every enemy, or requiring mana. Level layouts and content SHALL NOT copy Hexen II assets or maps.

#### Scenario: Complete the intended route
- **WHEN** a new run begins and the player follows the available routes
- **THEN** the player can travel from the entrance through both combat areas, obtain the key, and return to the exit without leaving the level

#### Scenario: Continue after exhausting mana
- **WHEN** the player has no mana before obtaining the key
- **THEN** navigation, melee combat, key collection, and exit interaction remain available

### Requirement: Key-gated exit objective
The level SHALL contain one collectible key and an identifiable exit. The exit SHALL require the key and a nearby E interaction with clear line of sight. Interacting while locked SHALL explain that the key is required; collecting the key SHALL update objective state; a valid unlocked interaction SHALL trigger victory exactly once.

#### Scenario: Try the locked exit
- **WHEN** the player interacts with the exit before collecting the key
- **THEN** the run remains active and the interface explains the missing-key requirement

#### Scenario: Unlock and complete the level
- **WHEN** the living player has collected the key and interacts with the exit from its allowed range without an obstruction
- **THEN** the run enters victory once and normal gameplay stops

#### Scenario: Reject remote interaction
- **WHEN** the player presses E outside the exit's interaction range or through a wall
- **THEN** no exit interaction or victory transition occurs

### Requirement: Useful health and mana pickups
The level SHALL provide health and mana pickups that apply their configured gain once, cap values at the corresponding maximum, and disappear only when they increase the player's value. Pickups SHALL NOT be collected by enemies or inactive/dead players.

#### Scenario: Collect a useful pickup
- **WHEN** a living active player with missing health or mana touches the corresponding pickup
- **THEN** the resource increases up to its maximum and that pickup is consumed once

#### Scenario: Preserve an unneeded pickup
- **WHEN** a player at the relevant maximum touches a pickup
- **THEN** the value is unchanged and the pickup remains available

### Requirement: Fresh and repeatable run state
Starting or restarting a run SHALL restore initial player health, mana, weapon selection, spawn position, enemies, pickups, key ownership, and exit state, and remove prior projectiles and transient effects. Repeated restarts SHALL NOT duplicate actors or event subscriptions.

#### Scenario: Restart an altered run repeatedly
- **WHEN** a player collects the key and pickups, damages enemies, fires projectiles, and then restarts multiple times
- **THEN** each new run matches its initial state with no old projectiles, duplicate enemies, or duplicate damage/objective events
