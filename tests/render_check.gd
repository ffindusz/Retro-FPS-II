extends SceneTree
## Renders only this game's viewport to files; never captures the desktop.
var session
var failures: int = 0

func _initialize() -> void:
	call_deferred("render_checks")

func draw_frames() -> void:
	for index in range(4):
		await process_frame
		await RenderingServer.frame_post_draw

func capture(name: String) -> void:
	await draw_frames()
	var path = "res://builds/validation/%s.png" % name
	root.get_texture().get_image().save_png(path)
	print("Rendered: ", path)

func verify_layout() -> void:
	var area: Rect2 = session.ui.hud.get_global_rect()
	for label in [session.ui.health_label, session.ui.mana_label, session.ui.weapon_label, session.ui.key_label, session.ui.message_label]:
		if not area.encloses(label.get_global_rect()):
			push_error("HUD label outside viewport: " + label.text)
			failures += 1
	var viewmodels = session.run.player.viewmodels
	# canvas_items stretch uses the logical canvas size (1280x720 at 16:9).
	var logical_size = Vector2i(viewmodels.viewport.get_parent().size)
	if viewmodels.viewport.size != logical_size:
		push_error("Weapon viewport has incorrect size: " + str(viewmodels.viewport.size))
		failures += 1
	if session.ui.volume_box.visible:
		for control in [session.ui.title, session.ui.volume_slider, session.ui.ambience_label, session.ui.ambience_slider] + session.ui.buttons.get_children():
			if not session.ui.menu.get_global_rect().encloses(control.get_global_rect()):
				push_error("Pause/volume control outside viewport")
				failures += 1

func render_checks() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/validation")
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	await capture("menu-1280")
	session.start_run()
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		push_error("Gameplay cursor was not captured")
		failures += 1
	var player = session.run.player
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.weapons.set_physics_process(false)
	player.rotation = Vector3.ZERO
	player.pivot.rotation = Vector3.ZERO
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	player.position = Vector3(0, 0.1, 3)
	await capture("melee-1280")
	verify_layout()
	var target = get_nodes_in_group("enemies")[0]
	target.position = Vector3(0.75, 0.05, 1)
	target.look_at(Vector3(0, target.position.y, 3), Vector3.UP)
	await physics_frame
	await physics_frame
	await draw_frames()
	player.weapons.try_attack()
	player.weapons.advance(0.08)
	await capture("melee-windup-1280")
	player.weapons.advance(0.14)
	session.ui.set_process(false)
	await capture("melee-swing-1280")
	if target.health != 34 or not session.ui.hit_marker.visible:
		push_error("Rendered contact did not confirm the off-center hit")
		failures += 1
	player.take_damage(12, target)
	await capture("damage-feedback-1280")
	session.ui.set_process(true)
	session.ui.clear_combat_feedback()
	player.weapons.advance(0.3)
	player.position = Vector3(0, 0.1, 18.5)
	player.rotation.y = PI
	player.weapons.try_attack()
	player.weapons.advance(0.22)
	await capture("melee-wall-impact-1280")
	if session.ui.hit_marker.visible:
		push_error("Wall strike incorrectly confirmed an enemy hit")
		failures += 1
	player.weapons.advance(0.3)
	player.rotation = Vector3.ZERO
	player.position = Vector3(0, 0.1, 3)
	player.weapons.select(1)
	await capture("magic-1280")
	# Check final art in the actual level, not just vendor thumbnails.
	player.position = Vector3(0, 0.1, 2)
	var actors: Array = []
	for archetype in [0, 1]:
		for enemy in get_nodes_in_group("enemies"):
			if enemy.archetype == archetype:
				enemy.position = Vector3(-1.1 if archetype == 0 else 1.1, 0.05, -2)
				enemy.look_at(Vector3(0, enemy.position.y, 2), Vector3.UP)
				actors.append(enemy)
				break
	var urn = load("res://scenes/props/urn.tscn").instantiate()
	urn.position = Vector3(-2.5, 0, -2)
	session.run.add_child(urn)
	var torch = load("res://scenes/props/torch.tscn").instantiate()
	torch.position = Vector3(2.5, 2.2, -2)
	session.run.add_child(torch)
	await capture("models-in-level-1280")
	for actor in actors:
		actor.state = actor.State.ATTACK
		actor.windup = 0.4
		actor.set_physics_process(true)
	player.weapons.try_attack()
	await capture("combat-models-1280")
	for actor in actors:
		actor.take_damage(1000, player)
	await create_timer(0.4).timeout
	await capture("enemy-death-models-1280")
	player.position = Vector3(0, 0.1, 18.5)
	player.rotation.y = PI
	await capture("wall-viewmodel-1280")
	player.rotation = Vector3.ZERO
	player.position = Vector3(0, 0.1, 3)
	session.pause_run()
	session.ui.volume_slider.value = 35
	session.ui.volume_slider.grab_focus()
	await capture("pause-volume-1280")
	verify_layout()
	session.resume_run()
	root.size = Vector2i(1920, 1080)
	await capture("magic-1920")
	verify_layout()
	session.pause_run()
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		push_error("Paused cursor was not released")
		failures += 1
	await capture("pause-1920")
	verify_layout()
	session.resume_run()
	session.finish(true)
	await capture("victory-1920")
	session.start_run()
	session.run.player.take_damage(1000, null)
	await capture("defeat-1920")
	session.show_menu()
	session.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("Render checks: ", failures, " failures")
	quit(0 if failures == 0 else 1)
