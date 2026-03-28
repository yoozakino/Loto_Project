extends Node

const SETTINGS_PATH = "user://settings.cfg"

var brightness = 1.0
var volume = 1.0


func _ready():
	load_settings()
	call_deferred("apply_all")


func set_brightness_value(value):
	brightness = clamp(value, 0.2, 1.0)
	apply_brightness()
	save_settings()


func set_volume_value(value):
	volume = clamp(value, 0.0, 1.0)
	apply_volume()
	save_settings()


func apply_all():
	apply_brightness()
	apply_volume()


func apply_brightness():
	if get_tree() == null:
		return

	var root = get_tree().root
	if root != null and root.has_node("GameBrightness"):
		root.get_node("GameBrightness").color = Color(brightness, brightness, brightness)


func apply_volume():
	if get_tree() == null:
		return

	var root = get_tree().root
	if root == null:
		return

	if root.has_node("MusicScene/MainSoundtrackPlayer"):
		var main_player = root.get_node("MusicScene/MainSoundtrackPlayer")
		main_player.volume_db = _volume_to_db(volume)

	if root.has_node("MusicScene/PressedButtonSound1Player"):
		var button_player = root.get_node("MusicScene/PressedButtonSound1Player")
		button_player.volume_db = _volume_to_db(volume)


func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("display", "brightness", brightness)
	config.save(SETTINGS_PATH)


func load_settings():
	var config = ConfigFile.new()
	var result = config.load(SETTINGS_PATH)
	if result != OK:
		return

	volume = float(config.get_value("audio", "volume", 1.0))
	brightness = float(config.get_value("display", "brightness", 1.0))

	volume = clamp(volume, 0.0, 1.0)
	brightness = clamp(brightness, 0.2, 1.0)


func _volume_to_db(value):
	if value <= 0.0:
		return -80
	return linear2db(value)
