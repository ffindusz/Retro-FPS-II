extends SceneTree
## Short same-view samples, not minimum-FPS or whole-game performance claims.

var actors: Array = []

func _initialize() -> void:
	call_deferred("profile_scene")

func tick_visuals() -> void:
	var delta := 1.0 / Engine.physics_ticks_per_second
	for actor in actors:
		if actor.has_method("advance_presentation"):
			actor.advance_presentation(delta, actor.move_speed * delta)

func profile_scene() -> void:
	var args := OS.get_cmdline_user_args()
	var label := args[0] if not args.is_empty() else "after"
	var output := ProjectSettings.globalize_path("res://builds/validation/warden-integration")
	if args.size() > 1:
		output = args[1]
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join(label + "-profile.json")
	if FileAccess.file_exists(path):
		push_error("Existing comparison profile preserved: " + path)
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session.start_run()
	var player = session.run.player
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.position = Vector3(0, 0.1, 3)
	player.rotation = Vector3.ZERO
	player.pivot.rotation = Vector3.ZERO
	actors = get_nodes_in_group("enemies")
	for actor in actors:
		actor.set_physics_process(false)
		actor.state = actor.State.CHASE
		actor.look_at(Vector3(0, actor.position.y, 3))
	session.run.presentation.set_process(false)
	session.run.ambience.stop_loops()
	physics_frame.connect(tick_visuals)
	var reports: Array = []
	for size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = size
		for frame in range(30):
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("%s-courtyard-%d.png" % [label, size.x]))
		var start := Time.get_ticks_usec()
		var drawn_start := Engine.get_frames_drawn()
		var frames := 0
		while Time.get_ticks_usec() - start < 2000000:
			await RenderingServer.frame_post_draw
			frames += 1
		var elapsed := (Time.get_ticks_usec() - start) / 1000000.0
		reports.append({"label": label, "resolution": str(size), "frames": frames, "engine_drawn_frames": Engine.get_frames_drawn() - drawn_start, "seconds": elapsed, "mean_frame_ms": elapsed * 1000.0 / frames, "observed_fps": frames / elapsed, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "gpu": RenderingServer.get_video_adapter_name(), "engine": Engine.get_version_info().string, "note": "Fixed courtyard/camera and actor transforms; AI/combat/torch aging frozen; runtime Warden visuals receive virtual travel at 60Hz. Two-second view sample, not whole-run/minimum FPS."})
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(reports, "  ") + "\n")
	file.close()
	print(JSON.stringify(reports))
	actors.clear()
	physics_frame.disconnect(tick_visuals)
	session.show_menu()
	session.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
