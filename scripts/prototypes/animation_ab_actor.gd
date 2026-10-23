extends Node3D
## One imported actor, sampled manually. No gameplay scripts/collision/events.

const CLOCK = preload("res://scripts/prototypes/animation_ab_clock.gd")
var normalizer: Node3D
var motion_offset: Node3D
var model: Node3D
var skeleton: Skeleton3D
var animation: AnimationPlayer
var clips: Array[StringName] = []
var durations: Array[float] = []
var cycle_drifts: Array[Vector3] = []
var root_bone: int = -1
var body: MeshInstance3D
var bone_lines: MeshInstance3D
var rest_bounds: AABB
var normalization_scale: float = 1.0
var last_clip: int = -1
var vertices: PackedVector3Array
var joints: PackedInt32Array
var weights: PackedFloat32Array
var influences: int = 4
var bind_bones: PackedInt32Array

func setup(scene: PackedScene, clip_names: Array, yaw: float, material: Material = null) -> void:
	normalizer = Node3D.new()
	add_child(normalizer)
	motion_offset = Node3D.new()
	normalizer.add_child(motion_offset)
	model = scene.instantiate()
	motion_offset.add_child(model)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	animation = model.find_children("*", "AnimationPlayer", true, false)[0]
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if material != null:
			for surface in range(mesh.mesh.get_surface_count()):
				mesh.set_surface_override_material(surface, material)
		if mesh.skin != null and body == null:
			body = mesh
	var arrays := body.mesh.surface_get_arrays(0)
	vertices = arrays[Mesh.ARRAY_VERTEX]
	joints = arrays[Mesh.ARRAY_BONES]
	weights = arrays[Mesh.ARRAY_WEIGHTS]
	influences = joints.size() / vertices.size()
	for bind in range(body.skin.get_bind_count()):
		var name := body.skin.get_bind_name(bind)
		bind_bones.append(skeleton.find_bone(name) if not name.is_empty() else body.skin.get_bind_bone(bind))
	# Skin binds can compensate an armature's centimetre scale. Raw mesh-node
	# bounds are then 100x too small, despite the rendered skin being meter-scale.
	animation.stop()
	skeleton.reset_bone_poses()
	skeleton.force_update_all_bone_transforms()
	rest_bounds = AABB(skinned_vertex(0), Vector3.ZERO)
	for index in range(1, vertices.size()):
		rest_bounds = rest_bounds.expand(skinned_vertex(index))
	normalization_scale = 1.8063 / rest_bounds.size.y
	normalizer.rotation.y = yaw
	normalizer.scale = Vector3.ONE * normalization_scale
	var center := Vector3(rest_bounds.get_center().x, rest_bounds.position.y, rest_bounds.get_center().z)
	normalizer.position = -(normalizer.basis * center)
	root_bone = 0
	for bone in range(skeleton.get_bone_count()):
		var name := String(skeleton.get_bone_name(bone)).to_lower()
		if name.contains("hips") or name == "pelvis":
			root_bone = bone
			break
	for name in clip_names:
		clips.append(StringName(name))
		durations.append(animation.get_animation(name).length)
	bone_lines = MeshInstance3D.new()
	bone_lines.mesh = ImmediateMesh.new()
	var line_material := StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.albedo_color = Color("59e6e8")
	line_material.no_depth_test = true
	bone_lines.material_override = line_material
	skeleton.add_child(bone_lines)
	bone_lines.hide()
	for clip in range(clips.size()):
		seek(clip, 0.0, false)
		var start := root_position()
		seek(clip, durations[clip], false)
		cycle_drifts.append(root_position() - start)
	seek(0, 0.0, false)

func root_position() -> Vector3:
	# Read raw pose in the model-parent frame, excluding presentation compensation.
	var point: Vector3 = normalizer.global_transform.affine_inverse() * skeleton.global_transform * skeleton.get_bone_global_pose(root_bone).origin
	return point - motion_offset.position

func seek(clip: int, time: float, anchored: bool) -> void:
	if last_clip != clip:
		animation.stop()
		skeleton.reset_bone_poses()
		animation.play(clips[clip])
		last_clip = clip
	animation.seek(time, true)
	animation.advance(0.0)
	skeleton.force_update_all_bone_transforms()
	motion_offset.position = CLOCK.horizontal_cycle_offset(cycle_drifts[clip], time, durations[clip], anchored) if cycle_drifts.size() > clip else Vector3.ZERO
	if bone_lines.visible:
		var lines := bone_lines.mesh as ImmediateMesh
		lines.clear_surfaces()
		lines.surface_begin(Mesh.PRIMITIVE_LINES)
		for bone in range(skeleton.get_bone_count()):
			var parent := skeleton.get_bone_parent(bone)
			if parent >= 0:
				lines.surface_add_vertex(skeleton.get_bone_global_pose(parent).origin)
				lines.surface_add_vertex(skeleton.get_bone_global_pose(bone).origin)
		lines.surface_end()

func skinned_vertex(index: int) -> Vector3:
	var point := Vector3.ZERO
	for slot in range(influences):
		var weight := weights[index * influences + slot]
		if weight > 0.0:
			var bind := joints[index * influences + slot]
			point += skeleton.get_bone_global_pose(bind_bones[bind]) * body.skin.get_bind_pose(bind) * vertices[index] * weight
	return motion_offset.global_transform.affine_inverse() * skeleton.global_transform * point

func presented_vertex(index: int) -> Vector3:
	return normalizer.transform * motion_offset.transform * skinned_vertex(index)
