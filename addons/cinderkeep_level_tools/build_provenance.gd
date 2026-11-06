@tool
extends RefCounted
## Canonical saved-scene/resource fingerprint. Scripts use an explicit build recipe version.

const VERSION: int = 1

static func file_hash(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "missing"
	if path.get_extension() in ["tscn", "tres", "gdshader"]:
		return FileAccess.get_file_as_string(path).replace("\r\n", "\n").sha256_text()
	return FileAccess.get_sha256(path)

static func dependency_paths(path: String, seen: Dictionary = {}) -> Array[String]:
	var result: Array[String] = []
	if seen.has(path):
		return result
	seen[path] = true
	result.append(path)
	if path.get_extension() in ["tscn", "tres", "res"] and FileAccess.file_exists(path):
		for dependency in ResourceLoader.get_dependencies(path):
			var resource_path: String = dependency.split("::")[-1]
			# Preview/actor scripts are not source geometry. Bump VERSION for recipe changes.
			if resource_path.begins_with("res://") and resource_path.get_extension() != "gd":
				result.append_array(dependency_paths(resource_path, seen))
	result.sort()
	return result

static func fingerprint(path: String) -> String:
	var rows: Array[String] = ["cinderkeep-build-recipe:%d" % VERSION]
	for dependency in dependency_paths(path, {}):
		rows.append(dependency + "|" + file_hash(dependency))
	return "\n".join(rows).sha256_text()
