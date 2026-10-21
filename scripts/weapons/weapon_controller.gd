extends Node

signal fired(slot: int)
signal selected(slot: int)
enum Phase { READY, WINDUP, ACTIVE, RECOVERY }
const PROJECTILE = preload("res://scenes/weapons/projectile.tscn")
@export var melee_damage: int = 34
@export var melee_range: float = 2.7
@export_range(0.01, 1.0, 0.01) var melee_windup: float = 0.12
@export_range(0.01, 1.0, 0.01) var melee_active: float = 0.16
@export_range(0.01, 1.0, 0.01) var melee_recovery: float = 0.24
@export_range(10, 120, 1) var melee_arc_degrees: float = 80.0
@export var magic_damage: int = 28
@export var magic_cost: int = 5
@export var magic_cooldown: float = 0.36
@export var projectile_speed: float = 23.0
var slot: int = 0
var cooldowns: Array[float] = [0.0, 0.0]
var phase: Phase = Phase.READY
var elapsed: float = 0.0
var attack_id: int = 0
var queued_slot: int = -1
var hit_targets: Dictionary = {}
var world_contact_reported: bool = false
var sweep_shape = CapsuleShape3D.new()
var melee_cooldown: float:
	get: return melee_windup + melee_active + melee_recovery
@onready var player: DemoPlayer = get_parent()

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if not player.can_act():
		return
	delta = maxf(0.0, delta)
	for index in range(cooldowns.size()):
		cooldowns[index] = maxf(0.0, cooldowns[index] - delta)
	if phase == Phase.READY:
		return
	var previous = elapsed
	elapsed = minf(melee_cooldown, elapsed + delta)
	var contact_end = melee_windup + melee_active
	if elapsed > melee_windup and previous < contact_end:
		_sweep(clampf((previous - melee_windup) / melee_active, 0.0, 1.0), clampf((elapsed - melee_windup) / melee_active, 0.0, 1.0))
	if elapsed >= melee_cooldown - 0.000001:
		phase = Phase.READY
		if queued_slot >= 0:
			_apply_selection(queued_slot)
			queued_slot = -1
	elif elapsed >= contact_end:
		phase = Phase.RECOVERY
	elif elapsed >= melee_windup:
		phase = Phase.ACTIVE
	else:
		phase = Phase.WINDUP

func phase_progress() -> float:
	match phase:
		Phase.WINDUP: return clampf(elapsed / melee_windup, 0.0, 1.0)
		Phase.ACTIVE: return clampf((elapsed - melee_windup) / melee_active, 0.0, 1.0)
		Phase.RECOVERY: return clampf((elapsed - melee_windup - melee_active) / melee_recovery, 0.0, 1.0)
	return 0.0

func cancel_attack() -> void:
	phase = Phase.READY
	elapsed = 0.0
	queued_slot = -1
	hit_targets.clear()
	world_contact_reported = false

func select(index: int) -> void:
	if not player.can_act() or index < 0 or index > 1:
		return
	if phase != Phase.READY:
		queued_slot = index
		return
	_apply_selection(index)

func _apply_selection(index: int) -> void:
	slot = index
	selected.emit(slot)
	player.stats_changed.emit()

func query(from: Vector3, to: Vector3, mask: int = 5) -> Dictionary:
	var ray = PhysicsRayQueryParameters3D.create(from, to, mask, [player.get_rid()])
	return player.get_world_3d().direct_space_state.intersect_ray(ray)

func try_attack() -> bool:
	if not player.can_act() or phase != Phase.READY or cooldowns[slot] > 0.000001:
		return false
	var origin = player.camera.global_position
	var forward = -player.camera.global_basis.z
	if slot == 0:
		attack_id += 1
		cooldowns[0] = melee_cooldown
		elapsed = 0.0
		phase = Phase.WINDUP
		hit_targets.clear()
		world_contact_reported = false
		CombatEvents.publish(player, &"melee_swing", origin, {"event_id": "%d:swing:%d" % [get_instance_id(), attack_id]})
	else:
		if player.mana < magic_cost:
			player.message.emit("Not enough arcana. Use the iron blade [1].")
			return false
		attack_id += 1
		cooldowns[1] = magic_cooldown
		player.mana -= magic_cost
		player.stats_changed.emit()
		CombatEvents.publish(player, &"magic_cast", origin, {"event_id": "%d:cast:%d" % [get_instance_id(), attack_id]})
		var aim = query(origin, origin + forward * 100.0)
		var target: Vector3 = aim.position if not aim.is_empty() else origin + forward * 100.0
		var muzzle = origin + forward * 0.55 + player.camera.global_basis.x * 0.12 - Vector3.UP * 0.12
		var obstruction = query(origin, muzzle)
		if not obstruction.is_empty():
			_resolve_magic_contact(obstruction)
		else:
			var bolt = PROJECTILE.instantiate()
			bolt.configure(player, (target - muzzle).normalized(), magic_damage, projectile_speed, 5, Color("5fcbd7"))
			player.get_parent().add_child(bolt)
			bolt.global_position = muzzle
	fired.emit(slot)
	return true

func _resolve_magic_contact(hit: Dictionary) -> void:
	if hit.collider.has_method("take_damage"):
		CombatEvents.apply_hit(player, hit.collider, magic_damage, player, hit.position, hit.normal, &"magic", attack_id)
	else:
		CombatEvents.publish(player, &"world_impact", hit.position, {"normal": hit.normal, "weapon": &"magic"})

func _sweep(start: float, end: float) -> void:
	# Angular subsamples cover every crossed contact interval, even across a long tick.
	var steps = maxi(1, ceili((end - start) * melee_arc_degrees / 2.0))
	for index in range(steps + 1):
		_sweep_sample(lerpf(start, end, float(index) / steps))

func _sweep_sample(progress: float) -> void:
	var camera_basis = player.camera.global_basis
	var origin = player.camera.global_position - camera_basis.y * 0.18
	var forward = -camera_basis.z
	var angle = deg_to_rad(lerpf(melee_arc_degrees / 2.0, -melee_arc_degrees / 2.0, progress))
	var direction = forward.rotated(camera_basis.y, -angle).normalized()
	sweep_shape.radius = minf(0.22, melee_range * 0.1)
	sweep_shape.height = melee_range
	var parameters = PhysicsShapeQueryParameters3D.new()
	parameters.shape = sweep_shape
	parameters.transform = Transform3D(Basis(Quaternion(Vector3.UP, direction)), origin + direction * melee_range * 0.5)
	parameters.collision_mask = 4
	parameters.exclude = [player.get_rid()]
	var candidates = player.get_world_3d().direct_space_state.intersect_shape(parameters, 16)
	for candidate in candidates:
		var target: Node3D = candidate.collider
		if hit_targets.has(target.get_instance_id()):
			continue
		var collider = target.get_node_or_null("Collision")
		var aim_point: Vector3 = collider.global_position if collider != null else target.global_position
		var hit = query(origin, aim_point)
		if hit.is_empty() or hit.collider != target:
			continue
		var offset: Vector3 = hit.position - origin
		if offset.length() > melee_range + 0.0001 or forward.dot(offset.normalized()) < cos(deg_to_rad(melee_arc_degrees * 0.5)):
			continue
		var applied = CombatEvents.apply_hit(player, target, melee_damage, player, hit.position, hit.normal, &"melee", attack_id)
		if applied > 0:
			hit_targets[target.get_instance_id()] = true
	if not world_contact_reported:
		var wall = query(origin, origin + direction * melee_range)
		if not wall.is_empty() and not wall.collider.has_method("take_damage"):
			world_contact_reported = true
			CombatEvents.publish(player, &"world_impact", wall.position, {"normal": wall.normal, "weapon": &"melee", "event_id": "%d:wall:%d" % [get_instance_id(), attack_id]})
