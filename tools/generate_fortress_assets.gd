extends SceneTree
## Original deterministic, offline environment images and seamless-loop source WAVs.

const SIZE = 512
const RATE = 22050
const SECONDS = 20
const LOOP_RMS = 0.063

func _initialize() -> void:
	call_deferred("generate")

func grain(x: float, y: float, seed: float) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233 + seed * 37.719) * 43758.5453, 1.0)

func generate() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/environment")
	DirAccess.make_dir_recursive_absolute("res://assets/audio/ambience")
	# Optional names after `--` regenerate only those assets (e.g. `-- wind crypt`).
	var only = OS.get_cmdline_user_args()
	var wanted = func(name: String) -> bool: return only.is_empty() or name in only
	for stone in [["wall", 128, 64, Color(0.43, 0.45, 0.43), 17], ["floor", 256, 256, Color(0.36, 0.38, 0.37), 29], ["trim", 256, 128, Color(0.49, 0.46, 0.39), 43]]:
		if wanted.call(stone[0]):
			make_stone(stone[0], stone[1], stone[2], stone[3], stone[4])
	if wanted.call("wind"):
		make_loop("wind", 7102)
	if wanted.call("crypt"):
		make_loop("crypt", 9104)
	quit()

## Chamberlin state-variable band-pass; `state` holds [low, band].
func bandpass(state: PackedFloat32Array, input: float, centre: float, q: float) -> float:
	var f = 2.0 * sin(PI * centre / RATE)
	state[0] += f * state[1]
	var high = input - state[0] - state[1] / q
	state[1] += f * high
	return state[1]

func make_stone(name: String, width: int, height: int, base: Color, seed: int) -> void:
	var albedo = Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var roughness = Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in range(SIZE):
		var row = floori(float(y) / height)
		var shift: int = width / 2 if row % 2 == 1 else 0
		for x in range(SIZE):
			var u = (x + shift) % width
			var v = y % height
			var column = floori(float(x + shift) / width) % int(SIZE / width)
			var edge = minf(minf(u, width - 1 - u), minf(v, height - 1 - v))
			var cell = grain(column, row, seed) - 0.5
			var noise = grain(x, y, seed + 1) - 0.5
			var waves = sin(TAU * x / SIZE * 7 + sin(TAU * y / SIZE * 5)) * 0.012 + cos(TAU * y / SIZE * 17) * 0.008
			var color = base * (0.9 + cell * 0.25 + noise * 0.08 + waves)
			var rough = 0.82 + cell * 0.1 + noise * 0.04
			if edge < 3:
				color = Color(0.13, 0.145, 0.15) * (0.9 + noise * 0.12)
				rough = 0.97
			else:
				color *= lerpf(0.72, 1.0, clampf((edge - 3) / 6.0, 0.0, 1.0))
			albedo.set_pixel(x, y, color)
			roughness.set_pixel(x, y, Color(rough, rough, rough))
	if name == "wall":
		assert(albedo.get_pixel(0, 32).r < 0.2 and albedo.get_pixel(0, 96).r > 0.2, "Staggered stone rows must wrap across tile boundaries")
	albedo.save_png("res://assets/environment/%s_albedo.png" % name)
	roughness.save_png("res://assets/environment/%s_roughness.png" % name)
	print("Authored ", name, " textures: 512px, seed ", seed)

func make_loop(name: String, seed: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	var count = RATE * SECONDS
	var overlap = int(RATE * 0.75)
	var raw = PackedFloat32Array()
	raw.resize(count + overlap)
	var low: float = 0.0
	var soft: float = 0.0
	var body = PackedFloat32Array([0.0, 0.0])
	var air = PackedFloat32Array([0.0, 0.0])
	var whistle = PackedFloat32Array([0.0, 0.0])
	# Sparse crypt drips (with two short echoes) kept clear of the loop overlap.
	var drips: Array[float] = []
	var drip_time = 1.5
	while drip_time < SECONDS - 1.5:
		drips.append(drip_time)
		drip_time += rng.randf_range(1.6, 3.4)
	for frame in range(raw.size()):
		var t = float(frame) / RATE
		var noise = rng.randf_range(-1, 1)
		low = lerpf(low, noise, 0.018)
		soft = lerpf(soft, noise, 0.12)
		if name == "wind":
			# Mid-band body and hiss carry on small speakers; the whistle rises only in gusts.
			var gust = 0.55 + 0.25 * sin(TAU * t / 7.1) + 0.15 * sin(TAU * t / 2.9 + 1.3)
			var hiss = bandpass(air, noise, 1400.0 + 300.0 * sin(TAU * t / 5.0), 1.2)
			var tone = bandpass(whistle, noise, 820.0 + 120.0 * sin(TAU * t / 9.0), 12.0)
			raw[frame] = gust * (bandpass(body, soft, 350.0, 0.6) * 6.0 + hiss * 0.3 * gust + tone * 0.5 * maxf(0.0, gust - 0.55)) + low * 0.6
		else:
			var drone = sin(TAU * 55 * t) * 0.07 + sin(TAU * 110 * t) * 0.12 + sin(TAU * 165 * t) * 0.05
			var drip_sum = 0.0
			for start in drips:
				for echo in [[0.0, 1.0], [0.11, 0.35], [0.23, 0.15]]:
					var age = t - start - echo[0]
					if age >= 0.0 and age < 0.15:
						# A short rising plink (water drop), not a falling chirp.
						drip_sum += echo[1] * exp(-age * 32.0) * sin(TAU * (1300.0 * age + 2500.0 * age * age))
			raw[frame] = drone * (0.85 + 0.1 * sin(TAU * t / 5.0)) + bandpass(air, noise, 900.0, 0.8) * 0.35 * (0.8 + 0.2 * sin(TAU * t / 6.3)) + drip_sum * 0.45 + low * 0.15
	var samples = PackedFloat32Array()
	samples.resize(count)
	var energy: float = 0.0
	for frame in range(count):
		var value: float = raw[frame]
		if frame < overlap:
			var weight = smoothstep(0.0, 1.0, float(frame) / (overlap - 1))
			# End-to-start remains adjacent source samples; overlap blends back to head.
			value = lerpf(raw[count + frame], raw[frame], weight)
		samples[frame] = value
		energy += value * value
	# Match loudness across loops (RMS about -24 dBFS); a tanh soft limit keeps peaks under .25.
	var scale = LOOP_RMS / sqrt(energy / count)
	var bytes = PackedByteArray()
	bytes.resize(count * 2)
	for frame in range(count):
		bytes.encode_s16(frame * 2, int(0.25 * tanh(samples[frame] * scale / 0.25) * 32767))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	var error = stream.save_to_wav("res://assets/audio/ambience/%s.wav" % name)
	if error != OK:
		push_error("Could not save ambience: " + name)
	print("Authored ", name, ": 20s mono PCM16, RMS-matched, peak <= .25, seed ", seed)
