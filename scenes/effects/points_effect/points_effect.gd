extends Sprite2D


const POINTS_ARRAY = [100, 200, 400, 500, 800, 1000, 2000, 4000, 5000, 8000, 1]
const SPEED = 60

var points := 100


func _ready():
	var index = POINTS_ARRAY.find(points)
	if index < 0:
		return
	
	frame = index
	
	get_tree().create_timer(0.8, false).timeout.connect(_on_timeout)


func _process(delta):
	position.y -= SPEED * delta


func _on_timeout():
	queue_free()
