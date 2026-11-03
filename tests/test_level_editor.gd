@tool
extends RefCounted
## Runs INSIDE a real editor instance via -- --test-level-editor; no desktop automation.

const BUILDER = preload("res://addons/cinderkeep_level_tools/level_builder.gd")
const FACTORY = preload("res://addons/cinderkeep_level_tools/level_factory.gd")
const PLACEMENT = preload("res://scripts/levels/level_placement.gd")
var checks: int = 0
var failures: int = 0
var plugin: EditorPlugin

func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func settle(frames: int = 8) -> void:
	for frame in range(frames):
		await plugin.get_tree().process_frame

func button(label: String) -> Button:
	for child in plugin.dock.find_children("*", "Button", true, false):
		if child is Button and child.text == label:
			return child
	return null

func run(editor_plugin: EditorPlugin) -> void:
	plugin = editor_plugin
	DirAccess.make_dir_recursive_absolute("res://builds/validation/level-authoring")
	# Plugins enter before the editor restores its initial scene/layout.
	await plugin.get_tree().create_timer(3.0).timeout
	while EditorInterface.get_resource_filesystem().is_scanning():
		await settle(2)
	await settle(20)
	await close_test_tabs()
	check(Engine.is_editor_hint(), "editor integration suite runs in a real Godot editor")
	check(not ProjectSettings.has_setting("autoload/CyclopsAutoload") and plugin.get_tree().root.has_node("CyclopsAutoload"), "Cyclops drawing service is editor-owned, never a project autoload")
	var weak: WeakRef
	var vertex: RefCounted
	var volume := ConvexVolume.new()
	volume.init_block(AABB(Vector3.ZERO, Vector3.ONE))
	weak = weakref(volume)
	vertex = volume.vertices[0]
	check(vertex.mesh == volume, "weak topology backlink resolves its live owning volume")
	volume = null
	check(weak.get_ref() == null, "Cyclops temporary topology releases without RefCounted cycles")
	vertex = null
	var token := "_editor_test_%d" % Time.get_ticks_usec()
	var source_path := "res://scenes/authoring/%s.tscn" % token
	var output_path := "res://scenes/levels/generated/%s.tscn" % token
	button("New Level…").pressed.emit()
	check(plugin.save_dialog.visible, "actual New Level dock button opens scene-save dialog")
	plugin.save_dialog.hide()
	plugin.save_dialog.file_selected.emit(source_path)
	await settle(20)
	var source := EditorInterface.get_edited_scene_root() as Node3D
	check(source != null and source.scene_file_path == source_path, "New Level saves and opens a separate editable source scene")
	if source == null or source.scene_file_path != source_path:
		plugin.get_tree().quit(1)
		return
	check(source.runtime_path == output_path and source.has_node("Architecture") and source.has_node("Placements"), "template has explicit separate runtime path and expected containers")
	var placements := source.get_node("Placements")
	var initial := placements.get_child_count()
	var all_place := true
	var all_undo := true
	var all_redo := true
	for kind in range(PLACEMENT.LABELS.size()):
		button("+ " + PLACEMENT.LABELS[kind]).pressed.emit()
		await settle(2)
		var marker = placements.get_children().back()
		all_place = all_place and placements.get_child_count() == initial + 1 and marker.kind == kind and marker.owner == source and marker.preview != null
		var manager := plugin.get_undo_redo()
		var history: UndoRedo = manager.get_history_undo_redo(manager.get_object_history_id(source))
		history.undo()
		all_undo = all_undo and placements.get_child_count() == initial
		history.redo()
		all_redo = all_redo and placements.get_child_count() == initial + 1 and placements.get_children().back() == marker
		history.undo()
	check(all_place, "all thirteen palette buttons create correctly owned visible placements")
	check(all_undo and all_redo, "actual editor history undoes/redoes every placement without duplicates")
	button("+ Health").pressed.emit()
	await settle()
	var health = placements.get_children().back()
	health.position = Vector3(-2, 0, 1)
	health.amount = 33
	var duplicate := health.duplicate() as Node3D
	placements.add_child(duplicate)
	duplicate.owner = source
	await settle()
	check(duplicate.get_child_count() == 1, "duplicating a preview marker does not duplicate its transient visual")
	duplicate.free()
	check(plugin.get_tree().get_nodes_in_group("enemies").is_empty() and plugin.get_tree().get_nodes_in_group("player").is_empty(), "editing previews creates no gameplay AI/player")
	check(health.preview.find_children("*", "CollisionObject3D", true, false).is_empty(), "placement previews add no gameplay collision")
	EditorInterface.save_scene()
	var saved := load(source_path) as PackedScene
	var reopened := saved.instantiate()
	var restored = reopened.get_node("Placements").get_children().back()
	check(restored.amount == 33 and restored.position == Vector3(-2, 0, 1) and restored.get_child_count() == 0, "save/reopen retains placement properties without serialized preview children")
	reopened.free()
	button("Build Level + Navigation").pressed.emit()
	var result: Dictionary = await plugin.build_finished
	check(result.ok and FileAccess.file_exists(output_path), "actual Build button converts template and saves per-level navigation")
	check(not BUILDER.is_stale(source), "successful output fingerprints its saved authoring source")
	check(placements.get_child_count() == initial + 1 and source.get_node("Architecture").get_child_count() == 5, "build preserves all source blocks and hand placements")
	button("Check Level").pressed.emit()
	result = await plugin.build_finished
	check(result.ok, "actual Check button validates collision and navigation")
	var floor_node: Node3D = source.get_node("Architecture").get_child(0)
	floor_node.position.x += 0.1
	EditorInterface.save_scene()
	check(BUILDER.is_stale(source), "source geometry edits make old runtime output stale")
	button("Check Level").pressed.emit()
	result = await plugin.build_finished
	check(result.ok and "stale" in plugin.report.text, "Check reports a valid but stale runtime build")
	var start = placements.get_node("PlayerStart")
	var original_start: Vector3 = start.position
	start.position = Vector3(5.2, 0, 0)
	result = await BUILDER.build(source, plugin.get_tree(), false)
	check(not result.ok and "overlaps world collision" in str(result.errors), "obstructed player start causes a focused spatial build error")
	start.position = original_start
	var key = placements.get_node("EmberKey")
	placements.remove_child(key)
	result = await BUILDER.build(source, plugin.get_tree(), false)
	check(not result.ok and "Exactly one Ember Key" in str(result.errors), "missing key blocks build with an actionable diagnostic")
	placements.add_child(key)
	key.owner = source
	var original_key: Vector3 = key.position
	key.position = Vector3(30, 0, 0)
	var island := FACTORY.block(source, "DisconnectedFloor", Vector3(30, -0.25, 0), Vector3(5, 0.5, 5), true)
	result = await BUILDER.build(source, plugin.get_tree(), false)
	check(not result.ok and "no navigation connection" in str(result.errors), "disconnected key island fails objective connectivity validation")
	island.free()
	key.position = original_key
	source.runtime_path = "res://scenes/levels/generated/mapping_example.tscn"
	var example_hash := FileAccess.get_sha256(source.runtime_path)
	result = await BUILDER.build(source, plugin.get_tree(), true)
	check(not result.ok and FileAccess.get_sha256(source.runtime_path) == example_hash, "build refuses to overwrite an output owned by another source")
	source.runtime_path = output_path
	EditorInterface.save_scene()
	button("Playtest Level").pressed.emit()
	result = await plugin.build_finished
	await settle(80)
	check(result.ok and EditorInterface.is_playing_scene(), "actual Playtest button builds and launches a custom normal-session entry")
	if EditorInterface.is_playing_scene():
		EditorInterface.stop_playing_scene()
	await settle(20)
	check(not EditorInterface.is_playing_scene(), "editor can stop playtest cleanly")
	var wrapper := load(plugin.PLAYTEST_PATH) as PackedScene
	if wrapper == null:
		plugin.get_tree().quit(1)
		return
	var session = wrapper.instantiate()
	check(session.auto_start and session.default_level != null, "playtest wrapper selects normal session with authored default level and auto-start")
	session.free()
	# Open the shipped example for handoff, never save test edits into it.
	EditorInterface.open_scene_from_path("res://scenes/authoring/mapping_example.tscn")
	await settle(20)
	await close_test_tabs()
	plugin.editor_dock.make_visible()
	await settle()
	check(button("Build Level + Navigation").is_visible_in_tree() and plugin.get_tree().root.get_visible_rect().encloses(button("Playtest Level").get_global_rect()), "build/check/play actions remain visible in the editor dock")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		plugin.get_tree().root.get_texture().get_image().save_png("res://builds/validation/level-authoring/editor-workflow.png")
	for path in [source_path, output_path]:
		DirAccess.remove_absolute(path) # Only uniquely named files created by this suite.
	print("RESULT: %d level-editor checks, %d failures" % [checks, failures])
	plugin.get_tree().quit(0 if failures == 0 else 1)

func close_test_tabs() -> void:
	for path in EditorInterface.get_open_scenes():
		if path.begins_with("res://scenes/authoring/_editor_test"):
			EditorInterface.open_scene_from_path(path)
			await settle(2)
			EditorInterface.save_scene()
			EditorInterface.close_scene()
	EditorInterface.open_scene_from_path("res://scenes/authoring/mapping_example.tscn")
	await settle(3)
