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
		
var player_card_numbers = [
	8, 25, 41, 60, 75,
	37, 43, 51, 77, 90,
	28, 39, 45, 52, 62
]

var bot_card_numbers = [
	16, 21, 31, 42, 60,
	1, 18, 33, 53, 62,
	2, 38, 55, 69, 74
]
