extends SceneTree
## Renders the Fire Bat in the Mapping Example (hover, fireball windup, fireball in flight, death)
## to builds/validation/fire-bat/.

func _initialize() -> void:
	call_deferred("capture")

func frames(count: int = 8) -> void:
	for index in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	await frames(2)
	var path = "res://builds/validation/fire-bat/%s.png" % name
	root.get_texture().get_image().save_png(path)
	print("Saved ", path)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/validation/fire-bat")
	root.size = Vector2i(1280, 720)
	var session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session._on_command("Mapping Example")
	var level = session.run
	var player = level.player
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	var bat = null
	for enemy in get_nodes_in_group("enemies"):
		if enemy.archetype == 2:
			bat = enemy
		else:
			enemy.set_physics_process(false)
	bat.set_physics_process(false)
	player.global_position = Vector3(3, 0.1, 1.5)
	player.camera.look_at(bat.global_position, Vector3.UP)
	bat.look_at(Vector3(player.global_position.x, bat.global_position.y, player.global_position.z), Vector3.UP)
	await frames(20)
	await shot("hover")
	bat.presentation.begin_attack()
	await create_timer(0.3).timeout
	await shot("windup")
	bat.state = bat.State.CHASE
	bat.resolve_attack()
	await create_timer(0.12).timeout
	await shot("fireball")
	bat.take_damage(1000, player)
	bat.set_physics_process(true)
	await create_timer(1.6).timeout
	player.camera.look_at(bat.global_position, Vector3.UP)
	await shot("dead")
	session.queue_free()
	await frames(2)
	quit(0)
