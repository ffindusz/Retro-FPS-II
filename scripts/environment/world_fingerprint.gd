class_name WorldFingerprint
extends RefCounted
## Canonical gameplay-only snapshot. Presentation nodes and generated names are ignored.

static func digest(value: Variant) -> String:
	var context = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(var_to_bytes(value))
	return context.finish().hex_encode()

static func colliders_under(node: Node) -> Array[String]:
	var rows: Array[String] = []
	if node is StaticBody3D:
		for child in node.get_children():
			if child is CollisionShape3D:
				var shape = child.shape
				rows.append("%s|%s|%s|%d|%d|%s" % [shape.get_class(), shape.size if shape is BoxShape3D else "other", child.global_transform, node.collision_layer, node.collision_mask, child.disabled])
	for child in node.get_children():
		rows.append_array(colliders_under(child))
	rows.sort()
	return rows

static func snapshot(level: Node3D) -> Dictionary:
	var enemies: Array[String] = []
	var pickups: Array[String] = []
	for actor in level.get_children():
		if actor.is_in_group("enemies"):
			enemies.append("%d|%s|%d|%d|%.4f|%.4f|%.4f|%.4f" % [actor.archetype, actor.position, actor.max_health, actor.attack_damage, actor.windup_duration, actor.attack_cooldown, actor.move_speed, actor.detection_range])
		elif actor.is_in_group("pickups"):
			pickups.append("%d|%s|%d" % [actor.kind, actor.position, actor.amount])
	enemies.sort()
	pickups.sort()
	var mesh: NavigationMesh = level.navigation.navigation_mesh
	var polygons: Array = []
	for index in range(mesh.get_polygon_count()):
		polygons.append(mesh.get_polygon(index))
	var player = level.player
	return {
		"colliders": colliders_under(level.geometry), "enemies": enemies, "pickups": pickups,
		"spawn": str(level.spawn_position), "exit": str(level.exit_position),
		"navigation": digest([mesh.get_vertices(), polygons]),
		"player": [player.max_health, player.max_mana, player.move_speed, player.jump_speed, player.gravity],
		"weapons": [player.weapons.melee_damage, player.weapons.melee_range, player.weapons.melee_cooldown, player.weapons.magic_damage, player.weapons.magic_cost, player.weapons.magic_cooldown]
	}
