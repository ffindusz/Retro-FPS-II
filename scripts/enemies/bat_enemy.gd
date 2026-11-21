extends "res://scripts/enemies/enemy.gd"
## Fire Bat: hovers above the floor, keeps its distance, strafes and spits small fireballs.
## Shares damage, death, groups and presentation hooks with the ground enemies.

@export var hover_height: float = 2.4
@export var preferred_min: float = 5.0
@export var preferred_max: float = 9.0
@export var retreat_distance: float = 3.5
@export var attack_range: float = 11.0
@export var fireball_speed: float = 12.0
const FIREBALL_TINT := Color("ff7a2e")
const BOB_AMPLITUDE := 0.12
var clock: float = 0.0
var strafe_sign: float = 1.0
var strafe_timer: float = 1.6
var wings: Array[Node3D] = []

func _ready() -> void:
	super._ready()
	# Each bat starts its wing beat and strafe at a different phase.
	clock = fmod(absf(position.x * 1.7 + position.z * 0.9), TAU)
	strafe_sign = 1.0 if int(absf(position.x + position.z)) % 2 == 0 else -1.0

func _build_placeholder() -> void:
	var fur = Color("3a2b2a")
	var membrane = Color("5a3a35")
	PrimitiveArt.orb(visual, Vector3.ZERO, 0.24, fur)
	PrimitiveArt.orb(visual, Vector3(0, 0.16, -0.16), 0.15, fur)
	for side in [-1.0, 1.0]:
		PrimitiveArt.box(visual, Vector3(side * 0.08, 0.33, -0.16), Vector3(0.06, 0.14, 0.04), fur)
		PrimitiveArt.orb(visual, Vector3(side * 0.06, 0.19, -0.29), 0.03, Color("ffb347"), 2.5)
		var wing = Node3D.new()
		wing.name = "WingL" if side < 0 else "WingR"
		wing.position = Vector3(side * 0.18, 0.05, 0)
		visual.add_child(wing)
		PrimitiveArt.box(wing, Vector3(side * 0.42, 0, 0.02), Vector3(0.84, 0.03, 0.42), membrane)
		PrimitiveArt.box(wing, Vector3(side * 0.42, 0.01, -0.18), Vector3(0.86, 0.05, 0.04), fur)
		wings.append(wing)

func advance_presentation(delta: float, movement_distance: float = 0.0) -> void:
	if presentation != null:
		super.advance_presentation(delta, movement_distance)
		return
	if state == State.DEAD:
		for wing in wings:
			wing.rotation.z = lerpf(wing.rotation.z, 0.0, minf(1.0, delta * 6.0))
		return
	var rate = 15.0 if state == State.ATTACK else 10.0
	var flap = sin(clock * rate) * 0.75
	for index in wings.size():
		wings[index].rotation.z = flap if index == 0 else -flap

func floor_height() -> float:
	var ray = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 8.0, 1, [get_rid()])
	var hit = get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.position.y if not hit.is_empty() else global_position.y - hover_height

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, delta * 6.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 6.0)
		velocity.y = 0.0 if is_on_floor() else velocity.y - 18.0 * delta
		move_and_slide()
		advance_presentation(delta)
		return
	clock += delta
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as DemoPlayer
	var horizontal := Vector3.ZERO
	var active = is_instance_valid(target) and target.can_act()
	if active:
		cooldown = maxf(0.0, cooldown - delta)
		hit_flash = maxf(0.0, hit_flash - delta)
		if presentation == null:
			visual.scale = Vector3.ONE * (1.0 + hit_flash * 0.7)
		if state == State.IDLE and global_position.distance_to(target.global_position) < detection_range and has_line_of_sight():
			state = State.CHASE
		if state != State.IDLE:
			horizontal = _combat(delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	var target_y = floor_height() + hover_height + sin(clock * 2.2) * BOB_AMPLITUDE
	velocity.y = clampf((target_y - global_position.y) * 4.0, -3.0, 3.0)
	var previous := global_position
	move_and_slide()
	var travel := global_position - previous
	advance_presentation(delta, Vector2(travel.x, travel.z).length())

## Returns the horizontal velocity for this frame and runs the attack state.
func _combat(delta: float) -> Vector3:
	var to_player = target.global_position - global_position
	to_player.y = 0.0
	var flat_distance = to_player.length()
	if flat_distance > 0.01:
		look_at(global_position + to_player, Vector3.UP)
	if state == State.ATTACK:
		windup -= delta
		if windup <= 0.0:
			if presentation != null:
				presentation.attack_contact()
			resolve_attack()
			state = State.CHASE
			cooldown = attack_cooldown
		return Vector3.ZERO
	var sight = has_line_of_sight()
	if sight and flat_distance <= attack_range and cooldown <= 0.0:
		state = State.ATTACK
		windup = windup_duration
		if presentation != null:
			presentation.begin_attack()
		CombatEvents.publish(self, &"enemy_charge", global_position)
		return Vector3.ZERO
	var away = -to_player.normalized() if flat_distance > 0.01 else Vector3.BACK
	if flat_distance > preferred_max or not sight:
		return _path_direction(delta) * move_speed
	if flat_distance < retreat_distance:
		return away * move_speed
	strafe_timer -= delta
	if strafe_timer <= 0.0:
		strafe_timer = 1.6
		strafe_sign = -strafe_sign
	var side = Vector3.UP.cross(away) * strafe_sign
	var drift = -away * 0.5 if flat_distance > preferred_min + 2.0 else (away * 0.5 if flat_distance < preferred_min else Vector3.ZERO)
	return (side + drift).normalized() * move_speed * 0.7

func _path_direction(delta: float) -> Vector3:
	var map = agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return Vector3.ZERO
	path_refresh -= delta
	if path_refresh <= 0.0:
		agent.target_position = target.global_position
		path_refresh = 0.25
	if agent.is_navigation_finished():
		return Vector3.ZERO
	var direction = agent.get_next_path_position() - global_position
	direction.y = 0.0
	return direction.normalized()

func has_line_of_sight() -> bool:
	if not is_instance_valid(target):
		return false
	var ray = PhysicsRayQueryParameters3D.create(global_position, target.camera.global_position, 3, [get_rid()])
	var hit = get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and hit.collider == target

func resolve_attack() -> void:
	if state == State.DEAD or not is_instance_valid(target) or not target.can_act() or not has_line_of_sight():
		return
	var origin = global_position - global_basis.z * 0.35
	CombatEvents.publish(self, &"enemy_cast", origin)
	var bolt = PROJECTILE.instantiate()
	bolt.configure(self, target.camera.global_position - origin, attack_damage, fireball_speed, 3, FIREBALL_TINT)
	bolt.scale = Vector3.ONE * 0.8
	get_parent().add_child(bolt)
	bolt.global_position = origin

func take_damage(amount: int, source: Node) -> int:
	var applied = super.take_damage(amount, source)
	if state == State.DEAD and applied > 0:
		# The base removes all collision; keep the floor so the body drops onto it.
		set_deferred("collision_mask", 1)
	return applied
