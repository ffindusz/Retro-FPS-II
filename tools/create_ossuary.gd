extends SceneTree
## Offline fixture authoring for the second test map. Refuses to overwrite a designer-modified source.

func _initialize() -> void:
	call_deferred("create")

func create() -> void:
	var path := "res://scenes/authoring/ossuary.tscn"
	if FileAccess.file_exists(path):
		push_error("Existing Ossuary source preserved; edit it in Godot instead.")
		quit(1)
		return
	var source = load("res://addons/cinderkeep_level_tools/level_factory.gd").create_ossuary()
	var packed := PackedScene.new()
	packed.pack(source)
	source.free()
	var error := ResourceSaver.save(packed, path)
	if error != OK:
		quit(error)
		return
	source = load(path).instantiate()
	root.add_child(source)
	var result: Dictionary = await load("res://addons/cinderkeep_level_tools/level_builder.gd").build(source, self)
	print(result.errors if not result.ok else "Built Ossuary: %d blocks, %d polygons" % [result.blocks, result.polygons])
	source.queue_free()
	await process_frame
	await process_frame
	quit(0 if result.ok else 1)
