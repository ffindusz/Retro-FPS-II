## ADDED Requirements

### Requirement: Original bundled combat cues
The demo SHALL bundle locally authored, provenance-recorded sounds for melee swings, enemy-hit impacts, wall strikes, player magic casts, projectile/world impacts, enemy melee windups, enemy ranged windups/casts, player damage, and useful health/arcana pickups. Swing/miss, enemy hit, and wall strike SHALL be distinguishable, as SHALL health and arcana pickup cues. Gameplay SHALL NOT require runtime synthesis, network access, API credentials, paid generation, or downloading third-party audio.

#### Scenario: Play the demo offline
- **WHEN** the bundled demo runs without a network connection or authoring tools
- **THEN** required combat cues load and play from local resources

### Requirement: Event-synchronized audio
Audio SHALL be triggered by accepted attacks, committed enemy windups/casts, confirmed contact/damage events, or successful useful resource pickups, not HUD refreshes or every physics query. Rejected attacks SHALL produce no attack/cast cue. Repeated contact sampling SHALL NOT duplicate a hit or wall sound for the same event; a swing SHALL NOT play its hit sound before contact.

#### Scenario: Swing and miss
- **WHEN** a melee attack is accepted but makes no contact
- **THEN** a swing cue plays without an enemy-hit or wall-impact cue

#### Scenario: Reject a staff shot
- **WHEN** the staff is on cooldown or has insufficient mana
- **THEN** no magic-cast cue is emitted

#### Scenario: Damage a target across repeated sweep samples
- **WHEN** several queries report the same target during one swing
- **THEN** only the confirmed deduplicated damage event triggers that target's hit cue

### Requirement: Spatial and bounded sound mixing
Player attack/hurt and resource pickup cues SHALL be local, while enemy and world-contact cues SHALL originate at their world positions and attenuate with distance. Combat playback SHALL use an SFX bus with conservative gain and limiting, and SHALL permit at most 12 simultaneous voices. Voice exhaustion SHALL drop or replace low-priority presentation rather than queue delayed bursts or affect damage.

#### Scenario: Hear enemies at different distances
- **WHEN** nearby and distant enemies emit the same cue under the same mix settings
- **THEN** the distant world-space cue is attenuated relative to the nearby one

#### Scenario: Saturate simultaneous impacts
- **WHEN** contact events request more voices than the limit
- **THEN** playback remains bounded, combat results are unchanged, and discarded cues are not played later as a burst

### Requirement: Accessible session SFX control
The pause menu SHALL provide a keyboard/mouse-accessible SFX volume slider whose zero value mutes combat audio. Its value SHALL persist across runs within the app session, without requiring disk persistence. Changing the slider SHALL NOT fire a weapon, resume gameplay, change combat state, or disable visual telegraphs.

#### Scenario: Mute and restart
- **WHEN** the user sets SFX volume to zero and restarts the run
- **THEN** combat remains muted while gameplay and visual feedback continue normally

### Requirement: Clean audio transitions
Pausing or entering defeat, victory, or the menu SHALL stop active combat one-shots and discard pending cues. Resume SHALL NOT replay old cues. Disposal/restart SHALL free old voice nodes and subscriptions while retaining the session volume setting.

#### Scenario: Pause during a cast
- **WHEN** the player pauses while combat sounds are playing and later resumes
- **THEN** old sounds stop and do not replay, and only new valid combat events start new sounds

### Requirement: Audio acceptance evidence
Automated checks SHALL validate bundled resource availability, event counts, volume/mute behavior, and voice cleanup. Completion of subjective sound-quality acceptance SHALL require a recorded human listening pass for cue distinction and comfortable mixing; successful dummy/headless playback SHALL NOT be reported as that pass.

#### Scenario: Only automated playback has been tested
- **WHEN** sound resources and event tests pass but no listening review has occurred
- **THEN** the validation record identifies listening/mix acceptance as pending

### Requirement: Useful resource pickup confirmation
Health and arcana pickups SHALL emit their distinct cue exactly once after restoring a positive amount, including a capped partial restoration. The confirmed event SHALL report the actual restored amount and use the existing SFX volume/mute and transition cleanup. Full resources, consumed pickups, nonpositive restoration, enemies, and inactive/dead/paused players SHALL NOT trigger pickup audio. Pickup confirmation SHALL NOT produce a combat hit marker or damage effect, and this change SHALL NOT add a key sound.

#### Scenario: Consume a useful health or arcana pickup
- **WHEN** a living active player collects the corresponding pickup with missing resource
- **THEN** the resource increases up to its maximum, the pickup is consumed once, and one matching cue is emitted for the actual gain

#### Scenario: Touch an unneeded or consumed pickup
- **WHEN** a player is already at the relevant maximum or the pickup has already been consumed
- **THEN** no pickup cue is emitted and an unneeded pickup remains available

#### Scenario: Collect while muted
- **WHEN** the SFX control is muted and the active player collects a useful resource pickup
- **THEN** restoration and consumption succeed without audio, delayed playback, or false combat feedback
