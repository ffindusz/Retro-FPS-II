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
	var root := Node3D.new()
	root.set_script(AUTHORING)
	root.name = "MappingExample" if example else "NewLevel"
	root.level_title = "The Mason's Trial" if example else "New Cinderkeep Level"
	root.runtime_path = "res://scenes/levels/generated/mapping_example.tscn" if example else "res://scenes/levels/generated/new_level.tscn"
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
