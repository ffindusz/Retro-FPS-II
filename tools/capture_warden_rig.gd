extends SceneTree
## Only captures the rig preview's rendered viewport; no desktop capture.

func _initialize() -> void:
	call_deferred("capture_rig")

func capture_rig() -> void:
	var output := "res://builds/validation/warden-rig"
	DirAccess.make_dir_recursive_absolute(output)
	var preview = load("res://scenes/prototypes/warden_rig_preview.tscn").instantiate()
	root.add_child(preview)
	preview.set_process(false)
	preview.paused = true
	var views := {
		"rest-front": [0, 0.0, 0, false], "idle": [0, 0.5, 0, false],
		"walk-front": [1, 0.25, 0, false], "walk-side": [1, 0.25, 1, false],
		"attack-prepared": [2, 0.55, 0, false], "attack-release": [2, 0.67, 0, false],
		"attack-side": [2, 0.55, 1, false], "attack-back": [2, 0.55, 2, false],
		"skeleton": [2, 0.55, 0, true],
	}
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		for name in views:
			var view: Array = views[name]
			preview.select_clip(view[0])
			preview.clip_time = view[1]
			preview.show_bones = view[3]
			preview.set_view(view[2])
			for frame in range(4):
				await process_frame
				await RenderingServer.frame_post_draw
			var path := "%s/%s-%d.png" % [output, name, width]
			if root.get_texture().get_image().save_png(path) != OK:
				push_error("Could not save rig capture: " + path)
				quit(1)
				return
			print("Rendered: ", path)
	preview.queue_free()
	await process_frame
	print("Rig preview captures complete: 18 viewport images")
	quit()
