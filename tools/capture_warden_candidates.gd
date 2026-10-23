extends SceneTree

func _initialize() -> void:
	call_deferred("capture_candidates")

func capture_candidates() -> void:
	var output := "res://builds/validation/warden-pilot-candidates"
	DirAccess.make_dir_recursive_absolute(output)
	var review = load("res://scenes/prototypes/warden_candidate_review.tscn").instantiate()
	root.add_child(review)
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		for index in range(6):
			review.focus_candidate(-1 if index < 3 else index - 3)
			review.set_view(index if index < 3 else 0)
			for frame in range(4):
				await process_frame
				await RenderingServer.frame_post_draw
			var name: String = ["all-front", "all-side", "all-back", "focus-1", "focus-2", "focus-3"][index]
			var path := "%s/%s-%d.png" % [output, name, width]
			if root.get_texture().get_image().save_png(path) != OK:
				push_error("Could not save candidate viewport")
				quit(1)
				return
			print("Rendered: ", path)
	review.queue_free()
	await process_frame
	print("Candidate captures complete: 12 viewport images")
	quit()
