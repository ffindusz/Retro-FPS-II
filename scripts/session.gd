class_name DemoSession
extends Node
## Owns transitions, never stores gameplay state across runs.

enum State { MENU, PLAYING, PAUSED, DEFEAT, VICTORY }
var state: State = State.MENU
var run: Node3D
var sfx_volume: float = 0.65
@export var atmosphere_enabled: bool = true
var ambience_volume: float = 0.3
@onready var ui = $Interface

func _ready() -> void:
	ui.command.connect(_on_command)
	ui.sfx_volume_changed.connect(_set_sfx_volume)
	ui.ambience_volume_changed.connect(_set_ambience_volume)
	get_window().focus_exited.connect(_on_focus_exited)
	show_menu()

func start_run() -> void:
	_dispose_run()
	run = load("res://scenes/levels/demo_level.tscn").instantiate()
	run.atmosphere_enabled = atmosphere_enabled
	add_child(run)
	run.feedback.audio.set_volume(sfx_volume)
	state = State.PLAYING
	get_tree().paused = false
	if is_instance_valid(run.ambience):
		run.ambience.configure(run.player, ambience_volume)
		run.ambience.start_loops()
	if run.has_signal("completed"):
		run.completed.connect(finish.bind(true))
	if run.get("player") != null:
		run.player.died.connect(finish.bind(false))
		run.player.attack_blocked_until_release = true
		ui.bind_player(run.player)
	run.feedback.event_received.connect(ui.on_combat_event)
	ui.show_play()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func pause_run() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	run.feedback.silence_audio()
	if is_instance_valid(run.ambience):
		run.ambience.set_paused(true)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui.show_menu("THE EMBERS WAIT", "The fortress holds its breath.", ["Resume", "Restart", "Quit to Menu"])

func resume_run() -> void:
	if state != State.PAUSED:
		return
	state = State.PLAYING
	if is_instance_valid(run) and run.get("player") != null:
		run.player.attack_blocked_until_release = true
	get_tree().paused = false
	if is_instance_valid(run.ambience):
		run.ambience.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ui.show_play()

func finish(won: bool) -> void:
	if state != State.PLAYING:
		return
	state = State.VICTORY if won else State.DEFEAT
	if is_instance_valid(run):
		run.combat_enabled = false
		run.player.weapons.cancel_attack()
		run.feedback.clear_transients()
		if is_instance_valid(run.ambience):
			run.ambience.stop_loops()
	ui.clear_combat_feedback()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if won:
		ui.show_menu("THE SEAL IS BROKEN", "You escaped Cinderkeep. The dark is not yet done.", ["Restart", "Quit to Menu"])
	else:
		ui.show_menu("ASHES TO ASHES", "The keep has claimed another soul.", ["Restart", "Quit to Menu"])

func show_menu() -> void:
	_dispose_run()
	state = State.MENU
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui.show_menu("CINDERKEEP", "A dark-fantasy first-person demo\nFORTRESS ATMOSPHERE 0.3  /  MESHY 3D MODELS", ["Start", "Quit"])

func _dispose_run() -> void:
	get_tree().paused = false
	ui.unbind_player()
	if is_instance_valid(run):
		run.combat_enabled = false
		run.player.weapons.cancel_attack()
		run.feedback.clear_transients()
		if is_instance_valid(run.ambience):
			run.ambience.stop_loops()
		remove_child(run)
		run.queue_free()
	run = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == State.PLAYING:
			pause_run()
		elif state == State.PAUSED:
			resume_run()
		get_viewport().set_input_as_handled()

func _on_focus_exited() -> void:
	pause_run()

func _set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	if is_instance_valid(run):
		run.feedback.audio.set_volume(sfx_volume)

func _set_ambience_volume(value: float) -> void:
	ambience_volume = clampf(value, 0.0, 1.0)
	if is_instance_valid(run) and is_instance_valid(run.ambience):
		run.ambience.set_volume(ambience_volume)

func _on_command(action: String) -> void:
	match action:
		"Start", "Restart": start_run()
		"Resume": resume_run()
		"Quit to Menu": show_menu()
		"Quit": get_tree().quit()

func _exit_tree() -> void:
	CombatAudio.cleanup_bus()
	FortressAmbience.cleanup_bus()
