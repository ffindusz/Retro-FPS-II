## ADDED Requirements

### Requirement: Clearly audible default ambience
At the default Ambience slider value, the wind loop SHALL be clearly audible in the entrance and courtyard, and the crypt loop SHALL be clearly audible inside the crypt, on ordinary speakers or headphones at the system volume used for combat. The measured ambience bus output SHALL stay at least 9 dB below the peak level of the combat and pickup cues at the default SFX volume, and SHALL NOT clip.

#### Scenario: Start a run at default settings
- **WHEN** a new run starts with the default Ambience and SFX volume
- **THEN** the active loop plays at the documented default level, which is above the previous ~-27 dB and keeps the required headroom below combat cues

### Requirement: Preserved ambience controls and lifecycle
The Ambience slider, mute, retained session value, doorway blend, pause freeze, terminal/menu stop and bus cleanup SHALL behave as before. Only the gain mapping and the default value MAY change.

#### Scenario: Mute and restore
- **WHEN** the player moves the Ambience slider to zero and back
- **THEN** ambience mutes and then returns to the selected level, with SFX unaffected and no loop restart or stacking
