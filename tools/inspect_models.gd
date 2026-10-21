extends SceneTree
## Read imported scene bounds to author visual-only normalization transforms.

func _initialize() -> void:
	call_deferred("inspect_models")

func bounds(node: Node, transform: Transform3D = Transform3D.IDENTITY) -> AABB:
	var result = AABB()
	var combined = transform
	if node is Node3D:
		combined = transform * node.transform
	if node is MeshInstance3D:
		result = combined * node.get_aabb()
	for child in node.get_children():
		var box = bounds(child, combined)
		if box.size != Vector3.ZERO:
			result = box if result.size == Vector3.ZERO else result.merge(box)
	return result

func inspect_models() -> void:
	for id in ["weapon-cleaver", "weapon-staff", "enemy-warden", "enemy-adept", "prop-torch", "prop-urn"]:
		var path = "res://assets/models/%s/model.glb" % id
		var model = load(path).instantiate()
		print(id, " bounds=", bounds(model), " transform=", model.transform)
		model.free()
	quit()
