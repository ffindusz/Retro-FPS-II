extends "res://scripts/prototypes/warden_motion_study.gd"
## A real skinned derivative, isolated from live enemies and authoritative damage.

const RIG = preload("res://assets/prototypes/warden-rig/warden_rig.glb")
const RIG_CLIPS: Array[StringName] = [&"Idle", &"Walk", &"Attack"]
const LENGTHS: Array[float] = [2.0, 1.0, 1.4]
var skeleton: Skeleton3D
var animation: AnimationPlayer
var body: MeshInstance3D
var bone_lines: MeshInstance3D
var show_bones: bool = false
var view_index: int = 0
var vertices: PackedVector3Array
var joints: PackedInt32Array
var weights: PackedFloat32Array
var influences: int = 4
var bind_bones: PackedInt32Array

func _build_stage() -> void:
	super._build_stage()
	var stand := candidate.get_parent()
	candidate.free()
	candidate = RIG.instantiate()
	stand.add_child(candidate)
	skeleton = candidate.find_children("*", "Skeleton3D", true, false)[0]
	animation = candidate.find_children("*", "AnimationPlayer", true, false)[0]
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var source_mesh: MeshInstance3D = baseline.find_children("*", "MeshInstance3D", true, false)[0]
	for node in candidate.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for surface in range(mesh.mesh.get_surface_count()):
			mesh.set_surface_override_material(surface, source_mesh.get_active_material(0))
		if mesh.skin != null:
			body = mesh
	var arrays := body.mesh.surface_get_arrays(0)
	vertices = arrays[Mesh.ARRAY_VERTEX]
	joints = arrays[Mesh.ARRAY_BONES]
	weights = arrays[Mesh.ARRAY_WEIGHTS]
	influences = joints.size() / vertices.size()
	for bind in range(body.skin.get_bind_count()):
		var name := body.skin.get_bind_name(bind)
		bind_bones.append(skeleton.find_bone(name) if not name.is_empty() else body.skin.get_bind_bone(bind))
	bone_lines = MeshInstance3D.new()
	bone_lines.mesh = ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("59e6e8")
	material.no_depth_test = true
	bone_lines.material_override = material
	skeleton.add_child(bone_lines)
	bone_lines.visible = false

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var top := VBoxContainer.new()
	top.position = Vector2(28, 18)
	canvas.add_child(top)
	_label(top, "WARDEN / skeletal rig prototype", 26)
	var warning := _label(top, "LOCAL RIG - actual bones/skin. Visual-only; no AI, damage or game integration.", 18)
	warning.modulate = Color("f3ca85")
	phase_label = _label(top, "", 20)
	mode_label = _label(top, "", 17)
	var columns := HBoxContainer.new()
	columns.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	columns.offset_top = 168
	columns.offset_bottom = 198
	canvas.add_child(columns)
	for title in ["LEFT / original static Warden", "RIGHT / 21-bone skinned prototype"]:
		var label := _label(columns, title, 18)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 28
	bottom.offset_top = -96
	bottom.offset_right = -20
	bottom.offset_bottom = -14
	canvas.add_child(bottom)
	_label(bottom, "0 Auto | 1 Idle | 2 Walk (in-place) | 3 Attack | Space Pause/resume | R Replay", 18)
	_label(bottom, "B Skeleton overlay | V Front/side/back | Esc Quit", 18)
	_label(bottom, "0.55s attack marker is visual only. Review shoulders, hips, cape and hand/blade attachment.", 16)

func advance(delta: float) -> void:
	if paused:
		return
	clip_time += maxf(delta, 0.0)
	while clip_time >= LENGTHS[clip_index]:
		clip_time -= LENGTHS[clip_index]
		if automatic:
			clip_index = (clip_index + 1) % RIG_CLIPS.size()
	_update_poses()

func select_clip(index: int, auto_sequence: bool = false) -> void:
	clip_index = clampi(index, 0, RIG_CLIPS.size() - 1)
	clip_time = 0.0
	automatic = auto_sequence
	_update_poses()

func _update_poses() -> void:
	var clip: StringName = RIG_CLIPS[clip_index]
	if animation.current_animation != clip:
		animation.play(clip)
	animation.seek(clip_time, true)
	animation.advance(0.0)
	skeleton.force_update_all_bone_transforms()
	var phase := MOTION.phase(&"attack", clip_time) if clip == &"Attack" else "In-place skeletal cycle"
	phase_label.text = "%s / %.2fs / %s" % [clip, clip_time, phase]
	mode_label.text = "%s | %s | %d bones | %s view | Skeleton %s" % ["PAUSED" if paused else "Playing", "Auto sequence" if automatic else "Single clip loop", skeleton.get_bone_count(), ["Front", "Side", "Back"][view_index], "on" if show_bones else "off"]
	bone_lines.visible = show_bones
	if show_bones:
		var lines := bone_lines.mesh as ImmediateMesh
		lines.clear_surfaces()
		lines.surface_begin(Mesh.PRIMITIVE_LINES)
		for bone in range(skeleton.get_bone_count()):
			var parent := skeleton.get_bone_parent(bone)
			if parent >= 0:
				lines.surface_add_vertex(skeleton.get_bone_global_pose(parent).origin)
				lines.surface_add_vertex(skeleton.get_bone_global_pose(bone).origin)
		lines.surface_end()

func set_view(index: int) -> void:
	view_index = posmod(index, 3)
	var angle: float = [0.0, PI / 2.0, PI][view_index]
	baseline.get_parent().rotation.y = angle
	candidate.get_parent().rotation.y = angle
	_update_poses()

func skinned_vertex(index: int) -> Vector3:
	# CPU reference for validation: actual bind matrices and current skeleton poses.
	var result := Vector3.ZERO
	for slot in range(influences):
		var weight := weights[index * influences + slot]
		if weight <= 0.0:
			continue
		var bind := joints[index * influences + slot]
		var matrix := skeleton.get_bone_global_pose(bind_bones[bind]) * body.skin.get_bind_pose(bind)
		result += matrix * vertices[index] * weight
	return candidate.global_transform.affine_inverse() * skeleton.global_transform * result

func dominant_bone(index: int) -> StringName:
	var best := 0
	for slot in range(1, influences):
		if weights[index * influences + slot] > weights[index * influences + best]:
			best = slot
	return skeleton.get_bone_name(bind_bones[joints[index * influences + best]])

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_3:
		select_clip(event.keycode - KEY_1)
	elif event.keycode == KEY_0:
		select_clip(0, true)
	elif event.keycode == KEY_SPACE:
		paused = not paused
		_update_poses()
	elif event.keycode == KEY_R:
		clip_time = 0.0
		_update_poses()
	elif event.keycode == KEY_B:
		show_bones = not show_bones
		_update_poses()
	elif event.keycode == KEY_V:
		set_view(view_index + 1)
	elif event.keycode == KEY_ESCAPE:
		get_tree().quit()
	else:
		return
	get_viewport().set_input_as_handled()
