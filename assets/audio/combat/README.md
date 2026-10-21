# Original combat SFX

These eleven short WAV cues are original deterministic procedural audio authored for this project by `tools/generate_combat_audio.gd`, not downloaded samples or outputs from a paid service. No Meshy or other API calls are used. The original nine combat WAVs were preserved byte-for-byte when the two resource cues were added.

Format: mono PCM16, 22,050 Hz; peak normalized to at most 0.5 (about -6 dBFS), with short attack/release envelopes and zero-valued endpoints. Seed starts at `0xC1D3` and increments by 19 in the declared cue order. Regenerate with the documented Godot editor executable and `--headless --path . --script tools/generate_combat_audio.gd`.

| Cue | Duration | Construction / purpose |
|---|---:|---|
| `swing` | .34s | Filtered noise envelope; melee whoosh |
| `hit` | .15s | Damped low sine and noise; enemy strike |
| `wall` | .28s | Inharmonic damped partials and attack noise; metallic clang |
| `magic_cast` | .32s | Rising chirp/harmonics; player staff |
| `magic_impact` | .22s | Falling chirp and noise; spell contact |
| `enemy_melee` | .38s | Low rumble/noise pulse; committed melee windup |
| `enemy_charge` | .65s | Rising low harmonics/noise; ranged windup |
| `enemy_cast` | .18s | Short falling chirp; enemy projectile release |
| `hurt` | .20s | Damped bass/noise thud; player damage |
| `pickup_health` | .26s | Warm two-note ascending chime; successful health restoration |
| `pickup_mana` | .30s | Brighter three-note harmonic chime; successful arcana restoration |

Generate only selected cues without rewriting accepted sounds by appending their names after `--`, for example `--headless --path . --script tools/generate_combat_audio.gd -- pickup_health pickup_mana`. Their seeds are 49790 and 49809 respectively. Source/imported cues remain uncompressed PCM16 with normalization disabled.

The runtime uses conservative gain, an SFX bus limiter, a 12-voice cap, and a session volume/mute slider. Pickups use local, non-positional cues only after actual positive restoration, not on full-resource contact; the key remains silent. On 2026-10-21 the user approved the existing sounds generally and confirmed pickup sound works; unreported detailed mix/control checks are not inferred. The owner chooses the project's overall source/asset distribution license; no third-party sample attribution is required for these original constructions.
