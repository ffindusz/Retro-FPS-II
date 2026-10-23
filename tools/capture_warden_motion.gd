extends SceneTree
## Captures only this scene's rendered viewport, never the desktop.

const STUDY = preload("res://scenes/prototypes/warden_motion_study.tscn")

func _initialize() -> void:
	call_deferred("capture_study")

func capture_study() -> void:
	var output := "res://builds/validation/warden-motion"
	DirAccess.make_dir_recursive_absolute(output)
	var study = STUDY.instantiate()
	root.add_child(study)
	study.set_process(false)
	study.paused = true
	var views := {"anticipation": [2, 0.4], "release": [2, 0.64], "death": [4, 0.9], "locomotion": [1, 0.25]}
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		for view in views:
			study.select_clip(views[view][0])
			study.clip_time = views[view][1]
			study._update_poses()
			for frame in range(4):
				await process_frame
				await RenderingServer.frame_post_draw
			var path := "%s/%s-%d.png" % [output, view, width]
			var result := root.get_texture().get_image().save_png(path)
			if result != OK:
				push_error("Failed to save motion-study capture: " + path)
				quit(1)
				return
			print("Rendered: ", path)
	study.queue_free()
	await process_frame
	print("Motion-study captures complete: 8 viewport images")
	quit()
