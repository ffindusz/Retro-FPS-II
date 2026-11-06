extends SceneTree
## Offline build/export policy tests. No real exporter is started on failing preflight.

const FACTORY = preload("res://addons/cinderkeep_level_tools/level_factory.gd")
const BUILDER = preload("res://addons/cinderkeep_level_tools/level_builder.gd")
const PROVENANCE = preload("res://addons/cinderkeep_level_tools/build_provenance.gd")
const GUARD = preload("res://addons/cinderkeep_level_tools/export_preflight.gd")
const POSE = preload("res://addons/cinderkeep_level_tools/placement_pose.gd")
const PLACEMENT = preload("res://scripts/levels/level_placement.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func save_source(source: Node3D, path: String) -> void:
	BUILDER.own_recursive(source, source)
	var packed := PackedScene.new()
	packed.pack(source)
	ResourceSaver.save(packed, path)
	source.scene_file_path = path

func run_tests() -> void:
	var initial := GUARD.check()
	check(initial.ok, "shipped public map has current versioned build provenance")
	var floor_pose := POSE.pose(PLACEMENT.Kind.WARDEN, Vector3(1.13, 0.15, 2.26), Vector3.UP, 90, true, 0.5, 0)
	check(floor_pose.ok and floor_pose.transform.origin.is_equal_approx(Vector3(1, 0.15, 2.5)), "floor snapping changes X/Z without burying raised-floor anchors")
	check((-floor_pose.transform.basis.z).is_equal_approx(Vector3.LEFT), "facing controls use the documented local -Z direction")
	var unsnapped := POSE.pose(PLACEMENT.Kind.HEALTH, Vector3(1.13, 0, 2.26), Vector3.UP, 0, false, 0.5, 0.25)
	check(unsnapped.transform.origin.is_equal_approx(Vector3(1.13, 0.25, 2.26)), "disabled snap and explicit height offset are respected")
	var lantern := POSE.pose(PLACEMENT.Kind.LANTERN, Vector3(5, 2.31, 0.23), Vector3.LEFT, 0, true, 0.5, 0)
	check(lantern.ok and (-lantern.transform.basis.z).is_equal_approx(Vector3.LEFT) and absf(lantern.transform.origin.x - 4.985) < 0.001, "lantern arm points away from wall with a small surface offset")
	var torch := POSE.pose(PLACEMENT.Kind.TORCH, Vector3(-5, 2, 0), Vector3.RIGHT, 0, false, 0.5, 0)
	check(torch.ok and torch.transform.basis.z.is_equal_approx(Vector3.RIGHT), "existing torch's +Z mount convention is preserved")
	check(not POSE.pose(PLACEMENT.Kind.WARDEN, Vector3.ZERO, Vector3.RIGHT, 0, true, 0.5, 0).ok, "floor objects reject walls")
	check(not POSE.pose(PLACEMENT.Kind.LANTERN, Vector3.ZERO, Vector3.UP, 0, true, 0.5, 0).ok, "wall fixtures reject floors")
	check(not POSE.pose(PLACEMENT.Kind.HEALTH, Vector3.ZERO, Vector3.DOWN, 0, true, 0.5, 0).ok, "ceiling hits cannot place floor objects")
	var zone := POSE.pose(PLACEMENT.Kind.AMBIENCE, Vector3.ZERO, Vector3.UP, 0, true, 0.5, 0)
	check(zone.transform.origin == Vector3(0, 2, 0), "default ambience volume is centred above its clicked floor anchor")
	var token := "editor_polish_test_%d" % Time.get_ticks_usec()
	var path := "res://scenes/authoring/%s.tscn" % token
	var output := "res://scenes/levels/generated/%s.tscn" % token
	var external := "res://scenes/authoring/%s_geometry.tres" % token
	var target := "res://builds/validation/editor-polish/%s.pck" % token
	DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	var source := FACTORY.create_level()
	source.runtime_path = output
	var data = source.get_node("Architecture/Floor").mesh_vector_data
	ResourceSaver.save(data, external, ResourceSaver.FLAG_CHANGE_PATH)
	data.take_over_path(external)
	save_source(source, path)
	root.add_child(source)
	var missing := GUARD.check()
	check(not missing.ok and missing.issues.any(func(issue): return issue.code == "missing_build" and issue.source_path == path), "new public source blocks checked export until built")
	var exporter := preload("res://addons/cinderkeep_level_tools/checked_export.gd").new()
	root.add_child(exporter)
	var rejected := exporter.start_export(target)
	check(not rejected.ok and exporter.process_id == -1 and not FileAccess.file_exists(target), "failed preflight never starts the exporter or creates its destination")
	var result: Dictionary = await BUILDER.build(source, self)
	check(result.ok and GUARD.check().ok, "building public source clears its missing-build export failure")
	var catalog: Array[Dictionary] = preload("res://scripts/levels/built_level_catalog.gd").entries()
	check(catalog.any(func(entry): return entry.path == output), "newly built public map is discovered without code or catalog-file edits")
	root.remove_child(source)
	var session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session.show_level_selection()
	var selected: Button
	for child in session.ui.buttons.get_children():
		if child.tooltip_text == output:
			selected = child
	selected.pressed.emit()
	session.run.player.set_physics_process(false)
	check(session.run.scene_file_path == output and session.run.level_title == "New Cinderkeep Level", "actual map button loads a newly built map, not a hardcoded example")
	session._on_command("Restart")
	session.run.player.set_physics_process(false)
	check(session.run.scene_file_path == output, "newly discovered map remains selected through restart")
	session.show_menu()
	session.queue_free()
	await process_frame
	root.add_child(source)
	var before := PROVENANCE.fingerprint(path)
	var original_text := FileAccess.get_file_as_string(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(original_text.replace("\n", "\r\n"))
	file.close()
	check(PROVENANCE.fingerprint(path) == before and not BUILDER.is_stale(source), "Windows line-ending changes do not create false stale builds")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(original_text)
	file.close()
	var external_text := FileAccess.get_file_as_string(external)
	file = FileAccess.open(external, FileAccess.WRITE)
	file.store_string(external_text + "\n; external geometry edit\n")
	file.close()
	check(PROVENANCE.fingerprint(path) != before and BUILDER.is_stale(source), "external source-resource edits invalidate the saved build")
	var stale := GUARD.check()
	check(not stale.ok and stale.issues.any(func(issue): return issue.code == "stale_build" and issue.source_path == path), "checked export identifies the stale map after an external-resource edit")
	rejected = exporter.start_export(target)
	check(not rejected.ok and exporter.process_id == -1 and not FileAccess.file_exists(target), "stale map cannot launch checked export or overwrite/create output")
	result = await BUILDER.build(source, self)
	check(result.ok and not BUILDER.is_stale(source) and GUARD.check().ok, "rebuild refreshes external-resource and recipe provenance")
	file = FileAccess.open(target, FileAccess.WRITE)
	file.store_string("existing artifact sentinel")
	file.close()
	var sentinel := FileAccess.get_sha256(target)
	rejected = exporter.start_export(target)
	check(not rejected.ok and exporter.process_id == -1 and FileAccess.get_sha256(target) == sentinel, "checked export refuses an existing output byte-for-byte")
	DirAccess.remove_absolute(path)
	var orphan := GUARD.check()
	check(not orphan.ok and orphan.issues.any(func(issue): return issue.code == "orphaned_build"), "orphaned public runtime maps block checked export")
	source.queue_free()
	exporter.queue_free()
	for owned_path in [output, external, target]:
		DirAccess.remove_absolute(owned_path)
	await process_frame
	check(GUARD.check().ok, "temporary policy fixtures leave the real public map exportable")
	print("RESULT: %d editor-polish policy checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
