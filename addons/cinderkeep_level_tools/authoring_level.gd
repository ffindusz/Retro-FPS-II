@tool
extends Node3D
## Editor source only. Build creates an independent playable scene.

@export var level_title: String = "New Cinderkeep Level"
@export_file("*.tscn") var runtime_path: String = "res://scenes/levels/generated/new_level.tscn"
