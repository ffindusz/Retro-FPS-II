class_name KeyWard
extends StaticBody3D
## Arcane bars sealing the ember-key alcove. Opens once, when every registered guard has died.

signal opened
const SIZE := Vector3(2.0, 3.0, 0.3)
const SINK := 3.1
const OPEN_TIME := 1.2
const HINT_RANGE := 3.5
const OPEN_TEXT := "The ward lifts. The ember key is free."
const HINT_TEXT := "Defeat the key guards to lift the ward."
var open_text: String = OPEN_TEXT
var hint_text: String = HINT_TEXT
var guards: Array[Node] = []
var is_open: bool = false
var player: DemoPlayer
var player_near: bool = false
var shape: CollisionShape3D
var visual: Node3D

func _ready() -> void:
	name = "KeyWard"
	add_to_group("key_ward")
	collision_layer = 1
	collision_mask = 0
	shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = SIZE
	shape.shape = box
	shape.position.y = SIZE.y / 2.0
	add_child(shape)
	visual = Node3D.new()
	visual.name = "VisualRoot"
	add_child(visual)
	var iron = Color("2c2a28")
	for index in range(7):
		PrimitiveArt.box(visual, Vector3(-0.9 + index * 0.3, SIZE.y / 2.0, 0), Vector3(0.07, SIZE.y, 0.07), iron)
	for y in [0.15, 1.5, 2.85]:
		PrimitiveArt.box(visual, Vector3(0, y, 0), Vector3(SIZE.x, 0.1, 0.1), iron)
	var veil = PrimitiveArt.mesh_node(visual, _plane(), Vector3(0, SIZE.y / 2.0, 0), Color(0.9, 0.45, 0.15, 0.3), 1.2)
	veil.name = "Veil"
	veil.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	veil.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	PrimitiveArt.orb(visual, Vector3(0, 1.5, 0.08), 0.16, Color("e7ba5b"), 1.6)

func _plane() -> Mesh:
	var mesh = QuadMesh.new()
	mesh.size = Vector2(SIZE.x - 0.1, SIZE.y - 0.1)
	return mesh

func add_guard(guard: Node) -> void:
	guards.append(guard)
	guard.died.connect(_on_guard_died, CONNECT_ONE_SHOT)

func living_guards() -> int:
	var count = 0
	for guard in guards:
		if is_instance_valid(guard) and guard.state != guard.State.DEAD:
			count += 1
	return count

func _on_guard_died() -> void:
	if living_guards() == 0:
		open()

func open() -> void:
	if is_open:
		return
	is_open = true
	shape.set_deferred("disabled", true)
	var tween = create_tween()
	# The bars sink into the floor slab; nothing is left hanging above the alcove walls.
	tween.tween_property(visual, "position:y", -SINK, OPEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(visual.hide)
	if is_instance_valid(player):
		player.message.emit(open_text)
	opened.emit()

func _physics_process(_delta: float) -> void:
	if is_open or not is_instance_valid(player):
		return
	var near = player.global_position.distance_to(global_position) <= HINT_RANGE
	if near and not player_near and player.can_act():
		player.message.emit(hint_text)
	player_near = near
