@tool
extends EditorExportPlugin
## Stock Godot's begin hook cannot abort. Never present this warning as a security gate.

func _get_name() -> String:
	return "CinderkeepExportWarning"

func _export_begin(_features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
	var result: Dictionary = preload("res://addons/cinderkeep_level_tools/export_preflight.gd").check()
	if not result.ok:
		get_export_platform().add_message(EditorExportPlatform.EXPORT_MESSAGE_WARNING, "Cinderkeep maps", "Stock export bypasses Cinderkeep's checked-export gate. Maps are missing/stale: " + "; ".join(PackedStringArray(result.errors)) + " Use Cinderkeep Checked Export after rebuilding.")
