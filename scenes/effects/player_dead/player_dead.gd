extends Node2D


signal finished


const GRAVITY_DELAY = 0.3

const JUMP_SPEED = 240
const GRAVITY = 550


var sprite_frames: SpriteFrames

var gravity_delay := GRAVITY_DELAY
var velocity := Vector2.ZERO

var finished_emitted := false


func _ready():
	if sprite_frames != null:
		$Sprite.sprite_frames = sprite_frames
	
	$Sprite.play("die")
	velocity.y = -JUMP_SPEED
	
	get_tree().create_timer(4.0, false).timeout.connect(_on_timer)


func _process(delta):
	if gravity_delay > 0:
		gravity_delay -= delta
	else:
		velocity.y += GRAVITY * delta
		
		position += velocity * delta
	
	if not finished_emitted:
		if Input.is_action_just_pressed("a"):
			finish()


func _on_timer():
	if finished_emitted:
		return
	
	finish()


func finish():
	finished_emitted = true
	finished.emit()
