extends SceneTree
## Deterministic original SFX. Offline authoring only; generated WAVs are bundled.

const RATE = 22050
const CUES = {
	"swing": 0.34, "hit": 0.15, "wall": 0.28, "magic_cast": 0.32,
	"magic_impact": 0.22, "enemy_melee": 0.38, "enemy_charge": 0.65,
	"enemy_cast": 0.18, "hurt": 0.20,
	"pickup_health": 0.26, "pickup_mana": 0.30, "pickup_key": 0.85
}

func _initialize() -> void:
	call_deferred("generate")

## Chamberlin state-variable band-pass; `state` holds [low, band].
func bandpass(state: PackedFloat32Array, input: float, centre: float, q: float) -> float:
	var f = 2.0 * sin(PI * centre / RATE)
	state[0] += f * state[1]
	var high = input - state[0] - state[1] / q
	state[1] += f * high
	return state[1]

func generate() -> void:
	var requested = OS.get_cmdline_user_args()
	for cue in requested:
		if not CUES.has(cue):
			push_error("Unknown cue requested: " + cue)
			quit(1)
			return
	DirAccess.make_dir_recursive_absolute("res://assets/audio/combat")
	var index = 0
	for cue in CUES:
		var duration: float = CUES[cue]
		var rng = RandomNumberGenerator.new()
		rng.seed = 0xC1D3 + index * 19
		index += 1
		if not requested.is_empty() and not requested.has(cue):
			continue
		var count = int(duration * RATE)
		var samples = PackedFloat32Array()
		samples.resize(count)
		var filtered: float = 0.0
		var phase: float = 0.0
		var peak: float = 0.001
		var formant_low = PackedFloat32Array([0.0, 0.0])
		var formant_high = PackedFloat32Array([0.0, 0.0])
		var crackle: float = 0.0
		for frame in range(count):
			var t = float(frame) / RATE
			var progress = t / duration
			var noise = rng.randf_range(-1.0, 1.0)
			filtered = lerpf(filtered, noise, 0.16 + 0.3 * sin(progress * PI))
			var sample: float = 0.0
			match cue:
				"swing":
					sample = filtered * pow(sin(progress * PI), 1.8)
				"hit":
					sample = (filtered * 0.7 + sin(TAU * 105 * t) * 0.55) * exp(-t * 28)
				"wall":
					sample = (sin(TAU * 1320 * t) * 0.35 + sin(TAU * 2183 * t) * 0.2 + sin(TAU * 3307 * t) * 0.1) * exp(-t * 18) + noise * exp(-t * 100) * 0.3
				"magic_cast":
					phase += TAU * lerpf(380, 1050, progress) / RATE
					sample = (sin(phase) * 0.65 + sin(phase * 1.5) * 0.2 + filtered * 0.25) * sin(progress * PI)
				"magic_impact":
					phase += TAU * lerpf(1400, 260, progress) / RATE
					sample = (sin(phase) * 0.4 + filtered * 0.8) * exp(-t * 16)
				"enemy_melee":
					# Breathy grunt: ~95 Hz glottal pulses and breath through two vowel formants, then a scrape.
					phase += TAU * (95.0 + 3.0 * sin(TAU * 7.0 * t)) / RATE
					var voice = pow(maxf(0.0, sin(phase)), 8.0) + noise * 0.35
					var grunt = bandpass(formant_low, voice, 320.0, 4.0) + bandpass(formant_high, voice, 780.0, 5.0) * 0.7
					var scrape = (noise - filtered) * smoothstep(0.45, 0.7, progress) * (0.6 + 0.4 * sin(TAU * 31.0 * t))
					sample = grunt * smoothstep(0.0, 0.2, progress) * (1.0 - smoothstep(0.55, 1.0, progress)) + scrape * 0.3
				"enemy_charge":
					# Arcane crackle whose density (not pitch) builds over a swelling hiss and low rumble.
					if rng.randf() < lerpf(0.002, 0.03, progress):
						crackle = rng.randf_range(-1.0, 1.0)
					crackle *= 0.86
					sample = crackle * 1.2 + (noise - filtered) * 0.25 * progress + bandpass(formant_low, noise, 140.0, 1.5) * 0.5 * sin(progress * PI)
				"enemy_cast":
					# Unpitched release: band-passed noise "fwoosh" with a short low thump.
					sample = bandpass(formant_low, noise, 1200.0, 0.7) * 1.4 * exp(-t * 16) + sin(TAU * 70 * t) * 0.5 * exp(-t * 35)
				"hurt":
					sample = (sin(TAU * 68 * t) * 0.6 + filtered * 0.75) * exp(-t * 22)
				"pickup_health":
					var frequency = 523.25 if progress < 0.5 else 659.25
					phase += TAU * frequency / RATE
					sample = (sin(phase) * 0.75 + sin(phase * 2.0) * 0.12) * sin(fmod(progress * 2.0, 1.0) * PI)
				"pickup_mana":
					var notes = [739.99, 987.77, 1174.66]
					phase += TAU * notes[mini(2, int(progress * 3.0))] / RATE
					sample = (sin(phase) * 0.6 + sin(phase * 2.01) * 0.2) * sin(fmod(progress * 3.0, 1.0) * PI)
				"pickup_key":
					var notes = [392.0, 523.25, 659.25, 1046.5]
					for note in range(notes.size()):
						var age = t - note * 0.11
						if age >= 0.0:
							var tone = TAU * notes[note] * age
							sample += (sin(tone) + sin(tone * 2.76) * 0.32 + sin(tone * 4.12) * 0.18) * exp(-age * 7.0) * minf(1.0, age / 0.004)
			sample *= minf(1.0, t / 0.006) * minf(1.0, (duration - t) / 0.025)
			samples[frame] = sample
			peak = maxf(peak, absf(sample))
		var bytes = PackedByteArray()
		bytes.resize(count * 2)
		for frame in range(count):
			bytes.encode_s16(frame * 2, int(samples[frame] / peak * 0.5 * 32767.0))
		bytes.encode_s16(0, 0)
		bytes.encode_s16((count - 1) * 2, 0)
		var stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = RATE
		stream.data = bytes
		var error = stream.save_to_wav("res://assets/audio/combat/%s.wav" % cue)
		if error != OK:
			push_error("Could not write cue " + cue)
			quit(1)
			return
		print("Authored ", cue, ": ", duration, "s; peak <= 0.5; seed ", rng.seed)
	quit()
