extends SceneTree

func _initialize() -> void:
	call_deferred("capture_pilot")

func capture_pilot() -> void:
	var output := "res://builds/validation/warden-pilot"
	DirAccess.make_dir_recursive_absolute(output)
	var preview = load("res://scenes/prototypes/warden_pilot_preview.tscn").instantiate()
	root.add_child(preview)
	preview.set_process(false)
	preview.paused = true
	var views := {"idle": [0, 0.7, 0, false], "walk": [1, 0.4, 0, false], "attack": [2, 0.55, 0, false], "attack-side": [2, 0.55, 1, false], "hit": [3, 0.5, 0, false], "death": [4, 2.7, 0, false], "back": [2, 0.55, 2, false], "bones": [2, 0.55, 0, true]}
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		for name in views:
			var view: Array = views[name]
			preview.select_clip(view[0])
			preview.clip_time = minf(view[1], preview.pilot.durations[view[0]])
			preview.show_bones = view[3]
			preview.set_view(view[2])
			for frame in range(4):
				await process_frame
				await RenderingServer.frame_post_draw
			var path := "%s/%s-%d.png" % [output, name, width]
			if root.get_texture().get_image().save_png(path) != OK:
				push_error("Could not save pilot viewport")
				quit(1)
				return
			print("Rendered: ", path)
	preview.queue_free()
	await process_frame
	print("Pilot captures complete: 16 viewport images")
	quit()
