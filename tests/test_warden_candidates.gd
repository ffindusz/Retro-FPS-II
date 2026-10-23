extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	root.push_input(event)
	await process_frame

func run_tests() -> void:
	var review = load("res://scenes/prototypes/warden_candidate_review.tscn").instantiate()
	root.add_child(review)
	await process_frame
	check(review.candidates.size() == 3 and review.report.preview_credits <= 60, "review loads exactly the three authorized previews")
	check(review.find_children("*", "CollisionObject3D", true, false).is_empty() and review.find_children("*", "Skeleton3D", true, false).is_empty(), "untextured candidate stage has no gameplay collision or rig")
	check(get_nodes_in_group("player").is_empty() and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("projectiles").is_empty(), "candidate review creates no gameplay actors")
	var common_material: Material
	var shared := true
	var height_ok := true
	for stand in review.candidates:
		var box := AABB()
		var first := true
		for node in stand.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			var local: Transform3D = stand.global_transform.affine_inverse() * mesh.global_transform
			var bounds: AABB = local * mesh.get_aabb()
			box = bounds if first else box.merge(bounds)
			first = false
			if common_material == null:
				common_material = mesh.get_active_material(0)
			shared = shared and mesh.get_active_material(0) == common_material
		height_ok = height_ok and absf(box.size.y - 1.8063) < 0.001 and absf(box.position.y) < 0.001
	check(shared, "all candidates use one common neutral material")
	check(height_ok, "candidate figures share a grounded 1.8063m presentation height")
	var camera: Camera3D = root.get_camera_3d()
	check(camera.unproject_position(review.candidates[0].global_position).x < camera.unproject_position(review.candidates[1].global_position).x and camera.unproject_position(review.candidates[1].global_position).x < camera.unproject_position(review.candidates[2].global_position).x, "candidate 1/2/3 order matches actual screen-left to screen-right")
	var count: int = review.find_children("*", "Node", true, false).size()
	await key(KEY_2)
	check(review.focus_index == 1 and not review.candidates[0].visible and review.candidates[1].visible and not review.candidates[2].visible, "real number input focuses the selected candidate only")
	await key(KEY_V)
	check(review.view_index == 1 and review.phase_label.text.contains("Side"), "real view input exposes the side silhouette")
	await key(KEY_0)
	check(review.focus_index == -1 and review.candidates.all(func(item): return item.visible), "all-candidate input restores every figure")
	check(review.find_children("*", "Node", true, false).size() == count, "focus/view changes do not accumulate scene nodes")
	var labels_fit := true
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		await process_frame
		await process_frame
		for label in review.find_children("*", "Label", true, false):
			labels_fit = labels_fit and root.get_visible_rect().encloses(label.get_global_rect())
	check(labels_fit, "candidate review labels fit at 720p and 1080p")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "candidate review does not trap the mouse")
	review.queue_free()
	await process_frame
	await process_frame
	check(not is_instance_valid(review), "closing disposes the candidate comparison")
	print("RESULT: %d candidate-review checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
