@tool
extends Node3D
## Decorative statue derived from the supplied stone golem model: a smaller, weathered golem frozen
## in one pose on a stone plinth. Static; no animation runs after the pose is set.

const MODEL = preload("res://assets/models/stone_golem/stone_golem.glb")
const PLINTH_SIZE := Vector3(1.0, 0.5, 1.0)
## Clip and time (seconds) for each pose: guard stance, hammer raised, mid-stride.
const POSES := [[&"idle", 0.0], [&"attack", 1.22], [&"walk", 0.21], [&"attack", 0.2]]
const STONE := Color(0.58, 0.6, 0.56)
@export var pose: int = 0
@export var statue_scale: float = 0.6
var model: Node3D

func _ready() -> void:
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(PLINTH_SIZE.x, PLINTH_SIZE.y + 1.4 * statue_scale, PLINTH_SIZE.z)
	shape.shape = box
	shape.position.y = box.size.y / 2.0
	body.add_child(shape)
	PrimitiveArt.box(self, Vector3.UP * PLINTH_SIZE.y / 2.0, PLINTH_SIZE, Color("3e4143"))
	PrimitiveArt.box(self, Vector3.UP * (PLINTH_SIZE.y + 0.03), PLINTH_SIZE + Vector3(0.12, -PLINTH_SIZE.y + 0.06, 0.12), Color("5a564c"))
	model = MODEL.instantiate()
	model.name = "Statue"
	# The golem faces +Z; placements face -Z.
	model.rotation.y = PI
	model.scale = Vector3.ONE * statue_scale
	model.position.y = PLINTH_SIZE.y + 0.06
	add_child(model)
	var entry: Array = POSES[posmod(pose, POSES.size())]
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.play(entry[0])
	player.seek(entry[1], true)
	player.advance(0.0)
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	# Keep the statue over its plinth: no horizontal root drift from the clip.
	var hips := skeleton.find_bone(&"Hips")
	var root_position := skeleton.get_bone_pose_position(hips)
	var rest := skeleton.get_bone_rest(hips).origin
	skeleton.set_bone_pose_position(hips, Vector3(rest.x, root_position.y, rest.z))
	player.active = false
	# Weathered, darker stone than the living golem, and no hammer shine.
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var source := mesh.get_active_material(0) as StandardMaterial3D
		if source == null:
			continue
		var weathered := source.duplicate() as StandardMaterial3D
		weathered.albedo_color = STONE
		weathered.metallic = 0.0
		weathered.roughness = 1.0
		mesh.set_surface_override_material(0, weathered)
		if mesh.skin != null:
			mesh.custom_aabb = AABB(Vector3(-150, -10, -150), Vector3(300, 260, 300))
