class_name DemoPlayer
extends CharacterBody3D

signal stats_changed
signal died
signal message(text: String)
@export var move_speed: float = 6.5
@export var jump_speed: float = 6.0
@export var gravity: float = 18.0
@export var sensitivity: float = 0.0022
@export var max_health: int = 100
@export var max_mana: int = 60
var health: int = 100
var mana: int = 60
var has_key: bool = false
var attack_blocked_until_release: bool = true
var weapon_slot: int:
	get: return weapons.slot
@onready var pivot: Node3D = $LookPivot
@onready var camera: Camera3D = $LookPivot/Camera
@onready var weapons = $Weapons
@onready var viewmodels = $Viewmodels

func _ready() -> void:
	health = max_health
	mana = max_mana
	add_to_group("player")
	weapons.fired.connect(viewmodels.animate_attack)
	weapons.selected.connect(viewmodels.select)

func can_act() -> bool:
	return health > 0 and is_inside_tree() and not get_tree().paused

func _physics_process(delta: float) -> void:
	if not can_act():
		return
	move_player(Input.get_vector("move_left", "move_right", "move_forward", "move_back"), delta, Input.is_action_just_pressed("jump"))
	if not Input.is_action_pressed("attack"):
		attack_blocked_until_release = false
	if Input.is_action_pressed("attack") and not attack_blocked_until_release:
		weapons.try_attack()
	if global_position.y < -10.0:
		take_damage(max_health, null)

func move_player(input: Vector2, delta: float, jump_pressed: bool) -> void:
	var direction = basis * Vector3(input.x, 0.0, input.y).limit_length(1.0)
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if is_on_floor():
		velocity.y = jump_speed if jump_pressed else 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()

func apply_look(relative: Vector2) -> void:
	rotate_y(-relative.x * sensitivity)
	pivot.rotation.x = clampf(pivot.rotation.x - relative.y * sensitivity, deg_to_rad(-85.0), deg_to_rad(85.0))

func _unhandled_input(event: InputEvent) -> void:
	if not can_act() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		apply_look(event.relative)
	if event.is_action_pressed("weapon_melee"):
		weapons.select(0)
	if event.is_action_pressed("weapon_magic"):
		weapons.select(1)
	if event.is_action_pressed("interact"):
		var level = get_parent()
		if level.has_method("interact_exit"):
			level.interact_exit()

func take_damage(amount: int, _source: Node) -> int:
	if not can_act() or amount <= 0:
		return 0
	var applied = mini(health, amount)
	health = maxi(0, health - amount)
	stats_changed.emit()
	message.emit("You were struck!" if health > 0 else "Your flame goes out.")
	CombatEvents.publish(self, &"player_hurt", camera.global_position, {"amount": applied})
	if health == 0:
		velocity = Vector3.ZERO
		died.emit()
	return applied

func restore_health(amount: int) -> bool:
	if not can_act() or amount <= 0 or health >= max_health:
		return false
	health = mini(max_health, health + amount)
	stats_changed.emit()
	return true

func restore_mana(amount: int) -> bool:
	if not can_act() or amount <= 0 or mana >= max_mana:
		return false
	mana = mini(max_mana, mana + amount)
	stats_changed.emit()
	return true

func collect_key() -> bool:
	if not can_act() or has_key:
		return false
	has_key = true
	stats_changed.emit()
	message.emit("Ember key claimed. Return to the courtyard gate.")
	return true
