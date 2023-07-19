extends Item


const BIG_POWERUP = preload("res://assets/resources/powerups/big.tres")
const FRAME_SPEED = 0.05

var frame_timer := 0.0


@onready var sprite = $Sprite


func _process(delta):
	frame_timer += delta
	if frame_timer >= FRAME_SPEED:
		sprite.frame += 1
		frame_timer = 0.0
		
		if sprite.frame >= (sprite.hframes * sprite.vframes) - 1:
			sprite.frame = 0


func collected(player):
	if Settings.fire_flower_to_super and player.powerup.powerup_level <= 0:
		powerup = BIG_POWERUP
	
	super(player)
