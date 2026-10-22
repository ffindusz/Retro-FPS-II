extends Area3D

@export_enum("Health", "Mana", "Key") var kind: int = 0
@export var amount: int = 25
@export var use_placeholder: bool = true
var consumed: bool = false
var elapsed: float = 0.0
@onready var visual: Node3D = $VisualRoot

func _ready() -> void:
	add_to_group("pickups")
	var colors = [Color("ba5144"), Color("4da2bc"), Color("e7ba5b")]
	if use_placeholder and kind == 2:
		PrimitiveArt.cylinder(visual, Vector3.ZERO, 0.07, 0.5, colors[kind])
		PrimitiveArt.orb(visual, Vector3(0, 0.32, 0), 0.14, colors[kind], 0.8)
		PrimitiveArt.box(visual, Vector3(0.1, -0.18, 0), Vector3(0.25, 0.08, 0.08), colors[kind])
	elif use_placeholder:
		PrimitiveArt.cylinder(visual, Vector3.ZERO, 0.19, 0.34, colors[kind])
		PrimitiveArt.cylinder(visual, Vector3(0, 0.22, 0), 0.09, 0.14, Color("d3bc88"))
	body_entered.connect(try_collect)

func try_collect(body: Node) -> bool:
	if consumed or not body is DemoPlayer or not body.can_act():
		return false
	var accepted = false
	var previous: int = body.health if kind == 0 else body.mana
	match kind:
		0: accepted = body.restore_health(amount)
		1: accepted = body.restore_mana(amount)
		2: accepted = body.collect_key()
	if accepted:
		consumed = true
		var restored: int = 1 if kind == 2 else (body.health if kind == 0 else body.mana) - previous
		CombatEvents.publish(self, [&"pickup_health", &"pickup_mana", &"pickup_key"][kind], global_position, {
			"amount": restored, "player_owned": true, "source_id": body.get_instance_id(),
			"event_id": "%d:pickup" % get_instance_id()
		})
		hide()
		queue_free()
	return accepted

func _process(delta: float) -> void:
	elapsed += delta
	visual.rotation.y += delta * 0.9
	visual.position.y = 0.65 + sin(elapsed * 2.0) * 0.08
