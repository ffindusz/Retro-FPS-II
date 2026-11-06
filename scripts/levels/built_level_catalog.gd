extends RefCounted
## Fixed project-resource discovery only. Never instantiates a level or loads editor data.

const ROOT := "res://scenes/levels/generated/"
const RUNTIME_SCRIPT := "res://scripts/levels/authored_level.gd"

static func public_path(path: String) -> bool:
	return path.begins_with(ROOT) and path.simplify_path() == path and path.get_base_dir() == ROOT.trim_suffix("/") and path.ends_with(".tscn") and path.get_file().get_basename().is_valid_identifier() and not path.get_file().begins_with("_")

static func properties(scene: PackedScene) -> Dictionary:
	var result := {}
	if scene == null:
		return result
	var state := scene.get_state()
	if state.get_node_count() == 0:
		return result
	for index in range(state.get_node_property_count(0)):
		result[str(state.get_node_property_name(0, index))] = state.get_node_property_value(0, index)
	return result

static func describe(path: String) -> Dictionary:
	if not public_path(path) or not ResourceLoader.exists(path, "PackedScene"):
		return {}
	var packed := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var data := properties(packed)
	var script = data.get("script")
	if not script is Script or script.resource_path != RUNTIME_SCRIPT:
		return {}
	var title := str(data.get("level_title", path.get_file().get_basename())).strip_edges()
	return {"path": path, "title": title if not title.is_empty() else path.get_file().get_basename()}

static func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for name in ResourceLoader.list_directory(ROOT):
		var entry := describe(ROOT.path_join(name))
		if not entry.is_empty():
			result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary):
		var order: int = str(a.title).naturalnocasecmp_to(str(b.title))
		return a.path < b.path if order == 0 else order < 0)
	return result
