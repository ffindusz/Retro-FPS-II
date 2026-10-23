extends "res://scripts/prototypes/warden_motion_study.gd"
## Actual local/Meshy pipeline comparison. No AI, damage, audio or live enemy.

const CLOCK = preload("res://scripts/prototypes/animation_ab_clock.gd")
const ACTOR = preload("res://scripts/prototypes/animation_ab_actor.gd")
const LOCAL = preload("res://assets/prototypes/warden-rig/warden_rig.glb")
const MESHY = preload("res://assets/prototypes/warden-meshy-ab/animations.glb")
var local_actor: Node3D
var meshy_actor: Node3D
var phase_matched: bool = false
var anchored: bool = true
var swapped: bool = false
var show_bones: bool = false
var view_index: int = 0
var sampled_times := Vector2.ZERO
var source_labels: Array[Label] = []
var drift_label: Label
var provenance: Dictionary

func _ready() -> void:
	automatic = false
	super._ready()

func _build_stage() -> void:
	super._build_stage()
	provenance = JSON.parse_string(FileAccess.get_file_as_string("res://assets/prototypes/warden-meshy-ab/provenance.json"))
	var source_mesh: MeshInstance3D = baseline.find_children("*", "MeshInstance3D", true, false)[0]
	var material := source_mesh.get_active_material(0)
	var left_stand := baseline.get_parent()
	var right_stand := candidate.get_parent()
	baseline.free()
	candidate.free()
	local_actor = ACTOR.new()
	left_stand.add_child(local_actor)
	local_actor.setup(LOCAL, ["Idle", "Walk", "Attack"], 0.0, material)
	meshy_actor = ACTOR.new()
	right_stand.add_child(meshy_actor)
	meshy_actor.setup(MESHY, provenance.clip_names, PI, material if provenance.use_original_material else null)
	baseline = local_actor
	candidate = meshy_actor

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var top := VBoxContainer.new()
	top.position = Vector2(28, 18)
	canvas.add_child(top)
	_label(top, "WARDEN / local A versus Meshy B", 26)
	var warning := _label(top, "Actual outputs / 14 credits. Different rigs + weights: pipeline A/B, not gameplay.", 18)
	warning.modulate = Color("f3ca85")
	phase_label = _label(top, "", 20)
	mode_label = _label(top, "", 17)
	drift_label = _label(top, "", 16)
	var columns := HBoxContainer.new()
	columns.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	columns.offset_top = 186
	columns.offset_bottom = 216
	canvas.add_child(columns)
	for index in range(2):
		var label := _label(columns, "", 18)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		source_labels.append(label)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 28
	bottom.offset_top = -96
	bottom.offset_right = -20
	bottom.offset_bottom = -14
	canvas.add_child(bottom)
	_label(bottom, "1 Idle | 2 Walk | 3 Attack | 0 Auto | Space Pause | R Replay | Esc Quit", 18)
	_label(bottom, "T Native/phase-match timing | G Anchored/raw XZ | V Views | B Bones | X Swap sides", 18)
	_label(bottom, "Local windup reference = 0.55s. Meshy contact is NOT aligned or assumed. No damage/events.", 16)

func period() -> float:
	return maxf(local_actor.durations[clip_index], meshy_actor.durations[clip_index])

func advance(delta: float) -> void:
	if paused:
		return
	clip_time += maxf(delta, 0.0)
	if automatic:
		while clip_time >= period():
			clip_time -= period()
			clip_index = (clip_index + 1) % 3
	_update_poses()

func select_clip(index: int, auto_sequence: bool = false) -> void:
	clip_index = clampi(index, 0, 2)
	clip_time = 0.0
	automatic = auto_sequence
	_update_poses()

func _update_poses() -> void:
	sampled_times = CLOCK.times(clip_time, local_actor.durations[clip_index], meshy_actor.durations[clip_index], phase_matched)
	local_actor.bone_lines.visible = show_bones
	meshy_actor.bone_lines.visible = show_bones
	local_actor.seek(clip_index, sampled_times.x, anchored)
	meshy_actor.seek(clip_index, sampled_times.y, anchored)
	phase_label.text = "%s | A %.2f / %.2fs | B %.2f / %.2fs" % [["Idle", "Walk", "Attack"][clip_index], sampled_times.x, local_actor.durations[clip_index], sampled_times.y, meshy_actor.durations[clip_index]]
	mode_label.text = "%s | %s | %s | %s view" % ["PAUSED" if paused else "Playing", "PHASE MATCHED / retimed" if phase_matched else "NATIVE SPEED / independent loops", "XZ cycle drift compensated" if anchored else "RAW ROOT MOTION", ["Front", "Side", "Back"][view_index]]
	var left_drift: Vector3 = local_actor.cycle_drifts[clip_index] * local_actor.normalization_scale
	var right_drift: Vector3 = meshy_actor.cycle_drifts[clip_index] * meshy_actor.normalization_scale
	drift_label.text = "Full-cycle XZ travel: A %.3fm / B %.3fm | Rest height 1.806m | %s" % [Vector2(left_drift.x, left_drift.z).length(), Vector2(right_drift.x, right_drift.z).length(), "Shared original PBR material" if provenance.use_original_material else "Native materials differ"]
	var titles := ["A / Local - %d bones" % local_actor.skeleton.get_bone_count(), "B / Meshy - %d bones" % meshy_actor.skeleton.get_bone_count()]
	source_labels[0].text = "LEFT / " + titles[1 if swapped else 0]
	source_labels[1].text = "RIGHT / " + titles[0 if swapped else 1]

func set_view(index: int) -> void:
	view_index = posmod(index, 3)
	var angle: float = [0.0, PI / 2.0, PI][view_index]
	local_actor.get_parent().rotation.y = angle
	meshy_actor.get_parent().rotation.y = angle
	_update_poses()

func swap_sides() -> void:
	swapped = not swapped
	local_actor.get_parent().position.x = -1.5 if swapped else 1.5
	meshy_actor.get_parent().position.x = 1.5 if swapped else -1.5
	_update_poses()

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
	elif event.keycode == KEY_T:
		phase_matched = not phase_matched
		clip_time = 0.0
		_update_poses()
	elif event.keycode == KEY_G:
		anchored = not anchored
		_update_poses()
	elif event.keycode == KEY_B:
		show_bones = not show_bones
		_update_poses()
	elif event.keycode == KEY_V:
		set_view(view_index + 1)
	elif event.keycode == KEY_X:
		swap_sides()
	elif event.keycode == KEY_ESCAPE:
		get_tree().quit()
	else:
		return
	get_viewport().set_input_as_handled()
