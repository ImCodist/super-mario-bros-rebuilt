extends Item


const SFX_1UP := preload("res://assets/sounds/1up.wav")


func collected(_player):
	var level = Main.get_level()
	if level != null:
		level.spawn_points(position, 1)
		level.lives += 1
	
	Audio.play_sfx(SFX_1UP)
