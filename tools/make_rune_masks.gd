extends SceneTree
## Bakes the rune-glow emission masks from the Meshy albedo textures of the rune door frame
## (ember-orange runes) and the key socket (red keyhole). Rerun after replacing either model:
##   Godot --headless --path . --script res://tools/make_rune_masks.gd

const SIZE := 1024
const JOBS := [
	["res://assets/models/rune-door-frame/model_0.jpg", "res://assets/models/rune-door-frame/rune_glow.png", "ember"],
	["res://assets/models/rune-key-socket/model_0.jpg", "res://assets/models/rune-key-socket/rune_glow.png", "red"],
]

func _initialize() -> void:
	for job in JOBS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(job[0]))
		if image == null:
			push_error("Cannot read " + job[0])
			quit(1)
			return
		image.resize(SIZE, SIZE, Image.INTERPOLATE_BILINEAR)
		var mask := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
		var lit := 0
		for y in SIZE:
			for x in SIZE:
				var c := image.get_pixel(x, y)
				var v: float
				if job[2] == "ember":
					v = clampf((c.r - c.b - 0.25) * 3.0, 0, 1) * clampf((c.r - 0.35) * 3.0, 0, 1)
				else:
					# The keyhole is a dark saturated red (about 0.31, 0.045, 0.035); muddy stone stays out.
					v = clampf((c.r - c.g - 0.1) * 6.0, 0, 1) * clampf((c.r - 0.15) * 6.0, 0, 1)
				if v > 0.3:
					lit += 1
				mask.set_pixel(x, y, Color(v, v, v))
		var error := mask.save_png(ProjectSettings.globalize_path(job[1]))
		print("%s: %d glowing texels of %d (%s)" % [job[1], lit, SIZE * SIZE, error_string(error)])
	quit()
