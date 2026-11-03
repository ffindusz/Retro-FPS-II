@tool
class_name LevelPlacement
extends Node3D
## Saved authoring data. Preview descendants are transient; gameplay is spawned by the level.

# Append new kinds only: saved maps store the integer value.
enum Kind { PLAYER_START, WARDEN, ADEPT, HEALTH, MANA, KEY, EXIT, TORCH, URN, AMBIENCE, BRAZIER, LANTERN, CRYSTAL_LAMP }
const LABELS := ["Player Start", "Warden", "Adept", "Health", "Mana", "Ember Key", "Exit Gate", "Torch", "Urn", "Crypt Ambience", "Brazier", "Wall Lantern", "Crystal Lamp"]
const FIXTURES := {Kind.BRAZIER: 0, Kind.LANTERN: 1, Kind.CRYSTAL_LAMP: 2}
@export var kind: Kind = Kind.PLAYER_START:
	set(value):
		kind = value
		_refresh_later()
@export_range(1, 100, 1) var amount: int = 25
@export var zone_size := Vector3(8, 4, 8):
	set(value):
		zone_size = value
		_refresh_later()
var preview: Node3D
var preview_pending: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_later()

func _refresh_later() -> void:
	if Engine.is_editor_hint() and is_inside_tree() and not preview_pending:
		preview_pending = true
		_refresh_preview.call_deferred()

func _refresh_preview() -> void:
	preview_pending = false
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	# Editor duplication may copy transient children; do not retain a second preview.
	for child in get_children():
		if child.has_meta("cinderkeep_preview"):
			remove_child(child)
			child.queue_free()
	preview = Node3D.new()
	preview.name = "EditorPreview"
	preview.set_meta("cinderkeep_preview", true)
	add_child(preview) # Deliberately no owner: never serialized.
	var label := Label3D.new()
	label.text = LABELS[kind]
	label.position.y = 2.3 if kind in [Kind.WARDEN, Kind.ADEPT, Kind.PLAYER_START, Kind.EXIT] else 1.5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 30
	preview.add_child(label)
	match kind:
		Kind.WARDEN:
			var body := load("res://assets/models/warden-animated/animate.glb").instantiate() as Node3D
			body.rotation.y = PI
			preview.add_child(body)
			var texture_source = load("res://assets/models/warden-animated/texture.glb").instantiate()
			var material: Material = texture_source.find_children("*", "MeshInstance3D", true, false)[0].get_active_material(0)
			for mesh in body.find_children("*", "MeshInstance3D", true, false):
				mesh.material_override = material
			texture_source.free()
		Kind.ADEPT, Kind.TORCH, Kind.URN:
			var paths := {Kind.ADEPT: "adept", Kind.TORCH: "wall_torch", Kind.URN: "stone_urn"}
			preview.add_child(load("res://scenes/models/%s.tscn" % paths[kind]).instantiate())
		Kind.PLAYER_START:
			var capsule := CapsuleMesh.new()
			capsule.radius = 0.28
			capsule.height = 1.8
			_mesh(capsule, Vector3(0, 0.9, 0), Color(0.3, 0.9, 0.5, 0.45))
		Kind.HEALTH, Kind.MANA:
			var bottle := CylinderMesh.new()
			bottle.top_radius = 0.19
			bottle.bottom_radius = 0.19
			bottle.height = 0.34
			_mesh(bottle, Vector3.UP * 0.65, Color("ba5144") if kind == Kind.HEALTH else Color("4da2bc"))
		Kind.KEY:
			var sphere := SphereMesh.new()
			sphere.radius = 0.15
			sphere.height = 0.3
			_mesh(sphere, Vector3.UP * 0.8, Color.GOLD)
		Kind.EXIT:
			var gate := BoxMesh.new()
			gate.size = Vector3(2.5, 3, 0.25)
			_mesh(gate, Vector3.UP * 1.5, Color("28343d"))
		Kind.BRAZIER, Kind.LANTERN, Kind.CRYSTAL_LAMP:
			var fixture := LightFixture.make(FIXTURES[kind])
			preview.add_child(fixture)
		Kind.AMBIENCE:
			var box := BoxMesh.new()
			box.size = zone_size.max(Vector3.ONE * 0.01)
			_mesh(box, Vector3.ZERO, Color(0.4, 0.7, 1.0, 0.12))
	if kind in [Kind.WARDEN, Kind.ADEPT, Kind.PLAYER_START, Kind.TORCH, Kind.EXIT, Kind.LANTERN]:
		var arrow := BoxMesh.new()
		arrow.size = Vector3(0.08, 0.08, 1.0)
		_mesh(arrow, Vector3(0, 0.12, -0.65), Color.YELLOW)

func _mesh(mesh: Mesh, point: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = point
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if color.a < 1:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override = material
	preview.add_child(node)
