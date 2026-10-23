extends "res://scripts/prototypes/warden_motion_study.gd"
## New body + native clips + a separate rigid blade. Never drives gameplay.

const ACTOR = preload("res://scripts/prototypes/animation_ab_actor.gd")
const BODY = preload("res://assets/prototypes/warden-pilot/winner/animate.glb")
const TEXTURED = preload("res://assets/prototypes/warden-pilot/winner/texture.glb")
const BLADE = preload("res://scenes/models/iron_blade.tscn")
const GRIP = preload("res://scripts/enemies/warden_grip.gd")
@export var grip_rotation_degrees := GRIP.ROTATION_DEGREES
@export var grip_offset_m := GRIP.PALM_TARGET_M
@export var weapon_scale: float = GRIP.WORLD_SCALE
var pilot: Node3D
var provenance: Dictionary
var hand_bone: int = -1
var hand_attachment: BoneAttachment3D
var weapon_mount: Node3D
var weapon: Node3D
var view_index: int = 0
var show_bones: bool = false
var show_weapon: bool = true

func _ready() -> void:
	automatic = false
	super._ready()

func _build_stage() -> void:
	super._build_stage()
	provenance = JSON.parse_string(FileAccess.get_file_as_string("res://assets/prototypes/warden-pilot/winner/provenance.json"))
	var material_source := TEXTURED.instantiate() as Node3D
	add_child(material_source)
	var source_mesh: MeshInstance3D = material_source.find_children("*", "MeshInstance3D", true, false)[0]
	var material := source_mesh.get_active_material(0)
	var stand := candidate.get_parent()
	candidate.free()
	pilot = ACTOR.new()
	stand.add_child(pilot)
	pilot.setup(BODY, provenance.clip_names, PI, material)
	candidate = pilot
	material_source.free()
	hand_bone = pilot.skeleton.find_bone(provenance.hand_bone)
	hand_attachment = BoneAttachment3D.new()
	hand_attachment.bone_name = provenance.hand_bone
	pilot.skeleton.add_child(hand_attachment)
	weapon_mount = Node3D.new()
	hand_attachment.add_child(weapon_mount)
	# Keep ownership on the hand, but apply a meter-scale orthonormal hand frame.
	# This avoids inheriting the Meshy armature's 0.01 scale or animation shear.
	weapon_mount.top_level = true
	weapon = BLADE.instantiate()
	weapon_mount.add_child(weapon)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 155, 0)
	fill.light_energy = 0.4
	add_child(fill)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var top := VBoxContainer.new()
	top.position = Vector2(28, 18)
	canvas.add_child(top)
	_label(top, "WARDEN / animation-ready pilot - selected body 2", 25)
	var warning := _label(top, "90-credit pilot / native Meshy clips / separate rigid Iron Blade / no gameplay", 18)
	warning.modulate = Color("f3ca85")
	phase_label = _label(top, "", 20)
	mode_label = _label(top, "", 17)
	var columns := HBoxContainer.new()
	columns.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	columns.offset_top = 168
	columns.offset_bottom = 198
	canvas.add_child(columns)
	for title in ["LEFT / accepted static Warden (unchanged)", "RIGHT / new body + hand-attached blade"]:
		var label := _label(columns, title, 17)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 28
	bottom.offset_top = -96
	bottom.offset_right = -20
	bottom.offset_bottom = -14
	canvas.add_child(bottom)
	_label(bottom, "1 Idle | 2 Walk | 3 Attack | 4 Hit | 5 Death | 0 Auto | Space Pause | R Replay", 18)
	_label(bottom, "V Front/side/back | B Skeleton | W Blade visibility | Esc Quit", 18)
	_label(bottom, "Death holds its final pose in single-clip mode. No AI, damage, foot IK or combat synchronization.", 16)

func hand_frame() -> Transform3D:
	var pose: Transform3D = pilot.skeleton.global_transform * pilot.skeleton.get_bone_global_pose(hand_bone)
	return Transform3D(pose.basis.orthonormalized(), pose.origin)

func grip_transform() -> Transform3D:
	return GRIP.mount_transform(grip_rotation_degrees, grip_offset_m, weapon_scale)

func _update_weapon() -> void:
	weapon_mount.global_transform = hand_frame() * grip_transform()
	weapon_mount.visible = show_weapon

func _update_poses() -> void:
	pilot.bone_lines.visible = show_bones
	pilot.seek(clip_index, clip_time, false)
	_update_weapon()
	phase_label.text = "%s / %.2f / %.2fs / native speed" % [provenance.clip_roles[clip_index], clip_time, pilot.durations[clip_index]]
	mode_label.text = "%s | %s | %d bones | Raw root motion | %s view" % ["PAUSED" if paused else "Playing", "Auto sequence" if automatic else "Single clip / death holds", pilot.skeleton.get_bone_count(), ["Front", "Side", "Back"][view_index]]

func advance(delta: float) -> void:
	if paused:
		return
	clip_time += maxf(delta, 0.0)
	if automatic:
		while clip_time >= pilot.durations[clip_index]:
			clip_time -= pilot.durations[clip_index]
			clip_index = (clip_index + 1) % 5
	elif clip_index == 4:
		clip_time = minf(clip_time, pilot.durations[clip_index])
	else:
		clip_time = fposmod(clip_time, pilot.durations[clip_index])
	_update_poses()

func select_clip(index: int, auto_sequence: bool = false) -> void:
	clip_index = clampi(index, 0, 4)
	clip_time = 0.0
	automatic = auto_sequence
	_update_poses()

func set_view(index: int) -> void:
	view_index = posmod(index, 3)
	var angle: float = [0.0, PI / 2.0, PI][view_index]
	baseline.get_parent().rotation.y = angle
	pilot.get_parent().rotation.y = angle
	_update_poses()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_5:
		select_clip(event.keycode - KEY_1)
	elif event.keycode == KEY_0:
		select_clip(0, true)
	elif event.keycode == KEY_SPACE:
		paused = not paused
		_update_poses()
	elif event.keycode == KEY_R:
		clip_time = 0.0
		_update_poses()
	elif event.keycode == KEY_V:
		set_view(view_index + 1)
	elif event.keycode == KEY_B:
		show_bones = not show_bones
		_update_poses()
	elif event.keycode == KEY_W:
		show_weapon = not show_weapon
		_update_weapon()
	elif event.keycode == KEY_ESCAPE:
		get_tree().quit()
	else:
		return
	get_viewport().set_input_as_handled()
