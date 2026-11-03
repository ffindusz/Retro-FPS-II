@tool
class_name LightFixture
extends Node3D
## Procedural, presentation-only light fixture: no collision, no gameplay effect.
## FortressPresentation drives it from the run clock, so it freezes on pause and resets on restart.

enum Kind { BRAZIER, LANTERN, CRYSTAL }
const IRON = Color("2c3136")
const STONE = Color("6b6558")
const BRASS = Color("a58b58")
const CRYSTAL_GLOW = Color("6fd6ff")

@export var kind: Kind = Kind.BRAZIER
var phase: float = 0.0
var light: OmniLight3D
var base_energy: float = 1.0
var flame: FlameVisual
var crystal: MeshInstance3D
var crystal_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var built: bool = false

static func make(fixture_kind: Kind) -> LightFixture:
	var fixture := LightFixture.new()
	fixture.kind = fixture_kind
	return fixture

func _ready() -> void:
	build()

func build() -> void:
	if built:
		return
	built = true
	add_to_group("light_fixtures")
	match kind:
		Kind.BRAZIER:
			_build_brazier()
		Kind.LANTERN:
			_build_lantern()
		Kind.CRYSTAL:
			_build_crystal()
	for node in find_children("*", "GeometryInstance3D", true, false):
		if node != flame:
			(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_clock(0.0)

func _light(point: Vector3, color: Color, energy: float, range_m: float) -> void:
	light = OmniLight3D.new()
	light.name = "FixtureLight"
	light.position = point
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	light.omni_attenuation = 1.4
	light.shadow_enabled = false
	base_energy = energy
	add_child(light)

func _cone(point: Vector3, top: float, bottom: float, height: float, color: Color, segments: int = 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	return PrimitiveArt.mesh_node(self, mesh, point, color)

func _metal(node: MeshInstance3D) -> MeshInstance3D:
	var material := node.material_override as StandardMaterial3D
	material.metallic = 0.6
	material.roughness = 0.6
	return node

func _build_brazier() -> void:
	_cone(Vector3(0, 0.04, 0), 0.26, 0.3, 0.08, STONE)
	_metal(_cone(Vector3(0, 0.34, 0), 0.07, 0.11, 0.56, IRON, 8))
	_metal(_cone(Vector3(0, 0.72, 0), 0.42, 0.24, 0.24, IRON))
	_metal(_cone(Vector3(0, 0.845, 0), 0.43, 0.43, 0.03, BRASS))
	var coals := PrimitiveArt.mesh_node(self, _disc(0.36), Vector3(0, 0.83, 0), Color("ff7a2a"), 2.5)
	coals.name = "Coals"
	flame = FlameVisual.create(Vector2(0.75, 1.15), 3.7)
	flame.position = Vector3(0, 0.8, 0)
	add_child(flame)
	_light(Vector3(0, 1.3, 0), Color("ffa860"), 1.6, 5.0)

func _disc(radius: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.02
	mesh.radial_segments = 12
	return mesh

func _build_lantern() -> void:
	# The marker is the wall bracket point; the arm reaches along local -Z, away from the wall.
	_metal(PrimitiveArt.box(self, Vector3(0, 0, -0.03), Vector3(0.16, 0.24, 0.06), IRON))
	_metal(PrimitiveArt.box(self, Vector3(0, 0.05, -0.3), Vector3(0.04, 0.04, 0.55), IRON))
	for index in range(3):
		_metal(PrimitiveArt.box(self, Vector3(0, -0.05 - index * 0.09, -0.55), Vector3(0.02, 0.07, 0.02), IRON))
	var centre := Vector3(0, -0.52, -0.55)
	_metal(_cone(centre + Vector3(0, 0.2, 0), 0.03, 0.15, 0.1, IRON, 4)).rotation.y = PI / 4.0
	_metal(_cone(centre - Vector3(0, 0.18, 0), 0.13, 0.13, 0.04, IRON, 4)).rotation.y = PI / 4.0
	for x in [-0.09, 0.09]:
		for z in [-0.09, 0.09]:
			_metal(PrimitiveArt.box(self, centre + Vector3(x, 0, z), Vector3(0.025, 0.34, 0.025), IRON))
	var glass := PrimitiveArt.box(self, centre, Vector3(0.17, 0.3, 0.17), Color("ffb85c"))
	glass_material = glass.material_override
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color = Color(1.0, 0.72, 0.36, 0.35)
	glass_material.emission_enabled = true
	glass_material.emission = Color("ffad55")
	glass_material.emission_energy_multiplier = 0.8
	flame = FlameVisual.create(Vector2(0.14, 0.24), 8.1)
	flame.position = centre - Vector3(0, 0.13, 0)
	add_child(flame)
	_light(centre, Color("ffc070"), 1.2, 4.0)

func _build_crystal() -> void:
	PrimitiveArt.box(self, Vector3(0, 0.05, 0), Vector3(0.5, 0.1, 0.5), STONE)
	PrimitiveArt.box(self, Vector3(0, 0.5, 0), Vector3(0.32, 0.8, 0.32), STONE)
	_metal(_cone(Vector3(0, 0.95, 0), 0.24, 0.18, 0.1, BRASS, 6))
	for angle in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
		var prong := _metal(PrimitiveArt.box(self, Vector3(sin(angle) * 0.17, 1.12, cos(angle) * 0.17), Vector3(0.03, 0.3, 0.03), BRASS))
		prong.rotation = Vector3(cos(angle) * 0.25, 0, -sin(angle) * 0.25)
	crystal = MeshInstance3D.new()
	crystal.name = "Crystal"
	var upper := _octahedron()
	crystal.mesh = upper
	crystal_material = StandardMaterial3D.new()
	crystal_material.albedo_color = Color("0f5f8f")
	crystal_material.emission_enabled = true
	crystal_material.emission = Color("1f9fff")
	crystal_material.roughness = 0.2
	crystal.material_override = crystal_material
	crystal.position = Vector3(0, 1.3, 0)
	add_child(crystal)
	_light(Vector3(0, 1.35, 0), CRYSTAL_GLOW, 1.3, 3.5)

func _octahedron() -> ArrayMesh:
	var points := [Vector3(0, 0.22, 0), Vector3(0, -0.16, 0), Vector3(0.1, 0, 0), Vector3(0, 0, 0.1), Vector3(-0.1, 0, 0), Vector3(0, 0, -0.1)]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(4):
		var a: Vector3 = points[2 + index]
		var b: Vector3 = points[2 + (index + 1) % 4]
		for tri in [[points[0], b, a], [points[1], a, b]]:
			for vertex in tri:
				tool.add_vertex(vertex)
	tool.generate_normals()
	return tool.commit()

func set_clock(value: float) -> void:
	var elapsed := maxf(0.0, value)
	if kind == Kind.CRYSTAL:
		var pulse := 0.2 * sin(elapsed * TAU * 0.25 + phase) + 0.05 * sin(elapsed * TAU * 0.9 + phase * 1.3)
		light.light_energy = base_energy * (1.0 + pulse)
		crystal_material.emission_energy_multiplier = 1.3 * (1.0 + pulse * 1.5)
		crystal.position.y = 1.3 + 0.03 * sin(elapsed * TAU * 0.2 + phase)
		crystal.rotation.y = elapsed * 0.4 + phase
	else:
		var modulation := FortressPresentation.flicker(elapsed, phase)
		light.light_energy = base_energy * (1.0 + modulation)
		flame.set_state(elapsed, 1.0 + modulation)
		if glass_material != null:
			glass_material.emission_energy_multiplier = 0.8 * (1.0 + modulation)
