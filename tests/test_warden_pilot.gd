extends SceneTree

const PREVIEW = preload("res://scenes/prototypes/warden_pilot_preview.tscn")
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

func reference_hand_frame(preview) -> Transform3D:
	# Resolve the named hand independently of the production follower helper.
	var bone: int = preview.pilot.skeleton.find_bone(&"RightHand")
	var pose: Transform3D = preview.pilot.skeleton.global_transform * preview.pilot.skeleton.get_bone_global_pose(bone)
	return Transform3D(pose.basis.orthonormalized(), pose.origin)

func run_tests() -> void:
	var preview = PREVIEW.instantiate()
	root.add_child(preview)
	preview.set_process(false)
	await process_frame
	check(preview.provenance.selected == "c02" and preview.provenance.total_credits == 90, "preview is the explicitly selected completed 90-credit body")
	check(preview.pilot.skeleton.get_bone_count() == 24 and preview.pilot.clips.size() == 5 and preview.pilot.body.skin != null, "pilot imports the actual five-clip 24-bone skin")
	var expected := [4.0, 5.0 / 3.0, 1.5, 49.0 / 30.0, 89.0 / 30.0]
	var durations_ok := true
	for index in range(5):
		durations_ok = durations_ok and is_equal_approx(preview.pilot.durations[index], expected[index])
	check(durations_ok, "native five-clip durations are retained without hidden retiming")
	check(absf(preview.pilot.rest_bounds.size.y * preview.pilot.normalization_scale - 1.8063) < 0.001, "body uses the validated meter-scale skinned rest normalization")
	check(preview.hand_bone >= 0 and preview.hand_attachment.bone_name == &"RightHand" and preview.hand_attachment.get_parent() == preview.pilot.skeleton, "attachment ownership is the carrying hand, not a leg")
	check(preview.hand_attachment.is_ancestor_of(preview.weapon) and preview.weapon.scene_file_path == "res://scenes/models/iron_blade.tscn", "the accepted separate Iron Blade scene is owned by the hand attachment")
	var unskinned := true
	for mesh in preview.weapon.find_children("*", "MeshInstance3D", true, false):
		unskinned = unskinned and mesh.skin == null
	check(unskinned and preview.weapon_mount.top_level, "weapon is unskinned with explicit armature-unit compensation")
	var material := preview.pilot.body.get_active_material(0) as StandardMaterial3D
	check(material != null and material.normal_enabled and material.normal_texture != null and material.roughness_texture != null, "selected body's full PBR maps are restored after UV-atlas verification")
	var texture_budget := true
	for texture in [material.albedo_texture, material.normal_texture, material.roughness_texture, material.metallic_texture]:
		if texture != null:
			texture_budget = texture_budget and texture.get_width() <= 1024 and texture.get_height() <= 1024
	check(texture_budget, "all active pilot body maps retain the 1K import limit")
	check(preview.find_children("*", "CollisionObject3D", true, false).is_empty() and preview.find_children("*", "NavigationAgent3D", true, false).is_empty(), "pilot preview has no gameplay collision or navigation")
	check(get_nodes_in_group("player").is_empty() and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("projectiles").is_empty(), "pilot creates no live player, enemies or projectiles")
	var camera: Camera3D = root.get_camera_3d()
	check(camera.unproject_position(preview.baseline.global_position).x < camera.unproject_position(preview.pilot.global_position).x, "accepted static reference is left and new pilot is right")
	var blade_mesh: MeshInstance3D = preview.weapon.find_children("*", "MeshInstance3D", true, false)[0]
	var vertices: PackedVector3Array = blade_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var farthest := 1
	for index in range(2, vertices.size()):
		if vertices[index].distance_squared_to(vertices[0]) > vertices[farthest].distance_squared_to(vertices[0]):
			farthest = index
	var base_length: float = (blade_mesh.global_transform * vertices[0]).distance_to(blade_mesh.global_transform * vertices[farthest])
	var fixed_relative := true
	var rigid := true
	var stable_scale := true
	var finite := true
	for clip in range(5):
		for frame in range(13):
			sample(preview, clip, preview.pilot.durations[clip] * float(frame) / 12.0)
			var relative: Transform3D = reference_hand_frame(preview).affine_inverse() * preview.weapon_mount.global_transform
			fixed_relative = fixed_relative and relative.is_equal_approx(preview.grip_transform())
			var distance: float = (blade_mesh.global_transform * vertices[0]).distance_to(blade_mesh.global_transform * vertices[farthest])
			rigid = rigid and absf(distance - base_length) < 0.0001
			stable_scale = stable_scale and preview.weapon_mount.global_basis.get_scale().is_equal_approx(Vector3.ONE * preview.weapon_scale)
			finite = finite and preview.weapon_mount.global_transform.is_finite()
	check(fixed_relative, "all 65 sampled poses keep the documented fixed hand-relative grip")
	check(rigid, "blade geometry cannot bend across idle/walk/attack/hit/death")
	check(stable_scale, "centimeter armature and animated bone scales cannot shrink or stretch the weapon")
	check(finite, "every sampled weapon pose is finite")
	sample(preview, 2, 0.0)
	var start_hand: Vector3 = preview.hand_frame().origin
	var start_vertex: Vector3 = preview.pilot.skinned_vertex(0)
	sample(preview, 2, 0.55)
	check(preview.hand_frame().origin.distance_to(start_hand) > 0.05 and preview.pilot.skinned_vertex(0).distance_to(start_vertex) > 0.001, "actual attack bones and skin move instead of only a mounted prop")
	preview.select_clip(4)
	preview.advance(preview.pilot.durations[4] + 1.0)
	var held: Transform3D = preview.weapon_mount.global_transform
	check(is_equal_approx(preview.clip_time, preview.pilot.durations[4]), "single death clip holds its final frame without resurrection looping")
	preview.advance(2.0)
	check(preview.weapon_mount.global_transform.is_equal_approx(held), "held death pose remains stable while frames advance")
	await key(KEY_R)
	check(is_zero_approx(preview.clip_time), "real replay input restarts a held death clip")
	await key(KEY_4)
	check(preview.clip_index == 3 and is_zero_approx(preview.clip_time), "real selection input chooses the hit reaction clip")
	preview.advance(0.3)
	await key(KEY_SPACE)
	var saved_time: float = preview.clip_time
	var saved_pose: Transform3D = preview.weapon_mount.global_transform
	preview.advance(1.0)
	check(preview.paused and is_equal_approx(preview.clip_time, saved_time) and preview.weapon_mount.global_transform.is_equal_approx(saved_pose), "pause freezes body playback and the rigid attachment")
	var count: int = preview.find_children("*", "Node", true, false).size()
	await key(KEY_W)
	check(not preview.show_weapon and not preview.weapon_mount.visible, "weapon visibility can reveal the genuinely empty-handed body")
	await key(KEY_W)
	await key(KEY_B)
	check(preview.show_bones and preview.pilot.bone_lines.visible, "skeleton overlay exposes the actual pilot rig")
	await key(KEY_V)
	check(preview.view_index == 1 and (reference_hand_frame(preview).affine_inverse() * preview.weapon_mount.global_transform).is_equal_approx(preview.grip_transform()), "view rotation preserves the hand-relative grip")
	await key(KEY_SPACE)
	await key(KEY_0)
	preview.advance(4.2)
	check(preview.automatic and preview.clip_index == 1 and is_equal_approx(preview.clip_time, 0.2), "auto playback advances through native clip lengths with leftover time")
	check(preview.find_children("*", "Node", true, false).size() == count, "playback/review controls do not allocate duplicate blades or actors")
	var labels_fit := true
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		await process_frame
		await process_frame
		for label in preview.find_children("*", "Label", true, false):
			labels_fit = labels_fit and root.get_visible_rect().encloses(label.get_global_rect())
	check(labels_fit, "pilot labels and controls fit at 720p and 1080p")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "preview does not capture the mouse")
	var old_weapon = preview.weapon
	preview.queue_free()
	await process_frame
	await process_frame
	check(not is_instance_valid(preview) and not is_instance_valid(old_weapon), "closing frees even the top-level compensated weapon descendant")
	preview = PREVIEW.instantiate()
	root.add_child(preview)
	preview.set_process(false)
	check(preview.clip_index == 0 and is_zero_approx(preview.clip_time) and not preview.paused and preview.show_weapon, "reopening starts a fresh pilot and one fresh attachment")
	preview.queue_free()
	await process_frame
	print("RESULT: %d pilot checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
