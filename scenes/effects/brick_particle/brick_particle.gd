extends SpriteThemed


const GRAVITY = 1000
const V_SPEED = 250
const H_SPEED = 60
const FRAME_TIME := 0.2


var frame_timer := 0.0


var velocity := Vector2.ZERO


func _ready():
	texture_name = "brick_particles"
	z_index = 1


func _process(delta):
	frame_timer += delta
	
	if frame_timer >= FRAME_TIME:
		frame += 1
		
		if frame >= (hframes * vframes) - 1:
			frame = 0
		
		frame_timer = 0.0
	
	velocity.y += GRAVITY * delta
	position += velocity * delta


func set_direction(x, y):
	position.x += 4 * x
	position.y += 4 * y
	
	if y < 0:
		velocity.y = -V_SPEED
	else:
		velocity.y = -V_SPEED * 1.5
		
	velocity.x = H_SPEED * x
