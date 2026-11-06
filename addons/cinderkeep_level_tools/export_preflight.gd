@tool
extends RefCounted
## Read-only export gate. Deliberately never executes authoring scenes or rebuilds anything.

const PROVENANCE = preload("res://addons/cinderkeep_level_tools/build_provenance.gd")
const CATALOG = preload("res://scripts/levels/built_level_catalog.gd")
const SOURCE_ROOT := "res://scenes/authoring/"
const AUTHORING_SCRIPT := "res://addons/cinderkeep_level_tools/authoring_level.gd"

static func _issue(result: Dictionary, message: String, source: String, code: String) -> void:
	result.errors.append(message)
	result.issues.append({"message": message, "source_path": source, "node_path": ".", "code": code})

static func check() -> Dictionary:
	var result := {"ok": true, "errors": [], "issues": [], "maps": [], "signature": ""}
	var associated := {}
	var rows: Array[String] = []
	var sources := DirAccess.get_files_at(SOURCE_ROOT)
	sources.sort()
	for name in sources:
		if not name.ends_with(".tscn") or name.begins_with("_"):
			continue
		var source := SOURCE_ROOT.path_join(name)
		var source_scene := ResourceLoader.load(source, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		var data := CATALOG.properties(source_scene)
		var script = data.get("script")
		if not script is Script or script.resource_path != AUTHORING_SCRIPT:
			continue
		var output := str(data.get("runtime_path", "res://scenes/levels/generated/new_level.tscn"))
		if not CATALOG.public_path(output):
			_issue(result, "%s: public source needs a public runtime .tscn under %s." % [name, CATALOG.ROOT], source, "output_path")
			continue
		if associated.has(output):
			_issue(result, "%s: runtime output is also used by %s." % [name, associated[output]], source, "duplicate_output")
		associated[output] = source
		if not FileAccess.file_exists(output):
			_issue(result, "%s: runtime build is missing. Build Level first." % name, source, "missing_build")
			continue
		var built := ResourceLoader.load(output, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		var built_data := CATALOG.properties(built)
		var runtime_script = built_data.get("script")
		if not runtime_script is Script or runtime_script.resource_path != CATALOG.RUNTIME_SCRIPT or str(built_data.get("authoring_source", "")) != source:
			_issue(result, "%s: runtime output is not owned by this source." % name, source, "ownership")
			continue
		var fingerprint := PROVENANCE.fingerprint(source)
		var nav = built_data.get("baked_navigation")
		if int(built_data.get("authoring_build_version", 0)) != PROVENANCE.VERSION or str(built_data.get("authoring_dependencies_sha256", "")) != fingerprint or str(built_data.get("authoring_sha256", "")) != PROVENANCE.file_hash(source):
			_issue(result, "%s: build is stale (source/resources/recipe changed). Build Level first." % name, source, "stale_build")
		if not nav is NavigationMesh or nav.get_polygon_count() == 0:
			_issue(result, "%s: runtime navigation is missing/empty." % name, source, "navigation")
		result.maps.append(output)
		rows.append(source + "|" + fingerprint + "|" + PROVENANCE.file_hash(output))
	for name in ResourceLoader.list_directory(CATALOG.ROOT):
		var output := CATALOG.ROOT.path_join(name)
		if CATALOG.public_path(output) and not associated.has(output):
			_issue(result, "%s: public runtime map has no matching public authoring source." % name, output, "orphaned_build")
	rows.sort()
	result.signature = "\n".join(rows).sha256_text()
	result.ok = result.errors.is_empty()
	return result

static func prepare(output: String) -> Dictionary:
	var result := check()
	if output.is_empty() or not output.ends_with(".pck") or (not output.is_absolute_path() and not output.begins_with("res://")):
		_issue(result, "Choose a new .pck output file for Checked Export.", "", "export_path")
	elif FileAccess.file_exists(output) or DirAccess.dir_exists_absolute(output):
		_issue(result, "Existing output left untouched: " + output, "", "existing_output")
	result.ok = result.errors.is_empty()
	return result
