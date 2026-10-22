class_name CombatAudio
extends Node
## Run-owned, bounded one-shots. No synthesis, streaming, deferred queue or credentials.

const CUE_NAMES = ["swing", "hit", "wall", "magic_cast", "magic_impact", "enemy_melee", "enemy_charge", "enemy_cast", "hurt", "pickup_health", "pickup_mana", "pickup_key"]
const MAX_VOICES = 12
static var owns_bus: bool = false
var streams: Dictionary = {}
var voices: Array = []
var played_counts: Dictionary = {}
var volume: float = 0.65
var bus_index: int = -1

func _ready() -> void:
	bus_index = AudioServer.get_bus_index("SFX")
	if bus_index < 0:
		owns_bus = true
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, "SFX")
		var limiter = ClassDB.instantiate("AudioEffectHardLimiter") if ClassDB.class_exists("AudioEffectHardLimiter") else AudioEffectLimiter.new()
		limiter.set("ceiling_db", -1.0)
		AudioServer.add_bus_effect(bus_index, limiter)
	for cue in CUE_NAMES:
		streams[cue] = load("res://assets/audio/combat/%s.wav" % cue)
	set_volume(volume)

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, volume == 0.0)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(0.0001, volume * 0.5)))
	if volume == 0.0:
		stop_all()

func consume(event: Dictionary) -> void:
	if volume <= 0.0 or get_tree().paused:
		return
	var cue = ""
	match event.kind:
		&"melee_swing": cue = "swing"
		&"magic_cast": cue = "magic_cast"
		&"enemy_hit": cue = "magic_impact" if event.get("weapon", &"") == &"magic" else "hit"
		&"world_impact": cue = "wall" if event.get("weapon", &"") == &"melee" else "magic_impact"
		&"enemy_melee_windup": cue = "enemy_melee"
		&"enemy_charge": cue = "enemy_charge"
		&"enemy_cast": cue = "enemy_cast"
		&"player_hurt": cue = "hurt"
		&"pickup_health": cue = "pickup_health"
		&"pickup_mana": cue = "pickup_mana"
		&"pickup_key": cue = "pickup_key"
	if cue.is_empty() or streams.get(cue) == null:
		return
	var spatial: bool = event.kind not in [&"melee_swing", &"magic_cast", &"player_hurt", &"pickup_health", &"pickup_mana", &"pickup_key"]
	var priority = 0 if event.kind in [&"enemy_hit", &"world_impact"] else 1
	if not spatial:
		priority = 2
	if voices.size() >= MAX_VOICES:
		var oldest = voices[0]
		for record in voices:
			if record.priority < oldest.priority:
				oldest = record
		if oldest.priority > priority:
			return
		_release(oldest.node)
	var voice = AudioStreamPlayer3D.new() if spatial else AudioStreamPlayer.new()
	voice.stream = streams[cue]
	voice.bus = "SFX"
	voice.volume_db = -8.0
	add_child(voice)
	voice.add_to_group("combat_voices")
	if spatial:
		voice.global_position = event.point
		voice.unit_size = 3.0
		voice.max_distance = 24.0
		voice.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	voices.append({"node": voice, "remaining": voice.stream.get_length() + 0.05, "priority": priority})
	voice.finished.connect(_release.bind(voice))
	voice.play()
	played_counts[cue] = played_counts.get(cue, 0) + 1

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	for record in voices.duplicate():
		record.remaining -= delta
		if record.remaining <= 0.0 or not is_instance_valid(record.node):
			_release(record.node)

func _release(voice: Node) -> void:
	for index in range(voices.size() - 1, -1, -1):
		if voices[index].node == voice:
			voices.remove_at(index)
	if is_instance_valid(voice):
		if voice.has_method("stop"):
			voice.stop()
		voice.stream = null
		if voice.get_parent() == self:
			remove_child(voice)
		voice.queue_free()

func stop_all() -> void:
	for record in voices.duplicate():
		_release(record.node)
	voices.clear()

static func cleanup_bus() -> void:
	var index = AudioServer.get_bus_index("SFX")
	if owns_bus and index >= 0:
		AudioServer.remove_bus(index)
		owns_bus = false
