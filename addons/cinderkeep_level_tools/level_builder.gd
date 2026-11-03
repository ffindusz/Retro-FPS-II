@tool
extends RefCounted
## Editor-only, non-destructive Cyclops -> native Godot geometry/nav build.

const PLACEMENT = preload("res://scripts/levels/level_placement.gd")
const RUNTIME = preload("res://scripts/levels/authored_level.gd")
const WALL = preload("res://resources/materials/mapping_wall.tres")
const OUTPUT_ROOT := "res://scenes/levels/generated/"

static func source_hash(path: String) -> String:
	return FileAccess.get_file_as_string(path).replace("\r\n", "\n").sha256_text()

static func editor_dependency(value: Variant, seen: Dictionary = {}) -> bool:
	if value is Resource:
		if seen.has(value.get_instance_id()):
			return false
		seen[value.get_instance_id()] = true
		if value.resource_path.begins_with("res://addons/") or value.resource_path.begins_with("res://scenes/authoring/"):
			return true
		for property in value.get_property_list():
			if property.usage & PROPERTY_USAGE_STORAGE and editor_dependency(value.get(property.name), seen):
				return true
	elif value is Array or value is Dictionary:
		for entry in value.values() if value is Dictionary else value:
			if editor_dependency(entry, seen):
				return true
	return false

static func own_recursive(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		own_recursive(child, root)

static func structural_errors(source: Node3D) -> Array[String]:
	var errors: Array[String] = []
	if not source.has_node("Architecture") or not source.has_node("Placements"):
		return ["Use a Cinderkeep authoring template with Architecture and Placements containers."]
	if not source.transform.is_equal_approx(Transform3D.IDENTITY) or not source.get_node("Placements").transform.is_equal_approx(Transform3D.IDENTITY):
		errors.append("Keep the level root and Placements container at identity transform; move individual objects instead.")
	var counts := {}
	for marker in source.get_node("Placements").get_children():
		if not marker is PLACEMENT:
			errors.append("%s: only Cinderkeep placement nodes belong in Placements." % marker.name)
			continue
		counts[marker.kind] = counts.get(marker.kind, 0) + 1
		if not marker.transform.is_finite() or not marker.scale.is_equal_approx(Vector3.ONE) or absf(marker.rotation.x) > 0.001 or absf(marker.rotation.z) > 0.001:
			errors.append("%s: use finite positions, unit scale and Y rotation only." % marker.name)
		if marker.kind == PLACEMENT.Kind.AMBIENCE and (not marker.zone_size.is_finite() or marker.zone_size.x <= 0 or marker.zone_size.y <= 0 or marker.zone_size.z <= 0 or not is_zero_approx(marker.rotation.y)):
			errors.append("%s: ambience zone must have positive dimensions and no rotation." % marker.name)
		if marker.amount < 1:
			errors.append("%s: pickup amount must be positive." % marker.name)
	for kind in [PLACEMENT.Kind.PLAYER_START, PLACEMENT.Kind.KEY, PLACEMENT.Kind.EXIT]:
		if counts.get(kind, 0) != 1:
			errors.append("Exactly one %s is required (found %d)." % [PLACEMENT.LABELS[kind], counts.get(kind, 0)])
	return errors

static func output_errors(source: Node3D) -> Array[String]:
	var path: String = source.runtime_path
	if source.scene_file_path.is_empty() or not FileAccess.file_exists(source.scene_file_path):
		return ["Save the authoring scene before building."]
	if not path.begins_with(OUTPUT_ROOT) or path.simplify_path() != path or path.get_base_dir() != OUTPUT_ROOT.trim_suffix("/") or not path.ends_with(".tscn") or not path.get_file().get_basename().is_valid_identifier():
		return ["Runtime Path must be a named .tscn directly under " + OUTPUT_ROOT]
	if FileAccess.file_exists(path):
		var packed := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		if packed == null:
			return ["Existing output cannot be loaded; left untouched: " + path]
		var existing := packed.instantiate()
		var same: bool = existing.get_script() == RUNTIME and existing.authoring_source == source.scene_file_path
		existing.free()
		if not same:
			return ["Existing output belongs to another source or is not a generated map; left untouched: " + path]
	return []

static func is_stale(source: Node3D) -> bool:
	if not FileAccess.file_exists(source.runtime_path) or not output_errors(source).is_empty():
		return true
	var packed := ResourceLoader.load(source.runtime_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var built := packed.instantiate()
	var stale: bool = built.authoring_sha256 != source_hash(source.scene_file_path)
	built.free()
	return stale

static func convert_architecture(node: Node3D, parent: Node3D, source: Node3D, errors: Array[String]) -> int:
	var count := 0
	if node is CyclopsBlock:
		if not node.global_transform.is_finite() or node.global_basis.determinant() <= 0.00001:
			errors.append("%s: architecture needs a finite, non-mirrored, non-zero transform." % node.name)
			return 0
		if node.mesh_vector_data == null:
			errors.append("%s: block has no mesh data." % node.name)
			return 0
		if node.collision_type not in [Collision.Type.NONE, Collision.Type.STATIC] or (node.collision_type == Collision.Type.STATIC and node.collision_layer != 1):
			errors.append("%s: architecture must be static on World layer 1 (or non-colliding decoration)." % node.name)
			return 0
		for material in node.materials:
			if material != null and editor_dependency(material):
				errors.append("%s: replace addon preview material with a game material." % node.name)
		var volume := ConvexVolume.new()
		volume.init_from_mesh_vector_data(node.mesh_vector_data)
		var root := Node3D.new()
		root.name = node.name
		root.transform = source.global_transform.affine_inverse() * node.global_transform
		root.visible = node.visible
		parent.add_child(root)
		var mesh := MeshInstance3D.new()
		mesh.name = "Mesh"
		mesh.mesh = volume.create_mesh(node.materials, WALL, false, 0.0)
		root.add_child(mesh)
		if node.collision_type == Collision.Type.STATIC:
			var body := StaticBody3D.new()
			body.name = "Body"
			body.collision_layer = 1
			body.collision_mask = 0
			root.add_child(body)
			var shape := CollisionShape3D.new()
			var convex := ConvexPolygonShape3D.new()
			convex.points = volume.get_points()
			shape.shape = convex
			body.add_child(shape)
		return 1
	if node is MeshInstance3D or node is CollisionObject3D:
		errors.append("%s: unsupported architecture node; use editable Cyclops blocks." % node.name)
	for child in node.get_children():
		if child is Node3D:
			count += convert_architecture(child, parent, source, errors)
	return count

static func spatial_errors(geometry: Node3D, markers: Node, nav: NavigationMesh, tree: SceneTree) -> Array[String]:
	var errors: Array[String] = []
	var viewport := SubViewport.new()
	viewport.world_3d = World3D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	viewport.add_child(geometry)
	var map := viewport.world_3d.navigation_map
	NavigationServer3D.map_set_active(map, true)
	NavigationServer3D.map_set_use_async_iterations(map, false)
	NavigationServer3D.map_set_cell_size(map, 0.2)
	NavigationServer3D.map_set_cell_height(map, 0.1)
	var region := NavigationServer3D.region_create()
	NavigationServer3D.region_set_use_async_iterations(region, false)
	NavigationServer3D.region_set_navigation_mesh(region, nav)
	NavigationServer3D.region_set_map(region, map)
	await tree.physics_frame
	await tree.physics_frame
	NavigationServer3D.map_force_update(map)
	var space := viewport.world_3d.direct_space_state
	var start := Vector3.ZERO
	for marker in markers.get_children():
		if marker.kind == PLACEMENT.Kind.PLAYER_START:
			start = marker.position
	for marker in markers.get_children():
		if marker.kind in [PLACEMENT.Kind.AMBIENCE, PLACEMENT.Kind.TORCH, PLACEMENT.Kind.URN]:
			continue
		var point: Vector3 = marker.position
		var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.3, point - Vector3.UP, 1))
		if floor_hit.is_empty() or absf(floor_hit.position.y - point.y) > 0.35:
			errors.append("%s: place its floor anchor on a supported walkable floor." % marker.name)
		var query := PhysicsShapeQueryParameters3D.new()
		query.collision_mask = 1
		if marker.kind in [PLACEMENT.Kind.PLAYER_START, PLACEMENT.Kind.WARDEN, PLACEMENT.Kind.ADEPT]:
			var capsule := CapsuleShape3D.new()
			capsule.radius = 0.28 if marker.kind == PLACEMENT.Kind.PLAYER_START else 0.38
			capsule.height = 1.8
			query.shape = capsule
			query.transform.origin = point + Vector3.UP * 0.94
		else:
			var sphere := SphereShape3D.new()
			sphere.radius = 0.18
			query.shape = sphere
			query.transform.origin = point + Vector3.UP * 0.8
		if not space.intersect_shape(query, 1).is_empty():
			errors.append("%s: placement overlaps world collision." % marker.name)
		var nearest := NavigationServer3D.map_get_closest_point(map, point)
		if nearest.distance_to(point) > 0.8:
			errors.append("%s: placement is outside usable navigation." % marker.name)
		var path := NavigationServer3D.map_get_path(map, start, point, true)
		if path.is_empty() or path[path.size() - 1].distance_to(nearest) > 0.5:
			errors.append("%s: no navigation connection from Player Start." % marker.name)
	viewport.remove_child(geometry)
	NavigationServer3D.map_set_active(map, false)
	NavigationServer3D.free_rid(region)
	viewport.queue_free()
	await tree.process_frame
	return errors

static func build(source: Node3D, tree: SceneTree, save_output: bool = true) -> Dictionary:
	var errors := structural_errors(source)
	errors.append_array(output_errors(source))
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	var geometry := Node3D.new()
	geometry.name = "Geometry"
	var count := convert_architecture(source.get_node("Architecture"), geometry, source, errors)
	if count == 0:
		errors.append("Architecture needs at least one Cyclops block.")
	if not errors.is_empty():
		geometry.free()
		return {"ok": false, "errors": errors}
	# Parse only static world colliders; never actor/preview meshes.
	var holder := Node3D.new()
	tree.root.add_child(holder)
	holder.add_child(geometry)
	var nav := NavigationMesh.new()
	nav.agent_radius = 0.4
	nav.agent_height = 2.0
	nav.agent_max_climb = 0.2
	nav.cell_size = 0.2
	nav.cell_height = 0.1
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = 1
	var data := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nav, data, geometry)
	NavigationServer3D.bake_from_source_geometry_data(nav, data)
	holder.remove_child(geometry)
	holder.queue_free()
	if nav.get_polygon_count() == 0:
		errors.append("No walkable navigation was baked; check floors, headroom and stairs.")
	else:
		errors.append_array(await spatial_errors(geometry, source.get_node("Placements"), nav, tree))
	if not errors.is_empty():
		geometry.free()
		return {"ok": false, "errors": errors}
	var runtime := Node3D.new()
	runtime.set_script(RUNTIME)
	runtime.name = source.name
	runtime.process_mode = Node.PROCESS_MODE_PAUSABLE
	runtime.level_title = source.level_title
	runtime.baked_navigation = nav
	runtime.authoring_source = source.scene_file_path
	runtime.authoring_sha256 = source_hash(source.scene_file_path)
	runtime.add_child(geometry)
	var placements := Node3D.new()
	placements.name = "Placements"
	runtime.add_child(placements)
	for marker in source.get_node("Placements").get_children():
		var copy := Node3D.new()
		copy.set_script(PLACEMENT)
		copy.name = marker.name
		copy.kind = marker.kind
		copy.amount = marker.amount
		copy.zone_size = marker.zone_size
		copy.transform = marker.transform
		placements.add_child(copy)
	own_recursive(runtime, runtime)
	var packed := PackedScene.new()
	var error := packed.pack(runtime)
	runtime.free()
	if error == OK and save_output:
		DirAccess.make_dir_recursive_absolute(source.runtime_path.get_base_dir())
		error = ResourceSaver.save(packed, source.runtime_path)
	if error != OK:
		return {"ok": false, "errors": ["Could not save built level: " + error_string(error)]}
	return {"ok": true, "errors": [], "scene": packed, "blocks": count, "polygons": nav.get_polygon_count(), "path": source.runtime_path}
