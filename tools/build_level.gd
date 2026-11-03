extends SceneTree
## Build a saved authoring scene without opening the editor. No paid/network tools.

func _initialize() -> void:
	call_deferred("build_level")

func build_level() -> void:
	var args := OS.get_cmdline_user_args()
	var path := args[0] if not args.is_empty() else "res://scenes/authoring/mapping_example.tscn"
	var packed := load(path) as PackedScene
	if packed == null:
		quit(1)
		return
	var source := packed.instantiate() as Node3D
	root.add_child(source)
	var result: Dictionary = await load("res://addons/cinderkeep_level_tools/level_builder.gd").build(source, self)
	print(result.errors if not result.ok else "Built %s: %d blocks, %d polygons" % [result.path, result.blocks, result.polygons])
	source.queue_free()
	await process_frame
	await process_frame
	quit(0 if result.ok else 1)
