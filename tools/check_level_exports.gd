extends SceneTree
## Read-only, offline preflight used before the checked CLI exporter is invoked.

func _initialize() -> void:
	call_deferred("check_exports")

func check_exports() -> void:
	var result: Dictionary = preload("res://addons/cinderkeep_level_tools/export_preflight.gd").check()
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--report":
		var file := FileAccess.open(args[1], FileAccess.WRITE)
		if file == null:
			push_error("Could not write preflight report.")
			quit(1)
			return
		file.store_string(JSON.stringify(result, "  ") + "\n")
	print("Checked export preflight: ", "ready" if result.ok else "BLOCKED", " (", result.maps.size(), " public maps)")
	for message in result.errors:
		print(message)
	quit(0 if result.ok else 1)
