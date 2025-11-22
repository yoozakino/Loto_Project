extends Node2D

var next_action = ""

func _ready():
	var exit_timer = Timer.new()
	exit_timer.name = "ExitTimer"
	exit_timer.wait_time = 0.33
	exit_timer.one_shot = true
	add_child(exit_timer)
	exit_timer.connect("timeout", self, "_on_ExitTimer_timeout")

func _play_button_sound1():
	var btn = get_node("/root/MusicScene/PressedButtonSound1Player")
	if btn.is_playing():
		btn.stop()
	btn.play()

func _on_PlayButton_pressed():
	_play_button_sound1()
	next_action = "play"
	
	var music = get_node("/root/MusicScene/MainSoundtrackPlayer")
	if music.playing:
		music.stop()
	get_node("ExitTimer").start()
	
func _on_SettingsButton_pressed():
	_play_button_sound1()
	next_action = "settings"
	get_node("ExitTimer").start()
	
func _on_ExitButton_pressed():
	_play_button_sound1()
	get_node("ExitTimer").start()
	next_action = "exit"
	
func _on_ExitTimer_timeout():
	match next_action:
		"exit":
			get_tree().quit()
		"settings":
			get_tree().change_scene("res://SettingsScene.tscn")
		"play":
			var gamefields = [
				"res://GameField1.tscn",
				"res://GameField2.tscn",
				"res://GameField3.tscn",
				"res://GameField4.tscn",
				"res://GameField5.tscn"
			]
			var random_scene = randi() % gamefields.size()
			var chosen_scene = gamefields[random_scene]
			get_tree().change_scene(chosen_scene)
	next_action = ""

