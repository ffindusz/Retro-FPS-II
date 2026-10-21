class_name CombatFeedback
extends Node3D

signal event_received(event: Dictionary)
const IMPACT = preload("res://scripts/combat/impact_effect.gd")
const MAX_EFFECTS = 24
var effects: Array = []
var seen_ids: Array[String] = []
var event_counts: Dictionary = {}
var audio: Node

func _ready() -> void:
	audio = CombatAudio.new()
	audio.name = "CombatAudio"
	add_child(audio)

func consume(event: Dictionary) -> void:
	var kind: StringName = event.get("kind", &"")
	if kind in [&"enemy_hit", &"player_hurt", &"pickup_health", &"pickup_mana"] and event.get("amount", 0) <= 0:
		return
	var event_id = str(event.get("event_id", ""))
	if not event_id.is_empty():
		if seen_ids.has(event_id):
			return
		seen_ids.append(event_id)
		if seen_ids.size() > 256:
			seen_ids.pop_front()
	event_counts[kind] = event_counts.get(kind, 0) + 1
	if kind in [&"enemy_hit", &"world_impact"]:
		_spawn_impact(event)
	if is_instance_valid(audio):
		audio.consume(event)
	event_received.emit(event)

func _spawn_impact(event: Dictionary) -> void:
	_prune()
	while effects.size() >= MAX_EFFECTS:
		var old: Node3D = effects.pop_front()
		remove_child(old)
		old.queue_free()
	var effect = IMPACT.new()
	effect.tint = Color("b95f49") if event.kind == &"enemy_hit" else Color("efb76f")
	if event.get("weapon", &"") == &"magic":
		effect.tint = Color("69c5d3") if event.kind == &"enemy_hit" else Color("e3bb78")
	add_child(effect)
	effect.global_position = event.point + event.get("normal", Vector3.UP) * 0.025
	effects.append(effect)

func _prune() -> void:
	effects = effects.filter(func(effect): return is_instance_valid(effect) and not effect.is_queued_for_deletion())

func _process(_delta: float) -> void:
	_prune()

func clear_transients() -> void:
	for effect in effects:
		if is_instance_valid(effect):
			if effect.get_parent() == self:
				remove_child(effect)
			effect.queue_free()
	effects.clear()
	silence_audio()

func silence_audio() -> void:
	if is_instance_valid(audio):
		audio.stop_all()
