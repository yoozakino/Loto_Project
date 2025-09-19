extends Node2D

var num
onready var NumLabel = $Number

func _ready():
	randomize()
	_numgen()

func _numgen():
	var generated_num = randi() % 90 + 1
	num = generated_num
	NumLabel.text = str(num)
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		MusicScene.get_node("MainSoundtrackPlayer").play()
		get_tree().change_scene("res://MainScene.tscn")
