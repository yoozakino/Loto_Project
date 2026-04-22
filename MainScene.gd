extends Node2D

const BASE_VIEWPORT_SIZE = Vector2(1280, 800)

var next_action = ""
var _layout_initialized = false
var _base_control_layouts = {}
var rules_popup_layer = null
var rules_popup_dim = null
var rules_popup_panel = null
var rules_popup_title_label = null
var rules_popup_text_label = null
var rules_popup_close_button = null


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
	$RulesButton.text = "Правила"
	_normalize_menu_buttons()
	_normalize_game_title()
	_log_info("Main menu initialized")
	_create_rules_popup()
	_cache_base_layout()
	_apply_responsive_layout()
	if not get_viewport().is_connected("size_changed", self, "_on_viewport_size_changed"):
		get_viewport().connect("size_changed", self, "_on_viewport_size_changed")


func _input(event):
	if rules_popup_layer != null and rules_popup_layer.visible and event.is_action_pressed("ui_cancel"):
		_hide_rules_popup()
		get_tree().set_input_as_handled()

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


func _on_RulesButton_pressed():
	_play_button_sound1()
	_show_rules_popup()
	_log_game_event("Main menu button", "Rules pressed")
	
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

	for node_name in ["PlayButton", "SettingsButton", "RulesButton", "ExitButton", "GameNameLabel"]:
		var control = get_node(node_name)
		_base_control_layouts[node_name] = Rect2(
			Vector2(control.margin_left, control.margin_top),
			Vector2(control.margin_right - control.margin_left, control.margin_bottom - control.margin_top)
		)

	_layout_initialized = true


func _normalize_menu_buttons():
	var button_names = ["PlayButton", "SettingsButton", "RulesButton", "ExitButton"]
	var left = 550.0
	var width = 240.0
	var height = 70.0
	var top_positions = {
		"PlayButton": 300.0,
		"SettingsButton": 420.0,
		"RulesButton": 540.0,
		"ExitButton": 660.0
	}
	var source_button = $PlayButton

	for node_name in button_names:
		var button = get_node(node_name)
		button.anchor_left = 0.0
		button.anchor_top = 0.0
		button.anchor_right = 0.0
		button.anchor_bottom = 0.0
		button.rect_scale = Vector2.ONE
		button.rect_rotation = 0.0
		button.rect_pivot_offset = Vector2.ZERO
		button.margin_left = left
		button.margin_top = top_positions[node_name]
		button.margin_right = left + width
		button.margin_bottom = top_positions[node_name] + height
		button.rect_min_size = Vector2.ZERO

		if button != source_button:
			button.set("custom_colors/font_color_disabled", source_button.get("custom_colors/font_color_disabled"))
			button.set("custom_colors/font_color_focus", source_button.get("custom_colors/font_color_focus"))
			button.set("custom_colors/font_color_hover_pressed", source_button.get("custom_colors/font_color_hover_pressed"))
			button.set("custom_colors/font_color", source_button.get("custom_colors/font_color"))
			button.set("custom_fonts/font", source_button.get("custom_fonts/font"))
			button.set("custom_styles/hover", source_button.get("custom_styles/hover"))
			button.set("custom_styles/pressed", source_button.get("custom_styles/pressed"))
			button.set("custom_styles/normal", source_button.get("custom_styles/normal"))


func _normalize_game_title():
	var title = $GameNameLabel
	title.anchor_left = 0.0
	title.anchor_top = 0.0
	title.anchor_right = 0.0
	title.anchor_bottom = 0.0
	title.margin_left = 500.0
	title.margin_top = 110.0
	title.margin_right = 840.0
	title.margin_bottom = 250.0
	title.align = Label.ALIGN_CENTER
	title.valign = Label.VALIGN_CENTER


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

	_update_rules_popup_layout(screen_size)


func _get_effective_screen_size():
	var viewport_size = get_viewport_rect().size
	var window_size = OS.window_size

	if window_size.x > 0 and window_size.y > 0:
		return Vector2(max(viewport_size.x, window_size.x), max(viewport_size.y, window_size.y))

	return viewport_size


func _create_rules_popup():
	rules_popup_layer = CanvasLayer.new()
	rules_popup_layer.visible = false
	add_child(rules_popup_layer)

	rules_popup_dim = ColorRect.new()
	rules_popup_dim.color = Color(0, 0, 0, 0.55)
	rules_popup_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	rules_popup_layer.add_child(rules_popup_dim)

	rules_popup_panel = Panel.new()
	rules_popup_layer.add_child(rules_popup_panel)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.18, 0.18, 0.18, 0.96)
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	rules_popup_panel.add_stylebox_override("panel", panel_style)

	rules_popup_title_label = Label.new()
	rules_popup_title_label.align = Label.ALIGN_CENTER
	rules_popup_title_label.valign = Label.VALIGN_CENTER
	rules_popup_title_label.text = "Правила"
	rules_popup_panel.add_child(rules_popup_title_label)

	rules_popup_text_label = Label.new()
	rules_popup_text_label.autowrap = true
	rules_popup_text_label.valign = Label.VALIGN_CENTER
	rules_popup_text_label.text = "1. В начале партии случайно выбирается игровое поле.\n2. Числа появляются автоматически по одному.\n3. Если выпавшее число есть на карточке бота, бот отмечает его сам.\n4. Игрок должен нажимать только на выпавшие числа на своей карточке.\n5. Нельзя отмечать число, которое еще не выпадало.\n6. Побеждает тот, кто первым закроет все числа на своей карточке."
	rules_popup_panel.add_child(rules_popup_text_label)

	rules_popup_close_button = Button.new()
	rules_popup_close_button.text = "Закрыть"
	_copy_menu_button_style(get_node("PlayButton"), rules_popup_close_button)
	rules_popup_close_button.connect("pressed", self, "_on_rules_popup_close_pressed")
	rules_popup_panel.add_child(rules_popup_close_button)

	_update_rules_popup_layout(_get_effective_screen_size())


func _copy_menu_button_style(source_button, target_button):
	target_button.set("custom_colors/font_color_disabled", source_button.get("custom_colors/font_color_disabled"))
	target_button.set("custom_colors/font_color_focus", source_button.get("custom_colors/font_color_focus"))
	target_button.set("custom_colors/font_color_hover_pressed", source_button.get("custom_colors/font_color_hover_pressed"))
	target_button.set("custom_colors/font_color", source_button.get("custom_colors/font_color"))
	target_button.set("custom_styles/hover", source_button.get("custom_styles/hover"))
	target_button.set("custom_styles/pressed", source_button.get("custom_styles/pressed"))
	target_button.set("custom_styles/normal", source_button.get("custom_styles/normal"))

	var source_font = source_button.get("custom_fonts/font")
	if source_font != null:
		var button_font = source_font.duplicate()
		button_font.size = 30
		target_button.set("custom_fonts/font", button_font)


func _update_rules_popup_layout(screen_size):
	if rules_popup_layer == null:
		return

	rules_popup_dim.rect_position = Vector2.ZERO
	rules_popup_dim.rect_size = screen_size

	var panel_width = min(900, max(700, screen_size.x * 0.62))
	var panel_height = min(520, max(430, screen_size.y * 0.58))
	rules_popup_panel.rect_size = Vector2(panel_width, panel_height)
	rules_popup_panel.rect_position = Vector2(
		(screen_size.x - panel_width) * 0.5,
		(screen_size.y - panel_height) * 0.5
	)

	rules_popup_title_label.rect_position = Vector2(30, 22)
	rules_popup_title_label.rect_size = Vector2(panel_width - 60, 52)

	rules_popup_text_label.rect_position = Vector2(36, 90)
	rules_popup_text_label.rect_size = Vector2(panel_width - 72, panel_height - 170)

	rules_popup_close_button.rect_size = Vector2(220, 60)
	rules_popup_close_button.rect_position = Vector2((panel_width - rules_popup_close_button.rect_size.x) * 0.5, panel_height - 84)

	var title_font = DynamicFont.new()
	title_font.font_data = load("res://Montserrat-SemiBold.ttf")
	title_font.size = 38
	rules_popup_title_label.add_font_override("font", title_font)
	rules_popup_title_label.add_color_override("font_color", Color(0.96, 0.84, 0.35, 1))

	var body_font = DynamicFont.new()
	body_font.font_data = load("res://Montserrat-SemiBold.ttf")
	body_font.size = 23
	rules_popup_text_label.add_font_override("font", body_font)
	rules_popup_text_label.add_color_override("font_color", Color(0.94, 0.94, 0.94, 1))


func _show_rules_popup():
	if rules_popup_layer == null:
		return

	rules_popup_layer.visible = true
	_update_rules_popup_layout(_get_effective_screen_size())


func _hide_rules_popup():
	if rules_popup_layer == null:
		return

	rules_popup_layer.visible = false


func _on_rules_popup_close_pressed():
	_play_button_sound1()
	_hide_rules_popup()
