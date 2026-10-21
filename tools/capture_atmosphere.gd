extends SceneTree
## Fixed game-viewport before/after views and a frozen-scene comparison sample.

const VIEWS = {
	"entrance": [Vector3(0, 0.1, 15), Vector3(0, 1.4, 1)],
	"courtyard": [Vector3(0, 0.1, 3), Vector3(2, 1.3, -7)],
	"crypt": [Vector3(14.5, 0.1, -6), Vector3(28, 1.2, -9)],
	"key": [Vector3(25, 0.1, -9), Vector3(28, 1.2, -12)],
	"exit": [Vector3(10, 0.1, -9.5), Vector3(11, 1.6, -13.7)],
	"stone-close": [Vector3(-10, 0.1, -6), Vector3(-13, 1.3, -8)]
}

func _initialize() -> void:
	call_deferred("capture")

func frames(count: int = 8) -> void:
	for index in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func capture() -> void:
	var arguments = OS.get_cmdline_user_args()
	var stage = arguments[0] if not arguments.is_empty() else "after"
	if stage not in ["before", "after"]:
		push_error("Expected before or after")
		quit(1)
		return
	if stage == "before" and FileAccess.file_exists("res://resources/atmosphere_baseline.tres"):
		push_error("Refusing to overwrite the recorded pre-change baseline")
		quit(1)
		return
	var directory = "res://builds/validation/atmosphere/%s" % stage
	DirAccess.make_dir_recursive_absolute(directory)
	var session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session.start_run()
	var level = session.run
	var player = level.player
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.weapons.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	if stage == "before":
		var baseline = WorldFingerprint.snapshot(level)
		var resource = Resource.new()
		resource.set_meta("snapshot", baseline)
		ResourceSaver.save(resource, "res://resources/atmosphere_baseline.tres")
		var hashes: Dictionary = {}
		for id in ["weapon-cleaver", "weapon-staff", "enemy-warden", "enemy-adept", "prop-torch", "prop-urn"]:
			var path = "assets/models/%s/model.glb" % id
			hashes[path] = FileAccess.get_sha256("res://" + path)
		for filename in DirAccess.get_files_at("res://assets/audio/combat"):
			if filename.ends_with(".wav"):
				var path = "assets/audio/combat/" + filename
				hashes[path] = FileAccess.get_sha256("res://" + path)
		hashes["resources/demo_navigation.tres"] = FileAccess.get_sha256("res://resources/demo_navigation.tres")
		var output = FileAccess.open("res://docs/fortress-atmosphere-baseline.json", FileAccess.WRITE)
		output.store_string(JSON.stringify({"snapshot": baseline, "source_hashes": hashes, "date": "2026-10-21", "version": "0.2.1"}, "\t"))
		output.close()
	if level.get("presentation") != null:
		level.presentation.set_process(false)
		level.presentation.set_clock(0.0)
	var reports: Array = []
	for size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = size
		for view in VIEWS:
			player.position = VIEWS[view][0]
			player.camera.look_at(VIEWS[view][1], Vector3.UP)
			if level.get("ambience") != null:
				level.ambience.advance(2.0)
			await frames()
			root.get_texture().get_image().save_png("%s/%s-%d.png" % [directory, view, size.x])
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		player.position = VIEWS.courtyard[0]
		player.camera.look_at(VIEWS.courtyard[1], Vector3.UP)
		await frames(60)
		var start = Time.get_ticks_usec()
		var drawn = Engine.get_frames_drawn()
		while Time.get_ticks_usec() - start < 2000000:
			await RenderingServer.frame_post_draw
		var elapsed = (Time.get_ticks_usec() - start) / 1000000.0
		var count = Engine.get_frames_drawn() - drawn
		var report = {"stage": stage, "resolution": str(size), "seconds": elapsed, "frames": count,
			"mean_ms": elapsed * 1000.0 / count, "fps": count / elapsed,
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
		reports.append(report)
		print(JSON.stringify(report))
	var output = FileAccess.open(directory + "/profile.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(reports, "\t"))
	output.close()
	session.show_menu()
	session.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("Saved fixed views and comparison sample: ", directory)
	quit()
