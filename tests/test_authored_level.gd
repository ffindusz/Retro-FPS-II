extends SceneTree

const MAP = preload("res://scenes/levels/generated/mapping_example.tscn")
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

func freeze() -> void:
	session.run.player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)

func run_tests() -> void:
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session._on_command("Mapping Example")
	freeze()
	await settle()
	var level = session.run
	var player = level.player
	check(session.state == session.State.PLAYING and level.level_title == "The Mason's Trial", "menu selects authored map through normal session")
	check(session.ui.hud.visible and player.get_parent() == level, "authored map has normal HUD and direct-child interaction contract")
	check("THE MASON'S TRIAL" in session.ui.level_heading.text, "authored map title appears in the normal HUD")
	check(not root.has_node("CyclopsAutoload"), "runtime never starts Cyclops editor drawing service")
	check(level.baked_navigation.get_polygon_count() > 0 and level.navigation.navigation_mesh == level.baked_navigation, "authored level uses its embedded per-level navigation")
	check(level.geometry.get_child_count() == 21, "twenty converted architecture blocks plus runtime gate are present")
	check(level.geometry.find_children("*", "StaticBody3D", true, false).size() == 20, "Cyclops architecture becomes native static world collision")
	check(get_nodes_in_group("enemies").size() == 3 and get_nodes_in_group("pickups").size() == 4, "authored placements create exact enemy and pickup counts")
	check(level.get_node("Placements").get_children().all(func(marker): return marker.preview == null), "runtime placements never create editor previews or duplicate actors")
	check(get_nodes_in_group("enemies").filter(func(enemy): return enemy.archetype == 0 and enemy.presentation != null).size() == 2, "placed Wardens reuse the accepted animated controller")
	check(level.presentation.torches.size() == 3 and level.presentation.extra_urns == 0, "authored atmosphere registers placed torches without demo-coordinate dressing")
	check(level.ambience.use_authored_zones and level.ambience.authored_zones.size() == 1, "crypt ambience uses explicit authored zone bounds")
	player.position = Vector3(13, 0, -3)
	level.ambience.advance(1.0)
	check(is_equal_approx(level.ambience.blend, 1.0), "authored crypt zone activates its ambience independent of demo coordinates")
	player.position = Vector3(0, 0.1, 13)
	level.ambience.advance(1.0)
	check(is_zero_approx(level.ambience.blend), "leaving authored zone restores exterior ambience")
	player.velocity = Vector3.ZERO
	for frame in range(25):
		player.move_player(Vector2.ZERO, 1.0 / 60.0, false)
		await physics_frame
	check(player.is_on_floor() and absf(player.position.y) < 0.1, "actual player collision stands on converted floor")
	var map: RID = level.navigation.get_navigation_map()
	var key_point := Vector3(16, 0, -5)
	var path := NavigationServer3D.map_get_path(map, player.position, key_point, true)
	check(path.size() > 2 and path[path.size() - 1].distance_to(key_point) < 0.8, "baked route connects entrance through courtyard doorway to crypt key")
	player.position = Vector3(-5, 0.1, -0.5)
	var enemy = get_nodes_in_group("enemies")[0]
	enemy.target = player
	enemy.state = enemy.State.CHASE
	var start: Vector3 = enemy.position
	for frame in range(35):
		await physics_frame
		enemy._physics_process(1.0 / 60.0)
	check(enemy.position.distance_to(start) > 0.3 and enemy.presentation.walk_time > 0.0, "placed Warden physically navigates converted geometry with travel-driven gait")
	var health = get_nodes_in_group("pickups").filter(func(pickup): return pickup.kind == 0)[0]
	check(not health.try_collect(player) and not health.consumed, "full-health authored pickup remains available")
	player.health = 60
	check(health.try_collect(player) and player.health == 85, "authored health pickup preserves normal restoration behaviour")
	var mana = get_nodes_in_group("pickups").filter(func(pickup): return pickup.kind == 1)[0]
	player.mana = 10
	check(mana.try_collect(player) and player.mana == 35, "authored mana pickup uses configured normal amount")
	player.position = level.exit_position + Vector3(0, 0, 1.8)
	await settle()
	check(not level.interact_exit() and not level.exit_used, "authored exit remains sealed without the ember key")
	var key = get_nodes_in_group("pickups").filter(func(pickup): return pickup.kind == 2)[0]
	check(key.try_collect(player) and player.has_key, "authored key uses existing inventory/event flow")
	check(level.interact_exit() and session.state == session.State.VICTORY and paused, "authored exit completes through normal victory/pause session flow")
	var old_player = player
	session._on_command("Restart")
	freeze()
	await settle()
	check(session.run.level_title == "The Mason's Trial" and not is_instance_valid(old_player), "victory restart disposes old map and retains selected authored level")
	check(session.run.player.health == 100 and not session.run.player.has_key and get_nodes_in_group("enemies").size() == 3, "authored restart resets resources/objectives and exact actor counts")
	var p = get_nodes_in_group("enemies")[0].presentation
	var before: float = p.idle_time
	session.pause_run()
	get_nodes_in_group("enemies")[0].advance_presentation(5.0)
	check(is_equal_approx(p.idle_time, before), "normal pause freezes authored enemy animation without catch-up")
	session.resume_run()
	session.run.player.take_damage(1000, null)
	check(session.state == session.State.DEFEAT and paused, "authored player death reaches normal defeat state")
	session._on_command("Restart")
	freeze()
	await settle()
	check(session.state == session.State.PLAYING and session.run.level_title == "The Mason's Trial", "defeat restart also retains selected map")
	session.show_menu()
	session._on_command("Start")
	freeze()
	await settle()
	check(session.run.scene_file_path == "res://scenes/levels/demo_level.tscn", "Start still selects preserved original demo")
	check(WorldFingerprint.snapshot(session.run) == load("res://resources/atmosphere_baseline.tres").get_meta("snapshot"), "original demo gameplay fingerprints remain identical after map switching")
	session.show_menu()
	session.queue_free()
	await settle()
	await create_timer(0.2).timeout
	print("RESULT: %d authored-level checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
