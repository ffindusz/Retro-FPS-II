class_name CombatEvents
extends RefCounted
## Small run-scoped messages. Payloads store IDs/values, never actor references.

static func publish(anchor: Node, kind: StringName, point: Vector3, data: Dictionary = {}) -> void:
	var event = data.duplicate()
	event["kind"] = kind
	event["point"] = point
	event["player_owned"] = data.get("player_owned", anchor is DemoPlayer)
	event["source_id"] = data.get("source_id", anchor.get_instance_id())
	var node = anchor
	while is_instance_valid(node):
		if node.has_method("emit_combat"):
			node.emit_combat(event)
			return
		node = node.get_parent()

static func apply_hit(anchor: Node, target: Node, amount: int, source: Node, point: Vector3, normal: Vector3, weapon: StringName, attack_id: int) -> int:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return 0
	var applied: int = target.take_damage(amount, source)
	if applied > 0 and target.is_in_group("enemies"):
		publish(anchor, &"enemy_hit", point, {
			"amount": applied, "normal": normal, "weapon": weapon,
			"player_owned": source is DemoPlayer, "target_id": target.get_instance_id(),
			"lethal": target.health == 0,
			"event_id": "%d:hit:%d:%d" % [anchor.get_instance_id(), attack_id, target.get_instance_id()]
		})
	return applied
