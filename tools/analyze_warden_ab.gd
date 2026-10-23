extends SceneTree
## Structural/presentation observations only, not an FPS or animation-quality score.

func _initialize() -> void:
	call_deferred("analyze")

func vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func analyze() -> void:
	var comparison = load("res://scenes/prototypes/warden_animation_ab.tscn").instantiate()
	root.add_child(comparison)
	comparison.set_process(false)
	var report := {"note": "Native clip data and documented comparison normalization; not a quality ranking", "actors": {}}
	for pair in [["local", comparison.local_actor], ["meshy", comparison.meshy_actor]]:
		var actor = pair[1]
		var clips: Array = []
		for clip in range(3):
			var drift: Vector3 = actor.cycle_drifts[clip] * actor.normalization_scale
			clips.append({"name": String(actor.clips[clip]), "duration_seconds": actor.durations[clip], "root_cycle_drift_m": vector(drift), "horizontal_cycle_drift_m": Vector2(drift.x, drift.z).length()})
		report.actors[pair[0]] = {"bones": actor.skeleton.get_bone_count(), "vertices": actor.vertices.size(), "rest_bounds_height_m": actor.rest_bounds.size.y, "normalization_scale": actor.normalization_scale, "normalization_origin": vector(actor.normalizer.position), "yaw_radians": actor.normalizer.rotation.y, "root_measurement_bone": String(actor.skeleton.get_bone_name(actor.root_bone)), "clips": clips}
	var file := FileAccess.open("res://builds/validation/warden-ab-runtime-metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print(JSON.stringify(report, "  "))
	comparison.queue_free()
	await process_frame
	quit()
