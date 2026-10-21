extends Node3D

@export_enum("Torch", "Urn") var kind: int = 0
@export var use_placeholder: bool = true
@export var model_scene: PackedScene

func _ready() -> void:
	if not use_placeholder and model_scene != null:
		$VisualRoot.add_child(model_scene.instantiate())
		return
	var visual: Node3D = $VisualRoot
	if kind == 0:
		PrimitiveArt.cylinder(visual, Vector3(0, -0.18, 0), 0.07, 0.5, Color("493a2e"))
		PrimitiveArt.orb(visual, Vector3.ZERO, 0.13, Color("e8a14e"), 2.0)
	else:
		PrimitiveArt.orb(visual, Vector3(0, 0.4, 0), 0.4, Color("766c5a"))
		PrimitiveArt.cylinder(visual, Vector3(0, 0.7, 0), 0.22, 0.18, Color("91826a"))
		PrimitiveArt.cylinder(visual, Vector3(0, 0.04, 0), 0.3, 0.08, Color("91826a"))
