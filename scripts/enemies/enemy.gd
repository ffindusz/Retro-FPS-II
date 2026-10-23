extends CharacterBody3D

signal died
enum State { IDLE, CHASE, ATTACK, DEAD }
const PROJECTILE = preload("res://scenes/weapons/projectile.tscn")
@export_enum("Melee", "Ranged") var archetype: int = 0
@export var use_placeholder: bool = true
@export var model_scene: PackedScene
@export var max_health: int = 68
@export var move_speed: float = 2.6
@export var detection_range: float = 18.0
@export var attack_damage: int = 12
@export var attack_cooldown: float = 1.6
@export var windup_duration: float = 0.55
@export var ranged_speed: float = 10.0
var health: int
var state: State = State.IDLE
var target: DemoPlayer
var cooldown: float = 0.0
var windup: float = 0.0
var path_refresh: float = 0.0
var hit_flash: float = 0.0
var presentation: Node3D
@onready var visual: Node3D = $VisualRoot
@onready var agent: NavigationAgent3D = $NavigationAgent

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	if not use_placeholder and model_scene != null:
		var model = model_scene.instantiate()
		visual.add_child(model)
		if archetype == 0 and model.has_method("advance_visual"):
			presentation = model
	else:
		_build_placeholder()
	agent.path_desired_distance = 0.4
	agent.target_desired_distance = 0.6
	agent.radius = 0.4

func _build_placeholder() -> void:
	var robe = Color("5b3732") if archetype == 0 else Color("324957")
	PrimitiveArt.cylinder(visual, Vector3(0, 0.68, 0), 0.34, 1.25, robe)
	PrimitiveArt.orb(visual, Vector3(0, 1.48, 0), 0.25, Color("9b937f"))
	PrimitiveArt.box(visual, Vector3(0, 1.48, -0.24), Vector3(0.27, 0.06, 0.035), Color("edaa4c"))
	PrimitiveArt.box(visual, Vector3(0, 1.17, 0), Vector3(0.92, 0.17, 0.4), robe.lightened(0.15))
	if archetype == 0:
		PrimitiveArt.box(visual, Vector3(0.5, 0.8, -0.24), Vector3(0.1, 0.9, 0.1), Color("94978e"))
	else:
		PrimitiveArt.cylinder(visual, Vector3(0.5, 0.9, 0), 0.045, 1.75, Color("756044"))
		PrimitiveArt.orb(visual, Vector3(0.5, 1.85, 0), 0.14, Color("db803e"), 1.5)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		advance_presentation(delta)
		return
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as DemoPlayer
	if not is_instance_valid(target) or not target.can_act():
		return
	cooldown = maxf(0.0, cooldown - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	if presentation == null:
		visual.scale = Vector3.ONE * (1.0 + hit_flash * 0.7)
	var distance = global_position.distance_to(target.global_position)
	if state == State.IDLE:
		if distance < detection_range and has_line_of_sight():
			state = State.CHASE
		else:
			advance_presentation(delta)
			return
	var flat_target = Vector3(target.global_position.x, global_position.y, target.global_position.z)
	if global_position.distance_squared_to(flat_target) > 0.01:
		look_at(flat_target, Vector3.UP)
	velocity.x = 0.0
	velocity.z = 0.0
	if state == State.ATTACK:
		windup -= delta
		if presentation == null:
			visual.position.y = sin(maxf(windup, 0.0) * 18.0) * 0.07
			visual.rotation.x = -0.16 - 0.1 * (1.0 - clampf(windup / windup_duration, 0.0, 1.0))
		if windup <= 0.0:
			if presentation != null:
				presentation.attack_contact()
			resolve_attack()
			state = State.CHASE
			cooldown = attack_cooldown
			if presentation == null:
				visual.position.y = 0.0
				visual.rotation.x = 0.0
	else:
		if presentation == null:
			visual.rotation.x = 0.0
		var range_limit = 10.0 if archetype == 1 else 1.9
		if distance <= range_limit and has_line_of_sight():
			if cooldown <= 0.0:
				state = State.ATTACK
				windup = windup_duration
				if presentation != null:
					presentation.begin_attack()
				CombatEvents.publish(self, &"enemy_melee_windup" if archetype == 0 else &"enemy_charge", global_position + Vector3.UP * 1.3)
		else:
			_chase(delta)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	var previous_position := global_position
	move_and_slide()
	var travel := global_position - previous_position
	advance_presentation(delta, Vector2(travel.x, travel.z).length())

func advance_presentation(delta: float, movement_distance: float = 0.0) -> void:
	if presentation != null:
		if state == State.DEAD and not presentation.dead:
			presentation.die()
		presentation.advance_visual(delta, movement_distance, state == State.ATTACK, windup, windup_duration)

func _chase(delta: float) -> void:
	var map = agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return
	path_refresh -= delta
	if path_refresh <= 0.0:
		agent.target_position = target.global_position
		path_refresh = 0.25
	if agent.is_navigation_finished():
		return
	var next = agent.get_next_path_position()
	var direction = (next - global_position)
	direction.y = 0.0
	direction = direction.normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

func has_line_of_sight() -> bool:
	if not is_instance_valid(target):
		return false
	var start = global_position + Vector3.UP * 1.25
	var ray = PhysicsRayQueryParameters3D.create(start, target.camera.global_position, 3, [get_rid()])
	var hit = get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and hit.collider == target

func resolve_attack() -> void:
	if state == State.DEAD or not is_instance_valid(target) or not target.can_act() or not has_line_of_sight():
		return
	if archetype == 0:
		if global_position.distance_to(target.global_position) <= 1.9:
			target.take_damage(attack_damage, self)
	else:
		var origin = global_position + Vector3.UP * 1.3
		CombatEvents.publish(self, &"enemy_cast", origin)
		var direction = (target.camera.global_position - origin).normalized()
		var bolt = PROJECTILE.instantiate()
		bolt.configure(self, direction, attack_damage, ranged_speed, 3, Color("e59143"))
		get_parent().add_child(bolt)
		bolt.global_position = origin

func take_damage(amount: int, source: Node) -> int:
	if state == State.DEAD or get_tree().paused or amount <= 0:
		return 0
	var applied = mini(health, amount)
	health = maxi(0, health - amount)
	hit_flash = 0.2
	if source is DemoPlayer:
		target = source
		if state == State.IDLE:
			state = State.CHASE
	if health == 0:
		state = State.DEAD
		windup = 0.0
		velocity = Vector3.ZERO
		visual.rotation.x = 0.0
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		if presentation != null:
			presentation.die()
		else:
			var tween = create_tween()
			tween.tween_property(visual, "rotation:z", PI / 2.0, 0.3)
			tween.parallel().tween_property(visual, "scale", Vector3(0.8, 0.55, 0.8), 0.3)
		died.emit()
	elif presentation != null:
		presentation.show_hit()
	return applied
