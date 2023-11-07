extends Control


@onready var hud := $HUD

@onready var background := $Background

@onready var world_label := $CenterContainer/WorldLabel
@onready var lives_label := $CenterContainer/LivesLabel

@onready var player_sprite := $CenterContainer/PlayerSprite


var level_scene: Level


func _ready():
	from_level(level_scene)
	_do_intro()

func from_level(level: Level):
	if level == null:
		return
	
	hud.set_timer_text(level.timer, level.use_timer)
	hud.set_world_text(level.world, level.level)
	hud.set_score_text(level.score)
	hud.set_coin_text(level.coins)
	
	world_label.text = "world %s-%s" % [level.world, level.level] 
	lives_label.text = "*%3d" % level.lives


func _do_intro():
	var center_container := $CenterContainer
	var level_color := level_scene.level_theme.background_color
	
	var wait_time := 3.0
	var flicker_timer := 0.0666667
	
	hud.visible = false
	center_container.visible = false
	background.color = level_color
	await get_tree().create_timer(flicker_timer, false).timeout
	
	background.color = Color.BLACK
	await get_tree().create_timer(flicker_timer, false).timeout
	
	hud.visible = true
	center_container.visible = true
	await get_tree().create_timer(wait_time, false).timeout
	
	hud.visible = false
	center_container.visible = false
	await get_tree().create_timer(flicker_timer * 2.0, false).timeout
	
	background.color = level_color
	await get_tree().create_timer(flicker_timer, false).timeout
	
	if level_scene != null:
		Main.change_scene(level_scene)
