extends SceneTree
## Only the game's rendered viewport; the long-list view is explicitly synthetic UI stress data.

func _initialize() -> void:
	call_deferred("capture")

func frames() -> void:
	for index in range(5):
		await process_frame
		await RenderingServer.frame_post_draw

func capture() -> void:
	var output := "res://builds/validation/editor-polish"
	DirAccess.make_dir_recursive_absolute(output)
	var session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		session.show_menu()
		await frames()
		root.get_texture().get_image().save_png(output.path_join("menu-%d.png" % width))
		session.show_level_selection()
		await frames()
		root.get_texture().get_image().save_png(output.path_join("choose-level-%d.png" % width))
		var synthetic: Array[Dictionary] = []
		for index in range(30):
			synthetic.append({"title": "Synthetic map-list stress entry", "path": "res://scenes/levels/generated/stress_%02d.tscn" % index})
		session.ui.show_level_selection(synthetic, "Synthetic long-list layout check — not shipped maps")
		await frames()
		session.ui.buttons.get_children().back().grab_focus()
		await frames()
		root.get_texture().get_image().save_png(output.path_join("synthetic-long-list-%d.png" % width))
	session.queue_free()
	await process_frame
	quit()
