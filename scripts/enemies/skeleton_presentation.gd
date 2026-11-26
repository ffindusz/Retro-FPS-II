extends Node3D
## Presentation only for the user-supplied skeleton warrior and archer. The enemy owns movement,
## attacks and damage. Same interface as the Adept/Warden presentations.
##
## Clips are sampled manually (like the Adept) so the attack can be stretched over the AI windup:
## native time runs from attack_start to attack_release during the windup, then recovers.

const EYE_FLICKER = preload("res://assets/models/skeleton/eye_flicker.gd")
const TRANSITION_SECONDS: float = 0.15
const HIT_SECONDS: float = 0.3
const FLASH_SECONDS: float = 0.18
const EYE_FADE_SECONDS: float = 1.2

@export var body: PackedScene
## Role -> clip name in the GLB. Roles: Idle, Walk, Run, Attack, Death, Hit (the stagger).
@export var clips: Dictionary = {&"Idle": &"idle", &"Walk": &"walk", &"Run": &"run", &"Attack": &"attack", &"Death": &"death", &"Hit": &"hit"}
@export var attack_start: float = 0.0
@export var attack_release: float = 0.56
## Native seconds played after the release before returning to locomotion.
@export var attack_recovery: float = 0.94
@export var walk_stride_meters: float = 1.1
@export var run_stride_meters: float = 1.6
## Travel speed (m/s) above which the run clip is used.
@export var run_speed: float = 2.6
## Role -> extra yaw in degrees. The idle combat stance turns the head ~30 degrees to the right;
## turning the model back keeps the face (and eyes) toward where the enemy is looking.
@export var clip_yaw: Dictionary = {&"Idle": 30.0}
@export var eye_energy: float = 5.0
@export var eye_light_energy: float = 0.2
@export var eye_light_color: Color = Color(1.0, 0.18, 0.06)
@export var eye_light_range: float = 0.35
## Uniform scale of the model inside the presentation (the actor collider is sized by its own scene).
@export var model_scale: float = 1.0
## Half-width (model metres) of the visual culling box around the actor; it must hold the death pose.
@export var cull_radius: float = 1.75
## Peak backward tilt (radians) of the hit reaction.
@export var flinch_amount: float = 0.16

var model: Node3D
var holder: Node3D
var flinch: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var material: StandardMaterial3D
## Colour of the first skinned surface (kept for callers); `base_colors` holds every surface's.
var base_color: Color
var materials: Array[StandardMaterial3D] = []
var base_colors: Array[Color] = []
var eyes: MeshInstance3D
var eye_light: OmniLight3D
var root_bone: int
var yaw: float = 0.0
var mode: StringName = &"Idle"
var native_time: float = 0.0
var idle_time: float = 0.0
var stride_time: float = 0.0
var hit_remaining: float = 0.0
var flash_remaining: float = 0.0
var death_age: float = 0.0
var dead: bool = false
var staggering: bool = false
var stagger_age: float = 0.0
var attack_active: bool = false
var contacted: bool = false
var just_contacted: bool = false
var recovery_age: float = 0.0
var blend_age: float = TRANSITION_SECONDS
var pose_positions: Array[Vector3] = []
var pose_rotations: Array[Quaternion] = []
var pose_scales: Array[Vector3] = []
var blend_positions: Array[Vector3] = []
var blend_rotations: Array[Quaternion] = []
var blend_scales: Array[Vector3] = []

func _ready() -> void:
	flinch = Node3D.new()
	flinch.name = "Flinch"
	add_child(flinch)
	# The skeleton GLBs face +Z; enemies face -Z. The holder also drives the eye flicker.
	holder = Node3D.new()
	holder.name = "Model"
	holder.rotation.y = PI
	holder.scale = Vector3.ONE * model_scale
	holder.set_script(EYE_FLICKER)
	holder.base_energy = eye_energy
	model = body.instantiate()
	_prepare_model()
	holder.add_child(model)
	flinch.add_child(holder)
	# eye_flicker.gd copied the eye material in _ready; start bright instead of waiting a frame.
	if holder.get("_material") != null:
		holder._material.emission_energy_multiplier = eye_energy
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	player = model.find_children("*", "AnimationPlayer", true, false)[0]
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	# Every skinned surface gets its own material copy, so tint and hit flash reach all of them
	# (the golem has a body and a separate rubble mesh for its crumbling death).
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.skin != null:
			for surface in range(mesh.mesh.get_surface_count()):
				var source := mesh.get_active_material(surface) as StandardMaterial3D
				if source == null:
					continue
				var copy := source.duplicate() as StandardMaterial3D
				mesh.set_surface_override_material(surface, copy)
				materials.append(copy)
				base_colors.append(copy.albedo_color)
				if material == null:
					material = copy
			# Visual-only culling bound that covers the lying death pose.
			var to_mesh: Transform3D = mesh.global_transform.affine_inverse() * global_transform
			mesh.custom_aabb = to_mesh * AABB(Vector3(-cull_radius, -0.4, -cull_radius) * model_scale, Vector3(cull_radius * 2.0, 3.0, cull_radius * 2.0) * model_scale)
	base_color = material.albedo_color
	eyes = model.find_child("EyeGlow", true, false) as MeshInstance3D
	if eyes != null:
		eye_light = OmniLight3D.new()
		eye_light.name = "EyeLight"
		eye_light.light_color = eye_light_color
		eye_light.light_energy = eye_light_energy
		eye_light.omni_range = eye_light_range
		eye_light.shadow_enabled = false
		# Not a torch: the authored-level presentation must not restyle it or add a flame.
		eye_light.add_to_group(&"actor_lights")
		eyes.add_child(eye_light)
		# No shadows, so the light reaches the skull face from between the eyes.
		eye_light.position = eyes.get_aabb().get_center()
	root_bone = skeleton.find_bone(&"Hips")
	_sample(&"Idle", fposmod(position.x * 0.37 + position.z * 0.61, clip_length(&"Idle")), 0.0, true)

## Hook for subclasses: add nodes to the model before it enters the tree (eye_flicker.gd looks for EyeGlow on entry).
func _prepare_model() -> void:
	pass

func has_clips() -> bool:
	for role in clips:
		if not player.has_animation(clips[role]):
			return false
	return true

func clip_length(role: StringName) -> float:
	return player.get_animation(clips[role]).length

func eye_glow() -> float:
	if eyes == null:
		return 0.0
	var eye_material := eyes.get_surface_override_material(0) as StandardMaterial3D
	return eye_material.emission_energy_multiplier if eye_material != null else 0.0

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
	var clip: StringName = clips[next_mode]
	if player.current_animation != clip:
		player.stop()
		skeleton.reset_bone_poses()
		player.play(clip)
	native_time = clampf(time, 0.0, player.get_animation(clip).length)
	player.seek(native_time, true)
	player.advance(0.0)
	# Keep the body over the actor's collider: no horizontal root drift.
	var root_position := skeleton.get_bone_pose_position(root_bone)
	var rest := skeleton.get_bone_rest(root_bone).origin
	root_position.x = rest.x
	root_position.z = rest.z
	skeleton.set_bone_pose_position(root_bone, root_position)
	blend_age = TRANSITION_SECONDS if exact else minf(TRANSITION_SECONDS, blend_age + delta)
	var weight := smoothstep(0.0, TRANSITION_SECONDS, blend_age)
	var target_yaw := deg_to_rad(float(clip_yaw.get(next_mode, 0.0)))
	yaw = target_yaw if exact else move_toward(yaw, target_yaw, delta * deg_to_rad(240.0))
	holder.rotation.y = PI + yaw
	pose_positions.clear()
	pose_rotations.clear()
	pose_scales.clear()
	for bone in range(skeleton.get_bone_count()):
		var bone_position := skeleton.get_bone_pose_position(bone)
		var bone_rotation := skeleton.get_bone_pose_rotation(bone)
		var bone_scale := skeleton.get_bone_pose_scale(bone)
		if weight < 1.0 and blend_positions.size() == skeleton.get_bone_count():
			bone_position = blend_positions[bone].lerp(bone_position, weight)
			bone_rotation = blend_rotations[bone].slerp(bone_rotation, weight)
			bone_scale = blend_scales[bone].lerp(bone_scale, weight)
			skeleton.set_bone_pose_position(bone, bone_position)
			skeleton.set_bone_pose_rotation(bone, bone_rotation)
			skeleton.set_bone_pose_scale(bone, bone_scale)
		pose_positions.append(bone_position)
		pose_rotations.append(bone_rotation)
		pose_scales.append(bone_scale)
	skeleton.force_update_all_bone_transforms()

func begin_attack() -> void:
	if dead or get_tree().paused:
		return
	attack_active = true
	contacted = false
	just_contacted = false
	recovery_age = 0.0
	hit_remaining = 0.0
	_sample(&"Attack", attack_start, 0.0)

func attack_contact() -> void:
	if dead or get_tree().paused:
		return
	if not attack_active:
		begin_attack()
	contacted = true
	just_contacted = true
	recovery_age = 0.0
	_sample(&"Attack", attack_release, 0.0, true)

func show_hit() -> void:
	if dead or get_tree().paused:
		return
	flash_remaining = FLASH_SECONDS
	hit_remaining = HIT_SECONDS
	_apply_flash()

func has_stagger_clip() -> bool:
	return clips.has(&"Hit") and player.has_animation(clips[&"Hit"])

## Starts the hit clip from the top and drops any attack in progress. Returns the clip length in
## seconds (0 without a hit clip), which the enemy uses as its stagger time.
func stagger() -> float:
	if dead or get_tree().paused or not has_stagger_clip():
		return 0.0
	staggering = true
	stagger_age = 0.0
	attack_active = false
	contacted = false
	just_contacted = false
	hit_remaining = 0.0
	flinch.rotation.x = 0.0
	_sample(&"Hit", 0.0, 0.0)
	return clip_length(&"Hit")

func die() -> void:
	if dead:
		return
	dead = true
	staggering = false
	attack_active = false
	contacted = false
	hit_remaining = 0.0
	flash_remaining = 0.0
	death_age = 0.0
	flinch.rotation.x = 0.0
	# Stop the pulse; the eyes fade out over the start of the death clip.
	holder.set_process(false)
	_apply_flash()
	_sample(&"Death", 0.0, 0.0)

func _apply_flash() -> void:
	var amount := 0.35 * clampf(flash_remaining / FLASH_SECONDS, 0.0, 1.0)
	for index in range(materials.size()):
		var base: Color = base_colors[index]
		materials[index].albedo_color = base.lerp(Color(1.0, 0.82, 0.7, base.a), amount)

func _update_eyes() -> void:
	if eyes == null:
		return
	var eye_material := eyes.get_surface_override_material(0) as StandardMaterial3D
	if eye_material == null:
		return
	if dead:
		var fade := 1.0 - clampf(death_age / EYE_FADE_SECONDS, 0.0, 1.0)
		eye_material.emission_energy_multiplier = eye_energy * fade
	eye_light.light_energy = eye_light_energy * eye_material.emission_energy_multiplier / eye_energy
	eye_light.visible = eye_light.light_energy > 0.01

func advance_visual(delta: float, movement_distance: float, ai_attacking: bool, windup_remaining: float, windup_duration: float) -> void:
	if get_tree().paused:
		return
	flash_remaining = maxf(0.0, flash_remaining - delta)
	_apply_flash()
	if hit_remaining > 0.0:
		hit_remaining = maxf(0.0, hit_remaining - delta)
		# Brief backward tilt about the feet; peaks early and settles.
		var age := 1.0 - hit_remaining / HIT_SECONDS
		flinch.rotation.x = flinch_amount * sin(age * PI) * (1.0 - age * 0.5)
	else:
		flinch.rotation.x = 0.0
	if dead:
		death_age = minf(death_age + delta, clip_length(&"Death"))
		_sample(&"Death", death_age, delta)
		_update_eyes()
		return
	_update_eyes()
	if staggering:
		stagger_age += delta
		# The hit clip is the reaction; no extra flinch tilt on top of it.
		hit_remaining = 0.0
		flinch.rotation.x = 0.0
		if stagger_age < clip_length(&"Hit"):
			_sample(&"Hit", stagger_age, delta)
			return
		staggering = false
	if ai_attacking:
		if not attack_active or contacted:
			begin_attack()
		var progress := 1.0 - clampf(windup_remaining / maxf(windup_duration, 0.001), 0.0, 1.0)
		_sample(&"Attack", lerpf(attack_start, attack_release, progress), delta)
		return
	if attack_active and contacted:
		if just_contacted:
			just_contacted = false
		else:
			recovery_age += delta
		if recovery_age < attack_recovery:
			_sample(&"Attack", minf(attack_release + recovery_age, clip_length(&"Attack")), delta)
			return
	attack_active = false
	var speed := movement_distance / maxf(delta, 0.0001)
	if movement_distance > 0.0001:
		var role: StringName = &"Run" if speed > run_speed else &"Walk"
		var stride := run_stride_meters if role == &"Run" else walk_stride_meters
		var length := clip_length(role)
		stride_time = fposmod(stride_time + movement_distance * length / stride, length)
		_sample(role, stride_time, delta)
	else:
		idle_time = fposmod(idle_time + delta, clip_length(&"Idle"))
		_sample(&"Idle", idle_time, delta)
