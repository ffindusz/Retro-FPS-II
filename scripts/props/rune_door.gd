@tool
class_name RuneDoor
extends Node3D
## Sliding stone exit door built from the Meshy rune door frame, door leaf and key socket.
## The origin is the middle of the threshold; the front faces -Z, towards the approaching player.
## Inserting the ember key at the socket wakes the runes and slides both leaves sideways into the
## walls; walking through the open doorway finishes the level.

signal key_inserted
signal opened
signal passed

enum State { SEALED, KEYED, OPENING, OPEN }

const FRAME := preload("res://assets/models/rune-door-frame/model.glb")
const LEAF := preload("res://assets/models/rune-door-leaf/model.glb")
const SOCKET := preload("res://assets/models/rune-key-socket/model.glb")
const FRAME_GLOW := preload("res://assets/models/rune-door-frame/rune_glow.png")
const SOCKET_GLOW := preload("res://assets/models/rune-key-socket/rune_glow.png")
## The frame model is about 0.71 x 0.95 x 0.23 units; at 6x its doorway is 2.32 m wide and 4.22 m high.
const FRAME_SCALE := 6.0
const OPENING := Vector2(2.32, 4.22)
const LEAF_SIZE := Vector3(1.2, 4.3, 0.36)
## Leaves run in the middle of the frame's depth, just behind its front face.
const LEAF_Z := 0.1
## Key socket in front of the right-hand pillar as seen by the approaching player.
const SOCKET_OFFSET := Vector3(-2.75, 0, -1.3)
const SOCKET_HEIGHT := 1.15
const DOOR_RANGE := 3.0
const SOCKET_RANGE := 2.4
const OPEN_DELAY := 1.2
const OPEN_SECONDS := 3.2
const IDLE_GLOW := 0.7
const KEYED_GLOW := 2.6
const EMBER := Color(1.0, 0.42, 0.12)
const SEALED_TEXT := "The rune door is sealed. Its socket waits for the ember key."
const KEY_TEXT := "The ember key turns in the socket. The runes blaze."
const OPEN_TEXT := "The rune door grinds open. The way onward lies beyond."

var state: State = State.SEALED
var elapsed: float = 0.0
var phase: float = 0.0
var glow: float = IDLE_GLOW
var player: DemoPlayer
var leaves: Array[AnimatableBody3D] = []
var socket: Node3D
var socket_body: StaticBody3D
var key_visual: Node3D
var materials: Array[StandardMaterial3D] = []
var rune_material: StandardMaterial3D
var socket_material: StandardMaterial3D
var door_light: OmniLight3D

func _ready() -> void:
	_build_frame()
	for side in [1.0, -1.0]:
		_build_leaf(side)
	_build_socket()
	door_light = OmniLight3D.new()
	door_light.name = "RuneLight"
	door_light.light_color = EMBER
	door_light.omni_range = 7.0
	# Far enough out that it warms the floor and walls instead of flooding the frame itself.
	door_light.position = Vector3(0, 4.6, -3.0)
	add_child(door_light)
	_apply_glow()

func _build_frame() -> void:
	var frame := FRAME.instantiate() as Node3D
	frame.name = "Frame"
	frame.rotation.y = PI
	# Stands 0.2 m proud of a 0.8 m wall; its rough back ends inside the wall.
	frame.scale = Vector3.ONE * FRAME_SCALE
	frame.position = Vector3(0, 0.476 * FRAME_SCALE, -0.1)
	add_child(frame)
	for mesh in frame.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = _glowing(mesh.get_active_material(0), FRAME_GLOW)
	# Pillars and lintel; in a level they sit inside the surrounding wall.
	var body := StaticBody3D.new()
	body.name = "FrameBody"
	body.collision_mask = 0
	add_child(body)
	var pillar := (FRAME_SCALE * 0.708 - OPENING.x) / 2.0
	for side in [1.0, -1.0]:
		_box(body, Vector3(side * (OPENING.x + pillar) / 2.0, OPENING.y / 2.0, 0.0), Vector3(pillar, OPENING.y, 1.2))
	_box(body, Vector3(0, (OPENING.y + FRAME_SCALE * 0.952) / 2.0, 0.0), Vector3(FRAME_SCALE * 0.708, FRAME_SCALE * 0.952 - OPENING.y, 1.2))

func _build_leaf(side: float) -> void:
	var leaf := AnimatableBody3D.new()
	leaf.name = "LeafLeft" if side > 0 else "LeafRight"
	leaf.sync_to_physics = false
	leaf.collision_mask = 0
	leaf.position = Vector3(side * LEAF_SIZE.x / 2.0, LEAF_SIZE.y / 2.0, LEAF_Z)
	add_child(leaf)
	_box(leaf, Vector3.ZERO, LEAF_SIZE)
	var model := LEAF.instantiate() as Node3D
	model.name = "Model"
	# The slab is carved on both faces: the second leaf shows its back instead of a mirrored copy
	# (negative scale would flip its lighting).
	model.rotation.y = PI if side > 0 else 0.0
	model.scale = Vector3(LEAF_SIZE.x / 0.232, LEAF_SIZE.y / 0.951, LEAF_SIZE.z / 0.156)
	leaf.add_child(model)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var material := (mesh.get_active_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
		material.metallic = 0.0
		material.roughness = 0.8
		# The leaf texture is near-black granite; lift it towards the frame's grey.
		material.albedo_color = Color(2.2, 2.2, 2.2)
		mesh.material_override = material
	leaf.add_child(_runes())
	leaves.append(leaf)

## Glowing strokes over the leaf's carved ring and spine, with angular branches along the spine.
func _runes() -> MeshInstance3D:
	if rune_material == null:
		rune_material = StandardMaterial3D.new()
		rune_material.albedo_color = Color(0.25, 0.08, 0.03)
		rune_material.emission_enabled = true
		rune_material.emission = EMBER
		materials.append(rune_material)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var face := -LEAF_SIZE.z / 2.0 - 0.006
	var top := 1.65
	var bottom := -1.31
	_stroke(tool, Vector3(0, (top - 0.24 + bottom) / 2.0, face), Vector2(0.045, top - 0.24 - bottom), 0.0)
	# Carved ring at the top of the spine.
	for index in 16:
		var angle := TAU * index / 16.0
		_stroke(tool, Vector3(sin(angle) * 0.2, top + cos(angle) * 0.2, face), Vector2(0.04, 0.085), -angle)
	# Each rune is a stretch of the spine plus angular twigs: [height, side, angle from straight up].
	var twigs := [
		[0.95, 1.0, 0.75], [0.95, -1.0, 0.75],
		[0.45, 1.0, 2.35], [0.3, -1.0, 0.8],
		[-0.15, 1.0, 0.8], [-0.15, 1.0, 2.35],
		[-0.65, -1.0, 0.75], [-0.65, 1.0, 2.4],
		[-1.05, -1.0, 2.35], [-1.05, 1.0, 2.35],
	]
	for twig in twigs:
		var length := 0.3
		var side: float = twig[1]
		var angle: float = twig[2]
		var direction := Vector3(side * sin(angle), cos(angle), 0)
		_stroke(tool, Vector3(0, twig[0], face) + direction * length / 2.0, Vector2(0.04, length), -side * angle)
	tool.generate_normals()
	var node := MeshInstance3D.new()
	node.name = "Runes"
	node.mesh = tool.commit()
	node.material_override = rune_material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

## A thin rectangle in the leaf face plane, rotated by `angle` around the face normal.
func _stroke(tool: SurfaceTool, center: Vector3, size: Vector2, angle: float) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(size.x, size.y, 0.012)
	tool.append_from(box, 0, Transform3D(Basis(Vector3.BACK, angle), center))

func _build_socket() -> void:
	socket = Node3D.new()
	socket.name = "KeySocket"
	socket.position = SOCKET_OFFSET
	# Keyhole faces the approaching player (-Z) and turns a little towards the doorway.
	socket.rotation.y = PI - 0.35
	add_child(socket)
	var model := SOCKET.instantiate() as Node3D
	model.name = "Model"
	model.scale = Vector3.ONE * SOCKET_HEIGHT / 0.952
	model.position.y = SOCKET_HEIGHT / 2.0
	socket.add_child(model)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		socket_material = _glowing(mesh.get_active_material(0), SOCKET_GLOW)
		mesh.material_override = socket_material
	socket_body = StaticBody3D.new()
	socket_body.name = "SocketBody"
	socket_body.collision_mask = 0
	socket.add_child(socket_body)
	_box(socket_body, Vector3.UP * SOCKET_HEIGHT / 2.0, Vector3(0.44, SOCKET_HEIGHT, 0.44))

func _glowing(source: Material, mask: Texture2D) -> StandardMaterial3D:
	var material := (source as StandardMaterial3D).duplicate() as StandardMaterial3D
	material.metallic = 0.0
	material.roughness = 0.85
	material.emission_enabled = true
	material.emission = EMBER
	material.emission_texture = mask
	# Multiply, not the default add: only the masked runes may glow.
	material.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	materials.append(material)
	return material

func _box(body: CollisionObject3D, center: Vector3, size: Vector3) -> void:
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = center
	body.add_child(shape)

func is_sealed() -> bool:
	return state == State.SEALED

func is_open() -> bool:
	return state == State.OPEN

## Player pressed interact. Returns true when the key went into the socket.
func interact(actor: DemoPlayer) -> bool:
	if state != State.SEALED or not actor.can_act():
		return false
	var near_socket := actor.global_position.distance_to(socket.global_position) <= SOCKET_RANGE
	var near_door := actor.global_position.distance_to(global_position) <= DOOR_RANGE
	if not (near_socket or near_door):
		return false
	var target := socket.global_position + Vector3.UP * 0.8 if near_socket else to_global(Vector3(0, 1.5, -0.5))
	var query := PhysicsRayQueryParameters3D.create(actor.camera.global_position, target, 1)
	var excluded: Array[RID] = [socket_body.get_rid()]
	for leaf in leaves:
		excluded.append(leaf.get_rid())
	query.exclude = excluded
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return false
	if not actor.has_key:
		actor.message.emit(SEALED_TEXT)
		return false
	player = actor
	state = State.KEYED
	elapsed = 0.0
	_show_key()
	actor.message.emit(KEY_TEXT)
	CombatEvents.publish(self, &"rune_door_key", socket.global_position + Vector3.UP * 0.8)
	key_inserted.emit()
	return true

func _show_key() -> void:
	key_visual = Node3D.new()
	key_visual.name = "InsertedKey"
	# Pushed into the round keyhole on the socket's front face, bow sticking out towards the player.
	key_visual.position = Vector3(0, 0.73, 0.3)
	key_visual.rotation.x = PI / 2.0
	socket.add_child(key_visual)
	PrimitiveArt.cylinder(key_visual, Vector3.ZERO, 0.04, 0.3, Color("e7ba5b"))
	PrimitiveArt.orb(key_visual, Vector3(0, 0.17, 0), 0.09, Color("e7ba5b"), 0.8)

func _process(delta: float) -> void:
	phase += delta
	if Engine.is_editor_hint():
		return
	elapsed += delta
	match state:
		State.SEALED:
			glow = IDLE_GLOW * (0.8 + 0.2 * sin(phase * 1.6))
		State.KEYED:
			glow = lerpf(IDLE_GLOW, KEYED_GLOW, smoothstep(0.0, OPEN_DELAY, elapsed))
			if elapsed >= OPEN_DELAY:
				state = State.OPENING
				elapsed = 0.0
				CombatEvents.publish(self, &"rune_door_open", to_global(Vector3(0, 1.5, 0)))
		State.OPENING:
			glow = KEYED_GLOW
			_place_leaves(smoothstep(0.0, 1.0, elapsed / OPEN_SECONDS))
			if elapsed >= OPEN_SECONDS:
				_place_leaves(1.0)
				state = State.OPEN
				if is_instance_valid(player):
					player.message.emit(OPEN_TEXT)
				opened.emit()
		State.OPEN:
			glow = KEYED_GLOW * (0.85 + 0.15 * sin(phase * 2.2))
	_apply_glow()

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or state != State.OPEN or not is_instance_valid(player):
		return
	var local := to_local(player.global_position)
	if local.z > 0.8 and absf(local.x) < OPENING.x / 2.0:
		set_physics_process(false)
		passed.emit()

## 0 = closed, 1 = both leaves inside the walls on either side.
func _place_leaves(amount: float) -> void:
	for leaf in leaves:
		var side := signf(leaf.position.x)
		leaf.position.x = side * (LEAF_SIZE.x / 2.0 + LEAF_SIZE.x * amount)

func _apply_glow() -> void:
	for material in materials:
		material.emission_energy_multiplier = glow * (1.6 if material == rune_material else 1.0)
	if socket_material:
		socket_material.emission_energy_multiplier = glow * (0.9 if state != State.SEALED else 0.5)
	if door_light:
		door_light.light_energy = 0.05 + glow * 0.12
