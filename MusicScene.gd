extends Node2D

onready var main_soundtrack := $MainSoundtrackPlayer
onready var pressed_button_sound1 := $PressedButtonSound1Player


func _ready():
	Settings.apply_volume()
