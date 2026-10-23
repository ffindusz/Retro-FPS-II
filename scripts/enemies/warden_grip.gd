extends RefCounted
## Meter-space calibration shared by runtime and the developer pilot.
## The existing blade wrapper origin is not its leather handle centre.

const ROTATION_DEGREES := Vector3(90, 0, 0)
# Dominant hand skin spans y=0.041..0.222m from the wrist bone;
# the palm (excluding fingertips/thumb) is around y=0.11m, not y=0.045m.
const PALM_TARGET_M := Vector3(0.015, 0.115, 0.025)
# Dark leather between brass pommel/guard, measured in blade-wrapper space.
# A preliminary brown-only colour filter selected the brass pommel instead;
# viewport markers and the complete handle profile corrected that measurement.
const HANDLE_CENTRE := Vector3(-0.000733, 0.041225, -0.001466)
const WORLD_SCALE: float = 0.75

static func mount_transform(rotation_degrees: Vector3 = ROTATION_DEGREES, palm_target: Vector3 = PALM_TARGET_M, scale: float = WORLD_SCALE) -> Transform3D:
	var basis := Basis.from_euler(rotation_degrees * PI / 180.0).scaled(Vector3.ONE * scale)
	return Transform3D(basis, palm_target - basis * HANDLE_CENTRE)

static func hand_frame(skeleton: Skeleton3D, bone: int) -> Transform3D:
	var pose := skeleton.global_transform * skeleton.get_bone_global_pose(bone)
	return Transform3D(pose.basis.orthonormalized(), pose.origin)
