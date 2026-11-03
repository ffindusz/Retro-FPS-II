## ADDED Requirements

### Requirement: Grounded enemy cues
`enemy_melee`, `enemy_charge` and `enemy_cast` SHALL be regenerated as original deterministic procedural sounds that avoid clean pitched chirps and simple tonal sweeps. They SHALL use noise-based textures (breath/grunt-like low formants, cloth and metal scrape, crackling or hissing arcane energy) so they read as threats rather than game-console effects. Durations SHALL stay within ±25% of the current cues so that windup timing still matches.

#### Scenario: Hear a Warden windup and an Adept cast
- **WHEN** a Warden begins its melee windup and an Adept charges and releases a bolt
- **THEN** each cue is distinct from the others and from the player cues, is synchronized with the existing event, and has no cartoon-like pitch glide

### Requirement: Preserved SFX pipeline
The new cues SHALL keep the existing format (mono PCM16, 22,050 Hz, peak at or below -6 dBFS, zero endpoints), import settings, bus, limiter, voice cap and trigger points. The other nine accepted WAVs SHALL remain byte-identical. Provenance, seeds and the regeneration command SHALL be documented.

#### Scenario: Verify audio assets
- **WHEN** the audio asset tests run
- **THEN** the three regenerated cues pass the format and level checks, and all other SFX hashes match the accepted values
