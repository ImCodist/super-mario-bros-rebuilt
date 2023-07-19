extends Area2D


const WHIRLPOOL_PULL_TIME := 0.02


var whirlpool_pull_timer := 0.0


func _physics_process(delta):
	whirlpool_pull_timer += delta
	if whirlpool_pull_timer >= WHIRLPOOL_PULL_TIME:
		for player in get_overlapping_bodies():
			if player.is_in_group("players") and player.swimming:
				var direction_to = player.position.direction_to(position).sign()
				
				player.position.x += direction_to.x
				if not player.is_on_floor() and player.velocity.y >= 0 and direction_to.y > 0:
					player.position.y += direction_to.y
		
		whirlpool_pull_timer = 0


func _on_body_entered(body):
	if body.is_in_group("players"):
		body.in_whirlpool = true

func _on_body_exited(body):
	if body.is_in_group("players"):
		body.in_whirlpool = false
