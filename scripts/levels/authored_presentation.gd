extends FortressPresentation
## Coordinate-independent atmosphere for authored maps; no demo dressing inference.

func setup(owner_level: Node3D) -> void:
	level = owner_level
	for node in level.find_children("*", "OmniLight3D", true, false):
		var light := node as OmniLight3D
		if _fixture_of(light) != null:
			continue
		light.light_color = Color("ffc28a")
		light.light_energy = 2.0
		light.shadow_enabled = torches.size() < 2
		if light.shadow_enabled:
			light.shadow_bias = 0.08
			light.shadow_normal_bias = 1.0
			_disable_emitter_shadows(light.get_parent())
		register_torch(light)
	for node in level.find_children("*", "", true, false):
		if node is LightFixture:
			node.phase = float(fixtures.size()) * 1.7 + 0.5
			node.build()
			fixtures.append(node)
	for node in level.get_children():
		if node is WorldEnvironment:
			node.environment.ambient_light_energy = 0.42
			_setup_sky(node.environment)
	set_clock(0.0)

func _fixture_of(node: Node) -> LightFixture:
	while node != null and node != level:
		if node is LightFixture:
			return node
		node = node.get_parent()
	return null
