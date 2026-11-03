extends FortressPresentation
## Coordinate-independent atmosphere for authored maps; no demo dressing inference.

func setup(owner_level: Node3D) -> void:
	level = owner_level
	for node in level.find_children("*", "OmniLight3D", true, false):
		var light := node as OmniLight3D
		light.light_color = Color("ffc28a")
		light.light_energy = 2.0
		light.shadow_enabled = torches.size() < 2
		if light.shadow_enabled:
			light.shadow_bias = 0.08
			light.shadow_normal_bias = 1.0
			_disable_emitter_shadows(light.get_parent())
		torches.append(light)
		torch_bases.append(light.light_energy)
	for node in level.get_children():
		if node is WorldEnvironment:
			node.environment.ambient_light_energy = 0.42
			_setup_sky(node.environment)
	set_clock(0.0)
