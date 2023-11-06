extends Control


@onready var hud := $HUD

@onready var world_label := $CenterContainer/WorldLabel
@onready var lives_label := $CenterContainer/LivesLabel

@onready var player_sprite := $CenterContainer/PlayerSprite


func _ready():
	from_level(Level.new())

func from_level(level: Level):
	hud.set_timer_text(level.timer, level.use_timer)
	hud.set_world_text(level.world, level.level)
	hud.set_score_text(level.score)
	hud.set_coin_text(level.coins)
	
	world_label.text = "world %s-%s" % [level.world, level.level] 
	lives_label.text = "*%3d" % level.lives
