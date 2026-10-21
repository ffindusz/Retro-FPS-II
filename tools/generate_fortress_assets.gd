extends SceneTree
## Original deterministic, offline environment images and seamless-loop source WAVs.

const SIZE = 512
const RATE = 22050
const SECONDS = 20

func _initialize() -> void:
	call_deferred("generate")

func grain(x: float, y: float, seed: float) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233 + seed * 37.719) * 43758.5453, 1.0)

func generate() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/environment")
	DirAccess.make_dir_recursive_absolute("res://assets/audio/ambience")
	make_stone("wall", 128, 64, Color(0.43, 0.45, 0.43), 17)
	make_stone("floor", 256, 256, Color(0.36, 0.38, 0.37), 29)
	make_stone("trim", 256, 128, Color(0.49, 0.46, 0.39), 43)
	make_loop("wind", 7101)
	make_loop("crypt", 9103)
	quit()

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
	var high: float = 0.0
	for frame in range(raw.size()):
		var t = float(frame) / RATE
		var noise = rng.randf_range(-1, 1)
		low = lerpf(low, noise, 0.018)
		high = lerpf(high, noise, 0.10)
		if name == "wind":
			raw[frame] = (low * 0.8 + high * 0.2) * (0.7 + 0.15 * sin(TAU * t / 8.0) + 0.1 * sin(TAU * t / 3.3))
		else:
			raw[frame] = (sin(TAU * 55 * t) * 0.35 + sin(TAU * 82.5 * t) * 0.12 + low * 0.3) * (0.85 + 0.1 * sin(TAU * t / 5.0))
	var samples = PackedFloat32Array()
	samples.resize(count)
	var peak: float = 0.001
	for frame in range(count):
		var value: float = raw[frame]
		if frame < overlap:
			var weight = smoothstep(0.0, 1.0, float(frame) / (overlap - 1))
			# End-to-start remains adjacent source samples; overlap blends back to head.
			value = lerpf(raw[count + frame], raw[frame], weight)
		samples[frame] = value
		peak = maxf(peak, absf(value))
	var bytes = PackedByteArray()
	bytes.resize(count * 2)
	for frame in range(count):
		bytes.encode_s16(frame * 2, int(samples[frame] / peak * 0.25 * 32767))
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
	print("Authored ", name, ": 20s mono PCM16, peak <= .25, seed ", seed)
