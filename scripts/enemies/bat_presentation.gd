extends Node3D
## Animated Fire Bat visual: Meshy model, Blender rig (tools/blender/rig_bat.py).
## Clips: fly (loop), attack, hit, death. The AnimationPlayer pauses with the tree.

const CLIPS := [&"fly", &"attack", &"hit", &"death"]
var player: AnimationPlayer
var dead: bool = false
var action: StringName = &"fly"

func _ready() -> void:
	player = find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var fly = player.get_animation(&"fly")
	fly.loop_mode = Animation.LOOP_LINEAR
	player.get_animation(&"death").loop_mode = Animation.LOOP_NONE
	player.animation_finished.connect(_on_finished)
	# Desynchronize neighbouring bats.
	player.play(&"fly")
	player.seek(fmod(absf(global_position.x * 0.37 + global_position.z * 0.61), fly.length), true)

func has_clips() -> bool:
	return CLIPS.all(func(clip): return player.has_animation(clip))

func _play(clip: StringName) -> void:
	action = clip
	player.play(clip, 0.08)

func _on_finished(clip: StringName) -> void:
	if not dead and clip != &"fly":
		_play(&"fly")

func begin_attack() -> void:
	if not dead:
		_play(&"attack")

func attack_contact() -> void:
	pass

func show_hit() -> void:
	if not dead and action != &"attack":
		_play(&"hit")

func die() -> void:
	if dead:
		return
	dead = true
	_play(&"death")

func advance_visual(_delta: float, _movement_distance: float, _ai_attacking: bool, _windup_remaining: float, _windup_duration: float) -> void:
	# Faster wing beats while travelling read as effort; idle hovering is calmer.
	if not dead and action == &"fly":
		player.speed_scale = 1.0 + clampf(_movement_distance * 8.0, 0.0, 0.4)
	else:
		player.speed_scale = 1.0
