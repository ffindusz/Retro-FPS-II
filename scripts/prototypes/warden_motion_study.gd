extends Node3D
## Standalone visual sandbox. Intentionally has no enemy/player scripts or physics.

const MOTION = preload("res://scripts/prototypes/warden_motion.gd")
const WARDEN = preload("res://scenes/models/warden.tscn")
var baseline: Node3D
var candidate: Node3D
var bounds: AABB
var clip_index: int = 0
var clip_time: float = 0.0
var automatic: bool = true
var paused: bool = false
var phase_label: Label
var mode_label: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_stage()
	_build_ui()
	_update_poses()

func _build_stage() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("131c26")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c4d0dd")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -25, 0)
	light.light_energy = 1.1
	light.shadow_enabled = true
	add_child(light)
	PrimitiveArt.box(self, Vector3(0, -0.05, 0), Vector3(12, 0.1, 10), Color("293442"))
	for x in range(-5, 6):
		PrimitiveArt.box(self, Vector3(x, 0.001, 0), Vector3(0.012, 0.003, 8), Color("394957"))
	for z in range(-4, 5):
		PrimitiveArt.box(self, Vector3(0, 0.001, z), Vector3(10, 0.003, 0.012), Color("394957"))
	for index in range(2):
		var stand := Node3D.new()
		# Camera looks along +Z, so world +X appears on screen-left.
		stand.position.x = 1.5 if index == 0 else -1.5
		add_child(stand)
		var visual := WARDEN.instantiate() as Node3D
		stand.add_child(visual)
		if index == 0:
			baseline = visual
		else:
			candidate = visual
	bounds = MOTION.visual_bounds(candidate)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 2.25, -7.0)
	camera.fov = 47.0
	add_child(camera)
	camera.look_at(Vector3(0, 0.9, 0))
	camera.current = true

func _label(parent: Node, text: String, font_size: int = 18) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var top := VBoxContainer.new()
	top.position = Vector2(28, 18)
	canvas.add_child(top)
	_label(top, "WARDEN / whole-model motion study", 26)
	var warning := _label(top, "UNRIGGED - visual-only preview. No limb animation, AI or damage.", 18)
	warning.modulate = Color("f3ca85")
	phase_label = _label(top, "", 20)
	mode_label = _label(top, "", 17)
	var columns := HBoxContainer.new()
	columns.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	columns.offset_top = 168
	columns.offset_bottom = 198
	canvas.add_child(columns)
	for title in ["LEFT / 0.4.1 feedback approximation", "RIGHT / candidate timing + grounded bounds"]:
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
	_label(bottom, "0 Auto | 1 Idle | 2 Locomotion silhouette | 3 Attack | 4 Hit | 5 Death", 18)
	_label(bottom, "Space Pause/resume | R Replay current clip | Esc Quit", 18)
	_label(bottom, "Attack marker: 0.55s (visual reference only). Proper walking/weapon motion needs a rig.", 16)

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if paused:
		return
	clip_time += maxf(delta, 0.0)
	while clip_time >= MOTION.duration(MOTION.CLIPS[clip_index]):
		clip_time -= MOTION.duration(MOTION.CLIPS[clip_index])
		if automatic:
			clip_index = (clip_index + 1) % MOTION.CLIPS.size()
	_update_poses()

func select_clip(index: int, auto_sequence: bool = false) -> void:
	clip_index = clampi(index, 0, MOTION.CLIPS.size() - 1)
	clip_time = 0.0
	automatic = auto_sequence
	_update_poses()

func _update_poses() -> void:
	var clip: StringName = MOTION.CLIPS[clip_index]
	baseline.transform = MOTION.sample_pose(clip, clip_time, bounds, true)
	candidate.transform = MOTION.sample_pose(clip, clip_time, bounds)
	phase_label.text = "%s / %.2fs / %s" % [String(clip).capitalize(), clip_time, MOTION.phase(clip, clip_time)]
	mode_label.text = "%s | %s | Fixed camera, shared original model/materials" % ["PAUSED" if paused else "Playing", "Auto sequence" if automatic else "Single clip loop"]

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
	elif event.keycode == KEY_ESCAPE:
		get_tree().quit()
	else:
		return
	get_viewport().set_input_as_handled()
