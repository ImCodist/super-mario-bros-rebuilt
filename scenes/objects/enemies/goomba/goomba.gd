extends Enemy


var frame_timer := 0.0


func _process(delta):
	if Main.game_paused:
		return
	
	if been_stomped:
		sprite.frame = 2
		return
	
	if been_killed:
		return
	
	frame_timer += delta
	
	if frame_timer >= 0.133333:
		if sprite.frame == 0:
			sprite.frame = 1
		else:
			sprite.frame = 0
		
		frame_timer = 0.0
