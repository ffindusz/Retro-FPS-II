extends Node3D
## Presentation only for the Meshy-rigged Adept. The enemy owns movement, casting and damage.
## Same interface as the Warden presentation; the staff is part of the skinned mesh.

const BODY = preload("res://assets/models/adept-animated/animate.glb")
const CLIPS = {&"Idle": &"Idle", &"Walk": &"Casual_Walk", &"Attack": &"Charged_Spell_Cast", &"Hit": &"Hit_Reaction", &"Death": &"Fall_Dead_from_Abdominal_Injury"}
## Native cast time at which the bolt visibly leaves; mapped onto the AI's existing windup.
const NATIVE_RELEASE: float = 1.85
const TRANSITION_SECONDS: float = 0.12
const HIT_SECONDS: float = 0.35
const WALK_STRIDE_METERS: float = 1.3
const REST_BOUNDS := AABB(Vector3(-0.367, 0, -0.458), Vector3(0.734, 2.0, 0.916))

var model: Node3D
var skeleton: Skeleton3D
var animation: AnimationPlayer
var body: MeshInstance3D
var material: StandardMaterial3D
var base_color: Color
var root_bone: int
var mode: StringName = &"Idle"
var native_time: float = 0.0
var idle_time: float = 0.0
var walk_time: float = 0.0
var hit_remaining: float = 0.0
var hit_age: float = 0.0
var flash_remaining: float = 0.0
var death_age: float = 0.0
var dead: bool = false
var attack_active: bool = false
var contacted: bool = false
var recovery_age: float = 0.0
var just_contacted: bool = false
var blend_age: float = TRANSITION_SECONDS
var pose_positions: Array[Vector3] = []
var pose_rotations: Array[Quaternion] = []
var pose_scales: Array[Vector3] = []
var blend_positions: Array[Vector3] = []
var blend_rotations: Array[Quaternion] = []
var blend_scales: Array[Vector3] = []

func _ready() -> void:
	var normalizer := Node3D.new()
	# Meshy characters face +Z; enemies face -Z.
	normalizer.rotation.y = PI
	add_child(normalizer)
	model = BODY.instantiate()
	normalizer.add_child(model)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	animation = model.find_children("*", "AnimationPlayer", true, false)[0]
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.skin != null:
			body = mesh
			material = (mesh.get_active_material(0) as StandardMaterial3D).duplicate()
			mesh.set_surface_override_material(0, material)
			# Visual-only culling bound that covers the lying pose.
			var to_mesh: Transform3D = mesh.global_transform.affine_inverse() * global_transform
			mesh.custom_aabb = to_mesh * AABB(Vector3(-1.75, -0.4, -1.75), Vector3(3.5, 3.0, 3.5))
	base_color = material.albedo_color
	root_bone = skeleton.find_bone(&"Hips")
	_sample(&"Idle", 0.0, 0.0, true)

func normalized_rest_bounds() -> AABB:
	return REST_BOUNDS

func clip_length(role: StringName) -> float:
	return animation.get_animation(CLIPS[role]).length

func _switch_mode(next_mode: StringName) -> void:
	if mode == next_mode:
		return
	blend_positions = pose_positions.duplicate()
	blend_rotations = pose_rotations.duplicate()
	blend_scales = pose_scales.duplicate()
	blend_age = 0.0
	mode = next_mode

func _sample(next_mode: StringName, time: float, delta: float, exact: bool = false) -> void:
	_switch_mode(next_mode)
	var clip: StringName = CLIPS[next_mode]
	if animation.current_animation != clip:
		animation.stop()
		skeleton.reset_bone_poses()
		animation.play(clip)
	native_time = clampf(time, 0.0, animation.get_animation(clip).length)
	animation.seek(native_time, true)
	animation.advance(0.0)
	# Keep the body over the actor's collider: no horizontal root drift.
	var root_position := skeleton.get_bone_pose_position(root_bone)
	var rest := skeleton.get_bone_rest(root_bone).origin
	root_position.x = rest.x
	root_position.z = rest.z
	skeleton.set_bone_pose_position(root_bone, root_position)
	blend_age = TRANSITION_SECONDS if exact else minf(TRANSITION_SECONDS, blend_age + delta)
	var weight := smoothstep(0.0, TRANSITION_SECONDS, blend_age)
	pose_positions.clear()
	pose_rotations.clear()
	pose_scales.clear()
	for bone in range(skeleton.get_bone_count()):
		var position := skeleton.get_bone_pose_position(bone)
		var rotation := skeleton.get_bone_pose_rotation(bone)
		var scale := skeleton.get_bone_pose_scale(bone)
		if weight < 1.0 and blend_positions.size() == skeleton.get_bone_count():
			position = blend_positions[bone].lerp(position, weight)
			rotation = blend_rotations[bone].slerp(rotation, weight)
			scale = blend_scales[bone].lerp(scale, weight)
			skeleton.set_bone_pose_position(bone, position)
			skeleton.set_bone_pose_rotation(bone, rotation)
			skeleton.set_bone_pose_scale(bone, scale)
		pose_positions.append(position)
		pose_rotations.append(rotation)
		pose_scales.append(scale)
	skeleton.force_update_all_bone_transforms()

func begin_attack() -> void:
	if dead or get_tree().paused:
		return
	attack_active = true
	contacted = false
	just_contacted = false
	recovery_age = 0.0
	hit_remaining = 0.0
	_sample(&"Attack", 0.0, 0.0)

func attack_contact() -> void:
	if dead or get_tree().paused:
		return
	if not attack_active:
		begin_attack()
	contacted = true
	just_contacted = true
	recovery_age = 0.0
	_sample(&"Attack", NATIVE_RELEASE, 0.0, true)

func show_hit() -> void:
	if dead or get_tree().paused:
		return
	flash_remaining = 0.18
	if not attack_active:
		hit_remaining = HIT_SECONDS
		hit_age = 0.0
	_apply_flash()

func die() -> void:
	if dead:
		return
	dead = true
	attack_active = false
	contacted = false
	hit_remaining = 0.0
	flash_remaining = 0.0
	death_age = 0.0
	_apply_flash()
	_sample(&"Death", 0.0, 0.0)

func _apply_flash() -> void:
	material.albedo_color = base_color.lerp(Color(1.0, 0.75, 0.6, base_color.a), 0.22 * clampf(flash_remaining / 0.18, 0.0, 1.0))

func advance_visual(delta: float, movement_distance: float, ai_attacking: bool, windup_remaining: float, windup_duration: float) -> void:
	if get_tree().paused:
		return
	flash_remaining = maxf(0.0, flash_remaining - delta)
	_apply_flash()
	if dead:
		death_age = minf(death_age + delta, clip_length(&"Death"))
		_sample(&"Death", death_age, delta)
		return
	if ai_attacking:
		if not attack_active or contacted:
			begin_attack()
		var progress := 1.0 - clampf(windup_remaining / maxf(windup_duration, 0.001), 0.0, 1.0)
		_sample(&"Attack", NATIVE_RELEASE * progress, delta)
		return
	if attack_active and contacted:
		if just_contacted:
			just_contacted = false
		else:
			recovery_age += delta
		var time := NATIVE_RELEASE + recovery_age
		if time < clip_length(&"Attack"):
			_sample(&"Attack", time, delta)
			return
		attack_active = false
	attack_active = false
	if hit_remaining > 0.0:
		hit_remaining = maxf(0.0, hit_remaining - delta)
		hit_age += delta
		if hit_remaining > 0.0:
			_sample(&"Hit", hit_age, delta)
			return
	if movement_distance > 0.0001:
		var length := clip_length(&"Walk")
		walk_time = fposmod(walk_time + movement_distance * length / WALK_STRIDE_METERS, length)
		_sample(&"Walk", walk_time, delta)
	else:
		idle_time = fposmod(idle_time + delta, clip_length(&"Idle"))
		_sample(&"Idle", idle_time, delta)
