## ADDED Requirements

### Requirement: Distinct confirmed key pickup chime
Successful first collection of the ember key SHALL publish a pickup-specific confirmed event and play one distinct original local magical chime through the existing SFX service. The cue SHALL be audible after the pickup node is freed and SHALL NOT create combat hit markers or impact effects. The eleven accepted WAV sources SHALL remain unchanged.

#### Scenario: Collect the key
- **WHEN** an active player without a key successfully collects it
- **THEN** key ownership and objective feedback update and exactly one local key chime plays

### Requirement: Respect rejected collection and audio lifecycle
Already-owned/consumed, enemy, paused and dead collection attempts SHALL NOT play the key cue. Duplicate event IDs SHALL NOT replay it. Existing mute/volume and twelve-voice limits SHALL apply; mute SHALL NOT prevent ownership changes or queue delayed audio. Pause/results/menu/restart SHALL retain existing one-shot cleanup behavior.

#### Scenario: Collect while muted
- **WHEN** an active player successfully collects the key with SFX muted
- **THEN** ownership updates silently and unmuting does not replay the cue

#### Scenario: Reject or repeat a key event
- **WHEN** collection is rejected or a previously consumed event ID is replayed
- **THEN** no additional key sound or successful-hit presentation is produced
