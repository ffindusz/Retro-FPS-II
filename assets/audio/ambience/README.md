# Original ambience loops

`wind.wav` and `crypt.wav` are original offline procedural audio authored by `tools/generate_fortress_assets.gd`. No external samples, model generation, or paid audio/API service is used. The eleven existing combat/pickup WAVs remain byte-for-byte unchanged.

- Both sources: 20 seconds, mono 22,050 Hz PCM16, peak at most 0.25 (about -12 dBFS), uncompressed/no normalization in Godot imports, forward loop over the complete resource.
- Wind seed 7101: two filtered noise bands with slow envelope variation.
- Crypt seed 9103: quiet 55/82.5Hz harmonics with low filtered noise and slow modulation; an environmental bed, not music or an enemy cue.
- A .75-second overlap joins the end of the generated source into the beginning, then blends back to the head. A source test verifies loop-boundary sample change is no larger than an ordinary adjacent sample change. That does not replace human seam/mix listening.
- Runtime: exactly two run-owned AudioStreamPlayers, complementary one-second doorway blends, independent Ambience bus/slider. Default user volume 30%, fixed bus gain 0.15; at full volume, the bounded source sum is at most about 0.0375 amplitude before Master. Accepted SFX clips/gain/voice pool are untouched. Mute changes gain without adding players; pause freezes playback and blend. Results/menu/disposal stop and detach streams.

Human listening acceptance for the new loops is pending. The owner chooses the project's overall source/asset distribution license; no third-party sample attribution is required for these original constructions.
