extends Node3D
## Presentation only. The enemy owns all movement, damage and attack decisions.

const BODY = preload("res://assets/models/warden-animated/animate.glb")
const TEXTURED = preload("res://assets/models/warden-animated/texture.glb")
const BLADE = preload("res://scenes/models/iron_blade.tscn")
const GRIP = preload("res://scripts/enemies/warden_grip.gd")
const CLIPS = {&"Idle": &"Idle", &"Walk": &"Walk_Fight_Forward", &"Attack": &"Right_Hand_Sword_Slash", &"Hit": &"Hit_Reaction", &"Death": &"Dead"}
# Frame 18/30: forward slash, after the raised/back-facing blade at frame 15.
# Mapped to the AI's existing windup, never used as a gameplay damage timer.
const NATIVE_CONTACT: float = 0.6
const TRANSITION_SECONDS: float = 0.08
const HIT_SECONDS: float = 0.2
const WALK_STRIDE_METERS: float = 1.6
const REST_BOUNDS := AABB(Vector3(-0.542, 0, -0.270), Vector3(1.084, 1.8063, 0.540))
static var shared_material: StandardMaterial3D

var model: Node3D
var skeleton: Skeleton3D
var animation: AnimationPlayer
var body: MeshInstance3D
var material: StandardMaterial3D
var base_color: Color
var hand_bone: int
var root_bone: int
var hand_attachment: BoneAttachment3D
var weapon_mount: Node3D
var weapon: Node3D
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
	if shared_material == null:
		var source := TEXTURED.instantiate()
		var source_mesh: MeshInstance3D = source.find_children("*", "MeshInstance3D", true, false)[0]
		shared_material = source_mesh.get_active_material(0)
		source.free()
	material = shared_material.duplicate()
	base_color = material.albedo_color
	var normalizer := Node3D.new()
	normalizer.rotation.y = PI
	add_child(normalizer)
	model = BODY.instantiate()
	normalizer.add_child(model)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	animation = model.find_children("*", "AnimationPlayer", true, false)[0]
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for surface in range(mesh.mesh.get_surface_count()):
			mesh.set_surface_override_material(surface, material)
		if mesh.skin != null:
			body = mesh
			# Explicit visual-only culling bound, compensating the source's cm parent.
			var to_mesh: Transform3D = mesh.global_transform.affine_inverse() * global_transform
			mesh.custom_aabb = to_mesh * AABB(Vector3(-1.75, -0.4, -1.75), Vector3(3.5, 3.0, 3.5))
	hand_bone = skeleton.find_bone(&"RightHand")
	root_bone = skeleton.find_bone(&"Hips")
	hand_attachment = BoneAttachment3D.new()
	hand_attachment.bone_name = &"RightHand"
	skeleton.add_child(hand_attachment)
	weapon_mount = Node3D.new()
	hand_attachment.add_child(weapon_mount)
	weapon_mount.top_level = true
	weapon = BLADE.instantiate()
	weapon_mount.add_child(weapon)
	_sample(&"Idle", 0.0, 0.0, true)

func normalized_rest_bounds() -> AABB:
	# Approved raw POSITION/bind-rest extents, not the cm mesh-node AABB or a swing.
	return REST_BOUNDS

func _process(_delta: float) -> void:
	# No clock aging here. This also follows developer teleports with AI frozen.
	update_weapon()

func update_weapon() -> void:
	if is_instance_valid(weapon_mount) and is_inside_tree():
		weapon_mount.global_transform = GRIP.hand_frame(skeleton, hand_bone) * GRIP.mount_transform()

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
	var root_position := skeleton.get_bone_pose_position(root_bone)
	root_position.x = 0.0
	root_position.z = 0.0
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
	update_weapon()

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
	# Sample before gameplay resolution, including misses/occluded swings.
	_sample(&"Attack", NATIVE_CONTACT, 0.0, true)

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
		death_age = minf(death_age + delta, animation.get_animation(CLIPS[&"Death"]).length)
		_sample(&"Death", death_age, delta)
		return
	if ai_attacking:
		if not attack_active or contacted:
			begin_attack()
		var progress := 1.0 - clampf(windup_remaining / maxf(windup_duration, 0.001), 0.0, 1.0)
		_sample(&"Attack", NATIVE_CONTACT * progress, delta)
		return
	if attack_active and contacted:
		if just_contacted:
			just_contacted = false
		else:
			recovery_age += delta
		var time := NATIVE_CONTACT + recovery_age
		if time < animation.get_animation(CLIPS[&"Attack"]).length:
			_sample(&"Attack", time, delta)
			return
		attack_active = false
	if attack_active:
		# An external state cancellation cannot leave a stale committed visual.
		attack_active = false
	if hit_remaining > 0.0:
		hit_remaining = maxf(0.0, hit_remaining - delta)
		hit_age += delta
		if hit_remaining > 0.0:
			_sample(&"Hit", hit_age, delta)
			return
	if movement_distance > 0.0001:
		var length := animation.get_animation(CLIPS[&"Walk"]).length
		walk_time = fposmod(walk_time + movement_distance * length / WALK_STRIDE_METERS, length)
		_sample(&"Walk", walk_time, delta)
	else:
		idle_time = fposmod(idle_time + delta, animation.get_animation(CLIPS[&"Idle"]).length)
		_sample(&"Idle", idle_time, delta)
