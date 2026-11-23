extends SceneTree
## Skeleton warrior and archer behaviour in The Ossuary, plus their editor placement and the map.

const BUILDER = preload("res://addons/cinderkeep_level_tools/level_builder.gd")
const PLACEMENT = preload("res://scripts/levels/level_placement.gd")
const CATALOG = preload("res://scripts/levels/built_level_catalog.gd")
var checks: int = 0
var failures: int = 0
var session
var level

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

func of_species(name: StringName) -> Array:
	return get_nodes_in_group("enemies").filter(func(enemy): return enemy.species == name)

func at_marker(label: String) -> Node:
	var marker: Node3D = level.get_node("Placements/" + label)
	for enemy in get_nodes_in_group("enemies"):
		if Vector2(enemy.position.x, enemy.position.z).distance_to(Vector2(marker.position.x, marker.position.z)) < 0.3:
			return enemy
	return null

func only_active(actor: Node) -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(enemy == actor)

func start() -> void:
	session._on_command("The Ossuary")
	level = session.run
	level.player.set_physics_process(false)
	only_active(null)
	await settle()
	# Navigation regions synchronize asynchronously; wait until the map answers queries.
	var map = level.get_world_3d().navigation_map
	for attempt in range(120):
		if NavigationServer3D.map_get_iteration_id(map) > 0:
			break
		await settle(1)

func run_tests() -> void:
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	check(session.ui.buttons.get_children().any(func(button): return button.text == "The Ossuary"), "main menu offers The Ossuary")
	check(CATALOG.entries().any(func(entry): return entry.path == "res://scenes/levels/generated/ossuary.tscn" and entry.title == "The Ossuary"), "Choose Level lists The Ossuary")
	await start()
	var player: DemoPlayer = level.player
	var warriors := of_species(&"skeleton")
	var archers := of_species(&"skeleton_archer")
	check(warriors.size() == 3 and archers.size() == 3 and get_nodes_in_group("enemies").size() == 6, "The Ossuary spawns three skeleton warriors and three archers")
	check(level.exit_position.distance_to(Vector3(3, 0, -12.7)) < 0.05, "the Ossuary's exit gate is at the north end of the gallery")
	var warrior = at_marker("GallerySkeleton")
	var archer = at_marker("NorthArcher")
	check(warrior.archetype == 0 and warrior.max_health == 48 and warrior.attack_damage == 11, "skeleton warrior uses the melee AI with its own stats")
	check(archer.archetype == 1 and archer.max_health == 40 and archer.attack_damage == 9 and archer.projectile_style == &"arrow", "skeleton archer uses the ranged AI and shoots arrows")
	var look = warrior.presentation
	var bow = archer.presentation
	check(look != null and look.has_clips() and bow != null and bow.has_clips(), "both skeletons load all of their clips")
	check(look.player.current_animation == "idle" and bow.player.current_animation == "idle", "unalerted skeletons play their idle clip")
	check(bow.clips[&"Attack"] == &"aim_idle" and is_equal_approx(bow.attack_release, 4.5), "the archer's attack uses the bow draw from aim_idle")
	check(is_equal_approx(look.holder.rotation.y, PI + deg_to_rad(30.0)), "idle stance is turned back so the skull faces forward")

	# Eyes: bright, pulsing, own light that the level presentation leaves alone.
	var glow_a: float = look.eye_glow()
	await settle(20)
	var glow_b: float = look.eye_glow()
	check(look.eyes != null and glow_a > 3.0 and glow_b > 3.0 and not is_equal_approx(glow_a, glow_b), "red eyes glow brightly and pulse (%.2f -> %.2f)" % [glow_a, glow_b])
	check(look.eye_light.is_in_group(&"actor_lights") and is_equal_approx(look.eye_light.light_color.r, 1.0) and look.eye_light.omni_range < 0.5, "eye light stays a small red light")
	check(warrior.find_children("*", "FlameVisual", true, false).is_empty() and archer.find_children("*", "FlameVisual", true, false).is_empty(), "no torch flame is attached to the skeletons")

	# Warrior runs at a visible player, then slashes.
	only_active(warrior)
	player.global_position = Vector3(-1.5, 0.1, 6)
	var running := false
	for frame in range(60):
		await settle(1)
		running = running or look.player.current_animation == "run"
	check(warrior.state != warrior.State.IDLE and running, "warrior notices the player and runs")
	player.global_position = warrior.global_position + (warrior.global_position.direction_to(player.global_position) * 1.4)
	player.global_position.y = 0.1
	warrior.cooldown = 0.0
	var attacked := false
	var hurt := false
	for frame in range(120):
		await settle(1)
		attacked = attacked or look.player.current_animation == "attack"
		if player.health < 100:
			hurt = true
			break
	check(attacked and hurt and player.health == 89, "warrior's sword slash hits for 11")
	only_active(null)
	warrior.state = warrior.State.IDLE

	# Archer: walks toward a far player, then draws and shoots an arrow.
	player.health = 100
	only_active(archer)
	player.global_position = Vector3(-1.5, 0.1, -0.5)
	archer.state = archer.State.CHASE
	archer.cooldown = 10.0
	archer.target = player
	var walking := false
	for frame in range(40):
		await settle(1)
		walking = walking or bow.player.current_animation == "walk"
	check(walking, "archer walks (not runs) at its slower speed")
	player.global_position = Vector3(archer.global_position.x, 0.1, archer.global_position.z + 7.0)
	var shots_before: int = level.feedback.event_counts.get(&"enemy_shot", 0)
	var casts_before: int = level.feedback.event_counts.get(&"enemy_cast", 0)
	var lights_before: int = level.feedback.spell_lights.size()
	archer.cooldown = 0.0
	var arrow: Node3D = null
	var drew := false
	for frame in range(90):
		await settle(1)
		drew = drew or bow.player.current_animation == "aim_idle"
		var flying := get_nodes_in_group("projectiles")
		if not flying.is_empty():
			arrow = flying[0]
			break
	check(drew and arrow != null and arrow.style == &"arrow", "archer draws its bow and looses an arrow")
	check(arrow != null and arrow.find_children("*", "OmniLight3D", true, false).is_empty() and level.feedback.spell_lights.size() == lights_before, "arrows carry no spell light")
	check(arrow != null and (-arrow.global_basis.z).dot(arrow.direction) > 0.99, "the arrow points along its flight")
	check(level.feedback.event_counts.get(&"enemy_shot", 0) == shots_before + 1 and level.feedback.event_counts.get(&"enemy_cast", 0) == casts_before, "the shot uses the bow event, not the magic cast")
	var hit := false
	for frame in range(90):
		await settle(1)
		if player.health < 100:
			hit = true
			break
	check(hit and player.health == 91, "arrow hits the player for 9")

	var wall = level.solid(Vector3(archer.global_position.x, 1.5, archer.global_position.z + 3.0), Vector3(6, 3, 0.4))
	await settle(2)
	archer.cooldown = 0.0
	archer.state = archer.State.CHASE
	for bolt in get_nodes_in_group("projectiles"):
		bolt.free()
	await settle(60)
	check(get_nodes_in_group("projectiles").is_empty() and archer.state != archer.State.ATTACK, "archer holds its shot without line of sight")
	wall.free()

	# A miss into a wall reports an arrow impact (wall sound, not the magic impact).
	var impacts: Array = []
	level.feedback.event_received.connect(func(event): if event.kind == &"world_impact": impacts.append(event))
	var stray = load("res://scenes/weapons/projectile.tscn").instantiate()
	stray.configure(archer, Vector3.LEFT, 9, 18.0, 1, Color.WHITE)
	stray.style = &"arrow"
	level.add_child(stray)
	stray.global_position = Vector3(-4, 1.5, 6)
	await settle(20)
	check(not impacts.is_empty() and impacts[-1].weapon == &"arrow", "a stray arrow reports an arrow world impact")

	var native: float = bow.native_time
	session.pause_run()
	await settle(20)
	check(bow.native_time == native, "pause freezes the skeleton animation")
	session.resume_run()

	# Hit reaction and death.
	only_active(null)
	await settle(2)
	check(warrior.take_damage(5, player) == 5 and look.flash_remaining > 0.0, "a hit flashes the warrior")
	only_active(warrior)
	await settle(4)
	check(absf(look.flinch.rotation.x) > 0.02, "a hit tilts the warrior back")
	var died := [false]
	warrior.died.connect(func() -> void: died[0] = true)
	check(warrior.take_damage(1000, player) == 43 and died[0] and warrior.state == warrior.State.DEAD, "lethal damage kills the warrior and emits died")
	check(look.dead and look.player.current_animation == "death", "the death clip plays")
	await settle(150)
	check(warrior.collision_layer == 0 and look.eye_glow() < 0.05 and not look.eye_light.visible, "dead skeleton stops taking hits and its eyes go dark")
	check(is_equal_approx(look.native_time, look.clip_length(&"Death")), "the death clip holds on its last frame")

	session._on_command("Restart")
	await settle()
	level = session.run
	check(of_species(&"skeleton").size() == 3 and of_species(&"skeleton").all(func(enemy): return enemy.health == 48 and enemy.state != enemy.State.DEAD and not enemy.presentation.dead), "restart recreates living skeletons")

	var source = load("res://scenes/authoring/ossuary.tscn").instantiate()
	root.add_child(source)
	check(PLACEMENT.Kind.SKELETON == 14 and PLACEMENT.Kind.SKELETON_ARCHER == 15 and PLACEMENT.LABELS[14] == "Skeleton" and PLACEMENT.LABELS[15] == "Skeleton Archer", "skeleton kinds are appended as 14 and 15")
	var result: Dictionary = await BUILDER.build(source, self, false)
	check(result.ok, "builder accepts The Ossuary")
	var marker = source.get_node("Placements/PillarSkeleton")
	marker.position = Vector3(3, 0, -3)
	result = await BUILDER.build(source, self, false)
	var codes: Array = result.issues.map(func(issue): return issue.code)
	check(not result.ok and codes.has("overlap"), "builder rejects a skeleton standing inside a pillar")
	source.queue_free()

	session.show_menu()
	session.queue_free()
	await settle(10)
	# Let freed runs, builder viewports and audio release their resources before quitting.
	await create_timer(0.3).timeout
	print("\nRESULT: %d skeleton checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
