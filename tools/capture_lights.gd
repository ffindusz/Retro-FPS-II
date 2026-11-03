extends SceneTree
## Review frames of animated torch flames and the procedural light fixtures in the demo level.
## Usage: godot --path . --resolution 1280x720 --script res://tools/capture_lights.gd

const VIEWS = {
	"torch-a": [Vector3(-3.3, 2.2, 10.2), Vector3(-4.8, 2.5, 10), 1.0],
	"torch-b": [Vector3(-3.3, 2.2, 10.2), Vector3(-4.8, 2.5, 10), 1.37],
	"courtyard-brazier-lantern": [Vector3(-7.5, 1.7, -7.5), Vector3(-12, 1.2, -11), 2.0],
	"gate-crystals": [Vector3(11, 1.7, -7.5), Vector3(11, 1.2, -13), 2.0],
	"crypt-lanterns": [Vector3(22, 1.7, -7), Vector3(22, 2.2, -0.5), 2.0],
	"key-chamber": [Vector3(28, 1.7, -7.5), Vector3(26.5, 1.0, -13.4), 2.0],
	"brazier-close": [Vector3(-10.6, 1.5, -11.6), Vector3(-12.45, 0.9, -13.45), 2.6],
}

func _initialize() -> void:
	call_deferred("capture")

func frames(count: int = 4) -> void:
	for index in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func capture() -> void:
	var directory = "res://builds/validation/living-lights"
	DirAccess.make_dir_recursive_absolute(directory)
	root.size = Vector2i(1280, 720)
	var session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	root.focus_exited.disconnect(session._on_focus_exited)
	session.start_run()
	var level = session.run
	level.player.set_physics_process(false)
	level.player.set_process_unhandled_input(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.visible = false
	level.presentation.set_process(false)
	var camera = Camera3D.new()
	camera.fov = 70
	level.add_child(camera)
	camera.make_current()
	session.ui.visible = false
	for view in VIEWS:
		var spec = VIEWS[view]
		camera.position = spec[0]
		camera.look_at(spec[1], Vector3.UP)
		level.presentation.set_clock(spec[2])
		await frames(6)
		root.get_texture().get_image().save_png("%s/%s.png" % [directory, view])
	session.show_menu()
	session.queue_free()
	await process_frame
	print("Saved light frames: ", directory)
	quit()
