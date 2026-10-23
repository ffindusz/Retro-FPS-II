extends SceneTree

const MOTION = preload("res://scripts/prototypes/warden_motion.gd")
const STUDY = preload("res://scenes/prototypes/warden_motion_study.tscn")
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
	var study = STUDY.instantiate()
	root.add_child(study)
	study.set_process(false)
	await process_frame
	check(study.bounds.size.y > 1.7 and study.bounds.size.y < 2.0, "study uses the actual normalized original Warden bounds")
	check(study.find_children("*", "MeshInstance3D", true, false).size() >= 2, "both original visuals are instantiated")
	check(study.find_children("*", "CollisionObject3D", true, false).is_empty() and study.find_children("*", "NavigationAgent3D", true, false).is_empty(), "sandbox contains no gameplay collision or navigation")
	check(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("player").is_empty() and get_nodes_in_group("projectiles").is_empty(), "sandbox creates no gameplay actors or projectiles")
	check(study.find_children("*", "Skeleton3D", true, false).is_empty(), "unrigged source is not presented as skeletal animation")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "preview does not capture the mouse")
	var camera: Camera3D = root.get_camera_3d()
	check(camera.unproject_position(study.baseline.global_position).x < camera.unproject_position(study.candidate.global_position).x, "camera projects the baseline on screen-left and candidate on screen-right")
	var labels_fit := true
	for width in [1280, 1920]:
		root.size = Vector2i(width, width * 9 / 16)
		await process_frame
		await process_frame
		for label in study.find_children("*", "Label", true, false):
			labels_fit = labels_fit and root.get_visible_rect().encloses(label.get_global_rect())
	check(labels_fit, "all review labels fit the logical viewport at 720p and 1080p")
	root.size = Vector2i(1280, 720)
	var grounded := true
	var bounded := true
	var deterministic := true
	for clip in MOTION.CLIPS:
		for frame in range(101):
			var time: float = MOTION.duration(clip) * float(frame) / 100.0
			var pose: Transform3D = MOTION.sample_pose(clip, time, study.bounds)
			var box: AABB = pose * study.bounds
			grounded = grounded and absf(box.position.y - study.bounds.position.y) < 0.0001
			bounded = bounded and pose.is_finite() and absf(pose.origin.x) <= 0.02 and absf(pose.origin.z) <= 0.17 and pose.origin.y < 0.7
			deterministic = deterministic and pose.is_equal_approx(MOTION.sample_pose(clip, time, study.bounds))
	check(grounded, "all 505 sampled candidate poses ground actual mesh bounds")
	check(bounded, "all candidate poses are finite and bounded")
	check(deterministic, "pose sampling is deterministic without tween/frame history")
	check(MOTION.phase(&"attack", 0.549) == "Anticipation" and MOTION.phase(&"attack", 0.55).begins_with("Release"), "release reference starts at the original 0.55-second windup")
	check(MOTION.phase(&"attack", 0.7) == "Recovery" and MOTION.phase(&"attack", 1.1) == "Ready", "release has separate recovery and ready phases")
	var before: Transform3D = MOTION.sample_pose(&"attack", 0.55 - 0.00001, study.bounds)
	var after: Transform3D = MOTION.sample_pose(&"attack", 0.55 + 0.00001, study.bounds)
	check(before.origin.distance_to(after.origin) < 0.001 and before.basis.is_equal_approx(after.basis), "attack pose remains continuous at release boundary")
	check(not MOTION.sample_pose(&"attack", 0.3, study.bounds).is_equal_approx(MOTION.sample_pose(&"attack", 0.63, study.bounds)), "candidate visibly changes between anticipation and release")
	check(not MOTION.sample_pose(&"locomotion", 0.25, study.bounds).is_equal_approx(Transform3D.IDENTITY), "locomotion silhouette actually moves without claiming limb articulation")
	check(not MOTION.sample_pose(&"hit", 0.12, study.bounds).is_equal_approx(Transform3D.IDENTITY), "candidate includes brief hit recoil")
	check(MOTION.sample_pose(&"death", 0.8, study.bounds).is_equal_approx(MOTION.sample_pose(&"death", 1.5, study.bounds)), "candidate death finishes and holds without repeated tween allocation")
	check(MOTION.sample_pose(&"attack", 1.2, study.bounds).is_equal_approx(Transform3D.IDENTITY), "completed attack returns to a neutral pose")
	check(not MOTION.sample_pose(&"attack", 0.3, study.bounds, true).is_equal_approx(MOTION.sample_pose(&"attack", 0.3, study.bounds)), "baseline and candidate remain independently sampled")
	study.select_clip(2)
	study.advance(0.3)
	check(study.candidate.transform.is_equal_approx(MOTION.sample_pose(&"attack", 0.3, study.bounds)), "scene applies the actual candidate sampler")
	var child_count: int = study.find_children("*", "Node", true, false).size()
	await key(KEY_SPACE)
	var saved_time: float = study.clip_time
	var saved_pose: Transform3D = study.candidate.transform
	study.advance(1.0)
	check(study.paused and is_equal_approx(study.clip_time, saved_time) and study.candidate.transform.is_equal_approx(saved_pose), "real Space input freezes preview time and poses")
	await key(KEY_R)
	check(is_zero_approx(study.clip_time) and study.candidate.transform.is_equal_approx(MOTION.sample_pose(&"attack", 0.0, study.bounds)), "real replay input resets while remaining paused")
	await key(KEY_5)
	check(study.clip_index == 4 and not study.automatic and is_zero_approx(study.clip_time), "number input selects a clip at its initial pose")
	await key(KEY_SPACE)
	study.advance(0.8)
	check(not study.paused and study.candidate.transform.is_equal_approx(MOTION.sample_pose(&"death", 0.8, study.bounds)), "resume continues the chosen clip")
	study.select_clip(0, true)
	study.advance(2.6)
	check(study.clip_index == 1 and is_equal_approx(study.clip_time, 0.2), "auto sequence carries leftover time into the next clip")
	study.select_clip(0, true)
	for step in range(26):
		study.advance(0.1)
	check(study.clip_index == 1 and is_equal_approx(study.clip_time, 0.2), "small-step and long-step playback agree")
	await key(KEY_3)
	study.advance(2.8)
	check(study.clip_index == 2 and is_zero_approx(study.clip_time), "single clip repeats deterministically")
	check(study.find_children("*", "Node", true, false).size() == child_count, "replay and clip changes do not accumulate nodes")
	check(study.phase_label.text.contains("Anticipation") and study.mode_label.text.contains("Single clip"), "phase and mode labels track playback")
	study.queue_free()
	await process_frame
	await process_frame
	check(not is_instance_valid(study), "closing frees the entire preview")
	study = STUDY.instantiate()
	root.add_child(study)
	study.set_process(false)
	check(study.clip_index == 0 and is_zero_approx(study.clip_time) and not study.paused, "reopening starts with fresh deterministic state")
	study.queue_free()
	await process_frame
	print("RESULT: %d motion-study checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
