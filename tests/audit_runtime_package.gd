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
		if "_editor_test" in path or "catalog_test_" in path or "editor_polish_test_" in path:
			push_error("Private test map leaked into package: " + path)
			failures += 1
		if "/prototypes/" in path or path.begins_with("res://addons/") or path.begins_with("res://scenes/authoring/") or path.begins_with("res://tools/") or path.begins_with("res://tests/") or path.begins_with("res://docs/") or path.begins_with("res://openspec/") or path.begins_with("res://builds/") or path.get_file().begins_with(".env") or path.ends_with(".exe"):
			push_error("Forbidden packaged resource: " + path)
			failures += 1
	for path in ["res://scenes/models/warden_animated.tscn", "res://scripts/enemies/warden_grip.gd", "res://assets/models/warden-animated/animate.glb", "res://assets/models/warden-animated/texture.glb", "res://scenes/models/iron_blade.tscn", "res://scenes/models/adept.tscn", "res://scenes/models/warden.tscn", "res://scenes/models/adept_animated.tscn", "res://scripts/enemies/adept_presentation.gd", "res://assets/models/adept-animated/animate.glb", "res://resources/shaders/flame.gdshader", "res://scripts/environment/flame_visual.gd", "res://scripts/environment/light_fixture.gd", "res://assets/models/prop-brazier/model.glb", "res://assets/models/prop-lantern/model.glb", "res://assets/models/prop-crystal-lamp/model.glb", "res://assets/models/prop-torch/model_unlit.mesh", "res://scripts/props/key_ward.gd", "res://scenes/enemies/bat_enemy.tscn", "res://scripts/enemies/bat_enemy.gd", "res://scenes/models/bat_animated.tscn", "res://scripts/enemies/bat_presentation.gd", "res://assets/models/bat-animated/bat_animated.glb", "res://scenes/enemies/skeleton_enemy.tscn", "res://scenes/enemies/skeleton_archer.tscn", "res://scenes/models/skeleton_warrior.tscn", "res://scenes/models/skeleton_archer.tscn", "res://scripts/enemies/skeleton_presentation.gd", "res://assets/models/skeleton/eye_flicker.gd", "res://assets/models/skeleton/skeleton_warrior.glb", "res://assets/models/skeleton_archer/skeleton_archer.glb", "res://scenes/enemies/stone_golem.tscn", "res://scenes/models/stone_golem.tscn", "res://scripts/enemies/golem_enemy.gd", "res://scripts/enemies/golem_presentation.gd", "res://scenes/props/golem_statue.tscn", "res://scripts/props/golem_statue.gd", "res://assets/models/stone_golem/stone_golem.glb"]:
		if not ResourceLoader.exists(path):
			push_error("Missing runtime resource: " + path)
			failures += 1
	for path in ["res://scenes/levels/generated/mapping_example.tscn", "res://scenes/levels/generated/ossuary.tscn", "res://scripts/levels/authored_level.gd", "res://resources/materials/mapping_wall.tres", "res://resources/materials/mapping_floor.tres"]:
		if not ResourceLoader.exists(path):
			push_error("Missing authored-level resource: " + path)
			failures += 1
	# Authoring sources for the skeletons and the golem stay in the repository, not in the package.
	for path in ["res://assets/models/skeleton/skeleton_warrior.blend", "res://assets/models/skeleton_archer/skeleton_archer.blend", "res://assets/models/skeleton/source/skeleton_meshy.glb", "res://assets/models/skeleton_archer/source/bow_meshy.glb", "res://assets/models/stone_golem/stone_golem.blend", "res://assets/models/stone_golem/source/golem_anims_meshy.glb"]:
		if FileAccess.file_exists(path) or ResourceLoader.exists(path):
			push_error("Authoring source packaged: " + path)
			failures += 1
	if not ResourceLoader.exists("res://scripts/levels/built_level_catalog.gd"):
		push_error("Missing runtime level catalog")
		failures += 1
	if ProjectSettings.get_setting("application/config/version") != "0.11.0":
		push_error("Wrong packaged version")
		failures += 1
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var file := FileAccess.open(args[0], FileAccess.WRITE)
		file.store_string(JSON.stringify({"version": "0.11.0", "resource_count": paths.size(), "failures": failures, "resources": paths}, "  ") + "\n")
	print("RESULT: package audit, %d resources, %d failures" % [paths.size(), failures])
	quit(0 if failures == 0 else 1)
