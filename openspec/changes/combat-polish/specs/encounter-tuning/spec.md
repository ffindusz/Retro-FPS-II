## ADDED Requirements

### Requirement: Preserve nonlethal enemy attack commitment
A living enemy receiving nonlethal damage during an attack windup SHALL retain its attack state, remaining windup, and cooldown progression while presenting its hit reaction. Nonlethal damage SHALL NOT repeatedly restart or cancel that windup. At resolution, attacks SHALL still obey existing range, line-of-sight, cooldown, and living-target rules; lethal damage SHALL cancel pending attacks immediately.

#### Scenario: Repeatedly hit a winding-up enemy
- **WHEN** a player lands nonlethal hits while an enemy is committed to an attack
- **THEN** the enemy reacts visually but completes the original windup without extra attacks, provided its resolution checks still pass

#### Scenario: Break line of sight during windup
- **WHEN** a damaged attacking enemy's line of sight becomes blocked before resolution
- **THEN** it does not apply direct damage through cover and any projectile remains subject to world collision

#### Scenario: Kill the attacking enemy
- **WHEN** damage becomes lethal before windup finishes
- **THEN** death cancels the attack and no later damage/cast is produced from it

### Requirement: Tune placement without increasing content or health
The level SHALL retain four melee enemies, two ranged enemies, three health pickups, three mana pickups, the existing key/exit objective, and existing player/enemy health, damage, and weapon-resource values. Encounter tuning SHALL use documented placement changes to create mixed-enemy pressure, maintain visible attack tells, and provide cover/retreat routes. It SHALL NOT add new blocking geometry, reinforcements, random spawns, or a kill-all gate.

#### Scenario: Review revised encounters
- **WHEN** a fresh run instantiates the tuned courtyard and crypt
- **THEN** actor/resource counts and combat stat baselines match the pre-polish demo, while recorded placement changes explain the intended pressure and cover choices

### Requirement: Safe entry and resource-independent completion
The entrance/spawn SHALL remain safe for learning the controls. Combat SHALL become threatening only after the player enters encounter space, without unavoidable initial damage. Existing navigation, key access, exit interaction, and zero-mana melee progression SHALL remain viable without killing every enemy.

#### Scenario: Start and enter combat deliberately
- **WHEN** the player starts a fresh run and then advances out of the entrance
- **THEN** the spawn is safe and subsequent mixed combat has readable windups and usable cover

#### Scenario: Complete with depleted mana
- **WHEN** the player runs out of mana before obtaining the key
- **THEN** the key and exit remain reachable through movement and the resource-free melee weapon

### Requirement: Honest post-polish playtest record
Validation SHALL retain the user's pre-polish five-minute/easy baseline and record new completion time, subjective difficulty, melee clarity, and audio comfort when tested. The target SHALL remain roughly 5–10 minutes, not a timed restriction. Untested subjective outcomes SHALL remain explicitly pending; this follow-up SHALL NOT automatically close or archive the original change's remaining human/offline acceptance tasks.

#### Scenario: Await post-polish feedback
- **WHEN** code/render checks pass but the revised demo has not been played and heard by a person
- **THEN** the record reports technical results without claiming improved difficulty, confirmed duration, comfortable audio, or completed human acceptance
