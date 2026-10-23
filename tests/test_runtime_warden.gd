extends SceneTree

const GRIP = preload("res://scripts/enemies/warden_grip.gd")
var checks: int = 0
var failures: int = 0
var session

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func settle() -> void:
	for frame in range(3):
		await physics_frame
	await process_frame

func freeze_run() -> void:
	session.run.player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)

func reference_hand(p) -> Transform3D:
	var bone: int = p.skeleton.find_bone(&"RightHand")
	var pose: Transform3D = p.skeleton.global_transform * p.skeleton.get_bone_global_pose(bone)
	return Transform3D(pose.basis.orthonormalized(), pose.origin)

func test_geometry(p) -> void:
	var mesh: MeshInstance3D = p.body
	var skeleton: Skeleton3D = p.skeleton
	var arrays := mesh.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var influences := joints.size() / vertices.size()
	var bones: Array[int] = []
	for bind in range(mesh.skin.get_bind_count()):
		bones.append(skeleton.find_bone(mesh.skin.get_bind_name(bind)))
	var rest := AABB()
	var culling_ok := true
	var grip_ok := true
	var rigid_ok := true
	var blade: MeshInstance3D = p.weapon.find_children("*", "MeshInstance3D", true, false)[0]
	var blade_vertices: PackedVector3Array = blade.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var blade_length: float = (blade.global_transform * blade_vertices[0]).distance_to(blade.global_transform * blade_vertices[100])
	# Include actual bind-rest, all five native clips, endpoints and intermediate poses.
	for clip in [&"Rest", &"Idle", &"Walk", &"Attack", &"Hit", &"Death"]:
		var count := 1 if clip == &"Rest" else 13
		for frame in range(count):
			if clip == &"Rest":
				p.animation.stop()
				skeleton.reset_bone_poses()
				skeleton.force_update_all_bone_transforms()
				p.update_weapon()
			else:
				p._sample(clip, p.animation.get_animation(p.CLIPS[clip]).length * frame / 12.0, 0.0, true)
			var matrices: Array[Transform3D] = []
			for bind in range(bones.size()):
				matrices.append(p.global_transform.affine_inverse() * skeleton.global_transform * skeleton.get_bone_global_pose(bones[bind]) * mesh.skin.get_bind_pose(bind))
			var bounds := AABB()
			for index in range(vertices.size()):
				var point := Vector3.ZERO
				for slot in range(influences):
					var offset := index * influences + slot
					point += matrices[joints[offset]] * vertices[index] * weights[offset]
				bounds = AABB(point, Vector3.ZERO) if index == 0 else bounds.expand(point)
			if clip == &"Rest":
				rest = bounds
			var mesh_to_visual: Transform3D = p.global_transform.affine_inverse() * mesh.global_transform
			culling_ok = culling_ok and (mesh_to_visual * mesh.custom_aabb).encloses(bounds)
			var centre: Vector3 = p.weapon_mount.global_transform * Vector3(-0.000733, 0.041225, -0.001466)
			grip_ok = grip_ok and centre.distance_to(reference_hand(p) * Vector3(0.015, 0.115, 0.025)) < 0.0001
			rigid_ok = rigid_ok and absf((blade.global_transform * blade_vertices[0]).distance_to(blade.global_transform * blade_vertices[100]) - blade_length) < 0.0001
	var cached: AABB = p.normalized_rest_bounds()
	print("Measured runtime bind-rest: ", rest)
	check(rest.position.distance_to(cached.position) < 0.005 and rest.size.distance_to(cached.size) < 0.005, "cached meter-scale rest bounds match independently skinned real vertices")
	check(culling_ok, "custom culling bounds contain every body vertex in rest and 65 sampled native poses")
	check(grip_ok and rigid_ok, "independently resolved RightHand/palm keeps rigid calibrated grip over all native poses")
	# Independently remeasure the dark grip, excluding the brass pommel/guard.
	var blade_arrays := blade.mesh.surface_get_arrays(0)
	var uv: PackedVector2Array = blade_arrays[Mesh.ARRAY_TEX_UV]
	var image: Image = blade.get_active_material(0).albedo_texture.get_image()
	image.decompress()
	var leather := AABB()
	var leather_count := 0
	var to_wrapper: Transform3D = p.weapon.global_transform.affine_inverse() * blade.global_transform
	for index in range(blade_vertices.size()):
		var point := to_wrapper * blade_vertices[index]
		if point.y <= -0.075 or point.y >= 0.155:
			continue
		var color := image.get_pixel(clampi(int(uv[index].x * image.get_width()), 0, image.get_width() - 1), clampi(int(uv[index].y * image.get_height()), 0, image.get_height() - 1))
		if maxf(color.r, maxf(color.g, color.b)) < 0.2:
			leather = AABB(point, Vector3.ZERO) if leather_count == 0 else leather.expand(point)
			leather_count += 1
	check(leather_count > 100 and leather.get_center().distance_to(GRIP.HANDLE_CENTRE) < 0.001, "calibrated point matches independently sampled dark leather, not brass pommel")
	var tracks_safe := true
	for clip in p.CLIPS.values():
		var animation: Animation = p.animation.get_animation(clip)
		for track in range(animation.get_track_count()):
			tracks_safe = tracks_safe and animation.track_get_type(track) in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]
	check(tracks_safe, "native animations contain only transform tracks, never gameplay method/audio events")
	p._sample(&"Idle", 0.0, 0.0, true)

func run_tests() -> void:
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	session.start_run()
	freeze_run()
	await settle()
	var wardens: Array = []
	var adepts: Array = []
	for enemy in get_nodes_in_group("enemies"):
		if enemy.archetype == 0:
			wardens.append(enemy)
		else:
			adepts.append(enemy)
	check(wardens.size() == 4 and adepts.size() == 2, "integration preserves four Wardens and two Adepts")
	check(wardens.all(func(enemy): return enemy.presentation != null and enemy.model_scene.resource_path == "res://scenes/models/warden_animated.tscn"), "all default melee enemies use the runtime animated visual")
	check(adepts.all(func(enemy): return enemy.presentation == null and enemy.model_scene.resource_path == "res://scenes/models/adept.tscn"), "inherited Adepts keep the unchanged ranged/static presentation path")
	var baseline: Dictionary = load("res://resources/atmosphere_baseline.tres").get_meta("snapshot")
	check(WorldFingerprint.snapshot(session.run) == baseline, "all original gameplay/collider/navigation/placement fingerprints still match")
	var enemy = wardens[0]
	var p = enemy.presentation
	var other = wardens[1].presentation
	check(p.skeleton.get_bone_count() == 24 and p.animation.has_animation(&"Dead") and p.animation.has_animation(&"Hit_Reaction"), "runtime build includes the complete selected humanoid and five clips")
	check(p.material != other.material and p.material.albedo_texture == other.material.albedo_texture, "Wardens share texture resources but not mutable hit materials")
	check(p.body.get_active_material(0).normal_enabled and p.body.get_active_material(0).normal_texture.get_width() <= 1024, "runtime body uses its full verified 1K PBR material")
	test_geometry(p)
	check(p.hand_attachment.bone_name == &"RightHand" and p.hand_attachment.is_ancestor_of(p.weapon), "runtime blade is owned by the named carrying-hand attachment")
	var weapon_unskinned := true
	for mesh in p.weapon.find_children("*", "MeshInstance3D", true, false):
		weapon_unskinned = weapon_unskinned and mesh.skin == null
	check(weapon_unskinned, "runtime blade has no skin or leg-weight influences")
	var grip_point: Vector3 = p.weapon_mount.global_transform * GRIP.HANDLE_CENTRE
	var hand := GRIP.hand_frame(p.skeleton, p.hand_bone)
	check(grip_point.distance_to(hand * GRIP.PALM_TARGET_M) < 0.0001, "measured handle centre, not wrapper origin, is placed at the palm")
	check(absf(GRIP.mount_transform().origin.distance_to(GRIP.PALM_TARGET_M) - 0.030945) < 0.0001, "calibration compensates the measured approximately 3.1cm dark-grip centre offset at world scale")
	var hand_before: Transform3D = p.weapon_mount.global_transform
	var time_before: float = p.idle_time
	enemy.position += Vector3(1, 0, 2)
	enemy.rotation.y += 0.3
	await settle()
	check(not p.weapon_mount.global_transform.is_equal_approx(hand_before) and is_equal_approx(p.idle_time, time_before), "render follower handles frozen-AI teleports/turns without aging animation")
	check((p.weapon_mount.global_transform * GRIP.HANDLE_CENTRE).distance_to(GRIP.hand_frame(p.skeleton, p.hand_bone) * GRIP.PALM_TARGET_M) < 0.0001, "teleport/turn cannot leave the top-level blade behind")
	p.attack_active = false
	enemy.state = enemy.State.CHASE
	var walk_before: float = p.walk_time
	enemy.advance_presentation(0.1, 0.16)
	check(p.mode == &"Walk" and p.walk_time > walk_before, "actual horizontal travel advances the configured gait")
	enemy.advance_presentation(0.1, 0.0)
	check(p.mode == &"Idle", "a collision stall/zero travel cannot keep walking in place")
	var root_pose: Vector3 = p.skeleton.get_bone_pose_position(p.root_bone)
	check(is_zero_approx(root_pose.x) and is_zero_approx(root_pose.z), "native horizontal root animation cannot displace the visual from the collider")
	enemy.take_damage(1, session.run.player)
	enemy.advance_presentation(0.05)
	check(p.mode == &"Hit" and p.hit_remaining > 0.0, "unprotected nonlethal damage can show the brief cosmetic hit clip")
	enemy.advance_presentation(0.3)
	check(p.mode == &"Idle" and is_zero_approx(p.hit_remaining), "hit presentation is bounded and returns without a gameplay stun")
	var player = session.run.player
	player.health = 100
	player.position = Vector3(0, 0.1, 14)
	enemy.position = Vector3(0, 0.1, 12.5)
	enemy.target = player
	enemy.state = enemy.State.CHASE
	enemy.cooldown = 0.0
	await settle()
	enemy._physics_process(0.01)
	check(enemy.state == enemy.State.ATTACK and is_equal_approx(enemy.windup, 0.55) and p.mode == &"Attack", "real AI begins the existing 0.55s attack and its visual telegraph")
	enemy._physics_process(0.2)
	check(player.health == 100 and is_equal_approx(p.native_time, p.NATIVE_CONTACT * 0.2 / 0.55), "pre-contact pose follows authoritative remaining windup with no early damage")
	var remaining: float = enemy.windup
	var other_color: Color = other.material.albedo_color
	enemy.take_damage(1, player)
	check(is_equal_approx(enemy.windup, remaining) and p.mode == &"Attack" and is_zero_approx(p.hit_remaining), "nonlethal feedback cannot restart/cancel or replace a committed windup")
	check(other.material.albedo_color == other_color and p.material.albedo_color != other_color, "protected-hit tint is local to the damaged instance")
	var contacts: Array = []
	var listener := func():
		if player.health < 100:
			contacts.append({"health": player.health, "native_time": p.native_time, "mode": p.mode})
	player.stats_changed.connect(listener)
	enemy._physics_process(0.34)
	check(player.health == 100 and enemy.windup > 0.0, "near-complete windup still cannot damage early")
	enemy._physics_process(0.011)
	check(player.health == 88 and contacts.size() == 1 and is_equal_approx(contacts[0].native_time, p.NATIVE_CONTACT) and contacts[0].mode == &"Attack", "strike pose is sampled before the single unchanged 12-damage resolution")
	player.stats_changed.disconnect(listener)
	check(enemy.state == enemy.State.CHASE and is_equal_approx(enemy.cooldown, 1.6), "animation does not alter authoritative cooldown/state transition")
	enemy._physics_process(0.1)
	check(player.health == 88 and p.native_time > p.NATIVE_CONTACT and p.attack_active, "visual follow-through progresses without duplicate damage")
	enemy._physics_process(1.0)
	check(not p.attack_active and p.mode == &"Idle", "visual recovery finishes without blocking the AI cooldown")
	enemy.cooldown = 0.0
	enemy._physics_process(0.01)
	var wall = session.run.solid(Vector3(0, 1.4, 13.2), Vector3(4, 2.8, 0.2))
	await settle()
	enemy._physics_process(0.56)
	check(player.health == 88 and p.contacted and is_equal_approx(p.native_time, p.NATIVE_CONTACT), "cover still blocks damage while the committed visual swing resolves")
	wall.free()
	await settle()
	enemy.cooldown = 0.0
	enemy._physics_process(0.01)
	player.position.z = 18.0
	await settle()
	enemy._physics_process(0.56)
	check(player.health == 88, "leaving range during windup still prevents damage")
	player.position = Vector3(0, 0.1, 14)
	enemy.position = Vector3(0, 0.1, 12.5)
	enemy.state = enemy.State.CHASE
	enemy.cooldown = 0.0
	await settle()
	enemy._physics_process(0.01)
	enemy._physics_process(0.1)
	var deaths := [0]
	enemy.died.connect(func(): deaths[0] += 1)
	enemy.take_damage(1000, player)
	enemy.take_damage(1000, player)
	await settle()
	check(enemy.state == enemy.State.DEAD and enemy.collision_layer == 0 and enemy.collision_mask == 0 and deaths[0] == 1 and not p.attack_active, "lethal hit immediately cancels attack/collision and emits death once")
	enemy._physics_process(3.5)
	check(player.health == 88 and p.mode == &"Death" and is_equal_approx(p.native_time, p.animation.get_animation(&"Dead").length), "death completes at native duration without a pending attack landing")
	var corpse: Transform3D = p.weapon_mount.global_transform
	enemy._physics_process(1.0)
	check(p.weapon_mount.global_transform.is_equal_approx(corpse) and enemy.visual.scale == Vector3.ONE and enemy.visual.rotation.z == 0.0, "corpse holds without the legacy shrink/rotation tween doubling the pose")
	var saved_time: float = other.idle_time
	session.pause_run()
	wardens[1].advance_presentation(10.0, 10.0)
	check(is_equal_approx(other.idle_time, saved_time), "pause rejects manual presentation aging as well as normal processing")
	session.resume_run()
	wardens[1].advance_presentation(0.01)
	check(is_equal_approx(other.idle_time, saved_time + 0.01), "resume advances only the new frame without catch-up")
	var old_weapon = p.weapon
	session.start_run()
	freeze_run()
	await settle()
	check(not is_instance_valid(old_weapon) and get_nodes_in_group("enemies").size() == 6, "restart disposes old top-level blades and recreates the exact encounter")
	check(WorldFingerprint.snapshot(session.run) == baseline, "fresh integrated run still matches every gameplay fingerprint")
	var fallback = load("res://scenes/enemies/melee_enemy.tscn").instantiate()
	fallback.use_placeholder = true
	session.run.add_child(fallback)
	fallback.set_physics_process(false)
	check(fallback.presentation == null and fallback.visual.get_child_count() > 1, "procedural fallback remains available without animated hooks")
	fallback.free()
	session.show_menu()
	session.queue_free()
	await settle()
	await create_timer(0.2).timeout
	print("RESULT: %d runtime-Warden checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
