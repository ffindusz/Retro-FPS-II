extends SceneTree
## The Golem Sanctum in The Ossuary: bone seal, dormant stone golem, boss bar, slam, held key,
## statues, exit gate, restart, and the new placement kinds in the builder.

const BUILDER = preload("res://addons/cinderkeep_level_tools/level_builder.gd")
const PLACEMENT = preload("res://scripts/levels/level_placement.gd")
const CENTER := Vector3(0, 0, -23)
var checks: int = 0
var failures: int = 0
var session
var level
var player: DemoPlayer
var golem
var seal

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func settle(frames: int = 4) -> void:
	for frame in range(frames):
		await physics_frame
	await process_frame

func only_active(actor: Node) -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(enemy == actor)

func put_player(point: Vector3) -> void:
	player.global_position = point + Vector3.UP * 0.1
	player.velocity = Vector3.ZERO

func start() -> void:
	session._on_command("The Ossuary")
	level = session.run
	player = level.player
	player.set_physics_process(false)
	only_active(null)
	golem = get_first_node_in_group("bosses")
	seal = get_first_node_in_group("bone_seals")
	await settle()
	var map = level.get_world_3d().navigation_map
	for attempt in range(120):
		if NavigationServer3D.map_get_iteration_id(map) > 0:
			break
		await settle(1)

func key_pickup() -> Node:
	for pickup in get_nodes_in_group("pickups"):
		if pickup.kind == 2 and level.is_ancestor_of(pickup):
			return pickup
	return null

func ray_hits_world(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	return not level.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func kill_skeletons(leave: int = 0) -> void:
	var skeletons: Array = get_nodes_in_group("enemies").filter(func(enemy): return enemy != golem and enemy.state != enemy.State.DEAD)
	for index in range(skeletons.size() - leave):
		skeletons[index].take_damage(1000, player)
	await settle(2)

func run_tests() -> void:
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	check(PLACEMENT.Kind.BONE_SEAL == 16 and PLACEMENT.Kind.STONE_GOLEM == 17 and PLACEMENT.Kind.GOLEM_STATUE == 18 and PLACEMENT.LABELS.slice(16) == ["Bone Seal", "Stone Golem", "Golem Statue"], "new kinds are appended as 16, 17 and 18")
	await start()

	# Layout.
	check(golem != null and get_nodes_in_group("bosses").size() == 1 and golem.species == &"stone_golem", "The Ossuary has one stone golem")
	check(golem.global_position.distance_to(CENTER + Vector3(0, 0.45, 0)) < 0.05, "the golem stands on top of the dais in the middle of the sanctum")
	check(golem.max_health == 420 and golem.attack_damage == 24 and is_equal_approx(golem.melee_range, 3.0), "golem boss stats")
	var statues: Array = level.get_children().filter(func(node): return node.get_script() == load("res://scripts/props/golem_statue.gd"))
	check(statues.size() == 4 and statues.all(func(statue): return statue.find_children("*", "StaticBody3D", true, false).size() == 1), "four golem statues with collision decorate the sanctum")
	check(statues.map(func(statue): return statue.pose) == [0, 1, 2, 3], "each statue holds a different pose")
	var lights: Array = level.find_children("*", "", true, false).filter(func(node): return node is LightFixture and node.global_position.distance_to(CENTER) < 7.5)
	check(lights.size() == 8, "the sanctum is lit by braziers, wall lanterns and crystal lamps (%d)" % lights.size())

	# Dormant statue.
	var look = golem.presentation
	check(golem.dormant and look.dormant and look.eye_glow() < 0.01 and not look.eye_light.visible, "the golem starts dormant with dark eyes")
	check(not golem.is_in_group("active_bosses") and not session.ui.boss_box.visible, "no boss bar while the golem sleeps")

	# The key is held by the golem.
	var key := key_pickup()
	check(key != null and golem.held_key == key and not key.visible and not key.monitoring, "the ember key is hidden inside the golem")
	put_player(key.global_position)
	await settle(4)
	check(not player.has_key, "the hidden key cannot be collected")

	# Bone seal blocks the doorway until every skeleton is dead.
	check(seal != null and seal.guards.size() == 6 and not seal.is_open, "the bone seal is closed and tied to all six skeletons")
	check(ray_hits_world(Vector3(0, 1.5, -15.0), Vector3(0, 1.5, -18.0)), "the closed seal blocks the doorway")
	await kill_skeletons(1)
	check(not seal.is_open, "the seal holds while one skeleton still walks")
	put_player(Vector3(0, 0, -14.8))
	await settle(2)
	check(golem.dormant, "the golem does not wake through the closed seal")
	await kill_skeletons()
	await settle(2)
	check(seal.is_open and not ray_hits_world(Vector3(0, 1.5, -15.0), Vector3(0, 1.5, -18.0)), "the seal opens when the last skeleton dies")

	# Dormant until the player is near.
	only_active(golem)
	put_player(Vector3(0, 0, -14.6))
	var native: float = look.native_time
	await settle(20)
	check(golem.dormant and look.native_time == native and golem.global_position.distance_to(CENTER + Vector3(0, 0.45, 0)) < 0.05, "out of range the golem stays a motionless statue")
	var messages: Array = []
	player.message.connect(func(text): messages.append(text))
	put_player(CENTER + Vector3(0, 0, 5.5))
	await settle(3)
	check(not golem.dormant and golem.awakening > 0.0 and messages.has(golem.WAKE_TEXT), "coming close wakes the golem")
	await settle(2)
	check(session.ui.boss_box.visible and session.ui.boss_label.text == "STONE GOLEM" and session.ui.boss_bar.value == 420, "the boss bar shows the golem's name and health")
	var paused_wake: float = golem.awakening
	session.pause_run()
	await settle(10)
	check(golem.awakening == paused_wake, "pause freezes the awakening")
	session.resume_run()
	for frame in range(150):
		await settle(1)
		if golem.awakening == 0.0:
			break
	await settle(3)
	check(golem.state == golem.State.CHASE and look.eye_glow() > 3.0 and look.eye_light.visible, "after waking the golem hunts with glowing eyes")

	# It walks down the dais steps toward the player.
	put_player(CENTER + Vector3(0, 0, 6.6))
	golem.cooldown = 10.0
	var walked := false
	for frame in range(240):
		await settle(1)
		walked = walked or look.player.current_animation == "walk"
		if golem.global_position.y < 0.05 and golem.global_position.z > CENTER.z + 3.4:
			break
	check(walked and golem.global_position.y < 0.05 and golem.global_position.z > CENTER.z + 3.4, "the golem walks down off its dais")

	# Slam: hits within 3 m after a long windup.
	golem.cooldown = 0.0
	var windup_seen := false
	var hurt := false
	for frame in range(200):
		await settle(1)
		windup_seen = windup_seen or golem.state == golem.State.ATTACK
		if player.health < 100:
			hurt = true
			break
	check(windup_seen and hurt and player.health == 76, "the hammer slam hits for 24")
	check(look.player.current_animation == "attack", "the slam plays the attack clip")
	# Stepping out of reach during the windup avoids the slam.
	player.health = 100
	golem.cooldown = 0.0
	for frame in range(120):
		await settle(1)
		if golem.state == golem.State.ATTACK:
			break
	var away: Vector3 = golem.global_position + golem.global_position.direction_to(player.global_position) * 4.2
	away.y = 0.0
	put_player(away)
	for frame in range(90):
		await settle(1)
		if golem.state != golem.State.ATTACK:
			break
	check(player.health == 100, "stepping out of reach during the windup dodges the slam")

	# Damage, death, key.
	only_active(null)
	golem.take_damage(100, player)
	await settle(2)
	check(golem.health == 320 and session.ui.boss_bar.value == 320, "the boss bar follows the golem's health")
	only_active(golem)
	golem.take_damage(1000, player)
	await settle(2)
	check(golem.state == golem.State.DEAD and look.player.current_animation == "death" and session.ui.boss_bar.value == 0, "the golem dies and its bar empties")
	check(not key.visible, "the key appears only after a short delay")
	await create_timer(1.3).timeout
	check(key.visible and key.monitoring and Vector2(key.global_position.x, key.global_position.z).distance_to(Vector2(golem.global_position.x, golem.global_position.z)) < 0.05, "the key is revealed where the golem fell")
	check(messages.has(golem.KEY_TEXT), "the player is told the key is free")
	await create_timer(1.6).timeout
	check(not session.ui.boss_box.visible, "the boss bar goes away after the fight")
	put_player(key.global_position - Vector3.UP * 0.25)
	await settle(6)
	check(player.has_key, "the player picks up the revealed key")

	# Exit gate on the far wall.
	var won := [false]
	level.completed.connect(func() -> void: won[0] = true)
	put_player(level.exit_position + Vector3(0, 0, 1.5))
	player.camera.look_at(level.exit_position + Vector3.UP * 1.5, Vector3.UP)
	await settle(2)
	check(level.interact_exit() and won[0], "with the key, the sanctum gate ends the run")

	# The player can climb the dais.
	session._on_command("Restart")
	await start()
	player.set_physics_process(true)
	put_player(CENTER + Vector3(2.5, 0, 4.0))
	for frame in range(120):
		player.move_player(Vector2(0, -1), 1.0 / 60.0, false)
		player.look_at(Vector3(CENTER.x, player.global_position.y, CENTER.z), Vector3.UP)
		await physics_frame
	player.set_physics_process(false)
	check(player.global_position.y > 0.4, "the player can walk up the dais steps (y %.2f)" % player.global_position.y)

	# Restart restores the sealed, dormant sanctum; hitting the golem from afar wakes it.
	check(golem.dormant and not seal.is_open and not key_pickup().visible and not session.ui.boss_box.visible, "restart restores the closed seal, the dormant golem and the hidden key")
	golem.take_damage(28, player)
	check(not golem.dormant and golem.health == 392, "a hit wakes the golem even from afar")

	# Builder.
	var source = load("res://scenes/authoring/ossuary.tscn").instantiate()
	root.add_child(source)
	var result: Dictionary = await BUILDER.build(source, self, false)
	check(result.ok, "builder accepts The Ossuary with its sanctum")
	var marker = source.get_node("Placements/StoneGolem")
	marker.position = CENTER + Vector3(0, 0, -6.4)
	result = await BUILDER.build(source, self, false)
	var codes: Array = result.issues.map(func(issue): return issue.code)
	check(not result.ok and codes.has("overlap"), "builder rejects a golem pushed into the sanctum wall")
	source.queue_free()

	session.show_menu()
	session.queue_free()
	await settle(10)
	await create_timer(0.3).timeout
	print("\nRESULT: %d golem checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
