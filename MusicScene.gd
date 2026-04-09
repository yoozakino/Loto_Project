extends Node2D

onready var main_soundtrack := $MainSoundtrackPlayer
onready var pressed_button_sound1 := $PressedButtonSound1Player


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


func _ready():
	Settings.apply_volume()
	_log_info("Music scene initialized")
	if main_soundtrack == null:
		_log_warning("Main soundtrack player not found")
	if pressed_button_sound1 == null:
		_log_warning("Button click sound player not found")
