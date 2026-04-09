extends Node

const PROJECT_LOG_DIR = "res://logs"
const FALLBACK_LOG_DIR = "user://logs"

var _log_file = File.new()
var _log_path = ""
var _error_count = 0
var _warning_count = 0
var _session_summary_written = false


func _ready():
	_open_log()
	log_separator()
	log_info("Game session started")
	log_info("Engine version: %s" % Engine.get_version_info().get("string", "unknown"))
	log_info("Platform: %s" % OS.get_name())
	log_info("Executable path: %s" % OS.get_executable_path())
	log_info("User data dir: %s" % ProjectSettings.globalize_path("user://"))


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		_write_session_summary()
	elif what == NOTIFICATION_PREDELETE:
		_write_session_summary()


func log_info(message):
	_write_line("INFO", str(message))


func log_warning(message):
	_warning_count += 1
	_write_line("WARN", str(message))


func log_error(message):
	_error_count += 1
	_write_line("ERROR", str(message))


func log_ok(message = "No explicit errors recorded during this step"):
	_write_line("OK", str(message))


func log_separator():
	_write_line("INFO", "----------------------------------------")


func log_scene(scene_name):
	_write_line("SCENE", str(scene_name))


func log_game_event(event_name, details = ""):
	if String(details) == "":
		_write_line("GAME", str(event_name))
	else:
		_write_line("GAME", "%s | %s" % [event_name, details])


func get_log_path():
	return _log_path


func _open_log():
	var directory = Directory.new()
	var dt = OS.get_datetime()
	var file_name = "game_log_%04d-%02d-%02d_%02d-%02d-%02d.txt" % [
		dt.year,
		dt.month,
		dt.day,
		dt.hour,
		dt.minute,
		dt.second
	]

	var project_log_path = "%s/%s" % [PROJECT_LOG_DIR, file_name]
	if not directory.dir_exists(PROJECT_LOG_DIR):
		directory.make_dir_recursive(PROJECT_LOG_DIR)

	var result = _log_file.open(project_log_path, File.WRITE)
	if result == OK:
		_log_path = ProjectSettings.globalize_path(project_log_path)
		_write_line("INFO", "Log file created")
		return

	var fallback_log_path = "%s/%s" % [FALLBACK_LOG_DIR, file_name]
	if not directory.dir_exists(FALLBACK_LOG_DIR):
		directory.make_dir_recursive(FALLBACK_LOG_DIR)

	result = _log_file.open(fallback_log_path, File.WRITE)
	if result != OK:
		push_error("GameLogger: failed to open log file in project and fallback directories")
		return

	_log_path = ProjectSettings.globalize_path(fallback_log_path)
	_write_line("WARN", "Project log directory unavailable, using fallback user directory")
	_write_line("INFO", "Log file created")


func _write_session_summary():
	if _session_summary_written:
		return
	if not _log_file.is_open():
		return
	_session_summary_written = true

	if _error_count == 0:
		_write_line("OK", "Session finished without explicit logged errors")
	else:
		_write_line("ERROR", "Session finished with %d logged error(s)" % _error_count)

	if _warning_count > 0:
		_write_line("WARN", "Warnings logged: %d" % _warning_count)

	_write_line("INFO", "Log saved to %s" % _log_path)
	_log_file.close()


func _write_line(level, message):
	var timestamp = _timestamp()
	var line = "[%s] [%s] %s" % [timestamp, level, message]

	if _log_file.is_open():
		_log_file.store_line(line)
		_log_file.flush()

	print(line)


func _timestamp():
	var dt = OS.get_datetime()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		dt.year,
		dt.month,
		dt.day,
		dt.hour,
		dt.minute,
		dt.second
	]
