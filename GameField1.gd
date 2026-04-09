extends Node2D

const BASE_VIEWPORT_SIZE = Vector2(1280, 800)
const DRAW_INTERVAL = 3.0
const MARK_COLOR = Color(0.9, 0.15, 0.1, 0.45)
const BOT_MARK_COLOR = Color(0.15, 0.45, 0.95, 0.35)

var ui_font = null
var current_number = 0
var game_over = false

var available_numbers = []
var drawn_numbers = []

var player_numbers = []
var bot_numbers = []

var player_marked = []
var bot_marked = []

var player_labels = {}
var bot_labels = {}

var player_card = null
var bot_card = null
var draw_timer = null
var player_click_sound = null

var result_overlay = null
var result_message_label = null
var result_summary_label = null
var result_dim = null
var result_panel = null
var restart_button_ref = null
var back_button_ref = null
var game_card_sprite = null
var _base_card_position = Vector2.ZERO
var _base_card_scale = Vector2.ONE
var _base_number_rect = Rect2()
var _base_number_font_size = 170
var _base_content_rect = Rect2()
var _responsive_layout_ready = false

onready var NumLabel = $Number


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


func _log_scene(message):
	var logger = _logger()
	if logger != null:
		logger.log_scene(message)


func _log_game_event(event_name, details = ""):
	var logger = _logger()
	if logger != null:
		logger.log_game_event(event_name, details)


func _ready():
	randomize()
	_log_scene("%s loaded" % name)
	_create_ui_font()
	_create_player_click_sound()
	_stop_menu_music()
	_apply_game_volume()
	_find_cards()
	_cache_base_layout()
	_prepare_cards()
	if player_card == null or bot_card == null:
		NumLabel.text = "ERR"
		_log_error("Game field cards were not found correctly")
		return
	_create_result_overlay()
	_create_draw_timer()
	_fill_barrels()
	_log_game_event("Game field initialized", "Player numbers: %d, Bot numbers: %d" % [player_numbers.size(), bot_numbers.size()])
	_apply_responsive_layout()
	if not get_viewport().is_connected("size_changed", self, "_on_viewport_size_changed"):
		get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_draw_next_number()


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_log_game_event("Input", "ui_cancel pressed")
		_return_to_menu()
		return

	if game_over and event.is_action_pressed("ui_accept"):
		_log_game_event("Input", "ui_accept pressed after game over")
		_return_to_menu()
		return


func _stop_menu_music():
	if has_node("/root/MusicScene/MainSoundtrackPlayer"):
		var music = get_node("/root/MusicScene/MainSoundtrackPlayer")
		if music.playing:
			music.stop()
			_log_info("Main menu music stopped for gameplay")
	else:
		_log_warning("MainSoundtrackPlayer not found when starting gameplay")


func _apply_game_volume():
	if has_node("GameSoundtrackPlayer"):
		if Settings.volume <= 0:
			$GameSoundtrackPlayer.volume_db = -80
		else:
			$GameSoundtrackPlayer.volume_db = linear2db(Settings.volume)

	if player_click_sound != null:
		if Settings.volume <= 0:
			player_click_sound.volume_db = -80
		else:
			player_click_sound.volume_db = linear2db(Settings.volume)


func _find_cards():
	for child in get_children():
		if child is Sprite:
			if game_card_sprite == null:
				game_card_sprite = child
			for subchild in child.get_children():
				if subchild is GridContainer:
					if String(subchild.name).begins_with("PlayerCard"):
						player_card = subchild
					elif String(subchild.name).begins_with("BotCard"):
						bot_card = subchild
	_log_info("Cards lookup complete for scene %s" % name)


func _cache_base_layout():
	if _responsive_layout_ready:
		return

	if game_card_sprite != null:
		_base_card_position = game_card_sprite.position
		_base_card_scale = game_card_sprite.scale

	var number_font = NumLabel.get("custom_fonts/font")
	if number_font != null:
		_base_number_font_size = number_font.size

	_base_number_rect = Rect2(
		Vector2(NumLabel.margin_left, NumLabel.margin_top),
		Vector2(NumLabel.margin_right - NumLabel.margin_left, NumLabel.margin_bottom - NumLabel.margin_top)
	)

	var sprite_rect = _get_sprite_rect(_base_card_position, _base_card_scale)
	_base_content_rect = sprite_rect
	_base_content_rect = _merge_rects(_base_content_rect, _base_number_rect)
	_responsive_layout_ready = true


func _on_viewport_size_changed():
	_apply_responsive_layout()


func _apply_responsive_layout():
	var screen_size = _get_effective_screen_size()
	if screen_size == Vector2.ZERO:
		return

	var offset = (screen_size - BASE_VIEWPORT_SIZE) * 0.5
	if game_card_sprite != null:
		game_card_sprite.position = _base_card_position + offset

	NumLabel.margin_left = _base_number_rect.position.x + offset.x
	NumLabel.margin_top = _base_number_rect.position.y + offset.y
	NumLabel.margin_right = _base_number_rect.position.x + _base_number_rect.size.x + offset.x
	NumLabel.margin_bottom = _base_number_rect.position.y + _base_number_rect.size.y + offset.y

	var overlay_scale = min(screen_size.x / BASE_VIEWPORT_SIZE.x, screen_size.y / BASE_VIEWPORT_SIZE.y)
	_apply_result_overlay_layout(screen_size, overlay_scale)


func _get_effective_screen_size():
	var viewport_size = get_viewport_rect().size
	var window_size = OS.window_size

	if window_size.x > 0 and window_size.y > 0:
		if viewport_size == Vector2.ZERO:
			return window_size
		return Vector2(max(viewport_size.x, window_size.x), max(viewport_size.y, window_size.y))

	return viewport_size


func _get_sprite_rect(position, scale):
	if game_card_sprite == null or game_card_sprite.texture == null:
		return Rect2(position, Vector2.ZERO)

	var texture_size = game_card_sprite.texture.get_size()
	var scaled_size = Vector2(texture_size.x * scale.x, texture_size.y * scale.y)
	return Rect2(position - scaled_size * 0.5, scaled_size)


func _merge_rects(a, b):
	if a.size == Vector2.ZERO:
		return b
	if b.size == Vector2.ZERO:
		return a

	var left = min(a.position.x, b.position.x)
	var top = min(a.position.y, b.position.y)
	var right = max(a.position.x + a.size.x, b.position.x + b.size.x)
	var bottom = max(a.position.y + a.size.y, b.position.y + b.size.y)
	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))


func _apply_result_overlay_layout(screen_size, scale_factor):
	if result_overlay == null or result_panel == null or result_dim == null:
		return

	result_dim.rect_position = Vector2.ZERO
	result_dim.rect_size = screen_size

	var panel_width = max(420, min(screen_size.x * 0.72, 640 * max(scale_factor, 0.85)))
	var panel_height = max(180, min(screen_size.y * 0.34, 220 * max(scale_factor, 0.9)))
	result_panel.rect_size = Vector2(panel_width, panel_height)
	result_panel.rect_position = Vector2(
		(screen_size.x - result_panel.rect_size.x) * 0.5,
		(screen_size.y - result_panel.rect_size.y) * 0.5
	)

	result_message_label.rect_position = Vector2(24, 20)
	result_message_label.rect_size = Vector2(result_panel.rect_size.x - 48, 72)
	_apply_font_to_control(result_message_label, max(22, int(round(30 * scale_factor))))

	result_summary_label.rect_position = Vector2(24, 102)
	result_summary_label.rect_size = Vector2(result_panel.rect_size.x - 48, 28)
	_apply_font_to_control(result_summary_label, max(18, int(round(24 * scale_factor))))

	if restart_button_ref != null:
		restart_button_ref.rect_position = Vector2(32, result_panel.rect_size.y - 52)
		restart_button_ref.rect_size = Vector2((result_panel.rect_size.x - 96) * 0.5, 36)
		_apply_font_to_control(restart_button_ref, max(16, int(round(20 * scale_factor))))

	if back_button_ref != null:
		back_button_ref.rect_position = Vector2(result_panel.rect_size.x * 0.5 + 16, result_panel.rect_size.y - 52)
		back_button_ref.rect_size = Vector2((result_panel.rect_size.x - 96) * 0.5, 36)
		_apply_font_to_control(back_button_ref, max(16, int(round(20 * scale_factor))))


func _prepare_cards():
	_collect_card(player_card, true)
	_collect_card(bot_card, false)


func _collect_card(card, is_player):
	if card == null:
		_log_error("Tried to collect numbers from a null card")
		return

	for label in card.get_children():
		if not (label is Label):
			continue

		label.text = ""
		label.align = Label.ALIGN_CENTER
		label.valign = Label.VALIGN_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.rect_clip_content = true

		var node_name = String(label.name)
		if _is_zero_slot(node_name):
			continue

		var number = int(node_name)
		if is_player:
			label.mouse_filter = Control.MOUSE_FILTER_STOP
			if not label.is_connected("gui_input", self, "_on_player_label_gui_input"):
				label.connect("gui_input", self, "_on_player_label_gui_input", [number])
			player_numbers.append(number)
			player_labels[number] = label
		else:
			bot_numbers.append(number)
			bot_labels[number] = label

	if is_player:
		_log_info("Player card collected with %d numbers" % player_numbers.size())
	else:
		_log_info("Bot card collected with %d numbers" % bot_numbers.size())


func _is_zero_slot(node_name):
	return node_name.length() > 1 and node_name.begins_with("0")


func _create_draw_timer():
	draw_timer = Timer.new()
	draw_timer.wait_time = DRAW_INTERVAL
	draw_timer.one_shot = false
	draw_timer.autostart = false
	draw_timer.connect("timeout", self, "_on_draw_timer_timeout")
	add_child(draw_timer)


func _fill_barrels():
	available_numbers.clear()
	drawn_numbers.clear()
	for i in range(1, 91):
		available_numbers.append(i)
	available_numbers.shuffle()
	_log_info("Barrels prepared: %d numbers available" % available_numbers.size())


func _draw_next_number():
	if game_over:
		return

	if available_numbers.empty():
		_finish_game("Бочонки закончились. Игра завершена.")
		return

	current_number = available_numbers.pop_front()
	drawn_numbers.append(current_number)
	NumLabel.text = str(current_number)
	_log_game_event("Barrel drawn", "Number %d, remaining %d" % [current_number, available_numbers.size()])

	if bot_labels.has(current_number):
		_mark_bot_number(current_number)

	_check_winner()

	if not game_over and draw_timer.is_stopped():
		draw_timer.start()


func _on_player_label_gui_input(event, number):
	if game_over:
		return

	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		var label = player_labels.get(number, null)
		if label == null:
			return
		var click_margin = 8
		var click_size = label.rect_size
		if click_size == Vector2.ZERO:
			click_size = label.rect_min_size
		if event.position.x < click_margin or event.position.y < click_margin:
			return
		if event.position.x > click_size.x - click_margin or event.position.y > click_size.y - click_margin:
			return
		if _try_mark_player_number(number):
			_log_game_event("Player mark", "Number %d marked by player" % number)
			_play_player_click_sound()


func _try_mark_player_number(number):
	if player_marked.has(number):
		_log_warning("Player attempted to mark already marked number %d" % number)
		return false

	if not drawn_numbers.has(number):
		_log_warning("Player attempted to mark undrawn number %d" % number)
		return false

	player_marked.append(number)
	_visual_mark(player_labels[number], true)
	_check_winner()
	return true


func _mark_bot_number(number):
	if bot_marked.has(number):
		return

	bot_marked.append(number)
	_visual_mark(bot_labels[number], false)
	_log_game_event("Bot mark", "Number %d marked by bot" % number)


func _visual_mark(label, is_player):
	if label == null:
		return

	if label.has_node("Mark"):
		return

	var mark = ColorRect.new()
	mark.name = "Mark"
	var mark_margin = 6
	if label.rect_size == Vector2.ZERO:
		mark.rect_size = label.rect_min_size
	else:
		mark.rect_size = label.rect_size

	mark.rect_position = Vector2(mark_margin, mark_margin)
	mark.rect_size.x = max(0, mark.rect_size.x - mark_margin * 2)
	mark.rect_size.y = max(0, mark.rect_size.y - mark_margin * 2)

	if is_player:
		mark.color = MARK_COLOR
	else:
		mark.color = BOT_MARK_COLOR

	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_child(mark)


func _check_winner():
	if game_over:
		return

	var player_done = player_marked.size() >= player_numbers.size()
	var bot_done = bot_marked.size() >= bot_numbers.size()

	if player_done and bot_done:
		_finish_game("Ничья. Обе карточки закрыты.")
	elif player_done:
		_finish_game("Вы победили. Карточка игрока закрыта полностью.")
	elif bot_done:
		_finish_game("Победил бот. Он закрыл свою карточку первым.")


func _finish_game(message):
	game_over = true
	if draw_timer != null:
		draw_timer.stop()
	_log_game_event(
		"Game finished",
		"%s | Player %d/%d | Bot %d/%d | Drawn %d" % [
			message,
			player_marked.size(),
			player_numbers.size(),
			bot_marked.size(),
			bot_numbers.size(),
			drawn_numbers.size()
		]
	)
	_show_result_overlay(message)


func _create_result_overlay():
	result_overlay = CanvasLayer.new()
	result_overlay.visible = false
	add_child(result_overlay)

	result_dim = ColorRect.new()
	result_dim.rect_position = Vector2.ZERO
	result_dim.rect_size = Vector2(1280, 800)
	result_dim.color = Color(0, 0, 0, 0.55)
	result_overlay.add_child(result_dim)

	result_panel = Panel.new()
	result_panel.rect_position = Vector2(320, 240)
	result_panel.rect_size = Vector2(640, 220)
	result_overlay.add_child(result_panel)

	result_message_label = Label.new()
	result_message_label.rect_position = Vector2(30, 30)
	result_message_label.rect_size = Vector2(580, 80)
	result_message_label.align = Label.ALIGN_CENTER
	result_message_label.valign = Label.VALIGN_CENTER
	result_message_label.autowrap = true
	_apply_font_to_control(result_message_label, 30)
	result_panel.add_child(result_message_label)

	result_summary_label = Label.new()
	result_summary_label.rect_position = Vector2(30, 120)
	result_summary_label.rect_size = Vector2(580, 30)
	result_summary_label.align = Label.ALIGN_CENTER
	_apply_font_to_control(result_summary_label, 24)
	result_panel.add_child(result_summary_label)

	restart_button_ref = Button.new()
	restart_button_ref.rect_position = Vector2(90, 165)
	restart_button_ref.rect_size = Vector2(200, 36)
	restart_button_ref.text = "Играть снова"
	_apply_font_to_control(restart_button_ref, 20)
	restart_button_ref.connect("pressed", self, "_on_restart_button_pressed")
	result_panel.add_child(restart_button_ref)

	back_button_ref = Button.new()
	back_button_ref.rect_position = Vector2(350, 165)
	back_button_ref.rect_size = Vector2(200, 36)
	back_button_ref.text = "Назад в меню"
	_apply_font_to_control(back_button_ref, 20)
	back_button_ref.connect("pressed", self, "_on_result_button_pressed")
	result_panel.add_child(back_button_ref)

	_apply_result_overlay_layout(_get_effective_screen_size(), 1.0)


func _show_result_overlay(message):
	if result_overlay == null:
		_create_result_overlay()

	result_overlay.visible = true
	result_message_label.text = message
	result_summary_label.text = "Игрок: %d/%d   Бот: %d/%d" % [
		player_marked.size(),
		player_numbers.size(),
		bot_marked.size(),
		bot_numbers.size()
	]


func _on_draw_timer_timeout():
	_draw_next_number()


func _on_result_button_pressed():
	_return_to_menu()


func _on_restart_button_pressed():
	_restart_game()


func _return_to_menu():
	if has_node("GameSoundtrackPlayer"):
		$GameSoundtrackPlayer.stop()

	if has_node("/root/MusicScene/MainSoundtrackPlayer"):
		var music = get_node("/root/MusicScene/MainSoundtrackPlayer")
		if not music.playing:
			music.play()

	_log_scene("Returning to MainScene from %s" % name)
	get_tree().change_scene("res://MainScene.tscn")


func _restart_game():
	if has_node("GameSoundtrackPlayer"):
		$GameSoundtrackPlayer.stop()

	var gamefields = [
		"res://GameField1.tscn",
		"res://GameField2.tscn",
		"res://GameField3.tscn",
		"res://GameField4.tscn"
	]
	var random_scene = randi() % gamefields.size()
	_log_game_event("Restart game", "Chosen scene: %s" % gamefields[random_scene])
	get_tree().change_scene(gamefields[random_scene])


func _create_ui_font():
	var font_data = load("res://PFAgoraSlabPro Bold.ttf")
	if font_data == null:
		_log_warning("UI font could not be loaded")
		return

	ui_font = DynamicFont.new()
	ui_font.font_data = font_data
	ui_font.size = 24


func _apply_font_to_control(control, size):
	if ui_font == null or control == null:
		return

	var font = DynamicFont.new()
	font.font_data = ui_font.font_data
	font.size = size
	control.add_font_override("font", font)


func _create_player_click_sound():
	var sound_stream = load("res://Sounds/PressedButtonSound2.mp3")
	if sound_stream == null:
		_log_warning("Player click sound could not be loaded")
		return

	if "loop" in sound_stream:
		sound_stream.loop = false

	player_click_sound = AudioStreamPlayer.new()
	player_click_sound.stream = sound_stream
	add_child(player_click_sound)
	_log_info("Player click sound initialized")


func _play_player_click_sound():
	if player_click_sound == null:
		return

	if player_click_sound.playing:
		player_click_sound.stop()
	player_click_sound.play()

