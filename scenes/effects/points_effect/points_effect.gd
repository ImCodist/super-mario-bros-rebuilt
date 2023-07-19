extends Sprite2D


const POINTS_ARRAY = [100, 200, 400, 500, 800, 1000, 2000, 4000, 5000, 8000, 1]
const SPEED = 30

var points := 100


func _ready():
	var index = POINTS_ARRAY.find(points)
	if index <= 0:
		return
	
	frame = index
	
	await get_tree().create_timer(1.0, false).timeout
	queue_free()


func _process(delta):
	position.y -= SPEED * delta
