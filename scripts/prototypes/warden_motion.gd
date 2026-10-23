extends RefCounted
## Whole-model timing study only: the source has no skeleton, skin or clips.

const CLIPS: Array[StringName] = [&"idle", &"locomotion", &"attack", &"hit", &"death"]
const CONTACT_TIME: float = 0.55

static func duration(clip: StringName) -> float:
	match clip:
		&"idle": return 2.4
		&"locomotion": return 1.2
		&"attack": return 1.4
		&"hit": return 0.6
		&"death": return 1.6
	return 1.0

static func phase(clip: StringName, time: float) -> String:
	if clip == &"attack":
		if time < CONTACT_TIME: return "Anticipation"
		if time < 0.69: return "Release / VISUAL contact reference"
		if time < 1.05: return "Recovery"
		return "Ready"
	if clip == &"locomotion": return "In-place silhouette study (NOT a walk cycle)"
	if clip == &"death": return "Collapse" if time < 0.55 else "Held death pose"
	if clip == &"hit": return "Recoil" if time < 0.24 else "Ready"
	return "Idle silhouette"

static func sample_pose(clip: StringName, time: float, bounds: AABB, baseline: bool = false) -> Transform3D:
	var t := clampf(time, 0.0, duration(clip))
	var angles := Vector3.ZERO
	var offset := Vector3.ZERO
	var size := Vector3.ONE
	if baseline:
		# Analytic approximation of enemy.gd's existing visual feedback, not AI playback.
		if clip == &"attack" and t < CONTACT_TIME:
			var remaining := CONTACT_TIME - t
			offset.y = sin(remaining * 18.0) * 0.07
			angles.x = -0.16 - 0.1 * (t / CONTACT_TIME)
		elif clip == &"hit":
			size = Vector3.ONE * (1.0 + maxf(0.2 - t, 0.0) * 0.7)
		elif clip == &"death":
			var blend := clampf(t / 0.3, 0.0, 1.0)
			angles.z = blend * PI / 2.0
			size = Vector3.ONE.lerp(Vector3(0.8, 0.55, 0.8), blend)
	else:
		match clip:
			&"idle":
				size.y += 0.003 * pow(sin(t * PI / 2.4), 2.0)
			&"locomotion":
				var cycle := t * TAU / duration(clip)
				angles = Vector3(0.018 * sin(cycle * 2.0), 0.025 * sin(cycle), 0.025 * sin(cycle))
				offset.x = 0.012 * sin(cycle)
			&"attack":
				var prepared := Vector3(0.12, 0.18, 0.0)
				var released := Vector3(-0.22, -0.1, -0.08)
				if t < CONTACT_TIME:
					var blend := smoothstep(0.0, CONTACT_TIME, t)
					angles = prepared * blend
					offset.z = 0.045 * blend
				elif t < 0.69:
					var blend := smoothstep(CONTACT_TIME, 0.69, t)
					angles = prepared.lerp(released, blend)
					offset.z = lerpf(0.045, -0.16, blend)
				else:
					var blend := smoothstep(0.69, 1.05, t)
					angles = released.lerp(Vector3.ZERO, blend)
					offset.z = lerpf(-0.16, 0.0, blend)
			&"hit":
				var recoil := sin(clampf(t / 0.24, 0.0, 1.0) * PI)
				angles.x = -0.1 * recoil
				offset.z = 0.05 * recoil
			&"death":
				var blend := smoothstep(0.0, 0.55, t)
				angles.z = PI / 2.0 * blend
				size = Vector3.ONE.lerp(Vector3(1.0, 0.8, 0.9), blend)
				offset.z = 0.12 * blend
	var pose := Transform3D(Basis.from_euler(angles).scaled(size), offset)
	if not baseline:
		# Ground the actual normalized static mesh bounds, not an assumed capsule.
		var transformed: AABB = pose * bounds
		pose.origin.y += bounds.position.y - transformed.position.y
	return pose

static func visual_bounds(root: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var local: Transform3D = root.global_transform.affine_inverse() * mesh.global_transform
		var box: AABB = local * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds
