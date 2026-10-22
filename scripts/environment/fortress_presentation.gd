class_name FortressPresentation
extends Node3D
## Visual-only level treatment. Never creates physics bodies or modifies actor resources.

var level: Node3D
var materials: Dictionary = {}
var torches: Array[OmniLight3D] = []
var torch_bases: Array[float] = []
var elapsed: float = 0.0
var extra_urns: int = 0

func setup(owner_level: Node3D) -> void:
	level = owner_level
	for node in level.geometry.get_children():
		if node is StaticBody3D:
			for child in node.get_children():
				if child is MeshInstance3D and child.mesh is BoxMesh:
					var family: StringName = &"floor" if node.position.y < 0 else &"wall"
					if node.position.y >= 0 and child.material_override.albedo_color.is_equal_approx(level.TRIM):
						family = &"trim"
					child.material_override = surface(family, area_at(node.position))
		elif node is MeshInstance3D and node.mesh is BoxMesh:
			node.material_override = surface(&"brass" if node.mesh.size.y < 0.05 else &"trim", area_at(node.position))
		elif node.name == "SealedExitVisual":
			for child in node.get_children():
				if child is MeshInstance3D and child.mesh is BoxMesh:
					child.material_override = surface(&"iron" if child.mesh.size.y > 2.9 and child.mesh.size.x > 2 else &"trim", &"court")
		if node.has_node("Light") and node.get_node("Light") is OmniLight3D:
			var light: OmniLight3D = node.get_node("Light")
			light.light_color = Color("ffc28a")
			light.light_energy = 2.0
			light.shadow_enabled = torches.size() in [2, 5]
			if light.shadow_enabled:
				light.shadow_bias = 0.08
				light.shadow_normal_bias = 1.0
				_disable_emitter_shadows(node)
			torches.append(light)
			torch_bases.append(light.light_energy)
	for node in level.get_children():
		if node is WorldEnvironment:
			node.environment.ambient_light_energy = 0.42
			node.environment.ambient_light_color = Color("9eacbd")
			node.environment.background_color = Color("101824")
			_setup_sky(node.environment)
		elif node is DirectionalLight3D:
			node.light_energy = 0.8
			node.light_color = Color("a6bddd")
	_dress()
	set_clock(0.0)

func _setup_sky(environment: Environment) -> void:
	var material = PanoramaSkyMaterial.new()
	material.panorama = load("res://assets/environment/sky/moonlit_fortress.png")
	var sky = Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	sky.sky_material = material
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED

func _disable_emitter_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_emitter_shadows(child)

func area_at(point: Vector3) -> StringName:
	if point.x > 13:
		return &"crypt"
	return &"entrance" if point.z > 5 else &"court"

func surface(family: StringName, area: StringName = &"court") -> StandardMaterial3D:
	if family in [&"iron", &"brass"]:
		area = &"accent"
	var key = "%s:%s" % [family, area]
	if materials.has(key):
		return materials[key]
	var material = StandardMaterial3D.new()
	material.roughness = 1.0
	if family in [&"iron", &"brass"]:
		material.albedo_color = Color("384754") if family == &"iron" else Color("a58b58")
		material.metallic = 0.65
		material.roughness = 0.7
	else:
		var source = "floor" if family == &"floor" else "wall"
		material.albedo_texture = load("res://assets/environment/photographic/%s_albedo.jpg" % source)
		material.roughness_texture = load("res://assets/environment/photographic/%s_roughness.jpg" % source)
		material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		material.normal_enabled = true
		material.normal_texture = load("res://assets/environment/photographic/%s_normal.jpg" % source)
		material.normal_scale = 0.4
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.uv1_scale = Vector3.ONE / (1.8 if family == &"floor" else 2.0)
		material.texture_repeat = true
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		material.albedo_color = Color(0.88, 0.91, 0.96) if area == &"court" else Color(0.88, 0.84, 0.76)
		if area == &"crypt":
			material.albedo_color = Color(0.78, 0.84, 0.9)
	materials[key] = material
	return material

func accent(point: Vector3, size: Vector3, family: StringName = &"trim") -> void:
	var mesh = PrimitiveArt.box(self, point, size, Color.WHITE)
	# These shallow bands sit on existing shadow-casting solids; avoid duplicate passes.
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.material_override = surface(family, area_at(point))

func _dress() -> void:
	# Low-relief bands hug existing wall/column surfaces; no opening is bridged.
	for x in [-4.99, 4.99]:
		accent(Vector3(x, 1.9, 5.9), Vector3(0.035, 3.8, 0.45))
		accent(Vector3(x, 3.65, 5.9), Vector3(0.045, 0.16, 0.55), &"brass")
	for z in [-10.15, -1.85]:
		accent(Vector3(12.985, 1.6, z), Vector3(0.04, 3.2, 0.28))
	accent(Vector3(12.985, 3.7, -6), Vector3(0.04, 0.25, 8.0))
	accent(Vector3(12.955, 3.67, -6), Vector3(0.015, 0.055, 7.7), &"brass")
	for point in [Vector3(-4, 0, -3), Vector3(4, 0, -7), Vector3(23, 0, -6)]:
		accent(point + Vector3.UP * 0.1, Vector3(2.01, 0.2, 2.01))
		accent(point + Vector3.UP * 2.44, Vector3(2.01, 0.12, 2.01), &"brass")
	# Flat key-area inlay rests on the existing floor; it is not an altar/obstacle.
	for x in [-1.1, 1.1]:
		accent(Vector3(28 + x, 0.018, -12), Vector3(0.06, 0.02, 2.2), &"brass")
	for z in [-1.1, 1.1]:
		accent(Vector3(28, 0.018, -12 + z), Vector3(2.2, 0.02, 0.06), &"brass")
	for x in [-0.95, 0.95]:
		accent(Vector3(11 + x, 1.5, -13.56), Vector3(0.065, 2.8, 0.035), &"brass")
	for point in [Vector3(-12, 0, 3.9), Vector3(-11.35, 0, 4.1), Vector3(11.8, 0, 4), Vector3(30, 0, -13.2), Vector3(29.35, 0, -13.35), Vector3(30, 0, -2.8)]:
		var urn = load("res://scenes/props/urn.tscn").instantiate()
		urn.position = point
		add_child(urn)
		extra_urns += 1

func set_clock(value: float) -> void:
	elapsed = maxf(0.0, value)
	for index in range(torches.size()):
		var phase = float(index) * 1.13
		var modulation = 0.05 * sin(elapsed * TAU * 1.1 + phase) + 0.03 * sin(elapsed * TAU * 0.37 + phase * 0.7)
		torches[index].light_energy = torch_bases[index] * (1.0 + modulation)

func advance(delta: float) -> void:
	if get_tree().paused:
		return
	set_clock(elapsed + maxf(0.0, delta))

func _process(delta: float) -> void:
	advance(delta)
