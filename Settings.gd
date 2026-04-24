extends Node

const SETTINGS_PATH = "user://settings.cfg"

var brightness = 1.0
var volume = 1.0
var fullscreen_enabled = false


func _logger():
	return get_node_or_null("/root/GameLogger")


func _log_info(message):
	var logger = _logger()
	if logger != null:
		logger.log_info(message)


func _log_warning(message):
	var logger = _logger()
	if logger != null:
		logger.log_warning(message)


func _log_error(message):
	var logger = _logger()
	if logger != null:
		logger.log_error(message)


func _ready():
	load_settings()
	call_deferred("apply_all")
	_log_info("Settings singleton initialized")


func set_brightness_value(value):
	brightness = clamp(value, 0.2, 1.0)
	apply_brightness()
	save_settings()
	_log_info("Brightness updated to %.2f" % brightness)


func set_volume_value(value):
	volume = clamp(value, 0.0, 1.0)
	apply_volume()
	save_settings()
	_log_info("Volume updated to %.2f" % volume)


func set_fullscreen_enabled(value):
	fullscreen_enabled = value == true
	apply_window_mode()
	save_settings()
	_log_info("Window mode updated: %s" % _window_mode_name())


func apply_all():
	apply_brightness()
	apply_volume()
	apply_window_mode()


func apply_brightness():
	if get_tree() == null:
		_log_warning("apply_brightness skipped: tree is null")
		return

	var root = get_tree().root
	if root != null and root.has_node("GameBrightness"):
		root.get_node("GameBrightness").color = Color(brightness, brightness, brightness)
	else:
		_log_warning("GameBrightness node not found while applying brightness")


func apply_volume():
	if get_tree() == null:
		_log_warning("apply_volume skipped: tree is null")
		return

	var root = get_tree().root
	if root == null:
		_log_warning("apply_volume skipped: root is null")
		return

	if root.has_node("MusicScene/MainSoundtrackPlayer"):
		var main_player = root.get_node("MusicScene/MainSoundtrackPlayer")
		main_player.volume_db = _volume_to_db(volume)

	if root.has_node("MusicScene/PressedButtonSound1Player"):
		var button_player = root.get_node("MusicScene/PressedButtonSound1Player")
		button_player.volume_db = _volume_to_db(volume)


func apply_window_mode():
	if OS.has_feature("Android"):
		return

	OS.window_borderless = false
	OS.window_resizable = true

	if fullscreen_enabled:
		OS.window_maximized = false
		OS.window_fullscreen = true
	else:
		OS.window_fullscreen = false
		OS.window_borderless = false
		OS.window_resizable = true
		OS.window_maximized = true


func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("display", "brightness", brightness)
	config.set_value("display", "fullscreen_enabled", fullscreen_enabled)
	var result = config.save(SETTINGS_PATH)
	if result == OK:
		_log_info("Settings saved to %s" % SETTINGS_PATH)
	else:
		_log_error("Failed to save settings to %s, code=%s" % [SETTINGS_PATH, str(result)])


func load_settings():
	var config = ConfigFile.new()
	var result = config.load(SETTINGS_PATH)
	if result != OK:
		_log_warning("Settings file not loaded, defaults will be used")
		return

	volume = float(config.get_value("audio", "volume", 1.0))
	brightness = float(config.get_value("display", "brightness", 1.0))
	fullscreen_enabled = config.get_value("display", "fullscreen_enabled", false) == true

	volume = clamp(volume, 0.0, 1.0)
	brightness = clamp(brightness, 0.2, 1.0)
	_log_info("Settings loaded: volume=%.2f brightness=%.2f window_mode=%s" % [volume, brightness, _window_mode_name()])


func _volume_to_db(value):
	if value <= 0.0:
		return -80
	return linear2db(value)


func _window_mode_name():
	if fullscreen_enabled:
		return "fullscreen"
	return "maximized window"
