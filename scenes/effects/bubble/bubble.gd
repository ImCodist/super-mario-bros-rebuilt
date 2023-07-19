extends Sprite2D


const SPEED = 50


func _process(delta):
	position.y -= SPEED * delta
	
	if position.y <= 32:
		queue_free()
