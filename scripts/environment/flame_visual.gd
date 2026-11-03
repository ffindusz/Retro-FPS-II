@tool
class_name FlameVisual
extends MeshInstance3D
## Presentation-only billboard flame. FortressPresentation drives it from the run clock.

const SHADER = preload("res://resources/shaders/flame.gdshader")

var flame_material: ShaderMaterial
var clock: float = 0.0
var intensity: float = 1.0

static func create(size: Vector2, seed_value: float, core: Color = Color(1.0, 0.86, 0.55), edge: Color = Color(0.95, 0.36, 0.08)) -> FlameVisual:
	var flame := FlameVisual.new()
	flame.name = "Flame"
	var quad := QuadMesh.new()
	quad.size = size
	quad.center_offset = Vector3(0, size.y / 2.0, 0)
	flame.mesh = quad
	flame.flame_material = ShaderMaterial.new()
	flame.flame_material.shader = SHADER
	flame.flame_material.set_shader_parameter("seed", seed_value)
	flame.flame_material.set_shader_parameter("core_color", core)
	flame.flame_material.set_shader_parameter("edge_color", edge)
	flame.material_override = flame.flame_material
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return flame

func set_state(value: float, level: float) -> void:
	clock = value
	intensity = level
	flame_material.set_shader_parameter("clock", value)
	flame_material.set_shader_parameter("intensity", level)
