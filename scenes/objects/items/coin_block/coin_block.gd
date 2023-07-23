extends Node2D


const UP_SPEED = 280
const GRAVITY = 1000
const POINTS = 200

const FRAME_TIME = 0.05

const SFX_COIN := preload("res://assets/sounds/coin.wav")


var frame_timer := 0.0
var frame := 0

var velocity := Vector2.ZERO

var start_position: Vector2


func _ready():
	velocity.y = -UP_SPEED
	
	position.y -= 16
	start_position = position
	
	z_index = 1
	
	await get_tree().create_timer(0.1, false).timeout
	
	var level = Main.get_level()
	level.coins += 1
	level.add_points(POINTS)
	Audio.play_sfx(SFX_COIN)


func _process(delta):
	frame_timer += delta
	
	if frame_timer >= FRAME_TIME:
		frame += 1
		if frame >= 3:
			frame = 0
		
		$Sprite.frame = frame
		frame_timer = 0
	
	velocity.y += GRAVITY * delta
	position += velocity * delta
	
	if position.y >= start_position.y:
		collect()


func collect():
	Main.get_level().spawn_points(position, POINTS)
	queue_free()
