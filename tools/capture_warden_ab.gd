extends SceneTree
## Common-stage rendered viewports only; never captures the desktop.

func _initialize() -> void:
	call_deferred("capture_ab")

func capture_ab() -> void:
	var output := "res://builds/validation/warden-ab"
	DirAccess.make_dir_recursive_absolute(output)
	var comparison = load("res://scenes/prototypes/warden_animation_ab.tscn").instantiate()
	root.add_child(comparison)
	comparison.set_process(false)
	comparison.paused = true
	var views := {
		"idle-native": [0, 0.7, 0, false, false],
		"walk-native": [1, 0.4, 0, false, false],
		"walk-phase": [1, 0.4, 0, true, false],
		"walk-side": [1, 0.4, 1, true, false],
		"attack-native": [2, 0.55, 0, false, false],
		"attack-phase": [2, 0.75, 0, true, false],
		"attack-side": [2, 0.75, 1, true, false],
		"attack-bones": [2, 0.75, 0, true, true],
	}
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		for name in views:
			var view: Array = views[name]
			comparison.select_clip(view[0])
			comparison.clip_time = view[1]
			comparison.phase_matched = view[3]
			comparison.show_bones = view[4]
			comparison.set_view(view[2])
			for frame in range(4):
				await process_frame
				await RenderingServer.frame_post_draw
			var path := "%s/%s-%d.png" % [output, name, width]
			if root.get_texture().get_image().save_png(path) != OK:
				push_error("Could not save A/B viewport: " + path)
				quit(1)
				return
			print("Rendered: ", path)
	comparison.queue_free()
	await process_frame
	print("A/B captures complete: 16 viewport images")
	quit()
