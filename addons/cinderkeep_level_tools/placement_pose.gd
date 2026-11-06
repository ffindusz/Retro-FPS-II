@tool
extends RefCounted
## Pure placement policy shared by viewport interaction and numeric regression tests.

const PLACEMENT = preload("res://scripts/levels/level_placement.gd")

static func wall_kind(kind: int) -> bool:
	return kind in [PLACEMENT.Kind.TORCH, PLACEMENT.Kind.LANTERN]

static func pose(kind: int, point: Vector3, normal: Vector3, yaw_degrees: float, snap: bool, grid: float, height: float) -> Dictionary:
	if kind < 0 or kind >= PLACEMENT.LABELS.size() or not point.is_finite() or not normal.is_finite():
		return {"ok": false, "message": "Choose a valid source surface."}
	var wall := wall_kind(kind)
	if wall and (absf(normal.y) > 0.25 or Vector2(normal.x, normal.z).length() < 0.9):
		return {"ok": false, "message": "Aim at a vertical wall for this fixture."}
	if not wall and normal.y < 0.65:
		return {"ok": false, "message": "Aim at a walkable upward-facing floor."}
	var position := point
	var yaw := deg_to_rad(yaw_degrees)
	if snap:
		var size := maxf(grid, 0.05)
		if wall:
			position = Plane(normal.normalized(), point).project(point.snapped(Vector3.ONE * size))
		else:
			position.x = snappedf(point.x, size)
			position.z = snappedf(point.z, size)
	if wall:
		# Existing torch projects along +Z; lantern arm projects along -Z.
		var outward := Vector3(normal.x, 0, normal.z).normalized()
		yaw += atan2(outward.x, outward.z) if kind == PLACEMENT.Kind.TORCH else atan2(-outward.x, -outward.z)
		position += outward * 0.015
	elif kind == PLACEMENT.Kind.AMBIENCE:
		position.y += 2.0 # Default zone is four metres high, anchored above the floor.
	position.y += height
	return {"ok": true, "transform": Transform3D(Basis(Vector3.UP, yaw), position), "message": "Click to place. R: rotate 90°. Esc / RMB: cancel."}
