extends Item


const FRAME_SPEED = 0.05


var frame_timer := 0.0


@onready var sprite := $Sprite


func _ready():
	forced_points = 1000
	
	super()

func _process(delta):
	frame_timer += delta
	if frame_timer >= FRAME_SPEED:
		sprite.frame += 1
		frame_timer = 0.0
		
		if sprite.frame >= (sprite.hframes * sprite.vframes) - 1:
			sprite.frame = 0


func collected(player):
	player.starman_enabled = true
	
	super(player)
