extends Node2D

var next_action = ""

func _ready():
	$BrightnessSlider.value = Settings.brightness * $BrightnessSlider.max_value
	$VolumeSlider.value = Settings.volume * $VolumeSlider.max_value
	Settings.apply_all()
	
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
	
	Settings.set_brightness_value(brightness)
	
func _on_VolumeSlider_value_changed(value):
	_play_button_sound1()
	
	var volume = value / $VolumeSlider.max_value
	
	Settings.set_volume_value(volume)
	
func _on_BackButton_pressed():
	_play_button_sound1()
	get_node("ExitTimer").start()
	next_action = "back"

func _on_ResetButton_pressed():
	_play_button_sound1()
	Settings.set_brightness_value(1.0)
	Settings.set_volume_value(1.0)
	$BrightnessSlider.value = Settings.brightness * $BrightnessSlider.max_value
	$VolumeSlider.value = Settings.volume * $VolumeSlider.max_value
	
func _on_ExitTimer_timeout():
	match next_action:
		"back":
			get_tree().change_scene("res://MainScene.tscn")
	next_action = ""



