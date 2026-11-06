@tool
extends Node
## Non-blocking, staged PCK export. Only publishes after a successful, unchanged preflight.

signal finished(result: Dictionary)
const PREFLIGHT = preload("res://addons/cinderkeep_level_tools/export_preflight.gd")
var process_id: int = -1
var output_path: String
var staging_path: String
var log_path: String
var signature: String

func start_export(output: String) -> Dictionary:
	if process_id != -1:
		return {"ok": false, "errors": ["A checked export is already running."], "issues": []}
	output_path = ProjectSettings.globalize_path(output) if output.begins_with("res://") else output
	var result := PREFLIGHT.prepare(output_path)
	if not result.ok:
		return result
	signature = result.signature
	var directory := ProjectSettings.globalize_path("res://builds/validation/checked-export-%d" % Time.get_ticks_usec())
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		return {"ok": false, "errors": ["Could not create export staging directory."], "issues": []}
	staging_path = directory.path_join("Cinderkeep.pck")
	log_path = directory.path_join("export.log")
	process_id = OS.create_process(OS.get_executable_path(), PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--export-pack", "Windows Desktop", staging_path, "--log-file", log_path]))
	if process_id == -1:
		return {"ok": false, "errors": ["Could not launch the Godot exporter."], "issues": []}
	set_process(true)
	return {"ok": true, "running": true, "errors": [], "issues": []}

func _process(_delta: float) -> void:
	if process_id == -1 or OS.is_process_running(process_id):
		return
	var exit_code := OS.get_process_exit_code(process_id)
	process_id = -1
	set_process(false)
	var result := PREFLIGHT.prepare(output_path)
	var log_text := FileAccess.get_file_as_string(log_path) if FileAccess.file_exists(log_path) else ""
	if exit_code != 0 or "ERROR:" in log_text or not FileAccess.file_exists(staging_path):
		result.errors.append("Godot export failed; see " + log_path)
	elif result.signature != signature:
		result.errors.append("Maps changed during export. Staged output retained; final output was not published. Export again after rebuilding.")
	if result.errors.is_empty():
		var error := DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
		if error == OK and not FileAccess.file_exists(output_path):
			error = DirAccess.copy_absolute(staging_path, output_path)
		else:
			error = ERR_ALREADY_EXISTS if FileAccess.file_exists(output_path) else error
		if error != OK:
			result.errors.append("Could not publish output; existing files are left untouched: " + error_string(error))
	result.ok = result.errors.is_empty()
	result["path"] = output_path
	result["log_path"] = log_path
	finished.emit(result)

func _exit_tree() -> void:
	if process_id != -1 and OS.is_process_running(process_id):
		OS.kill(process_id) # Only the child exporter this node started.
