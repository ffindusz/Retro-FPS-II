extends SceneTree
## Re-records resources/atmosphere_baseline.tres after a deliberate gameplay-world change.
## Run tools/bake_navigation.gd first so the snapshot includes the current navigation mesh.

func _initialize() -> void:
	call_deferred("record")

func record() -> void:
	var session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session.start_run()
	await process_frame
	var snapshot = WorldFingerprint.snapshot(session.run)
	var resource = Resource.new()
	resource.set_meta("snapshot", snapshot)
	var error = ResourceSaver.save(resource, "res://resources/atmosphere_baseline.tres")
	print("Enemies: ", snapshot.enemies.size(), "; colliders: ", snapshot.colliders.size(), "; navigation: ", snapshot.navigation, "; save result: ", error)
	session.queue_free()
	await process_frame
	quit(error)
