extends SceneTree
## The rune door exit of The Ossuary: sealed leaves, key socket, glowing runes, sliding open into
## the walls, walking through to finish, pause, restart, and the Rune Door placement kind.

const BUILDER = preload("res://addons/cinderkeep_level_tools/level_builder.gd")
const PLACEMENT = preload("res://scripts/levels/level_placement.gd")
const DOOR := Vector3(0, 0, -29.9)
var checks: int = 0
var failures: int = 0
var session
var level
var player: DemoPlayer
var door: RuneDoor
var messages: Array = []
var events: Array = []

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

func put_player(point: Vector3) -> void:
	player.global_position = point + Vector3.UP * 0.1
	player.velocity = Vector3.ZERO

func look(point: Vector3) -> void:
	player.camera.look_at(point, Vector3.UP)

func start() -> void:
	session._on_command("The Ossuary")
	level = session.run
	player = level.player
	player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	door = level.rune_door
	messages = []
	events = []
	player.message.connect(func(text): messages.append(text))
	level.combat_event.connect(func(event): events.append(event.kind))
	await settle()

func blocked(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	return not level.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func in_front_of_socket() -> void:
	put_player(door.socket.global_position + door.socket.global_basis.z * 1.2)
	look(door.socket.global_position + Vector3.UP * 0.8)
	await settle(2)

func run_tests() -> void:
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	check(PLACEMENT.Kind.RUNE_DOOR == 19 and PLACEMENT.LABELS[19] == "Rune Door" and PLACEMENT.EXITS == [PLACEMENT.Kind.EXIT, PLACEMENT.Kind.RUNE_DOOR], "Rune Door is appended as kind 19 and counts as an exit")
	await start()

	# Layout.
	check(door != null and level.get_children().filter(func(node): return node is RuneDoor).size() == 1, "The Ossuary has one rune door")
	check(door.global_position.distance_to(DOOR) < 0.05 and level.exit_position.distance_to(DOOR) < 0.05, "the rune door is set into the far wall of the Golem Sanctum")
	check((-door.global_basis.z).dot(Vector3.BACK) > 0.99, "its front faces into the sanctum")
	check(door.has_node("Frame") and door.leaves.size() == 2 and door.socket.has_node("Model"), "frame, two leaves and the key socket are built from the Meshy models")
	var frame_material := door.get_node("Frame").find_children("*", "MeshInstance3D", true, false)[0].material_override as StandardMaterial3D
	check(frame_material.emission_enabled and frame_material.emission_texture == RuneDoor.FRAME_GLOW, "the frame's carved runes glow through the baked rune mask")
	check(door.leaves.all(func(leaf): return leaf.has_node("Runes") and leaf.get_node("Runes").mesh.get_surface_count() == 1), "each leaf carries glowing rune strokes")
	var socket_floor: Vector3 = door.socket.global_position
	check(absf(socket_floor.y) < 0.01 and blocked(socket_floor + Vector3(0.5, 0.3, 0), socket_floor + Vector3(0.5, -0.3, 0)), "the key socket stands on the sanctum floor")
	check(door.socket.global_position.distance_to(Vector3(2.75, 0, -28.6)) < 0.05, "the socket stands in front of the right-hand pillar")

	# Sealed.
	check(door.is_sealed() and door.glow < 1.5, "the door starts sealed with softly glowing runes")
	check(blocked(DOOR + Vector3(0, 1.5, 1.5), DOOR + Vector3(0, 1.5, -1.5)), "the closed leaves block the doorway")
	put_player(DOOR + Vector3(0, 0, 1.0))
	player.set_physics_process(true)
	for frame in range(60):
		player.move_player(Vector2(0, -1), 1.0 / 60.0, false)
		player.look_at(DOOR + Vector3(0, player.global_position.y, -5), Vector3.UP)
		await physics_frame
	player.set_physics_process(false)
	check(player.global_position.z > DOOR.z + 0.2, "the player cannot walk through the closed door")

	# Without the key.
	await in_front_of_socket()
	check(not player.has_key and not level.interact_exit() and messages.has(RuneDoor.SEALED_TEXT) and door.is_sealed(), "without the key the door stays sealed and says what it needs")
	messages.clear()
	put_player(DOOR + Vector3(0, 0, 7))
	look(door.socket.global_position)
	await settle(2)
	check(not level.interact_exit() and messages.is_empty(), "too far away, interacting does nothing")

	# Key into the socket.
	player.collect_key()
	await in_front_of_socket()
	check(level.interact_exit() and not door.is_sealed() and door.key_visual != null and messages.has(RuneDoor.KEY_TEXT), "with the key the player sets it into the socket")
	check(not level.interact_exit(), "the key goes in only once")
	await settle(2)
	check(events.has(&"rune_door_key"), "inserting the key makes a sound")
	session.pause_run()
	var frozen := door.glow
	await settle(20)
	check(door.glow == frozen and door.state == RuneDoor.State.KEYED, "pause freezes the door")
	session.resume_run()
	for frame in range(150):
		await settle(1)
		if door.state == RuneDoor.State.OPENING:
			break
	check(door.state == RuneDoor.State.OPENING and door.glow > RuneDoor.KEYED_GLOW * 0.9 and events.has(&"rune_door_open"), "after a moment the runes blaze and the leaves start to move")
	var midway := false
	for frame in range(400):
		await settle(1)
		midway = midway or (absf(door.leaves[0].position.x) > 1.0 and not door.is_open())
		if door.is_open():
			break
	check(midway and door.is_open() and messages.has(RuneDoor.OPEN_TEXT), "the leaves slide apart and the door reports open")
	var hidden := door.leaves.all(func(leaf): return absf(leaf.position.x) - RuneDoor.LEAF_SIZE.x / 2.0 >= RuneDoor.OPENING.x / 2.0 - 0.05)
	check(hidden, "both leaves end up inside the walls on either side")
	check(not blocked(DOOR + Vector3(0, 1.5, 1.5), DOOR + Vector3(0, 1.5, -2.0)), "the open doorway is clear")
	check(blocked(DOOR + Vector3(1.8, 1.5, 1.5), DOOR + Vector3(1.8, 1.5, -1.5)), "the walls beside the doorway still block")

	# Walking through.
	var won := [0]
	level.completed.connect(func() -> void: won[0] += 1)
	put_player(DOOR + Vector3(0, 0, 0.6))
	await settle(3)
	check(won[0] == 0, "standing in the doorway does not finish yet")
	put_player(DOOR + Vector3(0, 0, -1.6))
	await settle(3)
	check(won[0] == 1 and level.exit_used, "walking through the open door finishes the level")
	await settle(3)
	check(won[0] == 1, "the level finishes only once")

	# Restart.
	session._on_command("Restart")
	await start()
	check(door.is_sealed() and door.key_visual == null and door.leaves.all(func(leaf): return is_equal_approx(absf(leaf.position.x), RuneDoor.LEAF_SIZE.x / 2.0)), "restart closes the door again")

	# Builder: exactly one exit, Exit Gate or Rune Door.
	var source = load("res://scenes/authoring/ossuary.tscn").instantiate()
	root.add_child(source)
	var gate := Node3D.new()
	gate.set_script(PLACEMENT)
	gate.name = "ExtraGate"
	gate.kind = PLACEMENT.Kind.EXIT
	gate.position = Vector3(0, 0, 12)
	source.get_node("Placements").add_child(gate)
	var result: Dictionary = await BUILDER.build(source, self, false)
	check(not result.ok and "Exactly one Exit Gate or Rune Door" in str(result.errors), "the builder rejects a second exit")
	source.get_node("Placements").remove_child(gate)
	gate.free()
	source.get_node("Placements/RuneDoor").free()
	result = await BUILDER.build(source, self, false)
	check(not result.ok and "Exactly one Exit Gate or Rune Door is required (found 0)" in str(result.errors), "the builder rejects a level without an exit")
	source.queue_free()

	session.show_menu()
	session.queue_free()
	await settle(10)
	await create_timer(0.3).timeout
	print("\nRESULT: %d rune-door checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
