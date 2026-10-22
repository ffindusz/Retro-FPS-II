extends SceneTree
## Original static panorama authoring; never invoked during gameplay.

const SIZE = Vector2i(1024, 512)
const SEED = 18419
const MOON_RADIUS = 0.025
const DIRECTORY = "res://assets/environment/sky"
var clouds = FastNoiseLite.new()
var moon_direction = Basis.from_euler(Vector3(deg_to_rad(-55), deg_to_rad(-30), 0)).z

func _initialize() -> void:
	call_deferred("generate")

func direction_at(x: float, y: float) -> Vector3:
	# PanoramaSkyMaterial wraps longitude clockwise from -Z.
	var longitude = (x / (SIZE.x - 1) - 0.5) * TAU
	var latitude = PI * (0.5 - y / (SIZE.y - 1))
	return Vector3(-sin(longitude) * cos(latitude), sin(latitude), cos(longitude) * cos(latitude))

func cloud_at(direction: Vector3) -> float:
	var point = Vector3(direction.x * 4.0, direction.y * 7.0, direction.z * 4.0) + Vector3(15, 3, -7)
	return smoothstep(-0.2, 0.4, clouds.get_noise_3dv(point))

func generate() -> void:
	clouds.seed = SEED
	clouds.frequency = 1.0
	clouds.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	clouds.fractal_type = FastNoiseLite.FRACTAL_FBM
	clouds.fractal_octaves = 5
	var image = Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var direction = direction_at(x, y)
			var height = pow(clampf(direction.y, 0.0, 1.0), 0.45)
			var color = Color(0.27, 0.3, 0.38).lerp(Color(0.095, 0.13, 0.22), height)
			if direction.y < 0.0:
				color = Color(0.07, 0.09, 0.13).lerp(color, exp(direction.y * 12.0))
			else:
				var cover = cloud_at(direction)
				color = color.lerp(Color(0.23, 0.28, 0.37), cover * 0.6 * smoothstep(0.0, 0.18, direction.y))
				var angle = acos(clampf(direction.dot(moon_direction), -1.0, 1.0))
				var glow = exp(-angle * angle / 0.0128) * (1.0 - cover * 0.5)
				color += Color(0.1, 0.13, 0.2) * glow
				var disc = 1.0 - smoothstep(MOON_RADIUS * 0.9, MOON_RADIUS, angle)
				var craters = 0.9 + clouds.get_noise_3dv(direction * 80.0) * 0.15
				color = color.lerp(Color(0.82, 0.86, 0.91) * craters, disc * (1.0 - cover * 0.35))
			image.set_pixel(x, y, color)
	var rng = RandomNumberGenerator.new()
	rng.seed = SEED
	for index in range(160):
		var center = Vector2(rng.randf_range(0, SIZE.x - 1), rng.randf_range(28, SIZE.y * 0.47))
		var radius = rng.randf_range(0.25, 0.5)
		var strength = rng.randf_range(0.25, 0.6) * (1.0 - cloud_at(direction_at(center.x, center.y)) * 0.9)
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var x = posmod(int(center.x) + dx, SIZE.x - 1)
				var y = clampi(int(center.y) + dy, 0, SIZE.y - 1)
				var distance = (Vector2(int(center.x) + dx, int(center.y) + dy) - center).length_squared()
				var weight = exp(-distance / (2.0 * radius * radius)) * strength
				image.set_pixel(x, y, image.get_pixel(x, y).lerp(Color(0.72, 0.8, 0.94), weight))
	for y in range(SIZE.y):
		image.set_pixel(SIZE.x - 1, y, image.get_pixel(0, y))
	var error = DirAccess.make_dir_recursive_absolute(DIRECTORY)
	if error != OK:
		push_error("Cannot create sky directory: " + error_string(error))
		quit(1)
		return
	var path = DIRECTORY + "/moonlit_fortress.png"
	error = image.save_png(path)
	if error != OK:
		push_error("Cannot save sky panorama: " + error_string(error))
		quit(1)
		return
	var output = FileAccess.open(DIRECTORY + "/provenance.json", FileAccess.WRITE)
	if output == null:
		push_error("Cannot write sky provenance: " + error_string(FileAccess.get_open_error()))
		quit(1)
		return
	output.store_string(JSON.stringify({
		"file": "moonlit_fortress.png", "sha256": FileAccess.get_sha256(path),
		"origin": "Original project art authored offline; no external texture or paid generation",
		"generator": "tools/generate_fortress_sky.gd", "godot": Engine.get_version_info().string,
		"width": SIZE.x, "height": SIZE.y, "seed": SEED, "stars": 160,
		"moon_rotation_degrees": [-55, -30, 0], "moon_angular_radius": MOON_RADIUS,
		"noise": "Spherical smooth simplex, five-octave fBm; fixed cloud coordinates in generator",
		"distribution": "Original project asset; owner chooses the project's distribution license"
	}, "\t"))
	output.close()
	print("Authored original moonlit sky: ", path, "; ", SIZE, "; seed ", SEED)
	quit()
