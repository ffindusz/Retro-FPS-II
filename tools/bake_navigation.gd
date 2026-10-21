extends SceneTree

func _initialize() -> void:
	call_deferred("bake")

func bake() -> void:
	var level = Node3D.new()
	level.set_script(load("res://scripts/level.gd"))
	level.set_process(false)
	# Avoid _ready spawning actors while authoring navigation.
	level.set_block_signals(true)
	level.build_geometry()
	level.remove_child(level.geometry)
	root.add_child(level.geometry)
	var mesh = level.bake_navigation()
	var error = ResourceSaver.save(mesh, "res://resources/demo_navigation.tres")
	print("Navigation polygons: ", mesh.get_polygon_count(), "; save result: ", error)
	level.geometry.free()
	level.free()
	quit(error)
