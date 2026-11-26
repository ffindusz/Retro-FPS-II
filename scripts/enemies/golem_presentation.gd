extends "res://scripts/enemies/skeleton_presentation.gd"
## Stone golem boss presentation: the skeleton presentation plus a dormant statue state, an
## awakening (grinding shake, dust, eyes lighting up) and a dust ring where the hammer lands.
##
## The supplied golem has no eyes, so two small emissive eyes are added on the `headfront` bone
## and driven by the same eye_flicker.gd as the skeletons.

const AWAKEN_SECONDS: float = 1.6
## Eye centre relative to the `headfront` bone, in the model's own metres (+Z is the face).
@export var eye_offset: Vector3 = Vector3(0.0, 0.0, 0.0)
@export var eye_spacing: float = 0.11
@export var eye_radius: float = 0.03
@export var eye_color: Color = Color(1.0, 0.42, 0.1)
## Where the hammer head lands, ahead of the actor (actor metres, -Z forward).
@export var slam_reach: float = 1.5
## Multiplies the body texture; the supplied texture is very light and reads as white in torchlight.
@export var body_tint: Color = Color(0.62, 0.62, 0.6)

var dormant: bool = true
var awakening: bool = false
var awaken_age: float = 0.0
var eye_anchor: BoneAttachment3D

func _prepare_model() -> void:
	var rig := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	eye_anchor = BoneAttachment3D.new()
	eye_anchor.name = "EyeAnchor"
	eye_anchor.bone_name = "headfront"
	rig.add_child(eye_anchor)
	var glow := MeshInstance3D.new()
	glow.name = "EyeGlow"
	glow.mesh = _eye_mesh()
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	eye_anchor.add_child(glow)

func _eye_mesh() -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radius = eye_radius
	sphere.height = eye_radius * 1.4
	sphere.radial_segments = 12
	sphere.rings = 6
	var tool := SurfaceTool.new()
	for side in [-1.0, 1.0]:
		tool.append_from(sphere, 0, Transform3D(Basis.IDENTITY, Vector3(side * eye_spacing / 2.0, 0, 0)))
	var mesh := tool.commit()
	var glow := StandardMaterial3D.new()
	# Dark stone sockets until the emission lights them.
	glow.albedo_color = Color(0.12, 0.1, 0.09)
	glow.emission_enabled = true
	glow.emission = eye_color
	glow.emission_energy_multiplier = 1.0
	mesh.surface_set_material(0, glow)
	return mesh

func _ready() -> void:
	super._ready()
	for index in range(materials.size()):
		base_colors[index] = base_colors[index] * body_tint
		materials[index].albedo_color = base_colors[index]
	base_color = base_colors[0]
	# The statue holds the first frame of its idle stance.
	idle_time = 0.0
	_sample(&"Idle", 0.0, 0.0, true)
	_place_eyes()
	holder.set_process(false)
	_set_eye_energy(0.0)

## The bone attachment carries the rig's centimetre scale and bone roll; place the eyes in the
## model's own frame (metres, facing +Z) at the face, once, relative to the attachment.
func _place_eyes() -> void:
	if eyes == null:
		return
	var bone := skeleton.find_bone(&"headfront")
	eye_anchor.global_transform = skeleton.global_transform * skeleton.get_bone_global_pose(bone)
	var frame := model.global_basis
	eyes.global_transform = Transform3D(frame, eye_anchor.global_position + frame * eye_offset)

func _set_eye_energy(energy: float) -> void:
	if eyes == null:
		return
	var eye_material := eyes.get_surface_override_material(0) as StandardMaterial3D
	if eye_material != null:
		eye_material.emission_energy_multiplier = energy
	eye_light.light_energy = eye_light_energy * energy / eye_energy
	eye_light.visible = eye_light.light_energy > 0.01

func awaken() -> void:
	if not dormant or dead:
		return
	dormant = false
	awakening = true
	awaken_age = 0.0
	_dust(Vector3(0, 0.05, 0), 1.2 * model_scale, 2.6 * model_scale, 0.9, Color(0.58, 0.54, 0.48, 0.55))

func advance_visual(delta: float, movement_distance: float, ai_attacking: bool, windup_remaining: float, windup_duration: float) -> void:
	if get_tree().paused:
		return
	if dormant and not dead:
		# A statue: no clip time, no flicker, eyes dark.
		return
	if awakening and not dead:
		awaken_age += delta
		var progress := clampf(awaken_age / AWAKEN_SECONDS, 0.0, 1.0)
		var eye_material := eyes.get_surface_override_material(0) as StandardMaterial3D if eyes != null else null
		if eye_material != null:
			eye_material.emission_energy_multiplier = eye_energy * smoothstep(0.1, 0.9, progress)
		super.advance_visual(delta, 0.0, false, 0.0, 0.0)
		# Grinding shake that settles as the golem comes alive.
		var shake := (1.0 - progress) * 0.035 * model_scale
		holder.position = Vector3(sin(awaken_age * 53.0) * shake, 0.0, cos(awaken_age * 41.0) * shake)
		if progress >= 1.0:
			awakening = false
			holder.position = Vector3.ZERO
			holder.set_process(true)
		return
	super.advance_visual(delta, movement_distance, ai_attacking, windup_remaining, windup_duration)

## No stagger while the statue sleeps or wakes.
func stagger() -> float:
	if dormant or awakening:
		return 0.0
	return super.stagger()

func attack_contact() -> void:
	var was_dead := dead
	super.attack_contact()
	if not was_dead and not get_tree().paused:
		_dust(Vector3(0, 0.05, -slam_reach), 0.3, 2.4, 0.45, Color(0.62, 0.57, 0.5, 0.75))

func die() -> void:
	awakening = false
	holder.position = Vector3.ZERO
	super.die()
	_dust(Vector3(0, 0.05, 0), 1.0 * model_scale, 3.2 * model_scale, 1.2, Color(0.55, 0.52, 0.47, 0.6))

## Flat expanding dust ring on the floor, in actor space; independent of the actor once spawned.
func _dust(local_point: Vector3, from_radius: float, to_radius: float, seconds: float, color: Color) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "Dust"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.7
	torus.outer_radius = 1.0
	ring.mesh = torus
	var dust := StandardMaterial3D.new()
	dust.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust.albedo_color = color
	ring.material_override = dust
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.top_level = true
	add_child(ring)
	ring.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3(from_radius, 0.25, from_radius)), global_transform * local_point)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector3(to_radius, 0.25, to_radius), seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(dust, "albedo_color:a", 0.0, seconds)
	tween.tween_callback(ring.queue_free)
