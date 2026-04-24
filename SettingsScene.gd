extends Node2D

const BASE_VIEWPORT_SIZE = Vector2(1280, 800)
const WINDOW_MODE_MAXIMIZED = 0
const WINDOW_MODE_FULLSCREEN = 1

var next_action = ""
var _layout_initialized = false
var _base_control_layouts = {}


func _logger():
	return get_node_or_null("/root/GameLogger")


func _log_info(message):
	var logger = _logger()
	if logger != null:
		logger.log_info(message)


func _log_scene(message):
	var logger = _logger()
	if logger != null:
		logger.log_scene(message)


func _log_game_event(event_name, details = ""):
	var logger = _logger()
	if logger != null:
		logger.log_game_event(event_name, details)

func _ready():
	_log_scene("SettingsScene loaded")
	$BrightnessSlider.value = Settings.brightness * $BrightnessSlider.max_value
	$VolumeSlider.value = Settings.volume * $VolumeSlider.max_value
	Settings.apply_all()
	_setup_window_mode_options()
	
	var exit_timer = Timer.new()
	exit_timer.name = "ExitTimer"
	exit_timer.wait_time = 0.33
	exit_timer.one_shot = true
	add_child(exit_timer)
	exit_timer.connect("timeout", self, "_on_ExitTimer_timeout")
	_log_info("Settings scene initialized")
	_normalize_settings_layout()
	_cache_base_layout()
	_apply_responsive_layout()
	if not get_viewport().is_connected("size_changed", self, "_on_viewport_size_changed"):
		get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	
func _play_button_sound1():
	var btn = get_node("/root/MusicScene/PressedButtonSound1Player")
	if btn.is_playing():
		btn.stop()
	btn.play()

func _on_HSlider_value_changed(value):
	var brightness = lerp(0.2, 1.0, value / $BrightnessSlider.max_value)
	
	Settings.set_brightness_value(brightness)
	_log_game_event("Settings", "Brightness slider changed to %.2f" % brightness)
	
func _on_VolumeSlider_value_changed(value):
	var volume = value / $VolumeSlider.max_value
	
	Settings.set_volume_value(volume)
	_log_game_event("Settings", "Volume slider changed to %.2f" % volume)
	
func _on_BackButton_pressed():
	_play_button_sound1()
	get_node("ExitTimer").start()
	next_action = "back"
	_log_game_event("Settings", "Back pressed")

func _on_ResetButton_pressed():
	_play_button_sound1()
	Settings.set_brightness_value(1.0)
	Settings.set_volume_value(1.0)
	Settings.set_fullscreen_enabled(false)
	$BrightnessSlider.value = Settings.brightness * $BrightnessSlider.max_value
	$VolumeSlider.value = Settings.volume * $VolumeSlider.max_value
	_update_window_mode_option()
	_log_game_event("Settings", "Settings reset to defaults")


func _on_WindowModeOption_item_selected(index):
	_play_button_sound1()
	Settings.set_fullscreen_enabled($WindowModeOption.get_item_id(index) == WINDOW_MODE_FULLSCREEN)
	_update_window_mode_option()
	_apply_responsive_layout()
	_log_game_event("Settings", "Window mode changed")
	
func _on_ExitTimer_timeout():
	match next_action:
		"back":
			_log_scene("Returning to MainScene from SettingsScene")
			get_tree().change_scene("res://MainScene.tscn")
	next_action = ""


func _on_viewport_size_changed():
	_apply_responsive_layout()


func _cache_base_layout():
	if _layout_initialized:
		return

	for node_name in ["SettingsLabel", "BrightnessLabel", "VolumeLabel", "BrightnessSlider", "VolumeSlider", "WindowModeLabel", "WindowModeOption", "BackButton", "ResetButton"]:
		var control = get_node(node_name)
		_base_control_layouts[node_name] = Rect2(
			Vector2(control.margin_left, control.margin_top),
			Vector2(control.margin_right - control.margin_left, control.margin_bottom - control.margin_top)
		)

	_layout_initialized = true


func _normalize_settings_layout():
	_set_rect($SettingsLabel, Rect2(500, 45, 340, 115))
	_set_rect($BrightnessLabel, Rect2(560, 175, 220, 45))
	_set_rect($BrightnessSlider, Rect2(489, 225, 181, 58))
	_set_rect($VolumeLabel, Rect2(560, 315, 220, 45))
	_set_rect($VolumeSlider, Rect2(489, 365, 181, 58))
	_set_rect($WindowModeLabel, Rect2(455, 455, 430, 42))
	_set_rect($WindowModeOption, Rect2(490, 535, 360, 62))
	_set_rect($BackButton, Rect2(550, 620, 240, 70))
	_set_rect($ResetButton, Rect2(550, 705, 240, 70))


func _setup_window_mode_options():
	$WindowModeOption.clear()
	$WindowModeOption.add_item("Развернутое окно", WINDOW_MODE_MAXIMIZED)
	$WindowModeOption.add_item("Полный экран", WINDOW_MODE_FULLSCREEN)

	var popup_font = $WindowModeOption.get("custom_fonts/font")
	if popup_font != null:
		$WindowModeOption.get_popup().add_font_override("font", popup_font)

	_update_window_mode_option()


func _update_window_mode_option():
	var mode_id = WINDOW_MODE_MAXIMIZED
	if Settings.fullscreen_enabled:
		mode_id = WINDOW_MODE_FULLSCREEN

	for index in range($WindowModeOption.get_item_count()):
		if $WindowModeOption.get_item_id(index) == mode_id:
			$WindowModeOption.select(index)
			return


func _set_rect(control, rect):
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.margin_left = rect.position.x
	control.margin_top = rect.position.y
	control.margin_right = rect.position.x + rect.size.x
	control.margin_bottom = rect.position.y + rect.size.y


func _apply_responsive_layout():
	if not _layout_initialized:
		return

	var screen_size = _get_effective_screen_size()
	if screen_size == Vector2.ZERO:
		return

	var offset = (screen_size - BASE_VIEWPORT_SIZE) * 0.5

	for node_name in _base_control_layouts.keys():
		var control = get_node(node_name)
		var rect = _base_control_layouts[node_name]
		control.margin_left = rect.position.x + offset.x
		control.margin_top = rect.position.y + offset.y
		control.margin_right = rect.position.x + rect.size.x + offset.x
		control.margin_bottom = rect.position.y + rect.size.y + offset.y


func _get_effective_screen_size():
	var raw_size = get_viewport_rect().size

	if raw_size.x <= 0 or raw_size.y <= 0:
		raw_size = OS.window_size
	if raw_size.x <= 0 or raw_size.y <= 0:
		return BASE_VIEWPORT_SIZE

	var screen_aspect = raw_size.x / raw_size.y
	var base_aspect = BASE_VIEWPORT_SIZE.x / BASE_VIEWPORT_SIZE.y

	if screen_aspect >= base_aspect:
		return Vector2(BASE_VIEWPORT_SIZE.y * screen_aspect, BASE_VIEWPORT_SIZE.y)

	return Vector2(BASE_VIEWPORT_SIZE.x, BASE_VIEWPORT_SIZE.x / screen_aspect)
