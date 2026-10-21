extends CanvasLayer

var viewport: SubViewport
var stage: Node3D
var melee: Node3D
var magic: Node3D
var attack_time: float = 0.0
var selected_slot: int = 0
@onready var weapons = get_parent().get_node("Weapons")

func _ready() -> void:
	var container = SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.handle_input_locally = false
	container.add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	var camera = Camera3D.new()
	camera.fov = 65.0
	camera.near = 0.01
	viewport.add_child(camera)
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b7c1c8")
	env.ambient_light_energy = 0.85
	environment.environment = env
	viewport.add_child(environment)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -35, 0)
	light.light_color = Color("ffdcab")
	light.light_energy = 1.2
	viewport.add_child(light)
	melee = load("res://scenes/weapons/melee_viewmodel.tscn").instantiate()
	magic = load("res://scenes/weapons/magic_viewmodel.tscn").instantiate()
	stage.add_child(melee)
	stage.add_child(magic)
	select(0)

func select(slot: int) -> void:
	selected_slot = slot
	melee.visible = slot == 0
	magic.visible = slot == 1

func animate_attack(slot: int) -> void:
	if slot == 1:
		attack_time = 0.3

func _process(delta: float) -> void:
	attack_time = maxf(0.0, attack_time - delta)
	var pulse = sin((attack_time / 0.3) * PI)
	stage.rotation = Vector3.ZERO
	stage.position = Vector3.ZERO
	if selected_slot == 1:
		stage.position.z = pulse * 0.12
		return
	var progress: float = weapons.phase_progress()
	if weapons.phase == weapons.Phase.WINDUP:
		stage.rotation.z = lerpf(0.0, -0.3, progress)
		stage.position = Vector3(0.1 * progress, 0, -0.05 * progress)
	elif weapons.phase == weapons.Phase.ACTIVE:
		stage.rotation.z = lerpf(-0.3, 0.95, progress)
		stage.position = Vector3(lerpf(0.1, -0.4, progress), -sin(progress * PI) * 0.1, 0.12 * progress)
	elif weapons.phase == weapons.Phase.RECOVERY:
		stage.rotation.z = lerpf(0.95, 0.0, progress)
		stage.position = Vector3(-0.4, 0, 0.12) * (1.0 - progress)
