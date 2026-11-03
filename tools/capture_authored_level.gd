extends SceneTree
## Only game viewports, never the desktop.

var session

func _initialize() -> void:
	call_deferred("capture_level")

func capture(label: String) -> void:
	for frame in range(5):
		await process_frame
		await RenderingServer.frame_post_draw
	var path := "res://builds/validation/level-authoring/%s-%d.png" % [label, root.size.x]
	if root.get_texture().get_image().save_png(path) != OK:
		push_error("Could not capture " + path)
	print("Rendered: ", path)

func capture_level() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/validation/level-authoring")
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		session.show_menu()
		await capture("menu")
		session._on_command("Mapping Example")
		var player = session.run.player
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
		for enemy in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		await capture("entrance")
		player.position = Vector3(0, 0.1, 3)
		await capture("courtyard")
		player.position = Vector3(10, 0.1, -1.3)
		player.look_at(Vector3(16, 0.1, -5))
		await capture("crypt")
		var camera := Camera3D.new()
		session.run.add_child(camera)
		camera.position = Vector3(24, 27, 30)
		camera.look_at(Vector3(4, 0, 3))
		camera.make_current()
		session.ui.hide()
		player.viewmodels.hide()
		await capture("overview")
		session.ui.show()
	session.show_menu()
	session.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
