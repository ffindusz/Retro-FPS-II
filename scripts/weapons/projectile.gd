extends Node3D

@export var lifetime: float = 4.0
var direction: Vector3 = Vector3.FORWARD
var speed: float = 23.0
var damage: int = 28
var hit_mask: int = 5
var source: Node3D
var source_rid: RID
var tint: Color = Color("5fcbd7")
var resolved: bool = false
var player_owned: bool = false

func configure(actor: Node3D, travel: Vector3, amount: int, velocity: float, mask: int, color: Color) -> void:
	source = actor
	player_owned = actor is DemoPlayer
	if actor is CollisionObject3D:
		source_rid = actor.get_rid()
	direction = travel.normalized()
	damage = amount
	speed = velocity
	hit_mask = mask
	tint = color

func _ready() -> void:
	add_to_group("projectiles")
	PrimitiveArt.orb(self, Vector3.ZERO, 0.12, tint, 2.5)
	PrimitiveArt.orb(self, Vector3.ZERO, 0.055, Color.WHITE, 3.0)

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if resolved or get_tree().paused:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		resolved = true
		queue_free()
		return
	var destination = global_position + direction * speed * delta
	var exclude: Array[RID] = []
	if source_rid.is_valid():
		exclude.append(source_rid)
	var ray = PhysicsRayQueryParameters3D.create(global_position, destination, hit_mask, exclude)
	var hit = get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		global_position = hit.position
		resolved = true
		if hit.collider.has_method("take_damage"):
			CombatEvents.apply_hit(self, hit.collider, damage, source if is_instance_valid(source) else null, hit.position, hit.normal, &"magic", get_instance_id())
		else:
			CombatEvents.publish(self, &"world_impact", hit.position, {"normal": hit.normal, "weapon": &"magic", "player_owned": player_owned})
		queue_free()
	else:
		global_position = destination
