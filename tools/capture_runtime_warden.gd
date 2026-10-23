extends SceneTree
## Actual-level viewport evidence. No desktop capture, network or authoring API.

var session
var enemy
var camera: Camera3D
var output := "res://builds/validation/warden-integration"
var frames: Array = []

func _initialize() -> void:
	call_deferred("capture_run")

func capture(label: String) -> void:
	for frame in range(4):
		await process_frame
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output.path_join("%s-%d.png" % [label, root.size.x])
	if image.save_png(path) != OK:
		push_error("Could not save " + path)
		quit(1)
	frames.append({"file": path, "mode": enemy.presentation.mode, "native_time": enemy.presentation.native_time, "remaining_windup": enemy.windup, "player_health": session.run.player.health, "actor_position": str(enemy.position)})
	print("Rendered: ", path)

func view(offset: Vector3, target: Vector3) -> void:
	camera.global_position = enemy.global_position + offset
	camera.look_at(target)
	camera.make_current()

func reset_actor() -> void:
	enemy.position = Vector3(0, 0.1, 12.5)
	enemy.look_at(Vector3(0, 0.1, 14))
	enemy.state = enemy.State.CHASE
	enemy.cooldown = 0.0
	enemy.health = 68
	enemy.collision_layer = 4
	enemy.collision_mask = 7
	enemy.velocity = Vector3.ZERO
	enemy.path_refresh = 0.0
	enemy.presentation.dead = false
	enemy.presentation.attack_active = false
	enemy.presentation.hit_remaining = 0.0
	enemy.presentation.flash_remaining = 0.0
	session.run.player.health = 100
	session.run.player.stats_changed.emit()
	session.run.player.message.emit("")
	session.run.player.position = Vector3(0, 0.1, 14)

func capture_run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session.start_run()
	var player = session.run.player
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	for actor in get_nodes_in_group("enemies"):
		actor.set_physics_process(false)
		if actor.archetype == 0 and enemy == null:
			enemy = actor
	session.run.presentation.set_process(false)
	session.run.ambience.stop_loops()
	camera = Camera3D.new()
	camera.fov = 52.0
	camera.near = 0.01
	session.run.add_child(camera)
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		reset_actor()
		player.viewmodels.hide()
		session.ui.hide()
		view(Vector3(2.2, 1.6, 3.0), enemy.global_position + Vector3.UP * 0.9)
		enemy.presentation._sample(&"Idle", 0.7, 0.0, true)
		await capture("level-idle")
		enemy.presentation._sample(&"Walk", 0.4, 0.0, true)
		await capture("level-walk")
		player.position = Vector3(0, 0.1, 8)
		var travel_start: Vector3 = enemy.position
		for frame in range(20):
			await physics_frame
			enemy._physics_process(1.0 / 60.0)
		if enemy.position.distance_to(travel_start) < 0.1 or enemy.presentation.mode != &"Walk":
			push_error("Actual navigation did not produce the rendered travel gait")
			quit(1)
			return
		await capture("level-actual-travel")
		reset_actor()
		# Native references for visual inspection, separate from authoritative timing.
		for time in [0.2, 0.35, 0.5, 0.6, 0.65, 0.8, 0.95]:
			enemy.presentation._sample(&"Attack", time, 0.0, true)
			await capture("native-strike-%03d" % roundi(time * 100))
		enemy.presentation._sample(&"Idle", 0.7, 0.0, true)
		var hand: Vector3 = enemy.presentation.weapon_mount.global_position
		view(hand - enemy.global_position + Vector3(0.45, 0.25, 0.65), hand)
		await capture("grip-idle")
		enemy.presentation._sample(&"Attack", enemy.presentation.NATIVE_CONTACT, 0.0, true)
		hand = enemy.presentation.weapon_mount.global_position
		view(hand - enemy.global_position + Vector3(0.45, 0.25, 0.65), hand)
		await capture("grip-contact")
		reset_actor()
		view(Vector3(2.2, 1.6, 3.0), enemy.global_position + Vector3.UP * 0.9)
		for frame in range(3):
			await physics_frame
		enemy._physics_process(0.01)
		enemy._physics_process(0.3)
		await capture("level-windup")
		enemy._physics_process(0.25)
		# Floating point can leave a tiny positive remainder at the exact boundary.
		if enemy.windup > 0.0:
			enemy._physics_process(0.00001)
		if player.health != 88 or not is_equal_approx(enemy.presentation.native_time, enemy.presentation.NATIVE_CONTACT):
			push_error("Contact render is not the authoritative damage boundary")
			quit(1)
			return
		await capture("level-contact")
		enemy._physics_process(0.25)
		await capture("level-recovery")
		enemy._physics_process(1.0)
		enemy.take_damage(1, player)
		enemy.advance_presentation(0.1)
		await capture("level-hit")
		enemy.take_damage(1000, player)
		enemy.advance_presentation(3.0)
		await capture("level-death")
		# Actual first-person view with unchanged encounter/camera/HUD rules.
		reset_actor()
		enemy.presentation._sample(&"Idle", 0.7, 0.0, true)
		player.camera.make_current()
		player.viewmodels.show()
		session.ui.show()
		await capture("gameplay-idle")
	var file := FileAccess.open(output.path_join("captures.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(frames, "  ") + "\n")
	file.close()
	session.show_menu()
	session.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
