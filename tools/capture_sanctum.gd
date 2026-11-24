extends SceneTree
## Renders the Golem Sanctum in The Ossuary (sealed door, dormant golem, statues, awakening, slam,
## boss bar, death and the revealed key) to builds/validation/sanctum/.

var player
var level
var session

func _initialize() -> void:
	call_deferred("capture")

func frames(count: int = 8) -> void:
	for index in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	await frames(2)
	var path = "res://builds/validation/sanctum/%s.png" % name
	root.get_texture().get_image().save_png(path)
	print("Saved ", path)

func view(from: Vector3, at: Vector3) -> void:
	player.global_position = from - Vector3.UP * 1.6
	await frames(1)
	player.rotation.y = 0.0
	player.pivot.rotation.x = 0.0
	player.camera.look_at(at, Vector3.UP)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/validation/sanctum")
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
	var golem = get_first_node_in_group("bosses")
	var seal = get_first_node_in_group("bone_seals")
	await frames(20)
	await view(Vector3(0, 1.7, -9), Vector3(0, 1.6, -16.35))
	await shot("seal_closed")
	seal.open()
	await create_timer(1.5).timeout
	await view(Vector3(0, 1.7, -14.6), Vector3(0, 1.8, -23))
	await shot("sanctum_from_door")
	await view(Vector3(5.5, 3.2, -18), Vector3(-1, 0.5, -25))
	await shot("sanctum_overview")
	await view(golem.global_position + Vector3(0.9, 3.0, 3.6), golem.global_position + Vector3(0, 2.6, 0))
	await shot("golem_dormant_face")
	await view(Vector3(-2.0, 1.6, -21.0), Vector3(-4.85, 1.0, -20.2))
	await shot("statue_west")
	await view(Vector3(1.5, 1.6, -24.0), Vector3(4.85, 1.0, -25.8))
	await shot("statue_east_north")
	# Wake the golem and watch the awakening.
	golem.target = player
	golem.awaken()
	for step in range(30):
		golem.presentation.advance_visual(0.02, 0.0, false, 0.0, 0.0)
	await view(golem.global_position + Vector3(0.9, 3.0, 3.6), golem.global_position + Vector3(0, 2.6, 0))
	await shot("golem_awakening_face")
	for step in range(80):
		golem.presentation.advance_visual(0.02, 0.0, false, 0.0, 0.0)
	await view(golem.global_position + Vector3(0.9, 3.0, 3.6), golem.global_position + Vector3(0, 2.6, 0))
	await shot("golem_awake_face")
	golem.awakening = 0.0
	golem.state = golem.State.CHASE
	# Slam: windup then contact, seen from the front-side.
	await view(golem.global_position + Vector3(3.2, 1.7, 3.8), golem.global_position + Vector3(0, 1.6, 0))
	golem.look_at(Vector3(player.global_position.x, golem.global_position.y, player.global_position.z), Vector3.UP)
	for remaining in [1.1, 0.8, 0.5, 0.3]:
		golem.presentation.advance_visual(0.016, 0.0, true, remaining, 1.2)
	await shot("golem_windup")
	golem.presentation.advance_visual(0.016, 0.0, true, 0.0, 1.2)
	golem.presentation.attack_contact()
	await frames(6)
	await shot("golem_slam")
	golem.health = 260
	await view(Vector3(0, 1.7, -16.0), golem.global_position + Vector3(0, 1.8, 0))
	await shot("boss_bar")
	golem.set_physics_process(true)
	golem.take_damage(1000, player)
	await create_timer(2.6).timeout
	await view(golem.global_position + Vector3(2.5, 2.2, 3.5), golem.global_position + Vector3(0, 0.6, 0))
	await shot("golem_dead_key")
	session.queue_free()
	await frames(2)
	quit(0)
