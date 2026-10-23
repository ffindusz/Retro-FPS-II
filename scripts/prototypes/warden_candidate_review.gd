extends "res://scripts/prototypes/warden_motion_study.gd"
## Three actual untextured candidates under common neutral presentation.

var candidates: Array[Node3D] = []
var report: Dictionary
var view_index: int = 0
var focus_index: int = -1

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_stage()
	_build_ui()
	set_view(0)
	set_process(false)

func _build_stage() -> void:
	super._build_stage()
	baseline.get_parent().free()
	candidate.get_parent().free()
	report = JSON.parse_string(FileAccess.get_file_as_string("res://assets/prototypes/warden-pilot/candidates/provenance.json"))
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("a0adb9")
	material.roughness = 0.85
	for index in range(3):
		var stand := Node3D.new()
		stand.position.x = 2.8 - index * 2.8
		add_child(stand)
		var normalizer := Node3D.new()
		stand.add_child(normalizer)
		var visual = load("res://assets/prototypes/warden-pilot/candidates/%s.glb" % report.candidates[index].id).instantiate()
		normalizer.add_child(visual)
		var box := AABB()
		var first := true
		for node in visual.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			var local: Transform3D = visual.global_transform.affine_inverse() * mesh.global_transform
			var bounds: AABB = local * mesh.get_aabb()
			box = bounds if first else box.merge(bounds)
			first = false
			for surface in range(mesh.mesh.get_surface_count()):
				mesh.set_surface_override_material(surface, material)
		normalizer.rotation.y = PI
		normalizer.scale = Vector3.ONE * (1.8063 / box.size.y)
		normalizer.position = -(normalizer.basis * Vector3(box.get_center().x, box.position.y, box.get_center().z))
		candidates.append(stand)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 155, 0)
	fill.light_energy = 0.85
	fill.shadow_enabled = false
	add_child(fill)
	var camera: Camera3D = get_viewport().get_camera_3d()
	camera.position = Vector3(0, 1.9, -8.5)
	camera.fov = 35.0
	camera.look_at(Vector3(0, 0.9, 0))

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var top := VBoxContainer.new()
	top.position = Vector2(28, 18)
	canvas.add_child(top)
	_label(top, "WARDEN / body candidate review", 26)
	var warning := _label(top, "Actual untextured Meshy 7.1 previews / A-pose requested: inspect actual pose", 18)
	warning.modulate = Color("f3ca85")
	phase_label = _label(top, "", 20)
	mode_label = _label(top, "60-credit previews; up to 30 credits authorized for ONE selected body", 17)
	var columns := HBoxContainer.new()
	columns.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	columns.offset_top = 168
	columns.offset_bottom = 198
	canvas.add_child(columns)
	for index in range(3):
		var item: Dictionary = report.candidates[index]
		var label := _label(columns, "%d / %s / %d tris" % [index + 1, item.label, item.inventory.triangles], 16)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 28
	bottom.offset_top = -84
	bottom.offset_right = -20
	bottom.offset_bottom = -14
	canvas.add_child(bottom)
	_label(bottom, "0 All | 1 / 2 / 3 Focus candidate | V Front/side/back | Esc Quit", 18)
	_label(bottom, "Review empty hands, limb gaps, mask/armor silhouette, knees/boots and unwanted props.", 16)
	_label(bottom, "Untextured candidate meshes only, not the finished pilot or gameplay. Selection does not spend credits.", 16)

func set_view(index: int) -> void:
	view_index = posmod(index, 3)
	for stand in candidates:
		stand.rotation.y = [0.0, PI / 2.0, PI][view_index]
	phase_label.text = "%s / %s view" % ["All candidates" if focus_index < 0 else "Focus %d: %s" % [focus_index + 1, report.candidates[focus_index].label], ["Front", "Side", "Back"][view_index]]

func focus_candidate(index: int) -> void:
	focus_index = clampi(index, -1, 2)
	for item in range(candidates.size()):
		candidates[item].visible = focus_index < 0 or item == focus_index
	var camera: Camera3D = get_viewport().get_camera_3d()
	if focus_index < 0:
		camera.position = Vector3(0, 1.9, -8.5)
		camera.fov = 35.0
		camera.look_at(Vector3(0, 0.9, 0))
	else:
		var x := candidates[focus_index].position.x
		camera.position = Vector3(x, 2.0, -5.0)
		camera.fov = 38.0
		camera.look_at(Vector3(x, 1.1, 0))
	set_view(view_index)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_0:
		focus_candidate(-1)
	elif event.keycode >= KEY_1 and event.keycode <= KEY_3:
		focus_candidate(event.keycode - KEY_1)
	elif event.keycode == KEY_V:
		set_view(view_index + 1)
	elif event.keycode == KEY_ESCAPE:
		get_tree().quit()
	else:
		return
	get_viewport().set_input_as_handled()
