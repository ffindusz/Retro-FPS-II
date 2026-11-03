@tool
extends EditorPlugin

signal build_finished(result: Dictionary)

const AUTHORING = preload("res://addons/cinderkeep_level_tools/authoring_level.gd")
const FACTORY = preload("res://addons/cinderkeep_level_tools/level_factory.gd")
const BUILDER = preload("res://addons/cinderkeep_level_tools/level_builder.gd")
const PLACEMENT = preload("res://scripts/levels/level_placement.gd")
const PLAYTEST_PATH := "res://scenes/authoring/_playtest.tscn"
var dock: VBoxContainer
var editor_dock: EditorDock
var report: RichTextLabel
var save_dialog: EditorFileDialog
var busy: bool = false

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "Cinderkeep"
	var title := Label.new()
	title.text = "CINDERKEEP LEVEL TOOLS"
	dock.add_child(title)
	_button("New Level…", _new_level)
	_button("Open Mapping Example", func(): EditorInterface.open_scene_from_path("res://scenes/authoring/mapping_example.tscn"))
	_button("Build Level + Navigation", _build_level)
	_button("Check Level", _check)
	_button("Playtest Level", _playtest)
	report = RichTextLabel.new()
	report.custom_minimum_size = Vector2(220, 70)
	dock.add_child(report)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 90
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dock.add_child(scroll)
	var palette := VBoxContainer.new()
	palette.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(palette)
	var hint := Label.new()
	hint.text = "Place at the viewport centre floor.\nMove/rotate with Godot's gizmos."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	palette.add_child(hint)
	for kind in range(PLACEMENT.LABELS.size()):
		_button("+ " + PLACEMENT.LABELS[kind], _place.bind(kind), palette)
	editor_dock = EditorDock.new()
	editor_dock.title = "Cinderkeep"
	editor_dock.layout_key = "CinderkeepLevelTools"
	editor_dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_BL
	editor_dock.add_child(dock)
	add_dock(editor_dock)
	save_dialog = EditorFileDialog.new()
	save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	save_dialog.filters = PackedStringArray(["*.tscn ; Godot scene"])
	save_dialog.file_selected.connect(_create_level)
	EditorInterface.get_base_control().add_child(save_dialog)
	_show(["Open an authoring scene or choose New Level. Architecture is edited with Cyclops; gameplay objects go in Placements."])
	if "--test-level-editor" in OS.get_cmdline_user_args():
		_run_editor_tests.call_deferred()

func _run_editor_tests() -> void:
	await load("res://tests/test_level_editor.gd").new().run(self)

func _exit_tree() -> void:
	remove_dock(editor_dock)
	editor_dock.queue_free()
	save_dialog.queue_free()

func _button(text: String, action: Callable, parent: Node = null) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	(parent if parent != null else dock).add_child(button)

func _show(lines: Array) -> void:
	report.text = "\n".join(PackedStringArray(lines))

func _source() -> Node3D:
	var root := EditorInterface.get_edited_scene_root()
	if root == null or root.get_script() != AUTHORING:
		_show(["Open a Cinderkeep authoring scene, not its generated runtime output."])
		return null
	return root

func _new_level() -> void:
	save_dialog.current_path = "res://scenes/authoring/new_level.tscn"
	save_dialog.popup_centered_ratio(0.65)

func _create_level(path: String) -> void:
	if not path.begins_with("res://scenes/authoring/") or not path.get_file().get_basename().is_valid_identifier():
		_show(["Choose a simple filename under scenes/authoring/ (letters, digits, underscores)."])
		return
	if FileAccess.file_exists(path):
		_show(["Existing scene left untouched. Choose a new filename."])
		return
	var source := FACTORY.create_level()
	source.runtime_path = BUILDER.OUTPUT_ROOT + path.get_file()
	var packed := PackedScene.new()
	packed.pack(source)
	source.free()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var error := ResourceSaver.save(packed, path)
	if error != OK:
		_show(["Could not save: " + error_string(error)])
		return
	EditorInterface.get_resource_filesystem().update_file(path)
	EditorInterface.open_scene_from_path(path)
	_show(["Created starter room. Edit Architecture with Cyclops, then Build Level."])

func _place(kind: int) -> void:
	var source := _source()
	if source == null or busy:
		return
	var point := Vector3.ZERO
	var floor_found := false
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	var area := camera.get_viewport().get_visible_rect().size / 2.0
	var origin := camera.project_ray_origin(area)
	var end := origin + camera.project_ray_normal(area) * 1000.0
	var hit := source.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, end, 1))
	if not hit.is_empty() and hit.normal.y > 0.5:
		point = hit.position.snapped(Vector3(0.5, 0.05, 0.5))
		floor_found = true
	var marker := Node3D.new()
	marker.set_script(PLACEMENT)
	marker.name = PLACEMENT.LABELS[kind].replace(" ", "")
	marker.kind = kind
	var lift := {PLACEMENT.Kind.AMBIENCE: 1.5, PLACEMENT.Kind.LANTERN: 2.8}
	marker.position = point + Vector3.UP * lift.get(kind, 0.0)
	var parent := source.get_node("Placements")
	var undo := get_undo_redo()
	undo.create_action("Place " + PLACEMENT.LABELS[kind], UndoRedo.MERGE_DISABLE, source)
	undo.add_do_method(parent, "add_child", marker, true)
	undo.add_do_property(marker, "owner", source)
	undo.add_undo_method(parent, "remove_child", marker)
	undo.add_do_reference(marker)
	undo.commit_action()
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(marker)
	EditorInterface.edit_node(marker)
	_show(["Placed " + PLACEMENT.LABELS[kind] + ". Move/rotate using Godot; Ctrl+Z undoes placement.", "" if floor_found else "No floor under viewport centre: placed at the level origin. Move it before building."])

func _run_build(save_output: bool) -> Dictionary:
	var source := _source()
	if source == null or busy:
		return {"ok": false, "errors": []}
	if EditorInterface.save_scene() != OK:
		_show(["Save the authoring scene first."])
		return {"ok": false, "errors": []}
	busy = true
	_show(["Converting architecture, baking navigation and checking placements…"])
	var result: Dictionary = await BUILDER.build(source, get_tree(), save_output)
	busy = false
	if result.ok:
		var lines: Array = ["Valid: %d blocks, %d navigation polygons." % [result.blocks, result.polygons]]
		if save_output:
			lines.append("Built " + result.path)
			EditorInterface.get_resource_filesystem().update_file(result.path)
		elif BUILDER.is_stale(source):
			lines.append("Runtime output is missing/stale. Build before export.")
		lines.append("Connectivity checks assist—not replace—a complete playtest.")
		_show(lines)
	else:
		_show(result.errors)
		print("Cinderkeep validation: ", result.errors)
	build_finished.emit(result)
	return result

func _build_level() -> void:
	await _run_build(true)

func _check() -> void:
	await _run_build(false)

func _playtest() -> void:
	var result := await _run_build(true)
	if not result.ok:
		return
	var session = load("res://scenes/main.tscn").instantiate()
	session.default_level = result.scene
	session.auto_start = true
	var wrapper := PackedScene.new()
	wrapper.pack(session)
	session.free()
	var error := ResourceSaver.save(wrapper, PLAYTEST_PATH)
	if error != OK:
		_show(["Could not save playtest entry: " + error_string(error)])
		return
	EditorInterface.play_custom_scene(PLAYTEST_PATH)
