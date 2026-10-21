## ADDED Requirements

### Requirement: Two original bundled ambience loops
With atmosphere enabled, the demo SHALL provide original locally authored wind and crypt-bed loops with documented provenance, valid forward-loop metadata, bounded unclipped source audio, and no runtime generation/download dependency. Exactly two reusable run-owned ambience players SHALL be used; ambience SHALL NOT consume the one-shot SFX voice pool or rewrite any of the eleven accepted SFX sources/gains.

#### Scenario: Launch a fresh run offline
- **WHEN** the bundled demo starts a run without network access or authoring tools
- **THEN** both loop resources are available locally, two ambience players are created, and combat/pickup SFX retain their existing resources and settings

### Requirement: Smooth presentation-only crypt transition
The ambience controller SHALL smoothly blend wind and crypt emphasis over approximately one second at the existing crypt doorway/boundary, using bounded complementary weights. Default ambience SHALL remain subordinate to important combat and pickup cues. Region/blend changes SHALL NOT affect AI, collision, resources, objectives, or the SFX mix.

#### Scenario: Cross and recross the crypt doorway
- **WHEN** the player walks between courtyard and crypt repeatedly
- **THEN** ambience weights transition smoothly without an abrupt audible cut, added audio players, or a gameplay state change

### Requirement: Independent accessible ambience volume
The pause menu SHALL expose an Ambience volume/mute slider operable by mouse and keyboard, separate from the existing SFX slider. Values SHALL persist independently across runs within the app session, with no required disk persistence. Changing either control SHALL NOT alter the other value, trigger attacks, resume gameplay, or push controls outside the 720p/1080p logical canvas.

#### Scenario: Mute ambience and restart
- **WHEN** the user mutes ambience while leaving SFX audible and restarts
- **THEN** ambience remains muted, SFX volume is unchanged, and gameplay/pickup sounds still function

### Requirement: Clean pause and session lifecycle
Pause SHALL freeze ambience blend and playback positions; resume SHALL continue without restarting or layering loops. Defeat, victory, menu return, and disposal SHALL stop/free the run's ambience. A fresh run SHALL reset blend/phase with the retained session volume applied before audible playback. Only game-created audio buses SHALL be removed on session teardown.

#### Scenario: Pause and resume a transition
- **WHEN** the player pauses partway through a crypt blend and later resumes
- **THEN** blend/playback do not advance while paused and continue without duplicate starts or catch-up

#### Scenario: Finish and restart repeatedly
- **WHEN** runs end and restart through defeat, victory, and menu return
- **THEN** old ambience players/callbacks are gone, only two new players exist in the active run, and no sound continues in result/menu states

### Requirement: Honest visual and listening acceptance
Technical checks SHALL validate resources, loop metadata, player counts, blend bounds, controls, lifecycle, and unchanged SFX behavior. Subjective acceptance SHALL require recorded human feedback on ambience seams/transition, default mix, lighting/flicker comfort, and route/combat readability. The prior positive combat/pickup feedback or successful headless playback SHALL NOT be reported as that new atmosphere review.

#### Scenario: Await atmosphere playtest
- **WHEN** automated/render checks pass but no person has reviewed the new atmosphere
- **THEN** technical evidence is recorded while visual/listening/full-run acceptance and prior unreported offline checks remain pending
