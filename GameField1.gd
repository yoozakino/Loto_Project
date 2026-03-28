extends Node2D

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

onready var NumLabel = $Number


func _ready():
	randomize()
	_create_ui_font()
	_create_player_click_sound()
	_stop_menu_music()
	_apply_game_volume()
	_find_cards()
	_prepare_cards()
	if player_card == null or bot_card == null:
		NumLabel.text = "ERR"
		return
	_create_result_overlay()
	_create_draw_timer()
	_fill_barrels()
	_draw_next_number()


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_return_to_menu()
		return

	if game_over and event.is_action_pressed("ui_accept"):
		_return_to_menu()
		return


func _stop_menu_music():
	if has_node("/root/MusicScene/MainSoundtrackPlayer"):
		var music = get_node("/root/MusicScene/MainSoundtrackPlayer")
		if music.playing:
			music.stop()


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
			for subchild in child.get_children():
				if subchild is GridContainer:
					if String(subchild.name).begins_with("PlayerCard"):
						player_card = subchild
					elif String(subchild.name).begins_with("BotCard"):
						bot_card = subchild


func _prepare_cards():
	_collect_card(player_card, true)
	_collect_card(bot_card, false)


func _collect_card(card, is_player):
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


func _draw_next_number():
	if game_over:
		return

	if available_numbers.empty():
		_finish_game("Бочонки закончились. Игра завершена.")
		return

	current_number = available_numbers.pop_front()
	drawn_numbers.append(current_number)
	NumLabel.text = str(current_number)

	if bot_labels.has(current_number):
		_mark_bot_number(current_number)

	_check_winner()

	if not game_over and draw_timer.is_stopped():
		draw_timer.start()


func _on_player_label_gui_input(event, number):
	if game_over:
		return

	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		_play_player_click_sound()
		_try_mark_player_number(number)


func _try_mark_player_number(number):
	if player_marked.has(number):
		return

	if not drawn_numbers.has(number):
		return

	player_marked.append(number)
	_visual_mark(player_labels[number], true)
	_check_winner()


func _mark_bot_number(number):
	if bot_marked.has(number):
		return

	bot_marked.append(number)
	_visual_mark(bot_labels[number], false)


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
	_show_result_overlay(message)


func _create_result_overlay():
	result_overlay = CanvasLayer.new()
	result_overlay.visible = false
	add_child(result_overlay)

	var dim = ColorRect.new()
	dim.rect_position = Vector2.ZERO
	dim.rect_size = Vector2(1280, 800)
	dim.color = Color(0, 0, 0, 0.55)
	result_overlay.add_child(dim)

	var panel = Panel.new()
	panel.rect_position = Vector2(320, 240)
	panel.rect_size = Vector2(640, 220)
	result_overlay.add_child(panel)

	result_message_label = Label.new()
	result_message_label.rect_position = Vector2(30, 30)
	result_message_label.rect_size = Vector2(580, 80)
	result_message_label.align = Label.ALIGN_CENTER
	result_message_label.valign = Label.VALIGN_CENTER
	result_message_label.autowrap = true
	_apply_font_to_control(result_message_label, 30)
	panel.add_child(result_message_label)

	result_summary_label = Label.new()
	result_summary_label.rect_position = Vector2(30, 120)
	result_summary_label.rect_size = Vector2(580, 30)
	result_summary_label.align = Label.ALIGN_CENTER
	_apply_font_to_control(result_summary_label, 24)
	panel.add_child(result_summary_label)

	var restart_button = Button.new()
	restart_button.rect_position = Vector2(90, 165)
	restart_button.rect_size = Vector2(200, 36)
	restart_button.text = "Играть заново"
	_apply_font_to_control(restart_button, 20)
	restart_button.connect("pressed", self, "_on_restart_button_pressed")
	panel.add_child(restart_button)

	var back_button = Button.new()
	back_button.rect_position = Vector2(350, 165)
	back_button.rect_size = Vector2(200, 36)
	back_button.text = "Вернуться в меню"
	_apply_font_to_control(back_button, 20)
	back_button.connect("pressed", self, "_on_result_button_pressed")
	panel.add_child(back_button)


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

	get_tree().change_scene("res://MainScene.tscn")


func _restart_game():
	if has_node("GameSoundtrackPlayer"):
		$GameSoundtrackPlayer.stop()

	var gamefields = [
		"res://GameField1.tscn",
		"res://GameField2.tscn",
		"res://GameField3.tscn",
		"res://GameField4.tscn",
		"res://GameField5.tscn"
	]
	var random_scene = randi() % gamefields.size()
	get_tree().change_scene(gamefields[random_scene])


func _create_ui_font():
	var font_data = load("res://PFAgoraSlabPro Bold.ttf")
	if font_data == null:
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
		return

	if "loop" in sound_stream:
		sound_stream.loop = false

	player_click_sound = AudioStreamPlayer.new()
	player_click_sound.stream = sound_stream
	add_child(player_click_sound)


func _play_player_click_sound():
	if player_click_sound == null:
		return

	if player_click_sound.playing:
		player_click_sound.stop()
	player_click_sound.play()
