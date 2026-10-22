class_name CombatFeedback
extends Node3D

signal event_received(event: Dictionary)
const IMPACT = preload("res://scripts/combat/impact_effect.gd")
const MAX_EFFECTS = 24
const MAX_SPELL_LIGHTS = 6
var effects: Array = []
var spell_lights: Array[Dictionary] = []
var seen_ids: Array[String] = []
var event_counts: Dictionary = {}
var audio: Node

func _ready() -> void:
	audio = CombatAudio.new()
	audio.name = "CombatAudio"
	add_child(audio)

func consume(event: Dictionary) -> void:
	var kind: StringName = event.get("kind", &"")
	if kind in [&"enemy_hit", &"player_hurt", &"pickup_health", &"pickup_mana", &"pickup_key"] and event.get("amount", 0) <= 0:
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
	if kind in [&"magic_cast", &"enemy_cast"] or (kind in [&"enemy_hit", &"world_impact"] and event.get("weapon", &"") == &"magic"):
		var color = Color("69c5d3") if event.get("player_owned", false) else Color("e3a75d")
		var light = _add_spell_light(self, color, 0.16, 1.2, 2.8)
		if light != null:
			light.global_position = event.point + event.get("normal", Vector3.ZERO) * 0.15
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

func light_projectile(projectile: Node3D, color: Color) -> void:
	_add_spell_light(projectile, color, -1.0, 0.9, 2.5)

func _add_spell_light(anchor: Node3D, color: Color, duration: float, energy: float, reach: float) -> OmniLight3D:
	_prune_spell_lights()
	if not get_parent().atmosphere_enabled or not get_parent().combat_enabled or get_tree().paused or spell_lights.size() >= MAX_SPELL_LIGHTS:
		return null
	var light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.shadow_enabled = false
	anchor.add_child(light)
	light.add_to_group("spell_lights")
	spell_lights.append({"node": light, "remaining": duration})
	return light

func _prune_spell_lights() -> void:
	spell_lights = spell_lights.filter(func(record): return is_instance_valid(record.node) and not record.node.is_queued_for_deletion())

func _free_spell_light(light: OmniLight3D) -> void:
	if is_instance_valid(light):
		if light.get_parent() != null:
			light.get_parent().remove_child(light)
		light.queue_free()

func _process(delta: float) -> void:
	_prune()
	_prune_spell_lights()
	if get_tree().paused:
		return
	for record in spell_lights.duplicate():
		if record.remaining >= 0.0:
			record.remaining -= delta
			record.node.light_energy = 1.2 * clampf(record.remaining / 0.16, 0.0, 1.0)
			if record.remaining <= 0.0:
				_free_spell_light(record.node)
	_prune_spell_lights()

func clear_transients() -> void:
	for effect in effects:
		if is_instance_valid(effect):
			if effect.get_parent() == self:
				remove_child(effect)
			effect.queue_free()
	effects.clear()
	_prune_spell_lights()
	for record in spell_lights:
		_free_spell_light(record.node)
	spell_lights.clear()
	silence_audio()

func silence_audio() -> void:
	if is_instance_valid(audio):
		audio.stop_all()
