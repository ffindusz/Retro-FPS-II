@tool
extends RefCounted
## Produces ordinary editable Cyclops blocks, not a runtime level generator.

const AUTHORING = preload("res://addons/cinderkeep_level_tools/authoring_level.gd")
const PLACEMENT = preload("res://scripts/levels/level_placement.gd")
const FLOOR = preload("res://resources/materials/mapping_floor.tres")
const WALL = preload("res://resources/materials/mapping_wall.tres")
const BUILDER = preload("res://addons/cinderkeep_level_tools/level_builder.gd")

static func block(root: Node3D, label: String, point: Vector3, size: Vector3, floor_material: bool = false) -> CyclopsBlock:
	var node := CyclopsBlock.new()
	node.name = label
	node.position = point
	node.lightmap_texel_size = 0.0
	var volume := ConvexVolume.new()
	volume.init_block(AABB(-size / 2.0, size), Transform2D.IDENTITY, 0)
	node.mesh_vector_data = volume.to_mesh_vector_data()
	node.materials = [FLOOR if floor_material else WALL]
	root.get_node("Architecture").add_child(node, true)
	return node

## Convex prism block: a horizontal polygon (local XZ points around the block origin) extruded
## from y = -height/2 to +height/2. Used for round floors, dais tiers and curved wall segments.
static func prism(root: Node3D, label: String, point: Vector3, outline: Array[Vector3], height: float, floor_material: bool = false) -> CyclopsBlock:
	var node := CyclopsBlock.new()
	node.name = label
	node.position = point
	node.lightmap_texel_size = 0.0
	var base: Array[Vector3] = []
	for corner in outline:
		base.append(Vector3(corner.x, -height / 2.0, corner.z))
	var volume := ConvexVolume.new()
	volume.init_prism(base, Vector3.UP * height, Transform2D.IDENTITY, 0)
	node.mesh_vector_data = volume.to_mesh_vector_data()
	node.materials = [FLOOR if floor_material else WALL]
	root.get_node("Architecture").add_child(node, true)
	return node

## Round convex block with sloped sides: radius `bottom` at the base, `top` at the top, origin at
## mid-height. Gentle slopes stay walkable for the player and baked navigation (no step-up needed).
static func frustum(root: Node3D, label: String, point: Vector3, bottom: float, top: float, height: float, segments: int, floor_material: bool = false) -> CyclopsBlock:
	var node := CyclopsBlock.new()
	node.name = label
	node.position = point
	node.lightmap_texel_size = 0.0
	var points := PackedVector3Array()
	for corner in circle(bottom, segments):
		points.append(corner - Vector3.UP * height / 2.0)
	for corner in circle(top, segments):
		points.append(corner + Vector3.UP * height / 2.0)
	var volume := ConvexVolume.new()
	volume.init_from_points(points, Transform2D.IDENTITY, 0)
	node.mesh_vector_data = volume.to_mesh_vector_data()
	node.materials = [FLOOR if floor_material else WALL]
	root.get_node("Architecture").add_child(node, true)
	return node

## Regular polygon of the given radius in the XZ plane, first corner offset by half a segment.
static func circle(radius: float, segments: int) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for index in range(segments):
		var angle := TAU * (index + 0.5) / segments
		points.append(Vector3(sin(angle) * radius, 0, cos(angle) * radius))
	return points

## Round wall made of one block per segment. Segment k is centred at angle k * TAU / segments,
## measured from +Z towards +X; segments listed in `gaps` are left open.
static func ring(root: Node3D, label: String, center: Vector3, inner: float, outer: float, height: float, segments: int, gaps: Array[int] = []) -> void:
	for index in range(segments):
		if index in gaps:
			continue
		var from := TAU * (index - 0.5) / segments
		var to := TAU * (index + 0.5) / segments
		var middle := TAU * index / segments
		var mid := Vector3(sin(middle), 0, cos(middle)) * (inner + outer) / 2.0
		var corners: Array[Vector3] = []
		for corner in [[from, inner], [to, inner], [to, outer], [from, outer]]:
			corners.append(Vector3(sin(corner[0]), 0, cos(corner[0])) * corner[1] - mid)
		prism(root, label, center + mid + Vector3.UP * height / 2.0, corners, height)

## Yaw that turns a -Z-facing placement at `from` toward `to`.
static func facing(from: Vector3, to: Vector3) -> float:
	var direction := to - from
	return atan2(-direction.x, -direction.z)

static func placement(root: Node3D, label: String, kind: int, point: Vector3, yaw: float = 0.0) -> Node3D:
	var node := Node3D.new()
	node.set_script(PLACEMENT)
	node.name = label
	node.kind = kind
	node.position = point
	node.rotation.y = yaw
	root.get_node("Placements").add_child(node)
	return node

static func create_level(example: bool = false) -> Node3D:
	var root := _shell("MappingExample" if example else "NewLevel", "The Mason's Trial" if example else "New Cinderkeep Level", "res://scenes/levels/generated/mapping_example.tscn" if example else "res://scenes/levels/generated/new_level.tscn")
	if example:
		_example(root)
	else:
		block(root, "Floor", Vector3(0, -0.25, 0), Vector3(10, 0.5, 12), true)
		block(root, "WestWall", Vector3(-5.2, 2, 0), Vector3(0.4, 4, 12.8))
		block(root, "EastWall", Vector3(5.2, 2, 0), Vector3(0.4, 4, 12.8))
		block(root, "NorthWall", Vector3(0, 2, -6.2), Vector3(10, 4, 0.4))
		block(root, "SouthWall", Vector3(0, 2, 6.2), Vector3(10, 4, 0.4))
		placement(root, "PlayerStart", PLACEMENT.Kind.PLAYER_START, Vector3(0, 0, 4))
		placement(root, "EmberKey", PLACEMENT.Kind.KEY, Vector3(-3, 0, -3))
		placement(root, "ExitGate", PLACEMENT.Kind.EXIT, Vector3(3, 0, -4))
	BUILDER.own_recursive(root, root)
	return root

## Second test map: entrance hall, pillared gallery and a side chamber held by skeletons, and the
## round Golem Sanctum behind a bone seal that breaks when every skeleton is dead.
static func create_ossuary() -> Node3D:
	var root := _shell("Ossuary", "The Ossuary", "res://scenes/levels/generated/ossuary.tscn")
	# Floors: entrance hall (x -4..4, z 8..16), gallery (x -6..6, z -14..8), chamber (x 6..14, z -10..-2).
	block(root, "EntranceFloor", Vector3(0, -0.25, 12), Vector3(8, 0.5, 8), true)
	block(root, "GalleryFloor", Vector3(0, -0.25, -3), Vector3(12, 0.5, 22), true)
	block(root, "ChamberFloor", Vector3(10, -0.25, -6), Vector3(8, 0.5, 8), true)
	for x in [-4.2, 4.2]:
		block(root, "EntranceWall", Vector3(x, 2, 12), Vector3(0.4, 4, 8.4))
	block(root, "EntranceBack", Vector3(0, 2, 16.2), Vector3(8.8, 4, 0.4))
	for x in [-5.2, 5.2]:
		block(root, "GallerySouth", Vector3(x, 2, 8.2), Vector3(2.4, 4, 0.4))
	block(root, "GalleryWest", Vector3(-6.2, 2, -3), Vector3(0.4, 4, 22.8))
	# North wall with a 2 m doorway (x -1..1) into the passage to the sanctum.
	for x in [-3.7, 3.7]:
		block(root, "GalleryNorth", Vector3(x, 2, -14.2), Vector3(5.4, 4, 0.4))
	block(root, "SanctumPassageLintel", Vector3(0, 3.5, -14.2), Vector3(2, 1, 0.4))
	# East wall with a 2.4 m doorway into the chamber (z -7.2..-4.8).
	block(root, "GalleryEastNorth", Vector3(6.2, 2, -10.8), Vector3(0.4, 4, 7.2))
	block(root, "GalleryEastSouth", Vector3(6.2, 2, 1.8), Vector3(0.4, 4, 13.2))
	block(root, "ChamberLintel", Vector3(6.2, 3.7, -6), Vector3(0.4, 0.6, 2.4))
	block(root, "ChamberNorth", Vector3(10.2, 2, -10.2), Vector3(8.4, 4, 0.4))
	block(root, "ChamberSouth", Vector3(10.2, 2, -1.8), Vector3(8.4, 4, 0.4))
	block(root, "ChamberEast", Vector3(14.2, 2, -6), Vector3(0.4, 4, 8.8))
	# Pillars give cover from the archers down the gallery.
	for z in [3.0, -3.0, -9.0]:
		for x in [-3.0, 3.0]:
			block(root, "Pillar", Vector3(x, 2, z), Vector3(1, 4, 1))
	placement(root, "PlayerStart", PLACEMENT.Kind.PLAYER_START, Vector3(0, 0, 14))
	placement(root, "GallerySkeleton", PLACEMENT.Kind.SKELETON, Vector3(-1.5, 0, -1), PI)
	placement(root, "PillarSkeleton", PLACEMENT.Kind.SKELETON, Vector3(1.5, 0, -6), PI)
	placement(root, "ChamberSkeleton", PLACEMENT.Kind.SKELETON, Vector3(9.5, 0, -4), PI / 2.0)
	placement(root, "NorthArcher", PLACEMENT.Kind.SKELETON_ARCHER, Vector3(-1.5, 0, -12.5), PI)
	placement(root, "WestArcher", PLACEMENT.Kind.SKELETON_ARCHER, Vector3(-5, 0, -6), PI)
	placement(root, "ChamberArcher", PLACEMENT.Kind.SKELETON_ARCHER, Vector3(13, 0, -8.8), PI / 2.0)
	placement(root, "Health", PLACEMENT.Kind.HEALTH, Vector3(-2.5, 0, 11))
	placement(root, "Mana", PLACEMENT.Kind.MANA, Vector3(2.5, 0, 11))
	placement(root, "GalleryHealth", PLACEMENT.Kind.HEALTH, Vector3(-5, 0, 5))
	placement(root, "ChamberMana", PLACEMENT.Kind.MANA, Vector3(8, 0, -9))
	placement(root, "EntranceTorch", PLACEMENT.Kind.TORCH, Vector3(-3.8, 2.3, 12), PI / 2.0)
	placement(root, "GalleryTorchWest", PLACEMENT.Kind.TORCH, Vector3(-5.8, 2.3, 0), PI / 2.0)
	placement(root, "GalleryTorchEast", PLACEMENT.Kind.TORCH, Vector3(5.8, 2.3, 3), -PI / 2.0)
	placement(root, "NorthTorch", PLACEMENT.Kind.TORCH, Vector3(-5.8, 2.3, -11), PI / 2.0)
	placement(root, "ChamberTorch", PLACEMENT.Kind.TORCH, Vector3(13.8, 2.3, -6), -PI / 2.0)
	placement(root, "GalleryBrazier", PLACEMENT.Kind.BRAZIER, Vector3(5, 0, -7.5))
	placement(root, "NorthUrn", PLACEMENT.Kind.URN, Vector3(-5.3, 0, -13.3))
	placement(root, "ChamberUrn", PLACEMENT.Kind.URN, Vector3(13.3, 0, -9.3))
	var gallery := placement(root, "GalleryAmbience", PLACEMENT.Kind.AMBIENCE, Vector3(0, 1.5, -3))
	gallery.zone_size = Vector3(12, 3, 22)
	var chamber := placement(root, "ChamberAmbience", PLACEMENT.Kind.AMBIENCE, Vector3(10, 1.5, -6))
	chamber.zone_size = Vector3(8, 3, 8)
	_sanctum(root)
	BUILDER.own_recursive(root, root)
	return root

static func _shell(node_name: String, title: String, runtime_path: String) -> Node3D:
	var root := Node3D.new()
	root.set_script(AUTHORING)
	root.name = node_name
	root.level_title = title
	root.runtime_path = runtime_path
	for label in ["Architecture", "Placements"]:
		var group := Node3D.new()
		group.name = label
		root.add_child(group)
	var world := WorldEnvironment.new()
	world.name = "EditorEnvironment"
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("263143")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("9ba8b6")
	world.environment.ambient_light_energy = 0.8
	root.add_child(world)
	var light := DirectionalLight3D.new()
	light.name = "EditorLight"
	light.rotation_degrees = Vector3(-55, -30, 0)
	root.add_child(light)
	return root

static func _example(root: Node3D) -> void:
	block(root, "EntranceFloor", Vector3(0, -0.25, 10), Vector3(8, 0.5, 10), true)
	block(root, "CourtyardFloor", Vector3(0, -0.25, -1), Vector3(16, 0.5, 12), true)
	block(root, "CryptFloor", Vector3(13, -0.25, -3), Vector3(10, 0.5, 8), true)
	for x in [-4.2, 4.2]:
		block(root, "EntranceWall", Vector3(x, 2, 10), Vector3(0.4, 4, 10))
	block(root, "EntranceBack", Vector3(0, 2, 15.2), Vector3(8.8, 4, 0.4))
	for x in [-6, 6]:
		block(root, "CourtyardSouth", Vector3(x, 2, 5.2), Vector3(4, 4, 0.4))
	block(root, "CourtyardWest", Vector3(-8.2, 2, -1), Vector3(0.4, 4, 12.8))
	block(root, "CourtyardNorth", Vector3(0, 2, -7.2), Vector3(16, 4, 0.4))
	block(root, "EastNorth", Vector3(8.2, 2, -5.3), Vector3(0.4, 4, 3.4))
	block(root, "EastSouth", Vector3(8.2, 2, 3), Vector3(0.4, 4, 4))
	block(root, "CryptLintel", Vector3(8.2, 3.7, -1.3), Vector3(0.4, 0.6, 4.6))
	block(root, "CryptNorth", Vector3(13, 2, -7.2), Vector3(10, 4, 0.4))
	block(root, "CryptSouth", Vector3(13, 2, 1.2), Vector3(10, 4, 0.4))
	block(root, "CryptEast", Vector3(18.2, 2, -3), Vector3(0.4, 4, 8.8))
	block(root, "CourtyardCover", Vector3(-2, 1.1, -2), Vector3(2, 2.2, 2))
	for step in range(3):
		var height := (step + 1) * 0.15
		block(root, "PracticeStep", Vector3(4, height / 2.0, 1.6 - step * 0.8), Vector3(2, height, 0.8), true)
	placement(root, "PlayerStart", PLACEMENT.Kind.PLAYER_START, Vector3(0, 0, 13))
	placement(root, "CourtyardWarden", PLACEMENT.Kind.WARDEN, Vector3(-5, 0, -4), PI)
	placement(root, "CryptWarden", PLACEMENT.Kind.WARDEN, Vector3(12, 0, -4), -PI / 2.0)
	placement(root, "CryptAdept", PLACEMENT.Kind.ADEPT, Vector3(16, 0, -1), -PI / 2.0)
	placement(root, "CourtyardBat", PLACEMENT.Kind.BAT, Vector3(3, 0, -3))
	placement(root, "Health", PLACEMENT.Kind.HEALTH, Vector3(-2, 0, 10))
	placement(root, "Mana", PLACEMENT.Kind.MANA, Vector3(2, 0, 10))
	placement(root, "CryptHealth", PLACEMENT.Kind.HEALTH, Vector3(10, 0, -5))
	placement(root, "EmberKey", PLACEMENT.Kind.KEY, Vector3(16, 0, -5))
	placement(root, "ExitGate", PLACEMENT.Kind.EXIT, Vector3(-5, 0, -5.7))
	placement(root, "EntranceTorch", PLACEMENT.Kind.TORCH, Vector3(-3.8, 2.3, 10), PI / 2.0)
	placement(root, "CourtTorch", PLACEMENT.Kind.TORCH, Vector3(-7.8, 2.3, -3), PI / 2.0)
	placement(root, "CryptTorch", PLACEMENT.Kind.TORCH, Vector3(17.8, 2.3, -3), -PI / 2.0)
	placement(root, "EntranceUrn", PLACEMENT.Kind.URN, Vector3(3, 0, 14))
	placement(root, "CryptUrn", PLACEMENT.Kind.URN, Vector3(17, 0, -6))
	var zone := placement(root, "CryptAmbience", PLACEMENT.Kind.AMBIENCE, Vector3(13, 1.5, -3))
	zone.zone_size = Vector3(10, 3, 8)

## The Golem Sanctum: a round room north of the Ossuary gallery (centre (0, 0, -23), 7 m inner
## radius), entered through a short passage sealed by a bone seal. A stepped dais in the middle
## holds the dormant stone golem and the ember key; the exit gate is on the far wall.
static func _sanctum(root: Node3D) -> void:
	var center := Vector3(0, 0, -23)
	block(root, "SanctumPassageFloor", Vector3(0, -0.25, -15.3), Vector3(3.2, 0.5, 2.6), true)
	for x in [-1.2, 1.2]:
		block(root, "SanctumPassageWall", Vector3(x, 2, -15.25), Vector3(0.4, 4, 1.7))
	prism(root, "SanctumFloor", center + Vector3(0, -0.25, 0), circle(7.6, 24), 0.5, true)
	# 24 wall segments of 15 degrees; the three facing the gallery are replaced by a straight facade.
	ring(root, "SanctumWall", center, 7.0, 7.5, 5.0, 24, [23, 0, 1])
	for x in [-2.05, 2.05]:
		block(root, "SanctumFacade", Vector3(x, 2.5, -16.35), Vector3(2.1, 5, 0.6))
	block(root, "SanctumLintel", Vector3(0, 4, -16.35), Vector3(2, 2, 0.6))
	# Round pedestal, 0.45 m high with sides sloped at about 16 degrees: the golem walks down it
	# and the player can walk up it.
	frustum(root, "Dais", center + Vector3(0, 0.225, 0), 3.4, 1.8, 0.45, 24, true)
	var door := Vector3(0, 0, -16.35)
	placement(root, "BoneSeal", PLACEMENT.Kind.BONE_SEAL, door)
	var top := center + Vector3(0, 0.45, 0)
	placement(root, "StoneGolem", PLACEMENT.Kind.STONE_GOLEM, top, facing(top, door))
	placement(root, "EmberKey", PLACEMENT.Kind.KEY, top)
	placement(root, "ExitGate", PLACEMENT.Kind.EXIT, center + Vector3(0, 0, -6.75))
	for angle in [60.0, -60.0, 120.0, -120.0]:
		var spot := center + Vector3(sin(deg_to_rad(angle)), 0, cos(deg_to_rad(angle))) * 5.6
		placement(root, "GolemStatue", PLACEMENT.Kind.GOLEM_STATUE, spot, facing(spot, center))
	for x in [-4.6, 4.6]:
		placement(root, "SanctumBrazier", PLACEMENT.Kind.BRAZIER, center + Vector3(x, 0, 0))
	for x in [-2.2, 2.2]:
		placement(root, "GateLamp", PLACEMENT.Kind.CRYSTAL_LAMP, center + Vector3(x, 0, -6.0))
	# Wall lanterns on the inner face of the segments at +-30 and +-150 degrees.
	for angle in [30.0, -30.0, 150.0, -150.0]:
		var radians := deg_to_rad(angle)
		var wall := 7.0 * cos(deg_to_rad(7.5)) - 0.015
		placement(root, "SanctumLantern", PLACEMENT.Kind.LANTERN, center + Vector3(sin(radians) * wall, 2.3, cos(radians) * wall), radians)
	placement(root, "SanctumHealth", PLACEMENT.Kind.HEALTH, center + Vector3(-3.0, 0, 4.6))
	placement(root, "SanctumMana", PLACEMENT.Kind.MANA, center + Vector3(3.0, 0, 4.6))
	var zone := placement(root, "SanctumAmbience", PLACEMENT.Kind.AMBIENCE, center + Vector3(0, 2, 0))
	zone.zone_size = Vector3(14, 4, 14)
