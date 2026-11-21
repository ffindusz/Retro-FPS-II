extends SceneTree
## Fire Bat behaviour in the Mapping Example, plus its editor placement validation.

const BUILDER = preload("res://addons/cinderkeep_level_tools/level_builder.gd")
const PLACEMENT = preload("res://scripts/levels/level_placement.gd")
var checks: int = 0
var failures: int = 0
var session

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

func bats() -> Array:
	return get_nodes_in_group("enemies").filter(func(enemy): return enemy.archetype == 2)

func start() -> Array:
	session._on_command("Mapping Example")
	var level = session.run
	level.player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(enemy.archetype == 2)
	await settle()
	# Navigation regions synchronize asynchronously; wait until the map answers queries.
	var map = level.get_world_3d().navigation_map
	for attempt in range(120):
		if NavigationServer3D.map_get_iteration_id(map) > 0:
			break
		await settle(1)
	return [level, level.player, bats()[0]]

func run_tests() -> void:
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	var started = await start()
	var level = started[0]
	var player: DemoPlayer = started[1]
	var bat = started[2]
	check(bats().size() == 1 and get_nodes_in_group("enemies").size() == 4, "Mapping Example spawns one Fire Bat beside its three ground enemies")
	check(bat.max_health == 30 and bat.health == 30 and bat.attack_damage == 7, "bat has its own light health and fireball damage")
	check(Vector2(bat.position.x, bat.position.z).distance_to(Vector2(3, -3)) < 0.05 and absf(bat.position.y - 2.4) < 0.2, "bat spawns at hover height above its marker")
	var look = bat.presentation
	check(look != null and look.has_clips() and look.player.current_animation == "fly", "bat uses the animated Meshy model with fly, attack, hit and death clips")
	check(look.player.get_animation(&"fly").loop_mode == Animation.LOOP_LINEAR and look.player.get_animation(&"death").loop_mode == Animation.LOOP_NONE, "fly loops and death plays once")
	var skeleton: Skeleton3D = look.find_children("*", "Skeleton3D", true, false)[0]
	var wing_bone := skeleton.find_bone("wing_1.L")
	var wing_start: Quaternion = skeleton.get_bone_pose_rotation(wing_bone)
	await settle(40)
	check(bat.state == bat.State.IDLE and absf(bat.global_position.y - 2.4) < 0.3, "out of range the bat idles in the air near its hover height")
	check(wing_bone >= 0 and not skeleton.get_bone_pose_rotation(wing_bone).is_equal_approx(wing_start), "rigged wings flap while hovering")
	var placeholder = load("res://scenes/enemies/bat_enemy.tscn").instantiate()
	placeholder.use_placeholder = true
	placeholder.position = Vector3(0, 2.4, 10)
	level.add_child(placeholder)
	check(placeholder.presentation == null and placeholder.wings.size() == 2, "placeholder fallback still builds a bat with two wings")
	placeholder.free()

	player.global_position = Vector3(3, 0.1, 5)
	bat.cooldown = 10.0
	await settle(60)
	check(bat.state == bat.State.CHASE and absf(bat.global_position.y - 2.4) < 0.4, "bat engages a visible player and keeps its altitude")

	player.global_position = bat.global_position + Vector3(0, -2.3, 1.5)
	var close: float = Vector2(bat.global_position.x - player.global_position.x, bat.global_position.z - player.global_position.z).length()
	await settle(40)
	var after: float = Vector2(bat.global_position.x - player.global_position.x, bat.global_position.z - player.global_position.z).length()
	check(after > close + 0.5, "bat backs away from a player who closes in (%.2f -> %.2f m)" % [close, after])

	player.global_position = Vector3(bat.global_position.x, 0.1, bat.global_position.z + 7.0)
	await settle(2)
	bat.cooldown = 0.0
	var fired := false
	var attack_clip := false
	for frame in range(60):
		await settle(1)
		attack_clip = attack_clip or look.player.current_animation == "attack"
		if not get_nodes_in_group("projectiles").is_empty():
			fired = true
			break
	check(fired, "bat fires a fireball after its windup")
	check(attack_clip, "the attack clip plays during the fireball windup")
	var hurt := false
	for frame in range(90):
		await settle(1)
		if player.health < 100:
			hurt = true
			break
	check(hurt and player.health == 93, "fireball damages the player by 7")

	var wall = level.solid(Vector3(bat.global_position.x, 2.0, bat.global_position.z + 3.0), Vector3(6, 4, 0.4))
	await settle(2)
	bat.state = bat.State.CHASE
	bat.cooldown = 0.0
	for bolt in get_nodes_in_group("projectiles"):
		bolt.free()
	await settle(60)
	check(get_nodes_in_group("projectiles").is_empty() and bat.state != bat.State.ATTACK, "bat holds fire without line of sight")
	wall.free()

	var height: float = bat.global_position.y
	var spot: Vector3 = bat.global_position
	session.pause_run()
	await settle(20)
	check(bat.global_position == spot and bat.global_position.y == height, "pause freezes the bat in the air")
	session.resume_run()

	await settle(30)
	check(bat.take_damage(5, player) == 5 and look.player.current_animation in ["hit", "attack"], "a non-lethal hit plays the hit clip unless the bat is mid-attack")
	var died := [false]
	bat.died.connect(func() -> void: died[0] = true)
	check(bat.take_damage(1000, player) == 25 and died[0] and bat.state == bat.State.DEAD, "lethal damage kills the bat and emits died")
	check(look.dead and look.player.current_animation == "death", "the death clip plays")
	await settle(90)
	check(bat.collision_layer == 0 and bat.global_position.y < 0.7, "dead bat stops taking hits and drops to the floor")
	var bolt_count = get_nodes_in_group("projectiles").size()
	await settle(60)
	check(get_nodes_in_group("projectiles").size() <= bolt_count, "dead bat fires no more fireballs")

	session._on_command("Restart")
	await settle()
	var fresh = bats()
	check(fresh.size() == 1 and fresh[0].health == 30 and fresh[0].state == fresh[0].State.IDLE and absf(fresh[0].position.y - 2.4) < 0.2, "restart recreates a living bat at hover height")

	var source = load("res://scenes/authoring/mapping_example.tscn").instantiate()
	root.add_child(source)
	var marker = source.get_node("Placements/CourtyardBat")
	check(marker.kind == PLACEMENT.Kind.BAT and PLACEMENT.Kind.BAT == 13 and PLACEMENT.LABELS[13] == "Fire Bat", "Fire Bat is appended as placement kind 13")
	marker.position = Vector3(7.8, 0, 3)
	var result: Dictionary = await BUILDER.build(source, self, false)
	var codes: Array = result.issues.map(func(issue): return issue.code)
	check(not result.ok and codes.has("hover_clearance") and not codes.has("overlap"), "builder rejects a bat whose wings would touch a wall")
	marker.position = Vector3(3, 0, -3)
	result = await BUILDER.build(source, self, false)
	check(result.ok, "builder accepts the courtyard bat")
	source.queue_free()

	session.show_menu()
	session.queue_free()
	await settle(10)
	# Let freed runs, builder viewports and audio release their resources before quitting.
	await create_timer(0.3).timeout
	print("\nRESULT: %d bat checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
