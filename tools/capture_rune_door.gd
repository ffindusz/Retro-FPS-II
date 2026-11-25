extends SceneTree
## Renders the rune door exit of The Ossuary (sealed, socket, key inserted, opening, open, corridor)
## to builds/validation/rune_door/.

var player
var level
var session
var door: RuneDoor

func _initialize() -> void:
	call_deferred("capture")

func frames(count: int = 8) -> void:
	for index in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	await frames(2)
	var path = "res://builds/validation/rune_door/%s.png" % name
	root.get_texture().get_image().save_png(path)
	print("Saved ", path)

func view(from: Vector3, at: Vector3) -> void:
	player.global_position = from - Vector3.UP * 1.6
	await frames(1)
	player.rotation.y = 0.0
	player.pivot.rotation.x = 0.0
	player.camera.look_at(at, Vector3.UP)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/validation/rune_door")
	root.size = Vector2i(1280, 720)
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session._on_command("The Ossuary")
	level = session.run
	player = level.player
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	door = level.rune_door
	get_first_node_in_group("bone_seals").open()
	await frames(20)
	var front := door.global_position
	await view(front + Vector3(0, 1.7, 9.5), front + Vector3(0, 2.6, 0))
	await shot("door_sealed_far")
	await view(front + Vector3(-1.6, 1.7, 4.2), front + Vector3(0.4, 2.4, 0))
	await shot("door_sealed_near")
	await view(door.socket.global_position + door.socket.global_basis.z * 1.3 + Vector3(0, 1.5, 0), door.socket.global_position + Vector3.UP * 0.7)
	await shot("socket")
	await view(door.global_position + Vector3(0, 0, -5.5) + Vector3(0, 1.7, 0) * 0 + Vector3(0, 1.7, 11.0), front + Vector3(0, 3.2, 0))
	await shot("door_from_dais")
	player.collect_key()
	await view(door.socket.global_position + door.socket.global_basis.z * 1.2 + Vector3(0, 1.6, 0), door.socket.global_position + Vector3.UP * 0.8)
	door.interact(player)
	await create_timer(0.9).timeout
	await shot("key_inserted")
	await view(front + Vector3(0.8, 1.7, 5.5), front + Vector3(0, 2.4, 0))
	await create_timer(1.9).timeout
	await shot("door_opening")
	await create_timer(3.0).timeout
	await shot("door_open")
	await view(front + Vector3(0, 1.7, 1.6), front + Vector3(0, 1.5, -4))
	await shot("beyond")
	session.queue_free()
	await frames(2)
	quit(0)
