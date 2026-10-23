extends SceneTree
## Run externally against the PCK, never ship this diagnostic inside the pack.

var paths: Array[String] = []
var failures: int = 0

func _initialize() -> void:
	call_deferred("audit")

func walk(path: String) -> void:
	for name in DirAccess.get_files_at(path):
		paths.append(path.path_join(name))
	for name in DirAccess.get_directories_at(path):
		walk(path.path_join(name))

func audit() -> void:
	walk("res://")
	paths.sort()
	for path in paths:
		if "/prototypes/" in path or path.begins_with("res://tools/") or path.begins_with("res://tests/") or path.begins_with("res://docs/") or path.begins_with("res://openspec/") or path.begins_with("res://builds/") or path.get_file().begins_with(".env") or path.ends_with(".exe"):
			push_error("Forbidden packaged resource: " + path)
			failures += 1
	for path in ["res://scenes/models/warden_animated.tscn", "res://scripts/enemies/warden_grip.gd", "res://assets/models/warden-animated/animate.glb", "res://assets/models/warden-animated/texture.glb", "res://scenes/models/iron_blade.tscn", "res://scenes/models/adept.tscn", "res://scenes/models/warden.tscn"]:
		if not ResourceLoader.exists(path):
			push_error("Missing runtime resource: " + path)
			failures += 1
	if ProjectSettings.get_setting("application/config/version") != "0.5.0":
		push_error("Wrong packaged version")
		failures += 1
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var file := FileAccess.open(args[0], FileAccess.WRITE)
		file.store_string(JSON.stringify({"version": "0.5.0", "resource_count": paths.size(), "failures": failures, "resources": paths}, "  ") + "\n")
	print("RESULT: package audit, %d resources, %d failures" % [paths.size(), failures])
	quit(0 if failures == 0 else 1)
