extends "res://scripts/enemies/enemy.gd"
## Stone golem boss. Stands dormant like a statue until the player comes within wake range with a
## clear line of sight, or hits it. Then it wakes up, walks at the player and slams its hammer.
## It can hold the level's ember key, which stays hidden until the golem dies.

signal awakened
const WAKE_TEXT := "The stone golem awakens!"
const KEY_TEXT := "The golem crumbles. The ember key glows in the rubble."
const KEY_REVEAL_DELAY: float = 1.0
## How long the boss bar stays up after the golem dies.
const BAR_LINGER: float = 2.5
@export var boss_name: String = "Stone Golem"
@export var wake_range: float = 6.0
@export var awaken_duration: float = 1.6
var dormant: bool = true
var awakening: float = 0.0
var held_key: Node3D
var key_revealed: bool = false

func _ready() -> void:
	super._ready()
	add_to_group("bosses")
	died.connect(_on_died)

## The key pickup stays hidden and uncollectable until the golem dies.
func hold_key(pickup: Node3D) -> void:
	held_key = pickup
	pickup.hide()
	pickup.set_deferred("monitoring", false)
	pickup.process_mode = Node.PROCESS_MODE_DISABLED

func is_awake() -> bool:
	return not dormant and state != State.DEAD

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		super._physics_process(delta)
		return
	if dormant:
		if not is_instance_valid(target):
			target = get_tree().get_first_node_in_group("player") as DemoPlayer
		if is_instance_valid(target) and target.can_act() and global_position.distance_to(target.global_position) <= wake_range and has_line_of_sight():
			awaken()
		return
	if awakening > 0.0:
		if is_instance_valid(target) and not target.can_act():
			return
		awakening = maxf(0.0, awakening - delta)
		advance_presentation(delta)
		if awakening == 0.0:
			state = State.CHASE
		return
	super._physics_process(delta)

func awaken() -> void:
	if not dormant or state == State.DEAD:
		return
	dormant = false
	awakening = awaken_duration
	add_to_group("active_bosses")
	if presentation != null and presentation.has_method("awaken"):
		presentation.awaken()
	CombatEvents.publish(self, &"boss_awaken", global_position + Vector3.UP * 2.0)
	if is_instance_valid(target):
		target.message.emit(WAKE_TEXT)
	awakened.emit()

func take_damage(amount: int, source: Node) -> int:
	if dormant and state != State.DEAD and amount > 0 and not get_tree().paused:
		if source is DemoPlayer:
			target = source
		awaken()
	return super.take_damage(amount, source)

func resolve_attack() -> void:
	if state == State.DEAD:
		return
	CombatEvents.publish(self, &"golem_slam", global_position - global_basis.z * 1.5)
	super.resolve_attack()

func _on_died() -> void:
	awakening = 0.0
	get_tree().create_timer(KEY_REVEAL_DELAY, false).timeout.connect(_reveal_key)
	get_tree().create_timer(BAR_LINGER, false).timeout.connect(func() -> void:
		if is_inside_tree():
			remove_from_group("active_bosses"))

func _reveal_key() -> void:
	if key_revealed or not is_instance_valid(held_key) or not is_inside_tree():
		return
	key_revealed = true
	held_key.global_position = global_position + Vector3.UP * 0.25
	held_key.process_mode = Node.PROCESS_MODE_INHERIT
	held_key.show()
	held_key.set_deferred("monitoring", true)
	var visual := held_key.get_node_or_null("VisualRoot") as Node3D
	if visual != null:
		visual.scale = Vector3.ONE * 0.2
		visual.create_tween().tween_property(visual, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_instance_valid(target):
		target.message.emit(KEY_TEXT)
