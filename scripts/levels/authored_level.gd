extends "res://scripts/level.gd"
## Runtime adapter. Built geometry/nav and inert placements are the only map inputs.

const PLACEMENT = preload("res://scripts/levels/level_placement.gd")
const PRESENTATION = preload("res://scripts/levels/authored_presentation.gd")
const BAT = preload("res://scenes/enemies/bat_enemy.tscn")
const SKELETON = preload("res://scenes/enemies/skeleton_enemy.tscn")
const SKELETON_ARCHER = preload("res://scenes/enemies/skeleton_archer.tscn")
const STONE_GOLEM = preload("res://scenes/enemies/stone_golem.tscn")
const GOLEM_STATUE = preload("res://scenes/props/golem_statue.tscn")
const RUNE_DOOR = preload("res://scenes/props/rune_door.tscn")
const SEAL_HINT := "The seal holds while the dead still walk. Destroy them all."
const SEAL_OPEN := "The bone seal shatters. The sanctum lies open."
## A key marker this close to a golem marker is held by that golem until it dies.
const HELD_KEY_RANGE: float = 1.5
@export var level_title: String = "Untitled Level"
@export var baked_navigation: NavigationMesh
@export var authoring_source: String
@export var authoring_sha256: String
@export var authoring_dependencies_sha256: String
@export var authoring_build_version: int = 0
var markers: Array[Node] = []
var bone_seals: Array[KeyWard] = []
var golems: Array[Node] = []
var rune_door: RuneDoor

func _ready() -> void:
	markers = get_node("Placements").get_children()
	for marker in markers:
		if marker.kind == PLACEMENT.Kind.PLAYER_START:
			spawn_position = marker.position
		elif marker.kind in PLACEMENT.EXITS:
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
	var statues := 0
	for marker in markers:
		match marker.kind:
			PLACEMENT.Kind.WARDEN, PLACEMENT.Kind.ADEPT, PLACEMENT.Kind.SKELETON, PLACEMENT.Kind.SKELETON_ARCHER:
				var scenes := {PLACEMENT.Kind.WARDEN: MELEE, PLACEMENT.Kind.ADEPT: RANGED, PLACEMENT.Kind.SKELETON: SKELETON, PLACEMENT.Kind.SKELETON_ARCHER: SKELETON_ARCHER}
				var enemy = scenes[marker.kind].instantiate()
				enemy.transform = marker.transform
				add_child(enemy)
				enemy.target = player
			PLACEMENT.Kind.STONE_GOLEM:
				var golem = STONE_GOLEM.instantiate()
				golem.transform = marker.transform
				add_child(golem)
				golem.target = player
				golems.append(golem)
			PLACEMENT.Kind.GOLEM_STATUE:
				var statue := GOLEM_STATUE.instantiate() as Node3D
				statue.pose = statues
				statues += 1
				statue.transform = marker.transform
				add_child(statue)
			PLACEMENT.Kind.BONE_SEAL:
				var seal := KeyWard.new()
				seal.transform = marker.transform
				seal.player = player
				seal.hint_text = SEAL_HINT
				seal.open_text = SEAL_OPEN
				add_child(seal)
				seal.name = "BoneSeal"
				seal.add_to_group("bone_seals")
				bone_seals.append(seal)
			PLACEMENT.Kind.BAT:
				var bat = BAT.instantiate()
				bat.transform = marker.transform
				bat.position += Vector3.UP * bat.hover_height
				add_child(bat)
				bat.target = player
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
			PLACEMENT.Kind.BRAZIER, PLACEMENT.Kind.LANTERN, PLACEMENT.Kind.CRYSTAL_LAMP:
				# Presentation-only fixture; the level presentation drives its clock.
				var fixture := LightFixture.make(PLACEMENT.FIXTURES[marker.kind])
				fixture.transform = marker.transform
				add_child(fixture)
			PLACEMENT.Kind.EXIT:
				var gate := Node3D.new()
				gate.name = "ExitVisual"
				gate.transform = marker.transform
				geometry.add_child(gate)
				PrimitiveArt.box(gate, Vector3.UP * 1.5, Vector3(2.5, 3, 0.25), Color("28343d"))
				PrimitiveArt.orb(gate, Vector3(0, 1.8, 0.2), 0.2, Color.GOLD, 0.8)
			PLACEMENT.Kind.RUNE_DOOR:
				rune_door = RUNE_DOOR.instantiate()
				rune_door.transform = marker.transform
				add_child(rune_door)
				rune_door.passed.connect(_on_rune_door_passed)
	# Bone seals hold until every other enemy has died; golems are the bosses behind them.
	for seal in bone_seals:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.is_inside_tree() and is_ancestor_of(enemy) and not enemy in golems:
				seal.add_guard(enemy)
		if seal.guards.is_empty():
			seal.open.call_deferred()
	for golem in golems:
		for pickup in get_tree().get_nodes_in_group("pickups"):
			if is_ancestor_of(pickup) and pickup.kind == 2 and Vector2(pickup.position.x, pickup.position.z).distance_to(Vector2(golem.position.x, golem.position.z)) <= HELD_KEY_RANGE:
				golem.hold_key(pickup)

## A Rune Door takes the key at its socket and finishes the level once the player walks through.
func interact_exit() -> bool:
	if rune_door == null:
		return super.interact_exit()
	if exit_used:
		return false
	return rune_door.interact(player)

func _on_rune_door_passed() -> void:
	if exit_used:
		return
	exit_used = true
	completed.emit()
