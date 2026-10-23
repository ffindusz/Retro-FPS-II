extends SceneTree

const PREVIEW = preload("res://scenes/prototypes/warden_rig_preview.tscn")
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

func sample(preview, clip: int, time: float) -> void:
	preview.select_clip(clip)
	preview.clip_time = time
	preview._update_poses()

func find_vertex(preview, bone: StringName) -> int:
	for index in range(preview.vertices.size()):
		if preview.dominant_bone(index) == bone:
			return index
	return -1

func run_tests() -> void:
	var preview = PREVIEW.instantiate()
	root.add_child(preview)
	preview.set_process(false)
	await process_frame
	check(preview.skeleton.get_bone_count() == 21 and preview.body.skin != null, "derived model has a real 21-bone skeleton and assigned skin")
	var clips_ok := true
	for clip in [&"Idle", &"Walk", &"Attack"]:
		clips_ok = clips_ok and preview.animation.has_animation(clip)
	check(clips_ok, "all three skeletal clips import into Godot")
	check(is_equal_approx(preview.animation.get_animation(&"Idle").length, 2.0) and is_equal_approx(preview.animation.get_animation(&"Walk").length, 1.0) and is_equal_approx(preview.animation.get_animation(&"Attack").length, 1.4), "imported clip durations preserve authored timing")
	var safe_tracks := true
	for clip in [&"Idle", &"Walk", &"Attack"]:
		var animation: Animation = preview.animation.get_animation(clip)
		for track in range(animation.get_track_count()):
			safe_tracks = safe_tracks and animation.track_get_type(track) in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]
	check(safe_tracks, "clips contain bone transforms only, no method/audio/gameplay callbacks")
	check(preview.vertices.size() == 7327 and preview.influences == 4 and preview.bind_bones.size() == 21, "imported mesh retains original vertex count and four-slot skin bindings")
	var bindings_ok := true
	for bone in preview.bind_bones:
		bindings_ok = bindings_ok and bone >= 0
	check(bindings_ok, "every imported skin bind resolves to an actual named bone")
	var source: MeshInstance3D = preview.baseline.find_children("*", "MeshInstance3D", true, false)[0]
	check(preview.body.get_active_material(0) == source.get_active_material(0), "rig reuses the exact accepted source material and textures")
	var material := preview.body.get_active_material(0) as StandardMaterial3D
	check(material != null and material.albedo_texture.get_width() <= 1024 and material.albedo_texture.get_height() <= 1024, "no new texture import exceeds the accepted 1K material budget")
	check(preview.find_children("*", "CollisionObject3D", true, false).is_empty() and preview.find_children("*", "NavigationAgent3D", true, false).is_empty(), "preview has no gameplay collision or navigation")
	check(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("player").is_empty() and get_nodes_in_group("projectiles").is_empty(), "rig does not instantiate live enemies, player or projectiles")
	var camera: Camera3D = root.get_camera_3d()
	check(camera.unproject_position(preview.baseline.global_position).x < camera.unproject_position(preview.candidate.global_position).x, "static original is on screen-left and skinned candidate on screen-right")
	sample(preview, 0, 0.0)
	var rest_error := 0.0
	for index in range(preview.vertices.size()):
		rest_error = maxf(rest_error, preview.skinned_vertex(index).distance_to(preview.vertices[index]))
	check(rest_error < 0.0001, "CPU skin reference reproduces original rest vertices with actual bind matrices")
	var foot_r := find_vertex(preview, &"Foot.R")
	var foot_l := find_vertex(preview, &"Foot.L")
	var hand := find_vertex(preview, &"Hand.R")
	var blade := find_vertex(preview, &"Weapon.R")
	check(foot_r >= 0 and foot_l >= 0 and hand >= 0 and blade >= 0, "independent foot, hand and blade skin regions are present")
	var right_rest: Vector3 = preview.skinned_vertex(foot_r)
	var left_rest: Vector3 = preview.skinned_vertex(foot_l)
	var hand_rest: Vector3 = preview.skinned_vertex(hand)
	var blade_rest: Vector3 = preview.skinned_vertex(blade)
	var arm_rest: Quaternion = preview.skeleton.get_bone_pose_rotation(preview.skeleton.find_bone(&"UpperArm.R"))
	var root_bone: int = preview.skeleton.find_bone(&"Root")
	var root_pose: Transform3D = preview.skeleton.get_bone_global_pose(root_bone)
	var baseline_pose: Transform3D = preview.baseline.transform
	sample(preview, 1, 0.25)
	var right_delta: Vector3 = preview.skinned_vertex(foot_r) - right_rest
	var left_delta: Vector3 = preview.skinned_vertex(foot_l) - left_rest
	check(right_delta.length() > 0.02 and left_delta.length() > 0.02, "walk moves actual skinned foot vertices, not just the model root")
	check(right_delta.z * left_delta.z < 0.0, "walk legs articulate in opposite stride directions")
	check(preview.candidate.transform.is_equal_approx(Transform3D.IDENTITY) and preview.skeleton.get_bone_global_pose(root_bone).is_equal_approx(root_pose), "walk preserves the fixed candidate and skeleton root")
	sample(preview, 2, 0.55)
	check(preview.skinned_vertex(hand).distance_to(hand_rest) > 0.2 and preview.skinned_vertex(blade).distance_to(blade_rest) > 0.4, "attack visibly moves independent skinned hand and blade vertices")
	check(not preview.skeleton.get_bone_pose_rotation(preview.skeleton.find_bone(&"UpperArm.R")).is_equal_approx(arm_rest), "attack changes the carrying-arm bone from its actual rest pose")
	var attack_vertices: PackedVector3Array = []
	for index in range(preview.vertices.size()):
		attack_vertices.append(preview.skinned_vertex(index))
	var indices: PackedInt32Array = preview.body.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	var short_edge_growth := 0.0
	for face in range(0, indices.size(), 3):
		for pair in [[0, 1], [1, 2], [2, 0]]:
			var a: int = indices[face + pair[0]]
			var b: int = indices[face + pair[1]]
			var original: float = preview.vertices[a].distance_to(preview.vertices[b])
			if original <= 0.01:
				short_edge_growth = maxf(short_edge_growth, attack_vertices[a].distance_to(attack_vertices[b]) - original)
	print("METRIC: maximum sub-centimeter edge growth at prepared attack = %.6fm" % short_edge_growth)
	check(short_edge_growth < 0.02, "prepared attack keeps sub-centimeter mesh edges below 2cm growth")
	sample(preview, 0, 0.0)
	check(preview.skinned_vertex(blade).distance_to(blade_rest) < 0.0001, "switching directly from prepared attack to idle clears the previous arm pose")
	sample(preview, 2, 0.55)
	var blade_indices: Array[int] = []
	for index in range(preview.vertices.size()):
		if preview.dominant_bone(index) == &"Weapon.R":
			blade_indices.append(index)
	var second := blade_indices[blade_indices.size() - 1]
	var length_rest: float = preview.vertices[blade].distance_to(preview.vertices[second])
	var hand_bone: int = preview.skeleton.find_bone(&"Hand.R")
	var attachment := Vector3.ZERO
	var rigid := true
	var attached := true
	var root_fixed := true
	var finite := true
	var min_foot_height := INF
	for clip in range(3):
		for frame in range(13):
			sample(preview, clip, preview.LENGTHS[clip] * float(frame) / 12.0)
			var first_point: Vector3 = preview.skinned_vertex(blade)
			var second_point: Vector3 = preview.skinned_vertex(second)
			rigid = rigid and absf(first_point.distance_to(second_point) - length_rest) < 0.0001
			var hand_world: Transform3D = preview.skeleton.global_transform * preview.skeleton.get_bone_global_pose(hand_bone)
			var relative: Vector3 = hand_world.affine_inverse() * (preview.candidate.global_transform * first_point)
			if clip == 0 and frame == 0:
				attachment = relative
			attached = attached and relative.distance_to(attachment) < 0.0001
			root_fixed = root_fixed and preview.candidate.transform.is_equal_approx(Transform3D.IDENTITY) and preview.skeleton.get_bone_global_pose(root_bone).is_equal_approx(root_pose)
			for bone in range(preview.skeleton.get_bone_count()):
				finite = finite and preview.skeleton.get_bone_global_pose(bone).is_finite()
			min_foot_height = minf(min_foot_height, minf(preview.skinned_vertex(foot_r).y, preview.skinned_vertex(foot_l).y))
	check(blade_indices.size() == 180 and rigid, "all blade-region vertices are rigid and sampled blade length cannot bend")
	check(attached, "blade remains fixed in carrying-hand coordinates across all clips")
	check(root_fixed, "all sampled clips preserve the stationary root")
	check(finite, "all sampled bone poses remain finite")
	check(min_foot_height >= -0.02, "sampled representative feet avoid more than 2cm floor penetration")
	print("METRIC: minimum sampled representative foot height = %.6fm" % min_foot_height)
	check(preview.baseline.transform.is_equal_approx(baseline_pose), "static original is not animated by the prototype")
	var loop_error := 0.0
	for clip in [0, 1]:
		sample(preview, clip, 0.0)
		var initial: Vector3 = preview.skinned_vertex(foot_r)
		sample(preview, clip, preview.LENGTHS[clip])
		loop_error = maxf(loop_error, preview.skinned_vertex(foot_r).distance_to(initial))
	check(loop_error < 0.0001, "idle/walk skin loop endpoints match")
	sample(preview, 2, 0.4)
	var count: int = preview.find_children("*", "Node", true, false).size()
	await key(KEY_SPACE)
	var frozen: Vector3 = preview.skinned_vertex(blade)
	preview.advance(1.0)
	check(preview.paused and is_equal_approx(preview.clip_time, 0.4) and preview.skinned_vertex(blade).is_equal_approx(frozen), "real pause input freezes clip time, bones and skin")
	await key(KEY_R)
	check(is_zero_approx(preview.clip_time) and preview.skinned_vertex(blade).is_equal_approx(blade_rest), "replay resets the real rig while staying paused")
	await key(KEY_2)
	check(preview.clip_index == 1 and not preview.automatic and is_zero_approx(preview.clip_time), "number input selects the actual walk clip")
	await key(KEY_B)
	check(preview.show_bones and preview.bone_lines.visible, "skeleton overlay can be enabled with real input")
	await key(KEY_V)
	check(preview.view_index == 1 and preview.mode_label.text.contains("Side"), "review view switches to the side without changing pose time")
	await key(KEY_B)
	await key(KEY_SPACE)
	preview.advance(0.25)
	check(not preview.paused and preview.skinned_vertex(foot_r).distance_to(right_rest) > 0.02, "resume continues actual leg skinning")
	await key(KEY_0)
	preview.advance(2.2)
	check(preview.automatic and preview.clip_index == 1 and is_equal_approx(preview.clip_time, 0.2), "auto sequence advances between real clips with leftover time")
	check(preview.find_children("*", "Node", true, false).size() == count, "clip, view and skeleton controls do not accumulate nodes")
	var labels_fit := true
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		await process_frame
		await process_frame
		for label in preview.find_children("*", "Label", true, false):
			labels_fit = labels_fit and root.get_visible_rect().encloses(label.get_global_rect())
	check(labels_fit, "all rig review labels fit at 720p and 1080p")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "rig review leaves the mouse uncaptured")
	preview.queue_free()
	await process_frame
	await process_frame
	check(not is_instance_valid(preview), "closing disposes the entire rig preview")
	preview = PREVIEW.instantiate()
	root.add_child(preview)
	preview.set_process(false)
	check(preview.clip_index == 0 and is_zero_approx(preview.clip_time) and not preview.paused and not preview.show_bones, "reopening starts a fresh rig without retained playback state")
	preview.queue_free()
	await process_frame
	print("RESULT: %d rig-preview checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
