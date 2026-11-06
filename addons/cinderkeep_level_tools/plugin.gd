@tool
extends EditorPlugin

signal build_finished(result: Dictionary)
signal export_finished(result: Dictionary)

const AUTHORING = preload("res://addons/cinderkeep_level_tools/authoring_level.gd")
const FACTORY = preload("res://addons/cinderkeep_level_tools/level_factory.gd")
const BUILDER = preload("res://addons/cinderkeep_level_tools/level_builder.gd")
const PLACEMENT = preload("res://scripts/levels/level_placement.gd")
const PLAYTEST_PATH := "res://scenes/authoring/_playtest.tscn"
const POSE = preload("res://addons/cinderkeep_level_tools/placement_pose.gd")
const PREFLIGHT = preload("res://addons/cinderkeep_level_tools/export_preflight.gd")
var dock: VBoxContainer
var editor_dock: EditorDock
var report: RichTextLabel
var save_dialog: EditorFileDialog
var busy: bool = false
var issue_list: ItemList
var issue_rows: Array = []
var source_status: Label
var placement_status: Label
var snap_toggle: CheckButton
var grid_size: SpinBox
var facing: SpinBox
var height_offset: SpinBox
var armed_kind: int = -1
var ghost: Node3D
var last_pose: Dictionary = {}
var last_camera: Camera3D
var last_pointer: Vector2
var palette_buttons: Array[Button] = []
var export_dialog: EditorFileDialog
var exporter: Node
var export_warning: EditorExportPlugin

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "Cinderkeep"
	var title := Label.new()
	title.text = "CINDERKEEP LEVEL TOOLS"
	dock.add_child(title)
	var create_row := _row(dock)
	_button("New Level…", _new_level, create_row)
	_button("Open Mapping Example", func(): EditorInterface.open_scene_from_path("res://scenes/authoring/mapping_example.tscn"), create_row)
	var navigate_row := _row(dock)
	_button("Open Source / Level Root", _open_source, navigate_row)
	_button("Open Built Scene", _open_built, navigate_row)
	var build_row := _row(dock)
	_button("Build Level + Navigation", _build_level, build_row)
	_button("Check Level", _check, build_row)
	var run_row := _row(dock)
	_button("Playtest Level", _playtest, run_row)
	_button("Checked Export PCK…", _choose_export, run_row)
	source_status = Label.new()
	source_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(source_status)
	report = RichTextLabel.new()
	report.custom_minimum_size = Vector2(220, 45)
	dock.add_child(report)
	issue_list = ItemList.new()
	issue_list.custom_minimum_size = Vector2(220, 80)
	issue_list.item_selected.connect(_select_issue)
	issue_list.hide()
	dock.add_child(issue_list)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 90
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dock.add_child(scroll)
	var palette := VBoxContainer.new()
	palette.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(palette)
	var hint := Label.new()
	hint.text = "Arm a kind, then click a floor/wall.\nR rotates; Esc / RMB cancels."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	palette.add_child(hint)
	placement_status = Label.new()
	placement_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	palette.add_child(placement_status)
	var kinds := GridContainer.new()
	kinds.columns = 2
	palette.add_child(kinds)
	for kind in range(PLACEMENT.LABELS.size()):
		_button("+ " + PLACEMENT.LABELS[kind], _place.bind(kind), kinds)
		var palette_button := kinds.get_children().back() as Button
		palette_button.toggle_mode = true
		palette_buttons.append(palette_button)
	snap_toggle = CheckButton.new()
	snap_toggle.text = "Grid snap"
	snap_toggle.button_pressed = true
	palette.add_child(snap_toggle)
	grid_size = _number(palette, "Grid (m)", 0.05, 4, 0.05, 0.5)
	facing = _number(palette, "Facing / wall offset (°)", 0, 360, 15, 0)
	height_offset = _number(palette, "Height offset (m)", -2, 5, 0.05, 0)
	for setting in [grid_size, facing, height_offset]:
		setting.value_changed.connect(func(_value): _refresh_placement_settings())
	snap_toggle.toggled.connect(func(_enabled): _refresh_placement_settings())
	_button("Place at View Centre", _place_at_centre, palette)
	_button("Cancel Placement", _cancel_placement, palette)
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
	export_dialog = EditorFileDialog.new()
	export_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	export_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	export_dialog.filters = PackedStringArray(["*.pck ; Checked game resource pack"])
	export_dialog.file_selected.connect(_checked_export_to)
	EditorInterface.get_base_control().add_child(export_dialog)
	exporter = preload("res://addons/cinderkeep_level_tools/checked_export.gd").new()
	add_child(exporter)
	exporter.finished.connect(_export_done)
	export_warning = preload("res://addons/cinderkeep_level_tools/export_warning.gd").new()
	add_export_plugin(export_warning)
	set_input_event_forwarding_always_enabled()
	scene_changed.connect(_scene_changed)
	_scene_changed.call_deferred(EditorInterface.get_edited_scene_root())
	_show(["Open an authoring scene or choose New Level. Architecture is edited with Cyclops; gameplay objects go in Placements."])
	if "--test-level-editor" in OS.get_cmdline_user_args():
		_run_editor_tests.call_deferred()

func _run_editor_tests() -> void:
	await load("res://tests/test_level_editor.gd").new().run(self)

func _exit_tree() -> void:
	_cancel_placement()
	remove_export_plugin(export_warning)
	remove_dock(editor_dock)
	editor_dock.queue_free()
	save_dialog.queue_free()
	export_dialog.queue_free()

func _button(text: String, action: Callable, parent: Node = null) -> void:
	var button := Button.new()
	button.text = text
	button.tooltip_text = text
	button.clip_text = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	(parent if parent != null else dock).add_child(button)

func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	parent.add_child(row)
	return row

func _show(lines: Array) -> void:
	report.text = "\n".join(PackedStringArray(lines))

func _number(parent: Node, title: String, minimum: float, maximum: float, step: float, value: float) -> SpinBox:
	var label := Label.new()
	label.text = title
	parent.add_child(label)
	var control := SpinBox.new()
	control.min_value = minimum
	control.max_value = maximum
	control.step = step
	control.value = value
	parent.add_child(control)
	return control

func _scene_changed(_root: Node) -> void:
	_cancel_placement()
	issue_rows.clear()
	issue_list.clear()
	issue_list.hide()
	_refresh_status()
	_show(["Authoring source ready. Arm an object or build/check the level."] if _root != null and _root.get_script() == AUTHORING else ["Open an authoring source to edit. Built scenes are generated snapshots."])

func _refresh_status() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null or root.get_script() != AUTHORING:
		source_status.text = "Open an authoring source to edit/build."
	elif root.scene_file_path.is_empty():
		source_status.text = "Save this new level before building."
	else:
		source_status.text = "Saved build: " + ("missing / stale" if BUILDER.is_stale(root) else "current") + "\n" + str(root.runtime_path).get_file()
		source_status.tooltip_text = root.scene_file_path + "\n" + root.runtime_path

func _show_result(result: Dictionary) -> void:
	issue_rows = result.get("issues", [])
	issue_list.clear()
	for issue in issue_rows:
		issue_list.add_item(issue.message)
		issue_list.set_item_tooltip(issue_list.item_count - 1, issue.message + "\n" + issue.get("source_path", "") + ":" + issue.get("node_path", "."))
	issue_list.visible = not issue_rows.is_empty()
	if not result.ok:
		_show(["Validation blocked: %d issue(s). Click a row to select its object." % result.errors.size()] if not issue_rows.is_empty() else result.errors)

func _select_issue(index: int) -> void:
	if index < 0 or index >= issue_rows.size():
		return
	var issue: Dictionary = issue_rows[index]
	var path := str(issue.get("source_path", ""))
	var root := EditorInterface.get_edited_scene_root()
	if root == null or root.scene_file_path != path:
		if not path.begins_with("res://scenes/authoring/") or not FileAccess.file_exists(path):
			_show(["Issue target is no longer available. Run Check Level again."])
			return
		EditorInterface.open_scene_from_path(path)
		await get_tree().process_frame
		await get_tree().process_frame
		root = EditorInterface.get_edited_scene_root()
	if root == null or root.scene_file_path != path or root.get_script() != AUTHORING:
		_show(["Source is not active. Open it and run Check Level again."])
		return
	var target := root.get_node_or_null(NodePath(str(issue.get("node_path", "."))))
	if target == null or (target != root and not root.is_ancestor_of(target)) or (issue.get("node_id", 0) != 0 and target.get_instance_id() != issue.node_id):
		_show(["Issue target was removed or renamed. Run Check Level again."])
		return
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(target)
	EditorInterface.edit_node(target)

func _open_source() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root != null and root.get_script() == AUTHORING:
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(root)
		EditorInterface.edit_node(root)
	elif root != null and root.get("authoring_source") != null and str(root.authoring_source).begins_with("res://scenes/authoring/"):
		EditorInterface.open_scene_from_path(root.authoring_source)
	else:
		_show(["Open an authoring source or its built scene first."])

func _open_built() -> void:
	var source := _source()
	if source != null and FileAccess.file_exists(source.runtime_path):
		EditorInterface.open_scene_from_path(source.runtime_path)
		_show(["Generated snapshot: edit the authoring source, not this built scene."])
	else:
		_show(["Build the source level before opening its runtime snapshot."])

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
	_cancel_placement()
	armed_kind = kind
	palette_buttons[kind].button_pressed = true
	placement_status.text = "Armed: " + PLACEMENT.LABELS[kind] + ". Click source architecture."
	# Deactivate Cyclops block editing while the placement mode owns LMB.
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(source.get_node("Placements"))

func _cancel_placement() -> void:
	armed_kind = -1
	last_pose = {}
	last_camera = null
	for button in palette_buttons:
		button.set_pressed_no_signal(false)
	if is_instance_valid(ghost):
		ghost.get_parent().remove_child(ghost)
		ghost.queue_free()
	ghost = null
	if is_instance_valid(placement_status):
		placement_status.text = "Placement off. Choose an object to arm."

func _handles(object: Object) -> bool:
	var source := EditorInterface.get_edited_scene_root()
	return source != null and source.get_script() == AUTHORING and object is Node and (object == source or source.is_ancestor_of(object))

func _aim(camera: Camera3D, position: Vector2) -> Dictionary:
	var source := EditorInterface.get_edited_scene_root() as Node3D
	if armed_kind < 0 or source == null or source.get_script() != AUTHORING or not source.has_node("Architecture"):
		return {"ok": false, "message": "Open an authoring source first."}
	if not source.has_node("Placements") or not source.transform.is_equal_approx(Transform3D.IDENTITY) or not source.get_node("Placements").transform.is_equal_approx(Transform3D.IDENTITY):
		return {"ok": false, "message": "Keep the level root and Placements container at identity transform."}
	var origin := camera.project_ray_origin(position)
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(position) * 1000.0, 1))
	if hit.is_empty() or not source.get_node("Architecture").is_ancestor_of(hit.collider):
		return {"ok": false, "message": "Aim at this source's architecture. No placement on a miss."}
	var result: Dictionary = POSE.pose(armed_kind, source.to_local(hit.position), hit.normal, facing.value, snap_toggle.button_pressed, grid_size.value, height_offset.value)
	if result.ok and snap_toggle.button_pressed and not POSE.wall_kind(armed_kind):
		var anchor: Vector3 = result.transform.origin - Vector3.UP * (height_offset.value + (2.0 if armed_kind == PLACEMENT.Kind.AMBIENCE else 0.0))
		var floor_hit := camera.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(anchor + Vector3.UP * 0.35, anchor - Vector3.UP * 0.4, 1))
		if floor_hit.is_empty() or floor_hit.normal.y < 0.65 or not source.get_node("Architecture").is_ancestor_of(floor_hit.collider):
			return {"ok": false, "message": "Snapped point has no supported floor. Reduce/disable grid snap."}
		result.transform.origin.y += floor_hit.position.y - anchor.y
	return result

func _update_ghost(camera: Camera3D, pointer: Vector2) -> void:
	last_camera = camera
	last_pointer = pointer
	last_pose = _aim(camera, pointer)
	placement_status.text = PLACEMENT.LABELS[armed_kind] + ": " + last_pose.message if armed_kind >= 0 else "Placement off."
	if not last_pose.ok:
		if is_instance_valid(ghost):
			ghost.hide()
		return
	var source := EditorInterface.get_edited_scene_root()
	if not is_instance_valid(ghost):
		ghost = Node3D.new()
		ghost.set_script(PLACEMENT)
		ghost.name = "PlacementGhost"
		ghost.kind = armed_kind
		ghost.set_meta("cinderkeep_placement_ghost", true)
		source.add_child(ghost) # No owner; outside both saved-data containers.
		var hint := Label3D.new()
		hint.text = "PLACEMENT PREVIEW"
		hint.modulate = Color.CYAN
		hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		hint.position.y = 2.7
		ghost.add_child(hint)
	ghost.transform = last_pose.transform
	ghost.show()

func _refresh_placement_settings() -> void:
	if armed_kind >= 0 and is_instance_valid(last_camera):
		_update_ghost(last_camera, last_pointer)

func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	if armed_kind < 0 or busy:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_cancel_placement()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		if event.keycode == KEY_R and not event.ctrl_pressed and not event.alt_pressed and not event.echo:
			facing.value = fposmod(facing.value + 90.0, 360.0)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_cancel_placement()
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	if event is InputEventMouse and event.alt_pressed:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouseMotion:
		_update_ghost(camera, event.position)
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_update_ghost(camera, event.position)
			if last_pose.ok:
				_commit_placement(last_pose.transform)
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func _place_at_centre() -> void:
	if armed_kind < 0:
		_show(["Arm a placement kind first."])
		return
	var camera := last_camera if is_instance_valid(last_camera) else EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	_update_ghost(camera, camera.get_viewport().get_visible_rect().size / 2.0)
	if last_pose.ok:
		_commit_placement(last_pose.transform)

func _commit_placement(frame: Transform3D) -> void:
	var source := _source()
	if source == null or armed_kind < 0 or busy:
		return
	var marker := Node3D.new()
	marker.set_script(PLACEMENT)
	marker.name = PLACEMENT.LABELS[armed_kind].replace(" ", "")
	marker.kind = armed_kind
	marker.transform = frame
	var parent := source.get_node("Placements")
	var undo := get_undo_redo()
	undo.create_action("Place " + PLACEMENT.LABELS[armed_kind], UndoRedo.MERGE_DISABLE, source)
	undo.add_do_method(parent, "add_child", marker, true)
	undo.add_do_property(marker, "owner", source)
	undo.add_undo_method(parent, "remove_child", marker)
	undo.add_do_reference(marker)
	undo.commit_action()
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(marker)
	EditorInterface.edit_node(marker)
	placement_status.text = "Placed " + PLACEMENT.LABELS[armed_kind] + ". Click again, Ctrl+Z to undo, Esc to finish."

func _run_build(save_output: bool) -> Dictionary:
	var source := _source()
	if source == null or busy:
		return {"ok": false, "errors": []}
	_cancel_placement()
	if EditorInterface.save_scene() != OK:
		_show(["Save the authoring scene first."])
		return {"ok": false, "errors": []}
	busy = true
	_show(["Converting architecture, baking navigation and checking placements…"])
	var result: Dictionary = await BUILDER.build(source, get_tree(), save_output)
	busy = false
	if not is_instance_valid(source):
		result = {"ok": false, "errors": ["Source was closed during validation. Reopen it and check again."], "issues": []}
	_show_result(result)
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
		print("Cinderkeep validation: ", result.errors)
	_refresh_status()
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

func _choose_export() -> void:
	if busy:
		return
	_cancel_placement()
	export_dialog.current_path = ProjectSettings.globalize_path("res://builds/checked-exports/Cinderkeep-0.7.0.pck")
	export_dialog.popup_centered_ratio(0.65)

func _checked_export_to(path: String) -> Dictionary:
	if busy:
		return {"ok": false, "errors": ["Wait for the current build/export to finish."], "issues": []}
	_cancel_placement()
	var source := EditorInterface.get_edited_scene_root()
	if source != null and source.get_script() == AUTHORING and source.scene_file_path.is_empty():
		var unsaved := {"ok": false, "errors": ["Save this new source level before checked export."], "issues": []}
		_show_result(unsaved)
		return unsaved
	EditorInterface.save_all_scenes()
	var result: Dictionary = exporter.start_export(path)
	_show_result(result)
	if result.ok:
		busy = true
		_show(["Checked export running in a child process. Final output is published only on success; existing files are never replaced."])
	else:
		export_finished.emit(result)
	return result

func _export_done(result: Dictionary) -> void:
	busy = false
	_show_result(result)
	if result.ok:
		_show(["Checked PCK export complete: " + result.path])
	_refresh_status()
	export_finished.emit(result)
