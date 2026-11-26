extends SceneTree
## Renders The Ossuary and its skeletons (overview, idle eyes, slash, staggers, bow draw, arrow, run, death)
## to builds/validation/ossuary/.

var player
var level

func _initialize() -> void:
	call_deferred("capture")

func frames(count: int = 8) -> void:
	for index in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	await frames(2)
	var path = "res://builds/validation/ossuary/%s.png" % name
	root.get_texture().get_image().save_png(path)
	print("Saved ", path)

func named(label: String) -> Node3D:
	var marker: Node3D = level.get_node("Placements/" + label)
	for enemy in get_nodes_in_group("enemies"):
		if Vector2(enemy.position.x, enemy.position.z).distance_to(Vector2(marker.position.x, marker.position.z)) < 0.3:
			return enemy
	return null

func view(from: Vector3, at: Vector3) -> void:
	player.global_position = from - Vector3.UP * 1.6
	await frames(1)
	player.camera.look_at(at, Vector3.UP)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/validation/ossuary")
	root.size = Vector2i(1280, 720)
	var session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session._on_command("The Ossuary")
	level = session.run
	player = level.player
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var warrior = named("GallerySkeleton")
	var archer = named("NorthArcher")
	await frames(20)
	await view(Vector3(0, 1.7, 13), Vector3(0, 1.2, -6))
	await shot("overview")
	# Close-up of the warrior's face and eyes.
	await view(warrior.global_position + Vector3(0.4, 1.55, -1.3), warrior.global_position + Vector3(0, 1.35, 0))
	warrior.look_at(Vector3(player.global_position.x, warrior.global_position.y, player.global_position.z), Vector3.UP)
	await frames(6)
	await shot("warrior_eyes")
	await view(warrior.global_position + Vector3(1.6, 1.5, -2.2), warrior.global_position + Vector3(0, 1.0, 0))
	warrior.look_at(Vector3(player.global_position.x, warrior.global_position.y, player.global_position.z), Vector3.UP)
	for remaining in [0.4, 0.2, 0.0]:
		warrior.presentation.advance_visual(0.016, 0.0, true, remaining, 0.6)
	warrior.presentation.attack_contact()
	await shot("warrior_slash")
	# Stagger: the hit clip early and midway, same side view.
	for step in range(60):
		warrior.presentation.advance_visual(0.02, 0.0, false, 0.0, 0.6)
	warrior.presentation.stagger()
	var played := 0.0
	for moment in [0.3, 0.75]:
		while played < moment:
			warrior.presentation.advance_visual(0.02, 0.0, false, 0.0, 0.6)
			played += 0.02
		await shot("warrior_stagger_%d" % int(moment * 100))
	# Archer at the north end: draw, then a real arrow toward the player.
	await view(archer.global_position + Vector3(1.2, 1.5, 3.2), archer.global_position + Vector3(0, 1.2, 0))
	archer.look_at(Vector3(player.global_position.x, archer.global_position.y, player.global_position.z), Vector3.UP)
	for step in range(58):
		archer.presentation.advance_visual(0.015, 0.0, true, 0.9 - step * 0.015, 0.9)
	await shot("archer_draw")
	archer.presentation.stagger()
	for step in range(25):
		archer.presentation.advance_visual(0.02, 0.0, false, 0.0, 0.9)
	await shot("archer_stagger")
	for step in range(80):
		archer.presentation.advance_visual(0.02, 0.0, false, 0.0, 0.9)
	# Back to the bow draw for the arrow shot below.
	for step in range(60):
		archer.presentation.advance_visual(0.015, 0.0, true, 0.9 - step * 0.015, 0.9)
	# Shoot from down the gallery so the arrow is visible in flight.
	await view(Vector3(-0.8, 1.7, -7.5), archer.global_position + Vector3(0, 1.2, 0))
	archer.look_at(Vector3(player.global_position.x, archer.global_position.y, player.global_position.z), Vector3.UP)
	archer.target = player
	archer.presentation.attack_contact()
	archer.resolve_attack()
	await create_timer(0.1).timeout
	await shot("arrow")
	# Face close-up of the archer: eye glow and the faint eye light on the skull.
	for bolt in get_nodes_in_group("projectiles"):
		bolt.free()
	archer.presentation.advance_visual(0.5, 0.0, false, 0.0, 0.9)
	await view(archer.global_position + Vector3(0.15, 1.45, 0.9), archer.global_position + Vector3(0, 1.38, 0))
	archer.look_at(Vector3(player.global_position.x, archer.global_position.y, player.global_position.z), Vector3.UP)
	for step in range(30):
		archer.presentation.advance_visual(0.03, 0.0, false, 0.0, 0.9)
	await shot("archer_eyes")
	# Let the gallery warrior notice the player and run.
	for bolt in get_nodes_in_group("projectiles"):
		bolt.free()
	await view(Vector3(-1.5, 1.7, 9), warrior.global_position + Vector3(0, 1, 0))
	warrior.target = player
	warrior.state = warrior.State.CHASE
	warrior.set_physics_process(true)
	await create_timer(0.7).timeout
	player.camera.look_at(warrior.global_position + Vector3(0, 1, 0), Vector3.UP)
	await shot("warrior_run")
	warrior.take_damage(1000, player)
	await create_timer(2.5).timeout
	player.camera.look_at(warrior.global_position + Vector3(0, 0.3, 0), Vector3.UP)
	await shot("warrior_dead")
	session.queue_free()
	await frames(2)
	quit(0)
