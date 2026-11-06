extends SceneTree
## Authoring tool: removes the baked static flame from the Meshy wall torch so only the
## procedural animated flame shows. Triangles whose centroid lies above the cup rim are dropped.
## Usage: godot --headless --path . --script res://tools/trim_torch_flame.gd

const SOURCE = "res://assets/models/prop-torch/model.glb"
const OUTPUT = "res://assets/models/prop-torch/model_unlit.mesh"
## Mesh-space height of the cup rim (measured: cup widest at 0.22, flame from ~0.24).
const CUT_Y = 0.235

func _initialize() -> void:
	var scene: Node = load(SOURCE).instantiate()
	var source: ArrayMesh
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		source = (node as MeshInstance3D).mesh
	var arrays := source.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if indices.is_empty():
		indices.resize(vertices.size())
		for i in range(vertices.size()):
			indices[i] = i
	var kept := PackedInt32Array()
	var removed := 0
	for t in range(0, indices.size(), 3):
		var centroid := (vertices[indices[t]] + vertices[indices[t + 1]] + vertices[indices[t + 2]]) / 3.0
		if centroid.y > CUT_Y:
			removed += 1
			continue
		kept.append_array([indices[t], indices[t + 1], indices[t + 2]])
	arrays[Mesh.ARRAY_INDEX] = kept
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, source.surface_get_material(0))
	var error := ResourceSaver.save(mesh, OUTPUT)
	print("Trimmed torch: kept %d triangles, removed %d above y=%.3f -> %s (error %d)" % [kept.size() / 3, removed, CUT_Y, OUTPUT, error])
	scene.free()
	quit(0 if error == OK else 1)
