extends SceneTree

const SCENE = preload("res://scenes/prototypes/warden_animation_ab.tscn")
const CLOCK = preload("res://scripts/prototypes/animation_ab_clock.gd")
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
	check(CLOCK.times(1.2, 1.0, 2.0, false).is_equal_approx(Vector2(0.2, 1.2)), "native clocks preserve independent clip speeds")
	check(CLOCK.times(1.2, 1.0, 2.0, true).is_equal_approx(Vector2(0.6, 1.2)), "phase mode explicitly retimes to a common period")
	check(CLOCK.horizontal_cycle_offset(Vector3(1, 2, -3), 0.5, 1.0, true).is_equal_approx(Vector3(-0.5, 0, 1.5)), "cycle compensation is linear XZ only and never erases vertical movement")
	check(CLOCK.horizontal_cycle_offset(Vector3.ONE, 0.5, 1.0, false) == Vector3.ZERO, "raw root mode applies no compensation")
	var comparison = SCENE.instantiate()
	root.add_child(comparison)
	comparison.set_process(false)
	await process_frame
	var left = comparison.local_actor
	var right = comparison.meshy_actor
	check(left.skeleton.get_bone_count() == 21 and right.skeleton.get_bone_count() == 24, "A/B loads the actual different local and Meshy rigs")
	check(left.clips == [&"Idle", &"Walk", &"Attack"] and right.clips == [&"Idle", &"Walk_Fight_Forward", &"Right_Hand_Sword_Slash"], "all six correct native clips are used without substituting motions")
	check(is_equal_approx(left.durations[0], 2.0) and is_equal_approx(left.durations[1], 1.0) and is_equal_approx(left.durations[2], 1.4) and is_equal_approx(right.durations[0], 4.0) and is_equal_approx(right.durations[1], 5.0 / 3.0) and is_equal_approx(right.durations[2], 1.5), "native clip durations are exposed rather than silently forced to match")
	check(not comparison.phase_matched and comparison.mode_label.text.contains("NATIVE SPEED"), "default playback is labelled native speed")
	check(left.body.get_active_material(0) == right.body.get_active_material(0), "both rigs share the exact original verified-compatible PBR material")
	var material := left.body.get_active_material(0) as StandardMaterial3D
	check(material.albedo_texture.get_width() <= 1024 and material.albedo_texture.get_height() <= 1024, "shared appearance retains the 1K runtime texture cap")
	var normalization_ok := true
	var posed_size_ok := true
	for actor in [left, right]:
		normalization_ok = normalization_ok and is_equal_approx(actor.rest_bounds.size.y * actor.normalization_scale, 1.8063) and actor.normalization_scale > 0.95 and actor.normalization_scale < 1.05
		var box: AABB = AABB(actor.presented_vertex(0), Vector3.ZERO)
		for index in range(1, actor.vertices.size()):
			box = box.expand(actor.presented_vertex(index))
		posed_size_ok = posed_size_ok and box.size.y > 1.2 and box.size.y < 2.2
	check(normalization_ok, "skinned rest bounds handle the centimetre-armature scale without 100x normalization")
	check(posed_size_ok, "both actual presented skins are human-sized rather than invisible/off-stage giants")
	check(comparison.find_children("*", "CollisionObject3D", true, false).is_empty() and comparison.find_children("*", "NavigationAgent3D", true, false).is_empty(), "comparison creates no gameplay collision or navigation")
	check(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("player").is_empty() and get_nodes_in_group("projectiles").is_empty(), "comparison creates no live gameplay actors or projectiles")
	var camera: Camera3D = root.get_camera_3d()
	check(camera.unproject_position(left.global_position).x < camera.unproject_position(right.global_position).x, "local A begins screen-left and Meshy B screen-right")
	comparison.select_clip(1)
	var before_left: Vector3 = left.skinned_vertex(0)
	var before_right: Vector3 = right.skinned_vertex(0)
	comparison.advance(0.4)
	check(left.skinned_vertex(0).distance_to(before_left) > 0.001 and right.skinned_vertex(0).distance_to(before_right) > 0.001, "both actual skins animate rather than displaying static catalog stand-ins")
	comparison.clip_time = 1.2
	comparison._update_poses()
	check(comparison.sampled_times.is_equal_approx(Vector2(0.2, 1.2)), "native comparison samples each actual clip at its own loop time")
	check(right.motion_offset.position.is_equal_approx(CLOCK.horizontal_cycle_offset(right.cycle_drifts[1], 1.2, right.durations[1], true)), "anchored playback applies only the disclosed cycle compensation")
	var saved_times: Vector2 = comparison.sampled_times
	await key(KEY_G)
	check(not comparison.anchored and right.motion_offset.position.is_zero_approx() and comparison.sampled_times.is_equal_approx(saved_times) and comparison.mode_label.text.contains("RAW ROOT"), "raw mode restores original motion without retiming")
	await key(KEY_SPACE)
	var frozen_left: Vector3 = left.skinned_vertex(0)
	var frozen_right: Vector3 = right.skinned_vertex(0)
	comparison.advance(1.0)
	check(comparison.paused and comparison.sampled_times.is_equal_approx(saved_times) and left.skinned_vertex(0).is_equal_approx(frozen_left) and right.skinned_vertex(0).is_equal_approx(frozen_right), "real pause input freezes both clocks and skins")
	await key(KEY_R)
	check(is_zero_approx(comparison.clip_time) and comparison.sampled_times == Vector2.ZERO and comparison.paused, "replay resets both clips and preserves paused state")
	await key(KEY_T)
	check(comparison.phase_matched and comparison.mode_label.text.contains("retimed"), "phase mode is clearly labelled as retiming")
	await key(KEY_SPACE)
	comparison.advance(0.4)
	check(is_equal_approx(comparison.sampled_times.x / left.durations[1], comparison.sampled_times.y / right.durations[1]), "phase-matched playback samples equal normalized phases")
	await key(KEY_3)
	check(comparison.clip_index == 2 and is_zero_approx(comparison.clip_time), "number keys select the actual attack pair at clip start")
	var count: int = comparison.find_children("*", "Node", true, false).size()
	await key(KEY_B)
	check(left.bone_lines.visible and right.bone_lines.visible, "skeleton overlay shows both real armatures")
	await key(KEY_V)
	check(comparison.view_index == 1 and comparison.mode_label.text.contains("Side"), "common view control rotates both candidates")
	await key(KEY_X)
	check(comparison.swapped and camera.unproject_position(right.global_position).x < camera.unproject_position(left.global_position).x and comparison.source_labels[0].text.contains("Meshy"), "side swap updates actual positions and source labels")
	await key(KEY_X)
	await key(KEY_0)
	comparison.advance(4.2)
	check(comparison.automatic and comparison.clip_index == 1 and is_equal_approx(comparison.clip_time, 0.2), "auto review advances using the slower pair duration with leftover time")
	check(comparison.find_children("*", "Node", true, false).size() == count, "review controls do not accumulate rigs, players or overlays")
	var labels_fit := true
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		await process_frame
		await process_frame
		for label in comparison.find_children("*", "Label", true, false):
			labels_fit = labels_fit and root.get_visible_rect().encloses(label.get_global_rect())
	check(labels_fit, "all A/B labels fit at 720p and 1080p")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "review does not capture the mouse")
	comparison.queue_free()
	await process_frame
	await process_frame
	check(not is_instance_valid(comparison), "closing frees both comparison rigs")
	comparison = SCENE.instantiate()
	root.add_child(comparison)
	comparison.set_process(false)
	check(comparison.clip_index == 0 and not comparison.paused and not comparison.phase_matched and not comparison.swapped, "reopening restores a fresh deterministic comparison")
	comparison.queue_free()
	await process_frame
	print("RESULT: %d A/B checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
