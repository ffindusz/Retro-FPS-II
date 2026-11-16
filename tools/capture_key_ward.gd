extends SceneTree
## Renders the guarded key alcove closed and open to builds/validation/key-ward/.

const VIEWS = {
	"approach": [Vector3(24, 0.1, -2.5), Vector3(28, 1.4, -9.4)],
	"gateway": [Vector3(28, 0.1, -5.5), Vector3(28, 1.2, -11)],
}

func _initialize() -> void:
	call_deferred("capture")

func frames(count: int = 8) -> void:
	for index in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func capture() -> void:
	var directory = "res://builds/validation/key-ward"
	DirAccess.make_dir_recursive_absolute(directory)
	root.size = Vector2i(1280, 720)
	var session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session.start_run()
	var level = session.run
	var player = level.player
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	for stage in ["closed", "open"]:
		if stage == "open":
			for guard in level.key_ward.guards:
				guard.take_damage(1000, player)
			await create_timer(KeyWard.OPEN_TIME + 1.0).timeout
		for view in VIEWS:
			player.position = VIEWS[view][0]
			player.camera.look_at(VIEWS[view][1], Vector3.UP)
			await frames()
			var path = "%s/%s-%s.png" % [directory, stage, view]
			root.get_texture().get_image().save_png(path)
			print("Saved ", path)
	session.queue_free()
	await frames(2)
	quit(0)
