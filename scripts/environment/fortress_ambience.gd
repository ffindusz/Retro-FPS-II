class_name FortressAmbience
extends Node
## Exactly two reusable loop players, independent of accepted combat SFX voices/gain.

static var owns_bus: bool = false
const BUS_GAIN = 0.15
var players: Array[AudioStreamPlayer] = []
var actor: Node3D
var volume: float = 0.3
var blend: float = 0.0
var running: bool = false
var paused: bool = false
var start_count: int = 0
var bus_index: int = -1

func _ready() -> void:
	bus_index = AudioServer.get_bus_index("Ambience")
	if bus_index < 0:
		owns_bus = true
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, "Ambience")
	for cue in ["wind", "crypt"]:
		var player = AudioStreamPlayer.new()
		player.name = cue.capitalize() + "Loop"
		player.stream = load("res://assets/audio/ambience/%s.wav" % cue)
		player.bus = "Ambience"
		add_child(player)
		player.add_to_group("ambience_players")
		players.append(player)
	_apply_blend()

func configure(player: Node3D, retained_volume: float) -> void:
	actor = player
	set_volume(retained_volume)

func start_loops() -> void:
	if running:
		return
	running = true
	paused = false
	start_count += 1
	for player in players:
		player.play()

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, volume == 0.0)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(0.0001, volume * BUS_GAIN)))

func advance(delta: float) -> void:
	if not running or paused or get_tree().paused or not is_instance_valid(actor):
		return
	var point = actor.global_position
	var target = 1.0 if point.x > 13.4 and point.x < 31.4 and point.z > -14.4 and point.z < 0.4 else 0.0
	blend = move_toward(blend, target, maxf(0.0, delta))
	_apply_blend()

func _apply_blend() -> void:
	if players.size() == 2:
		players[0].volume_db = linear_to_db(maxf(0.0001, 1.0 - blend))
		players[1].volume_db = linear_to_db(maxf(0.0001, blend))

func set_paused(value: bool) -> void:
	paused = value
	for player in players:
		player.stream_paused = value

func stop_loops() -> void:
	running = false
	paused = false
	for player in players:
		player.stop()
		player.stream = null

func _process(delta: float) -> void:
	advance(delta)

func _exit_tree() -> void:
	stop_loops()

static func cleanup_bus() -> void:
	var index = AudioServer.get_bus_index("Ambience")
	if owns_bus and index >= 0:
		AudioServer.remove_bus(index)
		owns_bus = false
