extends Block


const BRICK_PARTICLE := preload("res://scenes/effects/brick_particle/brick_particle.tscn")
const SFX_BRICK_BREAK := preload("res://assets/sounds/brick_break.wav")


func _ready():
	item_count = 0


func hit(body):
	if body.is_in_group("players"):
		if body.powerup.powerup_level >= 1 and item_count <= 0:
			for i in 4:
				var particle = BRICK_PARTICLE.instantiate()
				particle.position = position
				get_parent().add_child(particle)
				
				match i:
					0:
						particle.set_direction(-1, 1)
					1:
						particle.set_direction(1, 1)
					2:
						particle.set_direction(1, -1)
					3:
						particle.set_direction(-1, -1)
			
			var level := Main.get_level()
			if level != null:
				level.add_points(50)
			
			await get_tree().process_frame
			
			Audio.play_sfx(SFX_BRICK_BREAK)
			queue_free()
			return
	
	super(body)
