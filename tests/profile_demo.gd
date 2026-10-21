extends SceneTree
## Short, reproducible prototype sample, NOT a release performance certification.

func _initialize() -> void:
	call_deferred("profile_demo")

func profile_demo() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/validation")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session.start_run()
	var player = session.run.player
	player.set_process_unhandled_input(false)
	player.position = Vector3(0, 0.1, 3)
	player.rotation = Vector3.ZERO
	player.pivot.rotation = Vector3.ZERO
	var reports: Array = []
	for size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = size
		for frame in range(30):
			await RenderingServer.frame_post_draw
		var begin = Time.get_ticks_usec()
		var drawn_start = Engine.get_frames_drawn()
		var previous = begin
		var longest: float = 0.0
		var frames: int = 0
		var process_total: float = 0.0
		var peak_effects: int = 0
		var peak_voices: int = 0
		while Time.get_ticks_usec() - begin < 3000000:
			# Keep the fixed-view encounter active rather than profiling a defeat menu.
			player.health = player.max_health
			await RenderingServer.frame_post_draw
			var now = Time.get_ticks_usec()
			longest = maxf(longest, (now - previous) / 1000.0)
			previous = now
			frames += 1
			peak_effects = maxi(peak_effects, session.run.feedback.effects.size())
			peak_voices = maxi(peak_voices, session.run.feedback.audio.voices.size())
			process_total += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		var elapsed = (Time.get_ticks_usec() - begin) / 1000000.0
		var report = {
			"resolution": str(size), "seconds": elapsed, "frames": frames,
			"mean_fps": frames / elapsed, "mean_frame_ms": elapsed * 1000.0 / frames,
			"engine_drawn_frames": Engine.get_frames_drawn() - drawn_start,
			"peak_effects": peak_effects, "peak_voices": peak_voices,
			"max_frame_ms": longest, "mean_process_ms": process_total / frames,
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			"gpu": RenderingServer.get_video_adapter_name(), "godot": Engine.get_version_info().string,
			"note": "Combat-polish 3-second fixed courtyard sample with Meshy models, SFX and active enemies; vsync disabled; player health refreshed for sampling"
		}
		reports.append(report)
		print(JSON.stringify(report))
	var output = FileAccess.open("res://builds/validation/profile.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(reports, "\t"))
	output.close()
	session.show_menu()
	session.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
