extends SceneTree

const CATALOG = preload("res://scripts/levels/built_level_catalog.gd")
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

func settle() -> void:
	for frame in range(4):
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
	var catalog := CATALOG.entries()
	check(catalog.any(func(entry): return entry.path == "res://scenes/levels/generated/mapping_example.tscn"), "runtime discovers the shipped built map, including exported remaps")
	check(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("player").is_empty(), "catalog inspection instantiates no actors or gameplay level")
	check(not CATALOG.public_path("user://custom.tscn") and not CATALOG.public_path("res://scenes/authoring/mapping_example.tscn") and not CATALOG.public_path(CATALOG.ROOT + "_editor_test.tscn"), "catalog rejects external, authoring and private test/draft paths")
	var choose: Button
	for child in session.ui.buttons.get_children():
		if child.text == "Choose Level":
			choose = child
	check(choose != null, "main menu exposes Choose Level without changing Start")
	choose.pressed.emit()
	await process_frame
	check(session.choosing_level and session.state == session.State.MENU and session.ui.title.text == "CHOOSE LEVEL", "actual menu button opens built-level selection")
	check(session.ui.buttons.get_child_count() == catalog.size() + 1 and session.ui.buttons.get_child(0).has_focus(), "map list has deterministic entries, Back and initial keyboard focus")
	await process_frame
	await process_frame
	check(session.ui.button_scroll.get_global_rect().encloses(session.ui.buttons.get_children().back().get_global_rect()), "small map list shows Back fully without unnecessary clipping")
	session._select_built_level("res://scenes/authoring/mapping_example.tscn")
	check(session.state == session.State.MENU and session.choosing_level, "arbitrary scene paths are not accepted as map selection")
	var escape := InputEventAction.new()
	escape.action = "pause"
	escape.pressed = true
	session._unhandled_input(escape)
	check(not session.choosing_level and session.state == session.State.MENU, "Escape from map selection returns to main menu without starting a game")
	session.show_level_selection()
	var map_button: Button
	for child in session.ui.buttons.get_children():
		if child.tooltip_text == "res://scenes/levels/generated/mapping_example.tscn":
			map_button = child
	map_button.grab_focus()
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	root.push_input(enter)
	await process_frame
	enter.pressed = false
	root.push_input(enter)
	freeze()
	await settle()
	check(session.state == session.State.PLAYING and session.run.get("level_title") == "The Mason's Trial", "real keyboard activation loads chosen map through normal session")
	var old_player = session.run.player
	session._on_command("Restart")
	freeze()
	await settle()
	check(not is_instance_valid(old_player) and session.run.level_title == "The Mason's Trial" and not session.run.player.has_key, "selected-map restart disposes old state and retains the chosen map")
	session.show_menu()
	session.show_level_selection()
	session.ui.buttons.get_children().back().pressed.emit()
	check(not session.choosing_level and session.state == session.State.MENU, "actual Back button returns to main menu")
	var empty_entries: Array[Dictionary] = []
	session.ui.show_level_selection(empty_entries)
	check(session.ui.buttons.get_child_count() == 1 and session.ui.buttons.get_child(0).text == "Back to Menu", "empty map list retains an accessible Back action")
	var rows: Array[Dictionary] = []
	for index in range(30):
		rows.append({"title": "Duplicate Title", "path": CATALOG.ROOT + "map_%02d.tscn" % index})
	session.ui.show_level_selection(rows)
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		await process_frame
		await process_frame
		check(root.get_visible_rect().encloses(session.ui.button_scroll.get_global_rect()) and session.ui.button_scroll.custom_minimum_size.y <= 240, "large map lists remain bounded at width %d" % width)
	check(session.ui.buttons.get_child(0).text != session.ui.buttons.get_child(1).text, "duplicate titles are disambiguated by filename rather than used as IDs")
	var last_button := session.ui.buttons.get_children().back() as Button
	last_button.grab_focus()
	await process_frame
	await process_frame
	check(session.ui.button_scroll.scroll_vertical > 0 and session.ui.button_scroll.get_global_rect().intersects(last_button.get_global_rect()), "keyboard focus scrolls a long map list to its Back action")
	session.show_menu()
	session._on_command("Start")
	freeze()
	await settle()
	check(session.run.scene_file_path == "res://scenes/levels/demo_level.tscn", "Start still selects the configured original demo")
	check(WorldFingerprint.snapshot(session.run) == load("res://resources/atmosphere_baseline.tres").get_meta("snapshot"), "map selector leaves all original gameplay fingerprints unchanged")
	session.show_menu()
	session.queue_free()
	await settle()
	await create_timer(0.2).timeout
	print("RESULT: %d level-selection checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
