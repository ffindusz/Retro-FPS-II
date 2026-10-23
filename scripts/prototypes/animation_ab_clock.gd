extends RefCounted
## Explicit comparison transforms. Neither mode changes the source animations.

static func times(elapsed: float, left_duration: float, right_duration: float, phase_matched: bool) -> Vector2:
	if phase_matched:
		var phase := fposmod(elapsed, maxf(left_duration, right_duration)) / maxf(left_duration, right_duration)
		return Vector2(phase * left_duration, phase * right_duration)
	return Vector2(fposmod(elapsed, left_duration), fposmod(elapsed, right_duration))

static func horizontal_cycle_offset(drift: Vector3, time: float, duration: float, anchored: bool) -> Vector3:
	if not anchored:
		return Vector3.ZERO
	var phase := clampf(time / duration, 0.0, 1.0)
	return Vector3(-drift.x * phase, 0.0, -drift.z * phase)
