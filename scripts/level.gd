class_name DemoLevel
extends Node3D
## Fixed, original layout built from reusable primitive geometry, not a random level.

signal completed
signal combat_event(event: Dictionary)
const PLAYER = preload("res://scenes/player/player.tscn")
const MELEE = preload("res://scenes/enemies/melee_enemy.tscn")
const RANGED = preload("res://scenes/enemies/ranged_enemy.tscn")
const PICKUP = preload("res://scenes/props/pickup.tscn")
const NAV_PATH = "res://resources/demo_navigation.tres"
const STONE = Color("44484b")
const TRIM = Color("6b6558")
@export var atmosphere_enabled: bool = true
var player: DemoPlayer
var geometry: Node3D
var navigation: NavigationRegion3D
var exit_position = Vector3(11, 0, -8)
var exit_used: bool = false
var spawn_position = Vector3(0, 0.1, 14)
var combat_enabled: bool = true
var event_serial: int = 0
var feedback: CombatFeedback
var presentation: FortressPresentation
var ambience: Node

func emit_combat(event: Dictionary) -> void:
	if not combat_enabled or get_tree().paused:
		return
	event_serial += 1
	if not event.has("event_id"):
		event["event_id"] = "%d:event:%d" % [get_instance_id(), event_serial]
	combat_event.emit(event)

func _ready() -> void:
	feedback = CombatFeedback.new()
	feedback.name = "CombatFeedback"
	add_child(feedback)
	combat_event.connect(feedback.consume)
	build_geometry()
	_setup_environment()
	if atmosphere_enabled:
		presentation = FortressPresentation.new()
		presentation.name = "FortressPresentation"
		add_child(presentation)
		presentation.setup(self)
	_setup_navigation()
	player = PLAYER.instantiate()
	player.position = spawn_position
	add_child(player)
	_populate()
	if atmosphere_enabled:
		ambience = FortressAmbience.new()
		ambience.name = "FortressAmbience"
		add_child(ambience)

func solid(position: Vector3, size: Vector3, color: Color = STONE) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 0
	geometry.add_child(body)
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	PrimitiveArt.box(body, Vector3.ZERO, size, color)
	return body

func build_geometry() -> void:
	geometry = Node3D.new()
	geometry.name = "Geometry"
	add_child(geometry)
	# Entrance x[-5,5], z[5,19]; courtyard x[-13,13], z[-14,5].
	solid(Vector3(0, -0.3, 12), Vector3(10, 0.6, 14), Color("4a4942"))
	solid(Vector3(0, -0.3, -4.5), Vector3(26, 0.6, 19), Color("4b4d4b"))
	# East crypt x[13,31], z[-14,0]. Door in its west wall at z=-6.
	solid(Vector3(22, -0.3, -7), Vector3(18, 0.6, 14), Color("353c42"))
	solid(Vector3(-5.4, 2, 12), Vector3(0.8, 4, 14))
	solid(Vector3(5.4, 2, 12), Vector3(0.8, 4, 14))
	solid(Vector3(0, 2, 19.4), Vector3(11.6, 4, 0.8))
	# Courtyard south wall leaves a wide entrance.
	solid(Vector3(-9, 2, 5.4), Vector3(8, 4, 0.8))
	solid(Vector3(9, 2, 5.4), Vector3(8, 4, 0.8))
	solid(Vector3(-13.4, 2.5, -4.5), Vector3(0.8, 5, 20.6))
	solid(Vector3(0, 2.5, -14.4), Vector3(27.6, 5, 0.8))
	solid(Vector3(13.4, 2.5, 1.5), Vector3(0.8, 5, 7))
	solid(Vector3(13.4, 2.5, -12), Vector3(0.8, 5, 4))
	# Door span z[-10,-2]; lintel remains above the walking clearance.
	solid(Vector3(13.4, 4.25, -6), Vector3(0.8, 1.5, 8), TRIM)
	solid(Vector3(22, 2, 0.4), Vector3(18, 4, 0.8))
	solid(Vector3(22, 2, -14.4), Vector3(18, 4, 0.8))
	solid(Vector3(31.4, 2, -7), Vector3(0.8, 4, 15.6))
	# Authored cover: broad paths on either side for both actors.
	for point in [Vector3(-4, 0, -3), Vector3(4, 0, -7), Vector3(23, 0, -6)]:
		solid(point + Vector3.UP * 1.25, Vector3(2, 2.5, 2), TRIM)
		solid(point + Vector3.UP * 2.65, Vector3(2.4, 0.3, 2.4), STONE)
	# Battlements and wall bands make the blockout readable without external art.
	for x in range(-12, 14, 2):
		PrimitiveArt.box(geometry, Vector3(x, 5.25, -14.4), Vector3(1, 0.6, 0.8), TRIM)
	for z in range(-13, 5, 2):
		PrimitiveArt.box(geometry, Vector3(-13.4, 5.25, z), Vector3(0.8, 0.6, 1), TRIM)
	for z in [16, 10, 4, -2, -10]:
		var width = 9.8 if z > 5 else 25.8
		PrimitiveArt.box(geometry, Vector3(0, 0.008, z), Vector3(width, 0.016, 0.09), Color("6b6759"))
	_build_exit()
	_sign("THE COURTYARD", Vector3(0, 3.0, 4.9), 0)
	_sign("EMBER CRYPT  →", Vector3(8, 2.6, -13.9), 0)
	_sign("THE EMBER KEY", Vector3(28, 2.6, -13.9), 0)
	for point in [Vector3(-4.8, 2.3, 10), Vector3(4.8, 2.3, 10), Vector3(-12.8, 2.3, -6), Vector3(12.8, 2.3, -1), Vector3(21, 2.3, -13.8), Vector3(30.8, 2.3, -7)]:
		_torch(point)
	for point in [Vector3(-4, 0, 17), Vector3(4, 0, 17), Vector3(16, 0, -12), Vector3(30, 0, -2)]:
		var urn = load("res://scenes/props/urn.tscn").instantiate()
		urn.position = point
		geometry.add_child(urn)

func _build_exit() -> void:
	var root = Node3D.new()
	root.name = "SealedExitVisual"
	root.position = exit_position + Vector3(0, 0, -5.7)
	geometry.add_child(root)
	PrimitiveArt.box(root, Vector3(0, 1.5, 0), Vector3(2.5, 3, 0.25), Color("28343d"))
	for x in [-1.4, 1.4]:
		PrimitiveArt.box(root, Vector3(x, 1.7, 0), Vector3(0.3, 3.4, 0.5), TRIM)
	PrimitiveArt.box(root, Vector3(0, 3.4, 0), Vector3(3.1, 0.35, 0.5), TRIM)
	PrimitiveArt.orb(root, Vector3(0, 1.8, 0.25), 0.2, Color("e7ba5b"), 0.8)
	exit_position = root.position + Vector3(0, 0, 0.6)
	_sign("SEALED GATE  /  E", root.position + Vector3(0, 3.9, 0.2), 0)

func _sign(text: String, position: Vector3, yaw: float) -> void:
	var label = Label3D.new()
	label.text = text
	label.position = position
	label.rotation.y = yaw
	label.font_size = 40
	label.pixel_size = 0.009
	label.modulate = Color("d4bc89")
	geometry.add_child(label)

func _torch(position: Vector3) -> void:
	var root = load("res://scenes/props/torch.tscn").instantiate()
	root.position = position
	if is_equal_approx(position.x, -4.8) or is_equal_approx(position.x, -12.8):
		root.rotation.y = PI / 2.0
	elif is_equal_approx(position.x, 4.8) or is_equal_approx(position.x, 12.8) or is_equal_approx(position.x, 30.8):
		root.rotation.y = -PI / 2.0
	geometry.add_child(root)

func _setup_environment() -> void:
	var world = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("141d29")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9ba8b6")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, -30, 0)
	moon.light_color = Color("a1b5cf")
	moon.light_energy = 0.7
	moon.shadow_enabled = true
	add_child(moon)

func bake_navigation() -> NavigationMesh:
	var mesh = NavigationMesh.new()
	mesh.agent_radius = 0.4
	mesh.agent_height = 2.0
	mesh.agent_max_climb = 0.2
	mesh.cell_size = 0.2
	mesh.cell_height = 0.1
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	var source = NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, source, geometry)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	return mesh

func _setup_navigation() -> void:
	navigation = NavigationRegion3D.new()
	navigation.name = "Navigation"
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map, 0.2)
	NavigationServer3D.map_set_cell_height(get_world_3d().navigation_map, 0.1)
	add_child(navigation)
	if ResourceLoader.exists(NAV_PATH):
		navigation.navigation_mesh = load(NAV_PATH)
	else:
		navigation.navigation_mesh = bake_navigation()
	# Match baked mesh cell size to avoid map quantization warnings.
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map, 0.2)
	NavigationServer3D.map_set_cell_height(get_world_3d().navigation_map, 0.1)

func _populate() -> void:
	# Courtyard flanks overlap a rear caster lane, but remain outside spawn detection.
	for point in [Vector3(-9, 0.1, -10.5), Vector3(10, 0.1, -10), Vector3(18, 0.1, -4), Vector3(25, 0.1, -10)]:
		_spawn_enemy(MELEE, point)
	for point in [Vector3(-6, 0.1, -12), Vector3(29, 0.1, -8)]:
		_spawn_enemy(RANGED, point)
	for point in [Vector3(-2, 0.5, 8), Vector3(-10, 0.5, -9), Vector3(28, 0.5, -2)]:
		_spawn_pickup(0, point)
	for point in [Vector3(2, 0.5, 8), Vector3(8, 0.5, -10), Vector3(17, 0.5, -3)]:
		_spawn_pickup(1, point)
	_spawn_pickup(2, Vector3(28, 0.5, -12))

func _spawn_enemy(scene: PackedScene, position: Vector3) -> void:
	var enemy = scene.instantiate()
	enemy.position = position
	add_child(enemy)
	enemy.target = player

func _spawn_pickup(kind: int, position: Vector3) -> void:
	var pickup = PICKUP.instantiate()
	pickup.kind = kind
	pickup.position = position
	add_child(pickup)

func interact_exit() -> bool:
	if exit_used or not player.can_act() or player.global_position.distance_to(exit_position) > 3.0:
		return false
	var query = PhysicsRayQueryParameters3D.create(player.camera.global_position, exit_position + Vector3.UP * 1.5, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return false
	if not player.has_key:
		player.message.emit("The courtyard gate is sealed. Find the ember key in the crypt.")
		return false
	exit_used = true
	completed.emit()
	return true
