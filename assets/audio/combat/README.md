# Original combat SFX

These twelve short WAV cues are original deterministic procedural audio authored for this project by `tools/generate_combat_audio.gd`, not downloaded samples or outputs from a paid service. No Meshy or other API calls are used. The original nine combat WAVs were preserved byte-for-byte when the two resource cues were added; all eleven accepted cues are unchanged by the 0.4 key follow-up.

Format: mono PCM16, 22,050 Hz; peak normalized to at most 0.5 (about -6 dBFS), with short attack/release envelopes and zero-valued endpoints. Seed starts at `0xC1D3` and increments by 19 in the declared cue order. Regenerate with the documented Godot editor executable and `--headless --path . --script tools/generate_combat_audio.gd`.

| Cue | Duration | Construction / purpose |
|---|---:|---|
| `swing` | .34s | Filtered noise envelope; melee whoosh |
| `hit` | .15s | Damped low sine and noise; enemy strike |
| `wall` | .28s | Inharmonic damped partials and attack noise; metallic clang |
| `magic_cast` | .32s | Rising chirp/harmonics; player staff |
| `magic_impact` | .22s | Falling chirp and noise; spell contact |
| `enemy_melee` | .38s | Breathy grunt (~95 Hz pulses and breath through 320/780 Hz formants) then a scrape; committed melee windup (0.5.1) |
| `enemy_charge` | .65s | Arcane crackle of rising density over swelling hiss and low rumble, no pitch rise; ranged windup (0.5.1) |
| `enemy_cast` | .18s | Unpitched band-passed noise "fwoosh" with a short 70 Hz thump; enemy projectile release (0.5.1) |
| `hurt` | .20s | Damped bass/noise thud; player damage |
| `pickup_health` | .26s | Warm two-note ascending chime; successful health restoration |
| `pickup_mana` | .30s | Brighter three-note harmonic chime; successful arcana restoration |
| `pickup_key` | .85s | Four overlapping ascending bell tones (392, 523.25, 659.25, 1046.5Hz), inharmonic partials and decaying tail; first successful key collection |

Generate only selected cues without rewriting accepted sounds by appending their names after `--`, for example `--headless --path . --script tools/generate_combat_audio.gd -- pickup_key`. Health/mana seeds are 49790/49809; the key cue's declared seed is 49828 (its waveform uses tones rather than random noise). Source/imported cues remain uncompressed PCM16 with normalization disabled.

The runtime uses conservative gain, an SFX bus limiter, a 12-voice cap, and a session volume/mute slider. Resource pickups sound only after positive restoration; the key sounds only after ownership first succeeds. All pickup cues are local, independent of the freed pickup node, deduplicated and muted without delayed replay. On 2026-10-21 the user approved the existing sounds generally and confirmed resource pickup sound works; that feedback does not approve the new key chime. The owner chooses the project's overall source/asset distribution license; no third-party sample attribution is required for these original constructions.

0.5.1: after the 2026-11-03 playtest found the enemy cues cartoonish, only `enemy_melee`, `enemy_charge` and `enemy_cast` were regenerated (`-- enemy_melee enemy_charge enemy_cast`) with their original declared seeds and durations. The other nine WAVs are byte-identical; new hashes are recorded in `docs/playtest-fixes-audio.json`. Listening acceptance of the new enemy cues is pending.
