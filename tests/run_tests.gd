extends SceneTree
## Dependency-free regression runner. A failure exits nonzero.

var checks: int = 0
var failures: int = 0
var session
var player: DemoPlayer

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)

func settle(frames: int = 3) -> void:
	for index in range(frames):
		await physics_frame
	await process_frame

func fresh() -> void:
	session.start_run()
	player = session.run.player
	player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	if is_instance_valid(session.run.presentation):
		session.run.presentation.set_process(false)
	if is_instance_valid(session.run.ambience):
		session.run.ambience.set_process(false)
	await settle()

func enemy_at(position: Vector3, ranged: bool = false):
	var scene = load("res://scenes/enemies/ranged_enemy.tscn" if ranged else "res://scenes/enemies/melee_enemy.tscn")
	var enemy = scene.instantiate()
	enemy.position = position
	session.run.add_child(enemy)
	enemy.target = player
	enemy.set_physics_process(false)
	return enemy

func wall_at(position: Vector3) -> StaticBody3D:
	return session.run.solid(position, Vector3(4, 2.8, 0.2))

func reset_weapons() -> void:
	player.weapons.cancel_attack()
	player.weapons.cooldowns.fill(0.0)
	for bolt in get_nodes_in_group("projectiles"):
		bolt.free()

func run_tests() -> void:
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	check(session.state == session.State.MENU, "launch reaches start menu")
	await test_menu_keyboard()
	await fresh()
	await test_player()
	await fresh()
	await test_weapons()
	await fresh()
	await test_enemies()
	await fresh()
	await test_pickups_and_exit()
	await fresh()
	await test_session()
	await fresh()
	await test_navigation()
	await test_imported_models()
	await test_melee_cycle()
	await test_melee_volume()
	await test_melee_occlusion()
	await test_melee_lifecycle()
	await test_feedback()
	await test_audio()
	await test_pickup_audio()
	await test_encounter_tuning()
	await test_atmosphere()
	await test_ambience()
	session.show_menu()
	session.queue_free()
	await settle()
	# One-shots stop immediately; let the backend finish its pending audio buffer.
	await create_timer(0.2).timeout
	print("\nRESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func press_key(code: Key) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame

func test_menu_keyboard() -> void:
	await press_key(KEY_TAB)
	check(session.ui.buttons.get_child(1).has_focus(), "Tab navigates menu buttons")
	session.ui.buttons.get_child(0).grab_focus()
	await press_key(KEY_ENTER)
	check(session.state == session.State.PLAYING, "Enter activates Start")
	session.pause_run()
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "pause releases cursor")
	await press_key(KEY_ENTER)
	check(session.state == session.State.PLAYING, "keyboard activates Resume")
	session.show_menu()

func mouse_click_at(point: Vector2) -> void:
	# Headless windows have no display-server mouse-enter event; emulate that first.
	root.notification(Node.NOTIFICATION_WM_MOUSE_ENTER)
	var motion = InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await process_frame
	var press = InputEventMouseButton.new()
	press.position = point
	press.global_position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	root.push_input(press, true)
	await process_frame
	var release = InputEventMouseButton.new()
	release.position = point
	release.global_position = point
	release.button_index = MOUSE_BUTTON_LEFT
	root.push_input(release, true)
	await settle()

func test_player() -> void:
	check(player.health == 100 and player.mana == 60, "fresh health and mana")
	player.take_damage(40, null)
	check(player.health == 60, "damage reduces health")
	check(player.restore_health(1000) and player.health == 100, "healing capped at maximum")
	check(not player.restore_health(10), "full health rejects healing")
	player.mana = 1
	check(player.restore_mana(1000) and player.mana == 60, "mana capped at maximum")
	player.apply_look(Vector2(100, 100000))
	check(absf(player.pivot.rotation.x) <= deg_to_rad(85.01), "mouse pitch bounded")
	player.rotation = Vector3.ZERO
	player.pivot.rotation = Vector3.ZERO
	for index in range(25):
		player.move_player(Vector2(1, -1), 1.0 / 60.0, false)
		await physics_frame
	check(Vector2(player.velocity.x, player.velocity.z).length() <= player.move_speed + 0.001, "diagonal movement speed normalized")
	player.position = Vector3(4, 0.1, 14)
	for index in range(40):
		player.move_player(Vector2.RIGHT, 1.0 / 60.0, false)
		await physics_frame
	check(player.position.x < 4.7, "player cannot walk through entrance wall")
	player.position = Vector3(0, 0.05, 14)
	for index in range(10):
		player.move_player(Vector2.ZERO, 1.0 / 60.0, false)
		await physics_frame
	check(player.is_on_floor(), "player settles on floor")
	player.move_player(Vector2.ZERO, 1.0 / 60.0, true)
	var first_jump = player.velocity.y
	await physics_frame
	player.move_player(Vector2.ZERO, 1.0 / 60.0, true)
	check(first_jump > 0 and player.velocity.y < first_jump, "jump only when grounded")
	var deaths = [0]
	player.died.connect(func(): deaths[0] += 1)
	player.take_damage(10000, null)
	player.take_damage(10000, null)
	check(player.health == 0 and deaths[0] == 1 and not player.can_act(), "lethal damage clamps health and emits death once")
	check(not player.restore_health(100) and not player.collect_key(), "dead player cannot heal or collect key")
	check(session.state == session.State.DEFEAT and paused, "death enters frozen defeat screen")

func test_weapons() -> void:
	var enemy = enemy_at(Vector3(0, 0.1, 11.8))
	await settle()
	check(player.weapons.try_attack(), "ready melee swing accepted")
	check(enemy.health == enemy.max_health, "melee windup does not deal instant damage")
	player.weapons.advance(0.22)
	check(enemy.health == enemy.max_health - player.weapons.melee_damage, "melee deals one hit")
	var remaining: int = enemy.health
	check(not player.weapons.try_attack() and enemy.health == remaining, "melee cooldown prevents duplicate hit")
	player.weapons.select(1)
	player.weapons.select(0)
	check(not player.weapons.try_attack(), "switching does not reset cooldown")
	reset_weapons()
	enemy.position.z = 8
	await settle()
	player.weapons.try_attack()
	player.weapons.advance(0.22)
	check(enemy.health == remaining, "out-of-range melee does not hit")
	enemy.position.z = 11.8
	var wall = wall_at(Vector3(0, 1.4, 12.9))
	await settle()
	reset_weapons()
	player.weapons.try_attack()
	player.weapons.advance(0.22)
	check(enemy.health == remaining, "melee respects walls")
	reset_weapons()
	player.weapons.select(1)
	player.mana = 0
	check(not player.weapons.try_attack() and player.mana == 0, "insufficient mana rejects shot without cost")
	player.mana = 60
	check(player.weapons.try_attack() and player.mana == 55, "successful magic shot charges once")
	check(not player.weapons.try_attack() and player.mana == 55, "cooldown rejection does not charge mana")
	var bolts = get_nodes_in_group("projectiles")
	check(bolts.size() == 1, "one projectile per accepted magic shot")
	if not bolts.is_empty():
		var bolt = bolts[0]
		bolt.set_physics_process(false)
		bolt.speed = 1000
		bolt.advance(0.01)
		check(bolt.resolved and enemy.health == remaining, "swept high-speed shot stops at first wall")
	await settle()
	wall.position.z = 13.8
	await settle()
	reset_weapons()
	player.weapons.try_attack()
	check(get_nodes_in_group("projectiles").is_empty() and enemy.health == remaining, "point-blank spawn obstruction cannot shoot through wall")
	wall.free()
	await settle()
	reset_weapons()
	player.weapons.try_attack()
	bolts = get_nodes_in_group("projectiles")
	if not bolts.is_empty():
		var bolt = bolts[0]
		bolt.set_physics_process(false)
		bolt.advance(0.08)
		check(bolt.resolved and enemy.health == remaining - player.weapons.magic_damage, "projectile hits enemy exactly once")
		var after: int = enemy.health
		bolt.advance(0.08)
		check(enemy.health == after, "resolved projectile cannot deal damage again")
	await settle()
	reset_weapons()
	var missed = load("res://scenes/weapons/projectile.tscn").instantiate()
	missed.configure(player, Vector3.UP, 10, 10, 5, Color.WHITE)
	session.run.add_child(missed)
	missed.global_position = player.camera.global_position
	missed.set_physics_process(false)
	missed.lifetime = 0.01
	missed.advance(0.02)
	check(missed.resolved, "missed projectile expires")
	check(player.health == 100, "player projectiles ignore shooter")
	await settle()

func test_enemies() -> void:
	var enemy = enemy_at(Vector3(0, 0.1, 12.5))
	await settle()
	enemy._physics_process(0.01)
	check(enemy.state == enemy.State.ATTACK and enemy.windup > 0.0, "melee enemy winds up before attacking")
	enemy.resolve_attack()
	check(player.health == 88, "nearby melee enemy attack damages player")
	var wall = wall_at(Vector3(0, 1.4, 13.2))
	await settle()
	enemy.resolve_attack()
	check(player.health == 88, "cover during windup blocks melee damage")
	var deaths = [0]
	enemy.died.connect(func(): deaths[0] += 1)
	enemy.take_damage(1000, player)
	enemy.take_damage(1000, player)
	enemy.resolve_attack()
	await settle()
	check(deaths[0] == 1 and enemy.state == enemy.State.DEAD and enemy.collision_layer == 0, "enemy death is one-shot, cancels attack and removes blocking")
	check(player.health == 88, "dead enemy cannot finish attack")
	wall.free()
	var ranged = enemy_at(Vector3(0, 0.1, 9), true)
	await settle()
	ranged._physics_process(0.01)
	check(ranged.state == ranged.State.ATTACK and ranged.windup > 0.0, "ranged enemy winds up before firing")
	ranged.resolve_attack()
	var bolts = get_nodes_in_group("projectiles")
	check(bolts.size() == 1, "ranged enemy launches visible projectile")
	if not bolts.is_empty():
		var bolt = bolts[0]
		bolt.set_physics_process(false)
		check(bolt.hit_mask == 3, "enemy bolts exclude enemy layer")
		bolt.advance(0.5)
		check(player.health == 76 and bolt.resolved, "enemy projectile damages player")
	await settle()
	wall = wall_at(Vector3(0, 1.4, 12))
	await settle()
	ranged.resolve_attack()
	check(get_nodes_in_group("projectiles").is_empty(), "ranged enemy cannot fire through cover")

func test_pickups_and_exit() -> void:
	var pickup_scene = load("res://scenes/props/pickup.tscn")
	var health = pickup_scene.instantiate()
	health.position = Vector3(0, 0, 17)
	session.run.add_child(health)
	check(not health.try_collect(player) and not health.consumed, "unneeded health pickup remains")
	player.take_damage(10, null)
	check(health.try_collect(player) and health.consumed and player.health == 100, "useful pickup heals with cap and consumes once")
	check(not health.try_collect(player), "pickup cannot be collected twice")
	var mana = pickup_scene.instantiate()
	mana.kind = 1
	mana.position = Vector3(2, 0, 17)
	session.run.add_child(mana)
	check(not mana.try_collect(player), "unneeded mana pickup remains")
	player.mana = 0
	check(mana.try_collect(player) and player.mana == 25, "useful mana pickup replenishes")
	var enemy = get_nodes_in_group("enemies")[0]
	var key = pickup_scene.instantiate()
	key.kind = 2
	key.position = Vector3(-2, 0, 17)
	session.run.add_child(key)
	check(not key.try_collect(enemy), "enemies cannot collect pickups")
	check(not session.run.interact_exit(), "remote exit interaction rejected")
	player.position = session.run.exit_position + Vector3(0, 0.1, 1.5)
	await settle()
	check(not session.run.interact_exit() and session.state == session.State.PLAYING, "locked exit rejects player without key")
	check(key.try_collect(player) and player.has_key, "key updates ownership")
	var barrier = wall_at(session.run.exit_position + Vector3(0, 1.4, 0.7))
	await settle()
	check(not session.run.interact_exit(), "exit interaction respects line of sight")
	barrier.free()
	await settle()
	player.mana = 0
	check(session.run.interact_exit() and session.state == session.State.VICTORY, "key unlocks victory without mana or enemy clearing")
	check(not session.run.interact_exit(), "exit victory emitted once")

func test_session() -> void:
	player.weapons.select(1)
	player.weapons.try_attack()
	var bolt = get_nodes_in_group("projectiles")[0]
	var position: Vector3 = bolt.position
	var lifetime: float = bolt.lifetime
	var cooldown: float = player.weapons.cooldowns[1]
	var enemy = get_nodes_in_group("enemies")[0]
	enemy.state = enemy.State.ATTACK
	enemy.windup = 0.4
	enemy.set_physics_process(true)
	session.pause_run()
	await settle(10)
	check(bolt.position == position and bolt.lifetime == lifetime, "pause freezes projectile position and lifetime")
	check(player.weapons.cooldowns[1] == cooldown and enemy.windup == 0.4, "pause freezes cooldown and enemy windup")
	check(not player.collect_key() and not player.weapons.try_attack(), "paused run rejects gameplay actions")
	check(session.ui.menu.visible and session.ui.buttons.get_child(0).has_focus(), "paused menu remains usable and focused")
	session.resume_run()
	check(player.attack_blocked_until_release and not paused, "resume gates attack until activation release")
	session._on_focus_exited()
	check(session.state == session.State.PAUSED, "focus loss pauses active gameplay")
	session.resume_run()
	for index in range(3):
		player.collect_key()
		player.health = 1
		session.start_run()
		player = session.run.player
		player.set_physics_process(false)
		for actor in get_nodes_in_group("enemies"):
			actor.set_physics_process(false)
		await settle()
		check(player.health == 100 and player.mana == 60 and not player.has_key and player.weapon_slot == 0, "restart %d restores player state" % (index + 1))
		check(get_nodes_in_group("enemies").size() == 6 and get_nodes_in_group("pickups").size() == 7 and get_nodes_in_group("projectiles").is_empty(), "restart %d has exact initial actors and no old projectiles" % (index + 1))
	session.finish(true)
	player.take_damage(10, null)
	check(player.health == 100 and paused, "terminal victory freezes damage")
	session.show_menu()
	await settle()
	check(session.run == null and not paused and session.ui.menu.visible, "quit to menu disposes run")
	session.start_run()
	player = session.run.player
	check(player.health == 100 and not player.has_key, "start from returned menu creates fresh run")

func test_navigation() -> void:
	var map = session.run.get_world_3d().navigation_map
	NavigationServer3D.map_force_update(map)
	# Region changes are synchronized asynchronously; do not query an old iteration.
	for attempt in range(120):
		if NavigationServer3D.map_get_closest_point_owner(map, Vector3(0, 0.1, 14)).is_valid():
			break
		await settle(1)
	check(session.run.navigation.navigation_mesh.get_polygon_count() > 0, "level includes baked navigation polygons")
	var path = NavigationServer3D.map_get_path(map, Vector3(0, 0.1, 14), Vector3(28, 0.1, -12), true)
	check(path.size() > 1 and path[-1].distance_to(Vector3(28, 0.1, -12)) < 1, "entrance-to-key route connected on navigation mesh")
	var return_path = NavigationServer3D.map_get_path(map, Vector3(28, 0.1, -12), session.run.exit_position, true)
	check(return_path.size() > 1 and return_path[-1].distance_to(session.run.exit_position) < 1, "key-to-exit route connected on navigation mesh")
	var enemy = get_nodes_in_group("enemies")[0]
	enemy.position = Vector3(-8, 0.1, -3)
	player.position = Vector3(1, 0.1, -3)
	enemy.state = enemy.State.CHASE
	enemy.target = player
	enemy.agent.target_position = player.position
	await settle()
	check(enemy.agent.get_current_navigation_path().size() > 1 or not enemy.agent.is_navigation_finished(), "enemy navigation can request path around cover")
	var original: Vector3 = enemy.position
	enemy.set_physics_process(true)
	await settle(80)
	check(enemy.position.distance_to(original) > 1.0, "enemy moves along navigable route around cover")
	var ranged = enemy_at(Vector3(-8, 0.1, -3), true)
	ranged.state = ranged.State.CHASE
	ranged.target = player
	ranged.set_physics_process(true)
	var ranged_start: Vector3 = ranged.position
	await settle(80)
	check(ranged.position.distance_to(ranged_start) > 1.0, "ranged enemy also navigates around cover to firing line")

func meshes_under(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		meshes.append_array(meshes_under(child))
	return meshes

func visual_bounds(node: Node, transform: Transform3D = Transform3D.IDENTITY) -> AABB:
	var combined = transform * node.transform if node is Node3D else transform
	var result = combined * node.get_aabb() if node is MeshInstance3D else AABB()
	for child in node.get_children():
		var box = visual_bounds(child, combined)
		if box.size != Vector3.ZERO:
			result = box if result.size == Vector3.ZERO else result.merge(box)
	return result

func collision_nodes_under(node: Node) -> int:
	var count = 1 if node is CollisionObject3D else 0
	for child in node.get_children():
		count += collision_nodes_under(child)
	return count

func test_imported_models() -> void:
	var paths = [
		"res://scenes/weapons/melee_viewmodel.tscn", "res://scenes/weapons/magic_viewmodel.tscn",
		"res://scenes/enemies/melee_enemy.tscn", "res://scenes/enemies/ranged_enemy.tscn",
		"res://scenes/props/torch.tscn", "res://scenes/props/urn.tscn"
	]
	for path in paths:
		var actor = load(path).instantiate()
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		session.run.add_child(actor)
		var visual: Node3D = actor.get_node("VisualRoot")
		check(not actor.use_placeholder and actor.model_scene != null and visual.get_child_count() == 1, "%s uses its imported visual" % actor.name)
		check(collision_nodes_under(visual) == 0, "%s imported visual has no gameplay collision" % actor.name)
		var meshes = meshes_under(visual)
		var textures_ok = not meshes.is_empty()
		for mesh in meshes:
			for surface in range(mesh.mesh.get_surface_count()):
				var material = mesh.get_active_material(surface)
				if not material is BaseMaterial3D or material.albedo_texture == null:
					textures_ok = false
					continue
				for channel in [BaseMaterial3D.TEXTURE_ALBEDO, BaseMaterial3D.TEXTURE_NORMAL, BaseMaterial3D.TEXTURE_METALLIC, BaseMaterial3D.TEXTURE_ROUGHNESS]:
					var texture = material.get_texture(channel)
					if texture != null and (texture.get_width() > 1024 or texture.get_height() > 1024):
						textures_ok = false
		check(textures_ok, "%s materials load with textures within 1024px budget" % actor.name)
		var box = visual_bounds(visual)
		if actor is CharacterBody3D:
			check(absf(box.position.y) < 0.01 and box.size.y > 1.7 and box.size.y < 2.1, "%s feet/height normalized independently of capsule" % actor.name)
		elif actor.get("kind") == 1 and path.contains("urn"):
			check(absf(box.position.y) < 0.01 and absf(box.size.y - 0.8) < 0.02, "urn is ground-aligned and approximately 0.8m tall")
		actor.free()
		var placeholder = load(path).instantiate()
		placeholder.use_placeholder = true
		placeholder.process_mode = Node.PROCESS_MODE_DISABLED
		session.run.add_child(placeholder)
		check(placeholder.get_node("VisualRoot").get_child_count() > 1, "%s can still use procedural placeholders" % placeholder.name)
		placeholder.free()

func melee_fixture() -> void:
	await fresh()
	player.weapons.set_physics_process(false)

func test_melee_cycle() -> void:
	await melee_fixture()
	var weapon = player.weapons
	var enemy = enemy_at(Vector3(0, 0.1, 11.8))
	var contacts: Array = []
	session.run.combat_event.connect(func(event):
		if event.kind == &"enemy_hit": contacts.append(event))
	await settle()
	check(weapon.try_attack() and weapon.phase == weapon.Phase.WINDUP, "accepted melee begins committed windup")
	weapon.advance(0.1)
	check(enemy.health == 68 and contacts.is_empty(), "no damage or confirmed hit during windup")
	player.viewmodels._process(0.0)
	check(player.viewmodels.stage.rotation.z < 0.0, "viewmodel preparation follows authoritative phase")
	var view_camera: Camera3D = player.viewmodels.viewport.get_camera_3d()
	var camera_transform: Transform3D = view_camera.global_transform
	check(view_camera.get_parent() != player.viewmodels.stage, "viewmodel camera is outside the animated weapon root")
	weapon.cooldowns[1] = 0.9
	weapon.select(1)
	weapon.select(0)
	weapon.select(1)
	check(weapon.slot == 0 and weapon.queued_slot == 1, "latest requested switch deferred until recovery")
	weapon.advance(0.12)
	check(enemy.health == 34 and contacts.size() == 1 and contacts[0].amount == 34, "contact phase produces actual damage event once")
	player.viewmodels._process(0.0)
	check(player.viewmodels.stage.rotation.z > 0.0, "visible stroke follows active contact progress")
	check(view_camera.global_transform.is_equal_approx(camera_transform), "weapon movement cannot move the overlay camera and cancel visible swing")
	weapon.advance(0.06)
	check(weapon.phase == weapon.Phase.RECOVERY and contacts.size() == 1, "recovery begins without duplicate contact")
	var late = enemy_at(Vector3(-1, 0.1, 12.2))
	await settle()
	weapon.advance(0.1)
	check(late.health == 68, "enemy entering during recovery is not hit")
	weapon.advance(0.14)
	check(weapon.phase == weapon.Phase.READY and weapon.slot == 1 and weapon.cooldowns[1] > 0.0, "recovery applies switch without resetting magic cooldown")
	check(not weapon.try_attack() and player.mana == 60, "switch itself does not fire or bypass cooldown")

func test_melee_volume() -> void:
	await melee_fixture()
	var weapon = player.weapons
	var right = enemy_at(Vector3(0.85, 0.1, 12.1))
	var left = enemy_at(Vector3(-0.85, 0.1, 12.1))
	var far = enemy_at(Vector3(0, 0.1, 10.5))
	var behind = enemy_at(Vector3(0, 0.1, 15.2))
	await settle()
	check(weapon.query(player.camera.global_position, player.camera.global_position + Vector3.FORWARD * 2.7).is_empty(), "off-center melee fixture misses the old center ray")
	weapon.try_attack()
	weapon.advance(0.52)
	check(right.health == 34 and left.health == 34, "one long tick sweeps multiple off-crosshair targets once each")
	check(far.health == 68 and behind.health == 68, "sweep rejects beyond-reach and behind-player targets")
	right.health = 68
	left.health = 68
	weapon.try_attack()
	for index in range(13):
		weapon.advance(0.04)
	check(right.health == 34 and left.health == 34, "small steps match long-step sweep without duplicate hits")
	weapon.advance(1.0)
	check(right.health == 34 and left.health == 34, "ready/recovery clock alone cannot repeat damage")

func test_melee_occlusion() -> void:
	await melee_fixture()
	var hidden = enemy_at(Vector3(0.85, 0.1, 12.1))
	var exposed = enemy_at(Vector3(-0.85, 0.1, 12.1))
	session.run.solid(Vector3(0.45, 1.4, 13), Vector3(0.6, 2.8, 0.2))
	var walls: Array = []
	session.run.combat_event.connect(func(event):
		if event.kind == &"world_impact": walls.append(event))
	await settle()
	player.weapons.try_attack()
	player.weapons.advance(0.52)
	check(hidden.health == 68 and exposed.health == 34, "corner occlusion rejects hidden target but permits exposed arc hit")
	check(walls.size() == 1, "overlapping wall queries produce one world-contact event per swing")
	await melee_fixture()
	var edge = enemy_at(Vector3(0, 0.1, 10.9))
	await settle()
	player.weapons.try_attack()
	player.weapons.advance(0.52)
	check(edge.health == 68, "query thickness does not extend permitted melee reach")
	check(CombatEvents.apply_hit(player, edge, 1000, player, edge.position, Vector3.UP, &"melee", 5000) == 68, "damage result reports actual remaining health for lethal contact")
	check(CombatEvents.apply_hit(player, edge, 10, player, edge.position, Vector3.UP, &"melee", 5001) == 0, "dead target rejects damage and successful-hit feedback")

func test_melee_lifecycle() -> void:
	await melee_fixture()
	var enemy = enemy_at(Vector3(0, 0.1, 11.8))
	await settle()
	player.weapons.try_attack()
	player.weapons.advance(0.1)
	session.pause_run()
	player.weapons.advance(10.0)
	await settle()
	check(is_equal_approx(player.weapons.elapsed, 0.1) and enemy.health == 68, "pause freezes melee progress and contact history")
	session.resume_run()
	player.weapons.advance(0.12)
	check(enemy.health == 34, "resume continues saved swing without catch-up burst")
	await melee_fixture()
	enemy = enemy_at(Vector3(0, 0.1, 11.8))
	await settle()
	player.weapons.try_attack()
	player.weapons.select(1)
	player.take_damage(1000, null)
	player.weapons.advance(1.0)
	check(enemy.health == 68 and player.weapons.phase == player.weapons.Phase.READY, "death cancels pending melee damage")
	await fresh()
	check(player.weapons.queued_slot == -1 and player.weapons.hit_targets.is_empty(), "fresh run clears queued selection and hit history")

func test_feedback() -> void:
	await melee_fixture()
	var feedback = session.run.feedback
	var enemy = enemy_at(Vector3(0, 0.1, 11.8))
	var other = enemy_at(Vector3(3, 0.1, 11.8))
	await settle()
	var original_material = meshes_under(other.get_node("VisualRoot"))[0].get_active_material(0)
	var original_color: Color = original_material.albedo_color
	player.stats_changed.emit()
	check(session.ui.hit_time == 0.0 and feedback.effects.is_empty(), "HUD refresh is not a combat hit")
	var received: Array = []
	feedback.event_received.connect(func(event): received.append(event))
	player.weapons.try_attack()
	player.weapons.advance(0.1)
	check(session.ui.hit_time == 0.0, "windup/miss presentation does not claim an enemy hit")
	player.weapons.advance(0.12)
	check(session.ui.hit_time > 0.0 and session.ui.hit_marker.visible and feedback.effects.size() == 1, "confirmed enemy damage shows marker and local effect")
	check(original_material.albedo_color == original_color and other.hit_flash == 0.0 and enemy.hit_flash > 0.0, "enemy reaction does not alter another instance's material/state")
	var count: int = feedback.event_counts.get(&"enemy_hit", 0)
	session.run.emit_combat(received[-1].duplicate())
	check(feedback.event_counts[&"enemy_hit"] == count and feedback.effects.size() == 1, "duplicate combat event produces no duplicate marker/effect")
	session.ui.clear_combat_feedback()
	session.run.emit_combat({"kind": &"enemy_hit", "point": Vector3.ZERO, "player_owned": true, "amount": 0})
	check(session.ui.hit_time == 0.0, "rejected damage produces no successful-hit marker")
	for index in range(40):
		session.run.emit_combat({"kind": &"world_impact", "point": Vector3(0, 1, 10), "weapon": &"melee"})
	check(feedback.effects.size() == 24 and session.ui.hit_time == 0.0, "world impacts cap at 24 without false enemy-hit markers")
	var effect = feedback.effects[0]
	var age: float = effect.elapsed
	session.pause_run()
	effect._process(10.0)
	check(effect.elapsed == age, "pause freezes impact lifetime")
	session.resume_run()
	for current in feedback.effects.duplicate():
		current._process(0.5)
	feedback._process(0.0)
	check(feedback.effects.is_empty(), "impact effects expire within half a second")
	player.take_damage(10, null)
	check(session.ui.hurt_time > 0.0 and session.ui.hurt_edges[0].color.a <= 0.181, "player damage gives restrained edge feedback")
	session.finish(true)
	check(session.ui.hurt_time == 0.0 and session.ui.hit_time == 0.0 and feedback.effects.is_empty(), "terminal transition clears transient feedback")
	await fresh()
	check(session.run.feedback.effects.is_empty() and session.ui.hit_time == 0.0 and get_nodes_in_group("combat_effects").is_empty(), "fresh run has no old impact nodes or HUD feedback")

func test_audio() -> void:
	await melee_fixture()
	var audio = session.run.feedback.audio
	var hashes: Dictionary = {}
	for cue in audio.CUE_NAMES:
		var stream: AudioStreamWAV = audio.streams[cue]
		var peak: int = 0
		for index in range(stream.data.size() / 2):
			peak = maxi(peak, absi(stream.data.decode_s16(index * 2)))
		check(stream.format == AudioStreamWAV.FORMAT_16_BITS and not stream.stereo and stream.get_length() > 0.05 and peak > 0 and peak <= 16384, "%s bundled SFX is nonempty mono PCM16 with unclipped headroom" % cue)
		hashes[hash(stream.data)] = true
	check(hashes.size() == audio.CUE_NAMES.size() and AudioServer.get_bus_effect_count(audio.bus_index) == 1, "all bundled cues are distinct with one bounded SFX bus limiter")
	var enemy = enemy_at(Vector3(0, 0.1, 11.8))
	await settle()
	player.weapons.try_attack()
	check(audio.played_counts.get("swing", 0) == 1 and audio.played_counts.get("hit", 0) == 0, "accepted swing sounds before contact without false hit cue")
	check(not player.weapons.try_attack() and audio.played_counts["swing"] == 1, "rejected attack emits no duplicate swing sound")
	player.weapons.advance(0.22)
	check(audio.played_counts.get("hit", 0) == 1 and enemy.health == 34, "confirmed contact emits one enemy impact cue")
	player.weapons.advance(0.3)
	player.weapons.select(1)
	player.mana = 0
	player.weapons.try_attack()
	check(audio.played_counts.get("magic_cast", 0) == 0, "empty staff emits no cast sound")
	var counts: Dictionary = audio.played_counts.duplicate()
	player.stats_changed.emit()
	check(audio.played_counts == counts, "HUD binding/refresh emits no combat sounds")
	for index in range(40):
		session.run.emit_combat({"kind": &"world_impact", "point": Vector3(index * 0.1, 1, 10), "weapon": &"magic"})
	check(audio.voices.size() <= 12, "simultaneous combat audio is bounded to 12 voices")
	var spatial = false
	for record in audio.voices:
		if record.node is AudioStreamPlayer3D:
			spatial = record.node.max_distance == 24.0 and record.node.attenuation_model == AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	check(spatial, "world audio uses finite-range distance attenuation")
	audio._process(2.0)
	counts = audio.played_counts.duplicate()
	await settle()
	check(audio.voices.is_empty() and audio.played_counts == counts, "finished/overloaded cues clean up without queued bursts")
	session.run.emit_combat({"kind": &"magic_cast", "point": player.camera.global_position, "player_owned": true})
	session.pause_run()
	check(audio.voices.is_empty() and session.ui.volume_box.visible, "pause stops one-shots and exposes volume control")
	session.ui.volume_slider.grab_focus()
	var before: float = session.ui.volume_slider.value
	await press_key(KEY_LEFT)
	check(session.ui.volume_slider.value < before and session.state == session.State.PAUSED, "keyboard volume adjustment does not resume or attack")
	await mouse_click_at(session.ui.volume_slider.get_global_rect().get_center())
	check(session.ui.volume_slider.value == 50 and session.state == session.State.PAUSED, "mouse slider interaction adjusts mix without gameplay leakage")
	session.ui.volume_slider.value = 0
	check(session.sfx_volume == 0.0 and AudioServer.is_bus_mute(audio.bus_index), "zero slider value mutes SFX bus")
	session.resume_run()
	check(audio.voices.is_empty(), "resume does not replay stopped cues")
	await melee_fixture()
	audio = session.run.feedback.audio
	enemy = enemy_at(Vector3(0, 0.1, 11.8))
	await settle()
	player.weapons.try_attack()
	player.weapons.advance(0.22)
	check(audio.volume == 0.0 and audio.played_counts.is_empty() and enemy.health == 34 and session.ui.hit_time > 0.0, "mute persists through restart while damage and visual feedback still work")
	session.ui.volume_slider.value = 65
	await fresh()
	check(is_equal_approx(session.run.feedback.audio.volume, 0.65) and get_nodes_in_group("combat_voices").is_empty(), "session volume survives restart without old voice nodes")

func audio_pickup(kind: int, amount: int = 25):
	var pickup = load("res://scenes/props/pickup.tscn").instantiate()
	pickup.kind = kind
	pickup.amount = amount
	pickup.position = Vector3(3, 0.5, 17)
	session.run.add_child(pickup)
	return pickup

func test_pickup_audio() -> void:
	await fresh()
	var audio = session.run.feedback.audio
	var events: Array = []
	session.run.feedback.event_received.connect(func(event):
		if event.kind in [&"pickup_health", &"pickup_mana"]: events.append(event))
	var health = audio_pickup(0)
	check(not health.try_collect(player) and not health.consumed and audio.played_counts.get("pickup_health", 0) == 0, "full health leaves flask available and silent")
	player.health = 97
	check(health.try_collect(player) and player.health == 100 and audio.played_counts.get("pickup_health", 0) == 1, "useful health pickup restores capped health and plays once")
	check(events.size() == 1 and events[0].amount == 3, "health confirmation reports actual capped gain")
	check(audio.voices.size() == 1 and audio.voices[0].node is AudioStreamPlayer, "pickup cue is local and outlives the consumed Area3D")
	health.try_collect(player)
	session.run.emit_combat(events[0].duplicate())
	check(audio.played_counts["pickup_health"] == 1, "consumed pickup and duplicate event cannot replay cue")
	check(session.ui.hit_time == 0.0 and session.run.feedback.effects.is_empty(), "pickup does not create enemy-hit feedback or damage effects")
	var mana = audio_pickup(1)
	check(not mana.try_collect(player) and audio.played_counts.get("pickup_mana", 0) == 0, "full arcana remains silent")
	check(not mana.try_collect(get_nodes_in_group("enemies")[0]) and not mana.consumed, "enemy cannot collect or sound a resource pickup")
	player.mana = 7
	session.pause_run()
	check(not mana.try_collect(player) and player.mana == 7 and audio.played_counts.get("pickup_mana", 0) == 0, "paused player cannot restore arcana or trigger its cue")
	session.resume_run()
	check(mana.try_collect(player) and player.mana == 32 and audio.played_counts.get("pickup_mana", 0) == 1, "useful arcana pickup restores resource and emits distinct cue")
	var capped = audio_pickup(1)
	player.mana = 57
	check(capped.try_collect(player) and player.mana == 60 and events[-1].amount == 3 and audio.played_counts["pickup_mana"] == 2, "partial arcana restoration reports capped amount and sounds once")
	var invalid = audio_pickup(0, 0)
	player.health = 90
	check(not invalid.try_collect(player) and not invalid.consumed and audio.played_counts["pickup_health"] == 1, "zero-gain pickup remains unconsumed and silent")
	var pending = audio_pickup(0)
	player.health = 0
	check(not pending.try_collect(player) and not pending.consumed and audio.played_counts["pickup_health"] == 1, "dead player cannot collect or trigger pickup cue")
	player.health = 90
	session.pause_run()
	session.ui.volume_slider.value = 0
	session.resume_run()
	check(pending.try_collect(player) and player.health == 100 and audio.played_counts["pickup_health"] == 1 and audio.voices.is_empty(), "muted health pickup still restores without audio or delayed playback")
	session.ui.volume_slider.value = 65
	var before: Dictionary = audio.played_counts.duplicate()
	var key = audio_pickup(2)
	check(key.try_collect(player) and audio.played_counts == before, "key collection audio remains unchanged")
	await fresh()
	check(session.run.feedback.audio.played_counts.is_empty() and get_nodes_in_group("combat_voices").is_empty(), "restart removes pickup voices and does not replay confirmations")

func test_encounter_tuning() -> void:
	await fresh()
	var melee_count = 0
	var ranged_count = 0
	for enemy in get_nodes_in_group("enemies"):
		if enemy.archetype == 0:
			melee_count += 1
			check(enemy.max_health == 68 and enemy.attack_damage == 12 and enemy.windup_duration == 0.55, "melee encounter stats unchanged")
		else:
			ranged_count += 1
			check(enemy.max_health == 56 and enemy.attack_damage == 12 and enemy.windup_duration == 0.8, "ranged encounter stats unchanged")
		enemy.set_physics_process(true)
	await settle(90)
	var idle = true
	for enemy in get_nodes_in_group("enemies"):
		idle = idle and enemy.state == enemy.State.IDLE
		enemy.set_physics_process(false)
	check(melee_count == 4 and ranged_count == 2 and idle and player.health == 100, "revised packs keep six actors and safe idle spawn")
	var pickup_counts = [0, 0, 0]
	for pickup in get_nodes_in_group("pickups"):
		pickup_counts[pickup.kind] += 1
	check(pickup_counts == [3, 3, 1], "revised level retains three health, three mana and one key")
	var attacker = enemy_at(Vector3(0, 0.1, 12.5))
	await settle()
	attacker.state = attacker.State.ATTACK
	attacker.windup = 0.4
	attacker.cooldown = 0.2
	attacker.take_damage(1, player)
	attacker.take_damage(1, player)
	check(attacker.state == attacker.State.ATTACK and attacker.windup == 0.4 and attacker.cooldown == 0.2 and attacker.hit_flash > 0.0, "nonlethal hit reactions preserve committed windup and cooldown")
	attacker._physics_process(0.41)
	check(player.health == 88 and attacker.cooldown > 0.0, "damaged enemy completes original attack once instead of being stun-locked")

func scene_count(node: Node, path: String) -> int:
	var count = 1 if node.scene_file_path == path else 0
	for child in node.get_children():
		count += scene_count(child, path)
	return count

func test_atmosphere() -> void:
	await fresh()
	var level = session.run
	var baseline: Dictionary = load("res://resources/atmosphere_baseline.tres").get_meta("snapshot")
	check(WorldFingerprint.snapshot(level) == baseline, "atmosphere preserves recorded collider, placement, stat and navigation fingerprints")
	var presentation = level.presentation
	check(collision_nodes_under(presentation) == 0, "all new dressing is visual-only with no collision objects")
	check(scene_count(level, "res://scenes/props/urn.tscn") == 10 and scene_count(level, "res://scenes/props/torch.tscn") == 6, "dressing uses ten reused urns and exactly six original torches")
	for family in [&"wall", &"floor", &"trim"]:
		var material = presentation.surface(family, &"court")
		check(material == presentation.surface(family, &"court"), "%s materials are shared rather than duplicated per block" % family)
		check(material.albedo_texture.get_width() == 512 and material.roughness_texture.get_width() == 512 and material.uv1_triplanar and material.uv1_world_triplanar and material.uv1_scale == Vector3.ONE * 0.5, "%s uses bundled 512px maps at shared two-meter world scale" % family)
	check(presentation.surface(&"brass", &"crypt") == presentation.surface(&"brass", &"court"), "solid accents reuse materials across areas (%d cached world material variants)" % presentation.materials.size())
	var view_environment: WorldEnvironment
	for node in player.viewmodels.viewport.get_children():
		if node is WorldEnvironment:
			view_environment = node
	check(is_equal_approx(view_environment.environment.ambient_light_energy, 0.85), "world mood does not change isolated weapon lighting")
	var bounded = true
	for frame in range(240):
		presentation.set_clock(frame * 0.1)
		for index in range(presentation.torches.size()):
			var light: OmniLight3D = presentation.torches[index]
			bounded = bounded and light.light_energy >= presentation.torch_bases[index] * 0.92 - 0.0001 and light.light_energy <= presentation.torch_bases[index] * 1.08 + 0.0001
			bounded = bounded and light.omni_range == 7.0 and not light.shadow_enabled
	check(bounded and presentation.torches.size() == 6, "slow deterministic flicker remains within eight-percent energy bounds without range/shadow changes")
	var clock: float = presentation.elapsed
	var energy: float = presentation.torches[0].light_energy
	session.pause_run()
	presentation.advance(10.0)
	await settle()
	check(presentation.elapsed == clock and presentation.torches[0].light_energy == energy, "pause freezes lighting time and output")
	session.resume_run()
	presentation.advance(0.1)
	check(is_equal_approx(presentation.elapsed, clock + 0.1), "resume advances lighting without catch-up")
	await fresh()
	check(session.run.presentation.elapsed == 0.0 and session.run.presentation.torches.size() == 6, "fresh run resets deterministic torch phases without extra lights")
	session.atmosphere_enabled = false
	await fresh()
	check(session.run.presentation == null and session.run.ambience == null and WorldFingerprint.snapshot(session.run) == baseline, "developer fallback restores flat/static world with identical gameplay and no ambience")
	session.atmosphere_enabled = true
	await fresh()
	check(WorldFingerprint.snapshot(session.run) == baseline, "repeated atmosphere-enabled runs preserve the baseline without accumulating gameplay nodes")
	var authoring = Node3D.new()
	authoring.set_script(load("res://scripts/level.gd"))
	authoring.build_geometry()
	authoring.remove_child(authoring.geometry)
	root.add_child(authoring.geometry)
	var navigation: NavigationMesh = authoring.bake_navigation()
	check(authoring.player == null and authoring.ambience == null and authoring.presentation == null and navigation.get_polygon_count() > 0, "geometry-only navigation authoring needs neither player nor ambience and saves no new navmesh")
	authoring.geometry.free()
	authoring.free()

func test_ambience() -> void:
	await fresh()
	var ambience = session.run.ambience
	check(ambience.players.size() == 2 and get_nodes_in_group("ambience_players").size() == 2 and ambience.start_count == 1, "active run creates and starts exactly two reusable ambience players")
	for voice in ambience.players:
		var stream: AudioStreamWAV = voice.stream
		check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_begin == 0 and stream.loop_end > 0 and is_equal_approx(stream.get_length(), 20.0) and stream.format == AudioStreamWAV.FORMAT_16_BITS, "%s has bundled 20-second PCM16 forward-loop metadata" % voice.name)
	var ids = [ambience.players[0].get_instance_id(), ambience.players[1].get_instance_id()]
	player.position = Vector3(20, 0.1, -7)
	ambience.advance(0.4)
	check(is_equal_approx(ambience.blend, 0.4) and is_equal_approx(db_to_linear(ambience.players[0].volume_db) + db_to_linear(ambience.players[1].volume_db), 1.0), "crypt doorway produces smooth bounded complementary ambience weights")
	ambience.advance(0.6)
	check(ambience.blend == 1.0, "crypt transition completes in approximately one second")
	player.position = Vector3(0, 0.1, 3)
	ambience.advance(0.25)
	check(is_equal_approx(ambience.blend, 0.75) and ambience.start_count == 1 and ids == [ambience.players[0].get_instance_id(), ambience.players[1].get_instance_id()], "recrossing the boundary reverses blend without restarting or adding players")
	check(session.run.feedback.audio.voices.is_empty() and session.run.feedback.audio.played_counts.is_empty(), "ambience does not consume combat voice slots or synthesize SFX events")
	session.pause_run()
	# Let a last backend mix buffer settle before checking an already-paused playhead.
	await create_timer(0.2).timeout
	var position: float = ambience.players[0].get_playback_position()
	var blend: float = ambience.blend
	ambience.advance(10.0)
	await settle(6)
	check(ambience.paused and ambience.players[0].stream_paused and ambience.blend == blend and absf(ambience.players[0].get_playback_position() - position) < 0.001, "pause freezes ambience blend and playback position")
	var sfx: float = session.sfx_volume
	session.ui.ambience_slider.grab_focus()
	var original: float = session.ui.ambience_slider.value
	await press_key(KEY_LEFT)
	check(session.ui.ambience_slider.value < original and session.sfx_volume == sfx and session.state == session.State.PAUSED, "ambience slider keyboard input is independent and cannot resume/attack")
	await mouse_click_at(session.ui.ambience_slider.get_global_rect().get_center())
	check(session.ui.ambience_slider.value == 50 and session.sfx_volume == sfx and session.state == session.State.PAUSED, "mouse ambience control is independent and does not resume gameplay")
	var independent: float = session.ambience_volume
	session.ui.volume_slider.value = 50
	check(session.ambience_volume == independent and ambience.volume == independent, "changing SFX volume cannot change ambience volume")
	session.ui.volume_slider.value = sfx * 100
	session.ui.ambience_slider.value = 0
	check(AudioServer.is_bus_mute(ambience.bus_index) and session.sfx_volume == sfx and not AudioServer.is_bus_mute(session.run.feedback.audio.bus_index), "ambience mute leaves accepted SFX volume/bus unchanged")
	session.resume_run()
	check(not ambience.paused and ambience.start_count == 1, "resume continues existing loops without layering")
	await fresh()
	ambience = session.run.ambience
	check(ambience.volume == 0.0 and session.sfx_volume == sfx and get_nodes_in_group("ambience_players").size() == 2, "independent ambience mute persists across fresh runs without old players")
	player.weapons.select(1)
	check(player.weapons.try_attack() and session.run.feedback.audio.played_counts.get("magic_cast", 0) == 1, "combat SFX still play while ambience is muted")
	session.finish(true)
	check(not ambience.running and not ambience.players[0].playing and not ambience.players[1].playing, "victory stops both ambience loops")
	session.ui.ambience_slider.value = 30
	await fresh()
	player.take_damage(1000, null)
	check(not session.run.ambience.running and not session.run.ambience.players[0].playing, "defeat also stops ambience immediately")
	session.show_menu()
	await settle()
	check(get_nodes_in_group("ambience_players").is_empty(), "menu return frees all old ambience players")
	await fresh()
	check(is_equal_approx(session.run.ambience.volume, 0.3) and session.run.ambience.blend == 0.0 and session.run.ambience.start_count == 1, "new run resets phase/blend and applies retained ambience volume before playback")
