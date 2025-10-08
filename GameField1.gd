extends Node2D

var num
onready var NumLabel = $Number

func _ready():
	randomize()
	NumLabel.modulate.a = 0
	yield(get_tree().create_timer(3.0), "timeout")
	_numgen()
	_fade_in_numlabel()

func _numgen():
	var generated_num = randi() % 90 + 1
	num = generated_num
	NumLabel.text = str(num)
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		MusicScene.get_node("MainSoundtrackPlayer").play()
		get_tree().change_scene("res://MainScene.tscn")
		
func _fade_in_numlabel():
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(NumLabel, "modulate:a", 0, 1, 1.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()

