extends "res://scripts/level.gd"
## Runtime adapter. Built geometry/nav and inert placements are the only map inputs.

const PLACEMENT = preload("res://scripts/levels/level_placement.gd")
const PRESENTATION = preload("res://scripts/levels/authored_presentation.gd")
@export var level_title: String = "Untitled Level"
@export var baked_navigation: NavigationMesh
@export var authoring_source: String
@export var authoring_sha256: String
var markers: Array[Node] = []

func _ready() -> void:
	markers = get_node("Placements").get_children()
	for marker in markers:
		if marker.kind == PLACEMENT.Kind.PLAYER_START:
			spawn_position = marker.position
		elif marker.kind == PLACEMENT.Kind.EXIT:
			exit_position = marker.position
	# Base gameplay services are reused, but not coordinate-specific demo atmosphere.
	var atmosphere := atmosphere_enabled
	atmosphere_enabled = false
	super._ready()
	atmosphere_enabled = atmosphere
	for marker in markers:
		if marker.kind == PLACEMENT.Kind.PLAYER_START:
			player.rotation.y = marker.rotation.y
	if atmosphere:
		presentation = PRESENTATION.new()
		add_child(presentation)
		presentation.setup(self)
		ambience = FortressAmbience.new()
		ambience.use_authored_zones = true
		for marker in markers:
			if marker.kind == PLACEMENT.Kind.AMBIENCE:
				ambience.authored_zones.append(AABB(marker.global_position - marker.zone_size / 2.0, marker.zone_size))
		add_child(ambience)

func build_geometry() -> void:
	geometry = get_node("Geometry")

func _setup_navigation() -> void:
	navigation = NavigationRegion3D.new()
	navigation.name = "Navigation"
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map, 0.2)
	NavigationServer3D.map_set_cell_height(get_world_3d().navigation_map, 0.1)
	navigation.navigation_mesh = baked_navigation
	add_child(navigation)

func _populate() -> void:
	for marker in markers:
		match marker.kind:
			PLACEMENT.Kind.WARDEN, PLACEMENT.Kind.ADEPT:
				var enemy = (MELEE if marker.kind == PLACEMENT.Kind.WARDEN else RANGED).instantiate()
				enemy.transform = marker.transform
				add_child(enemy)
				enemy.target = player
			PLACEMENT.Kind.HEALTH, PLACEMENT.Kind.MANA, PLACEMENT.Kind.KEY:
				var pickup = PICKUP.instantiate()
				pickup.kind = marker.kind - PLACEMENT.Kind.HEALTH
				pickup.amount = marker.amount
				pickup.position = marker.position
				add_child(pickup)
			PLACEMENT.Kind.TORCH, PLACEMENT.Kind.URN:
				var path := "torch" if marker.kind == PLACEMENT.Kind.TORCH else "urn"
				var prop := load("res://scenes/props/%s.tscn" % path).instantiate() as Node3D
				prop.transform = marker.transform
				add_child(prop)
			PLACEMENT.Kind.EXIT:
				var gate := Node3D.new()
				gate.name = "ExitVisual"
				gate.transform = marker.transform
				geometry.add_child(gate)
				PrimitiveArt.box(gate, Vector3.UP * 1.5, Vector3(2.5, 3, 0.25), Color("28343d"))
				PrimitiveArt.orb(gate, Vector3(0, 1.8, 0.2), 0.2, Color.GOLD, 0.8)
