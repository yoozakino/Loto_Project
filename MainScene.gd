extends Node2D

func _ready():
	# Создаём таймер в коде
	var exit_timer = Timer.new()
	exit_timer.name = "ExitTimer"
	exit_timer.wait_time = 0.33
	exit_timer.one_shot = true
	add_child(exit_timer)
	exit_timer.connect("timeout", self, "_on_ExitTimer_timeout")

func _on_PlayButton_pressed():
	if $PressedButtonSoundPlayer.playing:
		$PressedButtonSoundPlayer.stop()
	$PressedButtonSoundPlayer.play()

func _on_SettingsButton_pressed():
	if $PressedButtonSoundPlayer.playing:
		$PressedButtonSoundPlayer.stop()
	$PressedButtonSoundPlayer.play()

func _on_ExitButton_pressed():
	if $PressedButtonSoundPlayer.playing:
		$PressedButtonSoundPlayer.stop()
	$PressedButtonSoundPlayer.play()
	get_node("ExitTimer").start()

func _on_ExitTimer_timeout():
	get_tree().quit()
