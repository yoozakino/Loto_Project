extends ParallaxBackground

var speed = 50

func _process(delta):
	scroll_offset.y += speed * delta 

