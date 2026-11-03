# Original ambience loops

`wind.wav` and `crypt.wav` are original offline procedural audio authored by `tools/generate_fortress_assets.gd`. No external samples, model generation, or paid audio/API service is used. The eleven existing combat/pickup WAVs remain byte-for-byte unchanged.

- Both sources: 20 seconds, mono 22,050 Hz PCM16, peak at most 0.25 (about -12 dBFS), uncompressed/no normalization in Godot imports, forward loop over the complete resource.
- Wind seed 7102 (0.5.1): a band-passed 350 Hz body from softened noise, a moving ~1.4 kHz hiss and a faint resonant ~820 Hz whistle that rises only in gusts, over a little low rumble.
- Crypt seed 9104 (0.5.1): 55/110/165 Hz drone, a soft 900 Hz air bed and sparse rising water-drip plinks with two short echoes, kept clear of the loop overlap; an environmental bed, not music or an enemy cue.
- 0.5.1 re-authoring: the 0.5.0 loops (seeds 7101/9103) put 45% (wind) and 76% (crypt) of their energy below 150 Hz and were inaudible in the 2026-11-03 playtest. Both loops are now RMS-matched at about -24.7 dBFS with a tanh soft limit under the 0.25 peak ceiling. Regenerate only the loops with `--headless --path . --script tools/generate_fortress_assets.gd -- wind crypt`.
- A .75-second overlap joins the end of the generated source into the beginning, then blends back to the head. A source test verifies loop-boundary sample change is no larger than an ordinary adjacent sample change. That does not replace human seam/mix listening.
- Runtime: exactly two run-owned AudioStreamPlayers, complementary one-second doorway blends, independent Ambience bus/slider. Default user volume 30%, fixed bus gain 0.3 (0.15 before 0.5.1): about -45 dBFS RMS and -34 dBFS peak at default, 9 dB below the default combat-cue peaks (about -24 dBFS). Accepted SFX clips/gain/voice pool are untouched. Mute changes gain without adding players; pause freezes playback and blend. Results/menu/disposal stop and detach streams.

Human listening acceptance for the 0.5.1 loops is pending. The owner chooses the project's overall source/asset distribution license; no third-party sample attribution is required for these original constructions.
