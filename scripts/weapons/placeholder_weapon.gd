extends Node3D

@export_enum("Cleaver", "Staff") var kind: int = 0
@export var use_placeholder: bool = true
@export var model_scene: PackedScene

func _ready() -> void:
	if not use_placeholder and model_scene != null:
		$VisualRoot.add_child(model_scene.instantiate())
		return
	var root: Node3D = $VisualRoot
	if kind == 0:
		PrimitiveArt.cylinder(root, Vector3.ZERO, 0.035, 0.55, Color("4c3024"))
		PrimitiveArt.box(root, Vector3(0.02, 0.37, 0), Vector3(0.32, 0.48, 0.055), Color("87929a"))
		PrimitiveArt.box(root, Vector3(0.19, 0.37, 0), Vector3(0.025, 0.45, 0.065), Color("d1c7ac"))
		PrimitiveArt.box(root, Vector3(0, 0.09, 0), Vector3(0.21, 0.045, 0.12), Color("b18b4c"))
	else:
		PrimitiveArt.cylinder(root, Vector3.ZERO, 0.042, 1.0, Color("47392f"))
		PrimitiveArt.cylinder(root, Vector3(0, 0.37, 0), 0.09, 0.1, Color("b18b4c"))
		PrimitiveArt.orb(root, Vector3(0, 0.52, 0), 0.12, Color("5fcbd7"), 1.3)
		for x in [-0.13, 0.13]:
			var prong = PrimitiveArt.box(root, Vector3(x, 0.49, 0), Vector3(0.035, 0.28, 0.055), Color("b18b4c"))
			prong.rotation.z = x * -2.0
	PrimitiveArt.box(root, Vector3(0, -0.15, 0.06), Vector3(0.13, 0.16, 0.18), Color("635044"))
