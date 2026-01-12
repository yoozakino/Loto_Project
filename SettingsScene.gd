extends Node2D

var next_action = ""

func _ready():
	$BrightnessSlider.value = Settings.brightness * $BrightnessSlider.max_value
	$VolumeSlider.value = Settings.volume * $VolumeSlider.max_value
	
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

func _on_HSlider_value_changed(value):
	_play_button_sound1()
	
	var brightness = lerp(0.2, 1.0, value / $BrightnessSlider.max_value)
	
	Settings.brightness = brightness
	
	get_tree().root.get_node("GameBrightness").color = Color(brightness, brightness, brightness)
	
func _on_VolumeSlider_value_changed(value):
	_play_button_sound1()
	
	var volume = value / $VolumeSlider.max_value
	
	Settings.volume = volume
	
	get_node("/root/MusicScene/MainSoundtrackPlayer").volume_db = linear2db(volume)
	get_node("/root/MusicScene/PressedButtonSound1Player").volume_db = linear2db(volume)
	#get_node("/root/GameField1/GameSoundtrackPlayer").volume_db = linear2db(volume)
	
func _on_BackButton_pressed():
	_play_button_sound1()
	get_node("ExitTimer").start()
	next_action = "back"
	
func _on_ExitTimer_timeout():
	match next_action:
		"back":
			get_tree().change_scene("res://MainScene.tscn")
	next_action = ""



