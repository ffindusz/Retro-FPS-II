extends Node3D
## Small visual-only impact; no collision, damage, timer callbacks or actor references.

var tint: Color = Color("efb76f")
var elapsed: float = 0.0
var lifetime: float = 0.32

func _ready() -> void:
	add_to_group("combat_effects")
	for index in range(5):
		var angle = float(index) * TAU / 5.0
		var shard = PrimitiveArt.box(self, Vector3(cos(angle), sin(angle), 0.1) * 0.025, Vector3(0.008, 0.055, 0.008), tint)
		shard.rotation.z = angle - PI / 2.0
		shard.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shard.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	scale = Vector3.ONE * (0.5 + elapsed * 3.0)
	for shard in get_children():
		shard.position *= 1.0 + delta * 4.0
		shard.material_override.albedo_color.a = 1.0 - elapsed / lifetime
