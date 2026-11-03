extends SceneTree
## Side-view frames of a real-run Adept death for visual review.
## The animated presentation is aged explicitly with AI frozen; the static fallback uses real time.
## Usage: godot --path . --resolution 1280x720 --script res://tools/capture_adept_death.gd

const STAGES = {"alive": -1.0, "stagger": 0.35, "buckle": 1.0, "fall": 2.0, "settled": 3.6}
const STEP = 1.0 / 60.0

func _initialize() -> void:
	call_deferred("capture")

func frames(count: int = 4) -> void:
	for index in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func capture() -> void:
	var directory = "res://builds/validation/living-lights/adept"
	DirAccess.make_dir_recursive_absolute(directory)
	root.size = Vector2i(1280, 720)
	var session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session.start_run()
	var player = session.run.player
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.weapons.set_physics_process(false)
	var adept: Node3D
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		if adept == null and enemy.archetype == 1:
			adept = enemy
	# Side view, so the fall reads in profile.
	player.position = adept.global_position + adept.global_basis.x * 4.5
	player.camera.look_at(adept.global_position + Vector3.UP * 0.9, Vector3.UP)
	if adept.presentation != null:
		adept.advance_presentation(0.5)
	await frames(30)
	var age = 0.0
	var start = -1.0
	for stage in STAGES:
		var at: float = STAGES[stage]
		if at >= 0.0:
			if start < 0.0:
				adept.take_damage(1000, null)
				start = Time.get_ticks_msec() / 1000.0
			if adept.presentation != null:
				while age < at:
					adept.advance_presentation(STEP)
					age += STEP
			else:
				while Time.get_ticks_msec() / 1000.0 - start < at:
					await process_frame
		await frames(2)
		root.get_texture().get_image().save_png("%s/adept-death-%s.png" % [directory, stage])
	session.show_menu()
	session.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("Saved Adept death frames: ", directory)
	quit()
