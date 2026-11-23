extends Node3D
## Slow pulsing ember flicker for the skeleton warrior's glowing eyes.
##
## Attach this script to the root node of an instanced skeleton_warrior.glb scene
## (or any node above the "EyeGlow" mesh). Each instance gets its own material copy
## and a random phase, so a group of skeletons doesn't pulse in sync.

@export var base_energy := 1.4        ## Matches the emission strength baked into the .glb.
@export var pulse_amount := 0.22      ## Slow "breathing" swing, as a fraction of base_energy.
@export var pulse_period := 3.0       ## Seconds per slow pulse.
@export var flicker_amount := 0.12    ## Fast ember wobble, as a fraction of base_energy.
@export var flicker_speed := 4.0      ## Higher = jumpier flicker.
@export var eye_node_name := "EyeGlow"

var _material: StandardMaterial3D
var _noise := FastNoiseLite.new()
var _time := 0.0


func _ready() -> void:
	var eyes := find_child(eye_node_name, true, false) as MeshInstance3D
	if eyes == null:
		push_warning("eye_flicker.gd: no MeshInstance3D named '%s' found." % eye_node_name)
		set_process(false)
		return
	var source := eyes.get_active_material(0) as StandardMaterial3D
	if source == null:
		push_warning("eye_flicker.gd: '%s' has no StandardMaterial3D." % eye_node_name)
		set_process(false)
		return
	_material = source.duplicate() as StandardMaterial3D
	eyes.set_surface_override_material(0, _material)
	_noise.seed = randi()
	_noise.frequency = 1.0
	_time = randf() * 100.0


func _process(delta: float) -> void:
	_time += delta
	var pulse := sin(_time * TAU / pulse_period) * pulse_amount
	var flicker := _noise.get_noise_1d(_time * flicker_speed) * flicker_amount
	_material.emission_energy_multiplier = maxf(0.0, base_energy * (1.0 + pulse + flicker))
