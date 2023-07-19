extends Node2D


const GRAVITY_DELAY = 0.3

const JUMP_SPEED = 240
const GRAVITY = 550


var sprite_frames: SpriteFrames

var gravity_delay := GRAVITY_DELAY
var velocity := Vector2.ZERO


func _ready():
	if sprite_frames != null:
		$Sprite.sprite_frames = sprite_frames
	
	$Sprite.play("die")
	velocity.y = -JUMP_SPEED


func _process(delta):
	if gravity_delay > 0:
		gravity_delay -= delta
	else:
		velocity.y += GRAVITY * delta
		
		position += velocity * delta
