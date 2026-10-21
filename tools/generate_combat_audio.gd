extends SceneTree
## Deterministic original SFX. Offline authoring only; generated WAVs are bundled.

const RATE = 22050
const CUES = {
	"swing": 0.34, "hit": 0.15, "wall": 0.28, "magic_cast": 0.32,
	"magic_impact": 0.22, "enemy_melee": 0.38, "enemy_charge": 0.65,
	"enemy_cast": 0.18, "hurt": 0.20,
	"pickup_health": 0.26, "pickup_mana": 0.30
}

func _initialize() -> void:
	call_deferred("generate")

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
					sample = (sin(TAU * (83 * t + 15 * t * t)) * 0.4 + filtered * 0.9) * sin(progress * PI) * (0.7 + sin(TAU * 23 * t) * 0.3)
				"enemy_charge":
					phase += TAU * lerpf(150, 480, progress) / RATE
					sample = (sin(phase) * 0.5 + sin(phase * 2.01) * 0.2 + filtered * 0.4) * sin(progress * PI)
				"enemy_cast":
					phase += TAU * lerpf(590, 110, progress) / RATE
					sample = (sin(phase) * 0.55 + noise * 0.25) * exp(-t * 14)
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
