extends Node2D

const BASE_VIEWPORT_SIZE = Vector2(1280, 800)

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
	_log_scene("MainScene loaded")
	var exit_timer = Timer.new()
	exit_timer.name = "ExitTimer"
	exit_timer.wait_time = 0.33
	exit_timer.one_shot = true
	add_child(exit_timer)
	exit_timer.connect("timeout", self, "_on_ExitTimer_timeout")
	_log_info("Main menu initialized")
	_cache_base_layout()
	_apply_responsive_layout()
	if not get_viewport().is_connected("size_changed", self, "_on_viewport_size_changed"):
		get_viewport().connect("size_changed", self, "_on_viewport_size_changed")

func _play_button_sound1():
	var btn = get_node("/root/MusicScene/PressedButtonSound1Player")
	if btn.is_playing():
		btn.stop()
	btn.play()

func _on_PlayButton_pressed():
	_play_button_sound1()
	next_action = "play"
	_log_game_event("Main menu button", "Play pressed")
	
	var music = get_node("/root/MusicScene/MainSoundtrackPlayer")
	if music.playing:
		music.stop()
	get_node("ExitTimer").start()
	
func _on_SettingsButton_pressed():
	_play_button_sound1()
	next_action = "settings"
	_log_game_event("Main menu button", "Settings pressed")
	get_node("ExitTimer").start()
	
func _on_ExitButton_pressed():
	_play_button_sound1()
	get_node("ExitTimer").start()
	next_action = "exit"
	_log_game_event("Main menu button", "Exit pressed")
	
func _on_ExitTimer_timeout():
	match next_action:
		"exit":
			_log_info("Application exit requested from main menu")
			get_tree().quit()
		"settings":
			_log_scene("Switching to SettingsScene")
			get_tree().change_scene("res://SettingsScene.tscn")
		"play":
			var gamefields = [
				"res://GameField1.tscn",
				"res://GameField2.tscn",
				"res://GameField3.tscn",
				"res://GameField4.tscn"
			]
			var random_scene = randi() % gamefields.size()
			var chosen_scene = gamefields[random_scene]
			_log_game_event("Game start", "Chosen scene: %s" % chosen_scene)
			get_tree().change_scene(chosen_scene)
	next_action = ""


func _on_viewport_size_changed():
	_apply_responsive_layout()


func _cache_base_layout():
	if _layout_initialized:
		return

	for node_name in ["PlayButton", "SettingsButton", "ExitButton", "GameNameLabel"]:
		var control = get_node(node_name)
		_base_control_layouts[node_name] = Rect2(
			Vector2(control.margin_left, control.margin_top),
			Vector2(control.margin_right - control.margin_left, control.margin_bottom - control.margin_top)
		)

	_layout_initialized = true


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
	var viewport_size = get_viewport_rect().size
	var window_size = OS.window_size

	if window_size.x > 0 and window_size.y > 0:
		return Vector2(max(viewport_size.x, window_size.x), max(viewport_size.y, window_size.y))

	return viewport_size
