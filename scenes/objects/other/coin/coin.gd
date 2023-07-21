extends Area2D


const SFX_COIN := preload("res://assets/sounds/coin.wav")


func _ready():
	add_to_group("coins")

func _process(_delta):
	$Sprite.frame = Sprites.flash_frame


func collect():
	var level = Main.get_level()
	if level != null:
		level.coins += 1
	
	Audio.play_sfx(SFX_COIN)
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("players"):
		collect()
